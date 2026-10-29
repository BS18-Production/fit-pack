import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/data/seed/exercises_seed.dart';
import 'package:fit_pack/features/explore/program_detail_screen.dart';
import 'package:fit_pack/features/goals/goal_journey_providers.dart';
import 'package:fit_pack/features/goals/goal_journey_screen.dart';
import 'package:fit_pack/features/home/providers/weekly_goal_provider.dart';
import 'package:fit_pack/features/home/today_task.dart';
import 'package:fit_pack/features/onboarding/program_recommendation.dart';
import 'package:fit_pack/features/onboarding/training_setup.dart';
import 'package:fit_pack/features/onboarding/training_setup_providers.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// Synthetic interrupted setup boundary: persisted preference survives a
/// provider/widget recreation. This does NOT simulate process death or disk DB
/// reopen; the isolated in-memory DB remains alive across the recreation.
void main() {
  testWidgets(
    'catalog setup survives container recreation and real Add completes route',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = newTestDatabase();
      final setup = TrainingSetupProfile(
        planSource: TrainingPlanSource.catalog,
        experience: TrainingExperience.some,
        exactDays: 4,
        sessionBudgetMinutes: 60,
      );
      final program = setup.recommendedProgram!;
      const account = 'synthetic-catalog-recovery';
      final l = lookupAppL10n(const Locale('tr'));
      ProviderContainer container() => ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          weeklyGoalAccountProvider.overrideWithValue(account),
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
              targetDays: 4,
            ),
          ),
          nextWeeklyTargetProvider.overrideWith(
            (ref) async => WeeklyTargetPeriod(
              start: DateTime(2026, 11, 2),
              end: DateTime(2026, 11, 9),
              targetDays: 4,
            ),
          ),
          todayTaskProvider.overrideWithValue(
            const TodayTask(TodayTaskKind.noRoutine),
          ),
        ],
      );

      // Persist the completed synthetic account profile before the interrupted
      // catalog installation boundary; no real account or health values exist.
      await tester.runAsync(() async {
        await db.userProfileDao.ensureProfile();
        await db.userProfileDao.updateFields(
          const UserProfileCompanion(onboarded: Value(true)),
        );
      });
      final first = container();
      await first.read(trainingSetupProfileProvider.future);
      await first
          .read(trainingSetupProfileProvider.notifier)
          .save(setup, expectedAccount: account);
      expect(
        await tester.runAsync(() => db.workoutDao.getActiveRoutines()),
        isEmpty,
      );
      first
          .dispose(); // interruption after preference commit, before installation

      final names = {
        for (final r in program.routines)
          for (final e in r.exercises) e.name,
      };
      await tester.runAsync(() async {
        for (final e in exerciseSeedData.where((e) => names.contains(e.name))) {
          await db
              .into(db.exercises)
              .insert(
                ExercisesCompanion.insert(
                  name: e.name,
                  category: e.category,
                  muscleGroups: '[]',
                  primaryMuscle: Value(e.primaryMuscle),
                  equipment: Value(e.equipment),
                  measurementType: Value(e.measurement),
                ),
              );
        }
      });
      final recreated = container();
      expect(
        (await tester.runAsync(
          () => db.userProfileDao.getProfile(),
        ))!.onboarded,
        isTrue,
      );
      final router = GoRouter(
        initialLocation: AppRoutes.goalJourney,
        routes: [
          GoRoute(
            path: AppRoutes.goalJourney,
            builder: (_, _) => const GoalJourneyScreen(),
          ),
          GoRoute(
            path: AppRoutes.programPath,
            builder: (_, state) => ProgramDetailScreen(
              programKey: state.pathParameters['programKey']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.workout,
            builder: (_, _) =>
                const Scaffold(body: Text('SYNTHETIC_WORKOUT_ROUTE')),
          ),
        ],
      );
      addTearDown(() async {
        router.dispose();
        recreated.dispose();
        await db.close();
      });
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: recreated,
          child: MaterialApp.router(
            theme: AppTheme.dark,
            locale: const Locale('tr'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      Future<void> settle() async {
        for (var i = 0; i < 12; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await settle();
      expect(
        (await recreated.read(
          trainingSetupProfileProvider.future,
        ))!.recommendedProgram!.key,
        program.key,
      );
      final recover = find.widgetWithText(TextButton, l.goalCompleteRoute);
      await tester.scrollUntilVisible(recover, 200);
      await tester.ensureVisible(recover);
      await tester.tap(recover);
      await settle();
      // Imperative push need not reflect in RouteInformationProvider's URL.
      // Assert the actual routed screen and its parsed catalog identifier.
      expect(find.byType(ProgramDetailScreen), findsOneWidget);
      expect(
        tester
            .widget<ProgramDetailScreen>(find.byType(ProgramDetailScreen))
            .programKey,
        program.key,
      );
      await tester.tap(find.text(l.exAddProgram));
      await settle();
      expect(find.text('SYNTHETIC_WORKOUT_ROUTE'), findsOneWidget);
      final installed = (await tester.runAsync(
        () => db.workoutDao.getActiveRoutines(),
      ))!;
      expect(installed, hasLength(program.routines.length));
      expect(installed.map((r) => r.programKey).toSet(), {program.key});
      final originalIds = installed.map((r) => r.id).toSet();
      router.go(AppRoutes.goalJourney);
      await settle();
      await tester.scrollUntilVisible(find.text(l.goalRouteTitle), 200);
      expect(find.text(l.goalCompleteRoute), findsNothing);
      expect(
        (await tester.runAsync(
          () => db.workoutDao.getActiveRoutines(),
        ))!.map((r) => r.id).toSet(),
        originalIds,
        reason: 'recovery view must not reinstall an already installed program',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
