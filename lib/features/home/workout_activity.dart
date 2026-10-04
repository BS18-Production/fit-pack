import '../../data/database/app_database.dart';
import '../workout/calorie_estimate.dart';

typedef WorkoutActivityDay = ({DateTime date, int sessions, int? kcal});

/// Son yedi takvim günü. Seans yoksa 0 kayıtlı yakım; bir seansın tahmini
/// hesaplanamıyorsa gün null kalır. Eksik tahmin 0 ya da kısmi toplam olmaz.
List<WorkoutActivityDay> workoutActivityDays({
  required DateTime now,
  required List<WorkoutSession> sessions,
  required Map<int, List<WorkoutSet>> setsBySession,
  required double? bodyWeightKg,
}) {
  return List.generate(7, (i) {
    final date = DateTime(now.year, now.month, now.day - 6 + i);
    final daySessions = sessions
        .where(
          (s) =>
              s.date.year == date.year &&
              s.date.month == date.month &&
              s.date.day == date.day,
        )
        .toList();
    var total = 0.0;
    var missing = false;
    for (final session in daySessions) {
      final intensity = sessionIntensity(setsBySession[session.id] ?? const []);
      final kcal = estimateWorkoutKcal(
        bodyWeightKg: bodyWeightKg,
        durationMin: session.durationMin,
        avgRpe: intensity.avgRpe,
        isCardio: intensity.isCardio || session.workoutType == 'Cardio',
      );
      if (kcal == null) {
        missing = true;
      } else {
        total += kcal;
      }
    }
    return (
      date: date,
      sessions: daySessions.length,
      kcal: missing ? null : total.round(),
    );
  });
}
