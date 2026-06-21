import 'package:drift/drift.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/seed/exercises_seed.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Antrenman V2 Faz A — hareket kütüphanesi (docs/09-workout-v2.md).
void main() {
  group('Hareket seed bütünlüğü', () {
    test('5 kategori de mevcut + makul sayıda hareket', () {
      final cats = exerciseSeedData.map((e) => e.category).toSet();
      expect(cats, containsAll(
          ['compound', 'isolation', 'calisthenics', 'cardio', 'flexibility']));
      expect(exerciseSeedData.length, greaterThanOrEqualTo(90));
    });

    test('her hareketin geçerli ölçüm tipi + ekipmanı var', () {
      const validMeasure = {'weight_reps', 'reps', 'time', 'distance'};
      for (final e in exerciseSeedData) {
        expect(validMeasure.contains(e.measurement), isTrue,
            reason: '${e.name} ölçüm tipi geçersiz: ${e.measurement}');
        expect(e.equipment.isNotEmpty, isTrue, reason: '${e.name} ekipman boş');
        expect(e.primaryMuscle.isNotEmpty, isTrue);
      }
    });

    test('isim tekrarı yok', () {
      final names = exerciseSeedData.map((e) => e.name).toList();
      expect(names.toSet().length, names.length);
    });
  });

  group('Kütüphane DAO', () {
    late AppDatabase db;
    setUp(() => db = newTestDatabase());
    tearDown(() => db.close());

    test('getLibraryExercises: özel hareket üstte, arşivli gelmez', () async {
      await db.workoutDao.insertExercises([
        ExercisesCompanion(
            name: const Value('Zztandart'),
            category: const Value('compound'),
            muscleGroups: const Value('["chest"]'),
            equipment: const Value('barbell'),
            measurementType: const Value('weight_reps')),
        ExercisesCompanion(
            name: const Value('Aacustom'),
            category: const Value('isolation'),
            muscleGroups: const Value('["biceps"]'),
            equipment: const Value('dumbbell'),
            measurementType: const Value('weight_reps'),
            isCustom: const Value(true)),
      ]);
      final lib = await db.workoutDao.getLibraryExercises();
      expect(lib.first.name, 'Aacustom'); // custom üstte
      expect(lib, hasLength(2));

      // Arşivle → listede görünmez.
      await db.workoutDao.archiveExercise(lib.first.id);
      final after = await db.workoutDao.getLibraryExercises();
      expect(after.any((e) => e.name == 'Aacustom'), isFalse);
      expect(after, hasLength(1));
    });
  });
}
