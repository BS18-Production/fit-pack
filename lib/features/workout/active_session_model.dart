import 'package:drift/drift.dart' show Value;

import '../../core/utils/format.dart';
import '../../core/units/units.dart';
import '../../data/database/app_database.dart';
import 'progression.dart';
import 'set_prefill.dart';
import 'workout_draft.dart';

// Aktif seansın bellek modeli (CR-018): set girdisi, seanstaki hareket, taslak
// dönüşümü ve bitirişte yazılacak satırlar. Ekrandan ayrı — UI'sız test
// edilebilir. Ekran ([ActiveSessionScreen]) durumun tek sahibi olarak kalır.

const sessionSetTypes = ['normal', 'warmup', 'drop', 'failure'];
const sessionSetTypeLabel = {
  'normal': '',
  'warmup': 'I',
  'drop': 'D',
  'failure': 'F',
};

class SessionSetEntry {
  double? weight;
  int? reps;
  double? rpe;
  int? durationSec; // süre ölçümlü hareket (plank, kardiyo)
  double? distanceM; // mesafe ölçümlü hareket (koşu, yüzme)
  String type = 'normal';
  bool done = false;
  bool isRecord = false; // bu set tamamlanınca kişisel rekor kırdı (rozet)
  // Değerler koddan doldurulunca artar (G-2): giriş alanları `initialValue`
  // ile kurulu, yeni değeri göstermeleri için bu sayaçla yeniden kurulurlar.
  int fillGen = 0;

  SessionSetEntry();

  /// Taslaktan geri yükleme (resume modu — docs/12).
  SessionSetEntry.fromDraft(DraftSet s)
    : weight = s.weight,
      reps = s.reps,
      rpe = s.rpe,
      durationSec = s.durationSec,
      distanceM = s.distanceM,
      type = s.type,
      done = s.done,
      isRecord = s.isRecord;

  DraftSet toDraft() => DraftSet(
    weight: weight,
    reps: reps,
    rpe: rpe,
    durationSec: durationSec,
    distanceM: distanceM,
    type: type,
    done: done,
    isRecord: isRecord,
  );

  SetValues get values => SetValues(
    weightKg: weight,
    reps: reps,
    durationSec: durationSec,
    distanceM: distanceM,
  );

  void apply(SetValues v) {
    weight = v.weightKg;
    reps = v.reps;
    durationSec = v.durationSec;
    distanceM = v.distanceM;
  }

  /// Ölçüm tipine göre set'te anlamlı bir veri girilmiş mi.
  bool hasInput(String measure) {
    switch (measure) {
      case 'reps':
        return reps != null;
      case 'time':
        return durationSec != null;
      case 'distance':
        return distanceM != null || durationSec != null;
      default:
        return weight != null || reps != null;
    }
  }
}

class SessionExerciseEntry {
  final Exercise exercise;
  // Geçen seansın son çalışma seti etiketi — yalnız taslak uyumu için
  // yazılır; ekran artık set numarasına göre [lastSets]'i gösterir (G-2).
  final String? previous;
  // Hareketin son yapıldığı seanstaki setler, set sırasıyla (G-2).
  final List<WorkoutSet> lastSets;
  final List<SessionSetEntry> sets;
  // Setler arası dinlenme (rutinden ya da kategoriye göre). Seansta
  // değiştirilebilir; rutindeki hareketse rutine de yazılır (A2).
  int restSec;
  // Hareket açılan rutinde var mı — dinlenme değişikliği rutine yazılır mı.
  final bool inRoutine;
  // Seans öncesi kişisel rekorlar (record_calc) — canlı modda, yalnız ağırlık
  // ölçümlü hareketlerde yüklenir. 0 = geçmiş yok → anlık rozet üretilmez.
  // Seans içinde rekor kırılınca güncellenir ki aynı seansta yalnız gerçek
  // artışlar yeniden rozetlensin.
  double bestE1rm = 0;
  double bestWeightKg = 0;
  // Sonraki hedef önerisi (docs/21 #3) — yalnız rutinli canlı seansta,
  // kilo×tekrar harekette ve geçmiş varsa.
  final ProgressionAdvice? advice;
  // Kullanıcı öneriyi uyguladıysa kullanılan artış (kg); uygulanmadıysa null.
  // Tekrar önerisinde (+1) yalnız "uygulandı" bayrağı olarak işler.
  double? appliedIncrementKg;
  SessionExerciseEntry(
    this.exercise,
    this.sets, {
    required this.lastSets,
    required this.restSec,
    required Units units,
    this.inRoutine = false,
    this.advice,
    this.appliedIncrementKg,
  }) : previous = prevLabel(
         lastSets.where((s) => !s.isWarmup).lastOrNull,
         exercise.measurementType,
         units,
       );

  String get measure => exercise.measurementType;

  DraftExercise toDraft() => DraftExercise(
    exerciseId: exercise.id,
    restSec: restSec,
    previous: previous,
    appliedIncrementKg: appliedIncrementKg,
    sets: sets.map((s) => s.toDraft()).toList(),
  );

  List<CurrentSet> get currentSets => [
    for (final s in sets) (values: s.values, warmup: s.type == 'warmup'),
  ];

