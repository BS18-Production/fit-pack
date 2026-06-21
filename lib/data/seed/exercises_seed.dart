import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Antrenman V2 hareket kütüphanesi (docs/09-workout-v2.md, docs/08-design-brief.md).
/// İngilizce adlar (salon standardı), arayüz Türkçe. Genel kitle ürünü —
/// kişisel/programa özgü hareket yok.
///
/// Kapsam: Türkiye'deki büyük zincir salonlarda (özellikle MacFit) bulunan
/// makine + serbest ağırlık + kablo + kalistenik hareketler. Kullanıcı
/// aradığı makineyi hazır bulsun, kendi eklemek zorunda kalmasın.
///
/// Kategoriler: compound, isolation, calisthenics, cardio, flexibility
/// Ekipman: barbell, dumbbell, machine, cable, smith, kettlebell, bodyweight,
///          cardio (kardiyo makinesi), none (ekipmansız)
/// Ölçüm tipi: weight_reps, reps, time, distance
/// primaryMuscle: chest, back, shoulders, biceps, triceps, legs, glutes, core,
///                calves, full_body (kas filtresi bu 10 değere göre çalışır)
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
  // ═══════════════════════════ COMPOUND ═══════════════════════════

  // ── Bacak (barbell / serbest) ──
  ExerciseSeedData('Barbell Back Squat', _c, 'legs', 'barbell', _wr, ['quads', 'glutes', 'core']),
  ExerciseSeedData('Front Squat', _c, 'legs', 'barbell', _wr, ['quads', 'core']),
  ExerciseSeedData('Conventional Deadlift', _c, 'back', 'barbell', _wr, ['back', 'glutes', 'hamstrings']),
  ExerciseSeedData('Romanian Deadlift', _c, 'legs', 'barbell', _wr, ['hamstrings', 'glutes']),
  ExerciseSeedData('Sumo Deadlift', _c, 'legs', 'barbell', _wr, ['glutes', 'hamstrings', 'back']),
  ExerciseSeedData('Trap Bar Deadlift', _c, 'legs', 'barbell', _wr, ['glutes', 'quads', 'back']),
  ExerciseSeedData('Good Morning', _c, 'legs', 'barbell', _wr, ['hamstrings', 'lower_back']),
  ExerciseSeedData('Bulgarian Split Squat', _c, 'legs', 'dumbbell', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Walking Lunge', _c, 'legs', 'dumbbell', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Reverse Lunge', _c, 'legs', 'dumbbell', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Dumbbell Step-Up', _c, 'legs', 'dumbbell', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Goblet Squat', _c, 'legs', 'dumbbell', _wr, ['quads', 'glutes']),

  // ── Bacak (makine) ──
  ExerciseSeedData('Leg Press', _c, 'legs', 'machine', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Single-Leg Press', _c, 'legs', 'machine', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Hack Squat', _c, 'legs', 'machine', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Pendulum Squat', _c, 'legs', 'machine', _wr, ['quads', 'glutes']),
  ExerciseSeedData('V-Squat Machine', _c, 'legs', 'machine', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Belt Squat', _c, 'legs', 'machine', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Smith Machine Squat', _c, 'legs', 'smith', _wr, ['quads', 'glutes']),
  ExerciseSeedData('Smith Machine Lunge', _c, 'legs', 'smith', _wr, ['quads', 'glutes']),

  // ── Göğüs (barbell / dumbbell) ──
  ExerciseSeedData('Barbell Bench Press', _c, 'chest', 'barbell', _wr, ['chest', 'triceps', 'front_delt']),
  ExerciseSeedData('Incline Barbell Bench Press', _c, 'chest', 'barbell', _wr, ['upper_chest', 'triceps', 'front_delt']),
  ExerciseSeedData('Decline Barbell Bench Press', _c, 'chest', 'barbell', _wr, ['chest', 'triceps']),
  ExerciseSeedData('Close-Grip Bench Press', _c, 'triceps', 'barbell', _wr, ['triceps', 'chest']),
  ExerciseSeedData('Floor Press', _c, 'chest', 'barbell', _wr, ['chest', 'triceps']),
  ExerciseSeedData('Dumbbell Bench Press', _c, 'chest', 'dumbbell', _wr, ['chest', 'triceps', 'front_delt']),
  ExerciseSeedData('Incline Dumbbell Press', _c, 'chest', 'dumbbell', _wr, ['upper_chest', 'triceps', 'front_delt']),
  ExerciseSeedData('Decline Dumbbell Press', _c, 'chest', 'dumbbell', _wr, ['chest', 'triceps']),

  // ── Göğüs (makine / smith) ──
  ExerciseSeedData('Chest Press Machine', _c, 'chest', 'machine', _wr, ['chest', 'triceps']),
  ExerciseSeedData('Incline Chest Press Machine', _c, 'chest', 'machine', _wr, ['upper_chest', 'triceps']),
  ExerciseSeedData('Decline Chest Press Machine', _c, 'chest', 'machine', _wr, ['chest', 'triceps']),
  ExerciseSeedData('Iso-Lateral Chest Press', _c, 'chest', 'machine', _wr, ['chest', 'triceps']),
  ExerciseSeedData('Smith Machine Bench Press', _c, 'chest', 'smith', _wr, ['chest', 'triceps']),
  ExerciseSeedData('Smith Machine Incline Press', _c, 'chest', 'smith', _wr, ['upper_chest', 'triceps']),
  ExerciseSeedData('Assisted Dip Machine', _c, 'chest', 'machine', _wr, ['chest', 'triceps']),

  // ── Sırt (barbell / dumbbell) ──
  ExerciseSeedData('Bent-Over Barbell Row', _c, 'back', 'barbell', _wr, ['back', 'biceps']),
  ExerciseSeedData('Pendlay Row', _c, 'back', 'barbell', _wr, ['back', 'biceps']),
  ExerciseSeedData('T-Bar Row', _c, 'back', 'machine', _wr, ['back', 'biceps']),
  ExerciseSeedData('Landmine Row', _c, 'back', 'barbell', _wr, ['back', 'biceps']),
  ExerciseSeedData('Meadows Row', _c, 'back', 'barbell', _wr, ['back', 'biceps']),
  ExerciseSeedData('Dumbbell Row', _c, 'back', 'dumbbell', _wr, ['back', 'biceps']),
  ExerciseSeedData('Chest-Supported Dumbbell Row', _c, 'back', 'dumbbell', _wr, ['back', 'biceps']),

  // ── Sırt (makine / kablo) ──
  ExerciseSeedData('Lat Pulldown', _c, 'back', 'cable', _wr, ['back', 'biceps']),
  ExerciseSeedData('Wide-Grip Lat Pulldown', _c, 'back', 'cable', _wr, ['back', 'biceps']),
  ExerciseSeedData('Close-Grip Lat Pulldown', _c, 'back', 'cable', _wr, ['back', 'biceps']),
  ExerciseSeedData('Reverse-Grip Lat Pulldown', _c, 'back', 'cable', _wr, ['back', 'biceps']),
  ExerciseSeedData('Seated Cable Row', _c, 'back', 'cable', _wr, ['back', 'biceps']),
  ExerciseSeedData('Iso-Lateral Row', _c, 'back', 'machine', _wr, ['back', 'biceps']),
  ExerciseSeedData('Iso-Lateral Lat Pulldown', _c, 'back', 'machine', _wr, ['back', 'biceps']),
  ExerciseSeedData('Chest-Supported Machine Row', _c, 'back', 'machine', _wr, ['back', 'biceps']),
  ExerciseSeedData('Seated Machine Row', _c, 'back', 'machine', _wr, ['back', 'biceps']),
  ExerciseSeedData('Assisted Pull-Up Machine', _c, 'back', 'machine', _wr, ['back', 'biceps']),
  ExerciseSeedData('Smith Machine Row', _c, 'back', 'smith', _wr, ['back', 'biceps']),

  // ── Omuz ──
  ExerciseSeedData('Overhead Press', _c, 'shoulders', 'barbell', _wr, ['shoulders', 'triceps']),
  ExerciseSeedData('Push Press', _c, 'shoulders', 'barbell', _wr, ['shoulders', 'triceps', 'legs']),
  ExerciseSeedData('Dumbbell Shoulder Press', _c, 'shoulders', 'dumbbell', _wr, ['shoulders', 'triceps']),
  ExerciseSeedData('Arnold Press', _c, 'shoulders', 'dumbbell', _wr, ['shoulders', 'triceps']),
  ExerciseSeedData('Machine Shoulder Press', _c, 'shoulders', 'machine', _wr, ['shoulders', 'triceps']),
  ExerciseSeedData('Smith Machine Shoulder Press', _c, 'shoulders', 'smith', _wr, ['shoulders', 'triceps']),
  ExerciseSeedData('Landmine Press', _c, 'shoulders', 'barbell', _wr, ['shoulders', 'triceps']),

  // ── Full body / patlayıcı ──
  ExerciseSeedData('Kettlebell Swing', _c, 'glutes', 'kettlebell', _wr, ['glutes', 'hamstrings', 'core']),

  // ═══════════════════════════ ISOLATION ═══════════════════════════

  // ── Biceps / ön kol ──
  ExerciseSeedData('Dumbbell Bicep Curl', _iso, 'biceps', 'dumbbell', _wr, ['biceps']),
  ExerciseSeedData('Incline Dumbbell Curl', _iso, 'biceps', 'dumbbell', _wr, ['biceps']),
  ExerciseSeedData('Hammer Curl', _iso, 'biceps', 'dumbbell', _wr, ['biceps', 'forearms']),
  ExerciseSeedData('Concentration Curl', _iso, 'biceps', 'dumbbell', _wr, ['biceps']),
  ExerciseSeedData('Spider Curl', _iso, 'biceps', 'dumbbell', _wr, ['biceps']),
  ExerciseSeedData('Barbell Curl', _iso, 'biceps', 'barbell', _wr, ['biceps']),
  ExerciseSeedData('EZ-Bar Curl', _iso, 'biceps', 'barbell', _wr, ['biceps']),
  ExerciseSeedData('Preacher Curl', _iso, 'biceps', 'machine', _wr, ['biceps']),
  ExerciseSeedData('Machine Bicep Curl', _iso, 'biceps', 'machine', _wr, ['biceps']),
  ExerciseSeedData('Cable Curl', _iso, 'biceps', 'cable', _wr, ['biceps']),
  ExerciseSeedData('Cable Hammer Curl', _iso, 'biceps', 'cable', _wr, ['biceps', 'forearms']),
  ExerciseSeedData('Reverse Curl', _iso, 'biceps', 'barbell', _wr, ['forearms', 'biceps']),
  ExerciseSeedData('Wrist Curl', _iso, 'biceps', 'dumbbell', _wr, ['forearms']),

  // ── Triceps / arka kol ──
  ExerciseSeedData('Tricep Pushdown', _iso, 'triceps', 'cable', _wr, ['triceps']),
  ExerciseSeedData('Rope Tricep Pushdown', _iso, 'triceps', 'cable', _wr, ['triceps']),
  ExerciseSeedData('Single-Arm Tricep Pushdown', _iso, 'triceps', 'cable', _wr, ['triceps']),
  ExerciseSeedData('Overhead Tricep Extension', _iso, 'triceps', 'cable', _wr, ['triceps']),
  ExerciseSeedData('Skull Crushers', _iso, 'triceps', 'barbell', _wr, ['triceps']),
  ExerciseSeedData('Tricep Kickback', _iso, 'triceps', 'dumbbell', _wr, ['triceps']),
  ExerciseSeedData('Machine Tricep Extension', _iso, 'triceps', 'machine', _wr, ['triceps']),
  ExerciseSeedData('Tricep Dip Machine', _iso, 'triceps', 'machine', _wr, ['triceps']),

  // ── Omuz (izolasyon) ──
  ExerciseSeedData('Dumbbell Lateral Raise', _iso, 'shoulders', 'dumbbell', _wr, ['side_delt']),
  ExerciseSeedData('Cable Lateral Raise', _iso, 'shoulders', 'cable', _wr, ['side_delt']),
  ExerciseSeedData('Machine Lateral Raise', _iso, 'shoulders', 'machine', _wr, ['side_delt']),
  ExerciseSeedData('Front Raise', _iso, 'shoulders', 'dumbbell', _wr, ['front_delt']),
  ExerciseSeedData('Cable Front Raise', _iso, 'shoulders', 'cable', _wr, ['front_delt']),
  ExerciseSeedData('Rear Delt Fly', _iso, 'shoulders', 'dumbbell', _wr, ['rear_delt']),
  ExerciseSeedData('Reverse Pec Deck', _iso, 'shoulders', 'machine', _wr, ['rear_delt']),
  ExerciseSeedData('Cable Rear Delt Fly', _iso, 'shoulders', 'cable', _wr, ['rear_delt']),
  ExerciseSeedData('Face Pull', _iso, 'shoulders', 'cable', _wr, ['rear_delt', 'traps']),
  ExerciseSeedData('Barbell Upright Row', _iso, 'shoulders', 'barbell', _wr, ['side_delt', 'traps']),
  ExerciseSeedData('Cable Upright Row', _iso, 'shoulders', 'cable', _wr, ['side_delt', 'traps']),

  // ── Göğüs (izolasyon) ──
  ExerciseSeedData('Dumbbell Chest Fly', _iso, 'chest', 'dumbbell', _wr, ['chest']),
  ExerciseSeedData('Incline Dumbbell Fly', _iso, 'chest', 'dumbbell', _wr, ['upper_chest']),
  ExerciseSeedData('Pec Deck', _iso, 'chest', 'machine', _wr, ['chest']),
  ExerciseSeedData('Cable Crossover', _iso, 'chest', 'cable', _wr, ['chest']),
  ExerciseSeedData('Low Cable Crossover', _iso, 'chest', 'cable', _wr, ['upper_chest']),
  ExerciseSeedData('Incline Cable Fly', _iso, 'chest', 'cable', _wr, ['upper_chest']),

  // ── Sırt / trapez (izolasyon) ──
  ExerciseSeedData('Straight-Arm Pulldown', _iso, 'back', 'cable', _wr, ['back']),
  ExerciseSeedData('Cable Pullover', _iso, 'back', 'cable', _wr, ['back', 'chest']),
  ExerciseSeedData('Dumbbell Pullover', _iso, 'back', 'dumbbell', _wr, ['back', 'chest']),
  ExerciseSeedData('Dumbbell Shrug', _iso, 'back', 'dumbbell', _wr, ['traps']),
  ExerciseSeedData('Barbell Shrug', _iso, 'back', 'barbell', _wr, ['traps']),
  ExerciseSeedData('Cable Shrug', _iso, 'back', 'cable', _wr, ['traps']),
  ExerciseSeedData('Machine Shrug', _iso, 'back', 'machine', _wr, ['traps']),
  ExerciseSeedData('Back Extension', _iso, 'back', 'machine', _wr, ['lower_back', 'glutes']),

  // ── Bacak (izolasyon) ──
  ExerciseSeedData('Leg Extension', _iso, 'legs', 'machine', _wr, ['quads']),
  ExerciseSeedData('Lying Leg Curl', _iso, 'legs', 'machine', _wr, ['hamstrings']),
  ExerciseSeedData('Seated Leg Curl', _iso, 'legs', 'machine', _wr, ['hamstrings']),
  ExerciseSeedData('Standing Leg Curl', _iso, 'legs', 'machine', _wr, ['hamstrings']),
  ExerciseSeedData('Hip Adduction Machine', _iso, 'legs', 'machine', _wr, ['adductors']),

  // ── Kalça ──
  ExerciseSeedData('Hip Thrust', _iso, 'glutes', 'barbell', _wr, ['glutes']),
  ExerciseSeedData('Machine Hip Thrust', _iso, 'glutes', 'machine', _wr, ['glutes']),
  ExerciseSeedData('Hip Abduction Machine', _iso, 'glutes', 'machine', _wr, ['glutes']),
  ExerciseSeedData('Glute Kickback Machine', _iso, 'glutes', 'machine', _wr, ['glutes']),
  ExerciseSeedData('Cable Glute Kickback', _iso, 'glutes', 'cable', _wr, ['glutes']),
  ExerciseSeedData('Cable Pull-Through', _iso, 'glutes', 'cable', _wr, ['glutes', 'hamstrings']),

  // ── Baldır ──
  ExerciseSeedData('Standing Calf Raise', _iso, 'calves', 'machine', _wr, ['calves']),
  ExerciseSeedData('Seated Calf Raise', _iso, 'calves', 'machine', _wr, ['calves']),
  ExerciseSeedData('Leg Press Calf Raise', _iso, 'calves', 'machine', _wr, ['calves']),
  ExerciseSeedData('Smith Machine Calf Raise', _iso, 'calves', 'smith', _wr, ['calves']),
  ExerciseSeedData('Donkey Calf Raise', _iso, 'calves', 'machine', _wr, ['calves']),

  // ═══════════════════════════ CALISTHENICS ═══════════════════════════

  ExerciseSeedData('Push-Up', _cal, 'chest', 'bodyweight', _rp, ['chest', 'triceps', 'core']),
  ExerciseSeedData('Diamond Push-Up', _cal, 'triceps', 'bodyweight', _rp, ['triceps', 'chest']),
  ExerciseSeedData('Pull-Up', _cal, 'back', 'bodyweight', _rp, ['back', 'biceps']),
  ExerciseSeedData('Chin-Up', _cal, 'back', 'bodyweight', _rp, ['back', 'biceps']),
  ExerciseSeedData('Parallel Bar Dips', _cal, 'chest', 'bodyweight', _rp, ['chest', 'triceps']),
  ExerciseSeedData('Bench Dip', _cal, 'triceps', 'bodyweight', _rp, ['triceps']),
  ExerciseSeedData('Bodyweight Squat', _cal, 'legs', 'bodyweight', _rp, ['quads', 'glutes']),
  ExerciseSeedData('Pistol Squat', _cal, 'legs', 'bodyweight', _rp, ['quads', 'glutes']),
  ExerciseSeedData('Bodyweight Lunge', _cal, 'legs', 'bodyweight', _rp, ['quads', 'glutes']),
  ExerciseSeedData('Plank', _cal, 'core', 'bodyweight', _tm, ['core']),
  ExerciseSeedData('Side Plank', _cal, 'core', 'bodyweight', _tm, ['core', 'obliques']),
  ExerciseSeedData('Hanging Leg Raise', _cal, 'core', 'bodyweight', _rp, ['core']),
  ExerciseSeedData('Knee Raise', _cal, 'core', 'bodyweight', _rp, ['core']),
  ExerciseSeedData('Captains Chair Leg Raise', _cal, 'core', 'machine', _rp, ['core']),
  ExerciseSeedData('Hyperextension', _cal, 'back', 'bodyweight', _rp, ['lower_back', 'glutes']),
  ExerciseSeedData('Mountain Climbers', _cal, 'core', 'bodyweight', _tm, ['core', 'cardio']),
  ExerciseSeedData('Burpees', _cal, 'full_body', 'bodyweight', _rp, ['full_body']),
  ExerciseSeedData('Muscle-Up', _cal, 'back', 'bodyweight', _rp, ['back', 'chest', 'triceps']),
  ExerciseSeedData('Inverted Row', _cal, 'back', 'bodyweight', _rp, ['back', 'biceps']),
  ExerciseSeedData('Pike Push-Up', _cal, 'shoulders', 'bodyweight', _rp, ['shoulders', 'triceps']),
  ExerciseSeedData('Handstand Push-Up', _cal, 'shoulders', 'bodyweight', _rp, ['shoulders', 'triceps']),
  ExerciseSeedData('L-Sit', _cal, 'core', 'bodyweight', _tm, ['core']),
  ExerciseSeedData('Crunch', _cal, 'core', 'bodyweight', _rp, ['core']),
  ExerciseSeedData('Sit-Up', _cal, 'core', 'bodyweight', _rp, ['core']),
  ExerciseSeedData('Decline Sit-Up', _cal, 'core', 'bodyweight', _rp, ['core']),
  ExerciseSeedData('Reverse Crunch', _cal, 'core', 'bodyweight', _rp, ['core']),
  ExerciseSeedData('Bicycle Crunch', _cal, 'core', 'bodyweight', _rp, ['core', 'obliques']),
  ExerciseSeedData('Russian Twist', _cal, 'core', 'bodyweight', _rp, ['obliques', 'core']),
  ExerciseSeedData('Cable Crunch', _cal, 'core', 'cable', _wr, ['core']),
  ExerciseSeedData('Ab Crunch Machine', _cal, 'core', 'machine', _wr, ['core']),
  ExerciseSeedData('Ab Wheel Rollout', _cal, 'core', 'bodyweight', _rp, ['core']),
  ExerciseSeedData('Dead Bug', _cal, 'core', 'bodyweight', _rp, ['core']),
  ExerciseSeedData('Glute Bridge', _cal, 'glutes', 'bodyweight', _rp, ['glutes']),
  ExerciseSeedData('Superman', _cal, 'back', 'bodyweight', _tm, ['lower_back']),
  ExerciseSeedData('Nordic Hamstring Curl', _cal, 'legs', 'bodyweight', _rp, ['hamstrings']),

  // ═══════════════════════════ CARDIO ═══════════════════════════

  ExerciseSeedData('Treadmill Running', _car, 'full_body', 'cardio', _tm, ['cardio']),
  ExerciseSeedData('Treadmill Walking', _car, 'full_body', 'cardio', _tm, ['cardio']),
  ExerciseSeedData('Incline Treadmill Walk', _car, 'full_body', 'cardio', _tm, ['cardio', 'glutes']),
  ExerciseSeedData('Stationary Bike', _car, 'legs', 'cardio', _tm, ['cardio', 'legs']),
  ExerciseSeedData('Recumbent Bike', _car, 'legs', 'cardio', _tm, ['cardio', 'legs']),
  ExerciseSeedData('Spin Bike', _car, 'legs', 'cardio', _tm, ['cardio', 'legs']),
  ExerciseSeedData('Assault Bike', _car, 'full_body', 'cardio', _tm, ['cardio']),
  ExerciseSeedData('Elliptical', _car, 'full_body', 'cardio', _tm, ['cardio']),
  ExerciseSeedData('Arc Trainer', _car, 'full_body', 'cardio', _tm, ['cardio']),
  ExerciseSeedData('Rowing Machine', _car, 'full_body', 'cardio', _tm, ['cardio', 'back']),
  ExerciseSeedData('SkiErg', _car, 'full_body', 'cardio', _tm, ['cardio', 'back']),
  ExerciseSeedData('Stair Climber', _car, 'legs', 'cardio', _tm, ['cardio', 'legs']),
  ExerciseSeedData('Jump Rope', _car, 'full_body', 'none', _tm, ['cardio', 'calves']),
  ExerciseSeedData('Battle Ropes', _car, 'full_body', 'none', _tm, ['cardio', 'shoulders']),
  ExerciseSeedData('Box Jump', _car, 'legs', 'none', _rp, ['cardio', 'legs']),
  ExerciseSeedData('Jumping Jacks', _car, 'full_body', 'none', _tm, ['cardio']),
  ExerciseSeedData('High Knees', _car, 'full_body', 'none', _tm, ['cardio']),
  ExerciseSeedData('Sled Push', _car, 'full_body', 'none', _ds, ['cardio', 'legs']),
  ExerciseSeedData('HIIT Intervals', _car, 'full_body', 'none', _tm, ['cardio']),
  ExerciseSeedData('Outdoor Running', _car, 'full_body', 'none', _ds, ['cardio']),
  ExerciseSeedData('Outdoor Cycling', _car, 'legs', 'none', _ds, ['cardio', 'legs']),
  ExerciseSeedData('Swimming', _car, 'full_body', 'none', _ds, ['cardio', 'full_body']),

  // ═══════════════════════════ FLEXIBILITY ═══════════════════════════

  ExerciseSeedData('Dynamic Warm-Up', _flex, 'full_body', 'bodyweight', _tm, ['full_body']),
  ExerciseSeedData('Foam Rolling', _flex, 'full_body', 'none', _tm, ['full_body']),
  ExerciseSeedData('Static Hamstring Stretch', _flex, 'legs', 'bodyweight', _tm, ['hamstrings']),
  ExerciseSeedData('Quad Stretch', _flex, 'legs', 'bodyweight', _tm, ['quads']),
  ExerciseSeedData('Hip Flexor Stretch', _flex, 'legs', 'bodyweight', _tm, ['hip_flexors']),
  ExerciseSeedData('Couch Stretch', _flex, 'legs', 'bodyweight', _tm, ['quads', 'hip_flexors']),
  ExerciseSeedData('Butterfly Stretch', _flex, 'legs', 'bodyweight', _tm, ['adductors']),
  ExerciseSeedData('Calf Stretch', _flex, 'calves', 'bodyweight', _tm, ['calves']),
  ExerciseSeedData('Shoulder Stretch', _flex, 'shoulders', 'bodyweight', _tm, ['shoulders']),
  ExerciseSeedData('Chest Stretch', _flex, 'chest', 'bodyweight', _tm, ['chest']),
  ExerciseSeedData('Neck Stretch', _flex, 'shoulders', 'bodyweight', _tm, ['neck']),
  ExerciseSeedData('Cat-Cow Stretch', _flex, 'core', 'bodyweight', _tm, ['spine', 'core']),
  ExerciseSeedData('Cobra Stretch', _flex, 'core', 'bodyweight', _tm, ['spine', 'core']),
  ExerciseSeedData('Child Pose', _flex, 'back', 'bodyweight', _tm, ['back']),
  ExerciseSeedData('Downward Dog', _flex, 'full_body', 'bodyweight', _tm, ['full_body']),
  ExerciseSeedData('Pigeon Pose', _flex, 'glutes', 'bodyweight', _tm, ['glutes', 'hip_flexors']),
  ExerciseSeedData('Seated Forward Fold', _flex, 'legs', 'bodyweight', _tm, ['hamstrings']),
  ExerciseSeedData('Spinal Twist', _flex, 'core', 'bodyweight', _tm, ['spine']),
  ExerciseSeedData('Thoracic Rotation', _flex, 'core', 'bodyweight', _tm, ['spine']),
  ExerciseSeedData("World's Greatest Stretch", _flex, 'full_body', 'bodyweight', _tm, ['full_body']),
  ExerciseSeedData('Yoga Flow', _flex, 'full_body', 'bodyweight', _tm, ['full_body']),
];

/// Seed → Drift companion'ları (yalnız boş kurulumda yazılır;
/// mevcut kurulumlara `SeedManager._backfillExercises` ile gelir).
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
