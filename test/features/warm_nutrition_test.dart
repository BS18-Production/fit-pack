import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_pack/core/onboarding/first_run_hints.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/core/theme/nutrition_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/nutrition/add_food_sheet.dart';
import 'package:fit_pack/features/nutrition/nutrition_screen.dart';
import 'package:fit_pack/features/nutrition/warm_nutrition_summary.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:fit_pack/shared/widgets/progress_indicators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/design_fixture.dart';
import '../helpers/test_database.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'Öğün tercihi korunur; yeni kayıt açılır; silme ve geri alma reaktif',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await FirstRunHints.initialize(onboarded: true);
      final db = newTestDatabase();
      await seedDesignFixture(db);
      Future<int> lunch() => db.nutritionDao.insertFoodLog(
        FoodLogsCompanion(
          date: Value(DateTime.now()),
          mealType: const Value('lunch'),
          foodId: const Value(1),
          grams: const Value(100),
          computedKcal: const Value(65),
          computedProtein: const Value(4),
          computedCarb: const Value(5),
          computedFat: const Value(3),
        ),
      );
      await lunch();
      tester.view.physicalSize = const Size(786, 2000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await db.close();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            themeAnimationDuration: Duration.zero,
            theme: AppTheme.dark,
            locale: const Locale('en'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: const NutritionScreen(),
          ),
        ),
      );
      await settle(tester);
      expect(find.text('Yoğurt'), findsOneWidget); // en yeni öğün açık
      final lunchHeader = find.byKey(const ValueKey('nutrition.meal.lunch'));
      await tester.ensureVisible(lunchHeader);
      await tester.tap(lunchHeader);
      await settle(tester);
      expect(find.text('Yoğurt'), findsNothing);
      await lunch();
      await settle(tester);
      expect(
        find.text('Yoğurt'),
        findsNWidgets(2),
      ); // yalnız yeni kayıtlı öğün açılır
      await tester.ensureVisible(find.byTooltip('Delete').first);
      await tester.tap(find.byTooltip('Delete').first);
      await settle(tester);
      expect((await db.nutritionDao.getLogsForDate(DateTime.now())).length, 2);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect((await db.nutritionDao.getLogsForDate(DateTime.now())).length, 3);
      expect(find.text('Yoğurt'), findsNWidgets(2));
      final macros = find.byKey(const ValueKey('nutrition.macros'));
      await tester.ensureVisible(macros);
      await tester.tap(macros);
      await settle(tester);
      expect(find.byType(MacroInlineText), findsNWidgets(2));
      await tester.tap(macros);
      await settle(tester);
      expect(find.byType(MacroInlineText), findsNothing);
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await settle(tester);
      expect(
        find.byKey(const ValueKey('nutrition.addFood')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('nutrition.scan')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('nutrition.addFood')));
      await settle(tester);
      expect(find.byType(AddFoodSheet), findsOneWidget);
      final quickAdd = find.byWidgetPredicate(
        (w) => w is IconButton && (w.tooltip?.startsWith('Add now:') ?? false),
      );
      await tester.ensureVisible(quickAdd.first);
      await tester.tap(quickAdd.first);
      await settle(tester);
      expect(
        find.byType(AddFoodSheet),
        findsOneWidget,
      ); // art arda eklemek için açık
      expect((await db.nutritionDao.getLogsForDate(DateTime.now())).length, 4);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect((await db.nutritionDao.getLogsForDate(DateTime.now())).length, 3);
    },
  );

  testWidgets(
    'Halka sıfır, hedef ve hedef üzerini doğru anlatır; azaltılmış hareket anlık',
    (tester) async {
      final semantics = tester.ensureSemantics();

      Future<void> ring(double kcal) async {
        await tester.pumpWidget(
          MaterialApp(
            themeAnimationDuration: Duration.zero,
            theme: NutritionTheme.of(AppTheme.dark),
            locale: const Locale('en'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Center(child: WarmEnergyRing(consumed: kcal, goal: 2400)),
            ),
          ),
        );
        await tester.pump();
      }

      try {
        await ring(0);
        expect(find.text('kcal remaining'), findsOneWidget);
        await ring(2400);
        expect(find.text('kcal to goal'), findsOneWidget);
        await ring(2600);
        expect(find.text('200'), findsOneWidget);
        expect(find.text('kcal above goal'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('200 kcal above goal')),
          findsOneWidget,
        );
        final builder = tester.widget<AnimatedBuilder>(
          find.descendant(
            of: find.byType(WarmEnergyRing),
            matching: find.byType(AnimatedBuilder),
          ),
        );
        expect((builder.animation as AnimationController).isAnimating, isFalse);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
