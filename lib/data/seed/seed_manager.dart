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
    }
  }

  Future<void> _seedExercises() async {
    await db.workoutDao.insertExercises(exercisesSeed);
  }

  Future<void> _seedTurkishFoods() async {
    final jsonStr = await rootBundle.loadString('assets/data/turkish_foods.json');
    final List<dynamic> foodList = json.decode(jsonStr);

    final foods = foodList.map((f) => FoodsCompanion(
      name: Value(f['name'] as String),
      kcalPer100g: Value((f['kcal_per_100g'] as num).toDouble()),
      proteinPer100g: Value((f['protein_per_100g'] as num).toDouble()),
      carbPer100g: Value((f['carb_per_100g'] as num).toDouble()),
      fatPer100g: Value((f['fat_per_100g'] as num).toDouble()),
      source: Value('local'),
      isCustom: Value(false),
      isRecipe: Value(false),
    )).toList();

    await db.nutritionDao.insertFoods(foods);
  }
}
