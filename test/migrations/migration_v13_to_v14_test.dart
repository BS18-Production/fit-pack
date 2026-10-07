import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v13.dart' as v13;

/// v13 → v14 göç testi — **hazır program kataloğu** (docs/28).
///
/// Eklenen: `routines.program_key` (NULLABLE). Mevcut rutinler olduğu gibi
/// kalır, program anahtarı boş başlar (kullanıcının kendi rutini).
/// Göç hiçbir satırı kuyruğa sokmamalı (ALTER TABLE tetikleyici çalıştırmaz).
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v13 → v14 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(13);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 14);
    await db.close();
  });

  test('v13 rutini kayıpsız taşınır, program boş, kuyruk değişmez', () async {
    final schema = await verifier.schemaAt(13);
    final old = v13.DatabaseAtV13(schema.newConnection());
    await old.customStatement(
      'INSERT INTO routines (name, order_index, created_at, is_archived, uid, '
      'sync_state, changed_at_ms, local_seq) '
      "VALUES ('Push', 2, 1700000000, 0, "
      "'0d1f8c8e-6f43-4a39-9a43-2b1c3f1a9e11', 0, 1700000000000, 4)",
    );
    await old.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 14);

    final r = (await db.workoutDao.getActiveRoutines()).single;
    expect(r.name, 'Push');
    expect(r.orderIndex, 2);
    expect(r.programKey, isNull);
    expect(r.syncState, 0, reason: 'göç satırı kuyruğa sokmamalı');
    expect(r.localSeq, 4);

    // v14'te anahtar yazılınca satır normal şekilde kuyruğa girer.
    await db.customStatement(
        "UPDATE routines SET program_key = 'ppl_intermediate'");
    final after = await db.workoutDao.getRoutine(r.id);
    expect(after!.programKey, 'ppl_intermediate');
    expect(after.syncState, 1);
  });
}
