import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/tables/sync_columns.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v8.dart' as v8;

/// v8 → v9 göç testi (Zorunlu hesap + senkron — docs/18-auth-and-sync.md §4).
///
/// v9: 12 tabloya `uid` / `userId` / `updatedAt` / `syncState` eklenir.
/// Göç ayrıca (a) eski satırlara UUID v4 backfill eder, (b) `uid` unique
/// index'lerini kurar, (c) mevcut satırları giden kutusuna alır — katalog
/// tablolarında YALNIZ `is_custom = 1` olanları (1022 seed hareket girmemeli).
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v8 → v9 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(8);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 9);
    await db.close();
  });

  test('v8 → v9 lossless: mevcut veri korunur, senkron alanları dolar',
      () async {
    final schema = await verifier.schemaAt(8);
    final oldDb = v8.DatabaseAtV8(schema.newConnection());

    await oldDb.customStatement(
      'INSERT INTO user_profile '
      '(current_phase, current_week, start_date, kcal_goal, protein_goal, '
      'height_cm, goal_weight_kg, onboarded, water_goal_ml) '
      'VALUES (1, 1, 1700000000, 2250, 170, 180.0, 75.0, 1, 2500)',
    );
    // Katalog hareketi (seed) + kullanıcının kendi eklediği hareket.
    await oldDb.customStatement(
      "INSERT INTO exercises (id, name, category, muscle_groups, is_custom) "
      "VALUES (1, 'Bench Press', 'compound', '[\"chest\"]', 0)",
    );
    await oldDb.customStatement(
      "INSERT INTO exercises (id, name, category, muscle_groups, is_custom) "
      "VALUES (2, 'Benim Hareketim', 'compound', '[\"chest\"]', 1)",
    );
    await oldDb.customStatement(
      "INSERT INTO workout_sessions (id, date, phase, workout_type, "
      "knee_status, is_deload) VALUES (1, 1700000000, 0, 'Push', 'normal', 0)",
    );
    await oldDb.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 9);

    // (1) Eski veri kayıpsız.
    final profile = await db.userProfileDao.getProfile();
    expect(profile, isNotNull);
    expect(profile!.kcalGoal, 2250);
    expect(profile.heightCm, 180.0);
    expect(profile.onboarded, isTrue);

    // (2) uid backfill — her satır dolu ve UUID v4 biçiminde.
    final uids = await db
        .customSelect('SELECT uid FROM exercises ORDER BY id')
        .get();
    expect(uids, hasLength(2));
    final uuidRe = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    for (final row in uids) {
      expect(uuidRe.hasMatch(row.read<String>('uid')), isTrue,
          reason: 'uid UUID v4 biçiminde olmalı');
    }

    // (3) uid'ler birbirinden farklı (unique index anlamlı olsun).
    final distinct = await db
        .customSelect('SELECT COUNT(DISTINCT uid) c FROM exercises')
        .getSingle();
    expect(distinct.read<int>('c'), 2);

    // (4) Kuyruk: seed hareket kuyruğa GİRMEZ, özel hareket girer.
    final seed = await db
        .customSelect('SELECT sync_state s FROM exercises WHERE id = 1')
        .getSingle();
    final custom = await db
        .customSelect('SELECT sync_state s FROM exercises WHERE id = 2')
        .getSingle();
    expect(seed.read<int>('s'), 0, reason: 'katalog satırı senkron edilmez');
    expect(custom.read<int>('s'), 1, reason: 'kullanıcının hareketi kuyrukta');

    // (5) Saf kullanıcı tablosundaki satır kuyruğa girer.
    final session = await db
        .customSelect('SELECT sync_state s FROM workout_sessions WHERE id = 1')
        .getSingle();
    expect(session.read<int>('s'), 1);

    // (6) userId/updatedAt henüz boş — ilk girişte doldurulacak.
    final fresh = await db
        .customSelect('SELECT user_id, updated_at FROM workout_sessions')
        .getSingle();
    expect(fresh.data['user_id'], isNull);
    expect(fresh.data['updated_at'], isNull);

    await db.close();
  });

  test('uid unique index her senkron tablosunda kurulu', () async {
    final schema = await verifier.schemaAt(8);
    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 9);

    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    for (final table in syncedTableNames) {
      expect(names, contains(uidIndexName(table)),
          reason: '$table için uid unique index eksik');
    }

    await db.close();
  });

  test('aynı uid iki kez yazılamaz (idempotency güvencesi)', () async {
    final schema = await verifier.schemaAt(8);
    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 9);

    await db.customStatement(
      "INSERT INTO routines (id, name, created_at, uid) "
      "VALUES (1, 'A', 1700000000, 'dup-uid')",
    );
    // Aynı uid ile ikinci satır → unique index reddetmeli. Bu, ağ koptuğunda
    // yeniden gönderimin çift kayıt yaratmamasının yerel güvencesi.
    expect(
      () => db.customStatement(
        "INSERT INTO routines (id, name, created_at, uid) "
        "VALUES (2, 'B', 1700000000, 'dup-uid')",
      ),
      throwsA(anything),
    );

    await db.close();
  });
}
