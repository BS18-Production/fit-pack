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

  Future<Food?> getFoodById(int id) =>
      (select(foods)..where((f) => f.id.equals(id))).getSingleOrNull();

  Future<Food?> getFoodByBarcode(String barcode) =>
      (select(foods)..where((f) => f.barcode.equals(barcode))).getSingleOrNull();

  Future<int> insertFood(FoodsCompanion entry) =>
      into(foods).insert(entry);

  /// Yemeği günceller (Yemekler ekranı — sadece custom düzenlenir, kural
  /// UI'da; DAO mekanik). `id` companion'da değil parametrede.
  Future<bool> updateFood(int id, FoodsCompanion entry) =>
      (update(foods)..where((f) => f.id.equals(id))).write(entry).then((n) => n > 0);

  /// Bu yemeğe kaç log bağlı? Silmeden önce sorulur — log varsa silinmez
  /// (FK bütünlüğü + geçmiş kaybolmasın, ADR-007 yıkıcı işlem yok).
  Future<int> foodLogCount(int foodId) async {
    final c = countAll(filter: foodLogs.foodId.equals(foodId));
    final q = selectOnly(foodLogs)..addColumns([c]);
    return (await q.getSingle()).read(c) ?? 0;
  }

  /// Yemeği siler. Önce [foodLogCount] kontrol edilmeli; bu metot ham siler.
  Future<int> deleteFood(int id) =>
      (delete(foods)..where((f) => f.id.equals(id))).go();

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

  /// Bir günün kayıtları + yemek adı (join). UI'da "Tavuk · 150g" göstermek
  /// için gerekir — düz FoodLog'da yemek adı yok, kullanıcı ne eklediğini
  /// göremez.
  Future<List<FoodLogWithFood>> getLogsWithFoodForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = select(foodLogs).join([
      innerJoin(foods, foods.id.equalsExp(foodLogs.foodId)),
    ])
      ..where(foodLogs.date.isBetweenValues(start, end))
      ..orderBy([OrderingTerm.asc(foodLogs.id)]);
    final rows = await query.get();
    return rows
        .map((r) => FoodLogWithFood(
              log: r.readTable(foodLogs),
              food: r.readTable(foods),
            ))
        .toList();
  }

  Future<List<FoodLog>> getLogsInRange(DateTime start, DateTime end) =>
      (select(foodLogs)
            ..where((l) => l.date.isBetweenValues(start, end))
            ..orderBy([(l) => OrderingTerm.desc(l.date)]))
          .get();

  Future<int> insertFoodLog(FoodLogsCompanion entry) =>
      into(foodLogs).insert(entry);

  /// Son eklenen DISTINCT yemekler — "Son kullanılanlar" hızlı şeridi.
  /// Aynı şeyleri yiyen kullanıcı her gün 111 yemek içinde aramasın.
  Future<List<Food>> getRecentFoods({int limit = 8}) async {
    final query = select(foodLogs).join([
      innerJoin(foods, foods.id.equalsExp(foodLogs.foodId)),
    ])
      ..orderBy([OrderingTerm.desc(foodLogs.id)])
      ..limit(limit * 5); // tekrarlar elenince limit dolsun diye geniş çek
    final rows = await query.get();
    final seen = <int>{};
    final result = <Food>[];
    for (final r in rows) {
      final f = r.readTable(foods);
      if (seen.add(f.id)) {
        result.add(f);
        if (result.length >= limit) break;
      }
    }
    return result;
  }

  /// [from] gününün tüm kayıtlarını [to] gününe kopyalar ("dünü kopyala").
  /// Kopyalanan kayıt sayısını döner; 0 → kaynak gün boş.
  Future<int> copyDayLogs(DateTime from, DateTime to) async {
    final logs = await getLogsForDate(from);
    for (final log in logs) {
      await insertFoodLog(FoodLogsCompanion(
        date: Value(DateTime(to.year, to.month, to.day)),
        mealType: Value(log.mealType),
        foodId: Value(log.foodId),
        grams: Value(log.grams),
        computedKcal: Value(log.computedKcal),
        computedProtein: Value(log.computedProtein),
        computedCarb: Value(log.computedCarb),
        computedFat: Value(log.computedFat),
      ));
    }
    return logs.length;
  }

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

/// FoodLog + ait olduğu Food (join sonucu). UI yemek adını buradan okur.
class FoodLogWithFood {
  final FoodLog log;
  final Food food;
  FoodLogWithFood({required this.log, required this.food});
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
