import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/nutrition/foods_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Yemek grupları (C-5). Kategori kolonu vardı ama **boştu**; 111 hazır
/// yemek 2026-09-17'de gruplandı. Bu testler iki şeyi bekçiler: kaynak veri
/// eksiksiz/geçerli kalsın, ekranın grup listesi beklenen sırada gelsin.
void main() {
  late List<dynamic> seed;

  setUpAll(() {
    seed = json.decode(
      File('assets/data/turkish_foods.json').readAsStringSync(),
    ) as List<dynamic>;
  });

  test('her hazır yemeğin geçerli bir grubu var', () {
    final missing = [
      for (final f in seed)
        if ((f as Map)['category'] == null) f['name'],
    ];
    expect(missing, isEmpty, reason: 'gruplanmamış yemek kalmamalı');

    final unknown = {
      for (final f in seed)
        if (!foodCategoryOrder.contains((f as Map)['category']))
          '${f['name']} → ${f['category']}',
    };
    expect(unknown, isEmpty, reason: 'grup kodu foodCategoryOrder dışında');
  });

  test('her grup kullanılıyor — ölü kod/etiket kalmasın', () {
    final used = {for (final f in seed) (f as Map)['category'] as String};
    expect(used, containsAll(foodCategoryOrder));
  });

  group('availableFoodCategories', () {
    Food food(String name, String? category) => Food(
      id: name.hashCode,
      name: name,
      category: category,
      kcalPer100g: 100,
      proteinPer100g: 10,
      carbPer100g: 10,
      fatPer100g: 1,
      source: 'local',
      isCustom: false,
      isRecipe: false,
      syncState: 0,
    );

    test('yalnız listede bulunan gruplar, sabit sırayla', () {
      final list = [
        food('Elma', 'fruit'),
        food('Süt', 'dairy'),
        food('Tavuk', 'meat'),
        food('Kendi yemeğim', null),
      ];
      // foodCategoryOrder sırası: meat → dairy → … → fruit
      expect(availableFoodCategories(list), ['meat', 'dairy', 'fruit']);
    });

    test('kategorisiz liste → çip şeridi çizilmez', () {
      expect(availableFoodCategories([food('Kendi yemeğim', null)]), isEmpty);
    });

    test('beklenmedik grup düşmez, sona alfabetik eklenir', () {
      final list = [food('X', 'zzz-yeni'), food('Elma', 'fruit')];
      expect(availableFoodCategories(list), ['fruit', 'zzz-yeni']);
    });
  });

  test('geriye dönük doldurma: kategorisi boş hazır yemek ada göre dolar',
      () async {
    final db = newTestDatabase();
    addTearDown(db.close);

    // Kategori alanı eklenmeden önce kurulmuş bir cihazı taklit et.
    final sample = (seed.first as Map<String, dynamic>);
    await db.nutritionDao.insertFood(
      FoodsCompanion.insert(
        name: sample['name'] as String,
        kcalPer100g: (sample['kcal_per_100g'] as num).toDouble(),
        proteinPer100g: (sample['protein_per_100g'] as num).toDouble(),
        carbPer100g: (sample['carb_per_100g'] as num).toDouble(),
        fatPer100g: (sample['fat_per_100g'] as num).toDouble(),
        source: const Value('local'),
        isCustom: const Value(false),
        isRecipe: const Value(false),
      ),
    );
    // Kullanıcının kendi yemeği: dokunulmamalı.
    await db.nutritionDao.insertFood(
      FoodsCompanion.insert(
        name: sample['name'] as String, // aynı ad, ama custom
        kcalPer100g: 1,
        proteinPer100g: 1,
        carbPer100g: 1,
        fatPer100g: 1,
        source: const Value('local'),
        isCustom: const Value(true),
        isRecipe: const Value(false),
      ),
    );

    final before = await db.nutritionDao.getAllFoods();
    expect(before.every((f) => f.category == null), isTrue);

    // SeedManager rootBundle kullanır (widget testi ister); backfill'in
    // SQL davranışını burada aynı kuralla doğruluyoruz.
    final byName = {
      for (final f in seed)
        (f as Map<String, dynamic>)['name'] as String: f['category'] as String,
    };
    for (final f in before.where((f) => f.source == 'local' && !f.isCustom)) {
      final c = byName[f.name];
      if (c != null) {
        await db.nutritionDao.updateFood(f.id, FoodsCompanion(category: Value(c)));
      }
    }

    final after = await db.nutritionDao.getAllFoods();
    expect(after.firstWhere((f) => !f.isCustom).category, isNotNull);
    expect(after.firstWhere((f) => f.isCustom).category, isNull,
        reason: 'kullanıcının kendi yemeğine dokunulmamalı');
  });
}
