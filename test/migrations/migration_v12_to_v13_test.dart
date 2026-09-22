import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/sync_meta_dao.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v12.dart' as v12;

/// v12 → v13 göç testi — **sunucu saati düzeltmesi** (docs/23 §2).
///
/// Bu göç **tabloya dokunmaz**: değişen yalnız senkron tetikleyicilerinin
/// gövdesi. `changed_at_ms` artık `sync_meta.clock_offset_ms` terimini ekliyor.
/// Tetikleyici gövdesi yerinde güncellenemediği için düşürülüp yeniden kurulur.
///
/// Ölçülenler, sırayla riskli olandan:
/// 1. Göç **hiçbir satırı kuyruğa sokmamalı** — soksaydı ilk açılışta bütün
///    veri gereksiz yere yeniden yüklenirdi (v11 göçünde tam bu yaşandı).
/// 2. Mevcut damgalar **değişmemeli**.
/// 3. Göçten sonra yazılan satır düzeltmeyi uygulamalı.
/// 4. Düzeltme 0 iken davranış v12 ile birebir aynı olmalı (geri dönüş).
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  /// v12 veritabanına, kuyruğa girmiş gibi görünen bir rutin yazar.
  Future<void> seedV12(dynamic old) => old.customStatement(
        'INSERT INTO routines '
        '(name, order_index, is_archived, created_at, uid, user_id, '
        'sync_state, changed_at_ms, local_seq, server_rev) '
        "VALUES ('Push day', 0, 0, 1700000000, "
        "'0fd87d7a-f4de-413f-96b9-58b83368aac6', "
        "'ceef15db-e595-4984-8038-3ff4fe4432d5', 0, 1700000000000, 7, 42)",
      );

  test('v12 → v13 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(12);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 13);
    await db.close();
  });

  test('göç satırı kuyruğa sokmaz, damgaya dokunmaz', () async {
    final schema = await verifier.schemaAt(12);
    final old = v12.DatabaseAtV12(schema.newConnection());
    await seedV12(old);
    await old.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 13);

    final r = await db
        .customSelect('SELECT sync_state, changed_at_ms, local_seq, server_rev '
            'FROM routines')
        .getSingle();
    expect(r.read<int>('sync_state'), 0,
        reason: 'tetikleyici yenilemesi satıra dokunmamalı');
    expect(r.read<int>('changed_at_ms'), 1700000000000,
        reason: 'mevcut damgalar olduğu gibi kalmalı');
    expect(r.read<int>('local_seq'), 7);
    expect(r.read<int>('server_rev'), 42);
  });

  test('düzeltme anahtarı kurulur ve 0 başlar', () async {
    final connection = await verifier.startAt(12);
    final db = AppDatabase.forTesting(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 13);

    expect(await SyncMetaDao(db).read(SyncMetaDao.keyClockOffsetMs), '0',
        reason: 'düzeltme öğrenilene kadar davranış v12 ile aynı olmalı');
  });

  test('göçten sonra yazılan satır düzeltmeyi uygular', () async {
    final connection = await verifier.startAt(12);
    final db = AppDatabase.forTesting(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 13);

    await SyncMetaDao(db).write(SyncMetaDao.keyClockOffsetMs, '7200000');
    await db.customStatement(
        "INSERT INTO routines (name, created_at) VALUES ('Yeni', 1700000000)");

    final r = await db
        .customSelect("SELECT changed_at_ms c FROM routines WHERE name = 'Yeni'")
        .getSingle();
    final beklenen = DateTime.now().millisecondsSinceEpoch + 7200000;
    expect((r.read<int>('c') - beklenen).abs(), lessThan(5000),
        reason: 'yenilenen tetikleyici clock_offset_ms terimini eklemeli');
  });

  test('düzeltme 0 iken damga v12 davranışıyla aynı', () async {
    final connection = await verifier.startAt(12);
    final db = AppDatabase.forTesting(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 13);

    await db.customStatement(
        "INSERT INTO routines (name, created_at) VALUES ('Sıfır', 1700000000)");

    final r = await db
        .customSelect("SELECT changed_at_ms c FROM routines WHERE name = 'Sıfır'")
        .getSingle();
    final simdi = DateTime.now().millisecondsSinceEpoch;
    expect((r.read<int>('c') - simdi).abs(), lessThan(5000),
        reason: 'geri dönüş: düzeltme yokken cihaz saati kullanılmalı');
  });
}
