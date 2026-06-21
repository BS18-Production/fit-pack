import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'schema/schema.dart';
import 'schema/schema_v2.dart' as v2;

/// v2 → v3 göç testi (P-10 Onboarding — docs/03-ux-flows.md §3).
///
/// KURAL (Workflow §4): schemaVersion artarsa bu lossless test AYNI değişiklik
/// setinde olur. v3 değişikliği: `user_profile.onboarded` (BOOL, default 0,
/// additive). Yıkıcı işlem YOK (ADR-007).
///
/// Kritik davranış: migration mevcut profili onboarded=1 yapmalı — uygulamayı
/// zaten kullanan pilot, güncelleme sonrası onboarding ekranını GÖRMEMELİ.
void main() {
  late SchemaVerifier verifier;
  setUp(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v2 → v3 şema göçü yapısal olarak geçerli', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase.forTesting(connection);
    await verifier.migrateAndValidate(db, 3);
    await db.close();
  });

  test('v2 → v3 lossless: mevcut profil korunur + onboarded=1 olur', () async {
    final schema = await verifier.schemaAt(2);

    // Eski uygulama gibi v2 şemasıyla gerçekçi bir profil yaz (hedefler dolu).
    final oldDb = v2.DatabaseAtV2(schema.newConnection());
    await oldDb.customStatement(
      "INSERT INTO user_profile (current_phase, current_week, start_date, "
      "kcal_goal, protein_goal, height_cm, goal_weight_kg) "
      "VALUES (1, 4, 1700000000, 2000, 180, 180.0, 75.0)",
    );
    await oldDb.close();

    // Gerçek DB ile göç et + şemayı doğrula.
    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);

    // Profil aynen duruyor mu? Ham SQL ile okunur — güncel DAO sonraki
    // sürümlerin kolonlarını (örn. v4 waterGoalMl) bekler, v3'te yoktur.
    final row = await db
        .customSelect('SELECT * FROM user_profile LIMIT 1')
        .getSingle();
    expect(row.read<int>('kcal_goal'), 2000);
    expect(row.read<int>('protein_goal'), 180);
    expect(row.read<int>('current_week'), 4);
    expect(row.read<double>('height_cm'), 180.0);
    expect(row.read<double>('goal_weight_kg'), 75.0);
    // Kritik: mevcut kullanıcı onboarding GÖRMEMELİ.
    expect(row.read<int>('onboarded'), 1);

    await db.close();
  });

  test('temiz kurulum (onCreate): profil onboarded=false ile başlar', () async {
    // Sıfır kurulumda onboarding gösterilmeli → onboarded false olmalı.
    // Gerçek AppDatabase + in-memory = gerçek onCreate yolu.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.userProfileDao.ensureProfile();
    final profile = await db.userProfileDao.getProfile();
    expect(profile!.onboarded, isFalse);
    await db.close();
  });
}
