import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import '../../data/database/tables/sync_columns.dart';
import 'sync_controller.dart' show syncLog;
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

/// Çekme (pull) hattı (docs/18 §6.4–6.5).
///
/// Girişte çalışır: sunucudaki kullanıcı verisini yerele indirir. Böylece
/// telefon değiştiren / uygulamayı yeniden kuran kullanıcı **verisini geri
/// alır** — gönderim (outbox) tek başına bunun yalnız yarısıydı.
///
/// **Çakışma kuralı: en son yazan kazanır** (`updated_at` karşılaştırması,
/// docs/18 §6.5). Uygulama ağırlıkla *ekleme* olduğu için çakışma nadir.
///
/// **Tetikleyiciler pull boyunca KAPALI** (docs/18 §6.4): sunucunun `updated_at`
/// damgası korunur ve inen satır kuyruğa geri girmez (yankı olmaz). Turun
/// başında kaldırılır, sonunda tek kaynaktan (`createInsertTriggerSql` /
/// `createUpdateTriggerSql`) geri kurulur.
class SyncPull {
  final AppDatabase db;
  final SyncRemote remote;

  SyncPull(this.db, this.remote);

  /// Sunucudaki bu kullanıcıya ait her şeyi indirir. Bağımlılık sırasıyla:
  /// referans verilen tablo (ebeveyn) önce iner ki çocuğun `*_uid`'i çözülsün.
  Future<PullResult> pullAll({required String userId}) async {
    var result = const PullResult();
    await _withTriggersDisabled(() async {
      for (final table in syncPushOrder) {
        try {
          result += await _pullTable(table, userId);
        } catch (e, st) {
          syncLog('$table çekilemedi: $e\n$st', error: e);
          result += PullResult(error: e);
          // Bir tablo başarısızsa dur: sonraki tablolar buna referans verebilir,
          // yarım çekilmiş ebeveynle çocuk eklemek FK kırar.
          break;
        }
      }
    });
    syncLog('pull bitti — eklenen ${result.inserted}, '
        'güncellenen ${result.updated}, atlanan ${result.skipped}',
        error: result.error);
    return result;
  }

  /// Tetikleyicileri kaldırır, [body]'yi çalıştırır, HER durumda geri kurar.
  Future<void> _withTriggersDisabled(Future<void> Function() body) async {
    for (final table in syncedTableNames) {
      await db.customStatement(dropInsertTriggerSql(table));
      await db.customStatement(dropUpdateTriggerSql(table));
    }
    try {
      await body();
    } finally {
      for (final table in syncedTableNames) {
        await db.customStatement(createInsertTriggerSql(table));
        await db.customStatement(createUpdateTriggerSql(table));
      }
    }
  }

  Future<PullResult> _pullTable(String table, String userId) async {
    final serverRows = await remote.fetch(table, userId);
    if (serverRows.isEmpty) return const PullResult();
    syncLog('$table ← sunucudan ${serverRows.length} satır');

    var inserted = 0, updated = 0, skipped = 0;
    final info = db.allTables.firstWhere((t) => t.actualTableName == table);
    // Kolon tipini `Object?` tutuyoruz: drift'in tip sınıfı sürümler arası
    // değişiyor, `_decode` değerle DriftSqlType sabitlerini karşılaştırıyor
    // (gönderimdeki `_encode` ile aynı desen).
    final types = <String, Object?>{
      for (final c in info.$columns) c.name: c.type
    };
    final fks = syncForeignKeys[table] ?? const {};

    await db.transaction(() async {
      for (final server in serverRows) {
        final local = await _toLocalRow(table, server, types, fks);
        if (local == null) {
          skipped++; // ebeveyn referansı henüz yok → beklet
          continue;
        }
        final outcome = await _applyRow(table, local);
        switch (outcome) {
          case _Applied.inserted:
            inserted++;
          case _Applied.updated:
            updated++;
          case _Applied.skipped:
            skipped++;
        }
      }
    });
    return PullResult(inserted: inserted, updated: updated, skipped: skipped);
  }

  /// Sunucu JSON'unu yerel satıra çevirir (gönderimdeki `_rowToJson`'un tersi):
  /// - `id`/`sync_state` yerele ait, sunucudan gelmez → id atlanır, sync_state=0
  /// - `*_uid` yabancı anahtarlar yerel integer id'ye çevrilir
  /// - boolean/tarih değerleri SQLite biçimine döner
  ///
  /// Ebeveyn `uid` yerelde bulunamazsa `null` döner (satır bu turda atlanır).
  Future<Map<String, Object?>?> _toLocalRow(
    String table,
    Map<String, Object?> server,
    Map<String, Object?> types,
    Map<String, String> fks,
  ) async {
    final out = <String, Object?>{};
    for (final entry in types.entries) {
      final col = entry.key;
      if (col == 'id') continue; // yerel autoincrement — sunucudan gelmez
      if (col == 'sync_state') {
        out[col] = 0; // inen satır temiz
        continue;
      }
      if (fks.containsKey(col)) {
        final serverUid = server[serverFkColumn(col)];
        if (serverUid == null) {
          out[col] = null;
          continue;
        }
        final localId = await _localIdOf(fks[col]!, serverUid as String);
        if (localId == null) return null; // ebeveyn henüz inmedi → beklet
        out[col] = localId;
        continue;
      }
      out[col] = _decode(server[col], entry.value);
    }
    return out;
  }

