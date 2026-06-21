import 'package:drift/drift.dart';

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  // v1: compound, isolation. v5 (Antrenman V2): + calisthenics, cardio, flexibility.
  TextColumn get category => text()();
  TextColumn get muscleGroups => text()(); // JSON array: ["chest", "triceps"]
  TextColumn get alternatives => text().nullable()(); // JSON array
  TextColumn get notes => text().nullable()();

  // v1 — kişisel/V1'e özgü (Antrenman V2'de üründen çıkar, dormant kalır).
  BoolColumn get isPosture => boolean().withDefault(const Constant(false))();
  BoolColumn get isArm => boolean().withDefault(const Constant(false))();

  // v5 (Antrenman V2 — docs/09-workout-v2.md): kütüphane filtreleri.
  TextColumn get primaryMuscle => text().nullable()(); // chest, back, legs...
  TextColumn get equipment => text().nullable()(); // barbell, dumbbell, machine...
  TextColumn get measurementType =>
      text().withDefault(const Constant('weight_reps'))(); // weight_reps, reps, time, distance
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  // V1: faz/program. V2 (Antrenman V2): faz=0, workoutType=seans adı (rutin
  // adı veya "Boş Antrenman"). Eski kayıtlar korunur (additive yaklaşım).
  IntColumn get phase => integer()();
  TextColumn get workoutType => text()();
  IntColumn get durationMin => integer().nullable()();
  TextColumn get kneeStatus => text().withDefault(const Constant('normal'))();
  IntColumn get energy => integer().nullable()();
  IntColumn get rpe => integer().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeload => boolean().withDefault(const Constant(false))();

  // v6 (Antrenman V2 — docs/09-workout-v2.md): rutin bağı + canlı süre.
  IntColumn get routineId => integer().nullable()(); // null = boş antrenman
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
}

class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(WorkoutSessions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get setNumber => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get reps => integer().nullable()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  IntColumn get restSeconds => integer().nullable()();

  // v7 (Antrenman V2 Faz C): gelişmiş set takibi.
  RealColumn get rpe => real().nullable()(); // 1-10, yarım değer destekli
  TextColumn get setType => text().withDefault(const Constant('normal'))(); // normal, warmup, drop, failure
  BoolColumn get isComplete => boolean().withDefault(const Constant(false))();
  RealColumn get distanceM => real().nullable()(); // mesafe ölçümlü hareket
  IntColumn get durationSec => integer().nullable()(); // süre ölçümlü hareket
}

/// v6 (Antrenman V2 — docs/09-workout-v2.md): kullanıcı rutinleri.
class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get note => text().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  // Opsiyonel haftalık gün (1=Pzt..7=Paz) → Home dinlenme günü zekası.
  IntColumn get scheduledWeekday => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

/// Bir rutindeki hareketler + hedef set×tekrar (sürükle-bırak sıralı).
class RoutineExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().references(Routines, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  IntColumn get targetSets => integer().nullable()();
  IntColumn get targetRepsMin => integer().nullable()();
  IntColumn get targetRepsMax => integer().nullable()();
  IntColumn get targetRestSec => integer().nullable()();
  TextColumn get note => text().nullable()();
}
