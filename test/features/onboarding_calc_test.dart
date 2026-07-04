import 'package:flutter_test/flutter_test.dart';
import 'package:fit_pack/features/onboarding/onboarding_calc.dart';

void main() {
  group('suggestGoals', () {
    test('cut 85 kg → bakım 2805 × 0.8 = 2244 → 2250 (50 yuvarlama)', () {
      final g = suggestGoals(weightKg: 85, phase: OnboardingPhase.cut);
      expect(g.kcal, 2250);
      expect(g.protein, 170); // 85 × 2.0
    });

    test('bulk 70 kg → 2310 × 1.1 = 2541 → 2550; protein 70×1.8=126→125', () {
      final g = suggestGoals(weightKg: 70, phase: OnboardingPhase.bulk);
      expect(g.kcal, 2550);
      expect(g.protein, 125);
    });
  });

  group('projectWeeks (docs/15 §A3)', () {
    test('cut 85→80, varsayılan açık (%20) → ~10 hafta', () {
      // bakım 2805, açık 561/gün → 0.51 kg/hafta → 5 kg / 0.51 = 9.8 → 10
      final w = projectWeeks(
          weightKg: 85, goalWeightKg: 80, phase: OnboardingPhase.cut);
      expect(w, 10);
    });

    test('cut: kullanıcının girdiği kaloriyle güncellenir', () {
      // bakım 2805, kullanıcı 2305 girdi → açık 500 → 0.4545 kg/hafta
      // 5 / 0.4545 = 11.0 → 11
      final w = projectWeeks(
          weightKg: 85,
          goalWeightKg: 80,
          phase: OnboardingPhase.cut,
          kcalGoal: 2305);
      expect(w, 11);
    });

    test('bulk 70→75, varsayılan fazla (%10) → 24 hafta', () {
      // bakım 2310, fazla 231/gün → 0.21 kg/hafta → 5 / 0.21 = 23.8 → 24
      final w = projectWeeks(
          weightKg: 70, goalWeightKg: 75, phase: OnboardingPhase.bulk);
      expect(w, 24);
    });

    test('koruma fazı → null (projeksiyon yok)', () {
      expect(
          projectWeeks(
              weightKg: 80,
              goalWeightKg: 75,
              phase: OnboardingPhase.maintenance),
          isNull);
    });

    test('cut ama hedef ≥ mevcut → null (yön tutarsız)', () {
      expect(
          projectWeeks(
              weightKg: 80, goalWeightKg: 85, phase: OnboardingPhase.cut),
          isNull);
    });

    test('hedef kilo yok → null', () {
      expect(
          projectWeeks(
              weightKg: 80, goalWeightKg: null, phase: OnboardingPhase.cut),
          isNull);
    });

    test('cut ama girilen kalori bakımın üstünde (açık yok) → null', () {
      expect(
          projectWeeks(
              weightKg: 85,
              goalWeightKg: 80,
              phase: OnboardingPhase.cut,
              kcalGoal: 3000),
          isNull);
    });

    test('çok küçük mesafe → en az 1 hafta', () {
      final w = projectWeeks(
          weightKg: 80.2, goalWeightKg: 80, phase: OnboardingPhase.cut);
      expect(w, 1);
    });
  });
}
