import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/achievement_tables.dart';

part 'user_profile_dao.g.dart';

@DriftAccessor(tables: [UserProfile])
class UserProfileDao extends DatabaseAccessor<AppDatabase>
    with _$UserProfileDaoMixin {
  UserProfileDao(super.db);

  Future<UserProfileData?> getProfile() =>
      (select(userProfile)..limit(1)).getSingleOrNull();

  Future<int> insertProfile(UserProfileCompanion entry) =>
      into(userProfile).insert(entry);

  Future<bool> updateProfile(UserProfileData entry) =>
      update(userProfile).replace(entry);

  /// Yalnız [patch]'te verilen kolonları yazar (CR-013). Ekranın elindeki
  /// profil kopyası eskimiş olabilir — diyalog açıkken senkron başka bir alanı
  /// güncellemiş olabilir. Tüm satırı o kopyadan yazmak (`replace`) o değişikliği
  /// ve senkron kolonlarını geri alırdı. Senkron kolonları tetikleyiciye kalır.
  Future<void> updateFields(UserProfileCompanion patch) async {
    await ensureProfile();
    await update(userProfile).write(patch);
  }

  Future<void> ensureProfile() async {
    final existing = await getProfile();
    if (existing == null) {
      await insertProfile(
        UserProfileCompanion(startDate: Value(DateTime.now())),
      );
    }
  }

  /// Reaktif onboarding kontrolü — router redirect'i bunu izler.
  Stream<UserProfileData?> watchProfile() =>
      (select(userProfile)..limit(1)).watchSingleOrNull();

  /// Sağlık verisi açık rızası (docs/41 §3). [version] = kabul edilen metin
  /// sürümü; `null` = rıza geri alındı. Her iki kararda zaman yazılır (ispat).
  Future<void> setHealthConsent(int? version, {DateTime? now}) async {
    await ensureProfile();
    await (update(userProfile)).write(
      UserProfileCompanion(
        // Geri alma da zamanla yazılır: sunucu rızayı zamana göre ilerletir
        // (health_consent_monotonic) — eski profil kopyası ezemez (Codex P1).
        healthConsentAt: Value(now ?? DateTime.now()),
        healthConsentVersion: Value(version),
      ),
    );
  }

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
    await updateProfile(
      profile.copyWith(
        goalDirection: Value(direction),
        goalDirectionSince: Value(
          direction == null ? null : (now ?? DateTime.now()),
        ),
      ),
    );
  }

  /// P-10 Onboarding tamamlandığında çağrılır: hedefleri yazar + onboarded=1.
  /// Tek profil satırını günceller (yoksa oluşturur). Boy/hedef kilo opsiyonel.
  ///
  /// [initialWeightKg] verilirse başlangıç kilosu ilk ölçüm olarak AYNI
  /// transaction'da yazılır (CR-014): ya ikisi birden kaydolur ya hiçbiri.
  /// Ayrı yazılınca ölçüm hata verse bile profil "onboarded" kalıyordu; kapı
  /// onboarding'i bir daha göstermediği için ilk ölçüm hep eksik kalırdı.
  /// Hata sonrası yeniden deneme de bu yüzden çift ölçüm üretmez.
  Future<void> completeOnboarding({
    required int kcalGoal,
    required int proteinGoal,
    required int phase,
    double? heightCm,
    double? goalWeightKg,
    DateTime? birthDate,
    String? gender,
    String? activityLevel,
    double? initialWeightKg,
    DateTime? now,
  }) =>
      transaction(() async {
        // Ölçüm önce: hata verirse profil hiç dokunulmadan geri alınır.
        if (initialWeightKg != null && initialWeightKg > 0) {
          await attachedDatabase.bodyDao.insertMeasurement(
            BodyMeasurementsCompanion(
              date: Value(now ?? DateTime.now()),
              weightKg: Value(initialWeightKg),
            ),
          );
        }
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
      });
}
