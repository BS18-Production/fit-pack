import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/insights/insight_queries.dart';
import 'package:fit_pack/features/insights/insight_window.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Verime sor" yeni hesaplar (docs/36 §1): dönem pencereleri,
/// today_remaining, top_exercises, beslenme penceresi. Saf Dart.
void main() {
  // Pazar 2026-10-11 akşamı; hafta pazartesi başlar (2026-10-05).
  final now = DateTime(2026, 10, 11, 19);

  var seq = 0;
  FoodLog ogun(
    DateTime d, {
    int food = 1,
    String meal = 'dinner',
    double grams = 100,
    double kcal = 500,
    double protein = 40,
  }) => FoodLog(
    id: ++seq,
    date: d,
    mealType: meal,
    foodId: food,
    grams: grams,
    computedKcal: kcal,
    computedProtein: protein,
    computedCarb: 0,
    computedFat: 0,
  );
  WorkoutSession seans(DateTime d) => WorkoutSession(
    id: ++seq,
    date: d,
    phase: 1,
    workoutType: 'push',
    kneeStatus: 'normal',
    isDeload: false,
  );
  WorkoutSet set(
    int sessionId,
    int exerciseId, {
    bool complete = true,
    bool warmup = false,
  }) => WorkoutSet(
    id: ++seq,
    sessionId: sessionId,
    exerciseId: exerciseId,
    setNumber: 1,
    weightKg: 50,
    reps: 10,
    isWarmup: warmup,
    setType: 'normal',
    isComplete: complete,
  );

  group('dönem pencereleri [start, end)', () {
    test('son 30 gün bugünü içerir: [bugün−29, yarın)', () {
      final w = windowFor(InsightPeriod.last30Days, now);
      expect(w.start, DateTime(2026, 9, 12));
      expect(w.end, DateTime(2026, 10, 12));
      expect(w.days, 30);
      expect(w.contains(DateTime(2026, 9, 11, 23, 59)), isFalse);
      expect(w.contains(DateTime(2026, 10, 12)), isFalse, reason: 'end hariç');
    });

    test('bu hafta devam ediyor, geçen hafta tamamlanmış', () {
      final bu = windowFor(InsightPeriod.thisWeek, now);
      final gecen = windowFor(InsightPeriod.lastWeek, now);
      expect(bu.start, DateTime(2026, 10, 5));
      expect(bu.isComplete, isFalse);
      expect(gecen.start, DateTime(2026, 9, 28));
      expect(gecen.end, DateTime(2026, 10, 5));
      expect(gecen.isComplete, isTrue);
    });

    test('pazar başlangıçlı hafta', () {
      final bu = windowFor(
        InsightPeriod.thisWeek,
        now,
        weekStart: DateTime.sunday,
      );
      expect(bu.start, DateTime(2026, 10, 11));
    });

    test('tüm zamanlar: başlangıç yok, yarından önceki her şey', () {
      final w = windowFor(InsightPeriod.allTime, now);
      expect(w.start, isNull);
      expect(w.days, isNull);
      expect(w.contains(DateTime(2001)), isTrue);
    });
  });

  group('today_remaining', () {
    test('kalan = hedef − bugünkü kayıtlar; dün sayılmaz', () {
      final r = computeTodayRemaining(
        now: now,
        logs: [
          ogun(
            DateTime(2026, 10, 11, 8),
            meal: 'breakfast',
            kcal: 600,
            protein: 30,
          ),
          ogun(
            DateTime(2026, 10, 11, 13),
            meal: 'lunch',
            kcal: 700,
            protein: 50,
          ),
          ogun(DateTime(2026, 10, 10, 20), kcal: 900, protein: 60), // dün
        ],
        kcalGoal: 2200,
        proteinGoal: 150,
      );
      expect(r.loggedKcal, 1300);
      expect(r.remainingKcal, 900);
      expect(r.remainingProtein, 70);
    });

    test('hedef yoksa kalan null, öneri yok', () {
      final r = computeTodayRemaining(
        now: now,
        logs: [ogun(DateTime(2026, 10, 1, 20))],
        kcalGoal: 0,
        proteinGoal: 0,
      );
      expect(r.remainingKcal, isNull);
      expect(r.suggestions, isEmpty);
    });

    test('öneri yalnız o öğünün geçmişinden, kalana sığan, en çok 3', () {
      final logs = [
        // akşam geçmişi
        ogun(DateTime(2026, 10, 1, 20), food: 1, kcal: 400, protein: 35),
        ogun(DateTime(2026, 10, 3, 20), food: 1, kcal: 400, protein: 35),
        ogun(DateTime(2026, 10, 2, 20), food: 2, kcal: 300, protein: 40),
        ogun(DateTime(2026, 10, 4, 20), food: 3, kcal: 350, protein: 10),
        ogun(DateTime(2026, 10, 5, 20), food: 4, kcal: 450, protein: 20),
        ogun(
          DateTime(2026, 10, 6, 20),
          food: 5,
          kcal: 1200,
          protein: 80,
        ), // sığmaz
        ogun(
          DateTime(2026, 10, 7, 13),
          food: 6,
          meal: 'lunch',
          kcal: 100,
        ), // öğle
        ogun(DateTime(2026, 9, 10, 20), food: 7, kcal: 100), // 30 günden eski
        // bugün
        ogun(
          DateTime(2026, 10, 11, 13),
          meal: 'lunch',
          kcal: 1500,
          protein: 90,
        ),
      ];
      final r = computeTodayRemaining(
        now: now,
        logs: logs,
        kcalGoal: 2000,
        proteinGoal: 150,
        mealType: 'dinner',
      );
      expect(r.remainingKcal, 500);
      // 1: en sık (2 kez); sonra tek seferlikler protein ↓: 2 (40), 4 (20), 3 (10)
      expect(r.suggestions.map((s) => s.foodId), [1, 2, 4]);
      expect(r.suggestions.first.timesEaten, 2);
    });

    test('her zamanki porsiyon = medyan gramajlı gerçek kayıt', () {
      final r = computeTodayRemaining(
        now: now,
        logs: [
          ogun(DateTime(2026, 10, 1, 20), grams: 100, kcal: 200),
          ogun(DateTime(2026, 10, 2, 20), grams: 300, kcal: 600),
          ogun(DateTime(2026, 10, 3, 20), grams: 150, kcal: 300),
        ],
        kcalGoal: 2000,
        proteinGoal: 0,
        mealType: 'dinner',
      );
      expect(r.suggestions.single.grams, 150);
      expect(r.suggestions.single.kcal, 300);
    });

    test('hedef aşıldıysa öneri yok, kalan negatif', () {
      final r = computeTodayRemaining(
        now: now,
        logs: [
          ogun(DateTime(2026, 10, 11, 13), kcal: 2500),
          ogun(DateTime(2026, 10, 1, 20), kcal: 100),
        ],
        kcalGoal: 2000,
        proteinGoal: 100,
      );
      expect(r.remainingKcal, -500);
      expect(r.suggestions, isEmpty);
    });
  });

  group('top_exercises', () {
    test(
      'set sayısına göre sıralı; ısınma/tamamlanmamış/pencere dışı sayılmaz',
      () {
        final a = seans(DateTime(2026, 10, 6, 18));
        final b = seans(DateTime(2026, 10, 8, 18));
        final eski = seans(DateTime(2026, 9, 1, 18));
        final r = topExercises(
          window: windowFor(InsightPeriod.last30Days, now),
          sessions: [a, b, eski],
          setsBySession: {
            a.id: [set(a.id, 10), set(a.id, 10), set(a.id, 20), set(a.id, 30)],
            b.id: [
              set(b.id, 20),
              set(b.id, 30),
              set(b.id, 10, warmup: true),
              set(b.id, 10, complete: false),
            ],
            eski.id: [for (var i = 0; i < 9; i++) set(eski.id, 40)],
          },
        );
        // 10: 2 set/1 seans; 20: 2 set/2 seans; 30: 2 set/2 seans
        // → 20 ve 30 seansla öne geçer, aralarında id küçük önde.
        expect(r.map((e) => e.exerciseId), [20, 30, 10]);
        expect(r.first.sets, 2);
        expect(r.first.sessions, 2);
      },
    );

    test('en çok 5 hareket', () {
      final s = seans(DateTime(2026, 10, 9));
      final r = topExercises(
        window: windowFor(InsightPeriod.allTime, now),
        sessions: [s],
        setsBySession: {
          s.id: [for (var id = 1; id <= 7; id++) set(s.id, id)],
        },
      );
      expect(r, hasLength(5));
    });
  });

  group('beslenme penceresi', () {
    test('kayıtsız gün ortalamaya girmez; hedef günü ≥', () {
      final w = windowFor(InsightPeriod.last30Days, now);
      final s = nutritionStats(
        window: w,
        logs: [
          ogun(DateTime(2026, 10, 1, 8), protein: 80),
          ogun(DateTime(2026, 10, 1, 20), protein: 70), // gün: 150
          ogun(DateTime(2026, 10, 5, 20), protein: 100),
          ogun(DateTime(2026, 9, 1, 20), protein: 999), // pencere dışı
        ],
        proteinGoal: 150,
        kcalGoal: 2000,
      );
      expect(s.loggedDays, 2);
      expect(s.avgProtein, 125);
      expect(s.proteinGoalDays, 1);
    });

    test('kayıt yoksa ortalama null', () {
      final s = nutritionStats(
        window: windowFor(InsightPeriod.thisWeek, now),
        logs: const [],
      );
      expect(s.loggedDays, 0);
      expect(s.avgKcal, isNull);
    });
  });
}
