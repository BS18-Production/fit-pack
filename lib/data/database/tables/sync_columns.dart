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
