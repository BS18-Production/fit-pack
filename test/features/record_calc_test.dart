import 'package:flutter_test/flutter_test.dart';
import 'package:fit_pack/data/database/daos/workout_dao.dart';
import 'package:fit_pack/features/workout/record_calc.dart';

/// Kişisel rekor hesabı (record_calc) — Rekorlar sekmesiyle tutarlı:
/// e1RM (Epley) + en ağır kilo; geçmişi olmayan hareket rekor üretmez.
void main() {
  ExerciseSetPoint p(double? kg, int? reps, {DateTime? date}) =>
      ExerciseSetPoint(
          date: date ?? DateTime(2026, 6, 1), weightKg: kg, reps: reps);

  group('epley', () {
    test('80 kg × 8 tekrar ≈ 101.3', () {
      expect(epley(80, 8), closeTo(101.33, 0.01));
    });
    test('eksik/geçersiz girdi → null', () {
      expect(epley(null, 8), isNull);
      expect(epley(80, null), isNull);
      expect(epley(0, 8), isNull);
      expect(epley(80, 0), isNull);
    });
  });

  group('bestsOf', () {
    test('en iyi e1RM ve en ağır kilo farklı setlerden gelebilir', () {
      // 100×1 → e1RM 103.3 (en ağır) · 80×10 → e1RM 106.7 (en iyi e1RM)
      final b = bestsOf([p(100, 1), p(80, 10)]);
      expect(b.weightKg, 100);
      expect(b.e1rm, closeTo(106.67, 0.01));
    });
    test('boş liste → isEmpty', () {
      expect(bestsOf(const []).isEmpty, true);
    });
  });

  group('newRecordFor', () {
    final prior = [p(80, 8), p(85, 5)]; // best e1RM ≈ 101.3 · en ağır 85

    test('geçmiş boşsa rekor yok (ilk seansın her seti rekor olmasın)', () {
      expect(
          newRecordFor(
              name: 'Bench', priorHistory: const [], sessionPoints: [p(60, 10)]),
          isNull);
    });

    test('e1RM aşımı → e1RM rekoru (öncelikli)', () {
      // 90×6 → e1RM 108 > 101.3 VE 90 > 85 (iki rekor birden) → e1RM önce.
      final r = newRecordFor(
          name: 'Bench', priorHistory: prior, sessionPoints: [p(90, 6)]);
      expect(r, isNotNull);
      expect(r!.isE1rm, true);
      expect(r.value, closeTo(108, 0.01));
      expect(r.weightKg, 90);
      expect(r.reps, 6);
    });

    test('yalnız kilo aşımı → en ağır rekoru', () {
      // 87×1 → e1RM 89.9 (aşmaz) ama 87 > 85 → kilo rekoru.
      final r = newRecordFor(
          name: 'Bench', priorHistory: prior, sessionPoints: [p(87, 1)]);
      expect(r, isNotNull);
      expect(r!.isE1rm, false);
      expect(r.value, 87);
    });

    test('aşım yoksa null', () {
      expect(
          newRecordFor(
              name: 'Bench', priorHistory: prior, sessionPoints: [p(80, 8)]),
          isNull);
    });

    test('seansın en iyi seti raporlanır (birden çok aşan set)', () {
      final r = newRecordFor(
          name: 'Bench',
          priorHistory: prior,
          sessionPoints: [p(90, 6), p(92, 6)]); // ikisi de aşar, 92×6 en iyi
      expect(r!.weightKg, 92);
    });
  });
}
