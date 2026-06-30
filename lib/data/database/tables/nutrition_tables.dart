import 'package:drift/drift.dart';

class Foods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get barcode => text().nullable()();
  RealColumn get kcalPer100g => real()();
  RealColumn get proteinPer100g => real()();
  RealColumn get carbPer100g => real()();
  RealColumn get fatPer100g => real()();
  TextColumn get source => text().withDefault(const Constant('local'))(); // local, openfoodfacts, custom
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isRecipe => boolean().withDefault(const Constant(false))();

  // V2 (Beslenme V2 — adet/birim porsiyon, bkz. docs/07-nutrition-v2.md).
  // İkisi de nullable → additive migration, V1 satırları NULL = "sadece gram".
  // gram = adet × defaultPortionGrams. FoodLogs.grams tek doğruluk kaynağı kalır.
  RealColumn get defaultPortionGrams => real().nullable()(); // 1 birim kaç gram
  TextColumn get unitLabel => text().nullable()(); // adet, dilim, porsiyon...

  // v7 (İçerik Zenginleştirme — docs/11-content-enrichment.md): TÜRKOMP gıda
  // grubu → Yemekler ekranında grup filtresi (D-4). Nullable → additive.
  TextColumn get category => text().nullable()(); // et, sebze, tahıl, süt...
}

class FoodLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get mealType => text()(); // breakfast, lunch, dinner, snack
  IntColumn get foodId => integer().references(Foods, #id)();
  RealColumn get grams => real()();
  RealColumn get computedKcal => real()();
  RealColumn get computedProtein => real()();
  RealColumn get computedCarb => real()();
  RealColumn get computedFat => real()();
}

class RecipeItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('recipe')
  IntColumn get recipeId => integer().references(Foods, #id)();
  @ReferenceName('ingredient')
  IntColumn get foodId => integer().references(Foods, #id)();
  RealColumn get grams => real()();
}

/// v4 (2026-06-21, Home su takibi): günlük su tüketimi. Gün başına TEK satır
/// (`date` 00:00'a normalize), `amountMl` kümülatif artırılır/sıfırlanır.
/// Hedef `user_profile.waterGoalMl`'de tutulur (varsayılan 2500 ml).
class WaterIntake extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get amountMl => integer().withDefault(const Constant(0))();
}
