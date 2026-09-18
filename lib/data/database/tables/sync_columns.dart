import 'package:drift/drift.dart';

/// Senkron kolonları — Supabase mirror tablolarıyla eşleşme için (docs/18 §4).
///
/// **Neden ayrı `uid` kolonu, neden UUID'ye tam göç değil?**
/// Tabloların birincil anahtarı `integer autoIncrement` ve tablolar birbirine
/// bu integer'larla bağlı (7 yabancı anahtar). Hepsini UUID'ye çevirmek tüm
/// DAO/sorgu/testleri etkilerdi. Onun yerine integer anahtar **yerelde aynen
/// kalır**, yanına dünyada tek olan `uid` eklenir:
///
/// - **Yerelde:** integer id + FK'ler değişmeden çalışır (mevcut kod dokunulmaz)
/// - **Sunucuda:** `uid` birincil anahtardır, FK'ler de `uid` üstünden kurulur
/// - **Senkron katmanı** çeviriyi yapar (int id ↔ uid)
///
/// `uid` istemcide üretilir (UUID v4) → aynı kayıt iki kez gönderilse sunucu
/// "bunu zaten aldım" deyip üstüne yazar, çift satır oluşmaz (idempotency).
/// Bu, ağ koptuğunda yeniden denemeyi güvenli yapan şeydir.
mixin SyncColumns on Table {
  /// Dünyada tek kimlik (UUID v4), istemcide üretilir. Sunucuda birincil
  /// anahtar. Nullable — göçte eski satırlara backfill edilir.
  ///
  /// Not: UNIQUE kısıtı kolonun kendisinde DEĞİL, ayrı bir unique index'te
  /// (SQLite `ALTER TABLE ADD COLUMN` ile UNIQUE kolon eklenemez). Index
  /// `AppDatabase` göçünde kurulur; NULL'lar birden fazla olabilir.
  TextColumn get uid => text().nullable()();

  /// Satırın sahibi (Supabase `auth.uid()`). Ortak katalog satırlarında NULL
  /// (1022 hareket + seed besinler kimseye ait değil — docs/18 §3.2).
  TextColumn get userId => text().nullable()();

  /// Son değişiklik zamanı — çakışmada "en son yazan kazanır" (docs/18 §6.5).
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Giden kutusu durumu (docs/18 §6): 0 = temiz (senkron), 1 = beklemede,
  /// 2 = hata. Kuyruk DİSKTE durur — uygulama öldürülse de kayıt kaybolmaz.
  ///
  /// **NULL = 0 (temiz).** Nullable olmasının sebebi projenin göç kuralı:
  /// eklenen kolonlar nullable olmalı ki ara sürüme göç eden eski testler ve
  /// v1'den gelen kurulumlar satır okurken patlamasın (üretilen mapper NOT
  /// NULL kolonu zorunlu sayıyor). Kuyruk sorguları `sync_state = 1` aradığı
  /// için NULL satırlar doğal olarak "gönderilecek bir şey yok" anlamına gelir.
  IntColumn get syncState =>
      integer().nullable().withDefault(const Constant(0))();

  /// Son yerel değişikliğin zamanı, **milisaniye** (senkron v2, docs/20 §4.1).
  /// Çakışma kuralı buna bakar. `updated_at` (saniye) ekranlar için kalır ama
  /// sürüm olarak kullanılmaz: aynı saniyedeki iki düzenleme ayırt edilemiyor,
  /// gönderim sırasındaki düzenleme sessizce kayboluyordu (#3).
  IntColumn get changedAtMs => integer().nullable()();

  /// Cihazdaki her yazmada artan sayı. "Gönderdiğim sürüm hâlâ aynı mı?"
  /// sorusunun cevabı — temiz işaretleme buna bakar.
  IntColumn get localSeq => integer().nullable()();

  /// Bu satırın en son görülen sunucu sürümü. `NULL` = hiç gönderilmedi.
  /// (Sunucu tarafı Aşama 3'te gelir; kolon şimdiden ayrılır.)
  IntColumn get serverRev => integer().nullable()();
}

