import 'package:drift/drift.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// docs/29 — "üst üste iki seans" kuralı sondan ikinci seansı okur.
void main() {
  late AppDatabase db;
  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  Future<void> seans(DateTime date, int ex, int reps, {int sets = 2}) =>
      db.workoutDao.insertSessionWithSets(
        WorkoutSessionsCompanion(
          date: Value(date),
          phase: const Value(0),
          workoutType: const Value('Push'),
        ),
        (id) => [
          for (var i = 0; i < sets; i++)
            WorkoutSetsCompanion(
              sessionId: Value(id),
              exerciseId: Value(ex),
              setNumber: Value(i + 1),
              weightKg: const Value(60),
              reps: Value(reps),
            ),
        ],
      );

  test('sondan ikinci seansın setleri; tek seansta boş', () async {
    for (final n in ['A', 'B']) {
      await db.workoutDao.insertExercise(ExercisesCompanion(
        name: Value('Test $n'),
        category: const Value('compound'),
        muscleGroups: const Value('[]'),
        measurementType: const Value('weight_reps'),
      ));
    }
    final all = await db.workoutDao.getAllExercises();
    final a = all.firstWhere((e) => e.name == 'Test A').id;
    final b = all.firstWhere((e) => e.name == 'Test B').id;
    await seans(DateTime(2026, 10, 1), a, 6);
    expect(await db.workoutDao.getPreviousSessionSetsForExercise(a), isEmpty);

    await seans(DateTime(2026, 10, 3), a, 7, sets: 3);
    await seans(DateTime(2026, 10, 2), b, 9); // başka hareket araya girmez
    final prev = await db.workoutDao.getPreviousSessionSetsForExercise(a);
    expect(prev.map((s) => s.reps), [6, 6]);
    final last = await db.workoutDao.getLastSessionSetsForExercise(a);
    expect(last.map((s) => s.reps), [7, 7, 7]);
  });
}
