// Test-only: normal app UI + real Dev, with a process-local network fault.
import 'dart:convert';
import 'dart:io';
import 'package:fit_pack/app.dart';
import 'package:fit_pack/main.dart' as product;
import 'package:fit_pack/core/auth/secure_session_storage.dart';
import 'package:fit_pack/core/config/supabase_config.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/analytics/analytics_providers.dart';
import 'package:fit_pack/features/onboarding/onboarding_screen.dart';
import 'package:fit_pack/features/workout/workout_summary_screen.dart';
import 'package:fit_pack/features/sync/sync_providers.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:fit_pack/shared/widgets/setting_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'phase1_dev_main.dart' show verifyPhase1DevTarget;

class _DevTransport extends http.BaseClient {
  final http.Client inner = http.Client();
  bool offline = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (offline && request.url.host == 'qecbnrkbordkqeogmevi.supabase.co') {
      return Future.error(const SocketException('synthetic_dev_offline'));
    }
    return inner.send(request);
  }

  @override
  void close() => inner.close();
}

Future<void> main() async {
  verifyPhase1DevTarget(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    analyticsEnabled: analyticsBuildEnabled,
  );
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final ui = LiveWidgetController(binding);
  final docs = await getApplicationDocumentsDirectory();
  final proof = File('${docs.path}/phase1-full-ui-proof.json');
  final report = <String, Object?>{
    'target': 'qecbnrkbordkqeogmevi',
    'normal_app': true,
    'network_fault': 'process-local Dev HTTP only',
    'steps': <String>[],
  };
  String step = 'bootstrap';
  void passed(String name) {
    (report['steps'] as List<String>).add(name);
    proof.writeAsStringSync(jsonEncode(report));
    debugPrint('PHASE1_FULL_UI_PASS $name');
  }

  void require(bool ok, String name) {
    if (!ok) throw StateError(name);
  }

  Future<void> until(bool Function() ok, {int seconds = 50}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      if (binding.rootElement != null && ok()) return;
      if (binding.rootElement == null) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      } else {
        await ui.pump(const Duration(milliseconds: 200));
      }
    }
    throw StateError('timeout:$step');
  }

  Future<void> show(Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await ui.scrollUntilVisible(
        finder,
        350,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 14,
      );
    } else {
      await ui.ensureVisible(finder.first);
    }
    await ui.pump(const Duration(milliseconds: 250));
  }

  Future<void> tap(Finder finder) async {
    report['pending_target'] = finder.describeMatch(Plurality.one);
    for (
      var i = 0;
      i < 3 && find.text('Got it').hitTestable().evaluate().isNotEmpty;
      i++
    ) {
      await ui.tap(find.text('Got it').hitTestable().first);
      await ui.pump(const Duration(milliseconds: 450));
    }
    if (finder.hitTestable().evaluate().isEmpty) await show(finder);
    await ui.tap(finder.hitTestable().first);
    await ui.pump(const Duration(milliseconds: 450));
  }

  Future<void> enter(Finder finder, String value) async {
    await tap(finder);
    final editable = find.descendant(
      of: finder.first,
      matching: find.byType(EditableText),
    );
    final target = finder.evaluate().first.widget is EditableText
        ? finder.first
        : editable.first;
    ui
        .state<EditableTextState>(target)
        .updateEditingValue(
          TextEditingValue(
            text: value,
            selection: TextSelection.collapsed(offset: value.length),
          ),
        );
    await ui.pump(const Duration(milliseconds: 250));
    FocusManager.instance.primaryFocus?.unfocus();
    await ui.pump(const Duration(milliseconds: 300));
  }

  Finder field(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label,
  );
  try {
    final fixture =
        jsonDecode(
              await File('${docs.path}/phase1-dev-test.json').readAsString(),
            )
            as Map<String, dynamic>;
    require(fixture['project'] == 'qecbnrkbordkqeogmevi', 'fixture target');
    final owner = fixture['owner'] as Map<String, dynamic>;
    require(
      owner['id'] == 'bf083139-9df9-4e90-8caf-e7d35e4b4848',
      'synthetic owner',
    );
    final transport = _DevTransport();
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      httpClient: transport,
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: false,
        localStorage: SecureSessionStorage(
          persistSessionKey: sessionStorageKey(SupabaseConfig.url),
        ),
      ),
    );
    final client = Supabase.instance.client;
    final auth = await client.auth.signInWithPassword(
      email: owner['email'],
      password: owner['password'],
    );
    require(auth.user?.id == owner['id'], 'verified owner session');
    product.main();
    step = 'normal-app-ready';
    await until(() => find.byType(FitPackApp).evaluate().isNotEmpty);
    final container = ProviderScope.containerOf(
      ui.element(find.byType(FitPackApp)),
      listen: false,
    );
    final analytics = container.read(analyticsControllerProvider);
    final l = await AppL10n.delegate.load(const Locale('en'));
    await until(() => analytics.available && !analytics.busy);
    if (find.byType(OnboardingScreen).evaluate().isNotEmpty) {
      step = 'normal-onboarding';
      if (!analytics.enabled) {
        require(analytics.pendingCount == 0, 'default off');
        passed('normal-app-onboarding-default-off');
        await tap(find.byKey(const ValueKey('analytics.optIn')));
        await tap(find.text(l.analyticsConsentAccept));
        await until(() => analytics.enabled && !analytics.busy);
        passed('onboarding-consent-ui-enabled');
      } else {
        passed('prior-onboarding-consent-retained-on-resume');
      }
      await tap(find.text(l.onbExpBeginner));
      await tap(find.text(l.onbDays23));
      await tap(find.text(l.commonNext));
      await tap(find.text(l.onbProgramSkip));
      await tap(find.text(l.commonNext));
      await enter(field(l.onbCurrentWeight), '80');
      await tap(find.text(l.commonNext));
      await tap(find.text(l.onbStart));
      await until(() => find.byType(OnboardingScreen).evaluate().isEmpty);
      passed('normal-onboarding-completed');
    } else {
      report['resumed_normal_saved_onboarding'] = true;
      passed('normal-saved-onboarding-restored');
    }
    // A resumed synthetic account may have been revoked by prior cleanup.
    // Re-enable only through the same real Settings opt-in UI.
    if (!analytics.enabled) {
      step = 'resumed-settings-consent';
      await tap(find.byKey(const ValueKey('velocity-tab-0')));
      await tap(find.byTooltip('Profile'));
      await tap(find.byTooltip('Settings'));
      await tap(find.byKey(const ValueKey('analytics.optIn')));
      await tap(find.text(l.analyticsConsentAccept));
      await until(() => analytics.enabled && !analytics.busy);
      passed('resumed-settings-ui-consent-enabled');
      await tap(find.byType(BackButton));
      await tap(find.byType(BackButton));
    }
    // Retain a real saved workout across a driver restart; never create a
    // duplicate synthetic workout just to recover a navigation selector.
    final sync = container.read(syncControllerProvider);
    final priorSessions = await container
        .read(workoutDaoProvider)
        .getAllSessions();
    if (priorSessions.isEmpty) {
      // Follow actual navigation and normal SQLite save path.
      step = 'workout';
      await tap(find.byKey(const ValueKey('velocity-tab-1')));
      await tap(find.text(l.exFreeWorkout));
      await until(() => find.text(l.workoutAddExercise).evaluate().isNotEmpty);
      passed('free-first-mount-no-error');
      await tap(find.text(l.workoutAddExercise));
      await enter(find.byType(EditableText).first, 'Barbell Bench Press');
      // find.text also matches the search EditableText; target the actual row.
      final pickedRow = find
          .ancestor(
            of: find.byWidgetPredicate(
              (w) => w is Text && w.data == 'Barbell Bench Press',
            ),
            matching: find.byType(InkWell),
          )
          .first;
      await until(() => pickedRow.evaluate().isNotEmpty);
      await tap(pickedRow);
      await until(
        () => find.byKey(const ValueKey('kg-0')).evaluate().isNotEmpty,
      );
      await enter(find.byKey(const ValueKey('kg-0')), '20');
      await enter(find.byKey(const ValueKey('reps-0')), '8');
      await tap(find.byKey(const ValueKey('set.complete.0')));
      if (find.byKey(const ValueKey('rest.skip')).evaluate().isNotEmpty) {
        await tap(find.byKey(const ValueKey('rest.skip')));
      }
      transport.offline = true;
      await tap(find.text(l.asFinish));
      if (find
          .byKey(const ValueKey('session.finishAnyway'))
          .evaluate()
          .isNotEmpty) {
        await tap(find.byKey(const ValueKey('session.finishAnyway')));
      }
      await until(
        () => find.byType(WorkoutSummaryScreen).evaluate().isNotEmpty,
      );
      final sessions = await container
          .read(workoutDaoProvider)
          .getAllSessions();
      require(sessions.length == 1, 'one real local workout');
      await until(() => analytics.pendingCount > 0);
      require(await sync.pendingCount() > 0, 'offline business queue');
      report['offline_analytics_queue'] = analytics.pendingCount;
      report['offline_business_queue'] = await sync.pendingCount();
      passed('normal-offline-workout-save-and-queues');
    } else {
      require(priorSessions.length == 1, 'single preserved synthetic workout');
      report['resumed_saved_workout'] = true;
      passed('normal-saved-offline-workout-retained-on-restart');
    }
    step = 'reconnect';
    transport.offline = false;
    if (find.byType(WorkoutSummaryScreen).evaluate().isNotEmpty) {
      await tap(find.text(l.wsDoneBtn));
    }
    await tap(find.byKey(const ValueKey('velocity-tab-0')));
    await tap(find.byTooltip('Profile'));
    await tap(
      find.byWidgetPredicate(
        (w) => w is SettingTile && w.title == l.settingsCloudAccount,
      ),
    );
    await tap(find.widgetWithText(OutlinedButton, l.cloudSyncNow));
    final end = DateTime.now().add(const Duration(seconds: 50));
    while (await sync.pendingCount() > 0 && DateTime.now().isBefore(end)) {
      await ui.pump(const Duration(milliseconds: 300));
    }
    require(
      await sync.pendingCount() == 0,
      'reconnected business queue drained',
    );
    await until(() => analytics.pendingCount == 0);
    passed('normal-sync-now-reconnect-drained');
    report['panel_ready'] = true;
    proof.writeAsStringSync(jsonEncode(report));
    debugPrint('PHASE1_FULL_UI_PANEL_READY');
    // Parent test driver verifies actual admin HTML before allowing withdrawal.
    step = 'admin-panel-verification';
    await until(
      () => File('${docs.path}/phase1-panel-verified.signal').existsSync(),
      seconds: 360,
    );
    passed('actual-admin-html-record-verified');
    step = 'withdraw';
    await tap(find.byType(BackButton));
    await tap(find.byTooltip('Settings'));
    await tap(find.byKey(const ValueKey('analytics.optIn')));
    await until(
      () =>
          !analytics.enabled && !analytics.busy && !analytics.revocationPending,
    );
    final status = await client.functions.invoke(
      'product-data',
      body: {'action': 'consent_status'},
    );
    require((status.data as Map)['enabled'] == false, 'server withdrawn');
    passed('normal-settings-ui-withdraw-server-off');
    step = 'account-switch';
    await tap(find.byType(BackButton));
    await tap(
      find.byWidgetPredicate(
        (w) => w is SettingTile && w.title == l.settingsCloudAccount,
      ),
    );
    await tap(find.widgetWithText(OutlinedButton, l.cloudSignOut));
    if (find.text('Sync first').evaluate().isNotEmpty) {
      await tap(find.text('Sync first'));
    }
    await until(
      () => find.text('Already have an account? Sign in').evaluate().isNotEmpty,
    );
    await tap(find.text('Already have an account? Sign in'));
    final viewer = fixture['viewer'] as Map<String, dynamic>;
    await enter(field(l.cloudEmail), viewer['email']);
    await enter(field(l.cloudPassword), viewer['password']);
    await tap(find.text(l.cloudSignInBtn));
    await until(
      () =>
          client.auth.currentUser?.id == viewer['id'] &&
          find.byType(OnboardingScreen).evaluate().isNotEmpty,
    );
    final b = ProviderScope.containerOf(
      ui.element(find.byType(FitPackApp)),
      listen: false,
    );
    await until(() => !b.read(analyticsControllerProvider).busy);
    require(
      !b.read(analyticsControllerProvider).enabled,
      'B has no inherited consent',
    );
    require(
      (await b.read(workoutDaoProvider).getAllSessions()).isEmpty,
      'B has no A workouts',
    );
    passed('normal-ui-signout-signin-account-isolation');
    report['passed'] = true;
    proof.writeAsStringSync(jsonEncode(report));
    debugPrint('PHASE1_FULL_UI_PASSED');
  } catch (e, stack) {
    report['passed'] = false;
    report['failed_step'] = step;
    report['error_type'] = e.runtimeType.toString();
    if (e is StateError) report['state_error'] = e.message.toString();
    report['stack'] = stack.toString().split('\n').take(5).toList();
    report['visible_labels'] = binding.rootElement == null
        ? <String>[]
        : find
              .byType(Text)
              .evaluate()
              .map((x) => (x.widget as Text).data)
              .whereType<String>()
              .take(90)
              .toList();
    proof.writeAsStringSync(jsonEncode(report));
    debugPrint('PHASE1_FULL_UI_FAILED $step ${e.runtimeType}');
  }
}