  /// Öneri kaynağı olarak geçen seans. Kullanıcı ilerlemeyi uyguladıysa
  /// çalışma setleri öneriye çevrilir (ısınma setleri aynen kalır); "ÖNCEKİ"
  /// sütunu ise her zaman gerçek geçmişi gösterir.
  List<SetValues> get lastValues {
    final a = advice;
    final inc = appliedIncrementKg;
    return [
      for (final w in lastSets)
        a != null && inc != null && !w.isWarmup
            ? a.apply(SetValues.fromSet(w), incrementKg: inc)
            : SetValues.fromSet(w),
    ];
  }

  /// [index]'teki set için ✓ önerisi (bkz. [suggestionFor]).
  SetValues? suggestionAt(int index) => suggestionFor(
    index: index,
    current: currentSets,
    lastSession: lastValues,
    measure: measure,
  );
}

/// "12:30" / "1.30" / "90" → saniye. Boş/geçersiz → null.
int? parseDuration(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (t.contains(':')) {
    final parts = t.split(':');
    final m = int.tryParse(parts[0]) ?? 0;
    final s = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return m * 60 + s;
  }
  // saf sayı → dakika kabul et
  final mins = double.tryParse(t.replaceAll(',', '.'));
  return mins == null ? null : (mins * 60).round();
}

/// Geçen seansın değerini ölçüm tipine göre GÖRÜNTÜ biriminde formatlar
/// ("60×8", "12", "12:30", "5.2 km" / imperial'de "132×8", "3.2 mi").
String? prevLabel(WorkoutSet? s, String measure, Units units) {
  if (s == null) return null;
  switch (measure) {
    case 'reps':
      return s.reps != null ? '${s.reps}' : null;
    case 'time':
      return s.durationSec != null ? fmtDuration(s.durationSec!) : null;
    case 'distance':
      if (s.distanceM == null) return null;
      return '${units.distanceValue(s.distanceM!)} ${units.distanceUnit}';
    default:
      return (s.weightKg != null && s.reps != null)
          ? '${units.liftValue(s.weightKg!)}×${s.reps}'
          : null;
  }
}

/// Bitirişte yazılacak seans satırı. Mantıksal gün = [sessionDate] (bugün ya
/// da geçmişe çekilmiş); gerçek başlangıç saati bu güne taşınır. Canlı modda
/// süre korunur; geçmiş kayıtta ([manual]) saat 12:00, süre yok.
WorkoutSessionsCompanion finishedSessionRow({
  required String title,
  required int? routineId,
  required DateTime sessionDate,
  required DateTime startedAt,
  required Duration elapsed,
  required bool manual,
}) {
  final hour = manual ? 12 : startedAt.hour;
  final minute = manual ? 0 : startedAt.minute;
  final started = DateTime(
    sessionDate.year,
    sessionDate.month,
    sessionDate.day,
    hour,
    minute,
  );
  final ended = manual ? null : started.add(elapsed);
  return WorkoutSessionsCompanion(
    date: Value(started),
    phase: const Value(0),
    workoutType: Value(title),
    routineId: Value(routineId),
    startedAt: Value(started),
    endedAt: Value(ended),
    durationMin: manual ? const Value(null) : Value(elapsed.inMinutes),
  );
}

/// Seans süresi kuralı (docs/53): son tamamlanan setten sonra
/// [sessionIdleCutoff]'tan uzun boşluk varsa bitiş = son set +
/// [sessionIdleGrace]; yoksa şimdi. Boşta bırakılan ya da "kaydet ve çık"
/// ile duraklatılan seansın saatleri süreye (ve kaloriye) eklenmez.
const sessionIdleCutoff = Duration(minutes: 10);
const sessionIdleGrace = Duration(minutes: 1);

Duration sessionElapsed({
  required DateTime startedAt,
  required DateTime now,
  DateTime? lastDoneAt,
}) {
  final end = lastDoneAt != null && now.difference(lastDoneAt) > sessionIdleCutoff
      ? lastDoneAt.add(sessionIdleGrace)
      : now;
  final d = end.difference(startedAt);
  return d.isNegative ? Duration.zero : d;
}

/// Bitirişte tamamlanmamış set sayısı (onay penceresi için).
int incompleteSetCount(List<SessionExerciseEntry> exercises) => exercises.fold(
    0, (n, e) => n + e.sets.where((s) => !s.done).length);

/// Bitirişte yazılacak setler (`insertSessionWithSets`): veri girilmemiş ve
/// tamamlanmamış setler atlanır, set numarası hareket içinde 1'den sayar.
List<WorkoutSetsCompanion> sessionSetRows(
  int sessionId,
  List<SessionExerciseEntry> exercises,
) {
  final out = <WorkoutSetsCompanion>[];
  for (final ex in exercises) {
    var n = 1;
    for (final s in ex.sets) {
      if (!s.hasInput(ex.measure) && !s.done) continue;
      out.add(
        WorkoutSetsCompanion(
          sessionId: Value(sessionId),
          exerciseId: Value(ex.exercise.id),
          setNumber: Value(n++),
          weightKg: Value(s.weight),
          reps: Value(s.reps),
          rpe: Value(s.rpe),
          durationSec: Value(s.durationSec),
          distanceM: Value(s.distanceM),
          setType: Value(s.type),
          isComplete: Value(s.done),
          isWarmup: Value(s.type == 'warmup'),
        ),
      );
    }
  }
  return out;
}
