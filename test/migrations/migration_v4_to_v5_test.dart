import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v4.dart' as v4;

/// v4 → v5 göç testi (Antrenman V2 Faz A — docs/09-workout-v2.md).
///
/// KURAL (Workflow §4): schemaVersion artarsa bu lossless test AYNI değişiklik
/// setinde olur. v5: `exercises` +primaryMuscle/+equipment/+measurementType/
/// +isCustom/+isArchived. Hepsi additive → eski hareketler kayıpsız korunur.
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v4 → v5 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(4);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 5);
    await db.close();
  });

  test('v4 → v5 lossless: eski hareket korunur, yeni kolonlar default', () async {
    final schema = await verifier.schemaAt(4);

    // v4 şemasıyla eski bir V1 hareketi yaz (yeni kolonlar yok).
    final oldDb = v4.DatabaseAtV4(schema.newConnection());
    await oldDb.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, is_posture, is_arm) "
      "VALUES ('Eski Bench Press', 'compound', '[\"chest\"]', 0, 0)",
    );
    await oldDb.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 5);

    // Eski hareket aynen duruyor; yeni kolonlar default (measurementType
    // 'weight_reps', isCustom/isArchived false, equipment NULL).
    final ex = await db.workoutDao.getAllExercises();
    expect(ex, hasLength(1));
    expect(ex.single.name, 'Eski Bench Press');
    expect(ex.single.category, 'compound');
    expect(ex.single.measurementType, 'weight_reps');
    expect(ex.single.isCustom, isFalse);
    expect(ex.single.isArchived, isFalse);
    expect(ex.single.equipment, isNull);

    await db.close();
  });
}
