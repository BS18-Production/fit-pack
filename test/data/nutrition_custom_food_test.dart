import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Kullanıcının "Kendi yemeğin" akışının veri yolunu doğrular:
/// porsiyon → /100g dönüşümü, kalıcılık, join ile geri okuma.
void main() {
  late AppDatabase db;
  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  test('Custom food: porsiyon → /100g dönüşür ve kalıcı olur', () async {
    final dao = db.nutritionDao;

    // Diyalog mantığı: "3 Yumurtalı Omlet", 220 g porsiyon, 320 kcal,
    // 22 P, 3 K, 24 Y  →  /100g'a çevrilir (factor = 100/220).
    const portion = 220.0;
    final f = 100 / portion;
    final id = await dao.insertFood(FoodsCompanion(
      name: const Value('3 Yumurtalı Omlet'),
      kcalPer100g: Value(320 * f),
      proteinPer100g: Value(22 * f),
      carbPer100g: Value(3 * f),
      fatPer100g: Value(24 * f),
      source: const Value('custom'),
      isCustom: const Value(true),
      isRecipe: const Value(false),
    ));

    final food = await dao.getFoodById(id);
    expect(food, isNotNull);
    expect(food!.isCustom, isTrue);
    expect(food.name, '3 Yumurtalı Omlet');
    // 220 g tekrar yenince porsiyon değerleri geri gelmeli.
    final ratio = portion / 100;
    expect((food.kcalPer100g * ratio).round(), 320);
    expect((food.proteinPer100g * ratio).round(), 22);
    expect((food.fatPer100g * ratio).round(), 24);
  });

  test('Custom food loglanır ve join ile adıyla geri okunur', () async {
    final dao = db.nutritionDao;
    final id = await dao.insertFood(const FoodsCompanion(
      name: Value('1 Avokado'),
      kcalPer100g: Value(160),
      proteinPer100g: Value(2),
      carbPer100g: Value(9),
      fatPer100g: Value(15),
      source: Value('custom'),
      isCustom: Value(true),
      isRecipe: Value(false),
    ));

    final today = DateTime.now();
    await dao.insertFoodLog(FoodLogsCompanion(
      date: Value(today),
      mealType: const Value('breakfast'),
      foodId: Value(id),
      grams: const Value(150),
      computedKcal: const Value(240),
      computedProtein: const Value(3),
      computedCarb: const Value(13.5),
      computedFat: const Value(22.5),
    ));

    final rows = await dao.getLogsWithFoodForDate(today);
    expect(rows.length, 1);
    expect(rows.first.food.name, '1 Avokado');
    expect(rows.first.log.grams, 150);
    expect(rows.first.log.computedKcal, 240);
  });
}
