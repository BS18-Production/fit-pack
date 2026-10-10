import 'package:drift/native.dart';
import 'package:fit_pack/core/ids/deterministic_uid.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/nutrition_dao.dart';
import 'package:flutter_test/flutter_test.dart';

/// Beslenme günü tamamlandı (docs/37, #8) — DAO kuralları.
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  final day = DateTime(2026, 10, 10, 21, 30);

  test('gün anahtarı yerel takvim günü, sıfır dolgulu', () {
    expect(NutritionDao.dayKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
  });

  test('kimlik belirlenimci: iki cihaz aynı günü aynı uid ile yazar', () {
    expect(nutritionDayUid('2026-10-10'), nutritionDayUid('2026-10-10'));
    expect(nutritionDayUid('2026-10-10'), isNot(nutritionDayUid('2026-10-11')));
    // UUIDv5 biçimi: 3. grubun ilk hanesi 5.
    expect(nutritionDayUid('2026-10-10'),
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab]')));
  });

  test('işaretle → satır tarihten türeyen uid ile, durum complete', () async {
    await db.nutritionDao.markDayComplete(day, now: DateTime(2026, 10, 10, 22));
    final row = (await db.select(db.nutritionDays).get()).single;
    expect(row.day, '2026-10-10');
    expect(row.status, 'complete');
    expect(row.uid, nutritionDayUid('2026-10-10'),
        reason: 'tetikleyici verilen uid\'i korumalı (COALESCE)');
    expect(row.completedAtMs, DateTime(2026, 10, 10, 22).millisecondsSinceEpoch);
  });

  test('çift dokunuş tek satır', () async {
    await Future.wait([
      db.nutritionDao.markDayComplete(day),
      db.nutritionDao.markDayComplete(day),
    ]);
    expect(await db.select(db.nutritionDays).get(), hasLength(1));
  });

  test('geri al silmez; yeniden işaretlemek aynı satırı kullanır', () async {
    await db.nutritionDao.markDayComplete(day);
    await db.nutritionDao.reopenDay(day);
    var rows = await db.select(db.nutritionDays).get();
    expect(rows.single.status, 'open');
    expect(rows.single.completedAtMs, isNull);
    final tombstones =
        await db.customSelect('SELECT * FROM sync_tombstones').get();
    expect(tombstones, isEmpty, reason: 'geri al mezar taşı üretmemeli');

    await db.nutritionDao.markDayComplete(day);
    rows = await db.select(db.nutritionDays).get();
    expect(rows.single.status, 'complete');
    expect(rows.single.uid, nutritionDayUid('2026-10-10'));
  });

  test('tamamlanmış günler [start, end) aralığıyla', () async {
    await db.nutritionDao.markDayComplete(DateTime(2026, 10, 5));
    await db.nutritionDao.markDayComplete(DateTime(2026, 10, 6));
    await db.nutritionDao.markDayComplete(DateTime(2026, 10, 12));
    await db.nutritionDao.reopenDay(DateTime(2026, 10, 6));
    final s = await db.nutritionDao
        .getCompletedDays(DateTime(2026, 10, 5), DateTime(2026, 10, 12));
    expect(s, {'2026-10-05'}, reason: 'açılan gün ve bitiş günü hariç');
  });

  test('tamamlandıktan sonra kayıt eklenirse "sonra değişti"', () async {
    final foodId = await db.nutritionDao.insertFood(FoodsCompanion.insert(
      name: 'Yumurta', kcalPer100g: 155, proteinPer100g: 13,
      carbPer100g: 1, fatPer100g: 11));
    // Tamamlanma anı geçmişte sabit: kayıt tetikleyicisi gerçek saati yazar.
    await db.nutritionDao.markDayComplete(day, now: DateTime(2020));
    expect(await db.nutritionDao.changedAfterComplete(day), isFalse);

    await db.nutritionDao.insertFoodLog(FoodLogsCompanion.insert(
      date: DateTime(2026, 10, 10, 12), mealType: 'lunch', foodId: foodId,
      grams: 100, computedKcal: 155, computedProtein: 13, computedCarb: 1,
      computedFat: 11));
    // Kaydın changed_at_ms'i şimdiki saat (tetikleyici) → 2020'den sonra.
    expect(await db.nutritionDao.changedAfterComplete(day), isTrue);
  });
}
