import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Profilde tek alan düzenlemesi (CR-013): ekranın elindeki kopya eskimiş
/// olsa da yalnız düzenlenen kolon yazılır — araya giren başka değişiklik
/// (ör. senkronun indirdiği kalori hedefi) ezilmez.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.userProfileDao.ensureProfile();
  });

  tearDown(() => db.close());

  test('eski kopyadan cinsiyet düzenlemesi araya giren kalori hedefini korur',
      () async {
    // Diyalog açılırken ekranın elindeki kopya.
    final stale = (await db.userProfileDao.getProfile())!;
    expect(stale.kcalGoal, 2200);

    // Diyalog açıkken başka bir yol (senkron) kalori hedefini değiştirdi.
    await db.customStatement('UPDATE user_profile SET kcal_goal = 2600');

    await db.userProfileDao
        .updateFields(const UserProfileCompanion(gender: Value('female')));

    final now = (await db.userProfileDao.getProfile())!;
    expect(now.gender, 'female');
    expect(now.kcalGoal, 2600, reason: 'araya giren değişiklik ezilmemeli');
    expect(stale.gender, isNot('female'));
  });

  test('açık null yazılır, verilmeyen alan dokunulmaz kalır', () async {
    await db.userProfileDao.updateFields(const UserProfileCompanion(
        heightCm: Value(180), goalWeightKg: Value(75)));

    await db.userProfileDao
        .updateFields(const UserProfileCompanion(goalWeightKg: Value(null)));

    final p = (await db.userProfileDao.getProfile())!;
    expect(p.goalWeightKg, isNull);
    expect(p.heightCm, 180);
  });

  test('düzenleme senkron kuyruğuna girer (tetikleyici çalışır)', () async {
    await db.customStatement('UPDATE user_profile SET sync_state = 0');

    await db.userProfileDao
        .updateFields(const UserProfileCompanion(proteinGoal: Value(170)));

    final row = await db
        .customSelect('SELECT sync_state, protein_goal FROM user_profile')
        .getSingle();
    expect(row.read<int>('protein_goal'), 170);
    expect(row.read<int>('sync_state'), 1);
  });

  test('profil satırı yoksa önce oluşturulur', () async {
    await db.customStatement('DELETE FROM user_profile');

    await db.userProfileDao
        .updateFields(const UserProfileCompanion(kcalGoal: Value(2400)));

    expect((await db.userProfileDao.getProfile())!.kcalGoal, 2400);
  });
}
