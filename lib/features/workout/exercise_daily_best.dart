import '../../data/database/daos/workout_dao.dart';

/// Her yerel takvim gününün en yüksek Epley tahmini; sıralı, tek nokta/gün.
List<({DateTime date, double e1rm})> dailyBestE1rm(List<ExerciseSetPoint> points) {
  final best = <DateTime, double>{};
  for (final p in points) {
    final value = p.e1rm;
    if (value == null) continue;
    final day = DateTime(p.date.year, p.date.month, p.date.day);
    if (value > (best[day] ?? 0)) best[day] = value;
  }
  final days = best.keys.toList()..sort();
  return [for (final day in days) (date: day, e1rm: best[day]!)];
}
