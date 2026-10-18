import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/core/notifications/notification_service.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/workout/recall_first_week.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// Bildirim eklentisi testte yok: kurulan/iptal edilenleri kaydeder.
class _FakeNotifications extends NotificationService {
  final scheduled = <int, DateTime>{};
  final texts = <int, (String, String)>{};
  final cancelled = <int>[];

  @override
  Future<void> scheduleOnce({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    scheduled[id] = when;
    texts[id] = (title, body);
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<void> cancelRestDone() async {}
}

/// docs/51 ikinci tur — ilk hafta tek hatırlatma.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DateTime at(int d, int h, [int m = 0]) => DateTime(2026, 10, d, h, m);

  group('planFirstWeek', () {
    test('hesabın 2. günü 19:00', () {
      expect(
          planFirstWeek(
              now: at(10, 12),
              accountStart: at(10, 9),
              hasWorkout: false,
              alreadySent: false),
          at(11, 19));
    });

    test('antrenman varsa, gönderildiyse ya da hesap tarihi yoksa yok', () {
      DateTime? plan({bool w = false, bool s = false, DateTime? start}) =>
          planFirstWeek(
              now: at(10, 12),
              accountStart: start,
              hasWorkout: w,
              alreadySent: s);
      expect(plan(start: null), isNull);
      expect(plan(start: at(10, 9), w: true), isNull);
      expect(plan(start: at(10, 9), s: true), isNull);
    });

    test('zamanı geçtiyse geç gönderilmez', () {
      expect(
          planFirstWeek(
              now: at(11, 19, 1),
              accountStart: at(10, 9),
              hasWorkout: false,
              alreadySent: false),
          isNull);
      expect(
          planFirstWeek(
              now: at(20, 9),
              accountStart: at(10, 9),
              hasWorkout: false,
              alreadySent: false),
          isNull);
    });

    test('gece yarısına yakın açılan hesap da ertesi gün 19:00; ay sonu', () {
      expect(
          planFirstWeek(
              now: at(10, 23, 50),
              accountStart: at(10, 23, 45),
              hasWorkout: false,
              alreadySent: false),
          at(11, 19));
      expect(
          planFirstWeek(
              now: DateTime(2026, 10, 31, 8),
              accountStart: DateTime(2026, 10, 31, 7),
              hasWorkout: false,
              alreadySent: false),
          DateTime(2026, 11, 1, 19));
    });

    test('UTC hesap tarihi yerel güne çevrilir', () {
      final utc = at(10, 9).toUtc();
      expect(
          planFirstWeek(
              now: at(10, 12),
              accountStart: utc,
              hasWorkout: false,
              alreadySent: false),
          at(11, 19));
    });
  });

  group('syncFirstWeekReminder', () {
    late AppDatabase db;
    late AppL10n l;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = newTestDatabase();
      l = await AppL10n.delegate.load(const Locale('tr'));
    });
    tearDown(() => db.close());

    Future<void> sync(_FakeNotifications svc, DateTime now,
            {bool enabled = true}) =>
        syncFirstWeekReminder(
          service: svc,
          dao: db.workoutDao,
          l: l,
          enabled: enabled,
          accountCreated: at(10, 9),
          now: now,
        );

    test('rutin adıyla kurulur, bayrak yazılır; zamanı geçince bir daha yok',
        () async {
      await db.workoutDao.createRoutine(
          RoutinesCompanion.insert(name: 'Tüm vücut A', createdAt: at(10, 9)));
      final svc = _FakeNotifications();
      await sync(svc, at(10, 12));
      expect(svc.cancelled, [NotificationService.idFirstWeek]);
      expect(svc.scheduled, {NotificationService.idFirstWeek: at(11, 19)});
      expect(svc.texts.values.single.$2, contains('Tüm vücut A'));
      expect(await FirstWeekReminder.load(), at(11, 19));

      // Ertesi gün 19:00 geçti → gönderildi sayılır, yeniden kurulmaz.
      final svc2 = _FakeNotifications();
      await sync(svc2, at(11, 20));
      expect(svc2.scheduled, isEmpty);
      expect(await FirstWeekReminder.load(), at(11, 19));
    });

    test('rutin yoksa genel metin', () async {
      final svc = _FakeNotifications();
      await sync(svc, at(10, 12));
      expect(svc.texts.values.single.$2, l.notifFirstWeekBody);
    });

    test('antrenman girilince iptal; gönderilmemiş bayrak silinir', () async {
      await sync(_FakeNotifications(), at(10, 12));
      await db.workoutDao.insertSession(WorkoutSessionsCompanion.insert(
        date: at(10, 18),
        phase: 0,
        workoutType: 'Test',
        startedAt: Value(at(10, 18)),
      ));
      final svc = _FakeNotifications();
      await sync(svc, at(10, 19));
      expect(svc.cancelled, [NotificationService.idFirstWeek]);
      expect(svc.scheduled, isEmpty);
      expect(await FirstWeekReminder.load(), isNull);
    });

    test('hatırlatıcı kapalıysa kurulmaz (izin istenmez)', () async {
      final svc = _FakeNotifications();
      await sync(svc, at(10, 12), enabled: false);
      expect(svc.scheduled, isEmpty);
      expect(await FirstWeekReminder.load(), isNull);
    });

    test('hesap değişiminde bildirim ve bayrak silinir', () async {
      await FirstWeekReminder.save(at(11, 19));
      final svc = _FakeNotifications();
      await svc.cancelAccountScoped();
      await FirstWeekReminder.clear();
      expect(svc.cancelled, contains(NotificationService.idFirstWeek));
      expect(await FirstWeekReminder.load(), isNull);
    });
  });
}
