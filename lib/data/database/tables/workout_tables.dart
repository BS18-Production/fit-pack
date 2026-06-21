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
  IntColumn get phase => integer()(); // 1, 2, 3
  TextColumn get workoutType => text()(); // FullA, FullB, FullC, UpperA, UpperB, LowerA, LowerB, Cardio
  IntColumn get durationMin => integer().nullable()();
  TextColumn get kneeStatus => text().withDefault(const Constant('normal'))(); // normal, sore, pain
  IntColumn get energy => integer().nullable()(); // 1-10
  IntColumn get rpe => integer().nullable()(); // 1-10
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeload => boolean().withDefault(const Constant(false))();
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
}
