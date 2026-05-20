import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Beslenme V2 veri yolu (docs/07-nutrition-v2.md §4, §5, §8):
/// birim alanları, gram dönüşümü, seed bütünlüğü, DAO update/delete.
void main() {
  late AppDatabase db;
  setUp(() => db = newTestDatabase());
  tearDown(() => db.close());

  test('Yemek birim alanlarıyla kalıcı (adet, defaultPortionGrams)',
      () async {
    final dao = db.nutritionDao;
    final id = await dao.insertFood(const FoodsCompanion(
      name: Value('Yumurta (Haşlanmış)'),
      kcalPer100g: Value(155),
      proteinPer100g: Value(13),
      carbPer100g: Value(1.1),
      fatPer100g: Value(11),
      defaultPortionGrams: Value(50),
      unitLabel: Value('adet'),
    ));
    final f = await dao.getFoodById(id);
    expect(f, isNotNull);
    expect(f!.unitLabel, 'adet');
    expect(f.defaultPortionGrams, 50);
  });

  test('Birim → gram dönüşümü: 3 adet × 50 g = 150 g, kcal doğru',
      () async {
    final dao = db.nutritionDao;
    final id = await dao.insertFood(const FoodsCompanion(
      name: Value('Yumurta'),
      kcalPer100g: Value(155),
      proteinPer100g: Value(13),
      carbPer100g: Value(1.1),
      fatPer100g: Value(11),
      defaultPortionGrams: Value(50),
      unitLabel: Value('adet'),
    ));
    final food = (await dao.getFoodById(id))!;

    // UI mantığı: gram = adet × defaultPortionGrams; makro = /100g × gram/100.
    const units = 3.0;
    final grams = units * food.defaultPortionGrams!;
    expect(grams, 150);
    final ratio = grams / 100;
    await dao.insertFoodLog(FoodLogsCompanion(
      date: Value(DateTime.now()),
      mealType: const Value('breakfast'),
      foodId: Value(id),
      grams: Value(grams),
      computedKcal: Value(food.kcalPer100g * ratio),
      computedProtein: Value(food.proteinPer100g * ratio),
      computedCarb: Value(food.carbPer100g * ratio),
      computedFat: Value(food.fatPer100g * ratio),
    ));

    final totals = await dao.getDailyTotals(DateTime.now());
    expect(totals.kcal.round(), 233); // 155 × 1.5
    expect(totals.protein.round(), 20); // 13 × 1.5 ≈ 19.5
  });

  test('updateFood custom yemeği günceller', () async {
    final dao = db.nutritionDao;
    final id = await dao.insertFood(const FoodsCompanion(
      name: Value('Ev Omleti'),
      kcalPer100g: Value(140),
      proteinPer100g: Value(10),
      carbPer100g: Value(2),
      fatPer100g: Value(10),
      source: Value('custom'),
      isCustom: Value(true),
      unitLabel: Value('porsiyon'),
      defaultPortionGrams: Value(200),
    ));
    final ok = await dao.updateFood(
      id,
      const FoodsCompanion(
        name: Value('Ev Omleti (3 yumurta)'),
        kcalPer100g: Value(160),
        defaultPortionGrams: Value(220),
      ),
    );
    expect(ok, isTrue);
    final f = (await dao.getFoodById(id))!;
    expect(f.name, 'Ev Omleti (3 yumurta)');
    expect(f.kcalPer100g, 160);
    expect(f.defaultPortionGrams, 220);
    expect(f.unitLabel, 'porsiyon'); // dokunulmayan alan korunur
  });

  test('foodLogCount + deleteFood: loglu yemek korunur, logsuz silinir',
      () async {
    final dao = db.nutritionDao;
    final used = await dao.insertFood(const FoodsCompanion(
      name: Value('Loglu Yemek'),
      kcalPer100g: Value(100),
      proteinPer100g: Value(5),
      carbPer100g: Value(5),
      fatPer100g: Value(5),
      isCustom: Value(true),
    ));
    final unused = await dao.insertFood(const FoodsCompanion(
      name: Value('Boşta Yemek'),
      kcalPer100g: Value(100),
      proteinPer100g: Value(5),
      carbPer100g: Value(5),
      fatPer100g: Value(5),
      isCustom: Value(true),
    ));
    await dao.insertFoodLog(FoodLogsCompanion(
      date: Value(DateTime.now()),
      mealType: const Value('lunch'),
      foodId: Value(used),
      grams: const Value(100),
      computedKcal: const Value(100),
      computedProtein: const Value(5),
      computedCarb: const Value(5),
      computedFat: const Value(5),
    ));

    expect(await dao.foodLogCount(used), 1);
    expect(await dao.foodLogCount(unused), 0);

    // Logsuz silinir.
    await dao.deleteFood(unused);
    expect(await dao.getFoodById(unused), isNull);

    // Loglu yemek FK ile korunur — ham silme reddedilir (yıkıcı işlem yok).
    await expectLater(dao.deleteFood(used), throwsA(anything));
    expect(await dao.getFoodById(used), isNotNull);
  });

  test('Seed JSON: 111 yemek, hepsi geçerli, çoğunda birim var', () {
    final raw = File('assets/data/turkish_foods.json').readAsStringSync();
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    expect(list, hasLength(111));
    for (final f in list) {
      expect(f['name'], isA<String>());
      expect((f['kcal_per_100g'] as num) > 0, isTrue);
    }
    final withUnit =
        list.where((f) => f['unit_label'] != null).length;
    expect(withUnit, greaterThan(100)); // kullanıcı talebi: adetli olsun
    final egg = list.firstWhere((f) =>
        (f['name'] as String).startsWith('Yumurta (Bütün'));
    expect(egg['unit_label'], 'adet');
    expect(egg['default_portion_g'], 50);
  });
}
