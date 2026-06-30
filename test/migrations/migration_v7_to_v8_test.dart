import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v7.dart' as v7;

/// v7 → v8 göç testi (BMR/TDEE — docs/12-session-resilience.md → BMR notu).
///
/// v8: user_profile +birthDate/+gender/+activityLevel. Hepsi nullable →
/// mevcut profil (hedefler/boy/su) kayıpsız, yeni alanlar NULL gelir.
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v7 → v8 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(7);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 8);
    await db.close();
  });

  test('v7 → v8 lossless: mevcut profil korunur, yeni alanlar NULL', () async {
    final schema = await verifier.schemaAt(7);

    // v7 şemasıyla gerçekçi bir profil yaz (zaten kullanan pilot).
    final oldDb = v7.DatabaseAtV7(schema.newConnection());
    await oldDb.customStatement(
      'INSERT INTO user_profile '
      '(current_phase, current_week, start_date, kcal_goal, protein_goal, '
      'height_cm, goal_weight_kg, onboarded, water_goal_ml) '
      'VALUES (1, 1, 1700000000, 2250, 170, 180.0, 75.0, 1, 2500)',
    );
    await oldDb.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);

    final profile = await db.userProfileDao.getProfile();
    expect(profile, isNotNull);
    // Eski değerler korundu.
    expect(profile!.kcalGoal, 2250);
    expect(profile.proteinGoal, 170);
    expect(profile.heightCm, 180.0);
    expect(profile.goalWeightKg, 75.0);
    expect(profile.waterGoalMl, 2500);
    expect(profile.onboarded, isTrue);
    // Yeni alanlar NULL geldi.
    expect(profile.birthDate, isNull);
    expect(profile.gender, isNull);
    expect(profile.activityLevel, isNull);

    await db.close();
  });
}
