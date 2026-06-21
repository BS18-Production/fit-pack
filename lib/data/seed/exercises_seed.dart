import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Antrenman V2 hareket kütüphanesi (docs/09-workout-v2.md, docs/08-design-brief.md).
/// İngilizce adlar (salon standardı), arayüz Türkçe. Genel kitle ürünü —
/// kişisel/programa özgü hareket yok.
///
/// Kategoriler: compound, isolation, calisthenics, cardio, flexibility
/// Ekipman: barbell, dumbbell, machine, cable, smith, bodyweight, cardio, none
/// Ölçüm tipi: weight_reps, reps, time, distance
/// primaryMuscle: chest, back, shoulders, biceps, triceps, legs, glutes, core, calves, full_body
class ExerciseSeedData {
  final String name;
  final String category;
  final String primaryMuscle;
  final String equipment;
  final String measurement;
  final List<String> muscles;
  const ExerciseSeedData(this.name, this.category, this.primaryMuscle,
      this.equipment, this.measurement, this.muscles);
}

const _c = 'compound', _iso = 'isolation', _cal = 'calisthenics';
const _car = 'cardio', _flex = 'flexibility';
const _wr = 'weight_reps', _rp = 'reps', _tm = 'time', _ds = 'distance';

const exerciseSeedData = <ExerciseSeedData>[
  // ───────────────────────── COMPOUND ─────────────────────────
  ExerciseSeedData('Barbell Back Squat', _c, 'legs', 'barbell', _wr, ['quads', 'glutes', 'core']),
  ExerciseSeedData('Front Squat', _c, 'legs', 'barbell', _wr, ['quads', 'core']),
  ExerciseSeedData('Conventional Deadlift', _c, 'back', 'barbell', _wr, ['back', 'glutes', 'hamstrings']),
  ExerciseSeedData('Romanian Deadlift', _c, 'legs', 'barbell', _wr, ['hamstrings', 'glutes']),
  ExerciseSeedData('Sumo Deadlift', _c, 'legs', 'barbell', _wr, ['glutes', 'hamstrings', 'back']),
  ExerciseSeedData('Barbell Bench Press', _c, 'chest', 'barbell', _wr, ['chest', 'triceps', 'front_delt']),
  ExerciseSeedData('Incline Barbell Bench Press', _c, 'chest', 'barbell', _wr, ['upper_chest', 'triceps', 'front_delt']),
  ExerciseSeedData('Overhead Press', _c, 'shoulders', 'barbell', _wr, ['shoulders', 'triceps']),
  ExerciseSeedData('Push Press', _c, 'shoulders', 'barbell', _wr, ['shoulders', 'triceps', 'legs']),
  ExerciseSeedData('Bent-Over Barbell Row', _c, 'back', 'barbell', _wr, ['back', 'biceps']),
  ExerciseSeedData('Pendlay Row', _c, 'back', 'barbell', _wr, ['back', 'biceps']),
  ExerciseSeedData('T-Bar Row', _c, 'back', 'machine', _wr, ['back', 'biceps']),
  ExerciseSeedData('Dumbbell Bench Press', _c, 'chest', 'dumbbell', _wr, ['chest', 'triceps', 'front_delt']),
  ExerciseSeedData('Incline Dumbbell Press', _c, 'chest', 'dumbbell', _wr, ['upper_chest', 'triceps', 'front_delt']),
  ExerciseSeedData('Dumbbell Shoulder Press', _c, 'shoulders', 'dumbbell', _wr, ['shoulders', 'triceps']),
  ExerciseSeedData('Dumbbell Row', _c, 'back', 'dumbbell', _wr, ['back', 'biceps']),
  ExerciseSeedData('Leg Press', _c, 'legs', 'machine', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Hack Squat', _c, 'legs', 'machine', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Lat Pulldown', _c, 'back', 'cable', _wr, ['back', 'biceps']),
  ExerciseSeedData('Seated Cable Row', _c, 'back', 'cable', _wr, ['back', 'biceps']),
  ExerciseSeedData('Chest Press Machine', _c, 'chest', 'machine', _wr, ['chest', 'triceps']),
  ExerciseSeedData('Smith Machine Squat', _c, 'legs', 'smith', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Smith Machine Bench Press', _c, 'chest', 'smith', _wr, ['chest', 'triceps']),
  ExerciseSeedData('Bulgarian Split Squat', _c, 'legs', 'dumbbell', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Walking Lunge', _c, 'legs', 'dumbbell', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Goblet Squat', _c, 'legs', 'dumbbell', _wr, ['quads', 'glutes']),

  // ───────────────────────── ISOLATION ─────────────────────────
  ExerciseSeedData('Dumbbell Bicep Curl', _iso, 'biceps', 'dumbbell', _wr, ['biceps']),
  ExerciseSeedData('Barbell Curl', _iso, 'biceps', 'barbell', _wr, ['biceps']),
  ExerciseSeedData('Hammer Curl', _iso, 'biceps', 'dumbbell', _wr, ['biceps', 'forearms']),
  ExerciseSeedData('Preacher Curl', _iso, 'biceps', 'machine', _wr, ['biceps']),
  ExerciseSeedData('Cable Curl', _iso, 'biceps', 'cable', _wr, ['biceps']),
  ExerciseSeedData('Concentration Curl', _iso, 'biceps', 'dumbbell', _wr, ['biceps']),
  ExerciseSeedData('Tricep Pushdown', _iso, 'triceps', 'cable', _wr, ['triceps']),
  ExerciseSeedData('Overhead Tricep Extension', _iso, 'triceps', 'cable', _wr, ['triceps']),
  ExerciseSeedData('Skull Crushers', _iso, 'triceps', 'barbell', _wr, ['triceps']),
  ExerciseSeedData('Tricep Kickback', _iso, 'triceps', 'dumbbell', _wr, ['triceps']),
  ExerciseSeedData('Dumbbell Lateral Raise', _iso, 'shoulders', 'dumbbell', _wr, ['side_delt']),
  ExerciseSeedData('Front Raise', _iso, 'shoulders', 'dumbbell', _wr, ['front_delt']),
  ExerciseSeedData('Rear Delt Fly', _iso, 'shoulders', 'dumbbell', _wr, ['rear_delt']),
  ExerciseSeedData('Cable Lateral Raise', _iso, 'shoulders', 'cable', _wr, ['side_delt']),
  ExerciseSeedData('Dumbbell Chest Fly', _iso, 'chest', 'dumbbell', _wr, ['chest']),
  ExerciseSeedData('Pec Deck', _iso, 'chest', 'machine', _wr, ['chest']),
  ExerciseSeedData('Cable Crossover', _iso, 'chest', 'cable', _wr, ['chest']),
  ExerciseSeedData('Leg Extension', _iso, 'legs', 'machine', _wr, ['quads']),
  ExerciseSeedData('Lying Leg Curl', _iso, 'legs', 'machine', _wr, ['hamstrings']),
  ExerciseSeedData('Seated Leg Curl', _iso, 'legs', 'machine', _wr, ['hamstrings']),
  ExerciseSeedData('Standing Calf Raise', _iso, 'calves', 'machine', _wr, ['calves']),
  ExerciseSeedData('Seated Calf Raise', _iso, 'calves', 'machine', _wr, ['calves']),
  ExerciseSeedData('Hip Thrust', _iso, 'glutes', 'barbell', _wr, ['glutes']),
  ExerciseSeedData('Cable Glute Kickback', _iso, 'glutes', 'cable', _wr, ['glutes']),
  ExerciseSeedData('Dumbbell Shrug', _iso, 'back', 'dumbbell', _wr, ['traps']),
  ExerciseSeedData('Cable Pullover', _iso, 'back', 'cable', _wr, ['back', 'chest']),
  ExerciseSeedData('Reverse Pec Deck', _iso, 'shoulders', 'machine', _wr, ['rear_delt']),

  // ───────────────────────── CALISTHENICS ─────────────────────────
  ExerciseSeedData('Push-Up', _cal, 'chest', 'bodyweight', _rp, ['chest', 'triceps', 'core']),
  ExerciseSeedData('Pull-Up', _cal, 'back', 'bodyweight', _rp, ['back', 'biceps']),
  ExerciseSeedData('Chin-Up', _cal, 'back', 'bodyweight', _rp, ['back', 'biceps']),
  ExerciseSeedData('Parallel Bar Dips', _cal, 'chest', 'bodyweight', _rp, ['chest', 'triceps']),
  ExerciseSeedData('Bodyweight Squat', _cal, 'legs', 'bodyweight', _rp, ['quads', 'glutes']),
  ExerciseSeedData('Pistol Squat', _cal, 'legs', 'bodyweight', _rp, ['quads', 'glutes']),
  ExerciseSeedData('Bodyweight Lunge', _cal, 'legs', 'bodyweight', _rp, ['quads', 'glutes']),
  ExerciseSeedData('Plank', _cal, 'core', 'bodyweight', _tm, ['core']),
  ExerciseSeedData('Side Plank', _cal, 'core', 'bodyweight', _tm, ['core', 'obliques']),
  ExerciseSeedData('Hanging Leg Raise', _cal, 'core', 'bodyweight', _rp, ['core']),
  ExerciseSeedData('Knee Raise', _cal, 'core', 'bodyweight', _rp, ['core']),
  ExerciseSeedData('Mountain Climbers', _cal, 'core', 'bodyweight', _tm, ['core', 'cardio']),
  ExerciseSeedData('Burpees', _cal, 'full_body', 'bodyweight', _rp, ['full_body']),
  ExerciseSeedData('Muscle-Up', _cal, 'back', 'bodyweight', _rp, ['back', 'chest', 'triceps']),
  ExerciseSeedData('Inverted Row', _cal, 'back', 'bodyweight', _rp, ['back', 'biceps']),
  ExerciseSeedData('Pike Push-Up', _cal, 'shoulders', 'bodyweight', _rp, ['shoulders', 'triceps']),
  ExerciseSeedData('Handstand Push-Up', _cal, 'shoulders', 'bodyweight', _rp, ['shoulders', 'triceps']),
  ExerciseSeedData('L-Sit', _cal, 'core', 'bodyweight', _tm, ['core']),
  ExerciseSeedData('Crunch', _cal, 'core', 'bodyweight', _rp, ['core']),
  ExerciseSeedData('Sit-Up', _cal, 'core', 'bodyweight', _rp, ['core']),
  ExerciseSeedData('Russian Twist', _cal, 'core', 'bodyweight', _rp, ['obliques', 'core']),
  ExerciseSeedData('Glute Bridge', _cal, 'glutes', 'bodyweight', _rp, ['glutes']),
  ExerciseSeedData('Superman', _cal, 'back', 'bodyweight', _tm, ['lower_back']),
  ExerciseSeedData('Nordic Hamstring Curl', _cal, 'legs', 'bodyweight', _rp, ['hamstrings']),

  // ───────────────────────── CARDIO ─────────────────────────
  ExerciseSeedData('Treadmill Running', _car, 'full_body', 'cardio', _tm, ['cardio']),
  ExerciseSeedData('Incline Treadmill Walk', _car, 'full_body', 'cardio', _tm, ['cardio', 'glutes']),
  ExerciseSeedData('Stationary Bike', _car, 'legs', 'cardio', _tm, ['cardio', 'legs']),
  ExerciseSeedData('Spin Bike', _car, 'legs', 'cardio', _tm, ['cardio', 'legs']),
  ExerciseSeedData('Elliptical', _car, 'full_body', 'cardio', _tm, ['cardio']),
  ExerciseSeedData('Rowing Machine', _car, 'full_body', 'cardio', _tm, ['cardio', 'back']),
  ExerciseSeedData('Stair Climber', _car, 'legs', 'cardio', _tm, ['cardio', 'legs']),
  ExerciseSeedData('Jump Rope', _car, 'full_body', 'none', _tm, ['cardio', 'calves']),
  ExerciseSeedData('Assault Bike', _car, 'full_body', 'cardio', _tm, ['cardio']),
  ExerciseSeedData('Outdoor Running', _car, 'full_body', 'none', _ds, ['cardio']),
  ExerciseSeedData('Outdoor Cycling', _car, 'legs', 'none', _ds, ['cardio', 'legs']),
  ExerciseSeedData('Swimming', _car, 'full_body', 'none', _ds, ['cardio', 'full_body']),
  ExerciseSeedData('SkiErg', _car, 'full_body', 'cardio', _tm, ['cardio', 'back']),
  ExerciseSeedData('HIIT Intervals', _car, 'full_body', 'none', _tm, ['cardio']),

  // ───────────────────────── FLEXIBILITY ─────────────────────────
  ExerciseSeedData('Static Hamstring Stretch', _flex, 'legs', 'bodyweight', _tm, ['hamstrings']),
  ExerciseSeedData('Hip Flexor Stretch', _flex, 'legs', 'bodyweight', _tm, ['hip_flexors']),
  ExerciseSeedData('Shoulder Stretch', _flex, 'shoulders', 'bodyweight', _tm, ['shoulders']),
  ExerciseSeedData('Foam Rolling', _flex, 'full_body', 'none', _tm, ['full_body']),
  ExerciseSeedData('Cat-Cow Stretch', _flex, 'core', 'bodyweight', _tm, ['spine', 'core']),
  ExerciseSeedData('Pigeon Pose', _flex, 'glutes', 'bodyweight', _tm, ['glutes', 'hip_flexors']),
  ExerciseSeedData('Couch Stretch', _flex, 'legs', 'bodyweight', _tm, ['quads', 'hip_flexors']),
  ExerciseSeedData('Thoracic Rotation', _flex, 'core', 'bodyweight', _tm, ['spine']),
  ExerciseSeedData('Dynamic Warm-Up', _flex, 'full_body', 'bodyweight', _tm, ['full_body']),
  ExerciseSeedData("World's Greatest Stretch", _flex, 'full_body', 'bodyweight', _tm, ['full_body']),
  ExerciseSeedData('Yoga Flow', _flex, 'full_body', 'bodyweight', _tm, ['full_body']),
];

/// Seed → Drift companion'ları (yalnız boş kurulumda yazılır).
final exercisesSeed = exerciseSeedData
    .map((e) => ExercisesCompanion(
          name: Value(e.name),
          category: Value(e.category),
          muscleGroups: Value(jsonEncode(e.muscles)),
          primaryMuscle: Value(e.primaryMuscle),
          equipment: Value(e.equipment),
          measurementType: Value(e.measurement),
          isCustom: const Value(false),
        ))
    .toList();
