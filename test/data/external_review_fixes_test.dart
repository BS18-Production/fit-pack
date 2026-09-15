import 'package:drift/drift.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Dış kod incelemesi (2026-09-15) bulgularının regresyon testleri.
/// Her test, raporun tarif ettiği somut başarısız senaryoyu canlandırır —
/// toplam test sayısını artırmak değil, o senaryonun bir daha oluşmadığını
/// göstermek için.
void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  // === #11 — kilo sorgusu ===
  group('#11 · kilosuz ölçüm son kiloyu gizlemez', () {
    test('yalnız bel çevresi girilen gün, dünkü kiloyu perdelemez', () async {
      final dun = DateTime(2026, 9, 14);
      final bugun = DateTime(2026, 9, 15);

      await db.bodyDao.insertMeasurement(BodyMeasurementsCompanion(
        date: Value(dun),
        weightKg: const Value(87.0),
      ));
      // Ölçüm formu tek alanla kaydetmeye izin veriyor → kilosuz satır.
      await db.bodyDao.insertMeasurement(BodyMeasurementsCompanion(
        date: Value(bugun),
        waistCm: const Value(82.0),
      ));

      final latest = await db.bodyDao.getLatestWeight();
      expect(latest?.weightKg, 87.0,
          reason: 'en son DOLU kilo dönmeli, en son satır değil');
    });

    test('hiç kilo girilmemişse null döner', () async {
      await db.bodyDao.insertMeasurement(BodyMeasurementsCompanion(
        date: Value(DateTime(2026, 9, 15)),
        waistCm: const Value(82.0),
      ));
      expect(await db.bodyDao.getLatestWeight(), null);
    });
  });

  // === #12 — "dünü kopyala" ===
  group('#12 · dünü kopyala', () {
    Future<int> yemekEkle() =>
        db.nutritionDao.insertFood(const FoodsCompanion(
          name: Value('Test Yemeği'),
          kcalPer100g: Value(100),
          proteinPer100g: Value(10),
          carbPer100g: Value(10),
          fatPer100g: Value(5),
          source: Value('local'),
          isCustom: Value(false),
          isRecipe: Value(false),
        ));

    Future<void> logla(int foodId, DateTime gun) =>
        db.nutritionDao.insertFoodLog(FoodLogsCompanion(
          date: Value(gun),
          mealType: const Value('lunch'),
          foodId: Value(foodId),
          grams: const Value(100),
          computedKcal: const Value(100),
          computedProtein: const Value(10),
          computedCarb: const Value(10),
          computedFat: const Value(5),
        ));

    test('normal kopyalama çalışır', () async {
      final f = await yemekEkle();
      final dun = DateTime(2026, 9, 14);
      final bugun = DateTime(2026, 9, 15);
      await logla(f, dun);
      await logla(f, dun);

      expect(await db.nutritionDao.copyDayLogs(dun, bugun), 2);
      expect((await db.nutritionDao.getLogsForDate(bugun)).length, 2);
    });

    test('hedef gün doluysa ikinci kopyalama HİÇBİR ŞEY eklemez', () async {
      final f = await yemekEkle();
      final dun = DateTime(2026, 9, 14);
      final bugun = DateTime(2026, 9, 15);
      await logla(f, dun);
      await logla(f, dun);

      // Hızlı iki dokunuş: ekran daha tazelenmeden ikinci çağrı gelir.
      final ilk = await db.nutritionDao.copyDayLogs(dun, bugun);
      final ikinci = await db.nutritionDao.copyDayLogs(dun, bugun);

      expect(ilk, 2);
      expect(ikinci, 0, reason: 'hedef doluyken kopyalama yapılmamalı');
      expect((await db.nutritionDao.getLogsForDate(bugun)).length, 2,
          reason: 'öğünler ikiye katlanmamalı');
    });

    test('kaynak gün boşsa 0 döner, hedefe dokunulmaz', () async {
      final bos = DateTime(2026, 9, 10);
      final hedef = DateTime(2026, 9, 11);
      expect(await db.nutritionDao.copyDayLogs(bos, hedef), 0);
      expect((await db.nutritionDao.getLogsForDate(hedef)), isEmpty);
    });
  });

  // === #8 — su kaydı ===
  group('#8 · su kaydı çoklu satıra dayanıklı', () {
    test('aynı güne iki satır düşerse okuma ÇÖKMEZ, toplar', () async {
      final gun = DateTime(2026, 9, 15);
      // İki cihazın ayrı uid'lerle açtığı satırların indirme sonrası hâli.
      await db.into(db.waterIntake).insert(
          WaterIntakeCompanion.insert(date: gun, amountMl: const Value(500)));
      await db.into(db.waterIntake).insert(
          WaterIntakeCompanion.insert(date: gun, amountMl: const Value(300)));

      expect(await db.nutritionDao.getWaterForDay(gun), 800,
          reason: 'tek satır sorgusu fırlatıyordu; toplam dönmeli');
    });

    test('aralık sorgusu aynı günün satırlarını ezmez, toplar', () async {
      final gun = DateTime(2026, 9, 15);
      await db.into(db.waterIntake).insert(
          WaterIntakeCompanion.insert(date: gun, amountMl: const Value(500)));
      await db.into(db.waterIntake).insert(
          WaterIntakeCompanion.insert(date: gun, amountMl: const Value(300)));

      final aralik = await db.nutritionDao
          .getWaterInRange(DateTime(2026, 9, 1), DateTime(2026, 10, 1));
      expect(aralik[gun], 800);
    });

    test('çoklu satır varken ekleme toplamı tek satırda birleştirir', () async {
      final gun = DateTime(2026, 9, 15);
      await db.into(db.waterIntake).insert(
          WaterIntakeCompanion.insert(date: gun, amountMl: const Value(500)));
      await db.into(db.waterIntake).insert(
          WaterIntakeCompanion.insert(date: gun, amountMl: const Value(300)));

      expect(await db.nutritionDao.addWater(gun, 200), 1000);
      expect(await db.nutritionDao.getWaterForDay(gun), 1000,
          reason: 'artış yutulmamalı, toplam iki kez sayılmamalı');
    });

    test('ardışık eklemeler kaybolmaz', () async {
      final gun = DateTime(2026, 9, 15);
      await db.nutritionDao.addWater(gun, 250);
      await db.nutritionDao.addWater(gun, 250);
      await db.nutritionDao.addWater(gun, 250);
      expect(await db.nutritionDao.getWaterForDay(gun), 750);
    });

    test('negatif ekleme 0 altına düşmez', () async {
      final gun = DateTime(2026, 9, 15);
      await db.nutritionDao.addWater(gun, 250);
      expect(await db.nutritionDao.addWater(gun, -500), 0);
    });
  });
}
