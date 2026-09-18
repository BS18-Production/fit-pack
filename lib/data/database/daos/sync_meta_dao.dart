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
