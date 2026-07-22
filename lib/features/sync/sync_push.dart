import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import '../../data/database/tables/sync_columns.dart';
import 'sync_controller.dart' show syncLog;

/// Bir gönderim turunun sonucu — arayüz ve testler bunu okur.
class PushResult {
  /// Sunucunun ONAYLADIĞI ve temiz işaretlenen satır sayısı.
  final int pushed;

  /// Gönderilemeyen satır sayısı (kuyrukta kaldı, sonra tekrar denenecek).
  final int failed;

  /// İlk hata — hata ayıklama/görüntüleme için.
  final Object? error;

  const PushResult({this.pushed = 0, this.failed = 0, this.error});

  bool get hasWork => pushed > 0 || failed > 0;
  bool get ok => failed == 0 && error == null;
}

/// Sunucuya yazma yüzeyi. Gerçek uygulaması Supabase'i çağırır; testler bunu
/// taklit ederek ağ olmadan arıza senaryolarını (kopan bağlantı, çift
/// gönderim) çalıştırır (docs/18 §10).
abstract class SyncRemote {
  /// Satırları `uid` çakışmasına göre upsert eder. **Dönmesi = sunucu onayı.**
  /// Hata fırlatırsa satırlar kuyrukta KALIR.
  Future<void> upsert(String table, List<Map<String, Object?>> rows);
}

/// Giden kutusu gönderim hattı (docs/18 §6).
///
/// **Değişmez kurallar** — hepsi veri kaybına karşı:
/// 1. Kuyruk diskte durur (`sync_state` kolonu) → uygulama ölse de kalır
/// 2. **Sunucu onayı gelmeden** hiçbir satır temiz işaretlenmez
/// 3. `uid` istemcide üretilir → aynı satır iki kez gönderilse sunucuda tek
///    satır olur (upsert + uid çakışması), çift kayıt oluşmaz
/// 4. Senkron **yerel satırı asla silmez** — yalnız `sync_state` bayrağını çevirir
/// 5. Gönderim sırasında satır değiştiyse temiz işaretlenmez (yarış koruması)
class SyncPush {
  final AppDatabase db;
  final SyncRemote remote;

  /// Tek seferde gönderilen satır sayısı — büyük kuyruklarda istek şişmesin.
  final int batchSize;

  SyncPush(this.db, this.remote, {this.batchSize = 200});

  /// Bekleyen her şeyi gönderir. `userId` = Supabase `auth.uid()`.
  ///
  /// Oturum yoksa çağrılmaz — satırlar kuyrukta bekler, girişte gönderilir.
  Future<PushResult> pushAll({required String userId}) async {
    var pushed = 0;
    var failed = 0;
    Object? firstError;

    // Ön geçiş 1: KİMLİKSİZ satırları onar. Tetikleyiciler (v10) her yeni
    // satıra `uid` verir, ama v10 ÖNCESİ oluşmuş satırlarda NULL kalmış
    // olabilir (canlıda tam bunu yaşadık: seed hareketleri uid'siz kalınca
    // onlara bakan 6 set de sessizce gönderilemedi).
    //
    // Kendi kendini onarır ve tekrar çalıştırmak güvenlidir — yalnız NULL
    // olanlara dokunur. Katalog satırlarında tetikleyici `sync_state`'i
    // sıfırlayabilir; sorun değil, sıradaki adım referans verilenleri
    // yeniden kuyruğa alıyor.
    await _repairMissingUids();

    // Ön geçiş 2: bekleyen satırların işaret ettiği KATALOG satırlarını kuyruğa
    // al (tembel katalog senkronu — docs/18 §3.2 seçenek A). Bunu yapmazsak
    // sunucudaki set, orada olmayan bir harekete referans verir.
    await _queueReferencedCatalogRows();

    // Bağımlılık sırası: referans verilen tablo önce gider.
    for (final table in syncPushOrder) {
      try {
        pushed += await _pushTable(table, userId);
      } catch (e, st) {
        firstError ??= e;
        failed += await _pendingCount(table);
        syncLog('$table gönderilemedi: $e\n$st', error: e);
        // Sonraki tablolar bu tabloya referans verebilir → tur burada biter,
        // kuyruk korunur, bir sonraki denemede baştan alınır.
        break;
      }
    }

    return PushResult(pushed: pushed, failed: failed, error: firstError);
  }

