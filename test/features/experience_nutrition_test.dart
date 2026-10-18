import 'package:fit_pack/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_pack/core/onboarding/first_run_hints.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/nutrition_dao.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/data/services/openfoodfacts_service.dart';
import 'package:fit_pack/features/home/providers/home_providers.dart';
import 'package:fit_pack/features/nutrition/add_food_sheet.dart';
import 'package:fit_pack/features/nutrition/barcode_flow.dart';
import 'package:fit_pack/features/nutrition/custom_food_dialog.dart';
import 'package:fit_pack/features/nutrition/edit_food_log_sheet.dart';
import 'package:fit_pack/features/nutrition/nutrition_screen.dart';
import 'package:fit_pack/features/nutrition/nutrition_providers.dart';
import 'package:fit_pack/features/nutrition/yesterday_meal.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_database.dart';

class UnavailableFoods extends NutritionDao {
  UnavailableFoods(super.db);
  @override
  Future<List<Food>> getAllFoods() async => throw StateError('disk');
}
class NoBarcode extends OpenFoodFactsService {
  int calls = 0;
  @override
  Future<OffProduct?> fetchByBarcode(String code) async { calls++; return null; }
}
void main() {
  late AppDatabase db;
  Future<void> settle(WidgetTester t) async {
    for (var i=0; i<8; i++) {
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.takeException(), isNull);
  }
  Future<void> open(WidgetTester t, Widget child, {List<Override> overrides = const []}) async {
    await t.pumpWidget(ProviderScope(overrides: [databaseProvider.overrideWithValue(db), ...overrides],
      child: MaterialApp(theme: AppTheme.dark, locale: const Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: child))));
    await settle(t);
  }
  Future<int> food() => db.nutritionDao.insertFood(FoodsCompanion.insert(
    name: 'Test yoğurt', kcalPer100g: 65, proteinPer100g: 4, carbPer100g: 5, fatPer100g: 3));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FirstRunHints.initialize(onboarded: true);
    db = newTestDatabase();
    await db.userProfileDao.ensureProfile();
  });
  tearDown(() => db.close());

  testWidgets('Hedefler düzenleyicinin olduğu Profil rotasını açar', (t) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const NutritionScreen()),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const Scaffold(body: Text('PROFILE EDITOR'))),
    ]);
    addTearDown(router.dispose);
    await t.pumpWidget(ProviderScope(overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(routerConfig: router, theme: AppTheme.dark,
        locale: const Locale('tr'), localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales)));
    await settle(t);
    final l = lookupAppL10n(const Locale('tr'));
    await t.ensureVisible(find.text(l.settingsSectionGoals));
    await t.tap(find.text(l.settingsSectionGoals));
    await settle(t);
    expect(find.text('PROFILE EDITOR'), findsOneWidget);
  });

  testWidgets('panel yükleme hatası dönen gösterge yerine tekrar dene verir', (t) async {
    await open(t, const AddFoodSheet(), overrides: [nutritionDaoProvider.overrideWithValue(UnavailableFoods(db))]);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Tekrar dene'), findsOneWidget);
  });
  testWidgets('özet ve profil hataları görünür ve yeniden denenebilir', (t) async {
    await open(t, const NutritionScreen(), overrides: [
      nutritionTotalsProvider.overrideWith((ref) => Stream.error(StateError('disk'))),
    ]);
    expect(find.text('Tekrar dene'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
    await open(t, const NutritionScreen(), overrides: [
      userProfileProvider.overrideWith((ref) => Stream.error(StateError('disk'))),
    ]);
    expect(find.text('Tekrar dene'), findsOneWidget);
  });
  testWidgets('Yemek Ekle araması odaklanır; öğün paneli kendiliğinden odaklanmaz', (t) async {
    await open(t, const AddFoodSheet(autofocusSearch: true));
    final field = t.widget<TextField>(find.byType(TextField).first);
    expect(field.autofocus, isTrue);
    await t.pumpWidget(const SizedBox.shrink());
    await open(t, const AddFoodSheet(mealType: 'lunch'));
    expect(t.widget<TextField>(find.byType(TextField).first).autofocus, isFalse);
  });
  testWidgets('kayıt miktarı panelden güncellenir ve adsız ± yok', (t) async {
    final f = await food();
    final day = DateTime.now();
    final id = await db.nutritionDao.insertFoodLog(FoodLogsCompanion.insert(date: day,
      mealType: 'lunch', foodId: f, grams: 100,
      computedKcal: 65, computedProtein: 4, computedCarb: 5, computedFat: 3));
    final item = (await db.nutritionDao.getLogsWithFoodForDate(day)).single;
    await open(t, Builder(builder: (context) => TextButton(
      onPressed: () => showEditFoodLogSheet(context, item), child: const Text('edit'))));
    await t.tap(find.text('edit'));
    await settle(t);
    expect(find.byTooltip('Miktarı azalt'), findsOneWidget);
    expect(find.byTooltip('Miktarı artır'), findsOneWidget);
    await t.enterText(find.byType(TextField), '250');
    await t.ensureVisible(find.textContaining('Güncelle ·'));
    await t.tap(find.textContaining('Güncelle ·'));
    await settle(t);
    final updated = (await db.nutritionDao.getLogsForDate(day)).single;
    expect(updated.id, id);
    expect(updated.grams, 250);
    expect(updated.computedKcal, 162.5);
  });
  testWidgets('Dünkü gibi yalnız o öğünü kopyalar; Geri al eklenenleri siler', (t) async {
    final f = await food();
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    await db.nutritionDao.insertFoodLog(FoodLogsCompanion.insert(date: yesterday,
      mealType: 'breakfast', foodId: f, grams: 100,
      computedKcal: 65, computedProtein: 4, computedCarb: 5, computedFat: 3));
    await open(t, const YesterdayMealShortcut(mealType: 'breakfast'));
    await t.tap(find.text('Dünkü gibi ekle'));
    await settle(t);
    expect((await db.nutritionDao.getLogsForDate(now)).single.mealType, 'breakfast');
    await t.tap(find.text('Geri al'));
    await settle(t);
    expect(await db.nutritionDao.getLogsForDate(now), isEmpty);
    expect((await db.nutritionDao.getLogsForDate(yesterday)).length, 1);
  });
  testWidgets('bilinmeyen barkod özel besin formuna taşınır', (t) async {
    Food? result;
    await open(t, Consumer(builder: (context, ref, _) => TextButton(
      onPressed: () async { result = await lookupBarcodeToFood(context, ref, '869000000001'); },
      child: const Text('scan'))), overrides: [openFoodFactsServiceProvider.overrideWithValue(NoBarcode())]);
    await t.tap(find.text('scan'));
    await settle(t);
    await t.tap(find.text('Kendi besinini oluştur'));
    await settle(t);
    expect(find.byType(CustomFoodDialog), findsOneWidget);
    expect(find.text('Barkod: 869000000001'), findsOneWidget);
    // İptal yerel katalogda yanlış besin oluşturmaz.
    await t.tap(find.text('İptal'));
    await settle(t);
    expect(result, isNull);
    expect(await db.nutritionDao.getFoodByBarcode('869000000001'), isNull);
  });
  testWidgets('özel besin barkodla kaydedilir; ikinci tarama yerelde eşleşir', (t) async {
    Food? result;
    final off = NoBarcode();
    await open(t, Consumer(builder: (context, ref, _) => TextButton(
      onPressed: () async { result = await lookupBarcodeToFood(context, ref, '869000000002'); },
      child: const Text('scan'))), overrides: [openFoodFactsServiceProvider.overrideWithValue(off)]);
    await t.tap(find.text('scan'));
    await settle(t);
    await t.tap(find.text('Kendi besinini oluştur'));
    await settle(t);
    await t.enterText(find.byType(TextFormField).first, 'Özel yoğurt');
    await t.enterText(find.byType(TextFormField).at(2), '65');
    t.testTextInput.hide();
    await t.pumpAndSettle();
    await t.tap(find.text('Kaydet'));
    await settle(t);
    expect(result?.barcode, '869000000002');
    expect((await db.nutritionDao.getFoodByBarcode('869000000002'))?.name, 'Özel yoğurt');
    await t.tap(find.text('scan'));
    await settle(t);
    expect(off.calls, 1);
    expect(result?.name, 'Özel yoğurt');
  });

}