  Future<int?> _localIdOf(String table, String uid) async {
    final r = await db.customSelect('SELECT id FROM $table WHERE uid = ?',
        variables: [Variable(uid)]).get();
    return r.isEmpty ? null : r.first.data['id'] as int;
  }

  /// Çevrilmiş satırı yerele yazar ve ne yaptığını döner.
  Future<_Applied> _applyRow(String table, Map<String, Object?> local) async {
    // Profil TEK satırdır (kullanıcı başına bir profil). uid ile eşleştirmek,
    // junk/yeniden-onboarding satırı ayrı bir uid taşıdığında ikinci profil
    // satırı OLUŞTURUR. Bu yüzden özel: mevcut tek satırı sunucununkiyle
    // değiştir (uid dahil) → junk kendiliğinden gerçek veriyle değişir.
    if (table == 'user_profile') {
      return _applyProfile(local);
    }

    final uid = local['uid'] as String?;
    if (uid == null) return _Applied.skipped;

    final existing = await db.customSelect(
        'SELECT id, updated_at FROM $table WHERE uid = ?',
        variables: [Variable(uid)]).get();

    if (existing.isNotEmpty) {
      if (_serverWins(local['updated_at'], existing.first.data['updated_at'])) {
        await _update(table, 'uid = ?', [Variable(uid)], local);
        return _Applied.updated;
      }
      return _Applied.skipped; // yerel daha yeni → koru (gönderilecek)
    }

    // Katalog tablosunda (exercises/foods) aynı isimli seed satırı varsa onu
    // benimse — cihazlar seed satırlarına FARKLI uid ürettiği için uid eşleşmez
    // ve pull aksi halde her seansta kullanılan hareketi ikizler.
    if (catalogTableNames.contains(table)) {
      final adopt = await _findAdoptableCatalogRow(table, local['name']);
      if (adopt != null) {
        await _update(table, 'id = ?', [Variable(adopt)], local);
        return _Applied.updated;
      }
    }

    await _insert(table, local);
    return _Applied.inserted;
  }

  Future<_Applied> _applyProfile(Map<String, Object?> local) async {
    final row = await db
        .customSelect('SELECT id, uid, updated_at FROM user_profile LIMIT 1')
        .get();
    if (row.isEmpty) {
      await _insert('user_profile', local);
      return _Applied.inserted;
    }
    final localUid = row.first.data['uid'] as String?;
    final serverUid = local['uid'] as String?;
    // Aynı profil kimliği + yerel daha yeni ise: kullanıcı çevrimdışı düzenledi,
    // koru (gönderilecek). Diğer her durumda (farklı uid = junk, ya da sunucu
    // daha yeni) sunucuyu benimse.
    if (localUid == serverUid &&
        !_serverWins(local['updated_at'], row.first.data['updated_at'])) {
      return _Applied.skipped;
    }
    await _update('user_profile', 'id = ?',
        [Variable(row.first.data['id'] as int)], local);
    return _Applied.updated;
  }

  Future<int?> _findAdoptableCatalogRow(String table, Object? name) async {
    if (name == null) return null;
    final r = await db.customSelect(
      'SELECT id FROM $table '
      'WHERE name = ? AND user_id IS NULL AND is_custom = 0 LIMIT 1',
      variables: [Variable(name)],
    ).get();
    return r.isEmpty ? null : r.first.data['id'] as int;
  }

  /// Sunucu satırı yereli geçer mi? `updated_at` epoch saniyeleri karşılaştırılır.
  /// Eşitlikte sunucu kazanır (idempotent tekrar pull zarar vermez). Yerelin
  /// damgası yoksa (eski satır) sunucu kazanır.
  bool _serverWins(Object? serverTs, Object? localTs) {
    if (serverTs is! int) return false; // sunucu damgasız → dokunma
    if (localTs is! int) return true;
    return serverTs >= localTs;
  }

  Future<void> _insert(String table, Map<String, Object?> row) async {
    final cols = row.keys.toList();
    final placeholders = List.filled(cols.length, '?').join(', ');
    await db.customStatement(
      'INSERT INTO $table (${cols.join(', ')}) VALUES ($placeholders)',
      cols.map((c) => row[c]).toList(),
    );
  }

  Future<void> _update(
    String table,
    String where,
    List<Variable> whereArgs,
    Map<String, Object?> row,
  ) async {
    // id sunucudan gelmez; uid dahil kalan tüm kolonları yaz.
    final cols = row.keys.where((c) => c != 'id').toList();
    final setClause = cols.map((c) => '$c = ?').join(', ');
    await db.customStatement(
      'UPDATE $table SET $setClause WHERE $where',
      [...cols.map((c) => row[c]), ...whereArgs.map((v) => v.value)],
    );
  }

  /// PostgREST/Postgres değerini SQLite'ın (drift'in) beklediği biçime çevirir —
  /// gönderimdeki `_encode`'un tersi.
  static Object? _decode(Object? value, Object? type) {
    if (value == null) return null;
    switch (type) {
      case DriftSqlType.bool:
        // Postgres boolean → SQLite 0/1
        if (value is bool) return value ? 1 : 0;
        return value == true || value == 1 ? 1 : 0;
      case DriftSqlType.dateTime:
        // timestamptz (ISO 8601) → drift'in tuttuğu unix saniye
        if (value is String) {
          final dt = DateTime.tryParse(value);
          if (dt == null) return null;
          return dt.millisecondsSinceEpoch ~/ 1000;
        }
        return value;
      default:
        return value;
    }
  }
}

enum _Applied { inserted, updated, skipped }