/// Senkron kolonu taşıyan tabloların SQL adları (docs/18 §3.1–3.2).
/// `Achievements` hariç — kullanılmıyor, senkron kapsamı dışı (docs/18 §3.3).
const syncedTableNames = <String>[
  'user_profile',
  'workout_sessions',
  'workout_sets',
  'routines',
  'routine_exercises',
  'food_logs',
  'water_intake',
  'body_measurements',
  'progress_photos',
  'recipe_items',
  'exercises',
  'foods',
];

/// Ortak katalog barındıran tablolar: yalnız `is_custom = 1` satırlar
/// kullanıcıya aittir ve senkron edilir. Kalanı cihazda seed olarak durur —
/// 1022 hareketi her kullanıcının hesabına kopyalamak israf olurdu.
const catalogTableNames = <String>['exercises', 'foods'];

/// Gönderim sırası — referans verilen tablo ÖNCE gider (docs/18 §6.2).
/// `supabase/01_schema.sql`'deki tablo oluşturma sırasıyla aynı olmalı.
const syncPushOrder = <String>[
  'user_profile',
  'exercises',
  'foods',
  'routines',
  'routine_exercises',
  'workout_sessions',
  'workout_sets',
  'food_logs',
  'recipe_items',
  'water_intake',
  'body_measurements',
  'progress_photos',
];

/// Yerel integer yabancı anahtar → hedef tablo. Sunucuda bu kolonlar `*_uid`
/// olarak gider; çeviriyi senkron katmanı yapar (docs/18 §4).
///
/// ⚠️ `supabase/01_schema.sql` üretecindeki FK haritasıyla AYNI olmalı —
/// ikisi ayrışırsa gönderilen JSON sunucu şemasına uymaz.
const syncForeignKeys = <String, Map<String, String>>{
  'workout_sessions': {'routine_id': 'routines'},
  'workout_sets': {'session_id': 'workout_sessions', 'exercise_id': 'exercises'},
  'routine_exercises': {'routine_id': 'routines', 'exercise_id': 'exercises'},
  'food_logs': {'food_id': 'foods'},
  'recipe_items': {'recipe_id': 'foods', 'food_id': 'foods'},
};

/// Sunucuya GİTMEYEN kolonlar: `id` cihaz içi kimlik, `sync_state` giden
/// kutusu bayrağı — ikisi de yerele ait (docs/18 §4).
///
/// Senkron v2 kolonları:
/// - `local_seq` **kalıcı olarak yerel** (cihaz sayacı, sunucuyu ilgilendirmez).
/// - `server_rev` sunucudan GELİR, istemci göndermez (sunucu atar).
/// - `changed_at_ms` **Aşama 4'ten beri GÖNDERİLİR** — sunucudaki çakışma
///   kuralının ölçüsü budur (docs/20 §5.2). Gönderilmezse sunucu yazmayı
///   "eski" sayıp sessizce reddeder.
const localOnlyColumns = <String>{
  'id',
  'sync_state',
  'local_seq',
  'server_rev',
};

/// `uid` için unique index adı — tablo başına tek.
String uidIndexName(String table) => 'idx_${table}_uid';

/// SQLite'ta UUID v4 üreten ifade (8-4-4-4-12). Göçte eski satırlara backfill
/// için tek bir UPDATE ile çalışır — satır satır Dart döngüsünden çok hızlı.
const _uuidV4Sql = '''lower(
  hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
  substr(hex(randomblob(2)), 2) || '-' ||
  substr('89ab', abs(random()) % 4 + 1, 1) ||
  substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))
)''';

/// Eksik `uid`'leri doldurur (yalnız NULL olanlar — tekrar çalıştırmak güvenli).
String backfillUidSql(String table) =>
    'UPDATE $table SET uid = $_uuidV4Sql WHERE uid IS NULL';

/// Eksik `updated_at`'leri şimdiye ayarlar (yalnız NULL olanlar — tekrar
/// çalıştırmak güvenli). v9 göçü `uid`'i backfill etti ama `updated_at`'i boş
/// bıraktı; sunucudaki kolon NOT NULL olduğu için bu satırlar gönderimde
/// `23502` (not-null ihlali) ile reddediliyordu (docs/18 §6.9). Zaman damgası
/// tetikleyicilerle AYNI birimde yazılır (unix saniye).
String backfillUpdatedAtSql(String table) =>
    "UPDATE $table SET updated_at = CAST(strftime('%s','now') AS INTEGER) "
    'WHERE updated_at IS NULL';

