import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/workout_dao.dart';
import 'package:fit_pack/features/home/dashboard_stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Ana Sayfa dashboard saf hesap katmanı + içgörü DAO sorgusu testleri.
void main() {
  group('aggregateWorkouts', () {
    test('hacim = Σ kg×tekrar, boş seans 0', () {
      final sessions = [
        WorkoutSession(
            id: 1,
            date: DateTime(2026, 7, 1),
            phase: 0,
            workoutType: 'Push',
            kneeStatus: 'normal',
            isDeload: false),
      ];
      WorkoutSet set(int id, double kg, int reps) => WorkoutSet(
            id: id,
            sessionId: 1,
            exerciseId: 1,
            setNumber: id,
            weightKg: kg,
            reps: reps,
            isWarmup: false,
            setType: 'normal',
            isComplete: true,
          );
      final agg = aggregateWorkouts(
        sessions: sessions,
        setsBySession: {
          1: [set(1, 60, 10), set(2, 60, 8)],
        },
        bodyWeightKg: 80,
      );
      expect(agg.sessions, 1);
      expect(agg.volumeKg, (60 * 10 + 60 * 8)); // 1080
      // kcal: süre yok → estimateWorkoutKcal null → 0.
      expect(agg.kcalBurned, 0);
    });
  });

  group('volumeDeltaPct', () {
    test('önceki 0 ise null; normal yüzde', () {
      expect(volumeDeltaPct(100, 0), isNull);
      expect(volumeDeltaPct(120, 100), 20);
      expect(volumeDeltaPct(80, 100), -20);
    });
  });

  group('weeklyProteinAdherencePct', () {
    FoodLog log(DateTime d, double protein) => FoodLog(
          id: d.millisecondsSinceEpoch,
          date: d,
          mealType: 'lunch',
          foodId: 1,
          grams: 100,
          computedKcal: 0,
          computedProtein: protein,
          computedCarb: 0,
          computedFat: 0,
        );
    test('kayıtlı günlerin ortalaması; kayıt yoksa null', () {
      expect(weeklyProteinAdherencePct([], 150), isNull);
      // Gün1: 150/150=100%, Gün2: 75/150=50% → ort %75.
      final logs = [
        log(DateTime(2026, 7, 1), 100),
        log(DateTime(2026, 7, 1), 50),
        log(DateTime(2026, 7, 2), 75),
      ];
      expect(weeklyProteinAdherencePct(logs, 150), 75);
    });
    test('hedef 0 → null', () {
      expect(weeklyProteinAdherencePct([log(DateTime(2026, 7, 1), 100)], 0),
          isNull);
    });
  });

  group('topProgressExercise', () {
    ExerciseProgressPoint p(int exId, String name, DateTime d, double kg, int reps) =>
        ExerciseProgressPoint(
            exerciseId: exId, name: name, date: d, weightKg: kg, reps: reps);

    test('en büyük pozitif e1RM artışını seçer', () {
      final points = [
        // Bench: ilk gün 60×8 (e1RM 76), son gün 70×8 (e1RM ~88.7) → +~12.7
        p(1, 'Bench', DateTime(2026, 6, 1), 60, 8),
        p(1, 'Bench', DateTime(2026, 6, 20), 70, 8),
        // Squat: 100×5 (117) → 102×5 (119) → +~2
        p(2, 'Squat', DateTime(2026, 6, 1), 100, 5),
        p(2, 'Squat', DateTime(2026, 6, 20), 102, 5),
      ];
      final top = topProgressExercise(points);
      expect(top, isNotNull);
      expect(top!.name, 'Bench');
      expect(top.deltaE1rm, greaterThan(10));
    });

    test('tek günlük veri → null (en az 2 gün gerekir)', () {
      final points = [p(1, 'Bench', DateTime(2026, 6, 1), 60, 8)];
      expect(topProgressExercise(points), isNull);
    });

    test('yalnız gerileme → null (pozitif delta yok)', () {
      final points = [
        p(1, 'Bench', DateTime(2026, 6, 1), 70, 8),
        p(1, 'Bench', DateTime(2026, 6, 20), 60, 8),
      ];
      expect(topProgressExercise(points), isNull);
    });
  });

  group('getWeightedSetPointsInRange (DAO)', () {
    late AppDatabase db;
    setUp(() => db = newTestDatabase());
    tearDown(() => db.close());

    test('aralık + ısınma + null filtreleri doğru', () async {
      final exId = await db.workoutDao.insertCustomExercise(
        const ExercisesCompanion(
            name: Value('Bench'),
            category: Value('push'),
            muscleGroups: Value('[]')),
      );
      Future<int> session(DateTime d) => db.workoutDao.insertSession(
            WorkoutSessionsCompanion(
                date: Value(d),
                phase: const Value(0),
                workoutType: const Value('Push')),
          );
      final sIn = await session(DateTime(2026, 7, 2, 18));
      final sOut = await session(DateTime(2026, 6, 1, 18)); // aralık dışı

      await db.workoutDao.insertSet(WorkoutSetsCompanion(
          sessionId: Value(sIn),
          exerciseId: Value(exId),
          setNumber: const Value(1),
          weightKg: const Value(60),
          reps: const Value(8)));
      // ısınma → hariç
      await db.workoutDao.insertSet(WorkoutSetsCompanion(
          sessionId: Value(sIn),
          exerciseId: Value(exId),
          setNumber: const Value(2),
          weightKg: const Value(40),
          reps: const Value(10),
          isWarmup: const Value(true)));
      // kg null → hariç
      await db.workoutDao.insertSet(WorkoutSetsCompanion(
          sessionId: Value(sIn),
          exerciseId: Value(exId),
          setNumber: const Value(3),
          reps: const Value(12)));
      // aralık dışı seans → hariç
      await db.workoutDao.insertSet(WorkoutSetsCompanion(
          sessionId: Value(sOut),
          exerciseId: Value(exId),
          setNumber: const Value(1),
          weightKg: const Value(50),
          reps: const Value(5)));

      final points = await db.workoutDao.getWeightedSetPointsInRange(
          DateTime(2026, 7, 1), DateTime(2026, 7, 8));
      expect(points, hasLength(1));
      expect(points.single.name, 'Bench');
      expect(points.single.weightKg, 60);
      expect(points.single.e1rm, closeTo(60 * (1 + 8 / 30), 0.001));
    });
  });
}
