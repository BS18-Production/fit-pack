import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../database/app_database.dart';
import 'exercises_seed.dart';

class SeedManager {
  final AppDatabase db;

  SeedManager(this.db);

  Future<void> seedIfNeeded() async {
    // Check if exercises already exist
    final existingExercises = await db.workoutDao.getAllExercises();
    if (existingExercises.isEmpty) {
      await _seedExercises();
      await _seedTurkishFoods();
      await db.userProfileDao.ensureProfile();
    } else {
      // V2 (docs/07-nutrition-v2.md): seed yalnız boş kurulumda çalışır;
      // mevcut DB'lerdeki hazır yemekler birim/porsiyon verisi almadan
      // kalırdı. Bu idempotent backfill, birimi NULL olan LOCAL yemekleri
      // JSON'dan ada göre doldurur. İlk çalıştırmadan sonra no-op
      // (custom/OpenFoodFacts yemeklere ve loglara dokunmaz).
      await _backfillFoodUnits();
      // Antrenman V2 (docs/09-workout-v2.md): mevcut kurulumlara yeni
      // İngilizce hareket kütüphanesini getir (eksikleri ekle + meta doldur).
      await _backfillExercises();
    }
  }

  /// İngilizce hareket kütüphanesini mevcut DB'ye uyarlar (idempotent):
  /// - Adı seed'de olup DB'de OLMAYAN hareketleri ekler.
  /// - Var olan ama ekipmanı NULL olan (eski V1) hareketlere meta yazar
  ///   (ada göre eşleşirse). Custom hareketlere ve loglara dokunmaz.
  Future<void> _backfillExercises() async {
    final existing = await db.workoutDao.getAllExercises();
    final byName = {for (final e in existing) e.name: e};

    final toInsert = <ExercisesCompanion>[];
    for (final seed in exerciseSeedData) {
      final current = byName[seed.name];
      if (current == null) {
        toInsert.add(ExercisesCompanion(
          name: Value(seed.name),
          category: Value(seed.category),
          muscleGroups: Value(jsonEncode(seed.muscles)),
          primaryMuscle: Value(seed.primaryMuscle),
          equipment: Value(seed.equipment),
          measurementType: Value(seed.measurement),
          isCustom: const Value(false),
        ));
      } else if (current.equipment == null && !current.isCustom) {
        // Eski V1 hareketi → meta doldur (ekipman/kas/ölçüm tipi).
        await db.workoutDao.updateExerciseMeta(
          current.id,
          ExercisesCompanion(
            primaryMuscle: Value(seed.primaryMuscle),
            equipment: Value(seed.equipment),
            measurementType: Value(seed.measurement),
          ),
        );
      }
    }
    if (toInsert.isNotEmpty) {
      await db.workoutDao.insertExercises(toInsert);
    }
  }

  Future<void> _backfillFoodUnits() async {
    final all = await db.nutritionDao.getAllFoods();
    final needs = all
        .where((f) =>
            f.source == 'local' && !f.isCustom && f.unitLabel == null)
        .toList();
    if (needs.isEmpty) return; // zaten dolu → ucuz çıkış

    final jsonStr =
        await rootBundle.loadString('assets/data/turkish_foods.json');
    final List<dynamic> foodList = json.decode(jsonStr);
    final byName = <String, Map<String, dynamic>>{
      for (final f in foodList) (f['name'] as String): f as Map<String, dynamic>
    };

    for (final food in needs) {
      final src = byName[food.name];
      final portion = src?['default_portion_g'];
      final unit = src?['unit_label'];
      if (portion == null || unit == null) continue;
      await db.nutritionDao.updateFood(
        food.id,
        FoodsCompanion(
          defaultPortionGrams: Value((portion as num).toDouble()),
          unitLabel: Value(unit as String),
        ),
      );
    }
  }

  Future<void> _seedExercises() async {
    await db.workoutDao.insertExercises(exercisesSeed);
  }

  Future<void> _seedTurkishFoods() async {
    final jsonStr = await rootBundle.loadString('assets/data/turkish_foods.json');
    final List<dynamic> foodList = json.decode(jsonStr);

    final foods = foodList.map((f) {
      // V2 birim alanları opsiyonel: JSON'da yoksa NULL (sadece gram).
      final portion = f['default_portion_g'];
      final unit = f['unit_label'];
      return FoodsCompanion(
        name: Value(f['name'] as String),
        kcalPer100g: Value((f['kcal_per_100g'] as num).toDouble()),
        proteinPer100g: Value((f['protein_per_100g'] as num).toDouble()),
        carbPer100g: Value((f['carb_per_100g'] as num).toDouble()),
        fatPer100g: Value((f['fat_per_100g'] as num).toDouble()),
        source: const Value('local'),
        isCustom: const Value(false),
        isRecipe: const Value(false),
        defaultPortionGrams:
            Value(portion == null ? null : (portion as num).toDouble()),
        unitLabel: Value(unit as String?),
      );
    }).toList();

    await db.nutritionDao.insertFoods(foods);
  }
}
