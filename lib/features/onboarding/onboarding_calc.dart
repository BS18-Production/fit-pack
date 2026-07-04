/// Onboarding hedef önerisi + değer projeksiyonu (docs/15 §A3).
///
/// Faz: kullanıcının hedefi. Kilo verme (cut), koruma (maintenance), kütle
/// alma (bulk). `currentPhase` kolonunda 1/2/3 olarak saklanır.
/// Görünen etiketler lokalize (docs/14) → onboarding_screen `_phaseLabel/Desc`.
enum OnboardingPhase {
  cut(1, 0.80, 2.0),
  maintenance(2, 1.00, 1.8),
  bulk(3, 1.10, 1.8);

  const OnboardingPhase(
    this.dbValue,
    this.kcalMultiplier,
    this.proteinPerKg,
  );

  /// `user_profile.currentPhase` değeri.
  final int dbValue;

  /// Bakım kalorisine uygulanan çarpan (cut < 1 < bulk).
  final double kcalMultiplier;

  /// Gram protein / kg vücut ağırlığı.
  final double proteinPerKg;
}

/// Orta aktiviteli bakım kalorisi ≈ kilo × 33. Profil bu aşamada yaş/cinsiyet
/// içermeyebileceğinden tam Mifflin-St Jeor yerine kaba ama makul yaklaşım —
/// kullanıcı ekranda düzenler.
const _maintenancePerKg = 33.0;

/// 1 kg vücut yağı ≈ 7700 kcal (projeksiyon için standart kabul).
const _kcalPerKgFat = 7700.0;

/// Kilo + fazdan günlük kalori/protein hedefi önerir.
({int kcal, int protein}) suggestGoals({
  required double weightKg,
  required OnboardingPhase phase,
}) {
  final maintenance = weightKg * _maintenancePerKg;
  // En yakın 50'ye yuvarla → "2236" yerine "2250" gibi temiz hedef.
  final kcal = ((maintenance * phase.kcalMultiplier) / 50).round() * 50;
  final protein = (weightKg * phase.proteinPerKg / 5).round() * 5;
  return (kcal: kcal, protein: protein);
}

/// Hedef kiloya ulaşma projeksiyonu, hafta olarak (docs/15 §A3 — "aha" anı).
///
/// `null` → projeksiyon GÖSTERİLMEZ (sahte vaat yok): koruma fazı, hedef kilo
/// boş, hedefin yönü fazla ters (cut'ta hedef ≥ mevcut vb.) ya da girilen
/// kaloriyle açık/fazla oluşmuyorsa.
///
/// [kcalGoal] verilirse açık/fazla KULLANICININ girdiği hedeften hesaplanır
/// (ekranda düzenledikçe projeksiyon dürüstçe güncellenir); verilmezse fazın
/// varsayılan çarpanı kullanılır.
int? projectWeeks({
  required double weightKg,
  required double? goalWeightKg,
  required OnboardingPhase phase,
  int? kcalGoal,
}) {
  if (goalWeightKg == null || weightKg <= 0 || goalWeightKg <= 0) return null;
  final maintenance = weightKg * _maintenancePerKg;

  final double deltaKg; // kapatılacak mesafe
  final double dailyKcal; // günlük açık (cut) / fazla (bulk)
  switch (phase) {
    case OnboardingPhase.cut:
      if (goalWeightKg >= weightKg) return null;
      deltaKg = weightKg - goalWeightKg;
      dailyKcal = kcalGoal != null
          ? maintenance - kcalGoal
          : maintenance * (1 - phase.kcalMultiplier);
    case OnboardingPhase.bulk:
      if (goalWeightKg <= weightKg) return null;
      deltaKg = goalWeightKg - weightKg;
      dailyKcal = kcalGoal != null
          ? kcalGoal - maintenance
          : maintenance * (phase.kcalMultiplier - 1);
    case OnboardingPhase.maintenance:
      return null;
  }

  if (dailyKcal <= 0) return null; // açık/fazla yok → tempo yok
  final weeklyKg = dailyKcal * 7 / _kcalPerKgFat;
  final weeks = (deltaKg / weeklyKg).ceil();
  return weeks < 1 ? 1 : weeks;
}
