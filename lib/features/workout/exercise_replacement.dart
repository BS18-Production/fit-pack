import '../../core/units/units.dart';
import '../../data/database/app_database.dart';
import 'active_session_model.dart';
import 'workout_ui.dart';

/// Girilmiş hiçbir alan farklı harekete yeniden etiketlenmez. Ölçüm tipinden
/// bağımsız bakılır: RPE/tür ve eski taslaktaki gizli alanlar da kullanıcı verisi.
bool _hasRecordedInput(SessionSetEntry s) =>
    s.done ||
    s.weight != null ||
    s.reps != null ||
    s.rpe != null ||
    s.durationSec != null ||
    s.distanceM != null ||
    s.type != 'normal' ||
    s.isRecord;

/// Saf plan: kaynak liste ve setler değişmez. Aynı ID'nin başka blokları
/// kimlikleriyle korunur. Yeni set nesneleri eski native hedefi devralmaz.
List<SessionExerciseEntry> replaceSessionExercise({
  required List<SessionExerciseEntry> exercises,
  required SessionExerciseEntry source,
  required Exercise replacement,
  required List<WorkoutSet> lastSets,
  required Units units,
}) {
  final index = exercises.indexOf(source);
  if (index < 0 || source.exercise.id == replacement.id) return exercises;
  final retained = source.sets.where(_hasRecordedInput).toList();
  final emptyCount = source.sets.length - retained.length;
  final next = SessionExerciseEntry(
    replacement,
    List.generate(emptyCount > 0 ? emptyCount : 1, (_) => SessionSetEntry()),
    lastSets: lastSets,
    restSec: WorkoutUi.defaultRestSec(replacement.category),
    units: units,
    sessionOnly: true,
  );
  final kept =
      SessionExerciseEntry(
          source.exercise,
          retained,
          lastSets: source.lastSets,
          restSec: source.restSec,
          units: units,
          inRoutine: source.inRoutine,
          sessionOnly: source.sessionOnly,
          advice: source.advice,
          appliedIncrementKg: source.appliedIncrementKg,
        )
        ..bestE1rm = source.bestE1rm
        ..bestWeightKg = source.bestWeightKg;
  // Girilmiş ama tamamlanmamış eski setler canlı kartın yeni hareketten
  // önce gelmesini engellemesin; kaybolmadan hemen arkasında kalırlar.
  final hasUnfinishedInput = retained.any((s) => !s.done);
  return [
    ...exercises.take(index),
    if (hasUnfinishedInput) next,
    if (retained.isNotEmpty) kept,
    if (!hasUnfinishedInput) next,
    ...exercises.skip(index + 1),
  ];
}
