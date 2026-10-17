import 'package:fit_pack/core/notifications/notification_prefs.dart';
import 'package:fit_pack/core/notifications/notification_service.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/workout/recall_offer.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

class _FakeNotifications extends NotificationService {
  _FakeNotifications(this.grant);
  final bool grant;
  var asked = 0;

  @override
  Future<bool> requestPermission() async {
    asked++;
    return grant;
  }
}

/// docs/51 karar 4 — izin kurulumda değil, ilk antrenmandan sonra sorulur.
void main() {
  late AppDatabase db;

  setUp(() {
    db = newTestDatabase();
  });
  tearDown(() => db.close());

  Future<ProviderContainer> pump(WidgetTester t,
      {required int sessions,
      required _FakeNotifications svc,
      Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    for (var i = 0; i < sessions; i++) {
      await db.workoutDao.insertSession(WorkoutSessionsCompanion.insert(
          date: DateTime(2026, 10, 10 + i, 18), phase: 0, workoutType: 'X'));
    }
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(svc),
    ]);
    addTearDown(c.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        locale: Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: RecallOffer()),
      ),
    ));
    await t.pumpAndSettle();
    return c;
  }

  testWidgets('ilk antrenmandan sonra sorulur; Evet → izin + hatırlatıcı açık',
      (t) async {
    final svc = _FakeNotifications(true);
    final c = await pump(t, sessions: 1, svc: svc);
    expect(find.byKey(const ValueKey('recall.offer')), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('recall.yes')));
    await t.pumpAndSettle();

    expect(svc.asked, 1);
    final p = c.read(notificationPrefsProvider);
    expect(p.workoutEnabled, isTrue);
    expect(p.recallPrompted, isTrue);
    expect(find.byKey(const ValueKey('recall.offer')), findsNothing);
  });

  testWidgets('Şimdi değil → izin istenmez, bir daha sorulmaz', (t) async {
    final svc = _FakeNotifications(true);
    final c = await pump(t, sessions: 1, svc: svc);
    await t.tap(find.byKey(const ValueKey('recall.no')));
    await t.pumpAndSettle();
    expect(svc.asked, 0);
    expect(c.read(notificationPrefsProvider).workoutEnabled, isFalse);
    expect(c.read(notificationPrefsProvider).shouldOfferRecall, isFalse);
  });

  testWidgets('izin reddedilirse hatırlatıcı kapalı kalır', (t) async {
    final svc = _FakeNotifications(false);
    final c = await pump(t, sessions: 1, svc: svc);
    await t.tap(find.byKey(const ValueKey('recall.yes')));
    await t.pumpAndSettle();
    expect(c.read(notificationPrefsProvider).workoutEnabled, isFalse);
  });

  testWidgets('ilk antrenman değilse gösterilmez', (t) async {
    await pump(t, sessions: 2, svc: _FakeNotifications(true));
    expect(find.byKey(const ValueKey('recall.offer')), findsNothing);
  });

  testWidgets('mola izni zaten varsa sormadan açılır', (t) async {
    final svc = _FakeNotifications(true);
    final c = await pump(t,
        sessions: 1, svc: svc, prefs: {'notif_rest': true});
    expect(find.byKey(const ValueKey('recall.offer')), findsNothing);
    expect(svc.asked, 0);
    expect(c.read(notificationPrefsProvider).workoutEnabled, isTrue);
  });
}
