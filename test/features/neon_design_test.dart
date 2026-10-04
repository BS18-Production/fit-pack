import 'dart:io';
import 'dart:ui' as ui;

import 'package:fit_pack/core/router/app_router.dart';
import 'package:fit_pack/core/onboarding/first_run_hints.dart';
import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/update/app_version_gate.dart';
import 'package:fit_pack/features/nutrition/meal_idea_card.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:fit_pack/shared/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/design_fixture.dart';
import '../helpers/test_database.dart';

/// Gerçek router/sağlayıcılar ve temalar: sekmeler, detaylar, 320 pt ve
/// büyük metinde taşma kontrolü. İsteğe bağlı PNG'ler örnek test verisidir.
void main() {
  for (final scenario in [
    (name: 'dark-tr', dark: true, locale: 'tr', width: 393.0, scale: 1.0),
    (name: 'light-en', dark: false, locale: 'en', width: 393.0, scale: 1.0),
    (name: 'narrow-tr', dark: true, locale: 'tr', width: 320.0, scale: 1.3),
    (name: 'large-en', dark: true, locale: 'en', width: 320.0, scale: 1.6),
  ]) {
    testWidgets('neon ${scenario.name}: gerçek sayfalar ve yemek ekle', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await FirstRunHints.initialize(onboarded: true);
      final db = newTestDatabase();
      await seedDesignFixture(db);
      final gate = DesignFixtureGate(db);
      final update = UpdateGate(
        AppVersionGate(
          currentBuild: () async => 1,
          fetchMinimum: () async => null,
        ),
      );
      final router = createAppRouter(gate: gate, updateGate: update);
      final boundary = GlobalKey();
      final errors = <FlutterErrorDetails>[];
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        previousErrorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      var location = AppRoutes.home;
      tester.view.physicalSize = Size(scenario.width * 2, 1704);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        gate.dispose();
        update.dispose();
        await db.close();
      });

      Future<void> settle() async {
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          tester.takeException(),
          isNull,
          reason: '$location\n${errors.map((e) => e.toString()).join('\n')}',
        );
      }

      Future<void> capture(String name) async {
        final dir = Platform.environment['FITPACK_CAPTURE_DIR'];
        if (dir == null) return;
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(dir).create(recursive: true);
          await File(
            '$dir/${scenario.name}-$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: scenario.dark ? AppTheme.dark : AppTheme.light,
              locale: Locale(scenario.locale),
              localizationsDelegates: AppL10n.localizationsDelegates,
              supportedLocales: AppL10n.supportedLocales,
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
                child: GlassBackground(child: child!),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await GoogleFonts.pendingFonts();
        for (final font in [
          ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
          (
            'packages/phosphor_flutter/PhosphorRegular',
            'packages/phosphor_flutter/lib/fonts/Phosphor.ttf',
          ),
          (
            'packages/phosphor_flutter/PhosphorFill',
            'packages/phosphor_flutter/lib/fonts/Phosphor-Fill.ttf',
          ),
        ]) {
          await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
        }
      });
      await settle();
      await capture('home');
      final homeScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('journal.addMeal')),
        150,
        scrollable: homeScroll,
      );
      await settle();
      await Scrollable.ensureVisible(
        tester.element(find.byType(MealIdeaCard)),
        alignment: 0,
      );
      await settle();
      await capture('meal');
      await tester.tap(find.byKey(const ValueKey('journal.addMeal')));
      await settle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await capture('food-sheet');
      router.pop();
      await settle();
      final activity = find.text(
        scenario.locale == 'tr' ? 'Antrenman aktivitesi' : 'Workout activity',
      );
      await tester.scrollUntilVisible(activity, 150, scrollable: homeScroll);
      await settle();
      await capture('activity');
      for (final route in [
        AppRoutes.workout,
        AppRoutes.nutrition,
        AppRoutes.progress,
        AppRoutes.routinePreview(1),
        AppRoutes.routineEdit(1),
        AppRoutes.workoutHistory,
        AppRoutes.summary(1),
        AppRoutes.exercises,
        AppRoutes.exerciseDetail(1),
        AppRoutes.foods,
        AppRoutes.profile,
        AppRoutes.settings,
        AppRoutes.calendar,
        AppRoutes.weeklyReview,
        AppRoutes.progressPhotos,
      ]) {
        location = route;
        router.go(route);
        await settle();
        await capture(route.replaceAll('/', '-'));
      }
    });
  }
}
