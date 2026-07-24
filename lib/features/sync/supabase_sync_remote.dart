import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_push.dart';

/// `SyncRemote`'un gerçek uygulaması — Supabase'e yazar (docs/18 §6.2).
///
/// **`onConflict: 'uid'` kritik:** aynı satır ikinci kez gönderilirse (ağ
/// koptu, onay gelmedi, yeniden denendi) sunucu yeni satır AÇMAZ, mevcut
/// satırın üstüne yazar. Çift antrenman kaydı olmamasının sunucu tarafındaki
/// yarısı budur; diğer yarısı istemcide üretilen `uid`.
///
/// Metodun dönmesi = **sunucu onayı**. Hata fırlatırsa `SyncPush` satırları
/// kuyrukta bırakır (docs/18 §6.3 kural 2).
class SupabaseSyncRemote implements SyncRemote {
  final SupabaseClient client;

  SupabaseSyncRemote(this.client);

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return;
    await client.from(table).upsert(rows, onConflict: 'uid');
  }

  @override
  Future<List<Map<String, Object?>>> fetch(String table, String userId) async {
    final rows = await client.from(table).select().eq('user_id', userId);
    return rows.cast<Map<String, Object?>>();
  }
}
