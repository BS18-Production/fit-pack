import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/home/providers/weekly_goal_provider.dart';
import 'package:fit_pack/features/home/providers/home_providers.dart';
import 'package:fit_pack/features/home/weekly_goal.dart';
import 'package:fit_pack/features/insights/weekly_review_providers.dart';
import 'package:fit_pack/features/assistant/assistant_providers.dart';
import 'package:fit_pack/features/onboarding/program_recommendation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_database.dart';

void main() {
  Routine routine({String? program, int? day, bool archived = false}) => Routine(
    id: 1, name: 'A', createdAt: DateTime(2026), orderIndex: 0,
    isArchived: archived, programKey: program, scheduledWeekday: day,
    syncState: 0, changedAtMs: 0, localSeq: 0);

  test('seçim > program > benzersiz plan > varsayılan', () {
    final r = [routine(program: 'upperlower_beginner', day: 1)];
    expect(resolveWeeklyGoal(selected: 6, routines: r), 6);
    expect(resolveWeeklyGoal(routines: r), 4);
    expect(resolveWeeklyGoal(routines: [routine(day: 1), routine(day: 1), routine(day: 3)]), 2);
    expect(resolveWeeklyGoal(routines: [routine(archived: true, day: 1)]), 3);
    expect(resolveWeeklyGoal(selected: 0, routines: []), 3);
    expect(onboardingWeeklyGoal(WeeklyDays.twoThree), 3);
    expect(onboardingWeeklyGoal(WeeklyDays.four), 4);
    expect(onboardingWeeklyGoal(WeeklyDays.fiveSix), 6);
  });

  test('hesap tercihleri birbirine sızmaz; yeniden açılınca korunur', () async {
    SharedPreferences.setMockInitialValues({'weekly_goal_v1_a': 4});
    final account = StateProvider<String?>((ref) => 'a');
    final c = ProviderContainer(overrides: [
      weeklyGoalAccountProvider.overrideWith((ref) => ref.watch(account)),
    ]);
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
    await expectLater(c.read(selectedWeeklyGoalProvider.notifier).setGoal(3), throwsStateError);
  });

  test('yazma sürerken hesap değişirse yeni hesap eski hedefi almaz', () async {
    SharedPreferences.setMockInitialValues({});
    final account = StateProvider<String?>((ref) => 'a');
    final c = ProviderContainer(overrides: [
      weeklyGoalAccountProvider.overrideWith((ref) => ref.watch(account)),
    ]);
    addTearDown(c.dispose);
    await c.read(selectedWeeklyGoalProvider.future);
    final write = c.read(selectedWeeklyGoalProvider.notifier).setGoal(6);
    c.read(account.notifier).state = 'b';
    await write;
    expect(await c.read(selectedWeeklyGoalProvider.future), isNull);
    c.read(account.notifier).state = 'a';
    expect(await c.read(selectedWeeklyGoalProvider.future), 6);
  });

  test('üç tüketici aynı hedefi okur ve seçim değişince yenilenir', () async {
    SharedPreferences.setMockInitialValues({'weekly_goal_v1_a': 4});
    final db = newTestDatabase();
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      weeklyGoalAccountProvider.overrideWithValue('a'),
    ]);
    final sub = c.listen(assistantSnapshotProvider, (_, _) {});
    final reviewSub = c.listen(weeklyReviewProvider(0), (_, _) {});
    addTearDown(() async { sub.close(); reviewSub.close(); c.dispose(); await db.close(); });
    await db.userProfileDao.ensureProfile();
    await db.into(db.routines).insert(RoutinesCompanion.insert(
      name: 'A', createdAt: DateTime.now(), scheduledWeekday: const Value(1)));
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
