import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/prefs/week_start_provider.dart';
import '../../../data/providers.dart';
import '../../../data/reactive.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/nutrition_dao.dart';
import '../streak_calc.dart';
import '../../../core/utils/weight_trend.dart';

/// Ana Sayfa okuma provider'ları — hepsi **reaktif** (H-05, `watchTables`):
/// dokundukları tablo değişince kendiliğinden tazelenir, elle invalidate yok.

final userProfileProvider = StreamProvider<UserProfileData?>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.userProfile],
      () => ref.read(userProfileDaoProvider).getProfile());
});

final lastWorkoutSessionProvider = StreamProvider<WorkoutSession?>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.workoutSessions],
      () => ref.read(workoutDaoProvider).getLastSession());
});

final todayNutritionProvider = StreamProvider<DailyNutrition>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.foodLogs, db.foods],
      () => ref.read(nutritionDaoProvider).getDailyTotals(DateTime.now()));
});

final latestWeightProvider = StreamProvider<BodyMeasurement?>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.bodyMeasurements],
      () => ref.read(bodyDaoProvider).getDailyLatestWeight());
});

/// Bugünün su tüketimi (ml). Home su kartı izler.
final todayWaterProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.waterIntake],
      () => ref.read(nutritionDaoProvider).getWaterForDay(DateTime.now()));
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
    final delta =
        weighted.length > 1 ? latest! - weighted[1].weightKg! : null;
    return (latest: latest, delta: delta, isTrend: false);
  });
});

/// Haftalık hedef bazlı antrenman serisi (streak_calc). Hedef = planlanmış
/// rutin günü sayısı (benzersiz haftalık gün); plan kurulmamışsa 1 — haftada
/// en az bir antrenman seriyi sürdürür. Hafta sınırı kullanıcının "haftanın
/// ilk günü" tercihine göre.
final weeklyStreakProvider = StreamProvider<WeeklyStreak>((ref) {
  final db = ref.watch(databaseProvider);
  final weekStart = ref.watch(weekStartProvider);
  return watchTables(db, [db.workoutSessions, db.routines], () async {
    final dao = ref.read(workoutDaoProvider);
    final sessions = await dao.getAllSessions();
    final routines = await dao.getActiveRoutines();

    final scheduledDays = routines
        .where((r) => r.scheduledWeekday != null)
        .map((r) => r.scheduledWeekday!)
        .toSet()
        .length;

    return computeWeeklyStreak(
      sessionDates: sessions.map((s) => s.date),
      weeklyGoal: scheduledDays == 0 ? 1 : scheduledDays,
      now: DateTime.now(),
      weekStart: weekStart,
    );
  });
});
