import 'dart:convert';

import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';
import 'package:fit_pack/features/home/providers/weekly_goal_provider.dart';
import 'package:fit_pack/features/onboarding/onboarding_screen.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

void main() {
  testWidgets('ilk kayıt hatasından sonra gün seçimini düzeltip tekrar dene', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final db = newTestDatabase();
    final gate = AuthGate(db);
    final l = lookupAppL10n(const Locale('tr'));
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        weeklyGoalAccountProvider.overrideWithValue('retry-account'),
        authGateProvider.overrideWithValue(gate),
      ],
    );
    final router = GoRouter(
      initialLocation: AppRoutes.onboarding,
      routes: [
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
      ],
    );
    addTearDown(() async {
      router.dispose();
      container.dispose();
      gate.dispose();
      await db.close();
    });
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.dark,
          locale: const Locale('tr'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    Future<void> settle() async {
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await settle();
    }

    Future<void> next() => tap(find.widgetWithText(FilledButton, l.commonNext));

    await settle();
    await tap(find.text(l.setupSourceCatalog));
    await tap(find.text(l.onbExpSome));
    await tap(find.byKey(const ValueKey('setup.days.3')));
    await next();
    await next();
    await tester.enterText(
      find.widgetWithText(TextField, l.onbCurrentWeight),
      '80',
    );
    await tap(find.text(l.phaseMaintain));
    await next();

    await tester.runAsync(
      () => db.customStatement(
        'CREATE TEMP TRIGGER fail_initial_weight BEFORE INSERT ON body_measurements '
        "BEGIN SELECT RAISE(ABORT, 'test write failure'); END",
      ),
    );
    await tap(find.widgetWithText(FilledButton, l.onbStart));
    expect(find.text(l.setupSaveError), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
    expect(
      (await tester.runAsync(() => db.bodyDao.getAllMeasurements()))!,
      isEmpty,
    );
    expect(
      (await tester.runAsync(() => db.workoutDao.getActiveRoutines()))!,
      isEmpty,
    );
    expect(await container.read(selectedWeeklyGoalProvider.future), 3);

    await tester.runAsync(
      () => db.customStatement('DROP TRIGGER fail_initial_weight'),
    );
    // Önceki Snackbar alt gezinme düğmelerini kapatmasın.
    final context = tester.element(find.byType(OnboardingScreen));
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tap(find.widgetWithText(TextButton, l.commonBack));
    }
    await tap(find.byKey(const ValueKey('setup.days.4')));
    await next();
    await next();
    await next();
    await tap(find.widgetWithText(FilledButton, l.onbStart));

    expect(find.text('HOME'), findsOneWidget);
    expect(gate.onboarded, isTrue);
    final profile = await tester.runAsync(() => db.userProfileDao.getProfile());
    expect(profile!.onboarded, isTrue);
    final weights = (await tester.runAsync(
      () => db.bodyDao.getAllMeasurements(),
    ))!;
    expect(weights.length, 1);
    expect(weights.single.weightKg, 80);
    final routines = (await tester.runAsync(
      () => db.workoutDao.getActiveRoutines(),
    ))!;
    expect(routines.length, 4);
    expect(routines.map((routine) => routine.programKey).toSet(), {
      'upperlower_intermediate',
    });
    expect(await container.read(selectedWeeklyGoalProvider.future), 4);
    final prefs = await SharedPreferences.getInstance();
    final saved =
        jsonDecode(prefs.getString('training_setup_v1_retry-account')!) as Map;
    expect(saved['exactDays'], 4);
  });
}
