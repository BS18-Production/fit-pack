import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v14.dart' as v14;

/// v14 → v15 göç testi — **beslenme günü tamamlandı** (docs/37, #8).
///
/// Eklenen: `nutrition_days` tablosu + uid index'i + üç senkron tetikleyicisi.
/// Mevcut satırlar değişmemeli, kuyruğa girmemeli; yeni tabloya yazınca kuyruk
/// normal çalışmalı.
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v14 → v15 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(14);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 15);
    await db.close();
  });

  test('eski kayıt kayıpsız, kuyruk değişmez; yeni tablo tetikleyicili', () async {
    final schema = await verifier.schemaAt(14);
    final old = v14.DatabaseAtV14(schema.newConnection());
    await old.customStatement(
      'INSERT INTO water_intake (date, amount_ml, uid, sync_state, '
      'changed_at_ms, local_seq) '
      "VALUES (1700000000, 500, '0d1f8c8e-6f43-4a39-9a43-2b1c3f1a9e12', 0, "
      '1700000000000, 7)',
    );
    await old.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 15);

    final w = await db.customSelect(
        'SELECT amount_ml, sync_state, local_seq FROM water_intake').getSingle();
    expect(w.read<int>('amount_ml'), 500);
    expect(w.read<int>('sync_state'), 0, reason: 'göç satırı kuyruğa sokmamalı');
    expect(w.read<int>('local_seq'), 7);

    final triggers = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'trigger' "
      "AND tbl_name = 'nutrition_days'",
    ).get();
    expect(triggers, hasLength(3));

    await db.nutritionDao.markDayComplete(DateTime(2026, 10, 10));
    final row = (await db.select(db.nutritionDays).get()).single;
    expect(row.syncState, 1, reason: 'işaretleme kuyruğa girmeli');
    expect(row.changedAtMs, isNotNull);
  });
}
