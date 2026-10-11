import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'schema/schema.dart';
import 'schema/schema_v15.dart' as v15;

void main() {
  final verifier = SchemaVerifier(GeneratedHelper());
  test('v15 → v16 kayıpsız; fitness kuyruğu ve 39 tetikleyici korunur', () async {
    final schema = await verifier.schemaAt(15);
    final old = v15.DatabaseAtV15(schema.newConnection());
    await old.customStatement(
      "INSERT INTO water_intake(date,amount_ml,uid,sync_state,changed_at_ms,local_seq) VALUES(1700000000,500,'water-test',0,1700000000000,7)",
    );
    await old.customStatement(
      'CREATE TRIGGER migration_sentinel AFTER UPDATE ON water_intake BEGIN SELECT 1; END',
    );
    final before =
        (await old
                .customSelect(
                  "SELECT name,sql FROM sqlite_master WHERE type='trigger' ORDER BY name",
                )
                .get())
            .map((r) => r.data)
            .toList();
    await old.close();
    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 16);
    final w = await db
        .customSelect('SELECT amount_ml,sync_state,local_seq FROM water_intake')
        .getSingle();
    expect(w.read<int>('amount_ml'), 500);
    expect(w.read<int>('sync_state'), 0);
    expect(w.read<int>('local_seq'), 7);
    final after =
        (await db
                .customSelect(
                  "SELECT name,sql FROM sqlite_master WHERE type='trigger' ORDER BY name",
                )
                .get())
            .map((r) => r.data)
            .toList();
    expect(after, containsAll(before));
    expect(
      after.where((r) => (r['name'] as String).contains('_sync_')),
      hasLength(39),
    );
    expect(await db.assistantQualityDao.events('owner'), isEmpty);
  });
}
