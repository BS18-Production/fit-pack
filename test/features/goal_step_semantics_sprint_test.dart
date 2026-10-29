import 'dart:convert';

import 'package:fit_pack/core/theme/app_theme.dart';
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
  testWidgets('goal steps expose distinct completed and pending semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final l = lookupAppL10n(const Locale('tr'));
      final journey = GoalJourney(
        purpose: GoalPurpose.routine,
        startedAt: DateTime(2026, 10, 1),
      );
      SharedPreferences.setMockInitialValues({
        'goal_journey_v1_semantics-account': jsonEncode(journey.toJson()),
      });
      final session = WorkoutSession(
        id: 1,
        date: DateTime(2026, 10, 20),
        phase: 1,
        workoutType: 'synthetic',
        kneeStatus: 'normal',
        isDeload: false,
      );
      final container = ProviderContainer(
        overrides: [
          weeklyGoalAccountProvider.overrideWithValue('semantics-account'),
          goalEvidenceProvider.overrideWith(
            (ref) => Stream.value(
              GoalEvidence(
                sessions: [session],
                baselineSessions: const [],
                points: const [],
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
          weeklyReviewProvider.overrideWith(
            (ref, offset) => Stream.value(
              buildWeeklyReview(
                WeeklyReviewInput(
                  weekStart: DateTime(2026, 10, 19),
                  now: DateTime(2026, 10, 29),
                  weeklyGoal: 3,
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Keep both steps inside the semantic viewport. A non-container
      // Semantics annotation may be merged with adjacent text.
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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

      final completed = '${l.goalMilestoneStart}. ${l.goalStepDone}';
      final pending = '${l.goalMilestoneReview}. ${l.goalStepPending}';
      await tester.scrollUntilVisible(find.text(l.goalMilestoneStart), 200);
      await tester.ensureVisible(find.text(l.goalMilestoneStart));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel(RegExp(RegExp.escape(completed))).first,
            )
            .getSemanticsData()
            .label,
        contains(completed),
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            RegExp.escape('${l.goalMilestoneStart}. ${l.goalStepPending}'),
          ),
        ),
        findsNothing,
      );

      await tester.ensureVisible(find.text(l.goalMilestoneReview));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel(RegExp(RegExp.escape(pending))).first,
            )
            .getSemanticsData()
            .label,
        contains(pending),
      );
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape('${l.goalMilestoneReview}. ${l.goalStepDone}')),
        ),
        findsNothing,
      );
    } finally {
      semantics.dispose();
    }
  });
}
