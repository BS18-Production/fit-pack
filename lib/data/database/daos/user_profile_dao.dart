import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/achievement_tables.dart';

part 'user_profile_dao.g.dart';

@DriftAccessor(tables: [UserProfile])
class UserProfileDao extends DatabaseAccessor<AppDatabase> with _$UserProfileDaoMixin {
  UserProfileDao(super.db);

  Future<UserProfileData?> getProfile() =>
      (select(userProfile)..limit(1)).getSingleOrNull();

  Future<int> insertProfile(UserProfileCompanion entry) =>
      into(userProfile).insert(entry);

  Future<bool> updateProfile(UserProfileData entry) =>
      update(userProfile).replace(entry);

  Future<void> ensureProfile() async {
    final existing = await getProfile();
    if (existing == null) {
      await insertProfile(UserProfileCompanion(
        startDate: Value(DateTime.now()),
      ));
    }
  }

  /// Reaktif onboarding kontrolü — router redirect'i bunu izler.
  Stream<UserProfileData?> watchProfile() =>
      (select(userProfile)..limit(1)).watchSingleOrNull();

  /// Kilo hedefinin yönünü yazar (docs/22 §3.4): 'lose' | 'maintain' |
  /// 'gain', ya da `null` (seçimi kaldır).
  ///
  /// `goalDirectionSince` YALNIZ yön gerçekten değiştiğinde güncellenir.
  /// Aynı yönü tekrar seçmek tarihi bugüne çekseydi, geçen haftaların yorumu
  /// sessizce "bilinmiyor"a dönerdi (geçmişe uygulama yasağının ölçüsü bu
  /// tarih). Hedef kilo/kalori DEĞİŞMEZ — kullanıcı onayı olmadan hedef
  /// değişmez (Samet kuralı).
  Future<void> setGoalDirection(String? direction, {DateTime? now}) async {
    await ensureProfile();
    final profile = await getProfile();
    if (profile!.goalDirection == direction) return;
    await updateProfile(profile.copyWith(
      goalDirection: Value(direction),
      goalDirectionSince: Value(direction == null ? null : (now ?? DateTime.now())),
    ));
  }

  /// P-10 Onboarding tamamlandığında çağrılır: hedefleri yazar + onboarded=1.
  /// Tek profil satırını günceller (yoksa oluşturur). Boy/hedef kilo opsiyonel.
  Future<void> completeOnboarding({
    required int kcalGoal,
    required int proteinGoal,
    required int phase,
    double? heightCm,
    double? goalWeightKg,
    DateTime? birthDate,
    String? gender,
    String? activityLevel,
  }) async {
    await ensureProfile();
    final profile = await getProfile();
    await updateProfile(profile!.copyWith(
      kcalGoal: kcalGoal,
      proteinGoal: proteinGoal,
      currentPhase: phase,
      heightCm: Value(heightCm),
      goalWeightKg: Value(goalWeightKg),
      birthDate: Value(birthDate),
      gender: Value(gender),
      activityLevel: Value(activityLevel),
      onboarded: true,
    ));
  }
}
