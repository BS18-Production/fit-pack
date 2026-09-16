import 'package:drift/drift.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/seed/exercises_seed.dart';
import 'package:fit_pack/features/workout/workout_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Seed'de adı [name] olan hareketin Türkçe/İngilizce [query] ile bulunup
/// bulunmadığını döndürür (kütüphane arama mantığının aynısı).
bool _seedMatches(String name, String query) {
  final e = exerciseSeedData.firstWhere((x) => x.name == name);
  final hay = WorkoutUi.searchHaystack(
    name: e.name,
    category: e.category,
    primaryMuscle: e.primaryMuscle,
    equipment: e.equipment,
    muscles: e.muscles,
  );
  return WorkoutUi.matchesQuery(hay, query);
}

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

    test('zengin kütüphane: MacFit/TR salonu makineleri mevcut', () {
      final names = exerciseSeedData.map((e) => e.name).toSet();
      // Kullanıcının salonda göreceği makineler hazır gelmeli.
      const mustHave = [
        'Hip Abduction Machine', 'Hip Adduction Machine', 'Pendulum Squat',
        'Iso-Lateral Row', 'Machine Shoulder Press', 'Pec Deck',
        'Leg Press', 'Hack Squat', 'Cable Crossover', 'Face Pull',
        'Ab Crunch Machine', 'Smith Machine Squat', 'Assisted Pull-Up Machine',
        'Standing Calf Raise', 'Rope Tricep Pushdown',
      ];
      for (final m in mustHave) {
        expect(names.contains(m), isTrue, reason: '$m kütüphanede yok');
      }
      expect(exerciseSeedData.length, greaterThanOrEqualTo(140));
    });
  });

  group('Rutin dinlenme süresi (targetRestSec)', () {
    late AppDatabase db;
    setUp(() => db = newTestDatabase());
    tearDown(() => db.close());

    test('rutine girilen dinlenme süresi kaydedilir ve geri okunur', () async {
      await db.workoutDao.insertExercise(ExercisesCompanion(
        name: const Value('Test Press'),
        category: const Value('compound'),
        muscleGroups: const Value('["chest"]'),
        equipment: const Value('barbell'),
        measurementType: const Value('weight_reps'),
      ));
      final exId = (await db.workoutDao.getAllExercises())
          .firstWhere((e) => e.name == 'Test Press')
          .id;
      final routineId = await db.workoutDao.createRoutine(
        RoutinesCompanion(name: const Value('Push'), createdAt: Value(DateTime(2026))),
      );
      await db.workoutDao.addRoutineExercise(RoutineExercisesCompanion(
        routineId: Value(routineId),
        exerciseId: Value(exId),
        orderIndex: const Value(0),
        targetSets: const Value(4),
        targetRestSec: const Value(180), // kullanıcı 3 dk seçti
      ));

      final items = await db.workoutDao.getRoutineExercises(routineId);
      expect(items, hasLength(1));
      expect(items.first.routineExercise.targetRestSec, 180);
    });
  });

  group('Kategoriye göre varsayılan dinlenme', () {
    // G-3: kuvvet hareketlerinde 60 sn (bileşikte 180 pratikte uzundu),
    // esneme 30 sn.
    test('kuvvet 60 sn, esneme 30 sn', () {
      expect(WorkoutUi.defaultRestSec('compound'), 60);
      expect(WorkoutUi.defaultRestSec('isolation'), 60);
      expect(WorkoutUi.defaultRestSec('calisthenics'), 60);
      expect(WorkoutUi.defaultRestSec('cardio'), 60);
      expect(WorkoutUi.defaultRestSec('flexibility'), 30);
      expect(WorkoutUi.defaultRestSec('bilinmeyen'), 60);
    });
    test('restLabel: 0 → Yok, 90 → 1:30', () {
      expect(WorkoutUi.restLabel(0, none: 'Yok'), 'Yok');
      expect(WorkoutUi.restLabel(null, none: 'Yok'), 'Yok');
      expect(WorkoutUi.restLabel(90, none: 'Yok'), '1:30');
      expect(WorkoutUi.restLabel(180, none: 'Yok'), '3:00');
    });
  });

  group('Türkçe arama', () {
    test('Türkçe kas adıyla bulunur (göğüs / bacak / arka kol / kalça)', () {
      expect(_seedMatches('Chest Press Machine', 'göğüs'), isTrue);
      expect(_seedMatches('Leg Press', 'bacak'), isTrue);
      expect(_seedMatches('Tricep Pushdown', 'arka kol'), isTrue);
      expect(_seedMatches('Hip Thrust', 'kalça'), isTrue);
      expect(_seedMatches('Standing Calf Raise', 'baldır'), isTrue);
    });

    test('Türkçe ekipman adıyla bulunur (makine / halter / kablo)', () {
      expect(_seedMatches('Leg Extension', 'makine'), isTrue);
      expect(_seedMatches('Barbell Back Squat', 'halter'), isTrue);
      expect(_seedMatches('Cable Crossover', 'kablo'), isTrue);
    });

    test('Türkçe karakter ve büyük/küçük harf duyarsız', () {
      expect(_seedMatches('Leg Press', 'BACAK'), isTrue);
      expect(_seedMatches('Hip Thrust', 'kalca'), isTrue); // çevirisiz
      expect(_seedMatches('Chest Press Machine', 'gogus'), isTrue);
    });

    test('İngilizce ad parçasıyla da bulunur', () {
      expect(_seedMatches('Bulgarian Split Squat', 'split'), isTrue);
      expect(_seedMatches('Romanian Deadlift', 'deadlift'), isTrue);
    });

    test('çoklu kelime AND mantığı (hepsi eşleşmeli)', () {
      // "makine bacak" → makine ekipmanlı bacak hareketi
      expect(_seedMatches('Leg Press', 'makine bacak'), isTrue);
      // alakasız kombinasyon eşleşmez
      expect(_seedMatches('Leg Press', 'göğüs kablo'), isFalse);
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
