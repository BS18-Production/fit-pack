import 'package:fit_pack/data/database/daos/workout_dao.dart';
import 'package:fit_pack/features/workout/exercise_daily_best.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('aynı günün setleri tek en iyi nokta; tarihler sıralı ve boş gün uydurulmaz', () {
    final result = dailyBestE1rm([
      ExerciseSetPoint(date: DateTime(2026, 10, 18), weightKg: 60, reps: 10),
      ExerciseSetPoint(date: DateTime(2026, 10, 10, 18), weightKg: 50, reps: 6),
      ExerciseSetPoint(date: DateTime(2026, 10, 10, 19), weightKg: 50, reps: 12),
      ExerciseSetPoint(date: DateTime(2026, 10, 11), weightKg: 0, reps: 0),
    ]);
    expect(result.length, 2);
    expect(result.first, (date: DateTime(2026, 10, 10), e1rm: 70.0));
    expect(result.last.e1rm, 80);
  });
}
