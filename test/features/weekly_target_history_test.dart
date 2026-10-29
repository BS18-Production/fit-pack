import 'dart:convert';

import 'package:fit_pack/features/goals/weekly_target_history.dart';
import 'package:fit_pack/features/home/streak_calc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final previous = DateTime(2026, 10, 19);
  final current = DateTime(2026, 10, 26);
  final next = DateTime(2026, 11, 2);

  WeeklyTargetHistory history(int days) => WeeklyTargetHistory([
    WeeklyTargetRevision(effectiveWeekStart: current, targetDays: days),
  ]);

  test(
    'gelecek hafta 3→2 önceki hedefi veya kapalı haftayı yeniden yazmaz',
    () {
      final first = history(3);
      final changed = first.schedule(
        currentWeekStart: current,
        effectiveWeekStart: next,
        targetDays: 2,
      );
      expect(changed.targetFor(previous), isNull);
      expect(changed.targetFor(current), 3);
      expect(changed.targetFor(next), 2);
      expect(first.revisions.length, 1);
      expect(
        () => first.schedule(
          currentWeekStart: current,
          effectiveWeekStart: previous,
          targetDays: 2,
        ),
        throwsArgumentError,
      );
      expect(
        () => first.schedule(
          currentWeekStart: current,
          effectiveWeekStart: current,
          targetDays: 2,
        ),
        throwsArgumentError,
      );
    },
  );

  test('tekrar onay gelecek haftada ikinci revizyon yaratmaz', () {
    final first = history(3).schedule(
      currentWeekStart: current,
      effectiveWeekStart: next,
      targetDays: 2,
    );
    final same = first.schedule(
      currentWeekStart: current,
      effectiveWeekStart: next,
      targetDays: 2,
    );
    final revised = same.schedule(
      currentWeekStart: current,
      effectiveWeekStart: next,
      targetDays: 4,
    );
    expect(same.revisions.length, 2);
    expect(revised.revisions.length, 2);
    expect(revised.targetFor(current), 3);
    expect(revised.targetFor(next), 4);
  });

  test('yerel tarih/kapalı metrik JSON gidiş dönüşü ve bozuk veri', () {
    final decoded = WeeklyTargetHistory.fromJson(
      jsonDecode(jsonEncode(history(3).toJson())),
    );
    expect(decoded.targetFor(current), 3);
    expect(decoded.toJson()['metric'], 'training_days');
    expect(
      () => WeeklyTargetHistory.fromJson({
        'version': 1,
        'metric': 'training_days',
        'revisions': [
          {'week': '2026-02-31', 'days': 3},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => WeeklyTargetHistory.fromJson({
        'version': 1,
        'metric': 'training_days',
        'revisions': [
          {'week': '2026-10-26', 'days': 0},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => WeeklyTargetHistory.fromJson({
        'version': 2,
        'metric': 'training_days',
        'revisions': [],
      }),
      throwsFormatException,
    );
    expect(
      () => WeeklyTargetHistory([
        WeeklyTargetRevision(effectiveWeekStart: current, targetDays: 3),
        WeeklyTargetRevision(effectiveWeekStart: current, targetDays: 2),
      ]),
      throwsFormatException,
    );
  });

  test(
    'eski tek sayı yalnız güncel haftada kanıt, geçmişte hedef bilinmiyor',
    () {
      final old = resolveWeeklyTargetPeriod(
        periodStart: previous,
        currentWeekStart: current,
        history: null,
        legacyCurrentGoal: 3,
      );
      final now = resolveWeeklyTargetPeriod(
        periodStart: current,
        currentWeekStart: current,
        history: null,
        legacyCurrentGoal: 3,
      );
      expect(old.targetKnown, isFalse);
      expect(old.targetDays, isNull);
      expect(now.targetKnown, isTrue);
      expect(now.targetDays, 3);
    },
  );

  test('seri her haftanın kendi hedefini kullanır ve bilinmeyende durur', () {
    final targets = history(3).schedule(
      currentWeekStart: current,
      effectiveWeekStart: next,
      targetDays: 2,
    );
    final streak = computeWeeklyStreak(
      sessionDates: [
        current,
        DateTime(2026, 10, 28),
        DateTime(2026, 10, 30),
        next,
        DateTime(2026, 11, 4),
        // Aynı gün ikinci seans hedefi üçüncü güne taşımaz.
        DateTime(2026, 11, 4, 18),
      ],
      weeklyGoal: 2,
      now: DateTime(2026, 11, 4, 20),
      weekStart: DateTime.monday,
      goalForWeek: targets.targetFor,
    );
    expect(streak.thisWeekDone, 2);
    expect(streak.weeks, 2);
    expect(streak.historyLimited, isTrue);
    expect(streak.targetKnown, isTrue);
  });

  test('hedef bilinmiyorsa varsayılan sayı başarı iddiası oluşturmaz', () {
    final result = computeWeeklyStreak(
      sessionDates: [current],
      weeklyGoal: 3,
      now: current,
      weekStart: DateTime.monday,
      targetKnown: false,
      goalForWeek: (_) => null,
    );
    expect(result.targetKnown, isFalse);
    expect(result.thisWeekComplete, isFalse);
    expect(result.remaining, 0);
    expect(result.weeks, 0);
  });

  test('Pazartesi→Pazar değişimi sabit yürürlük tarihini kaydırmaz', () {
    final targets = history(3).schedule(
      currentWeekStart: current,
      effectiveWeekStart: next,
      targetDays: 2,
    );
    // Takvim Pazar oldu; mevcut haftanın başlangıcı ilk revizyondan önce.
    final nowSundayWeek = resolveWeeklyTargetPeriod(
      periodStart: DateTime(2026, 10, 25),
      currentWeekStart: DateTime(2026, 10, 25),
      currentDate: DateTime(2026, 10, 29),
      history: targets,
    );
    expect(nowSundayWeek.targetDays, 3);
    expect(nowSundayWeek.targetEffectiveFrom, current);
    final beforeMonday = resolveWeeklyTargetPeriod(
      periodStart: DateTime(2026, 11, 1),
      currentWeekStart: DateTime(2026, 11, 1),
      currentDate: DateTime(2026, 11, 1),
      history: targets,
    );
    final onMonday = resolveWeeklyTargetPeriod(
      periodStart: DateTime(2026, 11, 1),
      currentWeekStart: DateTime(2026, 11, 1),
      currentDate: DateTime(2026, 11, 2),
      history: targets,
    );
    expect(beforeMonday.targetDays, 3);
    expect(onMonday.targetDays, 2);
    expect(onMonday.targetEffectiveFrom, next);
    expect(onMonday.coversWholePeriod, isFalse);
    expect(beforeMonday.coversWholePeriod, isTrue);
    final closed = resolveWeeklyTargetPeriod(
      periodStart: DateTime(2026, 10, 25),
      currentWeekStart: DateTime(2026, 11, 1),
      currentDate: DateTime(2026, 11, 4),
      history: targets,
    );
    expect(closed.targetDays, 3);
    expect(closed.coversWholePeriod, isFalse);
  });
}
