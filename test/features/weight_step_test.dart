import 'package:drift/drift.dart' hide isNull;
import 'package:fit_pack/core/units/units.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/workout_dao.dart';
import 'package:fit_pack/features/workout/weight_step.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// A4 (Samet'in salon notu, 2026-09-30) — kilo ± adımı ve A2 — seansta
/// değişen dinlenme süresinin rutine yazılması.
void main() {
  const metric = Units(UnitSystem.metric);
  const imperial = Units(UnitSystem.imperial);

  group('defaultStepKg — ekipmana göre', () {
    test('halter 2,5 · dambıl 2 · makine/kablo 5 · kettlebell 4', () {
      expect(defaultStepKg('barbell', metric), 2.5);
      expect(defaultStepKg('dumbbell', metric), 2);
      expect(defaultStepKg('machine', metric), 5);
      expect(defaultStepKg('cable', metric), 5);
      expect(defaultStepKg('kettlebell', metric), 4);
      expect(defaultStepKg(null, metric), 2.5);
    });

    test('imperial: 5 lb', () {
      expect(imperial.lift(defaultStepKg('dumbbell', imperial)), '5 lb');
    });
  });

  group('inferStepKg — geçmişten tahmin', () {
    test('55 → 57,5 → 60: 2,5', () {
      expect(inferStepKg([55, 57.5, 60]), 2.5);
    });

    test('farklı artışlarda en küçüğü: 20 → 21,75 → 25', () {
      expect(inferStepKg([20, 21.75, 25]), 1.75);
    });

    test('ısınma sıçraması (20 → 55) sayılmaz', () {
      expect(inferStepKg([20, 55, 55]), isNull);
    });

    test('tek kilo ya da boş liste: tahmin yok', () {
      expect(inferStepKg([55, 55, 55]), isNull);
      expect(inferStepKg([]), isNull);
    });
  });

  group('applyStepKg', () {
    test('boş alanda öneriden başlar', () {
      expect(
        applyStepKg(current: null, base: 55, stepKg: 2.5, direction: 1),
        57.5,
      );
    });

    test('girilmiş değer öneriden önce gelir', () {
      expect(
        applyStepKg(current: 60, base: 55, stepKg: 2.5, direction: -1),
        57.5,
      );
    });

    test('kayan nokta gürültüsü temizlenir', () {
      expect(
        applyStepKg(current: 0.1, base: null, stepKg: 0.2, direction: 1),
        0.3,
      );
    });

    test('0 altına inmez', () {
      expect(
        applyStepKg(current: 1, base: null, stepKg: 2.5, direction: -1),
        0,
      );
    });
  });

  group('setRoutineExerciseRest — seanstan rutine', () {
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

    test('yalnız o rutinin o hareketi güncellenir', () async {
      final bench = await exercise('Bench');
      final squat = await exercise('Squat');
      final a = await db.workoutDao.createRoutine(
        RoutinesCompanion.insert(name: 'A', createdAt: DateTime(2026)),
      );
      final b = await db.workoutDao.createRoutine(
        RoutinesCompanion.insert(name: 'B', createdAt: DateTime(2026)),
      );
      for (final (r, e) in [(a, bench), (a, squat), (b, bench)]) {
        await db.workoutDao.addRoutineExercise(
          RoutineExercisesCompanion.insert(
            routineId: r,
            exerciseId: e,
            targetRestSec: const Value(90),
          ),
        );
      }

      final n = await db.workoutDao.setRoutineExerciseRest(
        routineId: a,
        exerciseId: bench,
        restSec: 120,
      );
      expect(n, 1);

      int? rest(List<RoutineExerciseWithExercise> l, int ex) => l
          .firstWhere((it) => it.exercise.id == ex)
          .routineExercise
          .targetRestSec;
      final ra = await db.workoutDao.getRoutineExercises(a);
      final rb = await db.workoutDao.getRoutineExercises(b);
      expect(rest(ra, bench), 120);
      expect(rest(ra, squat), 90);
      expect(rest(rb, bench), 90);
    });

    test('aynı değer yeniden yazılmaz (senkron kuyruğu boşuna dolmasın)',
        () async {
      final bench = await exercise('Bench');
      final r = await db.workoutDao.createRoutine(
        RoutinesCompanion.insert(name: 'A', createdAt: DateTime(2026)),
      );
      await db.workoutDao.addRoutineExercise(
        RoutineExercisesCompanion.insert(
          routineId: r,
          exerciseId: bench,
          targetRestSec: const Value(90),
        ),
      );
      final n = await db.workoutDao.setRoutineExerciseRest(
        routineId: r,
        exerciseId: bench,
        restSec: 90,
      );
      expect(n, 0);
    });

    test('süresi boş (varsayılan) satır da yazılır', () async {
      final bench = await exercise('Bench');
      final r = await db.workoutDao.createRoutine(
        RoutinesCompanion.insert(name: 'A', createdAt: DateTime(2026)),
      );
      await db.workoutDao.addRoutineExercise(
        RoutineExercisesCompanion.insert(routineId: r, exerciseId: bench),
      );
      expect(
        await db.workoutDao.setRoutineExerciseRest(
          routineId: r,
          exerciseId: bench,
          restSec: 60,
        ),
        1,
      );
    });
  });
}
