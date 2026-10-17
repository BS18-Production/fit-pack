import 'package:fit_pack/features/explore/program_catalog.dart';
import 'package:fit_pack/features/onboarding/program_recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

/// docs/49 §1 — 3 deneyim × 3 gün aralığı = 9 kombinasyon.
void main() {
  const table = {
    (TrainingExperience.beginner, WeeklyDays.twoThree): 'fullbody_beginner',
    (TrainingExperience.beginner, WeeklyDays.four): 'upperlower_beginner',
    (TrainingExperience.beginner, WeeklyDays.fiveSix): 'upperlower_beginner',
    (TrainingExperience.some, WeeklyDays.twoThree): 'fullbody_intermediate',
    (TrainingExperience.some, WeeklyDays.four): 'upperlower_intermediate',
    (TrainingExperience.some, WeeklyDays.fiveSix): 'ppl_intermediate',
    (TrainingExperience.long, WeeklyDays.twoThree): 'fullbody_advanced',
    (TrainingExperience.long, WeeklyDays.four): 'upperlower_advanced',
    (TrainingExperience.long, WeeklyDays.fiveSix): 'ppl_advanced',
  };

  test('9 kombinasyonun her biri tablodaki programa gider', () {
    for (final exp in TrainingExperience.values) {
      for (final days in WeeklyDays.values) {
        expect(
          recommendProgram(exp, days),
          table[(exp, days)],
          reason: '$exp × $days',
        );
      }
    }
  });

  test('önerilen her anahtar katalogda var', () {
    for (final key in table.values) {
      expect(programByKey(key), isNotNull, reason: key);
    }
  });

  test('dinlenme notu yalnız yeni başlayan + 5–6 gün', () {
    for (final exp in TrainingExperience.values) {
      for (final days in WeeklyDays.values) {
        expect(
          restDayNote(exp, days),
          exp == TrainingExperience.beginner && days == WeeklyDays.fiveSix,
        );
      }
    }
  });
}
