import 'weight_trend.dart' show WeightPoint;

/// **Gerçek harcama tahmini** (docs/43) — saf, test edilebilir, metin üretmez.
///
/// Harcama = tamamlanmış günlerin ortalama alımı − kilo eğimi × 7.700 kcal/kg.
/// Adım / saat kalorisi kullanılmaz (çift sayım yok). Hedefi değiştirmez.

const kTdeeWindowDays = 28; // A-1
const kTdeeMinCompletedDays = 10; // A-2
const kTdeeMinWeighIns = 4; // A-3
const kTdeeMinWeightSpanDays = 14; // A-3
const kKcalPerKg = 7700.0; // A-4
const kTdeeMin = 1200; // A-5
const kTdeeMax = 5000; // A-5

enum TdeeStatus {
  ready,

  /// A-2: yeterli tamamlanmış beslenme günü yok.
  needCompletedDays,

  /// A-3: yeterli tartı / gün aralığı yok.
  needWeighIns,

  /// A-5: sonuç makul aralık dışında — büyük olasılıkla eksik kayıt.
  inconsistent,
}

class TdeeEstimate {
  final TdeeStatus status;

  /// A-4, 50'ye yuvarlı; yalnız `ready` iken dolu.
  final int? kcal;
  final int completedDays;
  final int weighIns;
  final int weightSpanDays;
  final double? avgIntake;

  /// kg/hafta (negatif = kayıp).
  final double? weeklyChangeKg;

  const TdeeEstimate({
    required this.status,
    this.kcal,
    required this.completedDays,
    required this.weighIns,
    required this.weightSpanDays,
    this.avgIntake,
    this.weeklyChangeKg,
  });

  /// A-6: [kcalGoal] ile beklenen haftalık değişim (kg). Hazır değilse `null`.
  double? weeklyChangeAtGoal(int kcalGoal) => (kcal == null || kcalGoal <= 0)
      ? null
      : (kcalGoal - kcal!) * 7 / kKcalPerKg;
}

int _days(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// [weights]: günde tek kilo, herhangi bir sırada; pencere dışı süzülür.
/// [completedIntake]: tamamlandı işaretli gün (00:00) → o günün toplam kcal'i.
TdeeEstimate estimateTdee({
  required DateTime now,
  required List<WeightPoint> weights,
  required Map<DateTime, double> completedIntake,
}) {
  final end = DateTime(now.year, now.month, now.day);
  final start = DateTime(end.year, end.month, end.day - kTdeeWindowDays);
  bool inWindow(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  final intake = [
    for (final e in completedIntake.entries)
      if (inWindow(e.key)) e.value,
  ];
  final w = [
    for (final p in weights)
      if (inWindow(p.date)) p,
  ]..sort((a, b) => a.date.compareTo(b.date));
  final span = w.length < 2 ? 0 : _days(w.first.date, w.last.date);

  TdeeEstimate status(TdeeStatus s) => TdeeEstimate(
    status: s,
    completedDays: intake.length,
    weighIns: w.length,
    weightSpanDays: span,
  );

  if (intake.length < kTdeeMinCompletedDays) {
    return status(TdeeStatus.needCompletedDays);
  }
  if (w.length < kTdeeMinWeighIns || span < kTdeeMinWeightSpanDays) {
    return status(TdeeStatus.needWeighIns);
  }

  final avgIntake = intake.reduce((a, b) => a + b) / intake.length;
  final slopePerDay = _slope(w);
  final raw = avgIntake - slopePerDay * kKcalPerKg;
  if (raw < kTdeeMin || raw > kTdeeMax) return status(TdeeStatus.inconsistent);

  return TdeeEstimate(
    status: TdeeStatus.ready,
    kcal: (raw / 50).round() * 50,
    completedDays: intake.length,
    weighIns: w.length,
    weightSpanDays: span,
    avgIntake: avgIntake,
    weeklyChangeKg: slopePerDay * 7,
  );
}

/// En küçük kareler eğimi, kg/gün.
double _slope(List<WeightPoint> w) {
  final t0 = w.first.date;
  final xs = [for (final p in w) p.date.difference(t0).inMinutes / 1440];
  final ys = [for (final p in w) p.kg];
  final mx = xs.reduce((a, b) => a + b) / xs.length;
  final my = ys.reduce((a, b) => a + b) / ys.length;
  var num = 0.0, den = 0.0;
  for (var i = 0; i < xs.length; i++) {
    num += (xs[i] - mx) * (ys[i] - my);
    den += (xs[i] - mx) * (xs[i] - mx);
  }
  return den == 0 ? 0 : num / den;
}
