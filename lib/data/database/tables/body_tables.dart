import 'package:drift/drift.dart';

class BodyMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get chestCm => real().nullable()();
  RealColumn get armCm => real().nullable()();
  RealColumn get hipCm => real().nullable()();
  RealColumn get neckCm => real().nullable()();
  RealColumn get bodyFatPct => real().nullable()();
}

class ProgressPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get angle => text()(); // front, side, back
  TextColumn get imagePath => text()();
}
