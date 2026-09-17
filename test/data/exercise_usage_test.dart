import 'package:drift/drift.dart' hide isNull;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Hareket arama v2 — "son kullandıkların" ve kişisel sıralama verisi.
void main() {
  late AppDatabase db;
  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  Future<int> exercise(String name) => db.workoutDao.insertCustomExercise(
    ExercisesCompanion.insert(
      name: name,
      category: 'compound',
      muscleGroups: 'chest',
    ),
  );

  Future<void> session(DateTime date, List<int> exerciseIds) =>
      db.workoutDao.insertSessionWithSets(
        WorkoutSessionsCompanion(
          date: Value(date),
          phase: const Value(0),
          workoutType: const Value('Test'),
        ),
        (id) => [
          for (var i = 0; i < exerciseIds.length; i++)
            WorkoutSetsCompanion(
              sessionId: Value(id),
              exerciseId: Value(exerciseIds[i]),
              setNumber: Value(i + 1),
              weightKg: const Value(50),
              reps: const Value(8),
            ),
        ],
      );

  test(
    'pencere içindeki kullanım: set sayısı + son tarih, en yeni önce',
    () async {
      final bench = await exercise('Bench');
      final squat = await exercise('Squat');
      final row = await exercise('Row');
      await session(DateTime(2026, 9, 1), [bench, bench, squat]);
      await session(DateTime(2026, 9, 10), [squat]);
      await session(DateTime(2026, 5, 1), [row]); // pencere dışı

      final usage = await db.workoutDao.getExerciseUsageSince(
        DateTime(2026, 6, 1),
      );
      expect(usage.map((u) => u.exerciseId), [squat, bench]);
      expect(usage.first.sets, 2);
      expect(usage.first.lastUsed, DateTime(2026, 9, 10));
      expect(usage.last.sets, 2);
      expect(usage.any((u) => u.exerciseId == row), isFalse);
    },
  );

  test('pencere başı dahil ([since, …))', () async {
    final bench = await exercise('Bench');
    await session(DateTime(2026, 6, 1), [bench]);
    final usage = await db.workoutDao.getExerciseUsageSince(
      DateTime(2026, 6, 1),
    );
    expect(usage.single.exerciseId, bench);
  });
}
