// Device-only synthetic proof. No credentials in source or Dart defines.
import 'dart:convert';
import 'dart:io';

import 'package:fit_pack/core/auth/secure_session_storage.dart';
import 'package:fit_pack/core/config/supabase_config.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/features/analytics/analytics_events.dart';
import 'package:fit_pack/features/analytics/analytics_providers.dart';
import 'package:fit_pack/features/analytics/analytics_settings_section.dart';
import 'package:fit_pack/features/analytics/analytics_storage.dart';
import 'package:fit_pack/features/cloud/auth_service.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'phase1_dev_main.dart' show verifyPhase1DevTarget;

void _verify(Object? actual, Object? expected) {
  final passed = expected is Matcher
      ? expected.matches(actual, <dynamic, dynamic>{})
      : actual == expected;
  if (!passed) throw StateError('Native Dev proof assertion failed');
}

Future<void> main() async {
  verifyPhase1DevTarget(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    analyticsEnabled: analyticsBuildEnabled,
  );
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final tester = LiveWidgetController(binding);
  final documents = await getApplicationDocumentsDirectory();
  final fixture =
      jsonDecode(
            await File('${documents.path}/phase1-dev-test.json').readAsString(),
          )
          as Map<String, dynamic>;
  if (fixture['project'] != 'qecbnrkbordkqeogmevi') {
    throw StateError('Unexpected fixture target');
  }
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    authOptions: FlutterAuthClientOptions(
      autoRefreshToken: false,
      localStorage: SecureSessionStorage(
        persistSessionKey: sessionStorageKey(SupabaseConfig.url),
      ),
    ),
  );
  final client = Supabase.instance.client;
  Future<User> login(String role) async {
    final data = fixture[role] as Map<String, dynamic>;
    final result = await client.auth.signInWithPassword(
      email: data['email'] as String,
      password: data['password'] as String,
    );
    if (result.user?.id != data['id']) {
      throw StateError('Synthetic account mismatch');
    }
    return result.user!;
  }

  final owner = await login('owner');
  final account = StateProvider<User?>((ref) => owner);
  final container = ProviderContainer(
    overrides: [currentUserProvider.overrideWith((ref) => ref.watch(account))],
  );
  final analytics = container.read(analyticsControllerProvider);
  await analytics.setAccount(owner.id);
  final l = await AppL10n.delegate.load(const Locale('en'));
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: AnalyticsSettingsSection()),
        ),
      ),
    ),
  );
  await tester.pump();
  const toggleKey = ValueKey('analytics.optIn');
  final toggle = find.byKey(toggleKey);
  _verify(tester.widget<SwitchListTile>(toggle).value, isFalse);
  await analytics.trackOwned(
    owner.id,
    AnalyticsEventName.workoutStarted,
    const {'mode': 'free'},
  );
  _verify(analytics.pendingCount, 0);
  debugPrint('PHASE1_NATIVE_PASS default-off-no-queue');

  await tester.tap(toggle);
  await tester.pump(const Duration(milliseconds: 400));
  _verify(find.text(l.analyticsConsentTitle), findsOneWidget);
  await tester.tap(find.text(l.commonCancel));
  await tester.pump(const Duration(milliseconds: 400));
  _verify(analytics.enabled, isFalse);
  debugPrint('PHASE1_NATIVE_PASS consent-dialog-cancel');

  Future<void> until(bool Function() done) async {
    final deadline = DateTime.now().add(const Duration(seconds: 40));
    while (!done() && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    _verify(done(), isTrue);
  }

  await tester.tap(toggle);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.text(l.analyticsConsentAccept));
  await until(() => analytics.enabled && !analytics.busy);
  _verify(tester.widget<SwitchListTile>(toggle).value, isTrue);
  await analytics.trackOwned(owner.id, AnalyticsEventName.workoutSaved, const {
    'mode': 'free',
    'source': 'live',
  });
  await analytics.flush();
  _verify(analytics.pendingCount, 0);
  final persisted = AnalyticsSnapshot.decode(
    (await PreferencesAnalyticsStorage().read())!,
    DateTime.now(),
  );
  _verify(persisted.ownerId, owner.id);
  _verify(persisted.enabled, isTrue);
  debugPrint('PHASE1_NATIVE_PASS opt-in-native-storage-real-ingest');

  await tester.tap(toggle);
  await until(
    () => !analytics.enabled && !analytics.busy && !analytics.revocationPending,
  );
  final status = await client.functions.invoke(
    'product-data',
    body: {'action': 'consent_status'},
  );
  _verify((status.data as Map)['enabled'], isFalse);
  _verify(analytics.pendingCount, 0);
  debugPrint('PHASE1_NATIVE_PASS revoke-local-and-server');
  await tester.pump(const Duration(milliseconds: 400));
  await client.auth.signOut();
  final viewer = await login('viewer');
  container.read(account.notifier).state = viewer;
  await analytics.setAccount(viewer.id);
  await tester.pump();
  _verify(analytics.ownerId, viewer.id);
  _verify(analytics.enabled, isFalse);
  _verify(analytics.pendingCount, 0);
  _verify(tester.widget<SwitchListTile>(toggle).value, isFalse);
  debugPrint('PHASE1_NATIVE_PASS account-switch-isolated');

  await client.auth.signOut();
  final ownerAgain = await login('owner');
  container.read(account.notifier).state = ownerAgain;
  await analytics.setAccount(ownerAgain.id);
  await tester.pump();
  _verify(analytics.enabled, isFalse);
  debugPrint('PHASE1_NATIVE_SMOKE_PASSED');
  await client.auth.signOut();
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('FitPack Dev: native consent proof passed')),
      ),
    ),
  );
  await tester.pump();
  container.dispose();
}
