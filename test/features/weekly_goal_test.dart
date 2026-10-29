import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/core/prefs/week_start_provider.dart';
import 'package:fit_pack/core/utils/current_day.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/home/providers/weekly_goal_provider.dart';
import 'package:fit_pack/features/home/providers/home_providers.dart';
import 'package:fit_pack/features/home/weekly_goal.dart';
import 'package:fit_pack/features/insights/weekly_review_providers.dart';
import 'package:fit_pack/features/insights/weekly_review.dart';
import 'package:fit_pack/features/assistant/assistant_providers.dart';
import 'package:fit_pack/features/onboarding/program_recommendation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_database.dart';

void main() {
  test('G3 sağlayıcı kısmi hedef haftasını tam hafta diye yargılamaz', () async {
    final history = WeeklyTargetHistory([
      WeeklyTargetRevision(
        effectiveWeekStart: DateTime(2026, 10, 19),
        targetDays: 3,
      ),
    ]);
    SharedPreferences.setMockInitialValues({
      'week_start': DateTime.sunday,
      WeeklyTargetHistoryController.storageKey('a'): jsonEncode(history.toJson()),
    });
    final db = newTestDatabase();
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        weeklyGoalAccountProvider.overrideWithValue('a'),
        currentDayProvider.overrideWith((ref) => DateTime(2026, 10, 29)),
      ],
    );
    final sub = c.listen(weeklyReviewProvider(1), (_, _) {});
    addTearDown(() async {
      sub.close();
      c.dispose();
      await db.close();
    });
    await c.read(weekStartProvider.notifier).setWeekStart(DateTime.sunday);
    final review = await c.read(weeklyReviewProvider(1).future);
    expect(review.period.start, DateTime(2026, 10, 18));
    expect(review.period.isComplete, isTrue);
    expect(review.workout.planned, 3);
    expect(review.workout.targetKnown, isTrue);
    expect(review.workout.trainingDays, 0);
    expect(review.workout.targetCoversWholePeriod, isFalse);
    expect(review.focus.kind, isNot(FocusKind.completePlan));
  });

  test(
    'disk yazması başarısızsa hedef yayımlanmaz; yeniden deneme kilitlenmez',
    () async {
      SharedPreferences.setMockInitialValues({});
      var fail = true;
      final c = ProviderContainer(
        overrides: [
          weeklyGoalAccountProvider.overrideWithValue('a'),
          weeklyTargetTodayProvider.overrideWithValue(DateTime(2026, 10, 28)),
          weeklyTargetWriteProvider.overrideWithValue((
            prefs,
            key,
            value,
          ) async {
            if (fail) return false;
            return prefs.setString(key, value);
          }),
        ],
      );
      addTearDown(c.dispose);
      await c.read(selectedWeeklyGoalProvider.future);
      await expectLater(
        c.read(selectedWeeklyGoalProvider.notifier).setGoal(3),
        throwsStateError,
      );
      expect(await c.read(selectedWeeklyGoalProvider.future), isNull);
      expect(await c.read(weeklyTargetHistoryProvider.future), isNull);
      fail = false;
      await c.read(selectedWeeklyGoalProvider.notifier).setGoal(3);
      expect(await c.read(selectedWeeklyGoalProvider.future), 3);
    },
  );

  test('A hesabında açılan düzenleyici B hesabının hedefini yazamaz', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer(
      overrides: [weeklyGoalAccountProvider.overrideWithValue('b')],
    );
    addTearDown(c.dispose);
    await c.read(selectedWeeklyGoalProvider.future);
    await expectLater(
      c
          .read(selectedWeeklyGoalProvider.notifier)
          .scheduleGoal(2, expectedAccount: 'a'),
      throwsStateError,
    );
    await expectLater(
      c
          .read(selectedWeeklyGoalProvider.notifier)
          .setGoal(2, expectedAccount: 'a'),
      throwsStateError,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(WeeklyTargetHistoryController.storageKey('b')),
      isNull,
    );
    expect(await c.read(selectedWeeklyGoalProvider.future), isNull);
  });

  test(
    'tamamlanmamış kurulum düzeltilebilir, bitmiş profil hedefi yeniden yazamaz',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = newTestDatabase();
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          weeklyGoalAccountProvider.overrideWithValue('a'),
          weeklyTargetTodayProvider.overrideWithValue(DateTime(2026, 10, 28)),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await db.userProfileDao.ensureProfile();
      await c.read(selectedWeeklyGoalProvider.future);
      await c
          .read(selectedWeeklyGoalProvider.notifier)
          .setGoal(
            3,
            expectedAccount: 'a',
            allowIncompleteOnboardingRetry: true,
          );
      await c
          .read(selectedWeeklyGoalProvider.notifier)
          .setGoal(
            2,
            expectedAccount: 'a',
            allowIncompleteOnboardingRetry: true,
          );
      expect(await c.read(selectedWeeklyGoalProvider.future), 2);
      expect(
        (await c.read(weeklyTargetHistoryProvider.future))!.revisions.length,
        1,
      );
      await db.userProfileDao.updateFields(
        const UserProfileCompanion(onboarded: Value(true)),
      );
      await expectLater(
        c
            .read(selectedWeeklyGoalProvider.notifier)
            .setGoal(
              4,
              expectedAccount: 'a',
              allowIncompleteOnboardingRetry: true,
            ),
        throwsStateError,
      );
      expect(await c.read(selectedWeeklyGoalProvider.future), 2);
    },
  );

  Routine routine({String? program, int? day, bool archived = false}) =>
      Routine(
        id: 1,
        name: 'A',
        createdAt: DateTime(2026),
        orderIndex: 0,
        isArchived: archived,
        programKey: program,
        scheduledWeekday: day,
        syncState: 0,
        changedAtMs: 0,
        localSeq: 0,
      );

  test('seçim > program > benzersiz plan > varsayılan', () {
    final r = [routine(program: 'upperlower_beginner', day: 1)];
    expect(resolveWeeklyGoal(selected: 6, routines: r), 6);
    expect(resolveWeeklyGoal(routines: r), 4);
    expect(
      resolveWeeklyGoal(
        routines: [routine(day: 1), routine(day: 1), routine(day: 3)],
      ),
      2,
    );
    expect(resolveWeeklyGoal(routines: [routine(archived: true, day: 1)]), 3);
    expect(resolveWeeklyGoal(selected: 0, routines: []), 3);
    expect(onboardingWeeklyGoal(WeeklyDays.twoThree), 3);
    expect(onboardingWeeklyGoal(WeeklyDays.four), 4);
    expect(onboardingWeeklyGoal(WeeklyDays.fiveSix), 6);
  });

  test('hesap tercihleri birbirine sızmaz; yeniden açılınca korunur', () async {
    SharedPreferences.setMockInitialValues({'weekly_goal_v1_a': 4});
    final account = StateProvider<String?>((ref) => 'a');
    final c = ProviderContainer(
      overrides: [
      weeklyGoalAccountProvider.overrideWith((ref) => ref.watch(account)),
      ],
    );
    addTearDown(c.dispose);
    expect(await c.read(selectedWeeklyGoalProvider.future), 4);
    c.read(account.notifier).state = 'b';
    expect(await c.read(selectedWeeklyGoalProvider.future), isNull);
    await c.read(selectedWeeklyGoalProvider.notifier).setGoal(6);
    expect(await c.read(selectedWeeklyGoalProvider.future), 6);
    c.read(account.notifier).state = 'a';
    expect(await c.read(selectedWeeklyGoalProvider.future), 4);
    c.invalidate(selectedWeeklyGoalProvider);
    expect(await c.read(selectedWeeklyGoalProvider.future), 4);
    c.read(account.notifier).state = null;
    expect(await c.read(selectedWeeklyGoalProvider.future), isNull);
    await expectLater(
      c.read(selectedWeeklyGoalProvider.notifier).setGoal(3),
      throwsStateError,
    );
  });

  test('yazma sürerken hesap değişirse yeni hesap eski hedefi almaz', () async {
    SharedPreferences.setMockInitialValues({});
    final account = StateProvider<String?>((ref) => 'a');
    final c = ProviderContainer(
      overrides: [
      weeklyGoalAccountProvider.overrideWith((ref) => ref.watch(account)),
      ],
    );
    addTearDown(c.dispose);
    await c.read(selectedWeeklyGoalProvider.future);
    final write = c.read(selectedWeeklyGoalProvider.notifier).setGoal(6);
    final canceled = expectLater(write, throwsStateError);
    c.read(account.notifier).state = 'b';
    await canceled;
    expect(await c.read(selectedWeeklyGoalProvider.future), isNull);
    c.read(account.notifier).state = 'a';
    expect(await c.read(selectedWeeklyGoalProvider.future), isNull);
  });

  test(
    'gelecek hafta hedefi bugün değişmez; kapalı hafta hedefi korunur',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = newTestDatabase();
      final today = StateProvider<DateTime>((ref) => DateTime(2026, 10, 28));
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          weeklyGoalAccountProvider.overrideWithValue('a'),
          weeklyTargetTodayProvider.overrideWith((ref) => ref.watch(today)),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await c.read(selectedWeeklyGoalProvider.future);
      await c.read(selectedWeeklyGoalProvider.notifier).setGoal(3);
      await c.read(selectedWeeklyGoalProvider.notifier).scheduleGoal(2);
      expect(await c.read(weeklyGoalProvider.future), 3);
      expect((await c.read(currentWeeklyTargetProvider.future)).targetDays, 3);
      expect((await c.read(nextWeeklyTargetProvider.future)).targetDays, 2);
      final old = await c.read(
        weeklyTargetForPeriodProvider(DateTime(2026, 10, 19)).future,
      );
      expect(old.targetKnown, isFalse);
      c.read(today.notifier).state = DateTime(2026, 11, 4);
      expect(await c.read(weeklyGoalProvider.future), 2);
      final closed = await c.read(
        weeklyTargetForPeriodProvider(DateTime(2026, 10, 26)).future,
      );
      expect(closed.targetDays, 3);
      await expectLater(
        c.read(selectedWeeklyGoalProvider.notifier).setGoal(6),
        throwsStateError,
      );
    },
  );

  test(
    'legacy hedefi planlarken yalnız mevcut haftadan itibaren dondurur',
    () async {
      SharedPreferences.setMockInitialValues({'weekly_goal_v1_a': 4});
      final db = newTestDatabase();
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          weeklyGoalAccountProvider.overrideWithValue('a'),
          weeklyTargetTodayProvider.overrideWithValue(DateTime(2026, 10, 28)),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await c.read(selectedWeeklyGoalProvider.future);
      await c.read(selectedWeeklyGoalProvider.notifier).scheduleGoal(2);
      expect((await c.read(currentWeeklyTargetProvider.future)).targetDays, 4);
      expect((await c.read(nextWeeklyTargetProvider.future)).targetDays, 2);
      expect(
        (await c.read(
          weeklyTargetForPeriodProvider(DateTime(2026, 10, 19)).future,
        )).targetDays,
        isNull,
      );
    },
  );

  test('bozuk tarihçe sessizce eski hedefe düşmez', () async {
    SharedPreferences.setMockInitialValues({
      'weekly_target_history_v1_a': '{broken',
      'weekly_goal_v1_a': 4,
    });
    final c = ProviderContainer(
      overrides: [weeklyGoalAccountProvider.overrideWithValue('a')],
    );
    addTearDown(c.dispose);
    await expectLater(
      c.read(selectedWeeklyGoalProvider.future),
      throwsFormatException,
    );
  });

  test('üç tüketici aynı hedefi okur ve seçim değişince yenilenir', () async {
    SharedPreferences.setMockInitialValues({'weekly_goal_v1_a': 4});
    final db = newTestDatabase();
    final c = ProviderContainer(
      overrides: [
      databaseProvider.overrideWithValue(db),
      weeklyGoalAccountProvider.overrideWithValue('a'),
      ],
    );
    final sub = c.listen(assistantSnapshotProvider, (_, _) {});
    final reviewSub = c.listen(weeklyReviewProvider(0), (_, _) {});
    addTearDown(() async {
      sub.close();
      reviewSub.close();
      c.dispose();
      await db.close();
    });
    await db.userProfileDao.ensureProfile();
    await db
        .into(db.routines)
        .insert(
          RoutinesCompanion.insert(
            name: 'A',
            createdAt: DateTime.now(),
            scheduledWeekday: const Value(1),
          ),
        );
    expect((await c.read(weeklyStreakProvider.future)).weeklyGoal, 4);
    expect((await c.read(assistantSnapshotProvider.future)).weeklyGoal, 4);
    final review = await c.read(weeklyReviewProvider(0).future);
    expect(review.workout.planned, 4);
    await c.read(selectedWeeklyGoalProvider.notifier).setGoal(6);
    expect((await c.read(weeklyStreakProvider.future)).weeklyGoal, 6);
    expect((await c.read(assistantSnapshotProvider.future)).weeklyGoal, 6);
    expect((await c.read(weeklyReviewProvider(0).future)).workout.planned, 6);
  });
}
