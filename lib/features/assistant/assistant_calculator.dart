import '../../data/database/app_database.dart';
import '../../data/database/daos/workout_dao.dart';
import '../home/dashboard_stats.dart';
import '../home/streak_calc.dart';
import '../insights/insight_queries.dart';
import '../insights/insight_rules.dart';
import '../insights/insight_window.dart';
import '../insights/weekly_review.dart';
import 'assistant_contract.dart';

enum AssistantDataStatus {
  ready,
  noData,
  insufficientData,
  noGoal,
  noPlan,
  incompleteDays,
}

enum AssistantDestination { workout, nutrition, progress, exercise }

enum AssistantMetricKey {
  sessions,
  sets,
  minutes,
  volume,
  plannedDays,
  doneDays,
  loggedDays,
  completedDays,
  excludedDays,
  avgKcal,
  avgProtein,
  proteinGoal,
  hitDays,
  measurements,
  firstWeight,
  lastWeight,
  change,
  weeks,
  weeklyGoal,
  remainingKcal,
  remainingProtein,
  firstE1rm,
  lastE1rm,
  portion,
  portionKcal,
  portionProtein,
}

enum AssistantUnit { count, kilograms, kcal, grams, minutes }

class AssistantMetric {
  final AssistantMetricKey key;
  final num? value;
  final AssistantUnit unit;
  const AssistantMetric(
    this.key,
    this.value, [
    this.unit = AssistantUnit.count,
  ]);
}

class AssistantDetail {
  final String name;
  final int? exerciseId;
  final List<AssistantMetric> metrics;
  final List<InsightComment> comments;
  const AssistantDetail(
    this.name,
    this.metrics, {
    this.exerciseId,
    this.comments = const [],
  });
}

class AssistantAnswer {
  final AssistantSelection selection;
  final DateWindow window;
  final AssistantDataStatus status;
  final int records;
  final List<AssistantMetric> metrics;
  final List<AssistantDetail> details;
  final List<InsightComment> comments;
  final AssistantDestination destination;
  final NutritionBasis? nutritionBasis;
  const AssistantAnswer({
    required this.selection,
    required this.window,
    required this.status,
    required this.records,
    required this.metrics,
    this.details = const [],
    this.comments = const [],
    required this.destination,
    this.nutritionBasis,
  });
}

class AssistantData {
  final DateTime now;
  final int weekStart;
  final List<WorkoutSession> sessions;
  final Map<int, List<WorkoutSet>> sets;
  final Map<int, Exercise> exercises;
  final List<ExerciseProgressPoint> points;
  final List<FoodLog> logs;
  final Set<DateTime> completedDays;
  final Map<int, Food> foods;
  final List<BodyMeasurement> measurements;
  final Set<int> scheduledWeekdays;
  final UserProfileData? profile;
  const AssistantData({
    required this.now,
    this.weekStart = DateTime.monday,
    this.sessions = const [],
    this.sets = const {},
    this.exercises = const {},
    this.points = const [],
    this.logs = const [],
    this.completedDays = const {},
    this.foods = const {},
    this.measurements = const [],
    this.scheduledWeekdays = const {},
    this.profile,
  });
}

