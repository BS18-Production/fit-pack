import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'schema/schema.dart';
import 'schema/schema_v16.dart' as v16;

/// v16 → v17 (docs/40, docs/41): body_measurements kaynak kolonları +
/// user_profile sağlık rızası. Yalnız kolon ekleme — mevcut ölçüm, kuyruk ve
/// tetikleyiciler aynen kalır.
void main() {
  final verifier = SchemaVerifier(GeneratedHelper());

  test('v16 → v17 kayıpsız; eski ölçüm elle giriş sayılır, rıza boş', () async {
    final schema = await verifier.schemaAt(16);
    final old = v16.DatabaseAtV16(schema.newConnection());
    await old.customStatement(
      "INSERT INTO body_measurements(date,weight_kg,body_fat_pct,uid,sync_state,changed_at_ms,local_seq) "
      "VALUES(1700000000,84.5,21.0,'bm-test',0,1700000000000,9)",
    );
    final before =
        (await old
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type='trigger' ORDER BY name",
                )
                .get())
            .map((r) => r.read<String>('name'))
            .toList();
    await old.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 17);

    final m = await db
        .customSelect(
          'SELECT weight_kg,body_fat_pct,sync_state,local_seq,source,source_ref,'
          'source_app,hidden FROM body_measurements',
        )
        .getSingle();
    expect(m.read<double>('weight_kg'), 84.5);
    expect(m.read<double>('body_fat_pct'), 21.0);
    expect(m.read<int>('sync_state'), 0, reason: 'göç kuyruğa almaz');
    expect(m.read<int>('local_seq'), 9);
    expect(m.read<String?>('source'), isNull, reason: 'NULL = elle giriş');
    expect(m.read<String?>('source_ref'), isNull);
    expect(m.read<bool?>('hidden'), isNull);

    final after =
        (await db
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type='trigger' ORDER BY name",
                )
                .get())
            .map((r) => r.read<String>('name'))
            .toList();
    expect(after, containsAll(before));

    final idx = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='index' "
          "AND name='idx_body_measurements_source_ref'",
        )
        .get();
    expect(idx, hasLength(1));
  });

  test('source_ref tekil; elle girilen satırlar (NULL) çakışmaz', () async {
    final schema = await verifier.schemaAt(16);
    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 17);

    Future<void> ekle(String? ref) => db.customStatement(
      'INSERT INTO body_measurements(date,weight_kg,source_ref) '
      'VALUES(1700000000,80,?)',
      [ref],
    );
    await ekle(null);
    await ekle(null);
    await ekle('hk-1');
    expect(() => ekle('hk-1'), throwsA(anything));
  });
}
