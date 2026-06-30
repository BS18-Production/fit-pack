import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Migration (şema göçü) testleri — bu projenin 1 numaralı testi.
/// Gerekçe: 3 aylık pilot data değerli; bir migration hatası onu siler
/// (Testing §1, §3.1).
///
/// KURAL (Workflow §4): `schemaVersion` artarsa, bu dosyaya o sürüm için
/// yeni bir lossless göç testi AYNI commit'te eklenir.
void main() {
  // V2 tablo adları override edilmemiş — Drift varsayılan snake_case üretir.
  const expectedTables = {
    'exercises',
    'workout_sessions',
    'workout_sets',
    'routines',
    'routine_exercises',
    'foods',
    'food_logs',
    'recipe_items',
    'water_intake',
    'body_measurements',
    'progress_photos',
    'achievements',
    'user_profile',
  };

  group('Schema v8', () {
    test('schemaVersion 8\'de (artırınca bu test bilinçli kırılır)',
        () async {
      // Bu assertion bir TRIPWIRE'dır: biri schemaVersion'ı artırınca
      // burası kırılır → onUpgrade adımı + yeni göç testi eklemeden
      // commit edemez (Workflow §4 kuralının mekanik bekçisi).
      // v1→v2: Beslenme V2 · v2→v3: Onboarding · v3→v4: Su · v4→v5: Hareket
      // kütüphanesi · v5→v6: Rutinler + gelişmiş set · v6→v7: İçerik
      // zenginleştirme (hareket görsel/talimat + gıda grubu) · v7→v8: BMR/TDEE
      // (user_profile +birthDate/+gender/+activityLevel).
      // Lossless göç testleri: migrations/migration_v*_to_v*_test.dart.
      final db = newTestDatabase();
      addTearDown(db.close);
      expect(db.schemaVersion, 8);
    });

    test('temiz kurulum (onCreate) beklenen 10 tabloyu yaratır', () async {
      final db = newTestDatabase();
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master "
            "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' "
            "AND name != 'sqlite_sequence'",
          )
          .get();
      final tableNames =
          rows.map((r) => r.read<String>('name')).toSet();

      expect(tableNames, containsAll(expectedTables));
    });

    test('beforeOpen yabancı anahtar (foreign key) kısıtını AÇAR', () async {
      final db = newTestDatabase();
      addTearDown(db.close);

      // İlk sorgu DB'yi açar → beforeOpen tetiklenir.
      final result =
          await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(result.read<int>('foreign_keys'), 1,
          reason: 'foreign_keys ON olmalı (ilişkisel bütünlük)');
    });
  });
}
