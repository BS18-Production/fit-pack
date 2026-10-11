import 'package:fit_pack/features/health/health_prefs.dart';
import 'package:fit_pack/features/health/step_providers.dart';
import 'package:fit_pack/features/health/step_source.dart';
import 'package:fit_pack/features/health/step_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adım — docs/39 §2 (S-2…S-5, S-8) ve sağlayıcı akışı. Platform yok: sahte
/// kaynak.
class _FakeSource implements StepSource {
  StepPlatformStatus status = StepPlatformStatus.available;
  bool? access;
  bool requestResult = true;
  int requests = 0;
  int Function(DateTime start) steps = (_) => 5000;

  @override
  Future<StepPlatformStatus> platformStatus() async => status;
  @override
  Future<bool> requestAccess() async {
    requests++;
    return requestResult;
  }

  @override
  Future<bool?> hasAccess() async => access;
  @override
  Future<int?> stepsBetween(DateTime start, DateTime end) async => steps(start);
  @override
  Future<void> openInstall() async {}
}

void main() {
  final now = DateTime(2026, 10, 11, 19);

  group('S-2 gün pencereleri [start, end)', () {
    test('7 gün, eskiden yeniye, sonuncusu bugün', () {
      final w = stepDayWindows(now);
      expect(w, hasLength(7));
      expect(w.first.start, DateTime(2026, 10, 5));
      expect(w.last.start, DateTime(2026, 10, 11));
      expect(w.last.end, DateTime(2026, 10, 12));
    });

    test('yaz saati geçişinde gün kaymaz (takvim günü)', () {
      // 2026-03-29: Avrupa yaz saatine geçiş (23 saatlik gün).
      final w = stepDayWindows(DateTime(2026, 3, 31, 9), days: 3);
      expect(w.map((d) => d.start.day), [29, 30, 31]);
      expect(w.first.end, DateTime(2026, 3, 30));
    });
  });

  group('S-3 / S-4 veri yok', () {
    test('0 ve boş = veri yok; ortalamaya girmez', () {
      final r = buildStepWeek(
        now: now,
        stepsByDay: {
          DateTime(2026, 10, 9): 8000,
          DateTime(2026, 10, 10): 0,
          DateTime(2026, 10, 11): 4000,
        },
      );
      expect(r.days[5].steps, isNull, reason: '0 → veri yok');
      expect(r.days[0].steps, isNull, reason: 'eksik gün');
      expect(r.average, 6000);
      expect(r.today, 4000);
      expect(r.state, StepWeekState.ok);
    });

    test('hiç veri yoksa noData (iOS izin reddi böyle görünür)', () {
      final r = buildStepWeek(
        now: now,
        stepsByDay: {for (final w in stepDayWindows(now)) w.start: 0},
      );
      expect(r.state, StepWeekState.noData);
      expect(r.average, isNull);
      expect(r.today, isNull);
    });
  });

  group('S-5 hedef', () {
    test('hedef yoksa ilerleme yok', () {
      final r = buildStepWeek(
        now: now,
        stepsByDay: {DateTime(2026, 10, 11): 4000},
      );
      expect(r.goal, isNull);
      expect(r.todayProgress, isNull);
    });

    test('hedef varsa oran kırpılmaz; 0/negatif hedef yok sayılır', () {
      final r = buildStepWeek(
        now: now,
        stepsByDay: {DateTime(2026, 10, 11): 12000},
        goal: 8000,
      );
      expect(r.todayProgress, 1.5);
      expect(
        buildStepWeek(now: now, stepsByDay: const {}, goal: 0).goal,
        isNull,
      );
    });
  });

  group('sağlayıcılar', () {
    late _FakeSource src;
    ProviderContainer kap() {
      final c = ProviderContainer(
        overrides: [stepSourceProvider.overrideWithValue(src)],
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() {
      src = _FakeSource();
      SharedPreferences.setMockInitialValues({});
    });

    Future<StepLinkState> link(ProviderContainer c) async {
      c.read(healthPrefsProvider); // tercihleri yükle
      await Future<void>.delayed(Duration.zero);
      return c.read(stepLinkStateProvider.future);
    }

    test(
      'platform yoksa unavailable; Health Connect eksikse needsInstall',
      () async {
        src.status = StepPlatformStatus.unavailable;
        expect(await link(kap()), StepLinkState.unavailable);
        src.status = StepPlatformStatus.needsInstall;
        expect(await link(kap()), StepLinkState.needsInstall);
      },
    );

    test('bağlanmadan önce notConnected; adım okunmaz', () async {
      final c = kap();
      expect(await link(c), StepLinkState.notConnected);
      expect(await c.read(stepWeekProvider.future), isNull);
    });

    test('bağlıysa 7 gün okunur, hedef uygulanır', () async {
      SharedPreferences.setMockInitialValues({
        'health_connected': true,
        'health_step_goal': 10000,
      });
      final c = kap();
      expect(await link(c), StepLinkState.connected);
      final w = await c.read(stepWeekProvider.future);
      expect(w!.days, hasLength(7));
      expect(w.goal, 10000);
      expect(w.todayProgress, 0.5);
    });

    test(
      'Android izni kaldırılmışsa bağlantı düşer; iOS (null) tercihe güvenir',
      () async {
        SharedPreferences.setMockInitialValues({'health_connected': true});
        src.access = false;
        expect(await link(kap()), StepLinkState.notConnected);
        src.access = null;
        expect(await link(kap()), StepLinkState.connected);
      },
    );

    test('S-8 hesap değişiminde tercihler silinir', () async {
      SharedPreferences.setMockInitialValues({
        'health_connected': true,
        'health_step_goal': 9000,
      });
      await HealthPrefs.clear();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('health_connected'), isNull);
      expect(prefs.getInt('health_step_goal'), isNull);
    });

    test('hedef 0 ya da boş verilince kaldırılır', () async {
      final c = kap();
      await c.read(healthPrefsProvider.notifier).setStepGoal(8000);
      expect(c.read(healthPrefsProvider).stepGoal, 8000);
      await c.read(healthPrefsProvider.notifier).setStepGoal(0);
      expect(c.read(healthPrefsProvider).stepGoal, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('health_step_goal'), isNull);
    });
  });
}
