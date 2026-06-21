import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v3.dart' as v3;

/// v3 → v4 göç testi (Home su takibi).
///
/// KURAL (Workflow §4): schemaVersion artarsa bu lossless test AYNI değişiklik
/// setinde olur. v4: `water_intake` tablosu + `user_profile.waterGoalMl`
/// (default 2500). İkisi de additive → veri kayıpsız (ADR-007).
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v3 → v4 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(3);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 4);
    await db.close();
  });

  test('v3 → v4 lossless: mevcut profil korunur + waterGoalMl=2500 olur',
      () async {
    final schema = await verifier.schemaAt(3);

    // v3 şemasıyla gerçekçi bir profil yaz.
    final oldDb = v3.DatabaseAtV3(schema.newConnection());
    await oldDb.customStatement(
      "INSERT INTO user_profile (current_phase, current_week, start_date, "
      "kcal_goal, protein_goal, onboarded) "
      "VALUES (3, 1, 1700000000, 1850, 180, 1)",
    );
    await oldDb.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 4);

    // Profil korundu + yeni kolon default'la geldi.
    final profile = await db.userProfileDao.getProfile();
    expect(profile, isNotNull);
    expect(profile!.kcalGoal, 1850);
    expect(profile.onboarded, isTrue);
    expect(profile.waterGoalMl, 2500);

    // water_intake tablosu çalışır: ekle/oku/sıfırla.
    final today = DateTime.now();
    expect(await db.nutritionDao.getWaterForDay(today), 0);
    await db.nutritionDao.addWater(today, 250);
    await db.nutritionDao.addWater(today, 250);
    expect(await db.nutritionDao.getWaterForDay(today), 500);
    await db.nutritionDao.resetWater(today);
    expect(await db.nutritionDao.getWaterForDay(today), 0);

    await db.close();
  });

  test('addWater 0 altına düşmez', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final today = DateTime.now();
    await db.nutritionDao.addWater(today, 250);
    final result = await db.nutritionDao.addWater(today, -500);
    expect(result, 0);
    await db.close();
  });
}
