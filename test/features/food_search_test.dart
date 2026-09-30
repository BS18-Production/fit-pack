import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/nutrition/food_search.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Yemek ekleme paneli (2026-09-30): arama sırası ve tek dokunuş miktarı.
void main() {
  var id = 0;
  Food f(String name,
          {bool custom = false, double? portion, String? unit}) =>
      Food(
        id: ++id,
        name: name,
        kcalPer100g: 200,
        proteinPer100g: 10,
        carbPer100g: 20,
        fatPer100g: 5,
        source: 'local',
        isCustom: custom,
        isRecipe: false,
        defaultPortionGrams: portion,
        unitLabel: unit,
      );

  group('rankFoods', () {
    final sut = f('Süt (Tam Yağlı)');
    final yogurt = f('Yoğurt (Tam Yağlı)');
    final sutlac = f('Sütlaç');
    final kakaolu = f('Kakaolu Süt');
    final hepsi = [yogurt, kakaolu, sutlac, sut];

    test('Türkçe harf farkı yok: "sut" → Süt', () {
      expect(rankFoods(hepsi, 'sut'), contains(sut));
    });

    test('tam kelime > ad başı: "sut" → Süt ve Kakaolu Süt, Sütlaç\'tan önce',
        () {
      final r = rankFoods(hepsi, 'sut');
      expect(r.indexOf(sut), lessThan(r.indexOf(sutlac)));
      expect(r.indexOf(kakaolu), lessThan(r.indexOf(sutlac)));
      // Adı aranan kelimeyle başlayan önce: Süt > Kakaolu Süt.
      expect(r.indexOf(sut), lessThan(r.indexOf(kakaolu)));
      expect(r, isNot(contains(yogurt)));
    });

    test('her kelime eşleşmeli: "tam yag" → iki tam yağlı', () {
      expect(rankFoods(hepsi, 'tam yag').toSet(), {sut, yogurt});
    });

    test('eşit alakada son kullanılan önce', () {
      final r = rankFoods(hepsi, 'tam', recentRank: {yogurt.id: 0});
      expect(r.first, yogurt);
    });

    test('boş arama: son kullanılan → kendi besinin → alfabe', () {
      final benim = f('Zeytinli Poğaça', custom: true);
      final r = rankFoods([...hepsi, benim], '', recentRank: {sutlac.id: 0});
      expect(r.take(2), [sutlac, benim]);
    });
  });

  group('defaultPortion — tek dokunuş miktarı', () {
    test('birimli besin: 1 birim', () {
      final p = defaultPortion(f('Menemen', portion: 200, unit: 'porsiyon'));
      expect((p.grams, p.units, p.unit), (200.0, 1.0, 'porsiyon'));
    });

    test('birimsiz: 100 g', () {
      final p = defaultPortion(f('Pirinç'));
      expect((p.grams, p.units, p.unit), (100.0, 0.0, null));
    });

    test('son kullanılan miktar kazanır', () {
      final p = defaultPortion(f('Yumurta', portion: 50, unit: 'adet'),
          lastGrams: 150);
      expect((p.grams, p.units), (150.0, 3.0));
    });

    test('macrosFor miktara göre ölçekler', () {
      final m = macrosFor(f('X'), 150);
      expect((m.kcal, m.protein), (300.0, 15.0));
    });
  });

  test('getRecentPortions: son besinler + son miktar, tekrarsız', () async {
    final db = newTestDatabase();
    addTearDown(db.close);
    final a = await db.nutritionDao.insertFood(FoodsCompanion.insert(
        name: 'A', kcalPer100g: 1, proteinPer100g: 1, carbPer100g: 1,
        fatPer100g: 1));
    final b = await db.nutritionDao.insertFood(FoodsCompanion.insert(
        name: 'B', kcalPer100g: 1, proteinPer100g: 1, carbPer100g: 1,
        fatPer100g: 1));
    Future<void> log(int food, double g) => db.nutritionDao.insertFoodLog(
        FoodLogsCompanion.insert(
            date: DateTime(2026, 9, 30),
            mealType: 'lunch',
            foodId: food,
            grams: g,
            computedKcal: 0,
            computedProtein: 0,
            computedCarb: 0,
            computedFat: 0));
    await log(a, 100);
    await log(b, 50);
    await log(a, 180); // en son
    final r = await db.nutritionDao.getRecentPortions();
    expect(r.map((x) => (x.food.name, x.grams)), [('A', 180.0), ('B', 50.0)]);
  });
}
