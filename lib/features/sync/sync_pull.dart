import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/sync_meta_dao.dart';
import '../../data/database/tables/sync_columns.dart';
import 'sync_apply.dart';
import 'sync_controller.dart' show syncLog;
import 'sync_health.dart';
import 'sync_push.dart';

/// Bir çekme (pull) turunun sonucu — arayüz ve testler bunu okur.
class PullResult {
  /// Yerelde OLMAYIP sunucudan eklenen satır sayısı.
  final int inserted;

  /// Sunucu daha yeni olduğu için üstüne yazılan satır sayısı.
  final int updated;

  /// Yerel daha yeni ya da referansı çözülemediği için dokunulmayan satır.
  final int skipped;

  final Object? error;

  const PullResult({
    this.inserted = 0,
    this.updated = 0,
    this.skipped = 0,
    this.error,
  });

  bool get ok => error == null;
  int get changed => inserted + updated;

  PullResult operator +(PullResult o) => PullResult(
        inserted: inserted + o.inserted,
        updated: updated + o.updated,
        skipped: skipped + o.skipped,
        error: error ?? o.error,
      );
}

/// Çekme (pull) hattı — **sayfalı, artımlı, iki aşamalı** (docs/20 §6.1).
///
/// Girişte ve açılışta çalışır: sunucudaki kullanıcı verisini yerele indirir.
/// Böylece telefon değiştiren / uygulamayı yeniden kuran kullanıcı **verisini
/// geri alır** — gönderim (outbox) tek başına bunun yalnız yarısıydı.
///
/// **v1'e göre ne değişti:**
/// - **Artımlı:** her tablonun imleci (`server_rev`) senkron defterinde durur;
///   ikinci açılışta yalnız DEĞİŞENLER iner. Eskiden her açılışta her şey
///   indiriliyordu.
/// - **Sayfalı:** sayfa boyu 500. Sayfalama `server_rev` üzerinden
///   (anahtar tabanlı) — sayfalar arasında yeni satır eklense de satır
///   atlanmaz ya da iki kez gelmez (docs/20 §1 hata #5).
/// - **İki aşamalı:** ağ beklemesi veritabanına dokunmadan yapılır,
///   tetikleyiciler o sırada AÇIK kalır → çekme sürerken kullanıcının yazdığı
///   satır kuyruğa girer (hata #2).
/// - **Çakışma ölçüsü `changed_at_ms`** (milisaniye), `updated_at` değil.
class SyncPull {
  final AppDatabase db;
  final SyncRemote remote;
  final SyncApply apply;

  /// Sayfa boyu. 500 < PostgREST'in 1.000 sınırı → sunucu sessizce kesemez.
  final int pageSize;

  /// **İmleç payı** (docs/20 §12.1). İmleç, son görülen `server_rev`'den bu
  /// kadar geriye kaydırılarak saklanır.
  ///
  /// NEDEN: `server_rev` transaction'ın BAŞINDA (tetikleyicide) atanır ama
  /// satır ancak COMMIT'te görünür olur. İki gönderim üst üste binerse küçük
  /// numaralı satır, büyük numaralı satırdan SONRA görünebilir; imleç
  /// çoktan geçmişse o satır bir daha hiç inmez. Payla birlikte aynı aralık
  /// bir sonraki turda yeniden okunur. Tekrar indirme zararsızdır: uygulama
  /// kuralı `changed_at_ms` karşılaştırıp eskiyi atar (idempotent).
  final int cursorLag;

  /// Kendiliğinden tam uzlaştırma aralığı (docs/20 §12.1 ikinci katman).
  /// Haftada bir: bu veri boyutunda maliyeti birkaç yüz satır indirmek.
  final Duration fullPullInterval;

  /// Son başarılı çekme / kesinti kaydı ("Son yedekleme" satırı).
  final SyncHealth health;

  SyncPull(
    this.db,
    this.remote, {
    SyncApply? apply,
    SyncHealth? health,
    this.pageSize = 500,
    this.cursorLag = 1000,
    this.fullPullInterval = const Duration(days: 7),
  })  : apply = apply ?? SyncApply(db),
        health = health ?? SyncHealth(db);

  SyncMetaDao get _meta => SyncMetaDao(db);

