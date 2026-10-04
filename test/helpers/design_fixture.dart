import 'package:drift/drift.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';

/// Yalnız test/önizleme için. Üretim kapısı, disk ve bulut hesabı kullanılmaz.
class DesignFixtureGate extends AuthGate {
  DesignFixtureGate(super.db);
  @override
  bool get signedIn => true;
  @override
  bool get onboarded => true;
}

Future<void> seedDesignFixture(AppDatabase db) async {
  final now = DateTime.now();
  await db.userProfileDao.completeOnboarding(
    kcalGoal: 2400,
    proteinGoal: 160,
    phase: 0,
    heightCm: 180,
    goalWeightKg: 80,
    gender: 'male',
    activityLevel: 'moderate',
  );
  final exercise = await db
      .into(db.exercises)
      .insert(
        ExercisesCompanion.insert(
          name: 'Bench Press',
          category: 'compound',
          muscleGroups: '["chest"]',
          primaryMuscle: const Value('chest'),
          equipment: const Value('barbell'),
        ),
      );
  final routine = await db
      .into(db.routines)
      .insert(
        RoutinesCompanion.insert(
          name: 'Üst Vücut A',
          createdAt: now,
          scheduledWeekday: Value(now.weekday),
        ),
      );
  await db
      .into(db.routineExercises)
      .insert(
        RoutineExercisesCompanion.insert(
          routineId: routine,
          exerciseId: exercise,
          targetSets: const Value(3),
          targetRepsMin: const Value(8),
          targetRepsMax: const Value(12),
          targetRestSec: const Value(90),
        ),
      );
  for (final offset in [18, 12, 6, 4, 2, 0]) {
    final date = DateTime(now.year, now.month, now.day - offset, 10);
    await db
        .into(db.bodyMeasurements)
        .insert(
          BodyMeasurementsCompanion.insert(
            date: date,
            weightKg: Value(82 + offset / 20),
            waistCm: const Value(84),
          ),
        );
    final session = await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            date: date,
            phase: 0,
            workoutType: 'Üst Vücut A',
            durationMin: Value(35 + offset),
            routineId: Value(routine),
          ),
        );
    await db
        .into(db.workoutSets)
        .insert(
          WorkoutSetsCompanion.insert(
            sessionId: session,
            exerciseId: exercise,
            setNumber: 1,
            weightKg: Value(70 - offset / 2),
            reps: const Value(10),
            isComplete: const Value(true),
            rpe: const Value(8),
          ),
        );
  }
  final food = await db
      .into(db.foods)
      .insert(
        FoodsCompanion.insert(
          name: 'Yoğurt',
          kcalPer100g: 65,
          proteinPer100g: 4,
          carbPer100g: 5,
          fatPer100g: 3,
        ),
      );
  await db
      .into(db.foodLogs)
      .insert(
        FoodLogsCompanion.insert(
          date: now,
          mealType: 'breakfast',
          foodId: food,
          grams: 200,
          computedKcal: 130,
          computedProtein: 8,
          computedCarb: 10,
          computedFat: 6,
        ),
      );
  await db.nutritionDao.addWater(now, 750);
}
