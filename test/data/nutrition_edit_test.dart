import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_database.dart';

void main() {
  test('miktar aynı kimlikte atomik güncellenir; kuyruk ve toplam doğru', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final dao = db.nutritionDao;
    final food = await dao.insertFood(FoodsCompanion.insert(name: 'Yoğurt',
      kcalPer100g: 65, proteinPer100g: 4, carbPer100g: 5, fatPer100g: 3));
    final day = DateTime(2026, 10, 18);
    final id = await dao.insertFoodLog(FoodLogsCompanion.insert(date: day,
      mealType: 'lunch', foodId: food, grams: 100,
      computedKcal: 65, computedProtein: 4, computedCarb: 5, computedFat: 3));
    final before = (await dao.getLogsForDate(day)).single;
    // Sunucuya gönderilmiş kayıt da UPDATE ile yeniden kuyruğa girmeli.
    await (db.update(db.foodLogs)..where((r) => r.id.equals(id)))
      .write(const FoodLogsCompanion(syncState: Value(0)));
    await dao.updateFoodLogAmount(id, 250);
    final after = (await dao.getLogsForDate(day)).single;
    expect(after.id, id);
    expect(after.uid, before.uid);
    expect(after.date, before.date);
    expect(after.mealType, before.mealType);
    expect(after.foodId, food);
    expect(after.localSeq, greaterThan(before.localSeq ?? 0));
    expect(after.syncState, 1);
    expect(after.computedKcal, 162.5);
    expect(after.computedProtein, 10);
    expect(after.computedCarb, 12.5);
    expect(after.computedFat, 7.5);
    expect((await dao.getDailyTotals(day)).kcal, 162.5);
    for (final invalid in [0.0, -1.0, double.nan, double.infinity, 5001.0]) {
      await expectLater(dao.updateFoodLogAmount(id, invalid), throwsArgumentError);
    }
    expect((await dao.getLogsForDate(day)).single.grams, 250);
  });
}