/// `uid` unique index'i. NULL'lar SQLite'ta unique index'i ihlal etmez, yani
/// backfill'den önce de kurulabilir.
String createUidIndexSql(String table) =>
    'CREATE UNIQUE INDEX IF NOT EXISTS ${uidIndexName(table)} ON $table(uid)';

/// Mevcut satırları giden kutusuna alır (`syncState = 1`) → ilk girişte
/// sunucuya yüklenirler. Katalog tablolarında yalnız kullanıcının kendi
/// eklediği satırlar kuyruğa girer; seed içerik girmez.
String queueExistingRowsSql(String table) => catalogTableNames.contains(table)
    ? 'UPDATE $table SET sync_state = 1 WHERE is_custom = 1'
    : 'UPDATE $table SET sync_state = 1';

// ─────────────────────── Giden kutusu tetikleyicileri (v10) ───────────────────

/// Neden tetikleyici, neden 23 yazma noktasını tek tek damgalamıyoruz?
///
/// Bir yazma noktası atlanırsa o veri **sessizce senkron edilmez** — kullanıcı
/// kaydettiğini sanır, aslında yalnız cihazda kalır. Hata türlerinin en kötüsü.
/// Tetikleyici veritabanı seviyesinde durur: mevcut DAO'lar, ileride yazılacak
/// kod ve ham SQL dahil **her** yazmayı yakalar.
///
/// **Döngü koruması:** Tetikleyici yalnız `sync_state` DEĞİŞMEDİĞİNDE çalışır.
/// Senkron katmanı satırı temiz işaretlerken `sync_state`'i 1→0 çevirir, yani
/// koşul tutmaz ve satır yeniden kirlenmez. Normal uygulama yazmaları
/// `sync_state`'e dokunmadığı için koşul tutar ve satır kuyruğa girer.
///
/// **Katalog istisnası:** `exercises`/`foods` seed satırları (1015 hareket)
/// kuyruğa GİRMEZ — yalnız `is_custom = 1` satırlar otomatik kirlenir. Katalog
/// satırı ancak kullanıcı onu bir sette kullanınca senkron katmanı tarafından
/// elle kuyruğa alınır (docs/18 §3.2 seçenek A).
/// Kuyruğa alma ifadesi. **Kimlik üretimi bundan ayrıdır:** katalog satırları
/// da `uid` ALIR (sette kullanılınca gönderilebilmeleri için), ama kuyruğa
/// kendiliğinden GİRMEZLER.
///
/// - Normal tablolar → her yazma kuyruğa girer
/// - Katalog tabloları → yalnız kullanıcının kendi satırı (`is_custom = 1`) ya
///   da daha önce senkron edilmiş satır (`user_id` dolu) kuyruğa girer; 1015
///   seed hareket girmez
String _dirtyExpr(String table) => catalogTableNames.contains(table)
    ? 'CASE WHEN NEW.is_custom = 1 OR NEW.user_id IS NOT NULL THEN 1 ELSE 0 END'
    : '1';

/// **v10 tetikleyicileri — TARİHTE DONMUŞ.** v9 → v10 göç adımı bunları kurar.
/// Güncel (v11) SQL'i kullanmak yasak: o SQL `changed_at_ms` / `local_seq` /
/// `sync_meta` ister, v10 şemasında bunlar yoktur ve göç yolundaki her yazma
/// patlar (aynı ders v4 tablo oluşturmada da yaşandı).
String createInsertTriggerSqlV10(String table) => '''
CREATE TRIGGER IF NOT EXISTS ${table}_sync_ins AFTER INSERT ON $table
BEGIN
  UPDATE $table
     SET uid        = COALESCE(NEW.uid, $_uuidV4Sql),
         updated_at = CAST(strftime('%s','now') AS INTEGER),
         sync_state = ${_dirtyExpr(table)}
   WHERE id = NEW.id;
END''';

String createUpdateTriggerSqlV10(String table) => '''
CREATE TRIGGER IF NOT EXISTS ${table}_sync_upd AFTER UPDATE ON $table
WHEN NEW.sync_state IS OLD.sync_state
BEGIN
  UPDATE $table
     SET uid        = COALESCE(NEW.uid, $_uuidV4Sql),
         updated_at = CAST(strftime('%s','now') AS INTEGER),
         sync_state = ${_dirtyExpr(table)}
   WHERE id = NEW.id;
END''';

