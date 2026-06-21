import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v1.dart' as v1;

/// v1 → v2 göç testi (Beslenme V2 — docs/07-nutrition-v2.md).
///
/// Bu projenin 1 numaralı testi: 3 aylık pilot data değerli, bir migration
/// hatası onu siler (Testing §1, §3.1). KURAL (Workflow §4): schemaVersion
/// artarsa bu lossless test AYNI değişiklik setinde olur.
///
/// v2 değişikliği: `foods.default_portion_grams` + `foods.unit_label`
/// (ikisi de nullable, additive). Yıkıcı işlem YOK (ADR-007).
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v1 → v2 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase.forTesting(connection);
    // Gerçek MigrationStrategy.onUpgrade'i çalıştırır, sonuç şemayı v2
    // snapshot'ı ile karşılaştırır (sapma varsa kırılır).
    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

  test('v1 → v2 lossless: eski yemek + log korunur, yeni kolonlar NULL',
      () async {
    final schema = await verifier.schemaAt(1);

    // Eski uygulama gibi v1 şemasıyla veri yaz.
    final oldDb = v1.DatabaseAtV1(schema.newConnection());
    await oldDb.customStatement(
      "INSERT INTO foods (name, kcal_per100g, protein_per100g, "
      "carb_per100g, fat_per100g, source, is_custom, is_recipe) "
      "VALUES ('Eski Tavuk', 165, 31, 0, 3.6, 'local', 0, 0)",
    );
    await oldDb.customStatement(
      "INSERT INTO food_logs (date, meal_type, food_id, grams, "
      "computed_kcal, computed_protein, computed_carb, computed_fat) "
      "VALUES (1700000000, 'lunch', 1, 200, 330, 62, 0, 7.2)",
    );
    await oldDb.close();

    // Gerçek DB ile göç et + şemayı doğrula.
    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);

    // Eski yemek aynen duruyor mu?
    final foods = await db.nutritionDao.getAllFoods();
    expect(foods, hasLength(1));
    expect(foods.single.name, 'Eski Tavuk');
    expect(foods.single.kcalPer100g, 165);
    // Yeni kolonlar NULL → "sadece gram" davranışı (kullanıcıyı bozmaz).
    expect(foods.single.defaultPortionGrams, isNull);
    expect(foods.single.unitLabel, isNull);

    // Log da kayıpsız (computed snapshot korunur).
    final row = await db
        .customSelect(
            'SELECT COUNT(*) c, SUM(computed_kcal) k FROM food_logs')
        .getSingle();
    expect(row.read<int>('c'), 1);
    expect(row.read<double>('k'), 330);

    await db.close();
  });
}
