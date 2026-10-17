import 'package:fit_pack/core/utils/current_day.dart';
import 'package:fit_pack/features/nutrition/nutrition_habit_providers.dart';
import 'package:fit_pack/features/nutrition/nutrition_habits.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Beslenme gün gezinmesi takvim günüyle, öğün dilimi gün içinde kendiliğinden
/// ilerler (CR-011 / CR-010 artıkları).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('gün okları ve "dünü kopyala"', () {
    test('saatli seçili günden takvimle önceki/sonraki güne gider', () {
      // Avrupa yaz saati günleri (23 ve 25 saatlik günler): ±24 saat bu
      // günlerde bir önceki günün 23:00'ına ya da aynı güne düşebilir.
      final ilkbahar = DateTime(2026, 3, 29, 0, 30);
      expect(addDays(ilkbahar, -1), DateTime(2026, 3, 28));
      expect(addDays(ilkbahar, 1), DateTime(2026, 3, 30));

      final sonbahar = DateTime(2026, 10, 25, 23, 30);
      expect(addDays(sonbahar, 1), DateTime(2026, 10, 26));
      expect(addDays(sonbahar, -1), DateTime(2026, 10, 24));

      // Ay sınırı: "dünü kopyala" 1 Kasım'dan 31 Ekim'e.
      expect(addDays(DateTime(2026, 11, 1, 8), -1), DateTime(2026, 10, 31));
    });
  });

  group('öğün dilimi sınırı', () {
    test('mealForTime ile aynı sınırlar', () {
      DateTime t(int h, int m) => DateTime(2026, 10, 17, h, m);
      expect(nextMealSlotBoundary(t(7, 0)), t(11, 0));
      expect(nextMealSlotBoundary(t(10, 59)), t(11, 0));
      expect(nextMealSlotBoundary(t(11, 0)), t(16, 0));
      expect(nextMealSlotBoundary(t(16, 30)), t(18, 0));
      expect(nextMealSlotBoundary(t(18, 0)), DateTime(2026, 10, 18));
      expect(nextMealSlotBoundary(t(23, 59)), DateTime(2026, 10, 18));
      // Her sınırda dilim gerçekten değişir.
      for (final s in [t(7, 0), t(12, 0), t(17, 0), t(20, 0)]) {
        final b = nextMealSlotBoundary(s);
        expect(mealForTime(b), isNot(mealForTime(s)));
        expect(mealForTime(b.subtract(const Duration(minutes: 1))),
            mealForTime(s));
      }
    });

    testWidgets('kahvaltı → öğle sınırında provider kendiliğinden ilerler',
        (tester) async {
      var saat = DateTime(2026, 10, 17, 10, 59, 30);
      final c = ProviderContainer(overrides: [
        mealSlotClockProvider.overrideWithValue(() => saat),
      ]);
      final degerler = <String>[];
      c.listen(currentMealSlotProvider, (_, v) => degerler.add(v),
          fireImmediately: true);
      expect(degerler, ['breakfast']);

      await tester.pump(const Duration(seconds: 20));
      expect(degerler, ['breakfast'], reason: 'sınırdan önce değişmez');

      // 10:59:30 + 31 sn (11:00 + 1 sn pay).
      saat = DateTime(2026, 10, 17, 11, 0, 1);
      await tester.pump(const Duration(seconds: 11));
      c.read(currentMealSlotProvider); // geçersizleşen provider'ı kur
      expect(degerler, ['breakfast', 'lunch']);

      // Yeniden kuruldu: bir sonraki sınır 16:00.
      saat = DateTime(2026, 10, 17, 16, 0, 1);
      await tester.pump(const Duration(hours: 5));
      c.read(currentMealSlotProvider);
      expect(degerler, ['breakfast', 'lunch', 'snack']);
      c.dispose(); // zamanlayıcı iptal — test bitmeden
    });

    testWidgets('akşam yemeği → gece yarısı kahvaltıya döner', (tester) async {
      var saat = DateTime(2026, 10, 17, 23, 59, 50);
      final c = ProviderContainer(overrides: [
        mealSlotClockProvider.overrideWithValue(() => saat),
      ]);
      expect(c.read(currentMealSlotProvider), 'dinner');

      saat = DateTime(2026, 10, 18, 0, 0, 1);
      await tester.pump(const Duration(seconds: 11));
      expect(c.read(currentMealSlotProvider), 'breakfast');
      c.dispose();
    });
  });
}
