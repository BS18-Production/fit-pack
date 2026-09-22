import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/nutrition/meal_copy_sheet.dart';
import 'package:fit_pack/features/nutrition/nutrition_screen.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// "Başka günden kopyala" paneli (docs/21 #2 küçük sürüm) — gerçek bellek-içi
/// veritabanı, gerçek panel akışı: gün seç → miktarları düzenle → ekle.
///
/// Tarihler `DateTime.now()`e göre kurulur: panelin sorgusu pencereyi gerçek
/// bugünden hesaplıyor (ekranda da öyle çalışacak).
void main() {
  late AppDatabase db;
  late DateTime bugun;
  late DateTime dun;

  setUp(() {
    db = newTestDatabase();
    final now = DateTime.now();
    bugun = DateTime(now.year, now.month, now.day);
    dun = DateTime(now.year, now.month, now.day - 1);
  });
  tearDown(() => db.close());

  Future<int> besin(String name, {double kcal = 100}) =>
      db.nutritionDao.insertFood(FoodsCompanion(
        name: Value(name),
        kcalPer100g: Value(kcal),
        proteinPer100g: const Value(10),
        carbPer100g: const Value(10),
        fatPer100g: const Value(2),
      ));

  Future<void> kayit(int foodId, DateTime date, String mealType,
      {double grams = 100}) async {
    final oran = grams / 100;
    await db.nutritionDao.insertFoodLog(FoodLogsCompanion(
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

  /// Paneli gerçek bir modal rota olarak açar (SnackBar'ı da görebilelim).
  Future<void> ac(WidgetTester tester,
      {String mealType = 'breakfast'}) async {
    // Telefon boyutu: 800×600'lük varsayılan test ekranında alt bilgi çubuğu
    // ile liste üst üste biniyor.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

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
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showMealCopySheet(context,
                    mealType: mealType, targetDay: bugun),
                child: const Text('panel'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('panel'));
    await tester.pumpAndSettle();
  }

  testWidgets('gün listesi: geçmiş gün görünür, hedef gün listelenmez',
      (tester) async {
    final a = await besin('Yulaf');
    await kayit(a, dun, 'breakfast');
    await kayit(a, bugun, 'breakfast'); // hedef gün — listelenmemeli

    await ac(tester);

    expect(find.text('Kahvaltı kopyala'), findsOneWidget);
    expect(find.text('Hangi günden kopyalanacak?'), findsOneWidget);
    expect(find.text('Dün'), findsOneWidget);
    expect(find.text('Bugün'), findsNothing);
  });

  testWidgets('başka öğünün kaydı bu panele girmez', (tester) async {
    final a = await besin('Mercimek');
    await kayit(a, dun, 'lunch');

    await ac(tester); // kahvaltı paneli

    expect(find.text('Son 14 günde bu öğünde kayıt yok'), findsOneWidget);
    expect(find.text('Dün'), findsNothing);
  });

  testWidgets('gün seçilince besinler düzenlenebilir listede açılır',
      (tester) async {
    final a = await besin('Yulaf');
    final b = await besin('Süt');
    await kayit(a, dun, 'breakfast', grams: 80);
    await kayit(b, dun, 'breakfast', grams: 200);

    await ac(tester);
    await tester.tap(find.text('Dün'));
    await tester.pumpAndSettle();

    expect(find.text('Miktarları değiştir, istemediğini çıkar'),
        findsOneWidget);
    expect(find.text('Yulaf'), findsOneWidget);
    expect(find.text('Süt'), findsOneWidget);
    // Gram kutuları kaynak kaydın miktarıyla dolu gelir.
    expect(find.widgetWithText(TextFormField, '80'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '200'), findsOneWidget);
    expect(find.text('Ekle (2)'), findsOneWidget);
    // Toplam: 80 g + 200 g × 100 kcal/100 g = 280 kcal
    expect(find.text('280 kcal'), findsOneWidget);
  });

  testWidgets('miktar değiştirilip eklenir — kayıt düzenlenen gramla düşer',
      (tester) async {
    final a = await besin('Yulaf');
    final b = await besin('Süt');
    await kayit(a, dun, 'breakfast', grams: 80);
    await kayit(b, dun, 'breakfast', grams: 200);

    await ac(tester);
    await tester.tap(find.text('Dün'));
    await tester.pumpAndSettle();

    // İlk satır (Yulaf) 80 → 150 g. Alt bilgi çubuğundaki toplam canlı
    // güncellenir: 150 + 200 = 350 kcal (satır başlıklarıyla karışmaz).
    await tester.enterText(find.byType(TextFormField).first, '150');
    await tester.pump();
    expect(find.text('350 kcal'), findsOneWidget);

    await tester.tap(find.text('Ekle (2)'));
    await tester.pumpAndSettle();

    final loglar = await db.nutritionDao.getLogsWithFoodForDate(bugun);
    expect(loglar.length, 2);
    final yulaf = loglar.firstWhere((l) => l.food.name == 'Yulaf').log;
    expect(yulaf.grams, 150);
    expect(yulaf.computedKcal, 150);
    expect(loglar.firstWhere((l) => l.food.name == 'Süt').log.grams, 200);
    expect(find.text('2 kayıt kopyalandı'), findsOneWidget);
  });

  testWidgets('listeden çıkarılan besin eklenmez', (tester) async {
    final a = await besin('Yulaf');
    final b = await besin('Süt');
    await kayit(a, dun, 'breakfast');
    await kayit(b, dun, 'breakfast');

    await ac(tester);
    await tester.tap(find.text('Dün'));
    await tester.pumpAndSettle();

    // "Süt" satırının çıkar düğmesi — satırlar log id ile anahtarlı (H-02).
    await tester.tap(find.descendant(
      of: find.ancestor(of: find.text('Süt'), matching: find.byType(Row)).first,
      matching: find.byIcon(Icons.close_rounded),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Süt'), findsNothing);
    expect(find.text('Ekle (1)'), findsOneWidget);

    await tester.tap(find.text('Ekle (1)'));
    await tester.pumpAndSettle();

    final loglar = await db.nutritionDao.getLogsWithFoodForDate(bugun);
    expect(loglar.map((l) => l.food.name).toList(), ['Yulaf']);
  });

  testWidgets('geri: gün listesine döner, seçim sıfırlanır', (tester) async {
    final a = await besin('Yulaf');
    await kayit(a, dun, 'breakfast');

    await ac(tester);
    await tester.tap(find.text('Dün'));
    await tester.pumpAndSettle();
    expect(find.text('Yulaf'), findsOneWidget);

    await tester.tap(find.text('Geri'));
    await tester.pumpAndSettle();

    expect(find.text('Hangi günden kopyalanacak?'), findsOneWidget);
    expect(find.text('Dün'), findsOneWidget);
  });

  testWidgets('kopyalama mevcut öğünün üstüne yazmaz, ekler', (tester) async {
    final a = await besin('Yulaf');
    final b = await besin('Süt');
    await kayit(a, dun, 'breakfast');
    await kayit(b, bugun, 'breakfast'); // bugünkü kahvaltı zaten dolu

    await ac(tester);
    await tester.tap(find.text('Dün'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ekle (1)'));
    await tester.pumpAndSettle();

    final loglar = await db.nutritionDao.getLogsWithFoodForDate(bugun);
    expect(loglar.map((l) => l.food.name).toSet(), {'Süt', 'Yulaf'});
  });

  testWidgets('öğün kartındaki "⋯" menüsü paneli doğru öğünle açar',
      (tester) async {
    // İlk-kullanım ipucu görülmüş sayılır — spotlight overlay'i dokunuşları
    // yutmasın (docs/15 §B).
    SharedPreferences.setMockInitialValues({'hint_seen_nutrition': true});
    final a = await besin('Yulaf');
    await kayit(a, dun, 'breakfast');

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

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
        home: const NutritionScreen(),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Kartlar öğün sırasında: ilk "⋯" kahvaltıya ait.
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başka günden kopyala'));
    await tester.pumpAndSettle();

    expect(find.text('Kahvaltı kopyala'), findsOneWidget);
    expect(find.text('Dün'), findsOneWidget);
  });
}
