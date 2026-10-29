import 'dart:ui' show Tristate;

import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';
import 'package:fit_pack/features/onboarding/onboarding_screen.dart';
import 'package:fit_pack/features/home/providers/weekly_goal_provider.dart';
import 'package:fit_pack/features/onboarding/training_setup_providers.dart';
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

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    bool failSetupWrite = false,
  }) async {
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
          weeklyGoalAccountProvider.overrideWithValue('onboarding-test'),
          authGateProvider.overrideWithValue(gate),
          if (failSetupWrite)
            trainingSetupPreferencesProvider.overrideWith(
              (ref) async => _FailedSetupPreferences(),
            ),
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

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> runFlow(
    WidgetTester tester, {
    required bool skip,
    bool failSetupWrite = false,
  }) async {
    await pumpOnboarding(tester, failSetupWrite: failSetupWrite);
    expect(find.text(l.onbTrainingTitle), findsOneWidget);
    await tapVisible(
      tester,
      find.text(skip ? l.setupSourceOwn : l.setupSourceCatalog),
    );
    if (!skip) {
      await tapVisible(tester, find.text(l.onbExpSome));
    } else {
      expect(find.text(l.onbExperienceQ), findsNothing);
    }
    await tapVisible(tester, find.byKey(const ValueKey('setup.days.4')));
    await next(tester, l.commonNext);

    expect(find.text(l.onbProgramTitle), findsOneWidget);
    expect(
      find.text(skip ? l.setupOwnTitle : l.setupRecommendationReason(4)),
      findsOneWidget,
    );
    await next(tester, l.commonNext);

    expect(find.text(l.onbAboutYouTitle), findsOneWidget);
    expect(find.text(l.settingsHeight), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextField, l.onbCurrentWeight),
      '80',
    );
    await tester.pump();
    // Kilo verme yönü artık kullanıcı yerine seçilmez.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, l.commonNext),
    );
    expect(button.onPressed, isNull);
    await tapVisible(tester, find.text(l.phaseMaintain));
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

  testWidgets('katalogda deneyim zorunlu, kesin 2 gün ayrıca onaylanır', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    FilledButton nextButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, l.commonNext),
    );
    expect(nextButton().onPressed, isNull);
    expect(find.text(l.onbExperienceQ), findsNothing);
    await tapVisible(tester, find.text(l.setupSourceCatalog));
    await tapVisible(tester, find.byKey(const ValueKey('setup.days.2')));
    expect(nextButton().onPressed, isNull);
    await tapVisible(tester, find.text(l.onbExpBeginner));
    expect(nextButton().onPressed, isNotNull);
    await next(tester, l.commonNext);
    expect(find.text(l.setupFrequencyMismatch(2, 3)), findsOneWidget);
    expect(nextButton().onPressed, isNull);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('setup.confirmMismatch')),
    );
    expect(nextButton().onPressed, isNotNull);
  });

  testWidgets(
    'tercih yazılamazsa kurulum başarısızlığı görünür, veri yazılmaz',
    (tester) async {
      await runFlow(tester, skip: true, failSetupWrite: true);
      expect(find.text('HOME'), findsNothing);
      expect(find.text(l.setupSaveError), findsOneWidget);
      expect(gate.onboarded, isFalse);
      final profile = await tester.runAsync(
        () => db.userProfileDao.getProfile(),
      );
      expect(profile?.onboarded ?? false, isFalse);
      expect(await routines(tester), isEmpty);
      expect(
        (await tester.runAsync(() => db.bodyDao.getAllMeasurements()))!,
        isEmpty,
      );
    },
  );

  testWidgets('tam gün ve deneyim cihazdaki kurulum tercihine kaydedilir', (
    tester,
  ) async {
    await runFlow(tester, skip: false);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('training_setup_v1_onboarding-test');
    expect(raw, contains('"exactDays":4'));
    expect(raw, contains('"experience":"some"'));
    expect((await routines(tester)).map((r) => r.programKey).toSet(), {
      'upperlower_intermediate',
    });
  });
  testWidgets('tek seçimler ekran okuyucuya seçili durumunu bildirir', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
    await pumpOnboarding(tester);

    void choiceState(String label, bool selected) {
      final wrapper = find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((widget) => widget is Semantics &&
          widget.properties.inMutuallyExclusiveGroup == true),
      ).first;
      final node = tester.getSemantics(wrapper);
      expect(node.flagsCollection.isButton, isTrue, reason: label);
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue, reason: label);
      expect(node.flagsCollection.isSelected == Tristate.isTrue, selected, reason: label);
    }

    choiceState(l.setupSourceCatalog, false);
    choiceState(l.setupSourceOwn, false);
    await tapVisible(tester, find.text(l.setupSourceOwn));
    choiceState(l.setupSourceOwn, true);
    choiceState(l.setupSourceCatalog, false);
    await tapVisible(tester, find.text(l.setupSourceCatalog));
    choiceState(l.setupSourceOwn, false);
    choiceState(l.setupSourceCatalog, true);
    await tapVisible(tester, find.text(l.onbExpSome));
    choiceState(l.onbExpSome, true);
    choiceState(l.onbExpBeginner, false);
    await tapVisible(tester, find.byKey(const ValueKey('setup.days.4')));
    await next(tester, l.commonNext);
    await next(tester, l.commonNext);
    await tapVisible(tester, find.text(l.phaseMaintain));
    choiceState(l.phaseMaintain, true);
    choiceState(l.phaseCut, false);
    } finally {
      semantics.dispose();
    }
  });

}

class _FailedSetupPreferences extends Fake implements SharedPreferences {
  @override
  String? getString(String key) => null;

  @override
  Future<bool> setString(String key, String value) async => false;
}
