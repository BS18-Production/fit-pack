import 'package:drift/drift.dart';
import 'sync_columns.dart';

/// v17 (docs/40 W-2): aynı platform örneği yerelde bir kez içe alınır.
/// Kısmi (partial) index: elle girilen satırların `source_ref`'i NULL'dır.
const bodySourceRefIndexSql =
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_body_measurements_source_ref '
    'ON body_measurements (source_ref) WHERE source_ref IS NOT NULL';

class BodyMeasurements extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get chestCm => real().nullable()();
  RealColumn get armCm => real().nullable()();
  RealColumn get hipCm => real().nullable()();
  RealColumn get neckCm => real().nullable()();
  RealColumn get bodyFatPct => real().nullable()();

  // v17 (docs/40 — tartıdan kilo): ölçümün kaynağı. Hepsi nullable → eski
  // satırlar NULL = elle giriş; eski istemci kolonları bilmez, bozulmaz.
  /// `NULL`/`manual` = elle; `health` = Apple Sağlık / Health Connect.
  TextColumn get source => text().nullable()();

  /// Platform örnek kimliği (HealthKit UUID / Health Connect kayıt kimliği).
  /// `_id` ile bitmez: senkron `*_id` kolonlarını yabancı anahtar sayar.
  TextColumn get sourceRef => text().nullable()();

  /// Ölçümü yazan uygulama (ör. "Withings"), kaynak simgesinde gösterilir.
  TextColumn get sourceApp => text().nullable()();

  /// İçe alınan satır silinmez, gizlenir (W-6): yeniden içe alınmasın.
  BoolColumn get hidden => boolean().nullable()();
}

class ProgressPhotos extends Table with SyncColumns {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get angle => text()(); // front, side, back
  TextColumn get imagePath => text()();
}
