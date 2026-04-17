import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Pre-loaded exercise list for the workout program
final exercisesSeed = <ExercisesCompanion>[
  // === COMPOUND - CHEST ===
  ExercisesCompanion(
    name: Value('Bench Press'),
    category: Value('compound'),
    muscleGroups: Value('["chest", "triceps", "front_delt"]'),
    alternatives: Value('["Dumbbell Bench Press", "Machine Chest Press"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Incline Dumbbell Press'),
    category: Value('compound'),
    muscleGroups: Value('["upper_chest", "triceps", "front_delt"]'),
    alternatives: Value('["Incline Barbell Press", "Incline Machine Press"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Dumbbell Bench Press'),
    category: Value('compound'),
    muscleGroups: Value('["chest", "triceps", "front_delt"]'),
    alternatives: Value('["Bench Press", "Machine Chest Press"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Close Grip Bench'),
    category: Value('compound'),
    muscleGroups: Value('["triceps", "chest"]'),
    alternatives: Value('["Dip"]'),
    isPosture: Value(false),
    isArm: Value(true),
  ),

  // === COMPOUND - BACK ===
  ExercisesCompanion(
    name: Value('Barbell Row'),
    category: Value('compound'),
    muscleGroups: Value('["upper_back", "lats", "biceps", "rear_delt"]'),
    alternatives: Value('["Dumbbell Row", "Cable Row"]'),
    isPosture: Value(true),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Lat Pulldown'),
    category: Value('compound'),
    muscleGroups: Value('["lats", "biceps", "upper_back"]'),
    alternatives: Value('["Pull-up", "Weighted Pull-up"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Cable Row'),
    category: Value('compound'),
    muscleGroups: Value('["upper_back", "lats", "biceps"]'),
    alternatives: Value('["Barbell Row", "Dumbbell Row"]'),
    isPosture: Value(true),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Weighted Pull-up'),
    category: Value('compound'),
    muscleGroups: Value('["lats", "biceps", "upper_back"]'),
    alternatives: Value('["Lat Pulldown"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),

  // === COMPOUND - LEGS ===
  ExercisesCompanion(
    name: Value('Leg Press'),
    category: Value('compound'),
    muscleGroups: Value('["quads", "glutes", "hamstrings"]'),
    alternatives: Value('["Bulgarian Split Squat"]'),
    isPosture: Value(false),
    isArm: Value(false),
    notes: Value('Diz dostu alternatif - squat yerine'),
  ),
  ExercisesCompanion(
    name: Value('Romanian Deadlift'),
    category: Value('compound'),
    muscleGroups: Value('["hamstrings", "glutes", "lower_back"]'),
    alternatives: Value('["Stiff Leg Deadlift"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Bulgarian Split Squat'),
    category: Value('compound'),
    muscleGroups: Value('["quads", "glutes"]'),
    alternatives: Value('["Leg Press", "Walking Lunge"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Hip Thrust'),
    category: Value('compound'),
    muscleGroups: Value('["glutes", "hamstrings"]'),
    alternatives: Value('["Glute Bridge"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Walking Lunge'),
    category: Value('compound'),
    muscleGroups: Value('["quads", "glutes"]'),
    alternatives: Value('["Bulgarian Split Squat"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),

  // === COMPOUND - SHOULDERS ===
  ExercisesCompanion(
    name: Value('Overhead Press'),
    category: Value('compound'),
    muscleGroups: Value('["front_delt", "side_delt", "triceps"]'),
    alternatives: Value('["Arnold Press", "Dumbbell Shoulder Press"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Arnold Press'),
    category: Value('compound'),
    muscleGroups: Value('["front_delt", "side_delt", "triceps"]'),
    alternatives: Value('["Overhead Press"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),

  // === ISOLATION - POSTURE ===
  ExercisesCompanion(
    name: Value('Face Pull'),
    category: Value('isolation'),
    muscleGroups: Value('["rear_delt", "upper_back", "rotator_cuff"]'),
    alternatives: Value('["Band Pull Apart", "Reverse Fly"]'),
    isPosture: Value(true),
    isArm: Value(false),
    notes: Value('Postür için kritik hareket'),
  ),
  ExercisesCompanion(
    name: Value('Reverse Fly'),
    category: Value('isolation'),
    muscleGroups: Value('["rear_delt", "upper_back"]'),
    alternatives: Value('["Face Pull", "Band Pull Apart"]'),
    isPosture: Value(true),
    isArm: Value(false),
    notes: Value('Postür için kritik hareket'),
  ),
  ExercisesCompanion(
    name: Value('Band Pull Apart'),
    category: Value('isolation'),
    muscleGroups: Value('["rear_delt", "upper_back"]'),
    alternatives: Value('["Face Pull", "Reverse Fly"]'),
    isPosture: Value(true),
    isArm: Value(false),
    notes: Value('Postür için kritik hareket'),
  ),

  // === ISOLATION - SHOULDERS ===
  ExercisesCompanion(
    name: Value('Lateral Raise'),
    category: Value('isolation'),
    muscleGroups: Value('["side_delt"]'),
    alternatives: Value('["Cable Lateral Raise"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),

  // === ISOLATION - BICEPS ===
  ExercisesCompanion(
    name: Value('Barbell Curl'),
    category: Value('isolation'),
    muscleGroups: Value('["biceps"]'),
    alternatives: Value('["Dumbbell Curl", "EZ Bar Curl"]'),
    isPosture: Value(false),
    isArm: Value(true),
  ),
  ExercisesCompanion(
    name: Value('Hammer Curl'),
    category: Value('isolation'),
    muscleGroups: Value('["biceps", "brachialis", "forearm"]'),
    alternatives: Value('["Cross Body Hammer Curl"]'),
    isPosture: Value(false),
    isArm: Value(true),
  ),
  ExercisesCompanion(
    name: Value('Preacher Curl'),
    category: Value('isolation'),
    muscleGroups: Value('["biceps"]'),
    alternatives: Value('["Concentration Curl"]'),
    isPosture: Value(false),
    isArm: Value(true),
  ),
  ExercisesCompanion(
    name: Value('Incline Curl'),
    category: Value('isolation'),
    muscleGroups: Value('["biceps"]'),
    alternatives: Value('["Barbell Curl"]'),
    isPosture: Value(false),
    isArm: Value(true),
  ),

  // === ISOLATION - TRICEPS ===
  ExercisesCompanion(
    name: Value('Tricep Pushdown'),
    category: Value('isolation'),
    muscleGroups: Value('["triceps"]'),
    alternatives: Value('["Overhead Tricep Extension"]'),
    isPosture: Value(false),
    isArm: Value(true),
  ),
  ExercisesCompanion(
    name: Value('Overhead Tricep Extension'),
    category: Value('isolation'),
    muscleGroups: Value('["triceps"]'),
    alternatives: Value('["Tricep Pushdown", "Skull Crusher"]'),
    isPosture: Value(false),
    isArm: Value(true),
  ),
  ExercisesCompanion(
    name: Value('Skull Crusher'),
    category: Value('isolation'),
    muscleGroups: Value('["triceps"]'),
    alternatives: Value('["Overhead Tricep Extension"]'),
    isPosture: Value(false),
    isArm: Value(true),
  ),
  ExercisesCompanion(
    name: Value('Dip'),
    category: Value('compound'),
    muscleGroups: Value('["triceps", "chest", "front_delt"]'),
    alternatives: Value('["Close Grip Bench", "Tricep Pushdown"]'),
    isPosture: Value(false),
    isArm: Value(true),
  ),

  // === ISOLATION - FOREARMS ===
  ExercisesCompanion(
    name: Value('Wrist Curl'),
    category: Value('isolation'),
    muscleGroups: Value('["forearm"]'),
    alternatives: Value('["Reverse Wrist Curl"]'),
    isPosture: Value(false),
    isArm: Value(true),
  ),

  // === ISOLATION - LEGS ===
  ExercisesCompanion(
    name: Value('Leg Curl'),
    category: Value('isolation'),
    muscleGroups: Value('["hamstrings"]'),
    alternatives: Value('["Nordic Curl"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Leg Extension'),
    category: Value('isolation'),
    muscleGroups: Value('["quads"]'),
    alternatives: Value(null),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Calf Raise'),
    category: Value('isolation'),
    muscleGroups: Value('["calves"]'),
    alternatives: Value('["Seated Calf Raise"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),

  // === CORE ===
  ExercisesCompanion(
    name: Value('Plank'),
    category: Value('isolation'),
    muscleGroups: Value('["core", "abs"]'),
    alternatives: Value('["Dead Bug"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Ab Wheel'),
    category: Value('isolation'),
    muscleGroups: Value('["abs", "core"]'),
    alternatives: Value('["Plank", "Hanging Leg Raise"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('Hanging Leg Raise'),
    category: Value('isolation'),
    muscleGroups: Value('["abs", "hip_flexors"]'),
    alternatives: Value('["Ab Wheel", "Plank"]'),
    isPosture: Value(false),
    isArm: Value(false),
  ),

  // === CARDIO ===
  ExercisesCompanion(
    name: Value('Yürüyüş / Koşu'),
    category: Value('cardio'),
    muscleGroups: Value('["cardio"]'),
    alternatives: Value(null),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('HIIT'),
    category: Value('cardio'),
    muscleGroups: Value('["cardio"]'),
    alternatives: Value(null),
    isPosture: Value(false),
    isArm: Value(false),
  ),
  ExercisesCompanion(
    name: Value('HIIT (opsiyonel)'),
    category: Value('cardio'),
    muscleGroups: Value('["cardio"]'),
    alternatives: Value(null),
    isPosture: Value(false),
    isArm: Value(false),
  ),
];
