import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/workout_dao.dart';
import 'package:fit_pack/features/insights/insight_queries.dart';
import 'package:fit_pack/features/insights/insight_rules.dart';
import 'package:fit_pack/features/insights/insight_window.dart';
import 'package:fit_pack/features/insights/weekly_review.dart'
    show GoalDirection;
import 'package:flutter_test/flutter_test.dart';

/// "Verime sor" yorum kuralları (docs/36 §2). Motor cümle üretmez; testler
/// anahtar, parametre, not ve kaynağı kilitler.
void main() {
  var seq = 0;

  // ───────────────────────────── muscle_balance ─────────────────────────────

  group('muscle_balance — ~10 set/hafta düzeyine göre konum', () {
    InsightComment kas(int sets, {bool complete = true}) => interpretMuscleSets(
      muscle: 'chest',
      sets: sets,
      weekComplete: complete,
      daysElapsed: 3,
    );

    test('9 altında, 10 ve 20 düzeyde, 21 ötesi', () {
      expect(kas(9).key, CommentKey.muscleBelowTen);
      expect(kas(10).key, CommentKey.muscleAtTen);
      expect(kas(20).key, CommentKey.muscleAtTen);
      expect(kas(21).key, CommentKey.muscleBeyondTwenty);
    });

    test('kaynak Schoenfeld; set sayım farkı ve genel kılavuz notu', () {
      final c = kas(12);
      expect(c.sources, [EvidenceSource.schoenfeld2017]);
      expect(c.notes, contains(CommentNote.completedSetsCounted));
      expect(c.notes, contains(CommentNote.generalGuideline));
      expect(c.notes, isNot(contains(CommentNote.soFar)));
    });

    test('devam eden hafta "şu ana kadar"', () {
      final c = kas(4, complete: false);
      expect(c.notes.first, CommentNote.soFar);
      expect(c.params['daysElapsed'], 3);
    });
  });

  // ───────────────────────────── weight_trend ─────────────────────────────

  group('weight_trend', () {
    final now = DateTime(2026, 10, 11, 20);
    final w30 = windowFor(InsightPeriod.last30Days, now);
    final since = DateTime(2026, 8, 1);

    BodyMeasurement tarti(DateTime d, double kg) =>
        BodyMeasurement(id: ++seq, date: d, weightKg: kg);

    /// 28 gün boyunca haftada [weekly] kg değişen, 5 ölçüm.
    List<BodyMeasurement> seri(double start, double weekly) => [
      for (var w = 0; w <= 4; w++)
        tarti(DateTime(2026, 9, 13 + 7 * w, 8), start + weekly * w),
    ];

    InsightComment yorum(
      List<BodyMeasurement> ms,
      GoalDirection? dir, {
      DateTime? dirSince,
    }) => interpretWeightTrend(
      window: w30,
      measurements: ms,
      direction: dir,
      directionSince: dirSince ?? since,
    );

    test('≥14 gün yoksa yorum yok; pencere ve ölçüm sayısı parametrede', () {
      final c = yorum([
        tarti(DateTime(2026, 10, 1), 80),
        tarti(DateTime(2026, 10, 10), 79),
      ], GoalDirection.lose);
      expect(c.key, CommentKey.weightNotEnoughData);
      expect(c.params['count'], 2);
      expect(c.params['spanDays'], 9);
      expect(c.params['windowDays'], 30);
    });

    test('bu haftanın verisiyle kilo yorumu yapılmaz', () {
      final c = interpretWeightTrend(
        window: windowFor(InsightPeriod.thisWeek, now),
        measurements: seri(80, -0.5),
        direction: GoalDirection.lose,
        directionSince: since,
      );
      expect(c.key, CommentKey.weightNotEnoughData);
    });

    test('ver: CDC kg aralığı (0,45–0,9) içinde / yavaş / hızlı', () {
      expect(
        yorum(seri(80, -0.6), GoalDirection.lose).key,
        CommentKey.weightLossInRange,
      );
      expect(
        yorum(seri(80, -0.3), GoalDirection.lose).key,
        CommentKey.weightLossSlower,
      );
      expect(
        yorum(seri(80, -1.0), GoalDirection.lose).key,
        CommentKey.weightLossFaster,
      );
    });

    test(
      'ver: kaynaklar CDC + Garthe; yağsız kütle ek bilgisi, uzman notu',
      () {
        final c = yorum(seri(80, -0.6), GoalDirection.lose);
        expect(c.sources, [
          EvidenceSource.cdcWeightLoss,
          EvidenceSource.garthe2011,
        ]);
        expect(c.notes, contains(CommentNote.leanMassInfo));
        expect(c.notes, contains(CommentNote.consultProfessional));
        expect(c.notes, isNot(contains(CommentNote.fastLossCaution)));
        expect(c.params['weeklyChangeKg'] as double, closeTo(-0.6, 1e-9));
        expect(c.params['rangeMinKg'], 0.45);
      },
    );

    test('ver: haftalık %1,5 üstü kayıpta dikkat notu öne çıkar', () {
      // 70 kg'da haftada 1,2 kg ≈ %1,8
      final c = yorum(seri(70, -1.2), GoalDirection.lose);
      expect(c.key, CommentKey.weightLossFaster);
      expect(c.notes.first, CommentNote.fastLossCaution);
    });

    test('ver + kilo artışı: "hedefinin tersi", "yavaş kayıp" değil', () {
      final c = yorum(seri(80, 0.4), GoalDirection.lose);
      expect(c.key, CommentKey.weightAgainstGoal);
      expect(c.sources, isEmpty);
    });

    test('tartı gürültüsü içinde: belirgin değişim yok', () {
      expect(
        yorum(seri(80, -0.05), GoalDirection.lose).key,
        CommentKey.weightNoClearChange,
      );
    });

    test('al: %0,25–0,5/hafta aralığı (Iraki), seviye notu', () {
      // 80 kg: 0,3 kg ≈ %0,37; 0,6 kg ≈ %0,74; 0,15 kg ≈ %0,19
      final c = yorum(seri(80, 0.3), GoalDirection.gain);
      expect(c.key, CommentKey.weightGainInRange);
      expect(c.sources, [EvidenceSource.iraki2019]);
      expect(c.notes, contains(CommentNote.beginnerIntermediateRange));
      expect(
        yorum(seri(80, 0.6), GoalDirection.gain).key,
        CommentKey.weightGainFaster,
      );
      expect(
        yorum(seri(80, 0.15), GoalDirection.gain).key,
        CommentKey.weightGainSlower,
      );
      expect(
        yorum(seri(80, -0.4), GoalDirection.gain).key,
        CommentKey.weightAgainstGoal,
      );
    });

    test('koru: ortalamanın ±%1 içinde sabit, dışında kayma', () {
      final sabit = yorum(seri(80, 0.15), GoalDirection.maintain); // 0,6 kg
      expect(sabit.key, CommentKey.weightStable);
      expect(sabit.basis, CommentBasis.ownHistory);
      expect(sabit.notes, isEmpty);
      expect(
        yorum(seri(80, 0.4), GoalDirection.maintain).key,
        CommentKey.weightDriftUp,
      );
      expect(
        yorum(seri(80, -0.4), GoalDirection.maintain).key,
        CommentKey.weightDriftDown,
      );
    });

    test('yön yok: kendi geçmişi + "yön seçersen yorumlarım"', () {
      final c = yorum(seri(80, -0.6), null);
      expect(c.key, CommentKey.weightDriftDown);
      expect(c.notes, [CommentNote.chooseGoalDirection]);
    });

    test(
      'geçmişe uygulama yasağı: pencereden sonra seçilen yön kullanılmaz',
      () {
        final uzun = DateWindow(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 10, 5),
          isComplete: true,
        );
        final c = interpretWeightTrend(
          window: uzun,
          measurements: seri(80, -0.6),
          direction: GoalDirection.lose,
          directionSince: DateTime(2026, 10, 6),
        );
        expect(c.key, CommentKey.weightDriftDown, reason: 'yön yokmuş gibi');
        expect(c.notes, contains(CommentNote.chooseGoalDirection));
      },
    );
  });

  // ─────────────────────────── workout_summary ───────────────────────────

  group('workout_summary — önceki 8 haftanın medyanı', () {
    final weekStart = DateTime(2026, 10, 5);
    final bitti = DateTime(2026, 10, 12, 9);

    WorkoutSession seans(DateTime d) => WorkoutSession(
      id: ++seq,
      date: d,
      phase: 1,
      workoutType: 'push',
      kneeStatus: 'normal',
      isDeload: false,
    );
    WorkoutSet set(int sid, {double kg = 100}) => WorkoutSet(
      id: ++seq,
      sessionId: sid,
      exerciseId: 1,
      setNumber: 1,
      weightKg: kg,
      reps: 10,
      isWarmup: false,
      setType: 'normal',
      isComplete: true,
    );

    /// Her hafta için set sayısı listesi (index 0 = bu hafta, 1 = geçen ...).
    ({List<WorkoutSession> s, Map<int, List<WorkoutSet>> m}) haftalar(
      List<int> setsPerWeek,
    ) {
      final s = <WorkoutSession>[];
      final m = <int, List<WorkoutSet>>{};
      for (var w = 0; w < setsPerWeek.length; w++) {
        if (setsPerWeek[w] == 0) continue;
        final ss = seans(DateTime(2026, 10, 6 - 7 * w, 18));
        s.add(ss);
        m[ss.id] = [for (var i = 0; i < setsPerWeek[w]; i++) set(ss.id)];
      }
      return (s: s, m: m);
    }

    test('medyan (ortalama değil): uç hafta tabanı bozmaz', () {
      // geçmiş: 10,10,10,10,10,10,10,90 → medyan 10, ortalama 20
      final h = haftalar([15, 10, 10, 10, 10, 10, 10, 10, 90]);
      final r = interpretWorkoutWeek(
        weekStart: weekStart,
        now: bitti,
        sessions: h.s,
        setsBySession: h.m,
      );
      final sets = r[WorkoutMetric.sets]!;
      expect(sets.params['median'], 10);
      expect(sets.params['pct'], 50);
      expect(sets.key, CommentKey.workoutAboveMedian);
      expect(r[WorkoutMetric.volume]!.params['median'], 10000);
      expect(r[WorkoutMetric.sessions]!.key, CommentKey.workoutAtMedian);
    });

    test('devam eden hafta: yüzde yok, "şu ana kadar"', () {
      final h = haftalar([3, 10, 10, 10, 10]);
      final r = interpretWorkoutWeek(
        weekStart: weekStart,
        now: DateTime(2026, 10, 7, 12),
        sessions: h.s,
        setsBySession: h.m,
      );
      final c = r[WorkoutMetric.sets]!;
      expect(c.key, CommentKey.workoutSoFar);
      expect(c.params.containsKey('pct'), isFalse);
      expect(c.params['daysElapsed'], 3);
      expect(c.notes, [CommentNote.soFar]);
    });

    test(
      'ilk seanstan önceki haftalar tabana girmez; boş haftalar 0 sayılır',
      () {
        // 3 hafta geçmiş → en az 4 gerekir
        final az = haftalar([10, 10, 10, 10]);
        expect(
          interpretWorkoutWeek(
            weekStart: weekStart,
            now: bitti,
            sessions: az.s,
            setsBySession: az.m,
          )[WorkoutMetric.sets]!.key,
          CommentKey.workoutNotEnoughHistory,
        );

        // ilk seans 6 hafta önce; arada 2 boş hafta → 0 olarak sayılır
        final bosluklu = haftalar([10, 10, 0, 0, 10, 10, 10]);
        final r = interpretWorkoutWeek(
          weekStart: weekStart,
          now: bitti,
          sessions: bosluklu.s,
          setsBySession: bosluklu.m,
        )[WorkoutMetric.sets]!;
        expect(r.params['baselineWeeks'], 6);
        expect(r.params['median'], 10); // 10,0,0,10,10,10 → 10
      },
    );

    test('medyan 0 ise yüzde yok', () {
      final h = haftalar([5]);
      final r = interpretWorkoutWeek(
        weekStart: weekStart,
        now: bitti,
        sessions: h.s,
        setsBySession: h.m,
        firstSessionDate: DateTime(2026, 6, 1),
      )[WorkoutMetric.sets]!;
      expect(r.key, CommentKey.workoutNoBaseline);
    });
  });

  // ───────────────────── strength_progress / exercise_history ─────────────────────

  group('e1RM eğilimi', () {
    ExerciseProgressPoint p(DateTime d, double kg, int reps) =>
        ExerciseProgressPoint(
          exerciseId: 1,
          name: 'Bench',
          date: d,
          weightKg: kg,
          reps: reps,
        );

    test('artıyor / düşüyor / ±%1 içinde sabit', () {
      expect(
        interpretStrengthTrend([
          p(DateTime(2026, 9, 14), 80, 8),
          p(DateTime(2026, 10, 9), 90, 8),
        ]).key,
        CommentKey.strengthUp,
      );
      expect(
        interpretStrengthTrend([
          p(DateTime(2026, 9, 14), 90, 8),
          p(DateTime(2026, 10, 9), 80, 8),
        ]).key,
        CommentKey.strengthDown,
      );
      // 100×10 ≈ 133,3; 102,5×9 ≈ 133,25 → sabit (gürültü)
      expect(
        interpretStrengthTrend([
          p(DateTime(2026, 9, 14), 100, 10),
          p(DateTime(2026, 9, 21), 102.5, 9),
        ]).key,
        CommentKey.strengthStable,
      );
    });

    test('plato: art arda 3 haftada en ağır set aynı kiloda', () {
      final c = interpretStrengthTrend([
        p(DateTime(2026, 9, 1), 70, 8),
        p(DateTime(2026, 9, 22), 80, 6),
        p(DateTime(2026, 9, 29), 80, 7),
        p(DateTime(2026, 10, 6), 80, 8),
      ]);
      expect(c.key, CommentKey.strengthPlateau);
      expect(c.params['topKg'], 80);
    });

    test('haftalar ardışık değilse plato değil', () {
      final c = interpretStrengthTrend([
        p(DateTime(2026, 9, 1), 80, 6),
        p(DateTime(2026, 9, 22), 80, 7),
        p(DateTime(2026, 10, 6), 80, 8),
      ]);
      expect(c.key, isNot(CommentKey.strengthPlateau));
    });

    test('tek gün → veri yetersiz; e1RM yok → uygulanamaz', () {
      expect(
        interpretStrengthTrend([p(DateTime(2026, 10, 1), 80, 5)]).key,
        CommentKey.strengthNotEnoughData,
      );
      expect(
        interpretStrengthTrend([p(DateTime(2026, 10, 1), 0, 0)]).key,
        CommentKey.strengthNotApplicable,
      );
    });
  });

  // ─────────────────────── protein_goal / nutrition_summary ───────────────────────

  group('beslenme yorumu', () {
    NutritionStats st({double avgP = 120, int goal = 150}) => NutritionStats(
      loggedDays: 20,
      avgKcal: 2100,
      avgProtein: avgP,
      proteinGoalDays: 8,
      kcalGoal: 2000,
      proteinGoal: goal,
    );

    test('kayıt yoksa yalnız "kayıt yok"', () {
      final r = interpretNutrition(
        const NutritionStats(
          loggedDays: 0,
          avgKcal: null,
          avgProtein: null,
          proteinGoalDays: 0,
          kcalGoal: 2000,
          proteinGoal: 150,
        ),
      );
      expect(r.single.key, CommentKey.nutritionNoLogs);
    });

    test('hedef günleri + kalori/hedef: "kaydedilen" notu', () {
      final r = interpretNutrition(st());
      expect(r.map((c) => c.key), [
        CommentKey.proteinGoalDays,
        CommentKey.kcalVsGoal,
      ]);
      expect(r.first.params['hitDays'], 8);
      expect(r.first.params['pctOfGoal'], 80);
      expect(r.first.notes, contains(CommentNote.loggedOnly));
      expect(r[1].params['pctOfGoal'], 105);
    });

    test('g/kg: 1,6 altı / 1,6–2,2 / üstü; kilo ve tarihi görünür', () {
      final tarih = DateTime(2026, 10, 9);
      InsightComment gkg(double p) => interpretNutrition(
        st(avgP: p),
        bodyWeightKg: 80,
        bodyWeightDate: tarih,
      ).last;
      expect(gkg(120).key, CommentKey.proteinPerKgBelow); // 1,5
      expect(gkg(128).key, CommentKey.proteinPerKgInRange); // 1,6
      expect(gkg(176).key, CommentKey.proteinPerKgInRange); // 2,2
      expect(gkg(180).key, CommentKey.proteinPerKgAbove); // 2,25
      final c = gkg(140);
      expect(c.params['bodyWeightKg'], 80);
      expect(c.params['bodyWeightDate'], tarih);
      expect(c.sources, [EvidenceSource.morton2018, EvidenceSource.iraki2019]);
      expect(c.notes, contains(CommentNote.consultProfessional));
    });

    test('devam eden pencerede "şu ana kadar"', () {
      final r = interpretNutrition(st(), windowComplete: false);
      expect(r.every((c) => c.notes.first == CommentNote.soFar), isTrue);
    });
  });

  // ─────────────────────────── today_remaining ───────────────────────────

  group('today_remaining yorumu', () {
    TodayRemaining t({double? rem}) => TodayRemaining(
      kcalGoal: rem == null ? 0 : 2000,
      proteinGoal: 150,
      loggedKcal: 1500,
      loggedProtein: 90,
      remainingKcal: rem,
      remainingProtein: 60,
      suggestions: const [],
    );

    test('hedef yok / kalan var / hedefe ulaşıldı', () {
      expect(interpretTodayRemaining(t()).key, CommentKey.todayNoGoal);
      expect(
        interpretTodayRemaining(t(rem: 500)).key,
        CommentKey.todayRemaining,
      );
      expect(
        interpretTodayRemaining(t(rem: -10)).key,
        CommentKey.todayGoalReached,
      );
    });
  });

  test('ARB anahtarı biçimi', () {
    expect(CommentKey.muscleBelowTen.arbKey, 'insightMuscleBelowTen');
  });
}
