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

  /// En son **kilosu dolu** ölçüm. Bilerek "en son ölçüm" değildir: ölçüm
  /// formu tek bir alanla kaydetmeye izin veriyor (yalnız bel çevresi gibi), o
  /// satırın `weightKg`'i NULL olur. Kiloyu o sorgudan okumak, dün girilen 87
  /// kg'ı "kilo yok" saydırıyordu — profil ve kalori hesapları çelişiyordu
  /// (dış inceleme 2026-09-15, #11).
  Future<BodyMeasurement?> getLatestWeight() => (select(bodyMeasurements)
        ..where((m) => m.weightKg.isNotNull())
        ..orderBy([(m) => OrderingTerm.desc(m.date)])
        ..limit(1))
      .getSingleOrNull();

  /// [start, end) aralığındaki ölçümler — bitiş HARİÇ (CODE_REVIEW H-01).
  Future<List<BodyMeasurement>> getMeasurementsInRange(DateTime start, DateTime end) =>
      (select(bodyMeasurements)
            ..where((m) =>
                m.date.isBiggerOrEqualValue(start) &
                m.date.isSmallerThanValue(end))
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
