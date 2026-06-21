/// Onboarding hedef önerisi (P-10 — docs/03-ux-flows.md §3).
///
/// Faz: kullanıcının hedefi. Kilo verme (cut), koruma (maintenance), kütle
/// alma (bulk). `currentPhase` kolonunda 1/2/3 olarak saklanır.
enum OnboardingPhase {
  cut(1, 'Kilo Ver', 'Yağ yak, kası koru', 0.80, 2.0),
  maintenance(2, 'Koru', 'Mevcut formu sürdür', 1.00, 1.8),
  bulk(3, 'Kütle Al', 'Kas yap, gücü artır', 1.10, 1.8);

  const OnboardingPhase(
    this.dbValue,
    this.label,
    this.description,
    this.kcalMultiplier,
    this.proteinPerKg,
  );

  /// `user_profile.currentPhase` değeri.
  final int dbValue;
  final String label;
  final String description;

  /// Bakım kalorisine uygulanan çarpan (cut < 1 < bulk).
  final double kcalMultiplier;

  /// Gram protein / kg vücut ağırlığı.
  final double proteinPerKg;
}

/// Kilo + fazdan günlük kalori/protein hedefi önerir.
///
/// Not: Profil yaş/cinsiyet tutmadığından tam Mifflin-St Jeor yerine,
/// orta aktiviteli bakım kalorisi ≈ kilo × 33 baz alınıp faz çarpanı
/// uygulanır. Kaba ama makul bir başlangıç — kullanıcı ekranda düzenler.
({int kcal, int protein}) suggestGoals({
  required double weightKg,
  required OnboardingPhase phase,
}) {
  const maintenancePerKg = 33.0; // orta aktivite bakım kalorisi
  final maintenance = weightKg * maintenancePerKg;
  // En yakın 50'ye yuvarla → "2236" yerine "2250" gibi temiz hedef.
  final kcal = ((maintenance * phase.kcalMultiplier) / 50).round() * 50;
  final protein = (weightKg * phase.proteinPerKg / 5).round() * 5;
  return (kcal: kcal, protein: protein);
}
