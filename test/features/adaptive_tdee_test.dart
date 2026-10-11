import 'package:fit_pack/core/utils/adaptive_tdee.dart';
import 'package:fit_pack/core/utils/weight_trend.dart';
import 'package:flutter_test/flutter_test.dart';

/// docs/43 — gerçek harcama tahmini (A-1…A-7).
void main() {
  final now = DateTime(2026, 10, 29, 12);
  DateTime gun(int geri) => DateTime(2026, 10, 29 - geri);

  Map<DateTime, double> alim(int gunSayisi, double kcal) => {
    for (var i = 1; i <= gunSayisi; i++) gun(i): kcal,
  };
  List<WeightPoint> kilo(double baslangic, double gunluk, {int adet = 28}) => [
    for (var i = adet; i >= 1; i--)
      (
        date: gun(i).add(const Duration(hours: 7)),
        kg: baslangic + gunluk * (adet - i),
      ),
  ];

  test('sabit kilo + 2.300 kcal → harcama 2.300', () {
    final e = estimateTdee(
      now: now,
      weights: kilo(80, 0),
      completedIntake: alim(20, 2300),
    );
    expect(e.status, TdeeStatus.ready);
    expect(e.kcal, 2300);
  });

  test('haftada −0,5 kg + 2.000 kcal → ~2.550', () {
    final e = estimateTdee(
      now: now,
      weights: kilo(80, -0.5 / 7),
      completedIntake: alim(20, 2000),
    );
    // 0,5 × 7.700 / 7 = 550
    expect(e.kcal, 2550);
    expect(e.weeklyChangeKg, closeTo(-0.5, 1e-6));
  });

  test('A-6: hedefin haftalık sonucu', () {
    final e = estimateTdee(
      now: now,
      weights: kilo(80, 0),
      completedIntake: alim(20, 2300),
    );
    expect(e.weeklyChangeAtGoal(2000), closeTo(-300 * 7 / 7700, 1e-9));
    expect(e.weeklyChangeAtGoal(0), isNull);
  });

  test('A-1: bugün ve pencere dışı günler sayılmaz', () {
    final e = estimateTdee(
      now: now,
      weights: kilo(80, 0),
      completedIntake: {
        ...alim(9, 2300),
        DateTime(2026, 10, 29): 9999, // bugün
        gun(40): 9999, // pencere dışı
      },
    );
    expect(e.status, TdeeStatus.needCompletedDays);
    expect(e.completedDays, 9);
  });

  test('A-3: az tartı ya da kısa aralık', () {
    final az = estimateTdee(
      now: now,
      weights: kilo(80, 0, adet: 3),
      completedIntake: alim(20, 2300),
    );
    expect(az.status, TdeeStatus.needWeighIns);
    final kisa = estimateTdee(
      now: now,
      weights: [for (var i = 6; i >= 1; i--) (date: gun(i), kg: 80.0)],
      completedIntake: alim(20, 2300),
    );
    expect(kisa.status, TdeeStatus.needWeighIns, reason: '5 gün < 14');
  });

  test('A-5: makul aralık dışı → sayı yok', () {
    final e = estimateTdee(
      now: now,
      weights: kilo(80, 0),
      completedIntake: alim(20, 600),
    );
    expect(e.status, TdeeStatus.inconsistent);
    expect(e.kcal, isNull);
  });
}
