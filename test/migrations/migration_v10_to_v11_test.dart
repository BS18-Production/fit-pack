import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/tables/sync_columns.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v10.dart' as v10;

/// v10 → v11 göç testi — **senkron v2 Aşama 1** (docs/20 §4.1).
///
/// Eklenenler: `changed_at_ms` (milisaniyelik damga), `local_seq` (cihaz
/// sayacı), `server_rev`; `sync_meta` ve `sync_tombstones` tabloları; her
/// senkron tablosunda yenilenmiş üç tetikleyici.
///
/// Bu göç **yıkıcı değildir** (ADR-007): hiçbir kolon/tablo silinmez, veri
/// olduğu gibi kalır. Testler bunu satır sayarak doğrular.
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  Future<AppDatabase> migrated() async {
    final schema = await verifier.schemaAt(10);
    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 11);
    return db;
  }

  test('v10 → v11 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(10);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 11);
    await db.close();
  });

  test('v10 verisi kayıpsız taşınır ve damgalar dolar', () async {
    final schema = await verifier.schemaAt(10);
    // Veri v10 şemasının KENDİ sınıfıyla yazılır: `AppDatabase` ile açmak
    // göçü hemen çalıştırır ve satır v11 tetikleyicilerinden geçerdi
    // (o zaman da "göçten önceki damga" ölçülemez).
    final old = v10.DatabaseAtV10(schema.newConnection());
    // v10 şemasında iki satır: biri temiz (gönderilmiş), biri kuyrukta.
    await old.customStatement(
      "INSERT INTO routines (name, created_at, uid, updated_at, sync_state, user_id) "
      "VALUES ('Gönderilmiş', 1700000000, 'uid-1', 1700000123, 0, 'u-1')",
    );
    await old.customStatement(
      "INSERT INTO routines (name, created_at, uid, updated_at, sync_state) "
      "VALUES ('Kuyrukta', 1700000000, 'uid-2', 1700000456, 1)",
    );
    // v10 tetikleyicilerini de kur: gerçek cihazda bunlar KURULUYDU ve
    // doldurma UPDATE'lerinde çalışıp her satırı yeniden kuyruğa aldılar.
    // Şema anlık görüntüsünde tetikleyici olmadığı için bu hata testten
    // kaçmıştı (2026-09-18, simülatörde yakalandı).
    for (final t in syncedTableNames) {
      await old.customStatement(createInsertTriggerSqlV10(t));
      await old.customStatement(createUpdateTriggerSqlV10(t));
    }
    await old.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 11);

    final rows = await db
        .customSelect(
          'SELECT name, uid, updated_at, sync_state, changed_at_ms, local_seq '
          'FROM routines ORDER BY id',
        )
        .get();
    expect(rows, hasLength(2), reason: 'satır kaybolmamalı');
    expect(rows.map((r) => r.read<String>('name')),
        ['Gönderilmiş', 'Kuyrukta']);
    // Damga saniyeden milisaniyeye çevrilir.
    expect(rows.first.read<int>('changed_at_ms'), 1700000123 * 1000);
    expect(rows.last.read<int>('changed_at_ms'), 1700000456 * 1000);
    // Kuyruk durumu olduğu gibi kalır — göç kimseyi yeniden göndermez.
    expect(rows.first.read<int>('sync_state'), 0);
    expect(rows.last.read<int>('sync_state'), 1);
    expect(rows.every((r) => r.read<int?>('local_seq') != null), isTrue);
    await db.close();
  });

  test('sync_meta ve sync_tombstones kurulu, varsayılanlar dolu', () async {
    final db = await migrated();
    final meta = await db
        .customSelect("SELECT key, value FROM sync_meta ORDER BY key")
        .get();
    final byKey = {
      for (final r in meta) r.read<String>('key'): r.read<String?>('value'),
    };
    expect(byKey['capture'], '1', reason: 'tetikleyiciler açık başlamalı');
    expect(int.parse(byKey['next_seq']!), greaterThan(0));

    final tomb = await db
        .customSelect('SELECT COUNT(*) c FROM sync_tombstones')
        .getSingle();
    expect(tomb.read<int>('c'), 0, reason: 'göç mezar taşı üretmez');
    await db.close();
  });

  test('her senkron tablosunda üç tetikleyici kurulu (36 adet)', () async {
    final db = await migrated();
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'")
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    for (final t in syncedTableNames) {
      for (final trigger in syncTriggerNames(t)) {
        expect(names, contains(trigger), reason: '$t → $trigger');
      }
    }
    expect(syncedTableNames.length * 3, 36);
    await db.close();
  });

  test('INSERT: milisaniyelik damga + artan sayaç', () async {
    final db = await migrated();
    await db.customStatement(
      "INSERT INTO routines (name, created_at) VALUES ('Push', 1700000000)",
    );
    await db.customStatement(
      "INSERT INTO routines (name, created_at) VALUES ('Pull', 1700000000)",
    );
    final rows = await db
        .customSelect('SELECT changed_at_ms, local_seq FROM routines ORDER BY id')
        .get();

    expect(rows.first.read<int>('changed_at_ms'), greaterThan(1700000000000),
        reason: 'milisaniye olmalı (saniye değil)');
    expect(rows.last.read<int>('local_seq'),
        greaterThan(rows.first.read<int>('local_seq')),
        reason: 'her yazma sayacı artırmalı');
    await db.close();
  });

  test('DELETE: gönderilmiş satır mezar taşı bırakır, seed satır bırakmaz',
      () async {
    final db = await migrated();
    // Sunucuya gitmiş satır (user_id dolu) → silinince iz kalmalı.
    await db.customStatement(
      "INSERT INTO routines (name, created_at, uid, user_id) "
      "VALUES ('Gönderilmiş', 1700000000, 'uid-1', 'u-1')",
    );
    // Hiç kullanılmamış seed katalog satırı → iz bırakmamalı.
    await db.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, is_custom, uid) "
      "VALUES ('Seed hareketi', 'compound', '[]', 0, 'uid-seed')",
    );

    await db.customStatement("DELETE FROM routines WHERE uid = 'uid-1'");
    await db.customStatement("DELETE FROM exercises WHERE uid = 'uid-seed'");

    final tomb = await db
        .customSelect('SELECT table_name, uid, local_seq FROM sync_tombstones')
        .get();
    expect(tomb, hasLength(1), reason: 'yalnız gönderilmiş satır iz bırakır');
    expect(tomb.single.read<String>('table_name'), 'routines');
    expect(tomb.single.read<String>('uid'), 'uid-1');
    expect(tomb.single.read<int?>('local_seq'), isNotNull);
    await db.close();
  });

  test('seans ve setleri silinince her ikisi de iz bırakır', () async {
    // Yerel şemada seans→set silmesi ZİNCİRLEMEZ (yabancı anahtar cascade
    // yok); uygulama setleri kendi siler (`deleteSessionWithSets`). Test bu
    // gerçek sırayı izler: her silinen satır kendi izini bırakmalı.
    final db = await migrated();
    await db.customStatement('PRAGMA foreign_keys = ON');
    await db.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, is_custom, uid, user_id) "
      "VALUES ('Bench', 'compound', '[]', 1, 'ex-1', 'u-1')",
    );
    await db.customStatement(
      "INSERT INTO workout_sessions (date, phase, workout_type, uid, user_id) "
      "VALUES (1700000000, 0, 'Push', 'ws-1', 'u-1')",
    );
    await db.customStatement(
      "INSERT INTO workout_sets (session_id, exercise_id, set_number, uid, user_id) "
      "VALUES ((SELECT id FROM workout_sessions WHERE uid = 'ws-1'), "
      "(SELECT id FROM exercises WHERE uid = 'ex-1'), 1, 'set-1', 'u-1')",
    );

    await db.customStatement("DELETE FROM workout_sets WHERE uid = 'set-1'");
    await db.customStatement("DELETE FROM workout_sessions WHERE uid = 'ws-1'");

    final tomb = await db
        .customSelect('SELECT table_name, uid FROM sync_tombstones ORDER BY id')
        .get();
    final uids = {for (final r in tomb) r.read<String>('uid')};
    expect(uids, containsAll(<String>{'ws-1', 'set-1'}),
        reason: 'seans ve seti ayrı ayrı iz bırakmalı');
    expect(
      {for (final r in tomb) r.read<String>('table_name')},
      containsAll(<String>{'workout_sessions', 'workout_sets'}),
    );
    await db.close();
  });
}