  /// Sunucudaki bu kullanıcıya ait değişiklikleri indirir. Bağımlılık
  /// sırasıyla: referans verilen tablo (ebeveyn) önce iner ki çocuğun
  /// `*_uid`'i çözülsün.
  ///
  /// [full] verilirse imleçler yok sayılır ve her şey baştan okunur — docs/20
  /// §12.1'in ikinci katmanı (düzenli tam uzlaştırma). Yeni girişte de
  /// imleç zaten yoktur, yani ilk tur doğal olarak tamdır.
  ///
  /// Çağıran istemese de **[fullPullInterval] geçmişse tam tur yapılır**:
  /// ikinci katmanın kimsenin çağırmasına bağlı olmaması gerekir, yoksa
  /// yalnız kâğıt üstünde kalır.
  Future<PullResult> pullAll({
    required String userId,
    bool full = false,
  }) async {
    final vadesiGeldi = full || await _fullPullDue(userId);
    if (vadesiGeldi && !full) {
      syncLog('tam uzlaştırma zamanı (docs/20 §12.1) — imleçler yok sayılıyor');
    }
    full = vadesiGeldi;

    var result = const PullResult();

    // SİLME İŞARETLERİ ÖNCE (docs/20 §6.1). Sonra çekilseydi, aynı turda
    // silinmiş bir satırın canlı kopyası önce inip ekranda bir an görünür,
    // sonra kaybolurdu.
    try {
      result += await _pullDeletions(userId, full: full);
    } catch (e, st) {
      syncLog('silme işaretleri çekilemedi: $e\n$st', error: e);
      result += PullResult(error: e);
    }

    for (final table in result.ok ? syncRemoteTables : const <String>[]) {
      try {
        result += await _pullTable(table, userId, full: full);
      } catch (e, st) {
        syncLog('$table çekilemedi: $e\n$st', error: e);
        result += PullResult(error: e);
        // Bir tablo başarısızsa dur: sonraki tablolar buna referans verebilir,
        // yarım çekilmiş ebeveynle çocuk eklemek FK kırar.
        break;
      }
    }
    // Damga YALNIZ tur temiz bittiğinde yazılır: yarıda kalan tam tur
    // "yapıldı" sayılırsa atlanmış satır bir hafta daha görünmez kalır.
    if (full && result.ok) {
      await _meta.write(
        SyncMetaDao.fullPullKey(userId),
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
      );
    }

    // Sağlık kaydı (docs/20 §9): kim çağırırsa çağırsın burada yazılır.
    if (result.ok) {
      await health.recordPullOk();
    } else {
      await health.recordError(result.error!);
    }

    syncLog('pull bitti — eklenen ${result.inserted}, '
        'güncellenen ${result.updated}, atlanan ${result.skipped}',
        error: result.error);
    return result;
  }

