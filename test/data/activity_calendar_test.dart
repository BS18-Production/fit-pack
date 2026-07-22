import 'package:drift/drift.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/nutrition_dao.dart';
import 'package:fit_pack/features/activity/activity_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Aktivite takvimi Faz A — veri katmanı (docs/10-activity-calendar.md).
void main() {
  group('Toplu DAO sorguları', () {
    late AppDatabase db;
    setUp(() => db = newTestDatabase());
    tearDown(() => db.close());

    Future<int> addFood() async {
      await db.nutritionDao.insertFood(const FoodsCompanion(
        name: Value('Yulaf'),
        kcalPer100g: Value(380),
        proteinPer100g: Value(13),
        carbPer100g: Value(60),
        fatPer100g: Value(7),
      ));
      return (await db.nutritionDao.getAllFoods()).first.id;
    }

    Future<void> log(int foodId, DateTime date,
        {double kcal = 300, double protein = 20}) {
      return db.nutritionDao.insertFoodLog(FoodLogsCompanion(
        date: Value(date),
        mealType: const Value('breakfast'),
        foodId: Value(foodId),
        grams: const Value(100),
        computedKcal: Value(kcal),
        computedProtein: Value(protein),
        computedCarb: const Value(40),
        computedFat: const Value(5),
      ));
    }

    test('getDailyTotalsInRange: aynı günün loglarını toplar', () async {
      final f = await addFood();
      await log(f, DateTime(2026, 6, 19, 8), kcal: 300, protein: 20);
      await log(f, DateTime(2026, 6, 19, 13), kcal: 500, protein: 30);
      await log(f, DateTime(2026, 6, 20, 9), kcal: 200, protein: 10);

      final totals = await db.nutritionDao.getDailyTotalsInRange(
          DateTime(2026, 6, 1), DateTime(2026, 6, 30, 23, 59));

      expect(totals[DateTime(2026, 6, 19)]!.kcal, 800);
      expect(totals[DateTime(2026, 6, 19)]!.protein, 50);
      expect(totals[DateTime(2026, 6, 20)]!.kcal, 200);
      expect(totals.containsKey(DateTime(2026, 6, 21)), isFalse);
    });

    test('getWaterInRange: gün → ml', () async {
      await db.nutritionDao.addWater(DateTime(2026, 6, 19), 1500);
      await db.nutritionDao.addWater(DateTime(2026, 6, 20), 2000);

      final water = await db.nutritionDao.getWaterInRange(
          DateTime(2026, 6, 1), DateTime(2026, 6, 30, 23, 59));
      expect(water[DateTime(2026, 6, 19)], 1500);
      expect(water[DateTime(2026, 6, 20)], 2000);
    });
  });

  group('buildMonthActivity (saf birleştirme)', () {
    test('makro + su + antrenman tek güne birleşir', () {
      final totals = {
        DateTime(2026, 6, 19): DailyNutrition(
            kcal: 800, protein: 50, carb: 80, fat: 10),
      };
      final water = {DateTime(2026, 6, 19): 1500};
      final sessions = [
        WorkoutSession(syncState: 0, 
          id: 1,
          date: DateTime(2026, 6, 19, 18),
          phase: 0,
          workoutType: 'Push Day',
          kneeStatus: 'normal',
          isDeload: false,
        ),
      ];
      final sets = {
        1: [
          WorkoutSet(syncState: 0, 
              id: 1,
              sessionId: 1,
              exerciseId: 1,
              setNumber: 1,
              weightKg: 60,
              reps: 8,
              isWarmup: false,
              setType: 'normal',
              isComplete: true),
        ],
      };

      final map = buildMonthActivity(
        year: 2026,
        month: 6,
        totals: totals,
        water: water,
        sessions: sessions,
        setsBySession: sets,
      );

      final d19 = map[19]!;
      expect(d19.kcal, 800);
      expect(d19.protein, 50);
      expect(d19.waterMl, 1500);
      expect(d19.hasWorkout, isTrue);
      expect(d19.workoutName, 'Push Day');
      expect(d19.volumeKg, 480); // 60×8
      expect(d19.setCount, 1);
      // veri olmayan günler haritada yok
      expect(map.containsKey(20), isFalse);
    });

    test('boş ay → boş harita', () {
      final map = buildMonthActivity(
        year: 2026,
        month: 6,
        totals: const {},
        water: const {},
        sessions: const [],
        setsBySession: const {},
      );
      expect(map, isEmpty);
    });

    test('farklı ayın seansı sızmaz', () {
      final sessions = [
        WorkoutSession(syncState: 0, 
          id: 1,
          date: DateTime(2026, 5, 19),
          phase: 0,
          workoutType: 'Push',
          kneeStatus: 'normal',
          isDeload: false,
        ),
      ];
      final map = buildMonthActivity(
        year: 2026,
        month: 6,
        totals: const {},
        water: const {},
        sessions: sessions,
        setsBySession: const {},
      );
      expect(map, isEmpty);
    });
  });
}
