import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/app_database.dart';
import 'database/daos/workout_dao.dart';
import 'database/daos/nutrition_dao.dart';
import 'database/daos/body_dao.dart';
import 'database/daos/achievement_dao.dart';
import 'database/daos/user_profile_dao.dart';
import 'services/openfoodfacts_service.dart';

/// Single database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// DAOs
final workoutDaoProvider = Provider<WorkoutDao>((ref) {
  return ref.watch(databaseProvider).workoutDao;
});

final nutritionDaoProvider = Provider<NutritionDao>((ref) {
  return ref.watch(databaseProvider).nutritionDao;
});

final bodyDaoProvider = Provider<BodyDao>((ref) {
  return ref.watch(databaseProvider).bodyDao;
});

final achievementDaoProvider = Provider<AchievementDao>((ref) {
  return ref.watch(databaseProvider).achievementDao;
});

final userProfileDaoProvider = Provider<UserProfileDao>((ref) {
  return ref.watch(databaseProvider).userProfileDao;
});

/// OpenFoodFacts (barkod → besin). Beslenme V2 (docs/07-nutrition-v2.md).
final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  final svc = OpenFoodFactsService();
  ref.onDispose(svc.dispose);
  return svc;
});
