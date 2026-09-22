import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_tables.dart';

part 'sync_meta_dao.g.dart';

/// Senkron defteri (`sync_meta`) — docs/20 §4.1.
///
/// Neden `shared_preferences` değil: buradaki değerler veritabanı işlemlerinin
/// **içinde** yazılmalı. "Hesap değişimi başladı" işaretini ayrı bir dosyaya
/// yazarsan, temizlik yarıda kalınca işaret ile veri birbirini tutmaz —
/// tam da önlemeye çalıştığımız sızıntı. Tetikleyiciler de `capture`
/// bayrağını buradan okur (SQLite tetikleyicisi Dart değişkeni göremez).
@DriftAccessor(tables: [SyncMeta])
class SyncMetaDao extends DatabaseAccessor<AppDatabase> with _$SyncMetaDaoMixin {
  SyncMetaDao(super.db);

  /// Hesap değişimi temizliği sürüyor (değer: yeni kullanıcı kimliği).
  /// Açılışta doluysa temizlik yarıda kalmış demektir → baştan yapılır.
  static const keySwitchInProgress = 'switch_in_progress';

  /// Cihazdaki verinin sahibi. `shared_preferences`'tan buraya taşındı:
  /// temizlikle aynı transaction'da güncellensin (docs/20 §7.3).
  static const keyLastUser = 'last_user_id';

  /// Bir tablonun çekme imleci: "bu kullanıcı için `server_rev`'i bundan
  /// büyük satırları henüz görmedim" (docs/20 §6.1).
  ///
  /// Anahtar kullanıcıyı İÇERİR: aynı cihazda başka hesaba girilirse o
  /// hesabın imleci sıfırdan başlar, öncekinin imleci yanlışlıkla
  /// kullanılmaz (hesap izolasyonu — docs/20 §7).
  static String pullCursorKey(String userId, String table) =>
      'cursor:$userId:$table';

  /// Son **tam uzlaştırmanın** zamanı (unix saniye) — docs/20 §12.1 ikinci
  /// katman. İmleç payı dar bir pencereyi kapatır; uzun süre açık kalmış bir
  /// sunucu transaction'ını ancak her şeyi baştan okumak yakalar.
  static String fullPullKey(String userId) => 'full_pull_at:$userId';

  /// Son başarılı gönderim / çekme zamanı (ms) — "Son yedekleme" satırı
  /// (docs/20 §9, C-36).
  static const keyLastPushOk = 'last_push_ok_at';
  static const keyLastPullOk = 'last_pull_ok_at';

  /// Sunucuya İLK ulaşılamadığı an (ms). Başarılı her temasta silinir;
  /// doluysa ve 3 günden eskiyse kullanıcı uyarılır (docs/20 §9).
  static const keyUnreachableSince = 'server_unreachable_since';

  /// Cihaz saati ile sunucu saati arasındaki fark (ms, işaretli) — docs/23 §2.
  ///
  /// Tetikleyiciler `changed_at_ms`'i damgalarken bunu EKLER, o yüzden
  /// `shared_preferences`'ta değil burada: SQLite tetikleyicisi Dart
  /// değişkeni göremez.
  static const keyClockOffsetMs = 'clock_offset_ms';

  Future<String?> read(String key) async {
    final row = await (select(syncMeta)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> write(String key, String? value) async {
    await into(syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion(key: Value(key), value: Value(value)),
    );
  }

  Future<void> remove(String key) async {
    await (delete(syncMeta)..where((t) => t.key.equals(key))).go();
  }
}
