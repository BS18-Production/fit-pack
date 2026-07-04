import 'package:drift/drift.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Batch 2 — H-01 regresyonu: tarih aralıkları [start, end) olmalı.
/// Tam gece yarısına yazılan kayıtlar (tarih seçiciyle geçmişe giriş,
/// "dünü kopyala") YALNIZ kendi gününe sayılmalı; eski `BETWEEN` (iki uç
/// dahil) bunları bir önceki günün toplamına da katıyordu.
void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  Future<int> insertFood() => db.nutritionDao.insertFood(const FoodsCompanion(
        name: Value('Test Yemeği'),
        kcalPer100g: Value(100),
        proteinPer100g: Value(10),
        carbPer100g: Value(10),
        fatPer100g: Value(5),
        source: Value('local'),
        isCustom: Value(false),
        isRecipe: Value(false),
      ));

  Future<void> logAt(int foodId, DateTime date) =>
      db.nutritionDao.insertFoodLog(FoodLogsCompanion(
        date: Value(date),
        mealType: const Value('lunch'),
        foodId: Value(foodId),
        grams: const Value(100),
        computedKcal: const Value(100),
        computedProtein: const Value(10),
        computedCarb: const Value(10),
        computedFat: const Value(5),
      ));

  group('yemek kayıtları gün sınırı (H-01)', () {
    test('gece yarısı kaydı yalnız kendi gününe sayılır', () async {
      final foodId = await insertFood();
      // 2 Temmuz TAM gece yarısı — tarih seçici / "dünü kopyala" böyle yazar.
      await logAt(foodId, DateTime(2026, 7, 2));
      // 1 Temmuz gün içi normal kayıt.
      await logAt(foodId, DateTime(2026, 7, 1, 13, 30));

      final day1 = await db.nutritionDao.getDailyTotals(DateTime(2026, 7, 1));
      final day2 = await db.nutritionDao.getDailyTotals(DateTime(2026, 7, 2));

      expect(day1.kcal, 100,
          reason: '2 Temmuz 00:00 kaydı 1 Temmuz\'a SAYILMAMALI');
      expect(day2.kcal, 100);

      expect(
          await db.nutritionDao.getLogsWithFoodForDate(DateTime(2026, 7, 1)),
          hasLength(1));
      expect(
          await db.nutritionDao.getLogsWithFoodForDate(DateTime(2026, 7, 2)),
          hasLength(1));
    });

    test('copyDayLogs sonrası kaynak günün toplamı değişmez', () async {
      final foodId = await insertFood();
      await logAt(foodId, DateTime(2026, 7, 1, 9));
      await logAt(foodId, DateTime(2026, 7, 1, 19));

      final before =
          await db.nutritionDao.getDailyTotals(DateTime(2026, 7, 1));
      final copied = await db.nutritionDao
          .copyDayLogs(DateTime(2026, 7, 1), DateTime(2026, 7, 2));
      expect(copied, 2);

      final after = await db.nutritionDao.getDailyTotals(DateTime(2026, 7, 1));
      expect(after.kcal, before.kcal,
          reason: 'Kopya hedef günde; kaynak günün toplamı şişmemeli');
      expect(
          (await db.nutritionDao.getDailyTotals(DateTime(2026, 7, 2))).kcal,
          before.kcal);
    });
  });

  group('seans aralıkları gün sınırı (H-01)', () {
    test('aralık bitişindeki kayıt bir önceki döneme sayılmaz', () async {
      // Pazartesi 00:00 başlayan hafta: [pzt, sonraki pzt) — sonraki
      // pazartesi tam gece yarısındaki seans YENİ haftaya ait.
      final monday = DateTime(2026, 6, 29);
      final nextMonday = DateTime(2026, 7, 6);
      await db.workoutDao.insertSession(WorkoutSessionsCompanion(
        date: Value(DateTime(2026, 7, 1, 18)),
        phase: const Value(0),
        workoutType: const Value('Bu Hafta'),
      ));
      await db.workoutDao.insertSession(WorkoutSessionsCompanion(
        date: Value(nextMonday), // tam gece yarısı
        phase: const Value(0),
        workoutType: const Value('Gelecek Hafta'),
      ));

      final week =
          await db.workoutDao.getSessionsByDateRange(monday, nextMonday);
      expect(week, hasLength(1));
      expect(week.single.workoutType, 'Bu Hafta');
      expect(await db.workoutDao.getSessionCountInRange(monday, nextMonday), 1);
    });
  });
}
