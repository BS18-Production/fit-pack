import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/nutrition_dao.dart';
import 'package:fit_pack/features/nutrition/nutrition_habits.dart';
import 'package:fit_pack/core/notifications/notification_service.dart';
import 'package:fit_pack/features/nutrition/meal_reminders.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Bildirim eklentisi testte yok: kurulan/iptal edilenleri kaydeder.
class _FakeNotifications extends NotificationService {
  final scheduled = <int, DateTime>{};
  final cancelled = <int>[];

  @override
  Future<void> scheduleOnce({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async =>
      scheduled[id] = when;

  @override
  Future<void> cancel(int id) async => cancelled.add(id);
}

/// docs/26 — beslenme kaydı alışkanlığı: her zamanki öğün, öğün
/// hatırlatıcısı, haftalık kayıt hedefi.
void main() {
  var seq = 0;
  Food besin(int id) => Food(
        id: id,
        name: 'B$id',
        kcalPer100g: 100,
        proteinPer100g: 10,
        carbPer100g: 0,
        fatPer100g: 0,
        source: 'local',
        isCustom: false,
        isRecipe: false,
      );
  FoodLog kayit(DateTime day, String meal, int foodId,
          {double grams = 100, DateTime? at}) =>
      FoodLog(
        id: ++seq,
        date: day,
        mealType: meal,
        foodId: foodId,
        grams: grams,
        computedKcal: grams,
        computedProtein: grams / 10,
        computedCarb: 0,
        computedFat: 0,
        updatedAt: at,
      );
  MealDay gun(DateTime day, List<int> foods, {double grams = 100}) => MealDay(
        day: day,
        items: [
          for (final f in foods)
            FoodLogWithFood(
                log: kayit(day, 'breakfast', f, grams: grams), food: besin(f)),
        ],
      );

  group('mealForTime', () {
    test('saat dilimleri', () {
      expect(mealForTime(DateTime(2026, 9, 30, 8)), 'breakfast');
      expect(mealForTime(DateTime(2026, 9, 30, 13)), 'lunch');
      expect(mealForTime(DateTime(2026, 9, 30, 17)), 'snack');
      expect(mealForTime(DateTime(2026, 9, 30, 20)), 'dinner');
    });
  });

  group('usualMealOf — her zamanki öğün', () {
    test('tek sefer yenen öğün önerilmez', () {
      expect(usualMealOf('breakfast', [gun(DateTime(2026, 9, 29), [1, 2])]),
          isNull);
    });

    test('2+ gün aynı besinler → öneri; miktarlar en yeni günden', () {
      final u = usualMealOf('breakfast', [
        gun(DateTime(2026, 9, 29), [1, 2], grams: 150), // en yeni
        gun(DateTime(2026, 9, 28), [3]),
        gun(DateTime(2026, 9, 27), [2, 1], grams: 100), // sıra farkı önemsiz
      ]);
      expect(u, isNotNull);
      expect(u!.timesLogged, 2);
      expect(u.items.map((i) => i.log.grams), [150, 150]);
      expect(u.kcal, 300);
    });

    test('en sık tekrar eden kazanır', () {
      final u = usualMealOf('breakfast', [
        gun(DateTime(2026, 9, 29), [1]),
        gun(DateTime(2026, 9, 28), [1]),
        gun(DateTime(2026, 9, 27), [2]),
        gun(DateTime(2026, 9, 26), [2]),
        gun(DateTime(2026, 9, 25), [2]),
      ]);
      expect(u!.items.single.log.foodId, 2);
      expect(u.timesLogged, 3);
    });
  });

  group('reminderMinutesFrom — saati alışkanlıktan öğren', () {
    DateTime d(int day) => DateTime(2026, 9, day);

    test('az örnek → varsayılan', () {
      final m = reminderMinutesFrom([
        kayit(d(28), 'lunch', 1, at: DateTime(2026, 9, 28, 12, 30)),
      ]);
      expect(m['lunch'], defaultReminderMinute['lunch']);
    });

    test('medyan + 60 dk', () {
      final m = reminderMinutesFrom([
        for (final (day, h, mi) in [(26, 12, 50), (27, 13, 0), (28, 13, 10)])
          kayit(d(day), 'lunch', 1, at: DateTime(2026, 9, day, h, mi)),
      ]);
      expect(m['lunch'], 14 * 60);
    });

    test('pencereye kırpılır ve geçmişe sonradan girilenler sayılmaz', () {
      final m = reminderMinutesFrom([
        // Akşam yemeği hep 22:30'da giriliyor → 23:30 değil, 22:30'a kırp.
        for (final day in [25, 26, 27])
          kayit(d(day), 'dinner', 1, at: DateTime(2026, 9, day, 22, 30)),
        // Ertesi gün girilen kahvaltılar alışkanlık değil.
        for (final day in [25, 26, 27])
          kayit(d(day), 'breakfast', 1,
              at: DateTime(2026, 9, day + 1, 7)),
      ]);
      expect(m['dinner'], 22 * 60 + 30);
      expect(m['breakfast'], defaultReminderMinute['breakfast']);
    });
  });

  group('planMealReminders — kayıt varsa bildirim yok', () {
    final saat = {'breakfast': 600, 'lunch': 840, 'dinner': 1230};

    test('bugün girilen öğün ve geçmiş saat atlanır', () {
      final p = planMealReminders(
        now: DateTime(2026, 9, 30, 12),
        loggedToday: {'lunch'},
        minutes: saat,
      );
      final bugun = p.where((r) => r.dayOffset == 0).map((r) => r.mealType);
      // Kahvaltı saati (10:00) geçti, öğle girildi → yalnız akşam.
      expect(bugun, ['dinner']);
      // Sonraki günler tam: 2 gün × 3 öğün.
      expect(p.where((r) => r.dayOffset > 0), hasLength(6));
    });

    test('günler takvimle ilerler', () {
      final p = planMealReminders(
        now: DateTime(2026, 9, 30, 23),
        loggedToday: const {},
        minutes: saat,
      );
      expect(p.first.at, DateTime(2026, 10, 1, 10));
    });
  });

  group('logWeekOf — haftalık hedef, günlük seri değil', () {
    Set<DateTime> gunler(int n) =>
        {for (var i = 0; i < n; i++) DateTime(2026, 9, 28 + i)};

    test('satır türleri', () {
      expect(logWeekOf(gunler(0)).line, LogWeekLine.start);
      expect(logWeekOf(gunler(2)).line, LogWeekLine.going);
      expect(logWeekOf(gunler(2)).left, 3);
      expect(logWeekOf(gunler(4)).line, LogWeekLine.lastOne);
      expect(logWeekOf(gunler(5)).line, LogWeekLine.done);
      expect(logWeekOf(gunler(7)).left, 0);
    });
  });

  group('veritabanı: hızlı giriş, geri alınabilir ekleme, hatırlatma', () {
    late AppDatabase db;
    setUp(() => db = newTestDatabase());
    tearDown(() => db.close());

    test('hızlı giriş: özel besin + 100 g kayıt, değerler aynen', () async {
      final id = await db.nutritionDao.quickAddLog(
        day: DateTime(2026, 9, 30, 13, 5),
        mealType: 'lunch',
        name: 'Döner dürüm',
        kcal: 650,
        protein: 32,
      );
      final logs = await db.nutritionDao
          .getLogsWithFoodForDate(DateTime(2026, 9, 30));
      final l = logs.single;
      expect(l.log.id, id);
      expect(l.log.computedKcal, 650);
      expect(l.log.computedProtein, 32);
      expect(l.log.date, DateTime(2026, 9, 30));
      expect(l.food.source, quickFoodSource);
      expect(l.food.isCustom, isTrue);
    });

    test('toplu ekleme kimlik döner; geri al tam o satırları siler', () async {
      final f = await db.nutritionDao.insertFood(FoodsCompanion.insert(
        name: 'Yulaf',
        kcalPer100g: 380,
        proteinPer100g: 13,
        carbPer100g: 60,
        fatPer100g: 7,
      ));
      final gun = DateTime(2026, 9, 30);
      final onceki = await db.nutritionDao.quickAddLog(
          day: gun, mealType: 'breakfast', name: 'X', kcal: 100);
      final ids = await db.nutritionDao.addFoodsToMealIds(gun, 'breakfast', [
        MealCopyItem(foodId: f, grams: 80),
        MealCopyItem(foodId: f, grams: 20),
      ]);
      expect(ids, hasLength(2));
      await db.nutritionDao.deleteFoodLogs(ids);
      final kalan = await db.nutritionDao.getLogsForDate(gun);
      expect(kalan.map((l) => l.id), [onceki]);
    });

    test('bugün girilen öğün için hatırlatma kurulmaz, eskiler silinir',
        () async {
      final l = await AppL10n.delegate.load(const Locale('tr'));
      final svc = _FakeNotifications();
      final now = DateTime(2026, 9, 30, 9);
      await db.nutritionDao.quickAddLog(
          day: now, mealType: 'breakfast', name: 'X', kcal: 300);
      await syncMealReminders(
          service: svc, dao: db.nutritionDao, l: l, enabled: true, now: now);
      expect(svc.cancelled, hasLength(NotificationService.mealReminderSlots));
      // Bugün: kahvaltı girildi → yalnız öğle + akşam; +2 gün × 3 öğün.
      expect(svc.scheduled, hasLength(2 + 6));
      final bugun = svc.scheduled.values.where((d) => d.day == 30);
      expect(bugun, hasLength(2));
    });

    test('kapalıysa yalnız iptal', () async {
      final l = await AppL10n.delegate.load(const Locale('tr'));
      final svc = _FakeNotifications();
      await syncMealReminders(
          service: svc, dao: db.nutritionDao, l: l, enabled: false);
      expect(svc.scheduled, isEmpty);
      expect(svc.cancelled, hasLength(NotificationService.mealReminderSlots));
    });
  });
}
