import 'dart:convert';

import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/daos/workout_dao.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/goals/goal_journey.dart';
import 'package:fit_pack/features/goals/goal_journey_providers.dart';
import 'package:fit_pack/features/goals/goal_journey_screen.dart';
import 'package:fit_pack/features/home/providers/weekly_goal_provider.dart';
import 'package:fit_pack/features/home/today_task.dart';
import 'package:fit_pack/features/insights/weekly_review.dart';
import 'package:fit_pack/features/insights/weekly_review_providers.dart';
import 'package:fit_pack/features/workout/routine_providers.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final l = lookupAppL10n(const Locale('tr'));

  Future<void> pumpGoal(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(UncontrolledProviderScope(container: container,
      child: MaterialApp(theme: AppTheme.dark, locale: const Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const GoalJourneyScreen())));
    await tester.pumpAndSettle();
  }

  for (final wholePeriod in [false, true]) {
    testWidgets('reflection target adjustment requires whole-period evidence: $wholePeriod', (tester) async {
      final journey = GoalJourney(purpose: GoalPurpose.routine, startedAt: DateTime(2026, 10, 1));
      SharedPreferences.setMockInitialValues({'goal_journey_v1_a': jsonEncode(journey.toJson())});
      final c = ProviderContainer(overrides: [
        weeklyGoalAccountProvider.overrideWithValue('a'),
        goalEvidenceProvider.overrideWith((ref) => Stream.value(const GoalEvidence(sessions: [], baselineSessions: [], points: []))),
        currentWeeklyTargetProvider.overrideWith((ref) async => WeeklyTargetPeriod(start: DateTime(2026, 10, 26), end: DateTime(2026, 11, 2), targetDays: 3)),
        nextWeeklyTargetProvider.overrideWith((ref) async => WeeklyTargetPeriod(start: DateTime(2026, 11, 2), end: DateTime(2026, 11, 9), targetDays: 3)),
        activeRoutinesProvider.overrideWith((ref) => Stream.value([])),
        todayTaskProvider.overrideWithValue(const TodayTask(TodayTaskKind.noRoutine)),
        weeklyReviewProvider.overrideWith((ref, offset) => Stream.value(buildWeeklyReview(WeeklyReviewInput(
          weekStart: DateTime(2026, 10, 19), now: DateTime(2026, 10, 29), weeklyGoal: 3,
          weeklyTargetKnown: true, weeklyTargetCoversWholePeriod: wholePeriod,
          sessions: [WorkoutSession(id: 1, date: DateTime(2026, 10, 20), phase: 1, workoutType: 'synthetic', kneeStatus: 'normal', isDeload: false)],
        )))),
      ]);
      addTearDown(c.dispose);
      await pumpGoal(tester, c);
      await tester.scrollUntilVisible(find.text(l.goalRecordsAccurate), 200);
      await tester.ensureVisible(find.text(l.goalRecordsAccurate));
      await tester.tap(find.text(l.goalRecordsAccurate));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(l.goalTimeObstacle), 150);
      await tester.ensureVisible(find.text(l.goalTimeObstacle));
      await tester.tap(find.text(l.goalTimeObstacle));
      await tester.pumpAndSettle();
      expect(find.text(l.goalSuggestDays(1)), wholePeriod ? findsOneWidget : findsNothing);
      expect(find.text(l.goalPastTargetUnknown), wholePeriod ? findsNothing : findsOneWidget);
    });
  }

  testWidgets('same-account read failure can retry without becoming a stale editor', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var reads = 0;
    final c = ProviderContainer(overrides: [
      weeklyGoalAccountProvider.overrideWithValue('a'),
      goalJourneyPreferencesProvider.overrideWith((ref) async {
        if (reads++ == 0) throw StateError('transient storage read');
        return SharedPreferences.getInstance();
      }),
      goalEvidenceProvider.overrideWith((ref) => Stream.value(const GoalEvidence(
        sessions: [], baselineSessions: [], points: []))),
      currentWeeklyTargetProvider.overrideWith((ref) async => WeeklyTargetPeriod(
        start: DateTime(2026, 10, 26), end: DateTime(2026, 11, 2), targetDays: null)),
      nextWeeklyTargetProvider.overrideWith((ref) async => WeeklyTargetPeriod(
        start: DateTime(2026, 11, 2), end: DateTime(2026, 11, 9), targetDays: null)),
      activeRoutinesProvider.overrideWith((ref) => Stream.value([])),
      todayTaskProvider.overrideWithValue(const TodayTask(TodayTaskKind.noRoutine)),
    ]);
    addTearDown(c.dispose);
    await pumpGoal(tester, c);
    expect(find.text(l.goalLoadError), findsOneWidget);
    await tester.tap(find.text(l.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text(l.goalWhyTitle), findsOneWidget);
    expect(find.text(l.goalAccountChanged), findsNothing);
    expect(reads, 2);
  });

  testWidgets('failed exercise selection keeps committed choice and comparison', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final initial = GoalJourney(purpose: GoalPurpose.strength,
      startedAt: DateTime(2026, 10, 1), exerciseId: 1);
    final fake = _RejectingGoalPreferences(jsonEncode(initial.toJson()));
    final c = ProviderContainer(overrides: [
      weeklyGoalAccountProvider.overrideWithValue('a'),
      goalJourneyPreferencesProvider.overrideWith((ref) async => fake),
      goalEvidenceProvider.overrideWith((ref) => Stream.value(GoalEvidence(
        sessions: [], baselineSessions: [], points: [
          ExerciseProgressPoint(exerciseId: 1, name: 'Row', date: DateTime(2026, 10, 5), weightKg: 30, reps: 10),
          ExerciseProgressPoint(exerciseId: 2, name: 'Press', date: DateTime(2026, 10, 8), weightKg: 25, reps: 8),
        ]))),
      currentWeeklyTargetProvider.overrideWith((ref) async => WeeklyTargetPeriod(
        start: DateTime(2026, 10, 26), end: DateTime(2026, 11, 2), targetDays: 3)),
      nextWeeklyTargetProvider.overrideWith((ref) async => WeeklyTargetPeriod(
        start: DateTime(2026, 11, 2), end: DateTime(2026, 11, 9), targetDays: 3)),
      activeRoutinesProvider.overrideWith((ref) => Stream.value([])),
      todayTaskProvider.overrideWithValue(const TodayTask(TodayTaskKind.noRoutine)),
      weeklyReviewProvider.overrideWith((ref, offset) => Stream.value(buildWeeklyReview(
        WeeklyReviewInput(weekStart: DateTime(2026, 10, 19), now: DateTime(2026, 10, 29), weeklyGoal: 3)))),
    ]);
    addTearDown(c.dispose);
    await pumpGoal(tester, c);
    final dropdown = find.byType(DropdownButton<int>);
    await tester.scrollUntilVisible(dropdown, 200);
    expect(tester.widget<DropdownButton<int>>(dropdown).value, 1);
    tester.widget<DropdownButton<int>>(dropdown).onChanged!(2);
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<int>>(dropdown).value, 1);
    expect((await c.read(goalJourneyProvider.future))!.exerciseId, 1);
    expect(find.text(l.commonSaveFailed), findsOneWidget);
  });

  testWidgets(
    'goal is optional, baseline unknown is honest, account switch rejects editor',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final account = StateProvider<String?>((ref) => 'a');
      final c = ProviderContainer(
        overrides: [
          weeklyGoalAccountProvider.overrideWith((ref) => ref.watch(account)),
          goalEvidenceProvider.overrideWith(
            (ref) => Stream.value(
              const GoalEvidence(
                sessions: [],
                baselineSessions: [],
                points: [],
              ),
            ),
          ),
          currentWeeklyTargetProvider.overrideWith(
            (ref) async => WeeklyTargetPeriod(
              start: DateTime(2026, 10, 26),
              end: DateTime(2026, 11, 2),
              targetDays: null,
            ),
          ),
          nextWeeklyTargetProvider.overrideWith(
            (ref) async => WeeklyTargetPeriod(
              start: DateTime(2026, 11, 2),
              end: DateTime(2026, 11, 9),
              targetDays: null,
            ),
          ),
          activeRoutinesProvider.overrideWith((ref) => Stream.value([])),
          todayTaskProvider.overrideWithValue(
            const TodayTask(TodayTaskKind.noRoutine),
          ),
        ],
      );
      addTearDown(c.dispose);
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.dark,
            locale: const Locale('tr'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: const GoalJourneyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l.goalWhyTitle), findsOneWidget);
      expect(await c.read(goalJourneyProvider.future), isNull);
      await tester.scrollUntilVisible(find.text(l.goalNoBaseline), 200);
      expect(find.text(l.goalNoBaseline), findsOneWidget);
      expect(tester.takeException(), isNull);
      c.read(account.notifier).state = 'b';
      await tester.pumpAndSettle();
      expect(find.text(l.goalAccountChanged), findsOneWidget);
      expect(find.text(l.goalWhyTitle), findsNothing);
      c.read(account.notifier).state = 'a';
      await c.read(goalJourneyProvider.future);
      await tester.pumpAndSettle();
      expect(find.text(l.goalAccountChanged), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    },
  );

  testWidgets(
    'open weekly edit then switch account cannot confirm new account target',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final account = StateProvider<String?>((ref) => 'a');
      final c = ProviderContainer(
        overrides: [
          weeklyGoalAccountProvider.overrideWith((ref) => ref.watch(account)),
          goalEvidenceProvider.overrideWith(
            (ref) => Stream.value(
              const GoalEvidence(
                sessions: [],
                baselineSessions: [],
                points: [],
              ),
            ),
          ),
          currentWeeklyTargetProvider.overrideWith(
            (ref) async => WeeklyTargetPeriod(
              start: DateTime(2026, 10, 26),
              end: DateTime(2026, 11, 2),
              targetDays: 3,
            ),
          ),
          nextWeeklyTargetProvider.overrideWith(
            (ref) async => WeeklyTargetPeriod(
              start: DateTime(2026, 11, 2),
              end: DateTime(2026, 11, 9),
              targetDays: 3,
            ),
          ),
          activeRoutinesProvider.overrideWith((ref) => Stream.value([])),
          todayTaskProvider.overrideWithValue(
            const TodayTask(TodayTaskKind.noRoutine),
          ),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.dark,
            locale: const Locale('tr'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: const GoalJourneyScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(l.goalChooseNextWeek), 250);
      await tester.ensureVisible(find.text(l.goalChooseNextWeek));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.goalChooseNextWeek));
      await tester.pumpAndSettle();
      expect(find.text(l.goalNextWeekOnly), findsOneWidget);
      c.read(account.notifier).state = 'b';
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '2'));
      await tester.pumpAndSettle();
      expect(find.text(l.goalConfirmTitle), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey(WeeklyTargetHistoryController.storageKey('a')),
        isFalse,
      );
      expect(
        prefs.containsKey(WeeklyTargetHistoryController.storageKey('b')),
        isFalse,
      );
    },
  );
}

class _RejectingGoalPreferences extends Fake implements SharedPreferences {
  final String initial;
  _RejectingGoalPreferences(this.initial);
  @override
  String? getString(String key) => key == 'goal_journey_v1_a' ? initial : null;
  @override
  Future<bool> setString(String key, String value) async => false;
}
