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
const localOnlyColumns = <String>{'id', 'sync_state'};

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

/// INSERT sonrası: `uid` yoksa üret, zaman damgala, (uygunsa) kuyruğa al.
String createInsertTriggerSql(String table) => '''
CREATE TRIGGER IF NOT EXISTS ${table}_sync_ins AFTER INSERT ON $table
BEGIN
  UPDATE $table
     SET uid        = COALESCE(NEW.uid, $_uuidV4Sql),
         updated_at = CAST(strftime('%s','now') AS INTEGER),
         sync_state = ${_dirtyExpr(table)}
   WHERE id = NEW.id;
END''';

/// UPDATE sonrası: zaman damgala, (uygunsa) kuyruğa al.
///
/// **Döngü koruması:** `sync_state` DEĞİŞTİYSE bu yazma senkron katmanına
/// aittir (temiz işaretleme ya da tembel kuyruğa alma) → tetikleyici çalışmaz.
/// Çalışsaydı satır anında yeniden kirlenir ve senkron hiç bitmezdi.
String createUpdateTriggerSql(String table) => '''
CREATE TRIGGER IF NOT EXISTS ${table}_sync_upd AFTER UPDATE ON $table
WHEN NEW.sync_state IS OLD.sync_state
BEGIN
  UPDATE $table
     SET uid        = COALESCE(NEW.uid, $_uuidV4Sql),
         updated_at = CAST(strftime('%s','now') AS INTEGER),
         sync_state = ${_dirtyExpr(table)}
   WHERE id = NEW.id;
END''';

/// Katalog satırını elle kuyruğa alır — kullanıcı onu bir sette/öğünde
/// kullandığında senkron katmanı çağırır (tembel katalog senkronu).
String queueCatalogRowSql(String table) =>
    'UPDATE $table SET sync_state = 1 WHERE id = ? AND sync_state = 0';
