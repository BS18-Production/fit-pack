import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/core/notifications/notification_service.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/workout/recall_missed_day.dart';
import 'package:fit_pack/features/workout/recall_reminders.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// Bildirim eklentisi testte yok: kurulan/iptal edilenleri kaydeder.
class _FakeNotifications extends NotificationService {
  final scheduled = <int, DateTime>{};
  final titles = <int, String>{};
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
    titles[id] = title;
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<void> cancelRestDone() async {}
}

/// docs/51 durum 1 — "planlı gün kaçtı" hatırlatıcısı.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Ekim 2026: 10 Cumartesi, 11 Pazar, 12 Pazartesi.
  DateTime at(int d, int h, [int m = 0]) => DateTime(2026, 10, d, h, m);

  late AppDatabase db;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
  });
  tearDown(() => db.close());

  Future<int> rutin(String name, int? weekday) => db.workoutDao.createRoutine(
      RoutinesCompanion.insert(
          name: name,
          createdAt: at(1, 9),
          scheduledWeekday: Value(weekday)));

  Future<int> seans(DateTime start) =>
      db.workoutDao.insertSession(WorkoutSessionsCompanion.insert(
        date: start,
        phase: 0,
        workoutType: 'Test',
        startedAt: Value(start),
      ));

  group('akşam saati', () {
    test('varsayılan 20:00; olağan 18:30 sonrası +90 dk, en geç 21:30', () {
      expect(missedDayMinute(null), 20 * 60);
      expect(missedDayMinute(18 * 60 + 30), 20 * 60);
      expect(missedDayMinute(19 * 60), 20 * 60 + 30);
      expect(missedDayMinute(21 * 60), 21 * 60 + 30);
    });
  });

  group('planMissedDay', () {
    test('güne bağlı rutin yoksa ya da hiç antrenman yoksa boş', () async {
      await rutin('A', null);
      final routines = await db.workoutDao.getActiveRoutines();
      expect(
          planMissedDay(
              now: at(10, 9),
              routines: routines,
              sessionDays: const {},
              hasWorkouts: true),
          isEmpty);
      await rutin('Bacak', 6);
      final scheduled = await db.workoutDao.getActiveRoutines();
      expect(
          planMissedDay(
              now: at(10, 9),
              routines: scheduled,
              sessionDays: const {},
              hasWorkouts: false),
          isEmpty);
    });

    test('planlı günlerin akşamı; o gün antrenman varsa yok', () async {
      await rutin('Bacak', 6); // Cumartesi
      await rutin('İtiş', 1); // Pazartesi
      final routines = await db.workoutDao.getActiveRoutines();
      final plan = planMissedDay(
          now: at(10, 9),
          routines: routines,
          sessionDays: const {},
          hasWorkouts: true);
      expect([for (final (t, r) in plan) (t, r.name)],
          [(at(10, 20), 'Bacak'), (at(12, 20), 'İtiş')]);

      final trained = planMissedDay(
          now: at(10, 12),
          routines: routines,
          sessionDays: {DateTime(2026, 10, 10)},
          hasWorkouts: true);
      expect([for (final (t, _) in trained) t], [at(12, 20)]);
    });

    test('saati geçen ve susturma öncesi anlar atlanır', () async {
      await rutin('Bacak', 6);
      await rutin('İtiş', 1);
      final routines = await db.workoutDao.getActiveRoutines();
      expect(
          planMissedDay(
              now: at(10, 21),
              routines: routines,
              sessionDays: const {},
              hasWorkouts: true,
              mutedUntil: at(12, 0)).map((p) => p.$1),
          [at(12, 20)]);
      expect(
          planMissedDay(
              now: at(10, 9),
              routines: routines,
              sessionDays: const {},
              hasWorkouts: true,
              mutedUntil: at(13, 0)),
          isEmpty);
    });
  });

  group('mergeRecallPlans', () {
    test('aynı günde toplam 2: planlı gün önce, ara uzadı sonra', () {
      final m = mergeRecallPlans(
        missed: [at(10, 20)],
        gap: [at(10, 18), at(10, 21), at(11, 18), at(11, 21)],
      );
      expect(m.missed, [at(10, 20)]);
      expect(m.gap, [at(10, 18), at(11, 18), at(11, 21)]);
    });

    test('haftada 6: geçmişle birlikte, geç anın haftası da korunur', () {
      final m = mergeRecallPlans(
        missed: [at(12, 20)],
        gap: [at(10, 18), at(10, 21), at(11, 18)],
        sent: [at(6, 18), at(7, 18), at(8, 18)],
      );
      // 3 gönderilmiş + 12'deki planlı gün = 4 → ara uzadıdan yalnız 2 yer.
      expect(m.missed, [at(12, 20)]);
      expect(m.gap, [at(10, 18), at(10, 21)]);
    });
  });

  group('syncRecallReminders ile', () {
    test('planlı gün kaçınca 46. yuvada kurulur, sınırlar ortak', () async {
      final l = await AppL10n.delegate.load(const Locale('tr'));
      await rutin('Bacak', 6);
      await seans(at(9, 18)); // dün antrenman → ara uzadı en erken 11'i
      final svc = _FakeNotifications();
      await syncRecallReminders(
        service: svc,
        dao: db.workoutDao,
        l: l,
        enabled: true,
        fallbackHour: 18,
        fallbackMinute: 0,
        now: at(10, 9),
      );
      expect(svc.cancelled, containsAll([
        for (var i = 0; i < NotificationService.missedDaySlots; i++)
          NotificationService.idMissedDayBase + i,
      ]));
      expect(svc.scheduled[NotificationService.idMissedDayBase], at(10, 20));
      expect(svc.scheduled.containsKey(NotificationService.idMissedDayBase + 1),
          isFalse);
      expect(svc.titles[NotificationService.idMissedDayBase],
          'Bugün Bacak günüydü');
      expect((await RecallLedger.load()).planned,
          [at(10, 20), at(11, 18), at(11, 21), at(12, 18), at(12, 21)]);

      // Antrenman girildi → yeniden kurulumda düşer.
      await seans(at(10, 18));
      final svc2 = _FakeNotifications();
      await syncRecallReminders(
        service: svc2,
        dao: db.workoutDao,
        l: l,
        enabled: true,
        fallbackHour: 18,
        fallbackMinute: 0,
        now: at(10, 19),
      );
      expect(svc2.scheduled.containsKey(NotificationService.idMissedDayBase),
          isFalse);
    });

    test('hesap değişiminde 46–48 iptal edilir', () async {
      final svc = _FakeNotifications();
      await svc.cancelAccountScoped();
      expect(svc.cancelled, containsAll([46, 47, 48]));
    });
  });
}