AssistantAnswer calculateAssistant(AssistantSelection s, AssistantData d) {
  if (!s.query.periods.contains(s.period)) {
    throw ArgumentError('Unsupported period');
  }
  final w = windowFor(s.period, d.now, weekStart: d.weekStart);
  final sessions = d.sessions.where((v) => w.contains(v.date)).toList();
  final sets = [for (final v in sessions) ...d.sets[v.id] ?? <WorkoutSet>[]];
  final completeSets = sets.where((v) => v.isComplete && !v.isWarmup).toList();
  final points = d.points.where((v) => w.contains(v.date)).toList();
  final weights =
      d.measurements
          .where((v) => v.weightKg != null && w.contains(v.date))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  final latestWeights =
      d.measurements
          .where((v) => v.weightKg != null && v.date.isBefore(w.end))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  final nutrition = nutritionStats(
    window: w,
    logs: d.logs,
    completedDays: d.completedDays,
    kcalGoal: d.profile?.kcalGoal ?? 0,
    proteinGoal: d.profile?.proteinGoal ?? 0,
  );
  AssistantAnswer answer(
    List<AssistantMetric> metrics,
    int records,
    AssistantDestination target, {
    AssistantDataStatus? status,
    List<AssistantDetail> details = const [],
    List<InsightComment> comments = const [],
    NutritionBasis? basis,
  }) => AssistantAnswer(
    selection: s,
    window: w,
    status:
        status ??
        (records == 0 ? AssistantDataStatus.noData : AssistantDataStatus.ready),
    records: records,
    metrics: metrics,
    details: details,
    comments: s.interpretation ? comments : const [],
    destination: target,
    nutritionBasis: basis,
  );
  switch (s.query) {
    case AssistantQuery.workoutSummary:
      final agg = aggregateWorkouts(
        sessions: sessions,
        setsBySession: d.sets,
        bodyWeightKg: latestWeights.firstOrNull?.weightKg,
      );
      return answer(
        [
          AssistantMetric(AssistantMetricKey.sessions, agg.sessions),
          AssistantMetric(AssistantMetricKey.sets, completeSets.length),
          AssistantMetric(
            AssistantMetricKey.minutes,
            sessions.fold<int>(0, (n, v) => n + (v.durationMin ?? 0)),
            AssistantUnit.minutes,
          ),
          AssistantMetric(
            AssistantMetricKey.volume,
            agg.volumeKg,
            AssistantUnit.kilograms,
          ),
        ],
        sessions.length,
        AssistantDestination.workout,
        comments: interpretWorkoutWeek(
          weekStart: w.start!,
          now: d.now,
          sessions: d.sessions,
          setsBySession: d.sets,
        ).values.toList(),
      );
    case AssistantQuery.planAdherence:
      final done = sessions
          .map((v) => dayOf(v.date))
          .toSet()
          .where((v) => d.scheduledWeekdays.contains(v.weekday))
          .length;
      return answer(
        [
          AssistantMetric(AssistantMetricKey.doneDays, done),
          AssistantMetric(
            AssistantMetricKey.plannedDays,
            d.scheduledWeekdays.length,
          ),
        ],
        sessions.length,
        AssistantDestination.workout,
        status: d.scheduledWeekdays.isEmpty ? AssistantDataStatus.noPlan : null,
      );
    case AssistantQuery.nutritionSummary:
    case AssistantQuery.proteinGoal:
      return answer(
        [
          AssistantMetric(AssistantMetricKey.loggedDays, nutrition.loggedDays),
          AssistantMetric(
            AssistantMetricKey.completedDays,
            nutrition.completedDays,
          ),
          AssistantMetric(
            AssistantMetricKey.excludedDays,
            nutrition.excludedLoggedDays,
          ),
          AssistantMetric(
            AssistantMetricKey.avgKcal,
            nutrition.avgKcal,
            AssistantUnit.kcal,
          ),
          AssistantMetric(
            AssistantMetricKey.avgProtein,
            nutrition.avgProtein,
            AssistantUnit.grams,
          ),
          if (s.query == AssistantQuery.proteinGoal) ...[
            AssistantMetric(
              AssistantMetricKey.proteinGoal,
              nutrition.proteinGoal > 0 ? nutrition.proteinGoal : null,
              AssistantUnit.grams,
            ),
            AssistantMetric(
              AssistantMetricKey.hitDays,
              nutrition.completedProteinGoalDays,
            ),
          ],
        ],
        d.logs.where((v) => w.contains(v.date)).length,
        AssistantDestination.nutrition,
        status: nutrition.knownDays == 0
            ? AssistantDataStatus.noData
            : s.query == AssistantQuery.proteinGoal &&
                  nutrition.proteinGoal == 0
            ? AssistantDataStatus.noGoal
            : s.query == AssistantQuery.proteinGoal &&
                  nutrition.completedDays == 0
            ? AssistantDataStatus.incompleteDays
            : AssistantDataStatus.ready,
        basis: nutrition.basis,
        comments: interpretNutrition(
          nutrition,
          bodyWeightKg: latestWeights.firstOrNull?.weightKg,
          bodyWeightDate: latestWeights.firstOrNull?.date,
          windowComplete: w.isComplete,
        ),
      );
    case AssistantQuery.weightTrend:
      final span = weights.isEmpty
          ? 0
          : calendarDaysBetween(weights.first.date, weights.last.date);
      return answer(
        [
          AssistantMetric(AssistantMetricKey.measurements, weights.length),
          AssistantMetric(
            AssistantMetricKey.firstWeight,
            weights.firstOrNull?.weightKg,
            AssistantUnit.kilograms,
          ),
          AssistantMetric(
            AssistantMetricKey.lastWeight,
            weights.lastOrNull?.weightKg,
            AssistantUnit.kilograms,
          ),
          AssistantMetric(
            AssistantMetricKey.change,
            weights.length >= 2
                ? weights.last.weightKg! - weights.first.weightKg!
                : null,
            AssistantUnit.kilograms,
          ),
        ],
        weights.length,
        AssistantDestination.progress,
        status: weights.isEmpty
            ? AssistantDataStatus.noData
            : weights.length < 2 || span < kWeightMinSpanDays
            ? AssistantDataStatus.insufficientData
            : AssistantDataStatus.ready,
        comments: [
          interpretWeightTrend(
            window: w,
            measurements: weights,
            direction: GoalDirection.tryParse(d.profile?.goalDirection),
            directionSince: d.profile?.goalDirectionSince,
          ),
        ],
      );
    case AssistantQuery.strengthProgress:
    case AssistantQuery.exerciseHistory:
      final ids = s.query == AssistantQuery.exerciseHistory
          ? {if (s.exerciseId != null) s.exerciseId!}
          : points.map((v) => v.exerciseId).toSet();
      final details = <AssistantDetail>[];
      for (final id in ids.toList()..sort()) {
        final ps = points.where((v) => v.exerciseId == id).toList();
        final byDay = <DateTime, double>{};
        for (final p in ps) {
          final e = p.e1rm;
          if (e != null && e > (byDay[dayOf(p.date)] ?? 0)) {
            byDay[dayOf(p.date)] = e;
          }
        }
        final days = byDay.keys.toList()..sort();
        details.add(
          AssistantDetail(
            d.exercises[id]?.name ?? ps.firstOrNull?.name ?? '',
            [
              AssistantMetric(
                AssistantMetricKey.firstE1rm,
                days.isEmpty ? null : byDay[days.first],
                AssistantUnit.kilograms,
              ),
              AssistantMetric(
                AssistantMetricKey.lastE1rm,
                days.isEmpty ? null : byDay[days.last],
                AssistantUnit.kilograms,
              ),
              AssistantMetric(
                AssistantMetricKey.change,
                days.length >= 2
                    ? byDay[days.last]! - byDay[days.first]!
                    : null,
                AssistantUnit.kilograms,
              ),
            ],
            exerciseId: id,
            comments: s.interpretation
                ? [interpretStrengthTrend(ps, weekStart: d.weekStart)]
                : const [],
          ),
        );
      }
      final records = points.where((v) => ids.contains(v.exerciseId)).length;
      return answer(
        [],
        records,
        s.query == AssistantQuery.exerciseHistory
            ? AssistantDestination.exercise
            : AssistantDestination.workout,
        details: details,
        status: records == 0
            ? AssistantDataStatus.noData
            : details.every((v) => v.metrics.last.value == null)
            ? AssistantDataStatus.insufficientData
            : AssistantDataStatus.ready,
      );
    case AssistantQuery.muscleBalance:
      final muscles = countMuscleSets(
        sessions: sessions,
        setsBySession: d.sets,
        exercises: d.exercises,
      );
      return answer(
        [],
        completeSets.length,
        AssistantDestination.workout,
        details: [
          for (final e in muscles.entries)
            AssistantDetail(
              e.key,
              [AssistantMetric(AssistantMetricKey.sets, e.value)],
              comments: s.interpretation
                  ? [
                      interpretMuscleSets(
                        muscle: e.key,
                        sets: e.value,
                        weekComplete: w.isComplete,
                      ),
                    ]
                  : const [],
            ),
        ],
      );
    case AssistantQuery.topExercises:
      final top = topExercises(
        window: w,
        sessions: sessions,
        setsBySession: d.sets,
        exercises: d.exercises,
      );
      return answer(
        [],
        completeSets.length,
        AssistantDestination.workout,
        details: [
          for (final e in top)
            AssistantDetail(e.name ?? '', [
              AssistantMetric(AssistantMetricKey.sets, e.sets),
              AssistantMetric(AssistantMetricKey.sessions, e.sessions),
            ], exerciseId: e.exerciseId),
        ],
      );
    case AssistantQuery.streak:
      final streak = computeWeeklyStreak(
        sessionDates: d.sessions.map((v) => v.date),
        weeklyGoal: d.scheduledWeekdays.length,
        now: d.now,
        weekStart: d.weekStart,
      );
      return answer(
        [
          AssistantMetric(AssistantMetricKey.weeks, streak.weeks),
          AssistantMetric(AssistantMetricKey.weeklyGoal, streak.weeklyGoal),
        ],
        d.sessions.length,
        AssistantDestination.workout,
      );
    case AssistantQuery.todayRemaining:
      final r = computeTodayRemaining(
        now: d.now,
        logs: d.logs,
        kcalGoal: d.profile?.kcalGoal ?? 0,
        proteinGoal: d.profile?.proteinGoal ?? 0,
        mealType: s.mealType,
      );
      return answer(
        [
          AssistantMetric(
            AssistantMetricKey.remainingKcal,
            r.remainingKcal,
            AssistantUnit.kcal,
          ),
          AssistantMetric(
            AssistantMetricKey.remainingProtein,
            r.remainingProtein,
            AssistantUnit.grams,
          ),
        ],
        d.logs.where((v) => w.contains(v.date)).length,
        AssistantDestination.nutrition,
        status: r.remainingKcal == null && r.remainingProtein == null
            ? AssistantDataStatus.noGoal
            : AssistantDataStatus.ready,
        comments: [interpretTodayRemaining(r)],
        details: s.mealType == null
            ? const []
            : [
                for (final v in r.suggestions)
                  AssistantDetail(d.foods[v.foodId]?.name ?? '', [
                    AssistantMetric(
                      AssistantMetricKey.portion,
                      v.grams,
                      AssistantUnit.grams,
                    ),
                    AssistantMetric(
                      AssistantMetricKey.portionKcal,
                      v.kcal,
                      AssistantUnit.kcal,
                    ),
                    AssistantMetric(
                      AssistantMetricKey.portionProtein,
                      v.protein,
                      AssistantUnit.grams,
                    ),
                  ]),
              ],
      );
    case AssistantQuery.outOfScope:
      throw ArgumentError('No calculation for out_of_scope');
  }
}
