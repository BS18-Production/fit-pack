import 'dart:io';
import 'dart:ui' as ui;
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/health/step_providers.dart';
import 'package:fit_pack/features/health/step_source.dart';
import 'package:fit_pack/features/home/home_screen.dart';
import 'package:fit_pack/features/nutrition/add_food_sheet.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/fake_step_source.dart';
import '../helpers/test_database.dart';
void main() {
  for (final scenario in [
    (name: 'first-day-dark', width: 393.0, scale: 1.0, dark: true),
    (name: 'first-day-large', width: 320.0, scale: 1.6, dark: true),
    (name: 'first-day-light', width: 320.0, scale: 1.3, dark: false),
  ]) {
    testWidgets('deneyim render ${scenario.name}: ilk gün ve miktar paneli', (t) async {
      SharedPreferences.setMockInitialValues({});
      final db = newTestDatabase();
      await db.userProfileDao.ensureProfile();
      final key = GlobalKey();
      t.view.physicalSize = Size(scenario.width * 2, 1704);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      addTearDown(db.close);
      Future<void> settle() async {
        for(var i=0; i<8; i++) {
          await t.runAsync(() => Future<void>.delayed(Duration.zero));
          await t.pump(const Duration(milliseconds:100));
        }
        expect(t.takeException(), isNull);
      }
      Future<void> capture(String name) async {
        final dir = Platform.environment['FITPACK_CAPTURE_DIR'];
        if(dir == null) return;
        await t.runAsync(() async {
          final image = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio:2);
          final bytes = await image.toByteData(format:ui.ImageByteFormat.png);
          await Directory(dir).create(recursive:true);
          await File('$dir/${scenario.name}-$name.png').writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      Future<void> open(Widget screen) async {
        await t.pumpWidget(ProviderScope(overrides: [databaseProvider.overrideWithValue(db),
          stepSourceProvider.overrideWithValue(FakeStepSource(status: StepPlatformStatus.unavailable))],
          child: RepaintBoundary(key:key, child: MaterialApp(
            theme: scenario.dark ? AppTheme.dark : AppTheme.light,
            locale: const Locale('tr'), localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scenario.scale)), child:child!),
            home: Scaffold(body:screen)))));
        await settle();
      }
      await open(const HomeScreen());
      final button = t.getRect(find.byKey(const ValueKey('home.pickProgram')));
      expect(button.bottom, lessThan(750));
      await capture('home');
      await db.nutritionDao.insertFood(FoodsCompanion.insert(name:'Yoğurt test',
        kcalPer100g:65, proteinPer100g:4, carbPer100g:5, fatPer100g:3));
      await open(const AddFoodSheet(mealType:'lunch'));
      await t.scrollUntilVisible(find.text('Yoğurt test'), 160, scrollable: find.byType(Scrollable).last);
      await t.tap(find.text('Yoğurt test'));
      await settle();
      expect(find.byType(FoodAmountPanel), findsOneWidget);
      await t.scrollUntilVisible(find.textContaining('Öğle yemeğine ekle ·'), 160,
        scrollable: find.byType(Scrollable).last);
      await settle();
      await capture('amount');
    });
  }
}
