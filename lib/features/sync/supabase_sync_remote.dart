import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_push.dart';

/// `SyncRemote`'un gerçek uygulaması — Supabase'e yazar (docs/20 §5.1, §6.1).
///
/// **`onConflict: 'user_id,uid'` kritik:** aynı satır ikinci kez gönderilirse
/// (ağ koptu, onay gelmedi, yeniden denendi) sunucu yeni satır AÇMAZ, mevcut
/// satırın üstüne yazar. Çift antrenman kaydı olmamasının sunucu tarafındaki
/// yarısı budur; diğer yarısı istemcide üretilen `uid`.
///
/// **`.select()` kritik:** sunucudaki `sync_guard` tetikleyicisi, sürümü eski
/// olan yazmayı atlar ve o satır `RETURNING` sonucunda GÖRÜNMEZ. Yani dönen
/// liste = kabul edilenler. `.select()` olmadan ret sessiz kalır ve istemci
/// ezilmiş sanır (docs/20 §5.1).
///
/// Metodun dönmesi = **sunucu onayı**. Hata fırlatırsa `SyncPush` satırları
/// kuyrukta bırakır (docs/18 §6.3 kural 2).
class SupabaseSyncRemote implements SyncRemote {
  /// İstemci **çağrı anında** çözülür. Kurulumda çözülseydi Supabase
  /// başlatılamadığında (ağ yok/yanlış config) `Supabase.instance` fırlatır ve
  /// uygulamanın kökü çökerdi — oysa bulut opsiyonel katman (main.dart).
  /// Bugün: satırlar kuyrukta kalır, uygulama yerelde çalışır.
  final SupabaseClient Function() _client;

  SupabaseSyncRemote(SupabaseClient Function() client) : _client = client;

  /// Hazır bir istemciyle (test/DI) kurmak için.
  SupabaseSyncRemote.of(SupabaseClient client) : _client = (() => client);

  SupabaseClient get client => _client();

  @override
  Future<List<AcceptedRow>> upsert(
      String table, List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return const [];
    final accepted = await client
        .from(table)
        .upsert(rows, onConflict: 'user_id,uid')
        .select('uid, server_rev');
    return [
      for (final r in accepted)
        if (r['uid'] is String)
          AcceptedRow(r['uid'] as String, _asInt(r['server_rev'])),
    ];
  }

  @override
  Future<List<Map<String, Object?>>> fetchSince(
    String table,
    String userId,
    int sinceRev,
    int limit,
  ) async {
    final rows = await client
        .from(table)
        .select()
        .eq('user_id', userId)
        .gt('server_rev', sinceRev)
        .order('server_rev', ascending: true)
        .limit(limit);
    return rows.cast<Map<String, Object?>>();
  }

  @override
  Future<List<Map<String, Object?>>> fetchByUids(
    String table,
    String userId,
    List<String> uids,
  ) async {
    if (uids.isEmpty) return const [];
    final rows = await client
        .from(table)
        .select()
        .eq('user_id', userId)
        .inFilter('uid', uids);
    return rows.cast<Map<String, Object?>>();
  }

  @override
  Future<List<String>> deleteRows(
    String table,
    String userId,
    List<String> uids,
  ) async {
    if (uids.isEmpty) return const [];
    // Doğrudan DELETE yerine RPC: tablo adı sunucuda sabit listeye karşı
    // doğrulanıyor ve gerçekten silinen kimlikler dönüyor (docs/20 §5.3).
    // Silme işaretlerini sunucudaki AFTER DELETE tetikleyicisi yazar.
    final rows = await client.rpc<List<dynamic>>(
      'sync_delete',
      params: {'p_table': table, 'p_uids': uids},
    );
    return [
      for (final r in rows)
        if (r is Map && r['uid'] is String) r['uid'] as String,
    ];
  }

  /// `server_rev` JSON'dan int ya da (büyük sayılarda) String gelebilir.
  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
