import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/nutrition_tables.dart';

part 'nutrition_dao.g.dart';

@DriftAccessor(tables: [Foods, FoodLogs, RecipeItems])
class NutritionDao extends DatabaseAccessor<AppDatabase> with _$NutritionDaoMixin {
  NutritionDao(super.db);

  // === Foods ===
  Future<List<Food>> getAllFoods() => select(foods).get();

  Future<List<Food>> searchFoods(String query) =>
      (select(foods)..where((f) => f.name.like('%$query%'))).get();

  Future<Food?> getFoodByBarcode(String barcode) =>
      (select(foods)..where((f) => f.barcode.equals(barcode))).getSingleOrNull();

  Future<int> insertFood(FoodsCompanion entry) =>
      into(foods).insert(entry);

  Future<void> insertFoods(List<FoodsCompanion> entries) async {
    await batch((b) => b.insertAll(foods, entries));
  }

  // === Food Logs ===
  Future<List<FoodLog>> getLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(foodLogs)
          ..where((l) => l.date.isBetweenValues(start, end))
          ..orderBy([(l) => OrderingTerm.asc(l.mealType)]))
        .get();
  }

  Future<List<FoodLog>> getLogsInRange(DateTime start, DateTime end) =>
      (select(foodLogs)
            ..where((l) => l.date.isBetweenValues(start, end))
            ..orderBy([(l) => OrderingTerm.desc(l.date)]))
          .get();

  Future<int> insertFoodLog(FoodLogsCompanion entry) =>
      into(foodLogs).insert(entry);

  Future<int> deleteFoodLog(int id) =>
      (delete(foodLogs)..where((l) => l.id.equals(id))).go();

  /// Daily totals for a date
  Future<DailyNutrition> getDailyTotals(DateTime date) async {
    final logs = await getLogsForDate(date);
    double kcal = 0, protein = 0, carb = 0, fat = 0;
    for (final log in logs) {
      kcal += log.computedKcal;
      protein += log.computedProtein;
      carb += log.computedCarb;
      fat += log.computedFat;
    }
    return DailyNutrition(kcal: kcal, protein: protein, carb: carb, fat: fat);
  }

  // === Recipe Items ===
  Future<List<RecipeItem>> getRecipeItems(int recipeId) =>
      (select(recipeItems)..where((r) => r.recipeId.equals(recipeId))).get();

  Future<void> insertRecipeItem(RecipeItemsCompanion entry) =>
      into(recipeItems).insert(entry);
}

class DailyNutrition {
  final double kcal;
  final double protein;
  final double carb;
  final double fat;

  DailyNutrition({
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
  });
}
