import 'package:drift/drift.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/services/export_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Batch 4 — M-07 regresyonu: dışa aktarma V2 alanlarını içermeli
/// (RPE, set tipi, süre/mesafe, su, rutinler). Eskiden yalnız V1 şeması vardı.
void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  final start = DateTime(2026, 7, 1);
  final end = DateTime(2026, 7, 8);

  Future<int> insertExercise(String name) =>
      db.workoutDao.insertCustomExercise(ExercisesCompanion(
        name: Value(name),
        category: const Value('push'),
        muscleGroups: const Value('[]'),
      ));

  test('CSV: set RPE / tipi / süre / mesafe sütunları dolu gelir', () async {
    final exId = await insertExercise('Plank');
    await db.workoutDao.insertSessionWithSets(
      WorkoutSessionsCompanion(
        date: Value(DateTime(2026, 7, 2, 18)),
        phase: const Value(0),
        workoutType: const Value('Push Day'),
      ),
      (id) => [
        WorkoutSetsCompanion(
          sessionId: Value(id),
          exerciseId: Value(exId),
          setNumber: const Value(1),
          rpe: const Value(8.5),
          setType: const Value('failure'),
          durationSec: const Value(75),
        ),
      ],
    );

    final csv = await ExportService(db)
        .exportCsv(start, end, scope: ExportScope.workout);
    expect(csv, contains('rpe'));
    expect(csv, contains('setType'));
    expect(csv, contains('8.5'));
    expect(csv, contains('failure'));
    expect(csv, contains('75')); // durationSec
  });

  test('JSON: su takibi + rutinler dahil', () async {
    await db.nutritionDao.addWater(DateTime(2026, 7, 3), 1500);
    final exId = await insertExercise('Squat');
    await db.workoutDao.saveRoutineWithExercises(
      routine: const RoutinesCompanion(
          name: Value('Leg Day'), scheduledWeekday: Value(3)),
      isNew: true,
      buildExercises: (id) => [
        RoutineExercisesCompanion(
          routineId: Value(id),
          exerciseId: Value(exId),
          orderIndex: const Value(0),
          targetSets: const Value(4),
        ),
      ],
    );

    final json =
        await ExportService(db).exportJson(start, end, scope: ExportScope.all);
    expect(json, contains('"water"'));
    expect(json, contains('1500'));
    expect(json, contains('"routines"'));
    expect(json, contains('Leg Day'));
  });

  test('Markdown: su bölümü + rutin bölümü başlıkları', () async {
    await db.nutritionDao.addWater(DateTime(2026, 7, 4), 2000);
    final md =
        await ExportService(db).exportMarkdown(start, end, scope: ExportScope.all);
    expect(md, contains('## Su'));
    expect(md, contains('2000'));
  });
}
