import 'package:flutter_test/flutter_test.dart';
import 'package:fit_pack/core/units/units.dart';

void main() {
  const metric = Units(UnitSystem.metric);
  const imp = Units(UnitSystem.imperial);

  group('Units — ağırlık', () {
    test('metrik geçiş no-op', () {
      expect(metric.weightFromKg(84.7), 84.7);
      expect(metric.weightToKg(84.7), 84.7);
      expect(metric.weight(84.7), '84.7 kg');
      expect(metric.weight(80), '80 kg'); // tam sayı kırpılır
    });

    test('kg ↔ lb gidiş-dönüş kayıpsıza yakın', () {
      final lb = imp.weightFromKg(100);
      expect(lb, closeTo(220.46, 0.01));
      expect(imp.weightToKg(lb), closeTo(100, 1e-9));
      expect(imp.weight(84.7), endsWith(' lb'));
    });
  });

  group('Units — uzunluk & boy', () {
    test('cm ↔ in', () {
      expect(imp.lengthFromCm(2.54), closeTo(1, 1e-9));
      expect(imp.lengthToCm(1), closeTo(2.54, 1e-9));
      expect(metric.length(94.5), '94.5 cm');
      expect(imp.lengthUnit, 'in');
    });

    test("boy ft-in: 180 cm ≈ 5'11\"", () {
      expect(Units.heightToFtIn(180), (5, 11));
      expect(imp.height(180), '5\'11"');
      expect(metric.height(180), '180 cm');
    });

    test('inç 12 olunca ft artar (183 cm = 6\'0")', () {
      expect(Units.heightToFtIn(183), (6, 0));
    });

    test('ftInToCm gidiş-dönüş', () {
      final cm = Units.ftInToCm(5, 11);
      expect(cm, closeTo(180.34, 0.01));
      expect(Units.heightToFtIn(cm), (5, 11));
    });
  });

  group('Units — mesafe', () {
    test('m → km / mi', () {
      expect(metric.distanceFromM(5200), closeTo(5.2, 1e-9));
      expect(imp.distanceFromM(1609.344), closeTo(1, 1e-9));
      expect(imp.distanceToM(1), closeTo(1609.344, 1e-9));
      expect(metric.distanceUnit, 'km');
      expect(imp.distanceUnit, 'mi');
    });
  });
}