  /// `uid`'i olmayan satırlara kimlik üretir. Kimliksiz satır gönderilemez —
  /// ve daha kötüsü, ona referans veren her satır da gönderilemez.
  Future<void> _repairMissingUids() async {
    for (final table in syncPushOrder) {
      final missing = await db
          .customSelect('SELECT COUNT(*) c FROM $table WHERE uid IS NULL')
          .getSingle();
      final count = missing.read<int>('c');
      if (count == 0) continue;
      syncLog('$table: $count satırın kimliği yok → üretiliyor');
      await db.customStatement(backfillUidSql(table));
    }
  }

  /// Bekleyen satırların referans verdiği katalog satırlarını kuyruğa alır.
  Future<void> _queueReferencedCatalogRows() async {
    for (final entry in syncForeignKeys.entries) {
      final child = entry.key;
      for (final fk in entry.value.entries) {
        final parent = fk.value;
        if (!catalogTableNames.contains(parent)) continue;
        // Bekleyen çocuk satırların işaret ettiği, henüz temiz olan katalog
        // satırlarını kuyruğa al.
        await db.customStatement(
          'UPDATE $parent SET sync_state = 1 '
          'WHERE sync_state = 0 AND id IN ('
          '  SELECT ${fk.key} FROM $child '
          '   WHERE sync_state = 1 AND ${fk.key} IS NOT NULL)',
        );
      }
    }
  }

  Future<int> _pendingCount(String table) async {
    final r = await db
        .customSelect('SELECT COUNT(*) c FROM $table WHERE sync_state = 1')
        .getSingle();
    return r.read<int>('c');
  }

  /// Tek tabloyu gönderir, onaylananları temiz işaretler, gönderilen sayısını
  /// döndürür. Hata fırlatırsa satırlar kuyrukta kalır.
  Future<int> _pushTable(String table, String userId) async {
    var total = 0;
    while (true) {
      final rows = await db
          .customSelect(
            'SELECT * FROM $table WHERE sync_state = 1 ORDER BY id LIMIT $batchSize',
          )
          .get();
      if (rows.isEmpty) return total;

      final payload = <Map<String, Object?>>[];
      // uid → o satırı okuduğumuz andaki updated_at. Temiz işaretlerken
      // karşılaştırılır: değişmişse kullanıcı arada satırı güncellemiştir,
      // dokunmayız (yoksa o değişiklik sessizce kaybolur).
      final stamps = <String, Object?>{};

      var skipped = 0;
      for (final row in rows) {
        final json = await _rowToJson(table, row.data, userId);
        if (json == null) {
          // Çevrilemedi (kimlik yok ya da ebeveyn referansı çözülemedi) →
          // kuyrukta bekletilir. SESSİZ BIRAKMA: canlıda 13 satır böyle
          // atlandı ve "gönderilen 0, kalan 0" yüzünden sorun görünmedi.
          skipped++;
          continue;
        }
        payload.add(json);
        stamps[json['uid']! as String] = row.data['updated_at'];
      }
      if (skipped > 0) {
        syncLog('$table: $skipped satır atlandı (kimlik/referans eksik) '
            '→ kuyrukta bekliyor');
      }
      if (payload.isEmpty) return total;

      // ⚠️ Sunucu onayı burada. Hata fırlarsa aşağıya inilmez → temiz
      // işaretleme YAPILMAZ, satırlar kuyrukta kalır.
      syncLog('$table → ${payload.length} satır gönderiliyor');
      await remote.upsert(table, payload);

      await _markClean(table, stamps, userId);
      total += payload.length;
      if (rows.length < batchSize) return total;
    }
  }

