import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';
import 'package:fit_pack/features/onboarding/onboarding_screen.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// docs/49 A+B — kurulum: antrenman soruları → program önerisi → kilo →
/// plan. Program seçilirse rutinler eklenir, "Kendim kuracağım"da eklenmez.
void main() {
  late AppDatabase db;
  late AuthGate gate;
  final l = lookupAppL10n(const Locale('tr'));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
    gate = AuthGate(db);
  });
  tearDown(() async {
    gate.dispose();
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpOnboarding(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authGateProvider.overrideWithValue(gate),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dark,
          locale: const Locale('tr'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> next(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await settle(tester);
  }

  /// İki soru → program sayfası; [skip] ise "Kendim kuracağım" seçilir.
  Future<void> runFlow(WidgetTester tester, {required bool skip}) async {
    await pumpOnboarding(tester);
    expect(find.text(l.onbTrainingTitle), findsOneWidget);
    await tester.tap(find.text(l.onbExpSome));
    await tester.tap(find.text(l.onbDays4));
    await tester.pump();
    await next(tester, l.commonNext);

    expect(find.text(l.onbProgramTitle), findsOneWidget);
    expect(find.text(l.onbProgramUse), findsOneWidget);
    if (skip) {
      await tester.tap(find.text(l.onbProgramSkip));
      await tester.pump();
      expect(find.text(l.onbProgramUse), findsNothing);
    }
    await next(tester, l.commonNext);

    expect(find.text(l.onbAboutYouTitle), findsOneWidget);
    expect(
      find.text(l.settingsHeight),
      findsNothing,
      reason: 'boy artık kurulumda sorulmuyor (karar 3)',
    );
    await tester.enterText(
      find.widgetWithText(TextField, l.onbCurrentWeight),
      '80',
    );
    await tester.pump();
    await next(tester, l.commonNext);

    expect(find.widgetWithText(TextField, l.onbDailyKcal), findsOneWidget);
    await next(tester, l.onbStart);
  }

  Future<List<Routine>> routines(WidgetTester tester) async =>
      (await tester.runAsync(() => db.workoutDao.getActiveRoutines()))!;

  testWidgets('program seçilince rutinler eklenir, Ana Sayfa açılır', (
    tester,
  ) async {
    await runFlow(tester, skip: false);

    expect(find.text('HOME'), findsOneWidget);
    expect(gate.onboarded, isTrue);
    final rs = await routines(tester);
    expect(rs, isNotEmpty);
    expect(rs.map((r) => r.programKey).toSet(), {'upperlower_intermediate'});
    final profile = await tester.runAsync(() => db.userProfileDao.getProfile());
    expect(profile!.onboarded, isTrue);
  });

  testWidgets('"Kendim kuracağım" → rutin eklenmez, kurulum yine biter', (
    tester,
  ) async {
    await runFlow(tester, skip: true);

    expect(find.text('HOME'), findsOneWidget);
    expect(gate.onboarded, isTrue);
    expect(await routines(tester), isEmpty);
  });

  testWidgets('iki soru cevaplanmadan İleri kapalı', (tester) async {
    await pumpOnboarding(tester);
    FilledButton btn() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, l.commonNext),
    );
    expect(btn().onPressed, isNull);
    await tester.tap(find.text(l.onbExpBeginner));
    await tester.pump();
    expect(btn().onPressed, isNull);
    await tester.tap(find.text(l.onbDays56));
    await tester.pump();
    expect(btn().onPressed, isNotNull);
    await next(tester, l.commonNext);
    // Yeni başlayan + 5–6 gün → 4 günlük öneri ve nedeni.
    expect(find.text(l.onbProgramRestNote), findsOneWidget);
  });
}
