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
