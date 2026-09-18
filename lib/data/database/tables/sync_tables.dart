import 'package:drift/drift.dart';

/// Senkron v2'nin iki yardımcı tablosu (docs/20 §4.1). İkisi de **cihaza
/// aittir**: sunucuya gönderilmez, senkron kolonları taşımaz.

/// Anahtar–değer defteri: tetikleyici bayrağı, cihaz sayacı, çekme imleçleri,
/// son başarılı senkron damgaları.
///
/// Neden tabloda? `capture` bayrağını tetikleyicilerin görmesi gerekiyor —
/// SQLite tetikleyicisi Dart değişkenini okuyamaz, tabloyu okur. Sayaç da
/// burada: uygulama ölse bile kaldığı yerden devam eder.
@DataClassName('SyncMetaEntry')
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};

  @override
  String get tableName => 'sync_meta';
}

/// Mezar taşı: silinen satırın **kimliği** (içeriği değil). Silmenin öteki
/// cihaza taşınmasını sağlar — "sildiğim kayıt geri geldi" hatasının çözümü
/// (docs/20 K-3). Gönderimi Aşama 5'te açılır; şimdilik yalnız birikir.
@DataClassName('SyncTombstone')
class SyncTombstones extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Silinen satırın tablosu (`workout_sets` gibi).
  TextColumn get sourceTable => text().named('table_name')();

  /// Silinen satırın sunucu kimliği.
  TextColumn get uid => text()();

  /// Silme zamanı (milisaniye).
  IntColumn get changedAtMs => integer().nullable()();

  /// Gönderim onayı için cihaz sayacı.
  IntColumn get localSeq => integer().nullable()();

  /// 0 = gönderildi, 1 = kuyrukta.
  IntColumn get syncState =>
      integer().nullable().withDefault(const Constant(0))();

  @override
  String get tableName => 'sync_tombstones';
}
