import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/nutrition/foods_screen.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// Yemekler ekranındaki grup filtresi (C-5) — çipler çizilir mi, seçim listeyi
/// süzer mi, kategorisiz kurulumda şerit gizlenir mi.
void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
  });
  tearDown(() => db.close());

  Future<void> addFood(String name, String? category) =>
      db.nutritionDao.insertFood(FoodsCompanion.insert(
        name: name,
        category: Value(category),
        kcalPer100g: 100,
        proteinPer100g: 10,
        carbPer100g: 10,
        fatPer100g: 2,
        source: const Value('local'),
        isCustom: const Value(false),
        isRecipe: const Value(false),
      ));

  Future<void> open(WidgetTester tester) async {
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
        home: const FoodsScreen(),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('grup seçilince liste süzülür, tekrar dokununca açılır',
      (tester) async {
    await addFood('Tavuk Göğsü', 'meat');
    await addFood('Süt', 'dairy');
    await addFood('Elma', 'fruit');
    await open(tester);

    expect(find.text('Tavuk Göğsü'), findsOneWidget);
    expect(find.text('Süt ürünleri'), findsOneWidget, reason: 'çip görünmeli');

    await tester.tap(find.text('Süt ürünleri'));
    await tester.pump();
    expect(find.text('Süt'), findsOneWidget);
    expect(find.text('Tavuk Göğsü'), findsNothing);
    expect(find.text('Elma'), findsNothing);

    await tester.tap(find.text('Süt ürünleri')); // seçimi kaldır
    await tester.pump();
    expect(find.text('Tavuk Göğsü'), findsOneWidget);
  });

  testWidgets('arama ile grup birlikte çalışır', (tester) async {
    await addFood('Tavuk Göğsü', 'meat');
    await addFood('Tavuk Pilav', 'grain');
    await open(tester);

    await tester.enterText(find.byType(TextField).first, 'tavuk');
    await tester.pump();
    expect(find.text('Tavuk Göğsü'), findsOneWidget);
    expect(find.text('Tavuk Pilav'), findsOneWidget);

    await tester.tap(find.text('Tahıl ve nişasta'));
    await tester.pump();
    expect(find.text('Tavuk Pilav'), findsOneWidget);
    expect(find.text('Tavuk Göğsü'), findsNothing);
  });

  testWidgets('kategorisiz kurulumda çip şeridi çizilmez', (tester) async {
    await addFood('Kendi yemeğim', null);
    await open(tester);

    expect(find.text('Kendi yemeğim'), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
  });
}
