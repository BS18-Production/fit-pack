import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/prefs/week_start_provider.dart';
import '../../../core/utils/current_day.dart';
import '../../../data/providers.dart';
import '../../../data/reactive.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/nutrition_dao.dart';
import '../streak_calc.dart';
import 'weekly_goal_provider.dart';
import '../../../core/utils/weight_trend.dart';

/// Ana Sayfa okuma provider'ları — hepsi **reaktif** (H-05, `watchTables`):
/// dokundukları tablo değişince kendiliğinden tazelenir, elle invalidate yok.

final userProfileProvider = StreamProvider<UserProfileData?>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [
    db.userProfile,
  ], () => ref.read(userProfileDaoProvider).getProfile());
});

final lastWorkoutSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [
    db.workoutSessions,
  ], () => ref.read(workoutDaoProvider).getLastSession());
});

final todayNutritionProvider = StreamProvider<DailyNutrition>((ref) {
  final db = ref.watch(databaseProvider);
  final day = ref.watch(currentDayProvider);
  return watchTables(db, [
    db.foodLogs,
    db.foods,
  ], () => ref.read(nutritionDaoProvider).getDailyTotals(day));
});

final latestWeightProvider = StreamProvider<BodyMeasurement?>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [
    db.bodyMeasurements,
  ], () => ref.read(bodyDaoProvider).getDailyLatestWeight());
});

/// Bugünün su tüketimi (ml). Home su kartı izler.
final todayWaterProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  final day = ref.watch(currentDayProvider);
  return watchTables(db, [
    db.waterIntake,
  ], () => ref.read(nutritionDaoProvider).getWaterForDay(day));
});

/// Ana Sayfa kilo hücresi. [delta]: trend hazırsa **7 günlük trend
/// değişimi** ([isTrend] = true, docs/42 T-4); değilse son iki günün farkı.
typedef WeightTrend = ({double? latest, double? delta, bool isTrend});

final weightTrendProvider = StreamProvider<WeightTrend>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.bodyMeasurements], () async {
    final daily = await ref.read(bodyDaoProvider).getDailyMeasurements();
    final weighted = daily.where((m) => m.weightKg != null).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // yeniden eskiye
    if (weighted.isEmpty) return (latest: null, delta: null, isTrend: false);
    final latest = weighted.first.weightKg;
    final points = [
      for (final m in weighted.reversed) (date: m.date, kg: m.weightKg!),
    ];
    if (trendReady(points)) {
      final change = trendChange(weightTrendSeries(points));
      if (change != null) {
        return (latest: latest, delta: change, isTrend: true);
      }
    }
    final delta = weighted.length > 1 ? latest! - weighted[1].weightKg! : null;
    return (latest: latest, delta: delta, isTrend: false);
  });
});

/// Haftalık hedef docs/52 tek kaynağından; hafta sınırı kullanıcı tercihidir.
final weeklyStreakProvider = StreamProvider<WeeklyStreak>((ref) {
  final db = ref.watch(databaseProvider);
  final goal = ref.watch(weeklyGoalProvider.future);
  final period = ref.watch(currentWeeklyTargetProvider.future);
  final history = ref.watch(weeklyTargetHistoryProvider.future);
  final targetToday = ref.watch(weeklyTargetTodayProvider);
  final weekStart = ref.watch(weekStartProvider);
  ref.watch(currentDayProvider); // hafta dönümü (CR-010)
  return watchTables(db, [db.workoutSessions, db.routines], () async {
    final dao = ref.read(workoutDaoProvider);
    final sessions = await dao.getAllSessions();
    final current = await period;
    final targets = await history;
    return computeWeeklyStreak(
      sessionDates: sessions.map((s) => s.date),
      weeklyGoal: await goal,
      now: DateTime.now(),
      weekStart: weekStart,
      targetKnown: current.targetKnown,
      goalForWeek: (start) {
        final target = resolveWeeklyTargetPeriod(
          periodStart: start,
          currentWeekStart: current.start,
          currentDate: targetToday,
          history: targets,
          legacyCurrentGoal: current.targetDays,
        );
        return target.coversWholePeriod ? target.targetDays : null;
      },
    );
  });
});
