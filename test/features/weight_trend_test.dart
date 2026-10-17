import 'dart:math' as math;

import 'package:fit_pack/core/utils/weight_trend.dart';
import 'package:flutter_test/flutter_test.dart';

/// docs/42 — trend kilo (T-1…T-4).
void main() {
  WeightPoint p(int day, double kg) =>
      (date: DateTime(2026, 10, day, 7), kg: kg);

  test('sabit kilo → trend sabit', () {
    final t = weightTrendSeries([p(1, 80), p(2, 80), p(3, 80)]);
    expect(t.map((e) => e.kg), everyElement(80));
  });

  test('T-2: tek günlük sıçrama trendi %10 çeker', () {
    final t = weightTrendSeries([p(1, 80), p(2, 81)]);
    expect(t.last.kg, closeTo(80.1, 1e-9));
  });

  test('T-2: 5 günlük boşluk → 1 − 0,9^5 ağırlık', () {
    final t = weightTrendSeries([p(1, 80), p(6, 81)]);
    expect(t.last.kg, closeTo(80 + (1 - math.pow(0.9, 5)), 1e-9));
  });

  test('ölçüm gürültüsü trendde küçülür', () {
    // 80 civarında ±0,8 kg oynayan seri
    final ham = [80.0, 80.8, 79.4, 80.6, 79.6, 80.7, 79.5, 80.4];
    final t = weightTrendSeries([
      for (var i = 0; i < ham.length; i++) p(i + 1, ham[i]),
    ]);
    final hamFark = ham.reduce(math.max) - ham.reduce(math.min);
    final trendFark =
        t.map((e) => e.kg).reduce(math.max) -
        t.map((e) => e.kg).reduce(math.min);
    expect(trendFark, lessThan(hamFark / 4));
  });

  test('T-3: ≥3 ölçüm ve ≥7 gün', () {
    expect(trendReady([p(1, 80), p(8, 80)]), isFalse, reason: '2 ölçüm');
    expect(
      trendReady([p(1, 80), p(3, 80), p(6, 80)]),
      isFalse,
      reason: '5 gün',
    );
    expect(trendReady([p(1, 80), p(4, 80), p(8, 80)]), isTrue);
  });

  test('T-4: 7 günlük değişim; geçmiş yoksa null', () {
    final t = weightTrendSeries([
      for (var d = 1; d <= 15; d++) p(d, 80 - 0.1 * d), // günde −0,1 kg
    ]);
    final c = trendChange(t)!;
    expect(c, lessThan(0));
    expect(c, greaterThan(-0.7), reason: 'trend geride kalır, aşmaz');
    expect(trendChange(weightTrendSeries([p(1, 80), p(3, 79)])), isNull);
  });
}