// ─────────────────── Senkron v2 (şema v11) — docs/20 §4.1 ───────────────────

/// Milisaniyelik "şimdi". `strftime('%s')` yalnız saniye verir; aynı saniyedeki
/// iki düzenleme ayırt edilemediği için gönderim sırasındaki değişiklik
/// kayboluyordu (docs/20 §1 hata #3).
const _nowMsSql =
    "CAST((julianday('now') - 2440587.5) * 86400000 AS INTEGER)";

/// Cihaz sayacı: her yazmada bir artan `local_seq` üretir.
const _nextSeqSql =
    "(SELECT CAST(COALESCE(value,'0') AS INTEGER) + 1 FROM sync_meta "
    "WHERE key = 'next_seq')";

const _bumpSeqSql = "UPDATE sync_meta SET value = "
    "CAST(CAST(COALESCE(value,'0') AS INTEGER) + 1 AS TEXT) "
    "WHERE key = 'next_seq'";

/// Tetikleyiciler yazmaları kuyruğa alsın mı (K-4). Çekme sırasında 0 yapılır:
/// eskiden tetikleyiciler DÜŞÜRÜLÜYORDU, o aralıkta kullanıcının yazdığı satır
/// uid'siz ve kuyruksuz kalıyordu (docs/20 §1 hata #9 / S-4).
const _captureOnSql =
    "(SELECT COALESCE(value,'1') FROM sync_meta WHERE key = 'capture') = '1'";

// `sync_meta` ve `sync_tombstones` tabloları drift tanımından kurulur
// (`tables/sync_tables.dart` + `Migrator.createTable`). Elle CREATE TABLE
// yazmak şema doğrulamasını bozuyordu: aynı tablo iki farklı DDL ile
// tanımlanınca `migrateAndValidate` "şema uyuşmuyor" diyor.

/// `sync_meta` varsayılanları — tekrar çalıştırmak güvenli.
const seedSyncMetaSql = [
  "INSERT OR IGNORE INTO sync_meta (key, value) VALUES ('capture', '1')",
  "INSERT OR IGNORE INTO sync_meta (key, value) VALUES ('next_seq', '1')",
];

/// Çekme/göç sırasında tetikleyicileri susturur (1 = kuyruğa al, 0 = sus).
String setCaptureSql(bool on) =>
    "INSERT INTO sync_meta (key, value) VALUES ('capture', '${on ? 1 : 0}') "
    "ON CONFLICT(key) DO UPDATE SET value = excluded.value";

/// Göçte `changed_at_ms`'i eski saniyelik damgadan doldurur.
String backfillChangedAtMsSql(String table) =>
    'UPDATE $table SET changed_at_ms = updated_at * 1000 '
    'WHERE changed_at_ms IS NULL AND updated_at IS NOT NULL';

/// Göçte `local_seq`: kuyruktaki satırlar sırayla numaralanır ki ilk
/// gönderimde "arada değişti mi?" karşılaştırması anlamlı olsun.
String backfillLocalSeqSql(String table) =>
    'UPDATE $table SET local_seq = id WHERE local_seq IS NULL';

/// Bir tablonun senkron tetikleyici adları (onarım kontrolü için).
List<String> syncTriggerNames(String table) => [
  '${table}_sync_ins',
  '${table}_sync_upd',
  '${table}_sync_del',
];

/// INSERT sonrası: `uid` yoksa üret, zaman damgala, sayaç ver, (uygunsa)
/// kuyruğa al. `capture = 0` iken hiçbir şey yapmaz (çekme yankılanmasın).
String createInsertTriggerSql(String table) => '''
CREATE TRIGGER IF NOT EXISTS ${table}_sync_ins AFTER INSERT ON $table
WHEN $_captureOnSql
BEGIN
  UPDATE $table
     SET uid           = COALESCE(NEW.uid, $_uuidV4Sql),
         updated_at    = CAST(strftime('%s','now') AS INTEGER),
         changed_at_ms = $_nowMsSql,
         local_seq     = $_nextSeqSql,
         sync_state    = ${_dirtyExpr(table)}
   WHERE id = NEW.id;
  $_bumpSeqSql;
END''';

