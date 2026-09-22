import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/nutrition_tables.dart';

part 'nutrition_dao.g.dart';

@DriftAccessor(tables: [Foods, FoodLogs, RecipeItems, WaterIntake])
class NutritionDao extends DatabaseAccessor<AppDatabase> with _$NutritionDaoMixin {
  NutritionDao(super.db);

  // === Su takibi (v4) — gün başına tek satır, kümülatif ml ===
  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Günün toplam su miktarı (ml). Kayıt yoksa 0.
  ///
  /// **`getSingleOrNull` DEĞİL** (dış inceleme 2026-09-15, #8): tabloda gün
  /// başına tekillik kısıtı yok. İki cihaz aynı güne ayrı `uid`'lerle satır
  /// açarsa indirme ikisini de yerele yazar ve tek-satır sorgusu **fırlatırdı**
  /// — su kartı olan her ekran hata verirdi. Çoklu satır beklenen durum değil
  /// ama okuma buna dayanıklı olmalı: satırlar toplanır.
  Future<int> getWaterForDay(DateTime day) async {
    final rows = await (select(waterIntake)
          ..where((w) => w.date.equals(_dayStart(day))))
        .get();
    return rows.fold<int>(0, (sum, r) => sum + r.amountMl);
  }

  /// Güne [ml] ekler (negatif = azaltır), 0 altına düşmez. Yeni güne satır
  /// açar, varsa artırır. Güncellenmiş toplamı döner.
  ///
  /// **Tek transaction** (dış inceleme 2026-09-15, #8): oku-değiştir-yaz dizisi
  /// açıktaydı; su düğmesine hızlı arka arkaya basınca iki okuma aynı değeri
  /// görüp biri diğerinin artışını yutabiliyordu. Aynı güne birden çok satır
  /// düşmüşse (çok cihaz) en eskisi güncellenir — kalıcı çözüm gün başına
  /// tekillik kısıtı, o senkron v2 kapsamında (docs/20).
  Future<int> addWater(DateTime day, int ml) => transaction(() async {
        final d = _dayStart(day);
        final rows = await (select(waterIntake)
              ..where((w) => w.date.equals(d))
              ..orderBy([(w) => OrderingTerm.asc(w.id)]))
            .get();
        if (rows.isEmpty) {
          final v = ml < 0 ? 0 : ml;
          await into(waterIntake)
              .insert(WaterIntakeCompanion.insert(date: d, amountMl: Value(v)));
          return v;
        }
        final total = rows.fold<int>(0, (sum, r) => sum + r.amountMl);
        final next = (total + ml).clamp(0, 100000);
        await (update(waterIntake)..where((w) => w.id.equals(rows.first.id)))
            .write(WaterIntakeCompanion(amountMl: Value(next)));
        // Fazla satırlar varsa toplam ilkine taşındı → kalanlar sıfırlanır ki
        // okuma iki kez saymasın.
        for (final extra in rows.skip(1)) {
          await (update(waterIntake)..where((w) => w.id.equals(extra.id)))
              .write(const WaterIntakeCompanion(amountMl: Value(0)));
        }
        return next;
      });

  /// Günün su kaydını sıfırlar (uzun basışla geri al).
  Future<void> resetWater(DateTime day) async {
    await (delete(waterIntake)..where((w) => w.date.equals(_dayStart(day))))
        .go();
  }

