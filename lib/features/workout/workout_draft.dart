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
  final bool sessionOnly;
  DraftExercise({
    required this.exerciseId,
    required this.restSec,
    required this.previous,
    required this.sets,
    this.appliedIncrementKg,
    this.sessionOnly = false,
  });

  Map<String, dynamic> toJson() => {
        'id': exerciseId,
        'rest': restSec,
        'prev': previous,
        'sets': sets.map((s) => s.toJson()).toList(),
        if (appliedIncrementKg != null) 'inc': appliedIncrementKg,
        if (sessionOnly) 'sessionOnly': true,
      };

  factory DraftExercise.fromJson(Map<String, dynamic> j) => DraftExercise(
        exerciseId: (j['id'] as num).toInt(),
        restSec: (j['rest'] as num?)?.toInt() ?? 0,
        previous: j['prev'] as String?,
        sets: ((j['sets'] as List?) ?? [])
            .map((e) => DraftSet.fromJson(e as Map<String, dynamic>))
            .toList(),
        appliedIncrementKg: (j['inc'] as num?)?.toDouble(),
        sessionOnly: j['sessionOnly'] == true,
      );
}

/// Kaydedilmiş aktif seans taslağı.
class WorkoutDraft {
  final String title;
  final int? routineId;
  final int startedAtMs;
  final int sessionDateMs;
  // Süren dinlenme (docs/45): uygulama arka planda öldürülse de dönüşte
  // sayaç kaldığı yerden sürer. Eski taslakta yok → null.
  final int? restStartedAtMs;
  final int? restEndsAtMs;
  // Son tamamlanan setin anı (docs/53 süre kuralı). Eski taslakta yok → null.
  final int? lastDoneAtMs;
  final List<DraftExercise> exercises;
  WorkoutDraft({
    required this.title,
    required this.routineId,
    required this.startedAtMs,
    required this.sessionDateMs,
    this.restStartedAtMs,
    this.restEndsAtMs,
    this.lastDoneAtMs,
    required this.exercises,
  });

  DateTime get startedAt => DateTime.fromMillisecondsSinceEpoch(startedAtMs);
  DateTime get sessionDate => DateTime.fromMillisecondsSinceEpoch(sessionDateMs);
  DateTime? get restStartedAt => restStartedAtMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(restStartedAtMs!);
  DateTime? get restEndsAt => restEndsAtMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(restEndsAtMs!);
  DateTime? get lastDoneAt => lastDoneAtMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(lastDoneAtMs!);

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
        if (restStartedAtMs != null) 'restStartedAtMs': restStartedAtMs,
        if (restEndsAtMs != null) 'restEndsAtMs': restEndsAtMs,
        if (lastDoneAtMs != null) 'lastDoneAtMs': lastDoneAtMs,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutDraft.fromJson(Map<String, dynamic> j) => WorkoutDraft(
        title: (j['title'] as String?) ?? 'Workout',
        routineId: (j['routineId'] as num?)?.toInt(),
        startedAtMs: (j['startedAtMs'] as num).toInt(),
        sessionDateMs: (j['sessionDateMs'] as num).toInt(),
        restStartedAtMs: (j['restStartedAtMs'] as num?)?.toInt(),
        restEndsAtMs: (j['restEndsAtMs'] as num?)?.toInt(),
        lastDoneAtMs: (j['lastDoneAtMs'] as num?)?.toInt(),
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
  WorkoutDraftService({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  // Her silmede artar. Açık seans ekranı başladığı andaki değeri saklar;
  // değer değiştiyse taslak başka yerden silinmiştir (hesap değişimi, banner
  // "Sil") ve ekranın geciken yazımı onu geri getirmemelidir. Statik: hesap
  // değişimi servisi sağlayıcı dışından kuruyor.
  static int _clearCount = 0;
  int get clearCount => _clearCount;

  // Hesap temizliği başka bir servis örneği kullanabilir. Bütün yazmalar
  // aynı sırada: başlamış yazma biter, ardından clear onu kaldırır. Bir
  // hatanın kuyruğu kilitlememesi için çağırana dönen hata ayrıca tüketilir.
  static Future<void>? _writes;
  static Object? _lastWrite;

  static Future<T> _serialize<T>(Future<T> Function() action) {
    final previous = _writes;
    final ticket = Object();
    _lastWrite = ticket;
    Future<T> run() async {
      try {
        return await Future<T>.sync(action);
      } finally {
        // Son iş kendi sonucu dönmeden kuyruğu bırakır. Tamamlanmış bir
        // Future'ı veya onun oluşturulduğu zamanlayıcı bölgesini tutmayız.
        if (identical(_lastWrite, ticket)) {
          _writes = null;
          _lastWrite = null;
        }
      }
    }

    final result = previous == null ? run() : previous.then((_) => run());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> save(WorkoutDraft draft) async {
    await saveIfCurrent(draft, expectedClearCount: _clearCount);
  }

  /// Seçim başlamadan yakalanan nesil hâlâ geçerliyse taslağı yazar.
  /// [isCurrent] ayrıca hesap/ekran sahipliğini doğrulayabilir; kuyruğu ve
  /// tercih yüklemesini bekledikten sonra yeniden kontrol edilir. false,
  /// bayat işlemdir; depolama hatası ise çağırana exception olarak gider.
  /// Platforma başlamış yazma iptal edilemez. Sahiplik yazarken değişirse
  /// yalnız bu yazının sonucu, kuyruk bırakılmadan kaldırılır; başka bir
  /// servis yazması araya giremez. Bu sıra süreç içi korumadır, ani süreç
  /// kapanmasında disk dayanıklılığı garantisi değildir.
  Future<bool> saveIfCurrent(
    WorkoutDraft draft, {
    required int expectedClearCount,
    bool Function()? isCurrent,
  }) {
    bool current() =>
        expectedClearCount == _clearCount && (isCurrent?.call() ?? true);
    if (!current()) return Future<bool>.value(false);
    // Mutable set değerleri kuyruk beklerken değişse de çağrı anı saklanır.
    final encoded = draft.encode();
    return _serialize(() async {
      if (!current()) return false;
      final prefs = await _preferences();
      if (!current()) return false;
      try {
        if (!await prefs.setString(_kDraftKey, encoded)) {
          throw StateError('Workout draft could not be saved');
        }
        if (!current()) {
          if (!await prefs.remove(_kDraftKey)) {
            throw StateError('Stale workout draft could not be cleared');
          }
          return false;
        }
      } catch (_) {
        // SharedPreferences önce bellek kopyasını günceller. Başarısız
        // platform yazısı sonraki load'a başarılı kayıt gibi görünmesin.
        await prefs.reload();
        rethrow;
      }
      return true;
    });
  }

  // SharedPreferences cache'i platform yazısı bitmeden değişir. Okuma da
  // sıraya girer: yeniden açılan ekran henüz sonucu bilinmeyen adayı görmez;
  // tercih yüklenirken başlayan başka yazma da okumanın önüne geçemez.
  Future<WorkoutDraft?> load() => _serialize(() async {
        final prefs = await _preferences();
        final raw = prefs.getString(_kDraftKey);
        if (raw == null) return null;
        return WorkoutDraft.decode(raw);
      });

  Future<void> clear() {
    // Bekleyen eski yazmalar, kaldırma sıra beklerken bile geçersizdir.
    _clearCount++;
    return _serialize(() async {
      final prefs = await _preferences();
      try {
        if (!await prefs.remove(_kDraftKey)) {
          throw StateError('Workout draft could not be cleared');
        }
      } catch (_) {
        await prefs.reload();
        rethrow;
      }
    });
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
