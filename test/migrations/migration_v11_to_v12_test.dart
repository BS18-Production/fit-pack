import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v11.dart' as v11;

/// v11 → v12 göç testi — **haftalık değerlendirme, hedef yönü** (docs/22 §6).
///
/// Eklenen: `user_profile.goal_direction` ve `goal_direction_since`, ikisi de
/// NULLABLE. Veri doldurulmaz; mevcut profil olduğu gibi kalır ve yön
/// "bilinmiyor" olarak başlar (kullanıcı seçince dolar).
///
/// Senkron için kritik: göç **hiçbir satırı kuyruğa sokmamalı**. `ALTER
/// TABLE ADD COLUMN` tetikleyici çalıştırmaz; test bunu sayarak doğrular —
/// sokarsaydı ilk açılışta bütün profil gereksiz yere yeniden yüklenirdi.
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v11 → v12 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(11);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 12);
    await db.close();
  });

  test('v11 profili kayıpsız taşınır, yön boş başlar, kuyruk değişmez',
      () async {
    final schema = await verifier.schemaAt(11);
    // Veri v11'in KENDİ sınıfıyla yazılır — AppDatabase ile açmak göçü
    // hemen çalıştırırdı ve "göç öncesi" durum ölçülemezdi.
    final old = v11.DatabaseAtV11(schema.newConnection());
    await old.customStatement(
      'INSERT INTO user_profile '
      '(current_phase, current_week, start_date, kcal_goal, protein_goal, '
      'height_cm, goal_weight_kg, onboarded, water_goal_ml, uid, user_id, '
      'sync_state, changed_at_ms, local_seq) '
      "VALUES (3, 1, 1700000000, 3100, 155, 180.0, 80.0, 1, 2500, "
      "'ad64beec-b8b0-4947-86c1-a57b8370d65c', "
      "'ceef15db-e595-4984-8038-3ff4fe4432d5', 0, 1700000000000, 7)",
    );
    await old.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);

    final p = await db.userProfileDao.getProfile();
    expect(p, isNotNull);
    expect(p!.kcalGoal, 3100);
    expect(p.goalWeightKg, 80.0);
    expect(p.uid, 'ad64beec-b8b0-4947-86c1-a57b8370d65c');
    expect(p.goalDirection, isNull, reason: 'yön seçilene kadar bilinmiyor');
    expect(p.goalDirectionSince, isNull);

    expect(p.syncState, 0,
        reason: 'göç satırı kuyruğa sokmamalı — gereksiz yeniden yükleme');
    expect(p.localSeq, 7, reason: 'cihaz sayacı değişmemeli');
    expect(p.changedAtMs, 1700000000000, reason: 'damga değişmemeli');
  });

  test('v12\'de yön yazılınca satır normal şekilde kuyruğa girer', () async {
    final schema = await verifier.schemaAt(11);
    final old = v11.DatabaseAtV11(schema.newConnection());
    await old.customStatement(
      'INSERT INTO user_profile '
      '(current_phase, current_week, start_date, kcal_goal, protein_goal, '
      'onboarded, water_goal_ml, sync_state) '
      'VALUES (1, 1, 1700000000, 2500, 150, 1, 2500, 0)',
    );
    await old.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 12);

    await db.customStatement(
        "UPDATE user_profile SET goal_direction = 'gain'");
    final r = await db
        .customSelect('SELECT goal_direction, sync_state FROM user_profile')
        .getSingle();
    expect(r.read<String>('goal_direction'), 'gain');
    expect(r.read<int>('sync_state'), 1,
        reason: 'v11 tetikleyicileri yeni kolondaki değişikliği de yakalamalı');
  });
}
