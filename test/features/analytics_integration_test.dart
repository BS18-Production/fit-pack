import 'package:fit_pack/features/analytics/analytics_controller.dart';
import 'package:fit_pack/features/analytics/analytics_events.dart';
import 'package:fit_pack/features/analytics/analytics_lifecycle.dart';
import 'package:fit_pack/features/analytics/analytics_providers.dart';
import 'package:fit_pack/features/analytics/analytics_settings_section.dart';
import 'package:fit_pack/features/cloud/auth_service.dart';
import 'package:fit_pack/features/sync/sync_controller.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_sync_server.dart';
import '../helpers/test_database.dart';
import 'analytics_core_test.dart' as fixtures;

// Reuse synthetic contract fixtures; their main() is not invoked by this import.
User account(String id) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-10-29T00:00:00Z',
);
final testAccount = StateProvider<User?>((ref) => account(fixtures.ownerA));

AnalyticsController make(
  fixtures.MemoryStorage storage,
  fixtures.FakeRemote remote, {
  bool featureEnabled = true,
}) => AnalyticsController(
  storage: storage,
  remote: remote,
  context: () async => fixtures.metadata(),
  featureEnabled: featureEnabled,
  now: () => fixtures.at,
  autoFlushDelay: const Duration(days: 1),
);

void main() {
  Future<ProviderContainer> open(
    WidgetTester tester,
    AnalyticsController analytics, {
    bool lifecycle = false,
  }) async {
    final container = ProviderContainer(
      overrides: [
        analyticsControllerProvider.overrideWith((ref) => analytics),
        currentUserProvider.overrideWith((ref) => ref.watch(testAccount)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: lifecycle
              ? const AnalyticsLifecycle(child: Scaffold(body: Text('APP')))
              : const Scaffold(
                  body: SingleChildScrollView(
                    child: AnalyticsSettingsSection(),
                  ),
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('cancel leaves preference off without an enable request', (
    tester,
  ) async {
    final remote = fixtures.FakeRemote();
    final analytics = make(fixtures.MemoryStorage(), remote);
    await analytics.setAccount(fixtures.ownerA);
    await open(tester, analytics);
    await tester.tap(find.byKey(const ValueKey('analytics.optIn')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(analytics.enabled, isFalse);
    expect(remote.requests, isEmpty);
  });

  testWidgets('accepting old account dialog cannot enable new account', (
    tester,
  ) async {
    final remote = fixtures.FakeRemote();
    final analytics = make(fixtures.MemoryStorage(), remote);
    await analytics.setAccount(fixtures.ownerA);
    final container = await open(tester, analytics);
    await tester.tap(find.byKey(const ValueKey('analytics.optIn')));
    await tester.pumpAndSettle();
    container.read(testAccount.notifier).state = account(fixtures.ownerB);
    await analytics.setAccount(fixtures.ownerB);
    await tester.pump();
    await tester.tap(
      find.text(
        AppL10n.of(
          tester.element(find.byType(AlertDialog)),
        ).analyticsConsentAccept,
      ),
    );
    await tester.pumpAndSettle();
    expect(remote.requests, isEmpty);
    expect(analytics.enabled, isFalse);
  });

  testWidgets('disabled build exposes explicit server withdrawal', (
    tester,
  ) async {
    final remote = fixtures.FakeRemote();
    final analytics = make(
      fixtures.MemoryStorage(),
      remote,
      featureEnabled: false,
    );
    await analytics.setAccount(fixtures.ownerA);
    await open(tester, analytics);
    expect(remote.calls, 0);
    await tester.tap(find.byKey(const ValueKey('analytics.withdraw')));
    await tester.pumpAndSettle();
    expect(remote.revocations, [fixtures.ownerA]);
    expect(analytics.enabled, isFalse);
  });

  testWidgets('lifecycle binds auth changes without relabeling queued events', (
    tester,
  ) async {
    final remote = fixtures.FakeRemote();
    final analytics = make(fixtures.MemoryStorage(), remote);
    final previousHandler = FlutterError.onError;
    final container = await open(tester, analytics, lifecycle: true);
    expect(analytics.ownerId, fixtures.ownerA);
    await analytics.setEnabled(true);
    await analytics.trackOwned(
      fixtures.ownerA,
      AnalyticsEventName.workoutSaved,
      {'mode': 'free', 'source': 'live'},
    );
    container.read(testAccount.notifier).state = account(fixtures.ownerB);
    await tester.pumpAndSettle();
    expect(analytics.ownerId, fixtures.ownerB);
    expect(analytics.enabled, isFalse);
    expect(analytics.pendingCount, 0);
    await tester.pumpWidget(const SizedBox());
    expect(FlutterError.onError, same(previousHandler));
  });

  test('throwing analytics observer cannot prevent sync saving', () async {
    final db = newTestDatabase();
    final server = FakeSyncServer();
    final sync = SyncController(
      db: db,
      push: SyncPush(db, server),
      currentUserId: () => fixtures.ownerA,
      onCycle: (_, _, _, _) => throw StateError('synthetic analytics failure'),
    );
    addTearDown(() async {
      await sync.stop();
      await db.close();
    });
    await db.customStatement(
      "INSERT INTO routines (name, created_at) VALUES ('Synthetic',1700000000)",
    );
    await sync.syncNow();
    expect(sync.last.value?.ok, isTrue);
    expect(await sync.pendingCount(), 0);
    expect(server.store['routines'], hasLength(1));
  });
}
