import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/insights/weekly_review_providers.dart';
import 'package:fit_pack/features/insights/weekly_review.dart';
import 'package:fit_pack/features/insights/weekly_review_screen.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// Haftalık değerlendirme ekranı (docs/22 §4) — gerçek bellek-içi veritabanı,
/// gerçek sağlayıcılar. Motorun kuralları `weekly_review_test.dart`'ta;
/// burada ekranın o kuralları doğru metinle gösterdiği ölçülür.
void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
  });
  tearDown(() => db.close());

  Future<void> ac(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: AppColors.lightScheme,
          extensions: [AppColors.lightSemantic],
        ),
        locale: const Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const WeeklyReviewScreen(),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> kaydir(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
  }

  testWidgets('boş hafta: bölümler GİZLENMEZ, "kayıt yok" der', (tester) async {
    await db.userProfileDao.ensureProfile();
    await ac(tester);

    expect(find.text('Haftalık değerlendirme'), findsOneWidget);
    expect(find.text('Bu hafta antrenman kaydı yok'), findsOneWidget);
    await kaydir(tester, find.text('Bu hafta beslenme kaydı yok'));
    expect(find.text('Bu hafta beslenme kaydı yok'), findsOneWidget);
    await kaydir(tester, find.text('Bu hafta kilo ölçümü yok'));
    expect(find.text('Bu hafta kilo ölçümü yok'), findsOneWidget);
    await kaydir(tester, find.text('Bu hafta tamamlanmış set yok'));
    expect(find.text('Bu hafta tamamlanmış set yok'), findsOneWidget);
  });

  testWidgets('her kartta "nereden hesaplandı" satırı var', (tester) async {
    await db.userProfileDao.ensureProfile();
    await ac(tester);
    // Beslenme kuralı ekranda açıkça yazmalı (Samet kuralı).
    final kaynak = find.textContaining('Kayıtsız gün 0 sayılmaz');
    await kaydir(tester, kaynak);
    expect(kaynak, findsOneWidget);
  });

  testWidgets('beslenme: kayıtlı günlerin ortalaması gösterilir',
      (tester) async {
    await db.userProfileDao.ensureProfile();
    final bugun = DateTime.now();
    final food = await db.into(db.foods).insert(FoodsCompanion.insert(
          name: 'Test',
          kcalPer100g: 100,
          proteinPer100g: 10,
          carbPer100g: 0,
          fatPer100g: 0,
        ));
    await db.into(db.foodLogs).insert(FoodLogsCompanion.insert(
          date: bugun,
          mealType: 'lunch',
          foodId: food,
          grams: 100,
          computedKcal: 2000,
          computedProtein: 150,
          computedCarb: 0,
          computedFat: 0,
        ));
    await ac(tester);

    final satir =
        find.text('Kayıtlı günlerin ortalaması: 2000 kcal · 150 g protein');
    await kaydir(tester, satir);
    expect(satir, findsOneWidget);
    expect(find.text('1 gün kayıt'), findsOneWidget);
  });

  testWidgets('hedef yönü seçilince profile yazılır, tarihiyle', (tester) async {
    await db.userProfileDao.ensureProfile();
    await ac(tester);

    final al = find.text('Al');
    await kaydir(tester, al);
    await tester.tap(al);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    final p = await db.userProfileDao.getProfile();
    expect(p!.goalDirection, 'gain');
    expect(p.goalDirectionSince, isNotNull,
        reason: 'geçmişe uygulama yasağı bu tarihe dayanıyor');
  });

  test('aynı yönü tekrar seçmek tarihi İLERİ KAYDIRMAZ', () async {
    await db.userProfileDao.ensureProfile();
    final ilk = DateTime(2026, 9, 1);
    await db.userProfileDao.setGoalDirection('lose', now: ilk);
    await db.userProfileDao.setGoalDirection('lose', now: DateTime(2026, 9, 19));
    final p = await db.userProfileDao.getProfile();
    expect(p!.goalDirectionSince, ilk,
        reason: 'kayarsa geçen haftaların yorumu sessizce "bilinmiyor"a döner');
  });

  test('hedef çelişkisi: "al" seçili ama hedef kilo şu ankinin altında', () {
    expect(
      goalConflicts(
          direction: GoalDirection.gain, goalWeightKg: 80, currentWeightKg: 85),
      isTrue,
    );
    expect(
      goalConflicts(
          direction: GoalDirection.lose, goalWeightKg: 80, currentWeightKg: 85),
      isFalse,
    );
    expect(
      goalConflicts(
          direction: GoalDirection.gain, goalWeightKg: 84.5, currentWeightKg: 85),
      isFalse,
      reason: 'küçük farklar çelişki sayılmaz',
    );
    expect(
      goalConflicts(direction: null, goalWeightKg: 80, currentWeightKg: 85),
      isFalse,
    );
  });
}
