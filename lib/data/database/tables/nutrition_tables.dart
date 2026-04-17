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
