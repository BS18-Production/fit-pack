import 'package:flutter_test/flutter_test.dart';
import 'package:fit_pack/features/workout/workout_draft.dart';
import 'package:fit_pack/features/workout/calorie_estimate.dart';

void main() {
  group('WorkoutDraft serialize round-trip', () {
    test('encode → decode tüm alanları korur', () {
      final draft = WorkoutDraft(
        title: 'Push Day',
        routineId: 7,
        startedAtMs: 1719750000000,
        sessionDateMs: 1719705600000,
        exercises: [
          DraftExercise(
            exerciseId: 12,
            restSec: 90,
            previous: '60×8',
            sets: [
              DraftSet(weight: 60, reps: 10, rpe: 8, type: 'normal', done: true),
              DraftSet(weight: 60, reps: 6, type: 'failure', done: false),
            ],
          ),
          DraftExercise(
            exerciseId: 30,
            restSec: 0,
            previous: null,
            sets: [DraftSet(durationSec: 750, distanceM: 5200)],
          ),
        ],
      );

      final restored = WorkoutDraft.decode(draft.encode())!;

      expect(restored.title, 'Push Day');
      expect(restored.routineId, 7);
      expect(restored.startedAtMs, draft.startedAtMs);
      expect(restored.sessionDateMs, draft.sessionDateMs);
      expect(restored.exercises.length, 2);

      final e0 = restored.exercises[0];
      expect(e0.exerciseId, 12);
      expect(e0.restSec, 90);
      expect(e0.previous, '60×8');
      expect(e0.sets.length, 2);
      expect(e0.sets[0].weight, 60);
      expect(e0.sets[0].reps, 10);
      expect(e0.sets[0].rpe, 8);
      expect(e0.sets[0].done, true);
      expect(e0.sets[1].type, 'failure');
      expect(e0.sets[1].done, false);

      final e1 = restored.exercises[1];
      expect(e1.previous, isNull);
      expect(e1.sets[0].durationSec, 750);
      expect(e1.sets[0].distanceM, 5200);
    });

    test('bozuk JSON → null (çökmez)', () {
      expect(WorkoutDraft.decode('}{ bozuk'), isNull);
      expect(WorkoutDraft.decode(''), isNull);
    });

    test('hasData: veri/✓ yoksa false, varsa true', () {
      WorkoutDraft d(List<DraftSet> sets) => WorkoutDraft(
            title: 't',
            routineId: null,
            startedAtMs: 0,
            sessionDateMs: 0,
            exercises: [
              DraftExercise(
                  exerciseId: 1, restSec: 0, previous: null, sets: sets)
            ],
          );
      expect(d([DraftSet()]).hasData, false);
      expect(d([DraftSet(reps: 5)]).hasData, true);
      expect(d([DraftSet(done: true)]).hasData, true);
      expect(d([DraftSet(distanceM: 1000)]).hasData, true);
    });
  });

  group('estimateWorkoutKcal', () {
    test('kilo veya süre yoksa → null', () {
      expect(
          estimateWorkoutKcal(
              bodyWeightKg: null, durationMin: 40, isCardio: false),
          isNull);
      expect(
          estimateWorkoutKcal(
              bodyWeightKg: 84, durationMin: null, isCardio: false),
          isNull);
      expect(
          estimateWorkoutKcal(
              bodyWeightKg: 84, durationMin: 0, isCardio: false),
          isNull);
    });

    test('RPE yok → MET 5.0 ile ACSM formülü', () {
      // 5.0 × 3.5 × 84 / 200 × 41 ≈ 301.35
      final kcal = estimateWorkoutKcal(
          bodyWeightKg: 84, durationMin: 41, isCardio: false);
      expect(kcal, isNotNull);
      expect(kcal!, closeTo(301.35, 0.5));
    });

    test('yüksek RPE → daha yüksek MET → daha çok kalori', () {
      final light = estimateWorkoutKcal(
          bodyWeightKg: 84, durationMin: 41, avgRpe: 5, isCardio: false)!;
      final hard = estimateWorkoutKcal(
          bodyWeightKg: 84, durationMin: 41, avgRpe: 10, isCardio: false)!;
      expect(hard, greaterThan(light));
    });

    test('kardiyo → MET 7.0 (RPE yok sabitinden yüksek)', () {
      final cardio = estimateWorkoutKcal(
          bodyWeightKg: 84, durationMin: 41, isCardio: true)!;
      final strength = estimateWorkoutKcal(
          bodyWeightKg: 84, durationMin: 41, isCardio: false)!;
      expect(cardio, greaterThan(strength));
    });
  });

  group('BMR / TDEE (Mifflin-St Jeor)', () {
    test('ageFromBirthDate doğum günü öncesi/sonrası', () {
      final now = DateTime(2026, 6, 30);
      expect(ageFromBirthDate(DateTime(1997, 8, 14), now: now), 28); // d.günü gelmedi
      expect(ageFromBirthDate(DateTime(1997, 6, 30), now: now), 29); // bugün d.günü
      expect(ageFromBirthDate(DateTime(1997, 5, 1), now: now), 29);
      expect(ageFromBirthDate(null, now: now), isNull);
    });

    test('erkek BMR Mifflin-St Jeor', () {
      // 10·84 + 6.25·180 − 5·28 + 5 = 840 + 1125 − 140 + 5 = 1830
      final bmr = mifflinStJeorBmr(
          weightKg: 84, heightCm: 180, age: 28, gender: 'male');
      expect(bmr, closeTo(1830, 0.01));
    });

    test('kadın BMR erkekten 166 düşük (aynı girdi)', () {
      final m = mifflinStJeorBmr(
          weightKg: 84, heightCm: 180, age: 28, gender: 'male')!;
      final f = mifflinStJeorBmr(
          weightKg: 84, heightCm: 180, age: 28, gender: 'female')!;
      expect(m - f, closeTo(166, 0.01)); // +5 vs −161
    });

    test('eksik veri → null', () {
      expect(
          mifflinStJeorBmr(
              weightKg: null, heightCm: 180, age: 28, gender: 'male'),
          isNull);
      expect(
          mifflinStJeorBmr(
              weightKg: 84, heightCm: 180, age: 28, gender: null),
          isNull);
      expect(
          mifflinStJeorBmr(
              weightKg: 84, heightCm: 180, age: null, gender: 'male'),
          isNull);
    });

    test('TDEE = BMR × aktiflik çarpanı, null aktiflik → moderate (1.55)', () {
      expect(tdee(bmr: 1830, activityLevel: 'sedentary'), closeTo(2196, 0.01));
      expect(tdee(bmr: 1830, activityLevel: 'moderate'), closeTo(2836.5, 0.01));
      expect(tdee(bmr: 1830, activityLevel: null), closeTo(2836.5, 0.01));
      expect(tdee(bmr: null, activityLevel: 'active'), isNull);
    });
  });
}
