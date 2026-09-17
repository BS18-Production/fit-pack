import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Aktif antrenman seansının kalıcı taslağı (docs/12-session-resilience.md).
/// Seans hafızadayken arka planda process öldürülürse veri kaybolmasın diye
/// shared_preferences'e JSON olarak yazılır, dönüşte kurtarılır.

const _kDraftKey = 'active_workout_draft_v1';

/// Tek bir set'in serileştirilebilir hali.
class DraftSet {
  double? weight;
  int? reps;
  double? rpe;
  int? durationSec;
  double? distanceM;
  String type;
  bool done;
  bool isRecord; // set tamamlanınca kişisel rekor rozeti aldı (resume korur)
  DraftSet({
    this.weight,
    this.reps,
    this.rpe,
    this.durationSec,
    this.distanceM,
    this.type = 'normal',
    this.done = false,
    this.isRecord = false,
  });

  Map<String, dynamic> toJson() => {
        'w': weight,
        'r': reps,
        'rpe': rpe,
        'd': durationSec,
        'm': distanceM,
        't': type,
        'done': done,
        'pr': isRecord,
      };

  factory DraftSet.fromJson(Map<String, dynamic> j) => DraftSet(
        weight: (j['w'] as num?)?.toDouble(),
        reps: (j['r'] as num?)?.toInt(),
        rpe: (j['rpe'] as num?)?.toDouble(),
        durationSec: (j['d'] as num?)?.toInt(),
        distanceM: (j['m'] as num?)?.toDouble(),
        type: (j['t'] as String?) ?? 'normal',
        done: (j['done'] as bool?) ?? false,
        isRecord: (j['pr'] as bool?) ?? false, // eski taslak: alan yok → false
      );
}

/// Taslaktaki bir hareket (exercise id + ipucu + setler).
class DraftExercise {
  final int exerciseId;
  final int restSec;
  final String? previous;
  final List<DraftSet> sets;
  // Kullanıcı ilerleme önerisini uyguladıysa kullanılan artış (kg) — devam
  // edince öneriler aynı kalsın (docs/21 #3). Eski taslakta yok → null.
  final double? appliedIncrementKg;
  DraftExercise({
    required this.exerciseId,
    required this.restSec,
    required this.previous,
    required this.sets,
    this.appliedIncrementKg,
  });

  Map<String, dynamic> toJson() => {
        'id': exerciseId,
        'rest': restSec,
        'prev': previous,
        'sets': sets.map((s) => s.toJson()).toList(),
        if (appliedIncrementKg != null) 'inc': appliedIncrementKg,
      };

  factory DraftExercise.fromJson(Map<String, dynamic> j) => DraftExercise(
        exerciseId: (j['id'] as num).toInt(),
        restSec: (j['rest'] as num?)?.toInt() ?? 0,
        previous: j['prev'] as String?,
        sets: ((j['sets'] as List?) ?? [])
            .map((e) => DraftSet.fromJson(e as Map<String, dynamic>))
            .toList(),
        appliedIncrementKg: (j['inc'] as num?)?.toDouble(),
      );
}

/// Kaydedilmiş aktif seans taslağı.
class WorkoutDraft {
  final String title;
  final int? routineId;
  final int startedAtMs;
  final int sessionDateMs;
  final List<DraftExercise> exercises;
  WorkoutDraft({
    required this.title,
    required this.routineId,
    required this.startedAtMs,
    required this.sessionDateMs,
    required this.exercises,
  });

  DateTime get startedAt => DateTime.fromMillisecondsSinceEpoch(startedAtMs);
  DateTime get sessionDate => DateTime.fromMillisecondsSinceEpoch(sessionDateMs);

  /// Banner için: en az bir sette anlamlı veri ya da ✓ var mı.
  bool get hasData =>
      exercises.any((e) => e.sets.any((s) =>
          s.done ||
          s.weight != null ||
          s.reps != null ||
          s.durationSec != null ||
          s.distanceM != null));

  Map<String, dynamic> toJson() => {
        'title': title,
        'routineId': routineId,
        'startedAtMs': startedAtMs,
        'sessionDateMs': sessionDateMs,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutDraft.fromJson(Map<String, dynamic> j) => WorkoutDraft(
        title: (j['title'] as String?) ?? 'Workout',
        routineId: (j['routineId'] as num?)?.toInt(),
        startedAtMs: (j['startedAtMs'] as num).toInt(),
        sessionDateMs: (j['sessionDateMs'] as num).toInt(),
        exercises: ((j['exercises'] as List?) ?? [])
            .map((e) => DraftExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String encode() => jsonEncode(toJson());

  static WorkoutDraft? decode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return WorkoutDraft.fromJson(map);
    } catch (_) {
      return null; // bozuk taslak — yok say
    }
  }
}

/// Taslağı disk üzerinde okur/yazar/siler.
class WorkoutDraftService {
  // Her silmede artar. Açık seans ekranı başladığı andaki değeri saklar;
  // değer değiştiyse taslak başka yerden silinmiştir (hesap değişimi, banner
  // "Sil") ve ekranın geciken yazımı onu geri getirmemelidir. Statik: hesap
  // değişimi servisi sağlayıcı dışından kuruyor.
  static int _clearCount = 0;
  int get clearCount => _clearCount;

  Future<void> save(WorkoutDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDraftKey, draft.encode());
  }

  Future<WorkoutDraft?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDraftKey);
    if (raw == null) return null;
    return WorkoutDraft.decode(raw);
  }

  Future<void> clear() async {
    _clearCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDraftKey);
  }
}

final workoutDraftServiceProvider =
    Provider<WorkoutDraftService>((ref) => WorkoutDraftService());

/// Antrenman ana ekranındaki "devam eden antrenman" banner'ı için taslağı okur.
/// Yalnızca veri içeren taslak döner (boş taslak banner göstermez).
final activeDraftProvider = FutureProvider.autoDispose<WorkoutDraft?>((ref) async {
  final draft = await ref.watch(workoutDraftServiceProvider).load();
  if (draft == null || !draft.hasData) return null;
  return draft;
});
