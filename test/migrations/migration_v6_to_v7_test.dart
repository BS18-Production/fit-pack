import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v6.dart' as v6;

/// v6 → v7 göç testi (İçerik Zenginleştirme — docs/11-content-enrichment.md).
///
/// v7: exercises +imagePath/+instructions/+level/+force, foods +category.
/// Hepsi nullable → eski hareket/yemek/özel kayıt kayıpsız.
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v6 → v7 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(6);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 7);
    await db.close();
  });

  test('v6 → v7 lossless: eski hareket + özel yemek korunur, yeni alanlar NULL',
      () async {
    final schema = await verifier.schemaAt(6);

    // v6 şemasıyla bir hareket + özel yemek yaz.
    final oldDb = v6.DatabaseAtV6(schema.newConnection());
    await oldDb.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, measurement_type, "
      "is_custom, is_archived, is_posture, is_arm) "
      "VALUES ('Bench Press', 'compound', '[\"chest\"]', 'weight_reps', 0, 0, 0, 0)",
    );
    await oldDb.customStatement(
      "INSERT INTO foods (name, kcal_per100g, protein_per100g, carb_per100g, "
      "fat_per100g, source, is_custom, is_recipe, default_portion_grams, unit_label) "
      "VALUES ('Ev Yemeği', 120.0, 8.0, 10.0, 5.0, 'custom', 1, 0, 200.0, 'porsiyon')",
    );
    await oldDb.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 7);

    // Eski hareket korundu, yeni kolonlar NULL geldi.
    final exercises = await db.workoutDao.getAllExercises();
    expect(exercises, hasLength(1));
    expect(exercises.single.name, 'Bench Press');
    expect(exercises.single.imagePath, isNull);
    expect(exercises.single.instructions, isNull);
    expect(exercises.single.level, isNull);

    // Özel yemek korundu (porsiyon bilgisiyle), category NULL geldi.
    final foods = await db.nutritionDao.getAllFoods();
    expect(foods, hasLength(1));
    expect(foods.single.name, 'Ev Yemeği');
    expect(foods.single.isCustom, isTrue);
    expect(foods.single.defaultPortionGrams, 200.0);
    expect(foods.single.category, isNull);

    await db.close();
  });
}
