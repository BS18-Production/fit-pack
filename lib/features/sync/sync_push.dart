import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import '../../data/database/tables/sync_columns.dart';
import 'sync_apply.dart';
import 'sync_controller.dart' show syncLog;

/// Bir gönderim turunun sonucu — arayüz ve testler bunu okur.
class PushResult {
  /// Sunucunun ONAYLADIĞI ve temiz işaretlenen satır sayısı.
  final int pushed;

  /// Gönderilemeyen satır sayısı (kuyrukta kaldı, sonra tekrar denenecek).
  final int failed;

  /// Sunucunun REDDETTİĞİ satır sayısı — sunucudaki sürüm daha yeniydi ya da
  /// o kimlik silinmişti. Bunlar hata DEĞİLDİR: satır sunucununkiyle
  /// değiştirilip temizlenir, tekrar gönderilmez (docs/20 §5.1 adım 5).
  final int rejected;

  /// Sunucuya iletilen **silme** sayısı (mezar taşı — docs/20 §5.3).
  final int deleted;

  /// İlk hata — hata ayıklama/görüntüleme için.
  final Object? error;

  const PushResult({
    this.pushed = 0,
    this.failed = 0,
    this.rejected = 0,
    this.deleted = 0,
    this.error,
  });

  bool get hasWork => pushed > 0 || failed > 0 || rejected > 0 || deleted > 0;
  bool get ok => failed == 0 && error == null;
}

/// Sunucunun KABUL ettiği bir satır (docs/20 §5.1 adım 4).
class AcceptedRow {
  final String uid;

  /// Sunucunun bu yazmaya verdiği sürüm numarası. Yerele yazılır; çekme
  /// imleci ve "bu satırın sunucudaki hali hangisi" sorusu buna bakar.
  final int serverRev;

  const AcceptedRow(this.uid, this.serverRev);
}

/// Sunucuya yazma yüzeyi. Gerçek uygulaması Supabase'i çağırır; testler bunu
/// taklit ederek ağ olmadan arıza senaryolarını (kopan bağlantı, çift
/// gönderim, ret) çalıştırır (docs/18 §10).
abstract class SyncRemote {
  /// Satırları `(user_id, uid)` çakışmasına göre upsert eder ve **sunucunun
  /// KABUL ETTİKLERİNİ** döndürür (docs/20 §5.1).
  ///
  /// Dönen listede olmayan satır **reddedilmiştir**: sunucudaki sürüm daha
  /// yeni (ya da o kimlik silinmiş). Sunucudaki `sync_guard` tetikleyicisi
  /// reddi `RETURNING`'den düşürerek bildirir — ayrı bir hata kodu yoktur.
  ///
  /// Hata fırlatırsa satırlar kuyrukta KALIR.
  Future<List<AcceptedRow>> upsert(
      String table, List<Map<String, Object?>> rows);

  /// Sürümü [sinceRev]'den BÜYÜK satırları, sürüm sırasına göre, en çok
  /// [limit] tane çeker (docs/20 §6.1). İmleç tabanlı sayfalama: sayfalar
  /// arasında yeni satır eklense de satır atlanmaz ya da iki kez gelmez.
  ///
  /// RLS "own rows" politikası sunucuda süzer; yine de `userId` ile
  /// filtreleriz (katalog tablolarında kullanıcının kendi + kullandığı
  /// satırlar için).
  Future<List<Map<String, Object?>>> fetchSince(
    String table,
    String userId,
    int sinceRev,
    int limit,
  );

  /// Belirli kimliklerin sunucudaki hâlini çeker — **reddedilen gönderimler**
  /// için (docs/20 §5.1 adım 5). Reddedilen satır sunucudakiyle değiştirilir,
  /// yoksa sonsuza kadar tekrar gönderilmeye çalışılır.
  Future<List<Map<String, Object?>>> fetchByUids(
    String table,
    String userId,
    List<String> uids,
  );

  /// Verilen kimlikleri sunucuda **gerçekten siler** ve silinenleri döndürür
  /// (docs/20 §5.3). Sunucu satırın yerine yalnız bir işaret bırakır; öteki
  /// cihaz silmeyi o işaretten öğrenir.
  ///
  /// Dönen listede olmayan kimlik "sunucuda zaten yoktu" demektir — hata
  /// değil: hiç gönderilmemiş bir satırın silinmesi sunucuya bilgi taşımaz.
  Future<List<String>> deleteRows(
    String table,
    String userId,
    List<String> uids,
  );
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

