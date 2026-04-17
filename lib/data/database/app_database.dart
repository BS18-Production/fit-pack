import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/workout_tables.dart';
import 'tables/nutrition_tables.dart';
import 'tables/body_tables.dart';
import 'tables/achievement_tables.dart';
import 'daos/workout_dao.dart';
import 'daos/nutrition_dao.dart';
import 'daos/body_dao.dart';
import 'daos/achievement_dao.dart';
import 'daos/user_profile_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    WorkoutSessions,
    WorkoutSets,
    Foods,
    FoodLogs,
    RecipeItems,
    BodyMeasurements,
    ProgressPhotos,
    Achievements,
    UserProfile,
  ],
  daos: [
    WorkoutDao,
    NutritionDao,
    BodyDao,
    AchievementDao,
    UserProfileDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fit_pack.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
