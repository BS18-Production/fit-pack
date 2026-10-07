import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/workout_dao.dart';
import 'package:fit_pack/features/workout/history_summary.dart';
import 'package:flutter_test/flutter_test.dart';

/// docs/31 — antrenman geçmişi özeti + detay hesapları.
void main() {
  var seq = 0;
  WorkoutSet set(int session, int ex, double? kg, int? reps,
          {bool warmup = false, double? rpe, int? sec}) =>
      WorkoutSet(
        id: ++seq,
        sessionId: session,
        exerciseId: ex,
        setNumber: seq,
        weightKg: kg,
        reps: reps,
        isWarmup: warmup,
        rpe: rpe,
        setType: warmup ? 'warmup' : 'normal',
        isComplete: true,
        durationSec: sec,
      );
  WorkoutSession session(int id, DateTime date) => WorkoutSession(
        id: id,
        date: date,
        phase: 0,
        workoutType: 'Push',
        kneeStatus: 'normal',
        isDeload: false,
      );

  group('en iyi set', () {
    test('e1RM önce: 80×8 > 90×2; ısınma sayılmaz', () {
      final best = bestSetOf([
        set(1, 1, 100, 5, warmup: true),
        set(1, 1, 90, 2),
        set(1, 1, 80, 8),
      ]);
      expect((best!.weightKg, best.reps), (80, 8));
    });

    test('vücut ağırlığı (kilosuz) tekrarla, süreli set süreyle', () {
      expect(bestSetOf([set(1, 1, null, 12), set(1, 1, null, 15)])!.reps, 15);
      expect(bestSetOf([set(1, 2, null, null, sec: 30), set(1, 2, null, null, sec: 45)])!
          .durationSec, 45);
    });

    test('hareket özeti seans sırasıyla, ısınma set sayısına girmez', () {
      final briefs = exerciseBriefs([
        set(1, 7, 20, 10, warmup: true),
        set(1, 7, 60, 8),
        set(1, 3, 30, 12),
        set(1, 7, 62.5, 8),
      ]);
      expect(briefs.map((b) => b.exerciseId), [7, 3]);
      expect(briefs.first.sets, 2);
      expect(briefs.first.best!.weightKg, 62.5);
    });
  });

  test('rekor sayısı: ilk seans rekor değil, aşan hareket başına 1', () {
    final s1 = session(1, DateTime(2026, 10, 1));
    final s2 = session(2, DateTime(2026, 10, 3));
    final s3 = session(3, DateTime(2026, 10, 5));
    final counts = recordCountsBySession([s3, s1, s2], {
      1: [set(1, 1, 60, 8), set(1, 2, 20, 10)],
      2: [set(2, 1, 62.5, 8), set(2, 1, 65, 8), set(2, 2, 20, 10)],
      3: [set(3, 1, 60, 8), set(3, 2, 22, 10)],
    });
    expect(counts, {1: 0, 2: 1, 3: 1});
  });

  group('geçen sefere göre', () {
    final history = [
      ExerciseSetPoint(date: DateTime(2026, 9, 1), weightKg: 100, reps: 5),
      ExerciseSetPoint(date: DateTime(2026, 9, 5), weightKg: 75, reps: 8),
      ExerciseSetPoint(date: DateTime(2026, 9, 5), weightKg: 77.5, reps: 6),
      ExerciseSetPoint(date: DateTime(2026, 9, 9), weightKg: 90, reps: 8),
    ];

    test('önceki = seanstan önceki SON seansın en iyisi', () {
      final p = previousBest(history, DateTime(2026, 9, 9));
      expect((p!.weightKg, p.reps), (75, 8)); // 75×8 e1RM > 77.5×6
      expect(previousBest(history, DateTime(2026, 9, 1)), isNull);
    });

    test('fark: kilo, kilo aynıysa tekrar, ikisi aynıysa "aynı"', () {
      final prev = previousBest(history, DateTime(2026, 9, 9));
      expect((deltaVsPrevious(set(1, 1, 80, 8), prev) as WeightDelta).kg, 5);
      expect((deltaVsPrevious(set(1, 1, 75, 10), prev) as RepsDelta).reps, 2);
      expect(deltaVsPrevious(set(1, 1, 75, 8), prev), isA<SameAsLast>());
      expect(deltaVsPrevious(set(1, 1, 75, 8), null), isNull);
    });
  });

  test('çalışan kaslar: set sayısıyla, çoktan aza; ısınma hariç', () {
    final split = muscleSplit([
      set(1, 1, 60, 8),
      set(1, 1, 60, 8),
      set(1, 1, 20, 8, warmup: true),
      set(1, 2, 10, 12),
      set(1, 3, 10, 12),
      set(1, 3, 10, 12),
      set(1, 3, 10, 12),
    ], {1: 'chest', 2: 'shoulders', 3: 'triceps'});
    expect(split, [('triceps', 3), ('chest', 2), ('shoulders', 1)]);
  });
}
