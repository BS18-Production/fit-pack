import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/nutrition/macro_goals.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Premium cila sprint'inin veri yolu testleri: makro hedef türetme,
/// son kullanılanlar, dünü kopyala, son seans (ghost) sorgusu.
void main() {
  group('deriveMacroGoals', () {
    test('2200 kcal / 180 g protein → karb+yağ kaloriyi tamamlar', () {
      final d = deriveMacroGoals(kcalGoal: 2200, proteinGoal: 180);
      expect(d.fat, greaterThan(0));
      expect(d.carb, greaterThan(0));
      final totalKcal = 180 * 4 + d.carb * 4 + d.fat * 9;
      // Yuvarlama payı: ±20 kcal içinde hedefi tutturmalı.
      expect((totalKcal - 2200).abs(), lessThanOrEqualTo(20));
    });

    test('protein kaloriyi aşarsa karb 0 olur, negatif olmaz', () {
      final d = deriveMacroGoals(kcalGoal: 800, proteinGoal: 200);
      expect(d.carb, 0);
      expect(d.fat, greaterThan(0));
    });
  });

  group('NutritionDao', () {
    late AppDatabase db;
    setUp(() => db = newTestDatabase());
    tearDown(() => db.close());

    Future<int> seedFood(String name) =>
        db.nutritionDao.insertFood(FoodsCompanion(
          name: Value(name),
          kcalPer100g: const Value(100),
          proteinPer100g: const Value(10),
          carbPer100g: const Value(10),
          fatPer100g: const Value(2),
        ));

    Future<void> log(int foodId, DateTime date) =>
        db.nutritionDao.insertFoodLog(FoodLogsCompanion(
          date: Value(date),
          mealType: const Value('lunch'),
          foodId: Value(foodId),
          grams: const Value(100),
          computedKcal: const Value(100),
          computedProtein: const Value(10),
          computedCarb: const Value(10),
          computedFat: const Value(2),
        ));

    test('getRecentFoods: en son eklenen önce, tekrarlar tek', () async {
      final a = await seedFood('Yumurta');
      final b = await seedFood('Ekmek');
      final now = DateTime(2026, 6, 10, 12);
      await log(a, now);
      await log(b, now);
      await log(a, now); // tekrar — listede bir kez, en üstte
      final recents = await db.nutritionDao.getRecentFoods();
      expect(recents.map((f) => f.id).toList(), [a, b]);
    });

    test('copyDayLogs: dünün kayıtları bugüne kopyalanır', () async {
      final a = await seedFood('Yumurta');
      final yesterday = DateTime(2026, 6, 10, 9);
      final today = DateTime(2026, 6, 11);
      await log(a, yesterday);
      await log(a, yesterday);

      final copied =
          await db.nutritionDao.copyDayLogs(yesterday, today);
      expect(copied, 2);
      final todayLogs = await db.nutritionDao.getLogsForDate(today);
      expect(todayLogs.length, 2);
      expect(todayLogs.first.computedKcal, 100);
    });

    test('copyDayLogs: kaynak gün boşsa 0 döner, hedefe yazmaz', () async {
      final from = DateTime(2026, 6, 1);
      final to = DateTime(2026, 6, 2);
      expect(await db.nutritionDao.copyDayLogs(from, to), 0);
      expect(await db.nutritionDao.getLogsForDate(to), isEmpty);
    });
  });

  group('WorkoutDao.getLastSessionWithSets', () {
    late AppDatabase db;
    setUp(() => db = newTestDatabase());
    tearDown(() => db.close());

    test('tip bazlı son seansı setleriyle döner', () async {
      final dao = db.workoutDao;
      await dao.insertExercise(const ExercisesCompanion(
        name: Value('Bench Press'),
        category: Value('compound'),
        muscleGroups: Value('chest'),
      ));
      final ex = (await dao.getAllExercises()).first;

      Future<int> session(String type, DateTime date) =>
          dao.insertSession(WorkoutSessionsCompanion(
            date: Value(date),
            phase: const Value(1),
            workoutType: Value(type),
            kneeStatus: const Value('normal'),
            energy: const Value(5),
            rpe: const Value(5),
          ));

      final old = await session('FullA', DateTime(2026, 6, 1));
      final newer = await session('FullA', DateTime(2026, 6, 8));
      await session('FullB', DateTime(2026, 6, 9)); // farklı tip — gelmemeli

      await dao.insertSet(WorkoutSetsCompanion(
        sessionId: Value(old),
        exerciseId: Value(ex.id),
        setNumber: const Value(1),
        weightKg: const Value(50),
        reps: const Value(10),
      ));
      await dao.insertSet(WorkoutSetsCompanion(
        sessionId: Value(newer),
        exerciseId: Value(ex.id),
        setNumber: const Value(1),
        weightKg: const Value(60),
        reps: const Value(8),
      ));

      final result = await dao.getLastSessionWithSets('FullA');
      expect(result, isNotNull);
      expect(result!.$1.id, newer);
      expect(result.$2.single.weightKg, 60);

      expect(await dao.getLastSessionWithSets('Cardio'), isNull);
    });
  });
}