  /// Yalnız gönderdiğimiz sürümü temiz işaretler. `updated_at` değiştiyse
  /// satır gönderimden SONRA düzenlenmiştir → kuyrukta bırakılır (yoksa o
  /// düzenleme sessizce kaybolurdu).
  ///
  /// `user_id` de yerele yazılır: (a) satırın kime ait olduğu cihazda bilinir
  /// → hesap değişimi tespiti (docs/18 §5.1 Kural 3), (b) senkron edilmiş
  /// katalog satırı bundan sonra düzenlendiğinde tekrar kuyruğa girer.
  Future<void> _markClean(
      String table, Map<String, Object?> stamps, String userId) async {
    await db.transaction(() async {
      for (final e in stamps.entries) {
        await db.customStatement(
          'UPDATE $table SET sync_state = 0, user_id = ? '
          'WHERE uid = ? AND sync_state = 1 AND updated_at IS ?',
          [userId, e.key, e.value],
        );
      }
    });
  }

  /// Yerel satırı sunucu JSON'una çevirir:
  /// - `id` ve `sync_state` düşer (yerele ait)
  /// - integer yabancı anahtarlar `*_uid`'e çevrilir
  /// - tarihler ISO 8601'e, boolean'lar true/false'a döner
  /// - `user_id` damgalanır
  ///
  /// Referans çözülemezse `null` döner (satır kuyrukta bekler) — sunucuya
  /// yarım referans göndermektense beklemek doğrudur.
  Future<Map<String, Object?>?> _rowToJson(
    String table,
    Map<String, Object?> data,
    String userId,
  ) async {
    final info = db.allTables.firstWhere((t) => t.actualTableName == table);
    final types = {for (final c in info.$columns) c.name: c.type};
    final fks = syncForeignKeys[table] ?? const {};

    final out = <String, Object?>{};
    for (final entry in data.entries) {
      final col = entry.key;
      if (localOnlyColumns.contains(col)) continue;

      if (fks.containsKey(col)) {
        final localId = entry.value;
        if (localId == null) {
          out['${_stripId(col)}_uid'] = null;
          continue;
        }
        final uid = await _uidOf(fks[col]!, localId as int);
        if (uid == null) return null; // ebeveyn henüz yok → beklet
        out['${_stripId(col)}_uid'] = uid;
        continue;
      }

      out[col] = _encode(entry.value, types[col]);
    }

    // Sahiplik her zaman gönderim anında damgalanır — RLS bunu doğrular.
    out['user_id'] = userId;
    if (out['uid'] == null) return null; // tetikleyici doldurmalıydı
    return out;
  }

  static String _stripId(String col) =>
      col.endsWith('_id') ? col.substring(0, col.length - 3) : col;

  Future<String?> _uidOf(String table, int localId) async {
    final r = await db
        .customSelect('SELECT uid FROM $table WHERE id = ?',
            variables: [Variable(localId)])
        .get();
    if (r.isEmpty) return null;
    return r.first.data['uid'] as String?;
  }

  /// SQLite değerini Postgres'in beklediği biçime çevirir.
  /// `type` drift'in kolon tipi (`DriftSqlType.bool` vb.) — sınıf adı sürümler
  /// arası değiştiği için `Object?` alıp değerle karşılaştırıyoruz.
  static Object? _encode(Object? value, Object? type) {
    if (value == null) return null;
    switch (type) {
      case DriftSqlType.bool:
        // SQLite 0/1 → Postgres boolean
        return value == 1 || value == true;
      case DriftSqlType.dateTime:
        // Drift tarihi unix saniye olarak tutar → timestamptz için ISO 8601.
        if (value is int) {
          return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
              .toIso8601String();
        }
        return value;
      default:
        return value;
    }
  }
}
