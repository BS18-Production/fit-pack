import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/tables/sync_columns.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';

/// v9 → v10 göç testi (Giden kutusu tetikleyicileri — docs/18 §6).
///
/// Tetikleyiciler 23 DAO yazma noktasını tek tek damgalamaya alternatiftir:
/// veritabanı seviyesinde her yazma yakalanır. Atlanan bir yazma = sessizce
/// senkron edilmeyen veri, hata türlerinin en kötüsü — bu testler o garantiyi
/// korur.
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  Future<AppDatabase> migrated() async {
    final schema = await verifier.schemaAt(9);
    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 10);
    return db;
  }

  test('v9 → v10 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(9);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 10);
    await db.close();
  });

  test('her senkron tablosunda insert+update tetikleyicisi kurulu', () async {
    final db = await migrated();
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'")
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    for (final t in syncedTableNames) {
      expect(names, contains('${t}_sync_ins'), reason: '$t insert tetikleyicisi');
      expect(names, contains('${t}_sync_upd'), reason: '$t update tetikleyicisi');
    }
    await db.close();
  });

  test('INSERT: uid üretilir, zaman damgalanır, kuyruğa girer', () async {
    final db = await migrated();
    // uid/updated_at/sync_state VERİLMEDEN yazılıyor — tetikleyici doldurmalı.
    await db.customStatement(
      "INSERT INTO routines (name, created_at) VALUES ('Push', 1700000000)",
    );
    final r = await db
        .customSelect('SELECT uid, updated_at, sync_state FROM routines')
        .getSingle();

    final uuidRe = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    expect(uuidRe.hasMatch(r.read<String>('uid')), isTrue);
    expect(r.read<int>('updated_at'), greaterThan(0));
    expect(r.read<int>('sync_state'), 1, reason: 'yazılan satır kuyruğa girer');
    await db.close();
  });

  test('UPDATE: satır yeniden kuyruğa girer', () async {
    final db = await migrated();
    await db.customStatement(
      "INSERT INTO routines (name, created_at) VALUES ('Push', 1700000000)",
    );
    // Senkron katmanı temiz işaretlemiş gibi yap.
    await db.customStatement('UPDATE routines SET sync_state = 0');

    await db.customStatement("UPDATE routines SET name = 'Pull'");
    final r = await db
        .customSelect('SELECT name, sync_state FROM routines')
        .getSingle();
    expect(r.read<String>('name'), 'Pull');
    expect(r.read<int>('sync_state'), 1, reason: 'değişen satır tekrar kuyrukta');
    await db.close();
  });

  test('DÖNGÜ KORUMASI: temiz işaretleme satırı yeniden kirletmez', () async {
    final db = await migrated();
    await db.customStatement(
      "INSERT INTO routines (name, created_at) VALUES ('Push', 1700000000)",
    );
    // Senkron katmanının yaptığı iş: sync_state 1 → 0. Tetikleyici bunu
    // görmezden gelmeli, yoksa satır sonsuza dek kuyrukta kalır ve senkron
    // hiç bitmez.
    await db.customStatement('UPDATE routines SET sync_state = 0');
    final r = await db
        .customSelect('SELECT sync_state FROM routines')
        .getSingle();
    expect(r.read<int>('sync_state'), 0, reason: 'temiz kalmalı');
    await db.close();
  });

  test('KATALOG: seed hareket kuyruğa girmez, özel hareket girer', () async {
    final db = await migrated();
    await db.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, is_custom) "
      "VALUES ('Bench Press', 'compound', '[\"chest\"]', 0)",
    );
    await db.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, is_custom) "
      "VALUES ('Benim Hareketim', 'compound', '[\"chest\"]', 1)",
    );
    final rows = await db
        .customSelect('SELECT is_custom, sync_state FROM exercises ORDER BY id')
        .get();
    expect(rows[0].read<int>('sync_state'), 0,
        reason: '1015 seed hareket her kullanıcıya kopyalanmamalı');
    expect(rows[1].read<int>('sync_state'), 1,
        reason: 'kullanıcının kendi hareketi senkron edilir');
    await db.close();
  });

  test('KATALOG: kullanılınca elle kuyruğa alınabilir (tembel senkron)',
      () async {
    final db = await migrated();
    await db.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, is_custom) "
      "VALUES ('Bench Press', 'compound', '[\"chest\"]', 0)",
    );
    // Kullanıcı bu hareketi bir sette kullandı → senkron katmanı kuyruğa alır.
    await db.customStatement(
      queueCatalogRowSql('exercises').replaceFirst('?', '1'),
    );
    final r = await db
        .customSelect('SELECT sync_state FROM exercises WHERE id = 1')
        .getSingle();
    expect(r.read<int>('sync_state'), 1);
    await db.close();
  });

  test('mevcut uid korunur — tetikleyici üzerine yazmaz', () async {
    final db = await migrated();
    const fixed = '11111111-2222-4333-8444-555555555555';
    await db.customStatement(
      "INSERT INTO routines (name, created_at, uid) "
      "VALUES ('Push', 1700000000, '$fixed')",
    );
    final r = await db.customSelect('SELECT uid FROM routines').getSingle();
    expect(r.read<String>('uid'), fixed,
        reason: 'sunucudan çekilen satırın uid\'i değişmemeli');
    await db.close();
  });
}