  /// Tam uzlaştırmanın vakti geldi mi? İlk kez çekiliyorsa damga yoktur;
  /// o tur zaten imleçsiz (tam) olduğu için damgayı yazıp geçiyoruz.
  Future<bool> _fullPullDue(String userId) async {
    final raw = await _meta.read(SyncMetaDao.fullPullKey(userId));
    final last = int.tryParse(raw ?? '');
    if (last == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now - last >= fullPullInterval.inSeconds;
  }

  /// Bir tabloyu imleçten itibaren sayfa sayfa indirir ve uygular.
  ///
  /// Her sayfa için: **ağ aşaması** (veritabanına dokunulmaz, tetikleyiciler
  /// açık) → **uygulama aşaması** (kısa transaction, tetikleyiciler susturulmuş).
  /// Uygulama transaction'ı yarıda ölürse geri alınır: imleç eski değerde
  /// kalır, bir sonraki tur o sayfayı tekrar indirir (idempotent).
  Future<PullResult> _pullTable(
    String table,
    String userId, {
    required bool full,
  }) async {
    final cursorKey = SyncMetaDao.pullCursorKey(userId, table);
    var cursor = full ? 0 : (int.tryParse(await _meta.read(cursorKey) ?? '') ?? 0);

    var inserted = 0, updated = 0, skipped = 0;
    final types = apply.columnTypes(table);

    while (true) {
      // ── AĞ AŞAMASI — veritabanına dokunmaz, tetikleyiciler AÇIK ──
      final page = await remote.fetchSince(table, userId, cursor, pageSize);
      if (page.isEmpty) break;

      // Sunucu istediğimizden fazlasını döndürmemeli. Döndürüyorsa sayfalama
      // varsayımı çökmüştür (sessizce satır atlamaktansa durup bağıralım).
      if (page.length > pageSize) {
        throw StateError(
          '$table: sayfa boyu aşıldı — istenen $pageSize, gelen ${page.length}',
        );
      }

      final lastRev = _maxRev(page);
      syncLog('$table ← sunucudan ${page.length} satır '
          '(imleç $cursor → $lastRev)');

      // ── UYGULAMA AŞAMASI — kısa transaction, tetikleyiciler susturulmuş ──
      await apply.withCaptureOff(() => db.transaction(() async {
            for (final server in page) {
              // Satır başına ayrı kayıt noktası: tek bozuk satır (ör. yerelde
              // NOT NULL olan alanı boş gelen) sayfanın geri kalanını geri
              // aldırmasın. Atlanan satır haftalık tam uzlaştırmada yeniden
              // denenir (docs/20 §12.1).
              final sonuc = await _isolated(
                  () => apply.applyServerRow(table, server, types: types),
                  '$table/${server['uid']}');
              switch (sonuc) {
                case ApplyOutcome.inserted:
                  inserted++;
                case ApplyOutcome.updated:
                  updated++;
                case ApplyOutcome.skipped || null:
                  skipped++;
              }
            }
            // İmleç sayfayla AYNI transaction'da ilerler: ikisi ayrı olsaydı
            // arada ölüm imleci veriden ileri bırakır ve o sayfa kaybolurdu.
            //
            // Yalnız İLERİ yazılır. Sürümsüz satır gelirse `lastRev` 0 olur;
            // onu yazmak imleci sıfırlayıp her açılışta tam çekmeye döndürürdü.
            if (lastRev > cursor) {
              await _meta.write(cursorKey, _laggedCursor(lastRev).toString());
            }
          }));

      if (lastRev <= cursor) {
        // Sunucu ilerlemedi (sürümsüz satır ya da bozuk sıralama) — sonsuz
        // döngüye girmektense dur. Sayfa yine de uygulandı, veri kaybı yok.
        syncLog('$table: imleç ilerlemedi ($cursor), sayfalama durduruldu');
        break;
      }
      cursor = lastRev;

      if (page.length < pageSize) break; // son sayfa
    }

    return PullResult(inserted: inserted, updated: updated, skipped: skipped);
  }

  /// Sunucudaki silme işaretlerini indirip yerele uygular (docs/20 §5.3).
  ///
  /// İşaret yalnız `table_name` + `uid` taşır — silinen kaydın içeriği
  /// sunucuda tutulmaz. Yerelde o satır varsa **silinir**; bekleyen düzenlemesi
  /// olsa bile, çünkü silme her zaman kazanır (K-3).
  ///
  /// Silme `capture = 0` ile yapılır: yoksa yerel tetikleyici yeni bir mezar
  /// taşı üretir ve silme sunucuya geri yankılanır.
  Future<PullResult> _pullDeletions(String userId, {required bool full}) async {
    final cursorKey = SyncMetaDao.pullCursorKey(userId, syncDeletedTable);
    var cursor =
        full ? 0 : (int.tryParse(await _meta.read(cursorKey) ?? '') ?? 0);
    var applied = 0;
    // O an uygulanamayan işaretler (çoğunlukla: ebeveyn işareti geldi, çocuğu
    // başka sayfada ve henüz yerelde). Sayfalar bitince yeniden denenir.
    final ertelenen = <(String, String)>[];

    while (true) {
      final page =
          await remote.fetchSince(syncDeletedTable, userId, cursor, pageSize);
      if (page.isEmpty) break;
      if (page.length > pageSize) {
        throw StateError('$syncDeletedTable: sayfa boyu aşıldı — '
            'istenen $pageSize, gelen ${page.length}');
      }

      final lastRev = _maxRev(page);
      syncLog('$syncDeletedTable ← ${page.length} silme işareti '
          '(imleç $cursor → $lastRev)');

      // ÇOCUK ÖNCE uygula. Sunucu zincirleme silmede EBEVEYNİ önce damgalar
      // (seans server_rev 136, seti 137); yerelde aynı sırayla silmek
      // `workout_sets.session_id` kısıtını patlatır ve — hepsi tek
      // transaction olduğu için — BÜTÜN çekmeyi düşürür. Cihazda ölçüldü
      // (2026-09-23): "FOREIGN KEY constraint failed (787)", pull 0 satırla
      // bitti ve her turda yeniden düştü. Gönderim tarafı bu kuralı zaten
      // uyguluyordu (docs/20 §5.3 adım 1), çekme tarafı uygulamıyordu.
      final sirali = [...page]
        ..sort((a, b) => _silmeSirasi(b) - _silmeSirasi(a));

      await apply.withCaptureOff(() => db.transaction(() async {
            for (final mark in sirali) {
              final table = mark['table_name'];
              final uid = mark['uid'];
              if (table is! String || uid is! String) continue;
              // Bilmediğimiz bir tablo adı geldiyse dokunma: ham adı SQL'e
              // koymak enjeksiyon kapısı olurdu.
              if (!syncRemoteTables.contains(table)) continue;
              final n = await _isolated(() => _deleteLocal(table, uid),
                  '$table/$uid silme', quiet: true);
              if (n == null) {
                ertelenen.add((table, uid));
              } else {
                applied += n;
              }
            }
            if (lastRev > cursor) {
              await _meta.write(cursorKey, _laggedCursor(lastRev).toString());
            }
          }));

      if (lastRev <= cursor) break;
      cursor = lastRev;
      if (page.length < pageSize) break;
    }

    // İKİNCİ DENEME — bütün sayfalar uygulandıktan sonra. Farklı sayfalara
    // düşen ebeveyn–çocuk çiftinde çocuk artık silinmiştir. Yine olmayan
    // işaret atlanır: imleç zaten ilerledi, kilit yok; haftalık tam
    // uzlaştırma bütün işaretleri baştan okuyup yeniden dener.
    var atlanan = 0;
    if (ertelenen.isNotEmpty) {
      await apply.withCaptureOff(() => db.transaction(() async {
            for (final (table, uid) in ertelenen.reversed) {
              final n = await _isolated(
                  () => _deleteLocal(table, uid), '$table/$uid silme');
              if (n == null) {
                atlanan++;
              } else {
                applied += n;
              }
            }
          }));
    }

    // Silinen satırlar `updated` sayılır: kullanıcı açısından "veri değişti".
    return PullResult(updated: applied, skipped: atlanan);
  }

  /// [body]'yi iç içe transaction'da (SQLite kayıt noktası — SAVEPOINT)
  /// çalıştırır. Hata verirse YALNIZ o adım geri alınır ve `null` döner;
  /// dıştaki sayfa transaction'ı ve imleç yazımı sürer.
  ///
  /// Neden: aksi halde tek bozuk kayıt bütün sayfayı geri aldırır, imleç
  /// ilerlemez ve her turda aynı yerde düşülür — gönderimdeki "bozuk satırı
  /// ayır, kuyruk durmasın" kuralının (Aşama 7) çekme karşılığı.
  /// Cihazda yaşandı (2026-09-23, FK 787).
  Future<T?> _isolated<T>(
    Future<T> Function() body,
    String what, {
    bool quiet = false,
  }) async {
    try {
      return await db.transaction(body);
    } catch (e) {
      if (!quiet) syncLog('$what uygulanamadı, atlandı: $e', error: e);
      return null;
    }
  }

  /// Tablo ADINDAN Drift tanımını bulur. Mezar taşı yalnız `table_name`
  /// taşıdığı için gereklidir; bilinmeyen ad `null` döner (silme yine çalışır,
  /// yalnız akış bildirimi yapılmaz).
  TableInfo<Table, dynamic>? _tableInfo(String name) {
    for (final t in db.allTables) {
      if (t.actualTableName == name) return t;
    }
    return null;
  }

  /// Mezar taşının tablo sırası; bilinmeyen tablo en sona (-1).
  /// Büyükten küçüğe sıralanınca **çocuk önce** gelir.
  static int _silmeSirasi(Map<String, Object?> mark) {
    final t = mark['table_name'];
    return t is String ? syncRemoteTables.indexOf(t) : -1;
  }

  /// Yerel satırı siler ve bekleyen mezar taşını temizler.
  ///
  /// Mezar taşı temizliği şart: satır zaten sunucuda silinmiş, bizim silme
  /// isteğimiz gereksiz. Bırakılsaydı her turda boşuna `sync_delete`
  /// çağrılırdı.
  Future<int> _deleteLocal(String table, String uid) async {
    // `updates` ŞART: Drift'e hangi tablonun değiştiği söylenmezse
    // `tableUpdates()` tetiklenmez, `watchTables` ile beslenen ekran
    // sağlayıcıları uyanmaz ve kullanıcı silinmiş kaydı uygulamayı kapatıp
    // açana kadar görmeye devam eder. Cihazda ölçüldü (2026-09-23): satır
    // silindi ama ana sayfa "5 antrenman" demeye devam etti, yeniden
    // açılışta "4 antrenman" oldu.
    final info = _tableInfo(table);
    final silinen = await db.customUpdate(
      'DELETE FROM $table WHERE uid = ?',
      variables: [Variable(uid)],
      updates: info == null ? null : {info},
      updateKind: UpdateKind.delete,
    );
    await db.customStatement(
      'DELETE FROM sync_tombstones WHERE table_name = ? AND uid = ?',
      [table, uid],
    );
    return silinen;
  }

  /// Sayfadaki en büyük `server_rev`. Sunucu sıralı döndürür, yine de en
  /// büyüğü arıyoruz: sıralama bozulursa imleç geri gitmesin.
  int _maxRev(List<Map<String, Object?>> page) {
    var max = 0;
    for (final row in page) {
      final rev = row['server_rev'];
      if (rev is int && rev > max) max = rev;
    }
    return max;
  }

  /// Saklanacak imleç = son görülen sürüm − pay (0'ın altına inmez).
  int _laggedCursor(int lastRev) {
    final v = lastRev - cursorLag;
    return v < 0 ? 0 : v;
  }
}
