import 'dart:math' as math;

/// **Trend kilo** (docs/42) — saf, test edilebilir.
///
/// Üstel hareketli ortalama ("Hacker's Diet"): her günlük ölçüm farkın
/// [kTrendAlpha]'sı kadar trendi çeker; boşluklu günlerde katsayı gün sayısına
/// göre büyür (T-2). Girdi günde tek değerdir (docs/40 W-4).

const kTrendAlpha = 0.1;

/// Trend hazır sayılması için en az ölçüm ve gün (T-3).
const kTrendMinPoints = 3;
const kTrendMinSpanDays = 7;

typedef WeightPoint = ({DateTime date, double kg});

int _days(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;

/// [points] eskiden yeniye. Dönen: her ölçüm gününün trend değeri.
List<WeightPoint> weightTrendSeries(List<WeightPoint> points) {
  if (points.isEmpty) return const [];
  final out = <WeightPoint>[(date: points.first.date, kg: points.first.kg)];
  var trend = points.first.kg;
  for (var i = 1; i < points.length; i++) {
    final gap = math.max(1, _days(points[i - 1].date, points[i].date));
    final a = 1 - math.pow(1 - kTrendAlpha, gap);
    trend += a * (points[i].kg - trend);
    out.add((date: points[i].date, kg: trend));
  }
  return out;
}

/// T-3: ≥ 3 ölçüm ve ilk–son arası ≥ 7 gün.
bool trendReady(List<WeightPoint> points) =>
    points.length >= kTrendMinPoints &&
    _days(points.first.date, points.last.date) >= kTrendMinSpanDays;

/// T-4: son trend − [days] gün önceki trend (o güne en yakın ÖNCEKİ nokta).
/// Yeterli geçmiş yoksa `null`.
double? trendChange(List<WeightPoint> trend, {int days = 7}) {
  if (trend.length < 2) return null;
  final last = trend.last;
  final target = DateTime(last.date.year, last.date.month, last.date.day - days);
  WeightPoint? before;
  for (final p in trend) {
    if (_days(p.date, target) >= 0) before = p; // p.date ≤ hedef gün
  }
  return before == null ? null : last.kg - before.kg;
}
