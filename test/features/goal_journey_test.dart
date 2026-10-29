import 'dart:async';
import 'dart:convert';

import 'package:fit_pack/data/database/daos/workout_dao.dart';
import 'package:fit_pack/features/goals/goal_journey.dart';
import 'package:fit_pack/features/goals/goal_journey_providers.dart';
import 'package:fit_pack/features/home/providers/weekly_goal_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final start = DateTime(2026, 10, 29);
  GoalJourney journey() => GoalJourney(
    purpose: GoalPurpose.strength,
    startedAt: start,
    exerciseId: 12,
  );

  test(
    'purpose changes preserve starting date and real exercise selection',
    () {
      final j = journey()
          .withPurpose(GoalPurpose.returnToRoutine)
          .withReview('2026-10-19');
      final read = GoalJourney.fromJson(
        jsonDecode(jsonEncode(j.toJson())) as Map<String, dynamic>,
      );
      expect(read.startedAt, start);
      expect(read.exerciseId, 12);
      expect(read.purpose, GoalPurpose.returnToRoutine);
      expect(read.reviewedWeek, '2026-10-19');
      expect(
        () => GoalJourney.fromJson({...j.toJson(), 'version': 9}),
        throwsFormatException,
      );
      expect(
        () => GoalJourney.fromJson({...j.toJson(), 'exerciseId': 0}),
        throwsFormatException,
      );
    },
  );

  test(
    'comparison needs different days; same day sets never invent progress',
    () {
      ExerciseProgressPoint p(int day, int reps, {int id = 12}) =>
          ExerciseProgressPoint(
            exerciseId: id,
            name: 'Example',
            date: DateTime(2026, 10, day),
            weightKg: 30,
            reps: reps,
          );
      expect(
        comparisonDays([p(20, 8), p(20, 10), p(25, 12, id: 9)], 12).length,
        1,
      );
      final result = comparisonDays([
        p(20, 8),
        p(20, 10),
        p(25, 11),
        p(27, 9),
      ], 12);
      expect(result.map((e) => e.date.day), [20, 27]);
      expect(result.first.reps, 10);
      expect(
        result.last.reps,
        9,
      ); // A decline remains visible; not only positive records.
      expect(comparisonDays([p(20, 0)], 12), isEmpty);
    },
  );

  test(
    'account-local purpose and metric survive reload without leaking',
    () async {
      SharedPreferences.setMockInitialValues({});
      final account = StateProvider<String?>((ref) => 'a');
      final c = ProviderContainer(
        overrides: [
          weeklyGoalAccountProvider.overrideWith((ref) => ref.watch(account)),
        ],
      );
      addTearDown(c.dispose);
      expect(await c.read(goalJourneyProvider.future), isNull);
      await c
          .read(goalJourneyProvider.notifier)
          .save(journey(), expectedAccount: 'a');
      c.read(account.notifier).state = 'b';
      expect(await c.read(goalJourneyProvider.future), isNull);
      c.read(account.notifier).state = 'a';
      expect((await c.read(goalJourneyProvider.future))!.exerciseId, 12);
    },
  );

  test('stale editor A cannot write B, including after return to A', () async {
    SharedPreferences.setMockInitialValues({});
    final account = StateProvider<String?>((ref) => 'a');
    final c = ProviderContainer(
      overrides: [
        weeklyGoalAccountProvider.overrideWith((ref) => ref.watch(account)),
      ],
    );
    addTearDown(c.dispose);
    await c.read(goalJourneyProvider.future);
    final generation = c.read(goalJourneyProvider.notifier).generation;
    c.read(account.notifier).state = 'b';
    await c.read(goalJourneyProvider.future);
    await expectLater(
      c
          .read(goalJourneyProvider.notifier)
          .save(journey(), expectedAccount: 'a'),
      throwsStateError,
    );
    c.read(account.notifier).state = 'a';
    await c.read(goalJourneyProvider.future);
    await expectLater(
      c
          .read(goalJourneyProvider.notifier)
          .save(
            journey(),
            expectedAccount: 'a',
            expectedGeneration: generation,
          ),
      throwsStateError,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('goal_journey_v1_a'), isNull);
    expect(prefs.getString('goal_journey_v1_b'), isNull);
  });

  test(
    'pending preference load cannot publish or write after account change',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final pending = Completer<SharedPreferences>();
      final account = StateProvider<String?>((ref) => 'a');
      final c = ProviderContainer(
        overrides: [
          weeklyGoalAccountProvider.overrideWith((ref) => ref.watch(account)),
          goalJourneyPreferencesProvider.overrideWith((ref) => pending.future),
        ],
      );
      addTearDown(c.dispose);
      final operation = c
          .read(goalJourneyProvider.notifier)
          .save(journey(), expectedAccount: 'a');
      final rejected = expectLater(operation, throwsStateError);
      c.read(account.notifier).state = 'b';
      pending.complete(prefs);
      await rejected;
      expect(prefs.containsKey('goal_journey_v1_a'), isFalse);
      expect(prefs.containsKey('goal_journey_v1_b'), isFalse);
    },
  );

  test(
    'corrupt local state stays an error; no silent replacement goal',
    () async {
      SharedPreferences.setMockInitialValues({'goal_journey_v1_a': '{broken'});
      final c = ProviderContainer(
        overrides: [weeklyGoalAccountProvider.overrideWithValue('a')],
      );
      addTearDown(c.dispose);
      await expectLater(
        c.read(goalJourneyProvider.future),
        throwsFormatException,
      );
    },
  );
}
