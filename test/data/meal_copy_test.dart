import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/nutrition_dao.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// "Geçmişten öğün kopyala" veri yolu (docs/21 #2 küçük sürüm):
/// `getMealDays` (hangi günler listelenir) + `addFoodsToMeal` (nasıl eklenir).
///
/// Zaman sabitlenir (`today:` parametresi) — testler gerçek takvime bağlı
/// olmasın, gece yarısı geçince kırılmasın.
void main() {
  late AppDatabase db;
  late NutritionDao dao;
  setUp(() {
    db = newTestDatabase();
    dao = db.nutritionDao;
  });
  tearDown(() => db.close());

  /// 100 g'ı 100 kcal / 10 P / 10 K / 2 Y olan besin — hesap kolay okunsun.
  Future<int> besin(String name,
          {double kcal = 100,
          double protein = 10,
          double carb = 10,
          double fat = 2}) =>
      dao.insertFood(FoodsCompanion(
        name: Value(name),
        kcalPer100g: Value(kcal),
        proteinPer100g: Value(protein),
        carbPer100g: Value(carb),
        fatPer100g: Value(fat),
      ));

  Future<int> kayit(int foodId, DateTime date, String mealType,
      {double grams = 100}) {
    final oran = grams / 100;
    return dao.insertFoodLog(FoodLogsCompanion(
      date: Value(date),
      mealType: Value(mealType),
      foodId: Value(foodId),
      grams: Value(grams),
      computedKcal: Value(100 * oran),
      computedProtein: Value(10 * oran),
      computedCarb: Value(10 * oran),
      computedFat: Value(2 * oran),
    ));
  }

  final bugun = DateTime(2026, 9, 20);

  group('getMealDays', () {
    test('aynı öğünün geçmiş günleri, yeniden eskiye', () async {
      final a = await besin('Yulaf');
      await kayit(a, DateTime(2026, 9, 17, 8), 'breakfast');
      await kayit(a, DateTime(2026, 9, 19, 8), 'breakfast');
      await kayit(a, DateTime(2026, 9, 18, 8), 'breakfast');

      final gunler = await dao.getMealDays('breakfast',
          exclude: bugun, today: bugun);
      expect(gunler.map((g) => g.day).toList(), [
        DateTime(2026, 9, 19),
        DateTime(2026, 9, 18),
        DateTime(2026, 9, 17),
      ]);
    });

    test('hedef gün listelenmez — kullanıcı zaten o güne kopyalıyor',
        () async {
      final a = await besin('Yulaf');
      await kayit(a, DateTime(2026, 9, 20, 8), 'breakfast'); // hedef gün
      await kayit(a, DateTime(2026, 9, 19, 8), 'breakfast');

      final gunler = await dao.getMealDays('breakfast',
          exclude: bugun, today: bugun);
      expect(gunler.map((g) => g.day).toList(), [DateTime(2026, 9, 19)]);
    });

    test('geçmiş bir güne kopyalarken bugün de listelenir', () async {
      final a = await besin('Yulaf');
      await kayit(a, DateTime(2026, 9, 20, 8), 'breakfast');
      await kayit(a, DateTime(2026, 9, 19, 8), 'breakfast');

      // Kullanıcı 19'u dolduruyor → pencere bugünden geriye bakar, 20 listede.
      final gunler = await dao.getMealDays('breakfast',
          exclude: DateTime(2026, 9, 19), today: bugun);
      expect(gunler.map((g) => g.day).toList(), [DateTime(2026, 9, 20)]);
    });

    test('yalnız istenen öğün — diğer öğünler karışmaz', () async {
      final a = await besin('Yulaf');
      await kayit(a, DateTime(2026, 9, 19, 8), 'breakfast');
      await kayit(a, DateTime(2026, 9, 18, 13), 'lunch');

      final kahvalti = await dao.getMealDays('breakfast',
          exclude: bugun, today: bugun);
      expect(kahvalti.map((g) => g.day).toList(), [DateTime(2026, 9, 19)]);
    });

    test('pencere tam [days] gün: 14 günlük pencerede 13 gün öncesi var, '
        '14 gün öncesi yok', () async {
      final a = await besin('Yulaf');
      await kayit(a, DateTime(2026, 9, 7, 8), 'breakfast'); // bugün-13 → içeride
      await kayit(a, DateTime(2026, 9, 6, 8), 'breakfast'); // bugün-14 → dışarıda

      final gunler = await dao.getMealDays('breakfast',
          exclude: bugun, days: 14, today: bugun);
      expect(gunler.map((g) => g.day).toList(), [DateTime(2026, 9, 7)]);
    });

    test('gün içindeki besinler ekleme sırasında, toplam kalori doğru',
        () async {
      final a = await besin('Yulaf');
      final b = await besin('Süt');
      await kayit(a, DateTime(2026, 9, 19, 8), 'breakfast', grams: 80);
      await kayit(b, DateTime(2026, 9, 19, 8, 5), 'breakfast', grams: 200);

      final gun = (await dao.getMealDays('breakfast',
              exclude: bugun, today: bugun))
          .single;
      expect(gun.items.map((i) => i.food.name).toList(), ['Yulaf', 'Süt']);
      expect(gun.totalKcal, 80 + 200); // 100 kcal/100 g
    });

    test('kayıt yoksa boş liste', () async {
      expect(
          await dao.getMealDays('breakfast', exclude: bugun, today: bugun),
          isEmpty);
    });
  });

  group('addFoodsToMeal', () {
    test('seçilen besinler hedef öğüne eklenir', () async {
      final a = await besin('Yulaf');
      final b = await besin('Süt');

      final eklenen = await dao.addFoodsToMeal(bugun, 'breakfast', [
        MealCopyItem(foodId: a, grams: 80),
        MealCopyItem(foodId: b, grams: 200),
      ]);

      expect(eklenen, 2);
      final loglar = await dao.getLogsForDate(bugun);
      expect(loglar.length, 2);
      expect(loglar.every((l) => l.mealType == 'breakfast'), isTrue);
    });

    test('makrolar DÜZENLENEN gramdan yeniden hesaplanır', () async {
      final a = await besin('Yulaf'); // 100 g → 100 kcal / 10 P / 10 K / 2 Y
      await dao.addFoodsToMeal(
          bugun, 'breakfast', [MealCopyItem(foodId: a, grams: 250)]);

      final log = (await dao.getLogsForDate(bugun)).single;
      expect(log.grams, 250);
      expect(log.computedKcal, 250);
      expect(log.computedProtein, 25);
      expect(log.computedCarb, 25);
      expect(log.computedFat, 5);
    });

    test('mevcut öğünün üstüne YAZMAZ, ekler ("dünü kopyala"dan farkı)',
        () async {
      final a = await besin('Yulaf');
      await kayit(a, bugun, 'breakfast'); // öğün zaten dolu

      final eklenen = await dao.addFoodsToMeal(
          bugun, 'breakfast', [MealCopyItem(foodId: a, grams: 50)]);

      expect(eklenen, 1);
      expect((await dao.getLogsForDate(bugun)).length, 2);
    });

    test('gram 0 veya negatifse o satır atlanır', () async {
      final a = await besin('Yulaf');
      final b = await besin('Süt');

      final eklenen = await dao.addFoodsToMeal(bugun, 'breakfast', [
        MealCopyItem(foodId: a, grams: 0),
        MealCopyItem(foodId: b, grams: -5),
      ]);

      expect(eklenen, 0);
      expect(await dao.getLogsForDate(bugun), isEmpty);
    });

    test('besin arada silinmişse o satır atlanır, kalanlar eklenir',
        () async {
      final a = await besin('Yulaf');
      const yokBesin = 99999;

      final eklenen = await dao.addFoodsToMeal(bugun, 'breakfast', [
        MealCopyItem(foodId: a, grams: 100),
        MealCopyItem(foodId: yokBesin, grams: 100),
      ]);

      expect(eklenen, 1);
      expect((await dao.getLogsForDate(bugun)).single.foodId, a);
    });

    test('boş liste → 0, hiçbir şey yazılmaz', () async {
      expect(await dao.addFoodsToMeal(bugun, 'breakfast', const []), 0);
      expect(await dao.getLogsForDate(bugun), isEmpty);
    });

    test('kaynak gün değişmez — kopyalama okuma tarafına dokunmaz', () async {
      final a = await besin('Yulaf');
      final kaynak = DateTime(2026, 9, 19);
      await kayit(a, kaynak, 'breakfast');

      await dao.addFoodsToMeal(
          bugun, 'breakfast', [MealCopyItem(foodId: a, grams: 100)]);

      expect((await dao.getLogsForDate(kaynak)).length, 1);
    });

    test('hedef gün saat taşımaz — kayıt 00:00 gününe düşer', () async {
      final a = await besin('Yulaf');
      await dao.addFoodsToMeal(DateTime(2026, 9, 20, 21, 45), 'dinner',
          [MealCopyItem(foodId: a, grams: 100)]);

      final log = (await dao.getLogsForDate(DateTime(2026, 9, 20))).single;
      expect(log.date, DateTime(2026, 9, 20));
    });
  });
}
