import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Onboarding profil + ilk ölçüm tek transaction (CR-014).
///
/// Ölçüm yazılamazsa profil "onboarded" kalmamalı: kalırsa kapı onboarding'i
/// bir daha göstermez ve ilk ölçüm hep eksik kalır.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get(); // onCreate + tetikleyiciler
  });

  tearDown(() => db.close());

  Future<void> complete() => db.userProfileDao.completeOnboarding(
        kcalGoal: 2400,
        proteinGoal: 160,
        phase: 1,
        heightCm: 180,
        initialWeightKg: 84.7,
        now: DateTime(2026, 10, 17, 9),
      );

  Future<int> measurements() async {
    final r = await db
        .customSelect('SELECT COUNT(*) c FROM body_measurements')
        .getSingle();
    return r.read<int>('c');
  }

  test('profil ve ilk ölçüm birlikte yazılır', () async {
    await complete();

    final profile = await db.userProfileDao.getProfile();
    expect(profile!.onboarded, isTrue);
    expect(profile.kcalGoal, 2400);
    final rows = await db.bodyDao.getAllMeasurements();
    expect(rows.single.weightKg, 84.7);
  });

  test('ölçüm yazılamazsa profil onboarded olmaz', () async {
    // Ölçüm insert'ine hata enjekte et.
    await db.customStatement('CREATE TEMP TRIGGER fail_measure '
        'BEFORE INSERT ON body_measurements '
        "BEGIN SELECT RAISE(ABORT, 'disk dolu'); END");

    await expectLater(complete(), throwsA(anything));

    final profile = await db.userProfileDao.getProfile();
    expect(profile?.onboarded ?? false, isFalse,
        reason: 'kapı onboarding\'i tekrar göstermeli');
    expect(await measurements(), 0);
  });

  test('hatadan sonra yeniden deneme tek ölçüm bırakır', () async {
    await db.customStatement('CREATE TEMP TRIGGER fail_measure '
        'BEFORE INSERT ON body_measurements '
        "BEGIN SELECT RAISE(ABORT, 'disk dolu'); END");
    await expectLater(complete(), throwsA(anything));
    await db.customStatement('DROP TRIGGER fail_measure');

    await complete();

    expect((await db.userProfileDao.getProfile())!.onboarded, isTrue);
    expect(await measurements(), 1);
  });

  test('kilo verilmezse yalnız profil yazılır', () async {
    await db.userProfileDao
        .completeOnboarding(kcalGoal: 2400, proteinGoal: 160, phase: 1);

    expect((await db.userProfileDao.getProfile())!.onboarded, isTrue);
    expect(await measurements(), 0);
  });
}