/// DELETE sonrası: mezar taşı bırak. Yalnız sunucuya gitmiş olabilecek satırlar
/// (kullanılmamış seed katalog satırı iz bırakmaz). Yabancı anahtar zinciriyle
/// silinen satırlar da bu tetikleyiciyi çalıştırır → seans silinince setlerin
/// mezar taşları da oluşur.
String createDeleteTriggerSql(String table) => '''
CREATE TRIGGER IF NOT EXISTS ${table}_sync_del AFTER DELETE ON $table
WHEN $_captureOnSql AND OLD.uid IS NOT NULL
     AND (OLD.server_rev IS NOT NULL OR OLD.user_id IS NOT NULL)
BEGIN
  INSERT INTO sync_tombstones (table_name, uid, changed_at_ms, local_seq, sync_state)
  VALUES ('$table', OLD.uid, $_nowMsSql, $_nextSeqSql, 1);
  $_bumpSeqSql;
END''';

/// UPDATE sonrası: zaman damgala, (uygunsa) kuyruğa al.
///
/// **Döngü koruması:** `sync_state` DEĞİŞTİYSE bu yazma senkron katmanına
/// aittir (temiz işaretleme ya da tembel kuyruğa alma) → tetikleyici çalışmaz.
/// Çalışsaydı satır anında yeniden kirlenir ve senkron hiç bitmezdi.
String createUpdateTriggerSql(String table) => '''
CREATE TRIGGER IF NOT EXISTS ${table}_sync_upd AFTER UPDATE ON $table
WHEN NEW.sync_state IS OLD.sync_state AND $_captureOnSql
BEGIN
  UPDATE $table
     SET uid           = COALESCE(NEW.uid, $_uuidV4Sql),
         updated_at    = CAST(strftime('%s','now') AS INTEGER),
         changed_at_ms = $_nowMsSql,
         local_seq     = $_nextSeqSql,
         sync_state    = ${_dirtyExpr(table)}
   WHERE id = NEW.id;
  $_bumpSeqSql;
END''';

/// Katalog satırını elle kuyruğa alır — kullanıcı onu bir sette/öğünde
/// kullandığında senkron katmanı çağırır (tembel katalog senkronu).
String queueCatalogRowSql(String table) =>
    'UPDATE $table SET sync_state = 1 WHERE id = ? AND sync_state = 0';

/// Tetikleyicileri geçici KALDIRMAK için (docs/18 §6.4 — pull).
///
/// **Neden pull sırasında kaldırılır?** Tetikleyiciler her INSERT/UPDATE'te
/// `updated_at`'i `now()` yapar ve satırı kuyruğa (`sync_state = 1`) alır. Ama
/// pull, sunucunun **yetkili** verisini indiriyor: sunucunun `updated_at`'i
/// korunmalı (çakışma kuralı ona bakar) ve inen satır kuyruğa GİRMEMELİ (yoksa
/// hemen geri gönderilir → sonsuz yankı). Pull kendi yazımlarını yaparken
/// tetikleyiciler kapalı olur, bitince `AppDatabase`'deki tek kaynaktan
/// (`createInsertTriggerSql`/`createUpdateTriggerSql`) geri kurulur.
String dropInsertTriggerSql(String table) =>
    'DROP TRIGGER IF EXISTS ${table}_sync_ins';
String dropUpdateTriggerSql(String table) =>
    'DROP TRIGGER IF EXISTS ${table}_sync_upd';
String dropDeleteTriggerSql(String table) =>
    'DROP TRIGGER IF EXISTS ${table}_sync_del';

/// Yerel integer yabancı anahtar kolonu → sunucudaki `*_uid` kolon adı.
/// Gönderimde `_stripId` + `_uid` ile üretilen adla AYNI olmalı (docs/18 §4):
/// `session_id` → `session_uid`, `food_id` → `food_uid`.
String serverFkColumn(String localFkColumn) {
  final base = localFkColumn.endsWith('_id')
      ? localFkColumn.substring(0, localFkColumn.length - 3)
      : localFkColumn;
  return '${base}_uid';
}
