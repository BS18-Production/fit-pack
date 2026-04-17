import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/body_tables.dart';

part 'body_dao.g.dart';

@DriftAccessor(tables: [BodyMeasurements, ProgressPhotos])
class BodyDao extends DatabaseAccessor<AppDatabase> with _$BodyDaoMixin {
  BodyDao(super.db);

  // === Body Measurements ===
  Future<List<BodyMeasurement>> getAllMeasurements() =>
      (select(bodyMeasurements)..orderBy([(m) => OrderingTerm.desc(m.date)])).get();

  Future<BodyMeasurement?> getLatestMeasurement() =>
      (select(bodyMeasurements)
            ..orderBy([(m) => OrderingTerm.desc(m.date)])
            ..limit(1))
          .getSingleOrNull();

  Future<List<BodyMeasurement>> getMeasurementsInRange(DateTime start, DateTime end) =>
      (select(bodyMeasurements)
            ..where((m) => m.date.isBetweenValues(start, end))
            ..orderBy([(m) => OrderingTerm.asc(m.date)]))
          .get();

  Future<int> insertMeasurement(BodyMeasurementsCompanion entry) =>
      into(bodyMeasurements).insert(entry);

  Future<int> deleteMeasurement(int id) =>
      (delete(bodyMeasurements)..where((m) => m.id.equals(id))).go();

  // === Progress Photos ===
  Future<List<ProgressPhoto>> getAllPhotos() =>
      (select(progressPhotos)..orderBy([(p) => OrderingTerm.desc(p.date)])).get();

  Future<int> insertPhoto(ProgressPhotosCompanion entry) =>
      into(progressPhotos).insert(entry);

  Future<int> deletePhoto(int id) =>
      (delete(progressPhotos)..where((p) => p.id.equals(id))).go();
}
