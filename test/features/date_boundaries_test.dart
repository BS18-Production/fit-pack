import 'package:drift/drift.dart';
import 'package:fit_pack/core/utils/current_day.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/home/providers/dashboard_providers.dart';
import 'package:fit_pack/features/insights/insight_window.dart';
import 'package:fit_pack/features/nutrition/nutrition_habit_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// Gün sınırları (CR-010, CR-011): gün dönümü güne bağlı verileri yeniler,
/// "son 30 gün" her yerde bugün dahil 30 gün, gün aritmetiği takvimle.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MidnightTimer (ön planda gece yarısı)', () {
    testWidgets('gece yarısında tetiklenir ve ertesi gün için yeniden kurulur',
        (tester) async {
      var saat = DateTime(2026, 10, 17, 23, 59, 30);
      var tetik = 0;
      final timer = MidnightTimer(
        now: () => saat,
        onMidnight: () => tetik++,
      );
      timer.arm();

      await tester.pump(const Duration(seconds: 20));
      expect(tetik, 0, reason: 'gece yarısından önce tetiklenmez');

      // 23:59:30 + 31 sn (gece yarısı + 1 sn pay).
      saat = DateTime(2026, 10, 18, 0, 0, 1);
      await tester.pump(const Duration(seconds: 11));
      expect(tetik, 1);

      // Yeniden kuruldu: bir sonraki gece yarısı 24 saat sonra.
      saat = DateTime(2026, 10, 19, 0, 0, 1);
      await tester.pump(const Duration(hours: 24));
      expect(tetik, 2);
      timer.cancel(); // test sonu bekleyen zamanlayıcı bırakmamalı
    });
  });

  group('takvim aritmetiği', () {
    test('addDays ay/yıl sınırında ve her zaman gece yarısında', () {
      expect(addDays(DateTime(2026, 1, 31, 15), 1), DateTime(2026, 2, 1));
      expect(addDays(DateTime(2026, 12, 31), 1), DateTime(2027));
      expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
      // Yaz saati günü (bazı bölgelerde 23 saat): sonuç yine 00:00.
      final ertesi = addDays(DateTime(2026, 3, 29), 1);
      expect((ertesi.hour, ertesi.minute), (0, 0));
      expect(ertesi.day, 30);
    });

    test('son 30 gün: bugün dahil tam 30 takvim günü', () {
      final w = windowFor(InsightPeriod.last30Days, DateTime(2026, 9, 30, 14));
      expect(w.start, DateTime(2026, 9, 1));
      expect(w.end, DateTime(2026, 10, 1));
      expect(w.days, 30);
    });
  });

  group('güne bağlı provider\'lar', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = newTestDatabase();
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() {
      container.dispose();
      db.close();
    });

    Future<T> bekle<T>(
      ProviderListenable<AsyncValue<T>> p,
      bool Function(T) kosul,
    ) async {
      final sonlanma = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(sonlanma)) {
        final v = container.read(p).valueOrNull;
        if (v != null && kosul(v)) return v;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      fail('beklenen değer 5 sn içinde gelmedi');
    }

    test('dashboard "son 30 gün" 31. günü saymaz (asistanla aynı pencere)',
        () async {
      container.read(currentDayProvider.notifier).state = DateTime(2026, 9, 30);
      for (final d in [DateTime(2026, 8, 31, 18), DateTime(2026, 9, 1, 18)]) {
        await db.workoutDao.insertSession(WorkoutSessionsCompanion(
          date: Value(d),
          phase: const Value(0),
          workoutType: const Value('Test'),
        ));
      }
      final sub = container.listen(last30WorkoutStatsProvider, (_, _) {});
      addTearDown(sub.close);

      final agg = await container.read(last30WorkoutStatsProvider.future);
      expect(agg.sessions, 1, reason: '31 Ağu bugün−30: pencere dışı');
    });

    test('hafta dönümünde kayıt haftası yeni haftaya geçer', () async {
      container.read(currentDayProvider.notifier).state =
          DateTime(2026, 9, 16); // Çarşamba
      final f = await db.nutritionDao.insertFood(const FoodsCompanion(
        name: Value('Test Yemeği'),
        kcalPer100g: Value(100),
        proteinPer100g: Value(10),
        carbPer100g: Value(10),
        fatPer100g: Value(5),
        source: Value('local'),
        isCustom: Value(false),
        isRecipe: Value(false),
      ));
      await db.nutritionDao.insertFoodLog(FoodLogsCompanion(
        date: Value(DateTime(2026, 9, 15, 13)),
        mealType: const Value('lunch'),
        foodId: Value(f),
        grams: const Value(100),
        computedKcal: const Value(100),
        computedProtein: const Value(10),
        computedCarb: const Value(10),
        computedFat: const Value(5),
      ));
      final sub = container.listen(logWeekProvider, (_, _) {});
      addTearDown(sub.close);
      await bekle(logWeekProvider, (w) => w.done == 1);

      // Ön planda pazartesiye geçildi: tablo değişmeden yeni hafta.
      container.read(currentDayProvider.notifier).state = DateTime(2026, 9, 21);
      final yeni = await bekle(logWeekProvider, (w) => w.done == 0);
      expect(yeni.done, 0);
    });
  });
}
