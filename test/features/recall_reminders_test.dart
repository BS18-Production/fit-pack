import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/core/notifications/notification_prefs.dart';
import 'package:fit_pack/core/notifications/notification_service.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/sync_meta_dao.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';
import 'package:fit_pack/features/workout/recall_reminders.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// Bildirim eklentisi testte yok: kurulan/iptal edilenleri kaydeder.
class _FakeNotifications extends NotificationService {
  final scheduled = <int, DateTime>{};
  final texts = <int, (String, String)>{};
  final payloads = <int, String?>{};
  final cancelled = <int>[];
  var restCancelled = 0;

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
    payloads[id] = payload;
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<void> cancelRestDone() async => restCancelled++;
}

/// docs/51 — geri çağırma ("ara uzadı") hatırlatıcısı.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DateTime at(int d, int h, [int m = 0]) => DateTime(2026, 10, d, h, m);

  group('olağan saat ve sessiz saat', () {
    test('ortanca başlangıç saati; veri yoksa null', () {
      expect(usualWorkoutMinute(const []), isNull);
      expect(
          usualWorkoutMinute([at(1, 18), at(2, 19, 30), at(3, 7), at(4, 18, 10)]),
          18 * 60 + 10);
    });

    test('22:00 sonrası ertesi sabah 08:30, 08:00 öncesi aynı sabah 08:30', () {
      expect(shiftOutOfQuietHours(at(10, 23)), at(11, 8, 30));
      expect(shiftOutOfQuietHours(at(10, 6)), at(10, 8, 30));
      expect(shiftOutOfQuietHours(at(10, 21, 59)), at(10, 21, 59));
      // Ay sonunda ertesi gün takvimle bulunur.
      expect(shiftOutOfQuietHours(DateTime(2026, 10, 31, 22, 30)),
          DateTime(2026, 11, 1, 8, 30));
    });
  });

  group('planRecall', () {
    test('hiç antrenman yoksa bildirim yok', () {
      expect(
          planRecall(now: at(10, 9), lastWorkout: null, minuteOfDay: 18 * 60),
          isEmpty);
    });

    test('2 gün dolmadan yok; 2. günden itibaren olağan saatte, günde 1', () {
      final plan = planRecall(
          now: at(10, 9), lastWorkout: at(10, 8), minuteOfDay: 18 * 60);
      // Bugün (10) ve yarın (11) erken; yalnız 12'si.
      expect(plan, [at(12, 18)]);
    });

    test('ara çoktan uzadıysa bugün + 2 gün; saati geçmiş bugün atlanır', () {
      expect(
          planRecall(now: at(10, 9), lastWorkout: at(5, 18), minuteOfDay: 18 * 60),
          [at(10, 18), at(11, 18), at(12, 18)]);
      expect(
          planRecall(now: at(10, 19), lastWorkout: at(5, 18), minuteOfDay: 18 * 60),
          [at(11, 18), at(12, 18)]);
    });

    test('haftada en fazla 3: geçmişte gönderilenler sayılır', () {
      final plan = planRecall(
        now: at(10, 9),
        lastWorkout: at(1, 18),
        minuteOfDay: 18 * 60,
        sent: [at(8, 18), at(9, 18)],
      );
      // Son 7 günde 2 gönderildi → yalnız 1 yer kaldı.
      expect(plan, [at(10, 18)]);
    });

    test('susturma bitmeden bildirim yok', () {
      final plan = planRecall(
        now: at(10, 9),
        lastWorkout: at(1, 18),
        minuteOfDay: 18 * 60,
        mutedUntil: at(12, 0),
      );
      expect(plan, [at(12, 18)]);
    });

    test('sessiz saate düşen ertesi sabaha kayar, aynı güne ikinci düşmez', () {
      final plan = planRecall(
          now: at(10, 9), lastWorkout: at(1, 18), minuteOfDay: 23 * 60);
      // 10 23:00 → 11 08:30; 11 23:00 → 12 08:30; 12 23:00 → 13 08:30.
      expect(plan, [at(11, 8, 30), at(12, 8, 30), at(13, 8, 30)]);
      expect(plan.map((d) => d.day).toSet().length, plan.length);
    });

    test('takvim günü: ay ve yaz saati sınırında saat kaymaz', () {
      // Avrupa'da 2026 yaz saati 29 Mart'ta başlar, 25 Ekim'de biter. Gün
      // eklemek 24 saat eklemek olsaydı saat bir kayardı.
      final spring = planRecall(
        now: DateTime(2026, 3, 28, 9),
        lastWorkout: DateTime(2026, 3, 20, 18),
        minuteOfDay: 18 * 60,
      );
      expect(spring.map((d) => (d.day, d.hour, d.minute)),
          [(28, 18, 0), (29, 18, 0), (30, 18, 0)]);
      final autumn = planRecall(
        now: DateTime(2026, 10, 24, 9),
        lastWorkout: DateTime(2026, 10, 20, 18),
        minuteOfDay: 18 * 60,
      );
      expect(autumn.map((d) => (d.day, d.hour, d.minute)),
          [(24, 18, 0), (25, 18, 0), (26, 18, 0)]);
      final monthEnd = planRecall(
        now: DateTime(2026, 10, 31, 19),
        lastWorkout: DateTime(2026, 10, 29, 18),
        minuteOfDay: 18 * 60,
      );
      expect(monthEnd, [DateTime(2026, 11, 1, 18), DateTime(2026, 11, 2, 18)]);
    });
  });

  group('RecallLedger', () {
    test('zamanı geçen planlananlar gönderildi sayılır, 8 günden eskiler gider',
        () {
      final l = RecallLedger(
        sent: [at(1, 18)],
        planned: [at(9, 18), at(11, 18)],
      ).reconcile(now: at(10, 9));
      expect(l.sent, [at(9, 18)]);
      expect(l.planned, isEmpty);
    });

    test('art arda 3 tepkisiz → 14 gün susar', () {
      final l = RecallLedger(sent: [at(7, 18), at(8, 18)], planned: [at(9, 18)])
          .reconcile(now: at(10, 9), lastWorkout: at(5, 18));
      // 14 takvim günü sonra, günün başında.
      expect(l.mutedUntil, DateTime(2026, 10, 24));
    });

    test('dokunma ya da sonrasında antrenman tepki sayılır', () {
      final tapped = RecallLedger(
        sent: [at(7, 18), at(8, 18), at(9, 18)],
        lastTap: at(8, 19),
      ).reconcile(now: at(10, 9), lastWorkout: at(5, 18));
      expect(tapped.mutedUntil, isNull);
      final trained = const RecallLedger()
          .withPlanned([at(7, 18), at(8, 18), at(9, 18)])
          .reconcile(now: at(10, 9), lastWorkout: at(9, 19));
      expect(trained.mutedUntil, isNull);
    });

    test('süresi dolan susturma kalkar', () {
      final l = RecallLedger(mutedUntil: at(9, 0))
          .reconcile(now: at(10, 9), lastWorkout: at(9, 18));
      expect(l.mutedUntil, isNull);
    });

    test('diske yazılır ve okunur; dokunma kaydedilir', () async {
      SharedPreferences.setMockInitialValues({});
      await RecallLedger(sent: [at(9, 18)], mutedUntil: at(20, 9)).save();
      await RecallLedger.markTapped(at(10, 8));
      final l = await RecallLedger.load();
      expect(l.sent, [at(9, 18)]);
      expect(l.mutedUntil, at(20, 9));
      expect(l.lastTap, at(10, 8));
      await RecallLedger.clear();
      final c = await RecallLedger.load();
      expect(c.sent, isEmpty);
      expect(c.lastTap, isNull);
    });
  });

  group('syncRecallReminders', () {
    late AppDatabase db;
    late AppL10n l;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = newTestDatabase();
      l = await AppL10n.delegate.load(const Locale('tr'));
    });
    tearDown(() => db.close());

    Future<int> seans(DateTime start, {int? routineId}) =>
        db.workoutDao.insertSession(WorkoutSessionsCompanion.insert(
          date: start,
          phase: 0,
          workoutType: 'Test',
          startedAt: Value(start),
          routineId: Value(routineId),
        ));

    test('eski günlük hatırlatıcı + yuvalar silinir; sıradaki rutin adıyla kurulur',
        () async {
      final a = await db.workoutDao
          .createRoutine(RoutinesCompanion.insert(name: 'Tüm vücut A', createdAt: at(1, 9)));
      await db.workoutDao
          .createRoutine(RoutinesCompanion.insert(name: 'Tüm vücut B', createdAt: at(1, 9)));
      await seans(at(5, 19, 30), routineId: a);
      final svc = _FakeNotifications();
      await syncRecallReminders(
        service: svc,
        dao: db.workoutDao,
        l: l,
        enabled: true,
        fallbackHour: 18,
        fallbackMinute: 0,
        now: at(10, 20),
      );
      expect(svc.cancelled, [
        NotificationService.idWorkout,
        for (var i = 0; i < NotificationService.recallSlots; i++)
          NotificationService.idRecallBase + i,
      ]);
      // Olağan saat geçmişten (19:30, ayardaki 18:00 değil); bugünkü geçti.
      expect(svc.scheduled.values, [at(11, 19, 30), at(12, 19, 30)]);
      expect(svc.texts.values.first.$2, contains('Tüm vücut B'));
      expect(svc.payloads.values.toSet(), {NotificationService.payloadRecall});
      // Planlananlar deftere yazıldı → bir sonraki kurulumda "gönderildi".
      expect((await RecallLedger.load()).planned, svc.scheduled.values);
    });

    test('kapalıysa yalnız iptal; antrenman girilince plan boşalır', () async {
      await seans(at(5, 18));
      final svc = _FakeNotifications();
      await syncRecallReminders(
          service: svc,
          dao: db.workoutDao,
          l: l,
          enabled: false,
          fallbackHour: 18,
          fallbackMinute: 0,
          now: at(10, 9));
      expect(svc.scheduled, isEmpty);
      expect(svc.cancelled, hasLength(1 + NotificationService.recallSlots));

      await seans(at(10, 10));
      final svc2 = _FakeNotifications();
      await syncRecallReminders(
          service: svc2,
          dao: db.workoutDao,
          l: l,
          enabled: true,
          fallbackHour: 18,
          fallbackMinute: 0,
          now: at(10, 11));
      // Bugün antrenman yapıldı → en erken 12'si.
      expect(svc2.scheduled.values, [at(12, 18)]);
    });
  });

  group('haftalık değerlendirme varsayılanı (docs/50 karar 3)', () {
    test('yeni hesapta açılır', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final changed = await c
          .read(notificationPrefsProvider.notifier)
          .enableWeeklyReviewByDefault();
      expect(changed, isTrue);
      expect(c.read(notificationPrefsProvider).weeklyReviewEnabled, isTrue);
    });

    test('kullanıcı daha önce kapattıysa dokunulmaz', () async {
      SharedPreferences.setMockInitialValues({'notif_weekly_review': false});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final changed = await c
          .read(notificationPrefsProvider.notifier)
          .enableWeeklyReviewByDefault();
      await Future<void>.delayed(Duration.zero);
      expect(changed, isFalse);
      expect(c.read(notificationPrefsProvider).weeklyReviewEnabled, isFalse);
    });
  });

  group('hesap değişimi', () {
    test('hesaba bağlı bildirimler açıkça silinir', () async {
      final svc = _FakeNotifications();
      await svc.cancelAccountScoped();
      expect(svc.restCancelled, 1);
      expect(svc.cancelled, containsAll([
        NotificationService.idWorkout,
        for (var i = 0; i < NotificationService.mealReminderSlots; i++)
          NotificationService.idMealBase + i,
        for (var i = 0; i < NotificationService.recallSlots; i++)
          NotificationService.idRecallBase + i,
      ]));
      expect(svc.cancelled, isNot(contains(NotificationService.idWater)));
      expect(svc.cancelled,
          isNot(contains(NotificationService.idWeeklyReview)));
    });

    test('yerel veri silinince kapı bildirimleri ve defteri temizler', () async {
      SharedPreferences.setMockInitialValues({});
      await RecallLedger(sent: [at(9, 18)]).save();
      final db = newTestDatabase();
      final svc = _FakeNotifications();
      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await db.syncMetaDao.write(SyncMetaDao.keyLastUser, 'a');
      await db.syncMetaDao.write(SyncMetaDao.keySwitchInProgress, 'b');

      await c.read(authGateProvider).bootstrap();
      await Future<void>.delayed(Duration.zero);

      expect(svc.restCancelled, 1);
      expect(svc.cancelled, contains(NotificationService.idRecallBase));
      expect((await RecallLedger.load()).sent, isEmpty);
    });
  });
}
