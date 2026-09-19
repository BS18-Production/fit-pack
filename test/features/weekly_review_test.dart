import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/workout_dao.dart';
import 'package:fit_pack/features/home/dashboard_stats.dart';
import 'package:fit_pack/features/insights/weekly_review.dart';
import 'package:flutter_test/flutter_test.dart';

/// Haftalık değerlendirme motoru (docs/22 §7 — W-1 … W-9).
///
/// Saf Dart: veritabanı yok, her kural elle kurulan girdiyle ölçülür.
void main() {
  // Pazartesi 2026-09-14 başlayan hafta; "şimdi" Pazar akşamı → hafta bitti.
  final pzt = DateTime(2026, 9, 14);
  final pazarAksami = DateTime(2026, 9, 21, 20); // bir sonraki pazartesi değil
  final hafta = pzt;

  var seq = 0;
  WorkoutSession seans(DateTime d, {int? dk}) => WorkoutSession(
        id: ++seq,
        date: d,
        phase: 1,
        workoutType: 'push',
        kneeStatus: 'normal',
        isDeload: false,
        durationMin: dk,
      );
  WorkoutSet set(int sessionId,
          {int exerciseId = 1,
          double? kg = 100,
          int? reps = 10,
          bool complete = true,
          bool warmup = false}) =>
      WorkoutSet(
        id: ++seq,
        sessionId: sessionId,
        exerciseId: exerciseId,
        setNumber: 1,
        weightKg: kg,
        reps: reps,
        isWarmup: warmup,
        setType: 'normal',
        isComplete: complete,
      );
  FoodLog ogun(DateTime d, {double kcal = 500, double protein = 40}) =>
      FoodLog(
        id: ++seq,
        date: d,
        mealType: 'lunch',
        foodId: 1,
        grams: 100,
        computedKcal: kcal,
        computedProtein: protein,
        computedCarb: 0,
        computedFat: 0,
      );
  BodyMeasurement tarti(DateTime d, double kg) =>
      BodyMeasurement(id: ++seq, date: d, weightKg: kg);
  ExerciseProgressPoint nokta(int id, String ad, DateTime d, double kg,
          int reps) =>
      ExerciseProgressPoint(
          exerciseId: id, name: ad, date: d, weightKg: kg, reps: reps);

  // ───────────────────────── W-1 / W-2: pencere ─────────────────────────

  group('W-1 hafta penceresi [start, end)', () {
    test('bitiş anı dahil DEĞİL — bir sonraki haftanın ilk seansı sayılmaz',
        () {
      final ic = seans(pzt.add(const Duration(days: 6, hours: 23)));
      final sinirda = seans(pzt.add(const Duration(days: 7))); // pzt 00:00
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        sessions: [ic], // sağlayıcı zaten [start, end) sorgular
        foodLogs: [
          ogun(pzt.add(const Duration(days: 6, hours: 23))),
          ogun(sinirda.date), // sınırdaki öğün süzülmeli
        ],
      ));
      expect(r.workout.sessions, 1);
      expect(r.nutrition.loggedDays, 1, reason: 'bitiş anı hariç');
    });
  });

  group('W-2 tamamlanmamış hafta', () {
    test('çarşamba öğlen → 3 günlük veri, bitmedi', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: DateTime(2026, 9, 16, 12),
      ));
      expect(r.period.isComplete, isFalse);
      expect(r.period.daysElapsed, 3);
    });

    test('bitmiş hafta → 7 gün', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: DateTime(2026, 9, 22, 9),
      ));
      expect(r.period.isComplete, isTrue);
      expect(r.period.daysElapsed, 7);
    });
  });

  // ───────────────────────── W-3 / W-4: beslenme ─────────────────────────

  group('W-3 / W-4 beslenme (Samet kuralı)', () {
    test('3 gün kayıt → ortalama 3 güne bölünür, 7\'ye DEĞİL', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        kcalGoal: 3000,
        proteinGoal: 150,
        foodLogs: [
          ogun(pzt, kcal: 1000, protein: 50),
          ogun(pzt.add(const Duration(hours: 5)), kcal: 1000, protein: 50),
          ogun(pzt.add(const Duration(days: 2)), kcal: 3000, protein: 150),
          ogun(pzt.add(const Duration(days: 4)), kcal: 2500, protein: 100),
        ],
      ));
      expect(r.nutrition.loggedDays, 3);
      // (2000 + 3000 + 2500) / 3 = 2500 — 7'ye bölünseydi 1071.
      expect(r.nutrition.avgKcal, 2500);
      expect(r.nutrition.avgProtein, 117); // (100 + 150 + 100) / 3
    });

    test('kayıtsız hafta → ortalama YOK, sıfır da değil', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        kcalGoal: 3000,
      ));
      expect(r.nutrition.loggedDays, 0);
      expect(r.nutrition.avgKcal, isNull,
          reason: 'kayıt yoksa "0 kalori yedin" denmez');
      expect(r.nutrition.avgProtein, isNull);
    });
  });

  // ───────────────────────── W-5 / W-6: kilo ─────────────────────────

  group('W-5 kilo', () {
    test('tek ölçüm → trend iddiası yok', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        goalDirection: GoalDirection.lose,
        goalDirectionSince: DateTime(2026, 8, 1),
        measurements: [
          tarti(pzt.subtract(const Duration(days: 3)), 86),
          tarti(pzt.add(const Duration(days: 2)), 85),
        ],
      ));
      expect(r.weight.singleMeasurement, isTrue);
      expect(r.weight.meaning, WeightMeaning.unknown,
          reason: 'tek ölçümden yön yorumu çıkarılmaz');
    });

    test('iki haftanın ortalaması → fark ve hedefe göre anlam', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        goalDirection: GoalDirection.lose,
        goalDirectionSince: DateTime(2026, 8, 1),
        measurements: [
          tarti(pzt.subtract(const Duration(days: 5)), 86),
          tarti(pzt.subtract(const Duration(days: 2)), 86),
          tarti(pzt.add(const Duration(days: 1)), 85.2),
          tarti(pzt.add(const Duration(days: 5)), 84.8),
        ],
      ));
      expect(r.weight.count, 2);
      expect(r.weight.delta, closeTo(-1.0, 0.001));
      expect(r.weight.meaning, WeightMeaning.onTrack);
    });

    test('aynı değişim "al" hedefinde tersine sayılır', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        goalDirection: GoalDirection.gain,
        goalDirectionSince: DateTime(2026, 8, 1),
        measurements: [
          tarti(pzt.subtract(const Duration(days: 5)), 86),
          tarti(pzt.subtract(const Duration(days: 2)), 86),
          tarti(pzt.add(const Duration(days: 1)), 85.2),
          tarti(pzt.add(const Duration(days: 5)), 84.8),
        ],
      ));
      expect(r.weight.meaning, WeightMeaning.against);
    });
  });

  group('W-6 hedef yönü geçmişe uygulanmaz', () {
    final olcumler = [
      tarti(pzt.subtract(const Duration(days: 5)), 86),
      tarti(pzt.subtract(const Duration(days: 2)), 86),
      tarti(pzt.add(const Duration(days: 1)), 85),
      tarti(pzt.add(const Duration(days: 5)), 85),
    ];

    test('yön bu haftadan SONRA seçildiyse bu hafta "bilinmiyor"', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: DateTime(2026, 9, 25),
        goalDirection: GoalDirection.gain,
        goalDirectionSince: DateTime(2026, 9, 23), // haftadan sonra
        measurements: olcumler,
      ));
      expect(r.weight.meaning, WeightMeaning.unknown,
          reason: 'sonradan seçilen hedef eski haftayı yargılayamaz');
    });

    test('yön hafta İÇİNDE seçildiyse bu hafta yorumlanır', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        goalDirection: GoalDirection.gain,
        goalDirectionSince: pzt.add(const Duration(days: 3)),
        measurements: olcumler,
      ));
      expect(r.weight.meaning, WeightMeaning.against);
    });

    test('yön seçilmemişse "bilinmiyor"', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        measurements: olcumler,
      ));
      expect(r.weight.meaning, WeightMeaning.unknown);
    });
  });

  // ───────────────────────── W-7: odak kural sırası ─────────────────────────

  group('W-7 odak cümlesi — kural sırası', () {
    test('1) plan tamamlanmadı (hafta bittiyse)', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        scheduledWeekdays: {1, 3, 5, 6},
        sessions: [seans(pzt), seans(pzt.add(const Duration(days: 2)))],
        foodLogs: [for (var d = 0; d < 7; d++) ogun(pzt.add(Duration(days: d)))],
      ));
      expect(r.focus.kind, FocusKind.completePlan);
      expect(r.focus.done, 2);
      expect(r.focus.planned, 4);
    });

    test('1) hafta bitmediyse plan için "kaçırdın" denmez', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: DateTime(2026, 9, 16, 12),
        scheduledWeekdays: {1, 3, 5, 6},
        sessions: [seans(pzt)],
        foodLogs: [for (var d = 0; d < 3; d++) ogun(pzt.add(Duration(days: d)))],
      ));
      expect(r.focus.kind, isNot(FocusKind.completePlan));
    });

    test('2) 3 haftadır aynı kilo ve aralık üstü → kiloyu artır', () {
      final pts = [
        for (var w = 0; w < 3; w++)
          nokta(7, 'Bench Press',
              pzt.subtract(Duration(days: 7 * w)).add(const Duration(days: 1)),
              80, 12),
      ];
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        targetRepsMaxByExercise: {7: 12},
        progressPoints: pts,
        foodLogs: [for (var d = 0; d < 7; d++) ogun(pzt.add(Duration(days: d)))],
      ));
      expect(r.focus.kind, FocusKind.increaseWeight);
      expect(r.focus.exerciseName, 'Bench Press');
    });

    test('2) kilo artmışsa takılı sayılmaz', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        targetRepsMaxByExercise: {7: 12},
        progressPoints: [
          nokta(7, 'Bench', pzt.subtract(const Duration(days: 13)), 80, 12),
          nokta(7, 'Bench', pzt.subtract(const Duration(days: 6)), 80, 12),
          nokta(7, 'Bench', pzt.add(const Duration(days: 1)), 82.5, 12),
        ],
        foodLogs: [for (var d = 0; d < 7; d++) ogun(pzt.add(Duration(days: d)))],
      ));
      expect(r.focus.kind, isNot(FocusKind.increaseWeight));
    });

    test('3) beslenme kaydı az → kayıt alışkanlığı', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        foodLogs: [ogun(pzt), ogun(pzt.add(const Duration(days: 1)))],
      ));
      expect(r.focus.kind, FocusKind.loggingHabit);
      expect(r.focus.done, 2);
    });

    test('3) pazartesi 1 günlük kayıtla "alışkanlık" denmez', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pzt.add(const Duration(hours: 20)),
        foodLogs: [ogun(pzt)],
      ));
      expect(r.focus.kind, FocusKind.keepRhythm);
    });

    test('4) kilo 2 haftadır hedefin tersine → kaloriyi gözden geçir', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        goalDirection: GoalDirection.lose,
        goalDirectionSince: DateTime(2026, 8, 1),
        measurements: [
          tarti(pzt.subtract(const Duration(days: 12)), 84),
          tarti(pzt.subtract(const Duration(days: 5)), 85),
          tarti(pzt.add(const Duration(days: 2)), 86),
        ],
        foodLogs: [for (var d = 0; d < 7; d++) ogun(pzt.add(Duration(days: d)))],
      ));
      expect(r.focus.kind, FocusKind.reviewCalories);
    });

    test('4) yön yeni seçildiyse 2 haftalık trend yargılanmaz', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        goalDirection: GoalDirection.lose,
        goalDirectionSince: pzt.add(const Duration(days: 1)),
        measurements: [
          tarti(pzt.subtract(const Duration(days: 12)), 84),
          tarti(pzt.subtract(const Duration(days: 5)), 85),
          tarti(pzt.add(const Duration(days: 2)), 86),
        ],
        foodLogs: [for (var d = 0; d < 7; d++) ogun(pzt.add(Duration(days: d)))],
      ));
      expect(r.focus.kind, FocusKind.keepRhythm);
    });

    test('5) hiçbiri → aynı ritmi sürdür', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        foodLogs: [for (var d = 0; d < 7; d++) ogun(pzt.add(Duration(days: d)))],
      ));
      expect(r.focus.kind, FocusKind.keepRhythm);
    });

    test('sıra: plan eksik VE kayıt az → plan kazanır (ilk kural)', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        scheduledWeekdays: {1, 3},
        sessions: [seans(pzt)],
        foodLogs: [ogun(pzt)],
      ));
      expect(r.focus.kind, FocusKind.completePlan);
    });
  });

  // ───────────────────────── W-8: hareket ilerlemesi ─────────────────────────

  group('W-8 hareket ilerlemesi', () {
    test('her hareket ayrı; toplanmaz, en fazla 3, en çok ilerleyen önde', () {
      final once = pzt.subtract(const Duration(days: 4));
      final bu = pzt.add(const Duration(days: 2));
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        progressPoints: [
          nokta(1, 'Bench', once, 80, 8),
          nokta(1, 'Bench', bu, 85, 8),
          nokta(2, 'Squat', once, 100, 5),
          nokta(2, 'Squat', bu, 110, 5),
          nokta(3, 'Curl', once, 12, 10),
          nokta(3, 'Curl', bu, 12, 11),
          nokta(4, 'Row', once, 60, 10),
          nokta(4, 'Row', bu, 62.5, 10),
          nokta(5, 'Press', once, 50, 8),
          nokta(5, 'Press', bu, 45, 8), // gerileme — listelenmez
        ],
      ));
      expect(r.progress.length, 3, reason: 'en fazla 3 hareket');
      expect(r.progress.first.name, 'Squat');
      expect(r.progress.map((p) => p.name), isNot(contains('Press')));
      expect(r.progress.map((p) => p.name).toSet().length, 3,
          reason: 'her satır tek hareket');
    });

    test('önceki kaydı olmayan hareket listelenmez', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        progressPoints: [nokta(1, 'Bench', pzt.add(const Duration(days: 1)), 80, 8)],
      ));
      expect(r.progress, isEmpty);
    });

    test('karşılaştırma EN SON kayda göre, eski rekora göre değil', () {
      final r = buildWeeklyReview(WeeklyReviewInput(
        weekStart: hafta,
        now: pazarAksami,
        progressPoints: [
          nokta(1, 'Bench', pzt.subtract(const Duration(days: 20)), 100, 8),
          nokta(1, 'Bench', pzt.subtract(const Duration(days: 3)), 80, 8),
          nokta(1, 'Bench', pzt.add(const Duration(days: 1)), 85, 8),
        ],
      ));
      expect(r.progress.single.deltaE1rm, greaterThan(0),
          reason: 'son kayıt 80 → bu hafta 85 = ilerleme');
    });
  });

  // ───────────────────────── W-9: ana sayfayla aynı sayı ─────────────────

  test('W-9 seans / hacim / kalori ana sayfayla AYNI hesap', () {
    final s1 = seans(pzt, dk: 60);
    final s2 = seans(pzt.add(const Duration(days: 2)), dk: 45);
    final sets = {
      s1.id: [set(s1.id, kg: 100, reps: 10), set(s1.id, kg: 60, reps: 12)],
      s2.id: [set(s2.id, kg: 80, reps: 8, complete: false)],
    };
    final r = buildWeeklyReview(WeeklyReviewInput(
      weekStart: hafta,
      now: pazarAksami,
      sessions: [s1, s2],
      setsBySession: sets,
      bodyWeightKg: 85,
    ));
    final ana = aggregateWorkouts(
        sessions: [s1, s2], setsBySession: sets, bodyWeightKg: 85);
    expect(r.workout.sessions, ana.sessions);
    expect(r.workout.volumeKg, ana.volumeKg);
    expect(r.workout.kcalBurned, ana.kcalBurned);
    expect(r.workout.completedSets, 2, reason: 'tamamlanmamış set sayılmaz');
    expect(r.workout.totalMinutes, 105);
  });

  test('kas grubu: yalnız tamamlanmış, ısınma dışı setler sayılır', () {
    final s = seans(pzt);
    const kas = Exercise(
      id: 1,
      name: 'Bench',
      category: 'compound',
      muscleGroups: '["chest","triceps"]',
      isPosture: false,
      isArm: false,
      measurementType: 'weight_reps',
      isCustom: false,
      isArchived: false,
    );
    final r = buildWeeklyReview(WeeklyReviewInput(
      weekStart: hafta,
      now: pazarAksami,
      sessions: [s],
      exercises: {1: kas},
      setsBySession: {
        s.id: [
          set(s.id),
          set(s.id),
          set(s.id, warmup: true),
          set(s.id, complete: false),
        ],
      },
    ));
    expect(r.muscleSets, {'chest': 2},
        reason: 'birincil kas yoksa listenin ilki');
  });
}