  // === Foods ===
  Future<List<Food>> getAllFoods() => select(foods).get();

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
  // Tarih aralığı KURALI (CODE_REVIEW H-01): [start, end) — başlangıç dahil,
  // bitiş HARİÇ. `isBetweenValues` SQL BETWEEN üretir (iki uç dahil); tam gece
  // yarısına yazılan kayıtlar (tarih seçici / "dünü kopyala") iki güne birden
  // sayılırdı. Bu yüzden aralık sorgularında >= start AND < end kullanılır.
  Future<List<FoodLog>> getLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(foodLogs)
          ..where((l) =>
              l.date.isBiggerOrEqualValue(start) & l.date.isSmallerThanValue(end))
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
      ..where(foodLogs.date.isBiggerOrEqualValue(start) &
          foodLogs.date.isSmallerThanValue(end))
      ..orderBy([OrderingTerm.asc(foodLogs.id)]);
    final rows = await query.get();
    return rows
        .map((r) => FoodLogWithFood(
              log: r.readTable(foodLogs),
              food: r.readTable(foods),
            ))
        .toList();
  }

  /// [start, end) aralığındaki kayıtlar (bitiş hariç — H-01 kuralı).
  Future<List<FoodLog>> getLogsInRange(DateTime start, DateTime end) =>
      (select(foodLogs)
            ..where((l) =>
                l.date.isBiggerOrEqualValue(start) &
                l.date.isSmallerThanValue(end))
            ..orderBy([(l) => OrderingTerm.desc(l.date)]))
          .get();

  Future<int> insertFoodLog(FoodLogsCompanion entry) =>
      into(foodLogs).insert(entry);

  /// Aktivite takvimi (docs/10-activity-calendar.md): tarih aralığındaki
  /// günlük makro toplamları. Gün başına TEK kayıt (00:00'a normalize) — ay
  /// görünümü tek sorguyla doldurulur (N+1 yok).
  Future<Map<DateTime, DailyNutrition>> getDailyTotalsInRange(
      DateTime start, DateTime end) async {
    final logs = await getLogsInRange(start, end);
    final map = <DateTime, DailyNutrition>{};
    for (final l in logs) {
      final day = DateTime(l.date.year, l.date.month, l.date.day);
      final cur = map[day];
      map[day] = DailyNutrition(
        kcal: (cur?.kcal ?? 0) + l.computedKcal,
        protein: (cur?.protein ?? 0) + l.computedProtein,
        carb: (cur?.carb ?? 0) + l.computedCarb,
        fat: (cur?.fat ?? 0) + l.computedFat,
      );
    }
    return map;
  }

  /// Aktivite takvimi: tarih aralığındaki günlük su (ml). Gün → ml.
  Future<Map<DateTime, int>> getWaterInRange(
      DateTime start, DateTime end) async {
    final rows = await (select(waterIntake)
          ..where((w) =>
              w.date.isBiggerOrEqualValue(start) &
              w.date.isSmallerThanValue(end)))
        .get();
    // Map literal'i aynı güne ikinci satır düşerse öncekini EZERDİ (#8 ile aynı
    // kök: gün başına tekillik kısıtı yok). Toplamak doğru davranış.
    final out = <DateTime, int>{};
    for (final w in rows) {
      final day = DateTime(w.date.year, w.date.month, w.date.day);
      out[day] = (out[day] ?? 0) + w.amountMl;
    }
    return out;
  }

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

  /// Son [days] günde **aynı öğünde** kayıt bulunan günler, yeniden eskiye
  /// (docs/21 #2 küçük sürüm). [exclude] günü listelenmez — kullanıcı zaten
  /// o güne kopyalıyor.
  ///
  /// Pencere BUGÜNden geriye bakar, hedef günden değil: geçmiş bir günü
  /// sonradan dolduran kullanıcı da son yediklerini görebilsin. Tam [days]
  /// takvim günü, bugün dahil: `[bugün-days+1, yarın)` — yarı-açık aralık
  /// (CONVENTIONS §3).
  ///
  /// Gün aritmetiği takvimle yapılır, `Duration(days:)` ile değil: yaz saati
  /// uygulayan bir bölgede 23/25 saatlik gün pencereyi bir gün kaydırırdı.
  Future<List<MealDay>> getMealDays(
    String mealType, {
    required DateTime exclude,
    int days = 14,
    DateTime? today,
  }) async {
    final bugun = today ?? DateTime.now();
    final end = DateTime(bugun.year, bugun.month, bugun.day + 1);
    final start = DateTime(bugun.year, bugun.month, bugun.day - days + 1);
    final haricGun = DateTime(exclude.year, exclude.month, exclude.day);

    final rows = await (select(foodLogs).join([
      innerJoin(foods, foods.id.equalsExp(foodLogs.foodId)),
    ])
          ..where(foodLogs.mealType.equals(mealType) &
              foodLogs.date.isBiggerOrEqualValue(start) &
              foodLogs.date.isSmallerThanValue(end))
          ..orderBy([OrderingTerm.asc(foodLogs.id)]))
        .get();

    final byDay = <DateTime, List<FoodLogWithFood>>{};
    for (final r in rows) {
      final log = r.readTable(foodLogs);
      final gun = DateTime(log.date.year, log.date.month, log.date.day);
      if (gun == haricGun) continue;
      byDay
          .putIfAbsent(gun, () => [])
          .add(FoodLogWithFood(log: log, food: r.readTable(foods)));
    }
    final gunler = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final g in gunler) MealDay(day: g, items: byDay[g]!)];
  }

  /// Seçilen besinleri [day] gününün [mealType] öğününe **tek transaction**
  /// ile ekler; eklenen satır sayısını döner.
  ///
  /// Makrolar gramdan YENİDEN hesaplanır — kullanıcı kopyalarken miktarı
  /// değiştirebiliyor; eski kaydın hazır makrosunu taşımak yanlış değer
  /// yazardı.
  ///
  /// Üzerine yazmaz, EKLER: "dünü kopyala"dan farkı bu. O, boş bir günü
  /// dolduruyor; bu, mevcut öğüne ekleme yapıyor.
  Future<int> addFoodsToMeal(
    DateTime day,
    String mealType,
    List<MealCopyItem> items,
  ) =>
      transaction(() async {
        if (items.isEmpty) return 0;
        final gun = DateTime(day.year, day.month, day.day);
        final ids = items.map((i) => i.foodId).toSet().toList();
        final besinler = {
          for (final f
              in await (select(foods)..where((f) => f.id.isIn(ids))).get())
            f.id: f,
        };
        final eklenecek = <FoodLogsCompanion>[];
        for (final i in items) {
          final f = besinler[i.foodId];
          // Besin arada silinmişse o satırı atla — kopyalamanın tamamı
          // başarısız olmasın.
          if (f == null || i.grams <= 0) continue;
          final oran = i.grams / 100;
          eklenecek.add(FoodLogsCompanion(
            date: Value(gun),
            mealType: Value(mealType),
            foodId: Value(f.id),
            grams: Value(i.grams),
            computedKcal: Value(f.kcalPer100g * oran),
            computedProtein: Value(f.proteinPer100g * oran),
            computedCarb: Value(f.carbPer100g * oran),
            computedFat: Value(f.fatPer100g * oran),
          ));
        }
        if (eklenecek.isEmpty) return 0;
        await batch((b) => b.insertAll(foodLogs, eklenecek));
        return eklenecek.length;
      });

  /// [from] gününün tüm kayıtlarını [to] gününe kopyalar ("dünü kopyala").
  /// Kopyalanan kayıt sayısını döner; 0 → kaynak gün boş **ya da** hedef gün
  /// zaten dolu.
  ///
  /// **Tek transaction + hedef kontrolü içeride** (dış inceleme 2026-09-15,
  /// #12): eskiden kayıtlar tek tek, transaction dışında ekleniyordu — üçüncü
  /// satırda hata olsa iki öğün yarım kalıyordu. Hedefin boş olduğu kontrolü de
  /// aynı transaction'da, çünkü düğme `logs.isEmpty` iken görünüyor ve hızlı
  /// iki dokunuş ekran daha tazelenmeden ikinci kopyayı başlatabiliyordu.
  Future<int> copyDayLogs(DateTime from, DateTime to) => transaction(() async {
        final day = DateTime(to.year, to.month, to.day);
        final existing = await getLogsForDate(day);
        if (existing.isNotEmpty) return 0; // hedef dolu → kopyalama
        final logs = await getLogsForDate(from);
        if (logs.isEmpty) return 0;
        await batch((b) => b.insertAll(
              foodLogs,
              [
                for (final log in logs)
                  FoodLogsCompanion(
                    date: Value(day),
                    mealType: Value(log.mealType),
                    foodId: Value(log.foodId),
                    grams: Value(log.grams),
                    computedKcal: Value(log.computedKcal),
                    computedProtein: Value(log.computedProtein),
                    computedCarb: Value(log.computedCarb),
                    computedFat: Value(log.computedFat),
                  ),
              ],
            ));
        return logs.length;
      });

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

  // NOT: `recipe_items` tablosu şemada durur (ADR-007) ama tarif/öğün-bileşimi
  // özelliği henüz yok — erişim metotları kullanılmıyordu, kaldırıldı. Özellik
  // gelince buraya yeniden eklenir.
}

/// FoodLog + ait olduğu Food (join sonucu). UI yemek adını buradan okur.
class FoodLogWithFood {
  final FoodLog log;
  final Food food;
  FoodLogWithFood({required this.log, required this.food});
}

/// Bir günün belirli öğünü — "başka günden kopyala" listesinin satırı.
class MealDay {
  final DateTime day;
  final List<FoodLogWithFood> items;
  const MealDay({required this.day, required this.items});

  double get totalKcal =>
      items.fold(0, (sum, i) => sum + i.log.computedKcal);
}

/// Kopyalanacak tek besin: hangi besin, kaç gram (kullanıcı değiştirmiş
/// olabilir).
class MealCopyItem {
  final int foodId;
  final double grams;
  const MealCopyItem({required this.foodId, required this.grams});
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
