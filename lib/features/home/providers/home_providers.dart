import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/nutrition_dao.dart';

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

/// Simple workout streak: count consecutive days with a workout session
final workoutStreakProvider = FutureProvider<int>((ref) async {
  final dao = ref.watch(workoutDaoProvider);
  final sessions = await dao.getAllSessions();
  if (sessions.isEmpty) return 0;

  int streak = 0;
  var checkDate = DateTime.now();

  // If no session today, start checking from yesterday
  final todayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
  final hasToday = sessions.any((s) =>
      s.date.year == todayStart.year &&
      s.date.month == todayStart.month &&
      s.date.day == todayStart.day);

  if (!hasToday) {
    checkDate = checkDate.subtract(const Duration(days: 1));
  }

  while (true) {
    final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
    final hasSession = sessions.any((s) =>
        s.date.year == dayStart.year &&
        s.date.month == dayStart.month &&
        s.date.day == dayStart.day);

    if (hasSession) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return streak;
});