  /// Reddedilen satırların sunucudaki hâlini yerele yazan ortak kural
  /// (docs/20 §6.2). Çekme ile AYNI nesne/kural kullanılır.
  final SyncApply apply;

  /// Tek seferde gönderilen satır sayısı — büyük kuyruklarda istek şişmesin.
  final int batchSize;

  SyncPush(this.db, this.remote, {SyncApply? apply, this.batchSize = 200})
      : apply = apply ?? SyncApply(db);

  /// Bekleyen her şeyi gönderir. `userId` = Supabase `auth.uid()`.
  ///
  /// Oturum yoksa çağrılmaz — satırlar kuyrukta bekler, girişte gönderilir.
  Future<PushResult> pushAll({required String userId}) async {
    var pushed = 0;
    var failed = 0;
    var rejected = 0;
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

    // Ön geçiş 1b: ZAMAN DAMGASIZ satırları onar. v9 göçü `uid`'i backfill
    // etti ama `updated_at`'i boş bıraktı; sunucudaki kolon NOT NULL olduğu
    // için o satırlar `23502` ile reddediliyordu. Yalnız Samet'in v9-öncesi
    // kendi satırlarını etkiler, yeni kullanıcıda olmaz (docs/18 §6.9). Yalnız
    // NULL olanlara dokunur → tekrar çalıştırmak güvenli.
    await _repairMissingTimestamps();

    // Ön geçiş 2: bekleyen satırların işaret ettiği KATALOG satırlarını kuyruğa
    // al (tembel katalog senkronu — docs/18 §3.2 seçenek A). Bunu yapmazsak
    // sunucudaki set, orada olmayan bir harekete referans verir.
    await _queueReferencedCatalogRows();

    // Bağımlılık sırası: referans verilen tablo önce gider.
    for (final table in syncPushOrder) {
      try {
        final r = await _pushTable(table, userId);
        pushed += r.pushed;
        rejected += r.rejected;
      } catch (e, st) {
        firstError ??= e;
        failed += await _pendingCount(table);
        syncLog('$table gönderilemedi: $e\n$st', error: e);
        // Sonraki tablolar bu tabloya referans verebilir → tur burada biter,
        // kuyruk korunur, bir sonraki denemede baştan alınır.
        break;
      }
    }

    // MEZAR TAŞLARI EN SONA. Aynı turda "ekle + sil" olan satır sunucuda önce
    // oluşup sonra silinmiş olur — tersi sırada silme boşa giderdi (satır
    // henüz sunucuda yok) ve ardından ekleme onu diriltirdi.
    //
    // Yazmalar hata verdiyse gönderilmez: eksik ebeveynle silme göndermek
    // sunucuda tutarsız ara durum bırakır. Mezar taşları kuyrukta kalır.
    var deleted = 0;
    if (firstError == null) {
      try {
        deleted = await _pushTombstones(userId);
      } catch (e, st) {
        firstError ??= e;
        syncLog('mezar taşları gönderilemedi: $e\n$st', error: e);
      }
    }

    return PushResult(
      pushed: pushed,
      failed: failed,
      rejected: rejected,
      deleted: deleted,
      error: firstError,
    );
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

  /// `updated_at`'i olmayan satırlara şimdiki zamanı yazar. Zaman damgası
  /// olmayan satır sunucunun NOT NULL kolonunda `23502` ile reddedilir — ve
  /// çakışma kuralı (en son yazan kazanır) bu damgaya bakar (docs/18 §6.9).
  Future<void> _repairMissingTimestamps() async {
    for (final table in syncPushOrder) {
      final missing = await db
          .customSelect(
              'SELECT COUNT(*) c FROM $table WHERE updated_at IS NULL')
          .getSingle();
      final count = missing.read<int>('c');
      if (count == 0) continue;
      syncLog('$table: $count satırın zaman damgası yok → şimdiye ayarlanıyor');
      await db.customStatement(backfillUpdatedAtSql(table));
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

  /// Tek tabloyu gönderir, onaylananları temiz işaretler, reddedilenleri
  /// sunucununkiyle değiştirir. Hata fırlatırsa satırlar kuyrukta kalır.
  Future<_TablePush> _pushTable(String table, String userId) async {
    var total = 0;
    var rejected = 0;
    while (true) {
      final rows = await db
          .customSelect(
            'SELECT * FROM $table WHERE sync_state = 1 ORDER BY id LIMIT $batchSize',
          )
          .get();
      if (rows.isEmpty) return _TablePush(total, rejected);

      final payload = <Map<String, Object?>>[];
      // uid → o satırı okuduğumuz andaki `local_seq` (cihaz sayacı). Temiz
      // işaretlerken karşılaştırılır: değişmişse kullanıcı arada satırı
      // güncellemiştir, dokunmayız (yoksa o değişiklik sessizce kaybolur).
      //
      // Eskiden `updated_at` karşılaştırılıyordu; saniye çözünürlüklü olduğu
      // için gönderimle AYNI saniyedeki düzenleme fark edilmiyor ve
      // kayboluyordu (docs/20 §1 hata #3, S-1).
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
        stamps[json['uid']! as String] = row.data['local_seq'];
      }
      if (skipped > 0) {
        syncLog('$table: $skipped satır atlandı (kimlik/referans eksik) '
            '→ kuyrukta bekliyor');
      }
      if (payload.isEmpty) return _TablePush(total, rejected);

      // ⚠️ Sunucu onayı burada. Hata fırlarsa aşağıya inilmez → temiz
      // işaretleme YAPILMAZ, satırlar kuyrukta kalır.
      syncLog('$table → ${payload.length} satır gönderiliyor');
      final accepted = await remote.upsert(table, payload);

      // KABUL EDİLENLER: temiz işaretle, sunucu sürümünü yaz.
      await _markClean(table, accepted, stamps, userId);
      total += accepted.length;

      // REDDEDİLENLER (dönmeyenler): sunucudaki sürüm daha yeni ya da o kimlik
      // silinmiş. Sunucudaki hâlini indirip uygula → satır temizlenir ve bir
      // daha gönderilmez. Bu adım olmadan satır sonsuza kadar kuyrukta kalır
      // ve her turda boşuna gönderilir (docs/20 §5.1 adım 5).
      final acceptedUids = accepted.map((a) => a.uid).toSet();
      final rejectedUids = stamps.keys
          .where((uid) => !acceptedUids.contains(uid))
          .toList();
      if (rejectedUids.isNotEmpty) {
        syncLog('$table: ${rejectedUids.length} satır reddedildi '
            '(sunucu daha yeni) → sunucudaki sürüm alınıyor');
        rejected += await _resolveRejected(table, rejectedUids, stamps, userId);
      }

      // Bu turda hiçbir satır ilerlemediyse dur: aksi halde aynı sayfayı
      // sonsuza kadar okuruz (çözülemeyen ret + dolu kuyruk).
      if (accepted.isEmpty && rejectedUids.isEmpty) {
        return _TablePush(total, rejected);
      }
      if (rows.length < batchSize) return _TablePush(total, rejected);
    }
  }

  /// Mezar taşlarını (yerel silmeleri) sunucuya iletir — docs/20 §5.3.
  ///
  /// **Tablo sırası TERS:** çocuk önce. `workout_sets` silinmeden
  /// `workout_sessions` silinirse sunucudaki zincirleme silme setleri de
  /// götürür; sorun değil ama o zaman setlerin işaretleri sunucu tarafında
  /// oluşur ve bu cihazın mezar taşları boşa gider. Çocuğu önce göndermek
  /// niyeti olduğu gibi aktarır.
  Future<int> _pushTombstones(String userId) async {
    var total = 0;
    for (final table in syncPushOrder.reversed) {
      while (true) {
        final rows = await db
            .customSelect(
              'SELECT id, uid FROM sync_tombstones '
              'WHERE table_name = ? AND sync_state = 1 '
              'ORDER BY id LIMIT $batchSize',
              variables: [Variable(table)],
            )
            .get();
        if (rows.isEmpty) break;

        final uids = [for (final r in rows) r.data['uid'] as String];
        syncLog('$table → ${uids.length} silme gönderiliyor');

        // ⚠️ Sunucu onayı burada. Hata fırlarsa aşağıya inilmez → mezar
        // taşları kuyrukta kalır ve bir sonraki turda tekrar denenir.
        final silinen = await remote.deleteRows(table, userId, uids);
        total += silinen.length;

        // Gönderdiğimiz HER kimliğin mezar taşı kalkar — dönmeyenler
        // "sunucuda zaten yoktu" demektir (hiç gönderilmemiş satır).
        // Bırakılsalardı sonsuza kadar tekrar gönderilirlerdi.
        final ids = [for (final r in rows) r.data['id'] as int];
        await db.customStatement(
          'DELETE FROM sync_tombstones WHERE id IN '
          '(${List.filled(ids.length, '?').join(', ')})',
          ids,
        );

        if (rows.length < batchSize) break;
      }
    }
    return total;
  }

  /// Reddedilen satırların sunucudaki hâlini indirip yerele uygular.
  ///
  /// Sunucuda satır YOKSA (silinmiş kimlik — Aşama 5) yerel satır kuyruktan
  /// çıkarılır ama SİLİNMEZ: senkron yerel veriyi asla silmez (kural 4).
  /// Silmeyi taşıyan mekanizma mezar taşlarıdır, Aşama 5'te gelir.
  Future<int> _resolveRejected(
    String table,
    List<String> uids,
    Map<String, Object?> stamps,
    String userId,
  ) async {
    final serverRows = await remote.fetchByUids(table, userId, uids);
    final byUid = {
      for (final r in serverRows)
        if (r['uid'] is String) r['uid'] as String: r,
    };

    var resolved = 0;
    final types = apply.columnTypes(table);
    await apply.withCaptureOff(() => db.transaction(() async {
          for (final uid in uids) {
            final server = byUid[uid];
            if (server != null) {
              await apply.applyServerRow(table, server, types: types);
            }
            // Temizle — ama YALNIZ gönderdiğimiz sürüm hâlâ duruyorsa.
            // `local_seq` değiştiyse kullanıcı arada satırı yeniden düzenledi;
            // o düzenleme gönderilmeli, kuyrukta kalsın.
            await db.customStatement(
              'UPDATE $table SET sync_state = 0, user_id = ? '
              'WHERE uid = ? AND sync_state = 1 AND local_seq IS ?',
              [userId, uid, stamps[uid]],
            );
            resolved++;
          }
        }));
    return resolved;
  }

  /// Yalnız **sunucunun kabul ettiği** ve gönderdiğimiz sürümü temiz
  /// işaretler. `local_seq` değiştiyse satır gönderimden SONRA (ya da gönderim
  /// SÜRERKEN) düzenlenmiştir → kuyrukta bırakılır, yoksa o düzenleme sessizce
  /// kaybolurdu.
  ///
  /// `server_rev` yerele yazılır: satırın sunucudaki hangi sürüme karşılık
  /// geldiği cihazda bilinir.
  ///
  /// `user_id` de yerele yazılır: (a) satırın kime ait olduğu cihazda bilinir
  /// → hesap değişimi tespiti (docs/18 §5.1 Kural 3), (b) senkron edilmiş
  /// katalog satırı bundan sonra düzenlendiğinde tekrar kuyruğa girer.
  Future<void> _markClean(
    String table,
    List<AcceptedRow> accepted,
    Map<String, Object?> stamps,
    String userId,
  ) async {
    if (accepted.isEmpty) return;
    // Temiz işaretleme de bir yazmadır; tetikleyici `sync_state` değişimini
    // zaten görmezden gelir, ama `server_rev` yazması onu uyandırmasın diye
    // bayrak kapatılır (docs/20 K-4).
    await apply.withCaptureOff(() => db.transaction(() async {
          for (final row in accepted) {
            await db.customStatement(
              'UPDATE $table SET sync_state = 0, user_id = ?, server_rev = ? '
              'WHERE uid = ? AND sync_state = 1 AND local_seq IS ?',
              [userId, row.serverRev, row.uid, stamps[row.uid]],
            );
          }
        }));
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

/// Tek tablonun gönderim sonucu — kabul edilen ve reddedilip çözülen sayısı.
class _TablePush {
  final int pushed;
  final int rejected;
  const _TablePush(this.pushed, this.rejected);
}
