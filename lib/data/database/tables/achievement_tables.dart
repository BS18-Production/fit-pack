import 'package:drift/drift.dart';

class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // streak_10, streak_25, session_50, etc.
  DateTimeColumn get unlockedAt => dateTime()();
  TextColumn get metadataJson => text().nullable()();
}

class UserProfile extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get currentPhase => integer().withDefault(const Constant(1))();
  IntColumn get currentWeek => integer().withDefault(const Constant(1))();
  DateTimeColumn get startDate => dateTime()();
  IntColumn get kcalGoal => integer().withDefault(const Constant(2200))();
  IntColumn get proteinGoal => integer().withDefault(const Constant(180))();
  DateTimeColumn get lastDeload => dateTime().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get goalWeightKg => real().nullable()();
}
