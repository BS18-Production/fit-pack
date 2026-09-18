import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import '../../data/database/tables/sync_columns.dart';

/// Bir sunucu satırının yerele uygulanması sonucunda ne olduğu.
enum ApplyOutcome { inserted, updated, skipped }

/// **Sunucu satırını yerele yazma kuralı** — tek yerde (docs/20 §6.2).
///
/// İki yerden çağrılır ve ikisinin de AYNI kuralı uygulaması şart:
/// 1. **Çekme** (`SyncPull`) — sunucudan inen her satır.
/// 2. **Gönderim reddi** (`SyncPush`) — sunucu "bende daha yenisi var" deyip
///    yazmayı atladığında, o satırın sunucudaki sürümü indirilip uygulanır.
///
/// İki kopya olsaydı biri güncellenip diğeri unutulduğunda çakışma kuralı
/// yöne göre farklı davranırdı — teşhisi en zor senkron hatası türü.
class SyncApply {
  final AppDatabase db;

  SyncApply(this.db);

  /// Tetikleyicileri **susturur** (düşürmez), [body]'yi çalıştırır, her
  /// durumda geri açar (docs/20 K-4, S-4).
  ///
  /// Eskiden tetikleyiciler DÜŞÜRÜLÜYORDU. O aralıkta kullanıcının yazdığı
  /// satır da tetikleyicisiz kalıyordu: uid'siz, damgasız, kuyruğa girmemiş →
  /// sunucuya hiç gitmiyordu. Ayrıca çekme sırasında uygulama ölürse
  /// tetikleyiciler geri kurulmuyordu (senkron sessizce ölürdü; açılıştaki
  /// onarım bunu da karşılıyor).
  ///
  /// Bayrak **yalnız inen satırların yazıldığı transaction** boyunca kapalı
  /// kalır — ağ beklenirken değil. Böylece kullanıcı çekme sürerken bir şey
  /// kaydederse tetikleyici çalışır ve o satır kuyruğa girer (S-4).
  Future<void> withCaptureOff(Future<void> Function() body) async {
    await db.customStatement(setCaptureSql(false));
    try {
      await body();
    } finally {
      await db.customStatement(setCaptureSql(true));
    }
  }

  /// Tablonun kolon tipleri — `_decode` bunlara bakarak çeviri yapar.
  Map<String, Object?> columnTypes(String table) {
    final info = db.allTables.firstWhere((t) => t.actualTableName == table);
    // Tip sınıfı drift sürümleri arasında değiştiği için `Object?` tutulur;
    // `_decode` değerle `DriftSqlType` sabitlerini karşılaştırır.
    return {for (final c in info.$columns) c.name: c.type};
  }

  /// Sunucu satırını çevirip yerele uygular. Çağıran `withCaptureOff` ve
  /// transaction'ı kendi yönetir (çekme sayfa başına, gönderim tur başına).
  Future<ApplyOutcome> applyServerRow(
    String table,
    Map<String, Object?> server, {
    Map<String, Object?>? types,
  }) async {
    final t = types ?? columnTypes(table);
    final fks = syncForeignKeys[table] ?? const {};
    final local = await _toLocalRow(table, server, t, fks);
    if (local == null) return ApplyOutcome.skipped; // ebeveyn henüz inmedi
    return _applyRow(table, local);
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
  Future<ApplyOutcome> _applyRow(
      String table, Map<String, Object?> local) async {
    // Profil TEK satırdır (kullanıcı başına bir profil). uid ile eşleştirmek,
    // junk/yeniden-onboarding satırı ayrı bir uid taşıdığında ikinci profil
    // satırı OLUŞTURUR. Bu yüzden özel: mevcut tek satırı sunucununkiyle
    // değiştir (uid dahil) → junk kendiliğinden gerçek veriyle değişir.
    if (table == 'user_profile') {
      return _applyProfile(local);
    }

    final uid = local['uid'] as String?;
    if (uid == null) return ApplyOutcome.skipped;

    final existing = await db.customSelect(
        'SELECT id, updated_at, changed_at_ms FROM $table WHERE uid = ?',
        variables: [Variable(uid)]).get();

    if (existing.isNotEmpty) {
      if (_serverWins(local, existing.first.data)) {
        await _update(table, 'uid = ?', [Variable(uid)], local);
        return ApplyOutcome.updated;
      }
      return ApplyOutcome.skipped; // yerel daha yeni → koru (gönderilecek)
    }

    // Katalog tablosunda (exercises/foods) aynı isimli seed satırı varsa onu
    // benimse — cihazlar seed satırlarına FARKLI uid ürettiği için uid eşleşmez
    // ve pull aksi halde her seansta kullanılan hareketi ikizler.
    if (catalogTableNames.contains(table)) {
      final adopt = await _findAdoptableCatalogRow(table, local['name']);
      if (adopt != null) {
        await _update(table, 'id = ?', [Variable(adopt)], local);
        return ApplyOutcome.updated;
      }
    }

    await _insert(table, local);
    return ApplyOutcome.inserted;
  }

  Future<ApplyOutcome> _applyProfile(Map<String, Object?> local) async {
    final row = await db
        .customSelect(
            'SELECT id, uid, updated_at, changed_at_ms FROM user_profile LIMIT 1')
        .get();
    if (row.isEmpty) {
      await _insert('user_profile', local);
      return ApplyOutcome.inserted;
    }
    final localUid = row.first.data['uid'] as String?;
    final serverUid = local['uid'] as String?;
    // Aynı profil kimliği + yerel daha yeni ise: kullanıcı çevrimdışı düzenledi,
    // koru (gönderilecek). Diğer her durumda (farklı uid = junk, ya da sunucu
    // daha yeni) sunucuyu benimse.
    if (localUid == serverUid && !_serverWins(local, row.first.data)) {
      return ApplyOutcome.skipped;
    }
    await _update('user_profile', 'id = ?',
        [Variable(row.first.data['id'] as int)], local);
    return ApplyOutcome.updated;
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

  /// Sunucu satırı yereli geçer mi? (docs/20 §5.2 — aynı kural, ters yön.)
  ///
  /// **Önce `changed_at_ms`** (milisaniye): çakışma kuralının ölçüsü budur ve
  /// sunucudaki `sync_guard` da bunu karşılaştırır. İki yön aynı alana
  /// bakmazsa bir satır gönderimde reddedilip çekmede de atlanabilir —
  /// sonsuza kadar iki tarafta farklı kalır.
  ///
  /// `updated_at` (saniye) yalnız **geri düşüş**: v2 öncesi yazılmış, damgası
  /// olmayan satırlar için. Aynı saniyedeki iki düzenlemeyi ayırt edemediği
  /// için sürüm ölçüsü olarak kullanılmaz (docs/20 §1 hata #3).
  ///
  /// Eşitlikte sunucu kazanır — tekrar çekme idempotent kalsın.
  bool _serverWins(Map<String, Object?> server, Map<String, Object?> local) {
    final sMs = server['changed_at_ms'];
    final lMs = local['changed_at_ms'];
    if (sMs is int && lMs is int) return sMs >= lMs;
    if (sMs is int && lMs == null) return true; // yerel damgasız (v2 öncesi)
    if (sMs == null && lMs is int) return false; // sunucu damgasız → dokunma

    final sTs = server['updated_at'];
    final lTs = local['updated_at'];
    if (sTs is! int) return false; // sunucu damgasız → dokunma
    if (lTs is! int) return true;
    return sTs >= lTs;
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
  static Object? decode(Object? value, Object? type) => _decode(value, type);

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
