import 'package:fit_pack/features/sync/sync_push.dart';

/// **Sunucuyu taklit eden sahte uç** — Aşama 3'te yazılan `sync_guard`
/// tetikleyicisiyle aynı kuralları uygular (docs/20 §4.2, §5.2).
///
/// Neden tek bir ortak sahte: dört test dosyası ayrı ayrı sahte tutuyordu ve
/// hiçbiri çakışma kuralını bilmiyordu — yani "sunucu reddetti" durumu hiç
/// test edilmiyordu. Kural tek yerdeyse gerçek sunucudan ayrışması da tek
/// yerde fark edilir.
///
/// Uygulanan kurallar:
/// - Yazma, gelen `changed_at_ms` sunucudakinden **büyükse** kabul edilir.
///   Eşit ya da küçükse **reddedilir**: satır dönen listede yer almaz.
/// - Kabul edilen her yazma ortak bir sayaçtan yeni `server_rev` alır
///   (tablolar arası ortak dizi — çekme imleci tek sayı).
/// - Çekme `server_rev`'e göre sıralı ve sayfalıdır.
class FakeSyncServer implements SyncRemote {
  /// tablo → (uid → satır). Gerçek Supabase upsert davranışı.
  final Map<String, Map<String, Map<String, Object?>>> store = {};

  /// Yapılan çağrılar — testler sırayı/sayıyı buradan okur.
  final List<String> calls = [];

  /// İstemcinin GÖNDERDİĞİ ham yük (sunucunun eklediği `server_rev` olmadan).
  /// "Yerele ait kolonlar sunucuya gitmiyor" testi bunu okur; `store`
  /// sunucunun yazdığı hâli tutar ve `server_rev` orada bulunur.
  final Map<String, List<Map<String, Object?>>> sent = {};

  /// Gönderim çağrısı sayısı — zamanlama testleri bunu okur.
  int get upsertCalls => _upsertCalls;
  int _upsertCalls = 0;

  /// Tablolar arası ortak sürüm sayacı (`sync_rev_seq` karşılığı).
  int _rev = 0;

  /// true ise her çağrı patlar (ağ yok).
  bool fail = false;

  /// Onay DÖNMEDEN patlar: sunucu satırı yazdı ama istemci onayı alamadı.
  bool failAfterWrite = false;

  /// Gönderim SÜRERKEN çalışır — kullanıcının tam o anda satırı düzenlemesini
  /// taklit eder. Yalnız bir kez tetiklenir.
  Future<void> Function()? onUpsert;

  /// Çekme SÜRERKEN (ağ aşamasında) çalışır. Yalnız bir kez tetiklenir.
  Future<void> Function()? onFetch;

  @override
  Future<List<AcceptedRow>> upsert(
      String table, List<Map<String, Object?>> rows) async {
    calls.add(table);
    _upsertCalls++;
    sent.putIfAbsent(table, () => []).addAll(rows.map(Map<String, Object?>.of));
    if (fail) throw Exception('ağ yok');

    final interrupt = onUpsert;
    if (interrupt != null) {
      onUpsert = null;
      await interrupt();
    }

    final t = store.putIfAbsent(table, () => {});
    final accepted = <AcceptedRow>[];
    for (final r in rows) {
      final uid = r['uid']! as String;
      final existing = t[uid];
      if (existing != null && !_incomingWins(r, existing)) {
        continue; // REDDEDİLDİ — dönen listede yok (sync_guard davranışı)
      }
      final stored = Map<String, Object?>.of(r);
      stored['server_rev'] = ++_rev;
      t[uid] = stored;
      accepted.add(AcceptedRow(uid, _rev));
    }

    if (failAfterWrite) throw Exception('onay alınamadı');
    return accepted;
  }

  /// docs/20 §5.2: yalnız DAHA YENİ damga kazanır; eşitlikte sunucu kalır.
  bool _incomingWins(
      Map<String, Object?> incoming, Map<String, Object?> existing) {
    final a = incoming['changed_at_ms'];
    final b = existing['changed_at_ms'];
    if (a is! int) return false; // damgasız gönderim → eski sayılır
    if (b is! int) return true;
    return a > b;
  }

  @override
  Future<List<Map<String, Object?>>> fetchSince(
    String table,
    String userId,
    int sinceRev,
    int limit,
  ) async {
    calls.add('fetchSince:$table');
    if (fail) throw Exception('ağ yok');
    final interrupt = onFetch;
    if (interrupt != null) {
      onFetch = null;
      await interrupt();
    }

    final rows = (store[table]?.values ?? const <Map<String, Object?>>[])
        .where((r) => r['user_id'] == userId)
        .where((r) => (r['server_rev'] as int? ?? 0) > sinceRev)
        .map(Map<String, Object?>.of)
        .toList()
      ..sort((a, b) =>
          (a['server_rev'] as int? ?? 0).compareTo(b['server_rev'] as int? ?? 0));
    return rows.take(limit).toList();
  }

  @override
  Future<List<Map<String, Object?>>> fetchByUids(
    String table,
    String userId,
    List<String> uids,
  ) async {
    calls.add('fetchByUids:$table');
    if (fail) throw Exception('ağ yok');
    return (store[table]?.values ?? const <Map<String, Object?>>[])
        .where((r) => r['user_id'] == userId && uids.contains(r['uid']))
        .map(Map<String, Object?>.of)
        .toList();
  }

  int rowCount(String table) => store[table]?.length ?? 0;
  int count(String table) => rowCount(table);

  /// Sunucudaki bir satırı doğrudan tazeler — "öteki cihaz yazdı" senaryosu.
  /// Gerçek sunucuda olduğu gibi yeni bir `server_rev` alır.
  void serverSideWrite(
    String table,
    String uid,
    Map<String, Object?> patch,
  ) {
    final t = store.putIfAbsent(table, () => {});
    final row = Map<String, Object?>.of(t[uid] ?? {'uid': uid});
    row.addAll(patch);
    row['server_rev'] = ++_rev;
    t[uid] = row;
  }
}
