import '../../data/database/app_database.dart';

/// Antrenman kalori yakım tahmini (docs/12-session-resilience.md → kalori notu).
///
/// ACSM standart formülü — aktif (egzersize bağlı) kalori:
///   kcal = MET × 3.5 × kilo(kg) / 200 × süre(dk)
///
/// MET, ortalama RPE'ye göre 3.5 (hafif) – 6.0 (zorlu) arası ölçeklenir;
/// kardiyo ağırlıklı seansta daha yüksek (7.0) alınır.
///
/// NOT: Yaş / cinsiyet / boy esas olarak *dinlenme* metabolizmasını (BMR)
/// etkiler, egzersize bağlı aktif yakımı kayda değer ölçüde değiştirmez. Bu
/// yüzden aktif kalori tahmini yalnızca kilo + süre + yoğunluğa dayanır
/// (dürüst tahmin). Tam günlük harcama için BMR (yaş/cinsiyet/boy) ayrı bir
/// genişleme olur — şema v8 + onboarding gerektirir.
double? estimateWorkoutKcal({
  required double? bodyWeightKg,
  required int? durationMin,
  double? avgRpe,
  required bool isCardio,
}) {
  if (bodyWeightKg == null || bodyWeightKg <= 0) return null;
  if (durationMin == null || durationMin <= 0) return null;
  final met = isCardio
      ? 7.0
      : (avgRpe == null
          ? 5.0
          : 3.5 + ((avgRpe.clamp(5, 10) - 5) / 5) * 2.5);
  return met * 3.5 * bodyWeightKg / 200 * durationMin;
}

// ───────────────────────── Tam günlük enerji (BMR / TDEE) ─────────────────────

/// Aktiflik düzeyi → TDEE çarpanı (Mifflin-St Jeor standardı).
const activityFactors = <String, double>{
  'sedentary': 1.2, // masa başı, az hareket
  'light': 1.375, // hafif egzersiz 1-3 gün/hafta
  'moderate': 1.55, // orta 3-5 gün/hafta
  'active': 1.725, // ağır 6-7 gün/hafta
  'veryActive': 1.9, // çok ağır / fiziksel iş
};

// Görünen aktiflik etiketleri docs/14 ile lokalize edildi →
// `core/i18n/enum_labels.dart` `activityLabel(l, key)` + `activityLevelKeys`.

double activityFactor(String? level) => activityFactors[level] ?? 1.55;

/// Yaşı doğum tarihinden hesaplar (tam yıl).
int? ageFromBirthDate(DateTime? birth, {DateTime? now}) {
  if (birth == null) return null;
  final n = now ?? DateTime.now();
  var age = n.year - birth.year;
  if (n.month < birth.month ||
      (n.month == birth.month && n.day < birth.day)) {
    age--;
  }
  return age < 0 ? null : age;
}

/// Mifflin-St Jeor bazal metabolizma hızı (BMR) — dinlenmedeki günlük yakım.
///   Erkek:  10·kg + 6.25·cm − 5·yaş + 5
///   Kadın:  10·kg + 6.25·cm − 5·yaş − 161
/// Eksik veri (kilo/boy/yaş/cinsiyet) → null.
double? mifflinStJeorBmr({
  required double? weightKg,
  required double? heightCm,
  required int? age,
  required String? gender,
}) {
  if (weightKg == null || weightKg <= 0) return null;
  if (heightCm == null || heightCm <= 0) return null;
  if (age == null || age <= 0) return null;
  if (gender != 'male' && gender != 'female') return null;
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return gender == 'male' ? base + 5 : base - 161;
}

/// Toplam günlük enerji harcaması (TDEE) = BMR × aktiflik çarpanı.
double? tdee({
  required double? bmr,
  required String? activityLevel,
}) {
  if (bmr == null) return null;
  return bmr * activityFactor(activityLevel);
}

/// Bir seansın setlerinden ortalama RPE (girilmiş olanlar) + kardiyo olup
/// olmadığını çıkarır — kalori tahmini için yardımcı.
({double? avgRpe, bool isCardio}) sessionIntensity(Iterable<WorkoutSet> sets) {
  final rpes = <double>[];
  var cardio = false;
  for (final s in sets) {
    if (s.rpe != null) rpes.add(s.rpe!);
    if (s.distanceM != null || s.durationSec != null) cardio = true;
  }
  final avg = rpes.isEmpty
      ? null
      : rpes.reduce((a, b) => a + b) / rpes.length;
  return (avgRpe: avg, isCardio: cardio);
}
