import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/prefs/week_start_provider.dart';
import '../../../data/providers.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/nutrition_dao.dart';
import '../../workout/routine_providers.dart';
import '../streak_calc.dart';

final userProfileProvider = FutureProvider<UserProfileData?>((ref) {
  return ref.watch(userProfileDaoProvider).getProfile();
});

final lastWorkoutSessionProvider = FutureProvider<WorkoutSession?>((ref) {
  return ref.watch(workoutDaoProvider).getLastSession();
});

final todayNutritionProvider = FutureProvider<DailyNutrition>((ref) {
  return ref.watch(nutritionDaoProvider).getDailyTotals(DateTime.now());
});

final latestWeightProvider = FutureProvider<BodyMeasurement?>((ref) {
  return ref.watch(bodyDaoProvider).getLatestMeasurement();
});

/// Bugünün su tüketimi (ml). Home su kartı izler.
final todayWaterProvider = FutureProvider<int>((ref) {
  return ref.watch(nutritionDaoProvider).getWaterForDay(DateTime.now());
});

/// Son kilo + bir önceki ölçüme göre değişim (kg). Home "↓0.4" rozeti için.
typedef WeightTrend = ({double? latest, double? delta});

final weightTrendProvider = FutureProvider<WeightTrend>((ref) async {
  final all = await ref.watch(bodyDaoProvider).getAllMeasurements();
  final weighted = all.where((m) => m.weightKg != null).toList()
    ..sort((a, b) => b.date.compareTo(a.date)); // yeniden eskiye
  if (weighted.isEmpty) return (latest: null, delta: null);
  final latest = weighted.first.weightKg;
  final delta =
      weighted.length > 1 ? latest! - weighted[1].weightKg! : null;
  return (latest: latest, delta: delta);
});

/// Haftalık hedef bazlı antrenman serisi (streak_calc). Hedef = planlanmış
/// rutin günü sayısı (benzersiz haftalık gün); plan kurulmamışsa 1 — haftada
/// en az bir antrenman seriyi sürdürür. Hafta sınırı kullanıcının "haftanın
/// ilk günü" tercihine göre.
final weeklyStreakProvider = FutureProvider<WeeklyStreak>((ref) async {
  final sessions = await ref.watch(workoutDaoProvider).getAllSessions();
  final routines = await ref.watch(activeRoutinesProvider.future);
  final weekStart = ref.watch(weekStartProvider);

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
