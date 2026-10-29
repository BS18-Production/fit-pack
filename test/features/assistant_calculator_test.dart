import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/assistant/assistant_calculator.dart';
import 'package:fit_pack/features/assistant/assistant_contract.dart';
import 'package:fit_pack/features/insights/insight_rules.dart';
import 'package:fit_pack/features/insights/insight_queries.dart';
import 'package:fit_pack/features/insights/insight_window.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/design_fixture.dart';
import '../helpers/test_database.dart';

void main() {
  test(
    'bilinmeyen hedefte asistan varsayılan3 veya tarihsel seri söylemez',
    () {
      final result = calculateAssistant(
        const AssistantSelection(
          query: AssistantQuery.streak,
          period: InsightPeriod.allTime,
        ),
        AssistantData(
          now: DateTime(2026, 10, 28),
          weeklyGoal: 3,
          weeklyTargetKnown: false,
          weeklyGoalForPeriod: (_) => null,
        ),
      );
      expect(result.status, AssistantDataStatus.noPlan);
      expect(result.metrics, isEmpty);
    },
  );

  test('kısmi hedef döneminde asistan tam hafta başarı sayacı göstermez', () {
    final result = calculateAssistant(
      const AssistantSelection(
        query: AssistantQuery.streak,
        period: InsightPeriod.allTime,
      ),
      AssistantData(
        now: DateTime(2026, 10, 28),
        weeklyGoal: 2,
        weeklyTargetKnown: true,
        weeklyGoalForPeriod: (_) => null,
      ),
    );
    expect(result.status, AssistantDataStatus.insufficientData);
    expect(result.metrics, isEmpty);
  });

  test('tarihsel hedefler bilinmiyorsa asistan eski seriyi başarı saymaz', () {
    final week = DateTime(2026, 10, 26);
    final data = AssistantData(
      now: DateTime(2026, 10, 28),
      weeklyGoal: 3,
      weeklyGoalForPeriod: (start) => start == week ? 3 : null,
    );
    final result = calculateAssistant(
      const AssistantSelection(
        query: AssistantQuery.streak,
        period: InsightPeriod.allTime,
      ),
      data.at(DateTime(2026, 10, 28, 18)),
    );
    expect(
      result.metrics.any((m) => m.key == AssistantMetricKey.weeks),
      isFalse,
    );
    expect(result.metrics.single.value, 3);
  });

  final now = DateTime(2026, 10, 11, 19);
  test(
    'beslenme ortalaması yalnız tamamlanan günler; boş gün sıfır, açık gün hariç',
    () {
      final logs = [
        for (final (id, day, kcal, protein) in [
          (1, 5, 2000.0, 160.0),
          (2, 6, 3000.0, 250.0),
        ])
          FoodLog(
            id: id,
            date: DateTime(2026, 10, day),
            mealType: 'dinner',
            foodId: 1,
            grams: 100,
            computedKcal: kcal,
            computedProtein: protein,
            computedCarb: 0,
            computedFat: 0,
          ),
      ];
      final data = AssistantData(
        now: now,
        logs: logs,
        completedDays: {DateTime(2026, 10, 5), DateTime(2026, 10, 7)},
      );
      final result = calculateAssistant(
        const AssistantSelection(
          query: AssistantQuery.nutritionSummary,
          period: InsightPeriod.thisWeek,
        ),
        data,
      );
      num? metric(AssistantMetricKey key) =>
          result.metrics.firstWhere((m) => m.key == key).value;
      expect(metric(AssistantMetricKey.avgKcal), 1000);
      expect(metric(AssistantMetricKey.avgProtein), 80);
      expect(metric(AssistantMetricKey.completedDays), 2);
      expect(metric(AssistantMetricKey.excludedDays), 1);
      final logged = nutritionStats(
        window: windowFor(InsightPeriod.thisWeek, now),
        logs: logs,
        proteinGoal: 150,
        kcalGoal: 2000,
      );
      expect(
        interpretNutrition(
          logged,
        ).any((c) => c.key == CommentKey.proteinGoalDays),
        false,
      );
    },
  );
  test(
    'tüm hazır sorgular gerçek DAO girdileriyle çalışır; desteklenmeyen dönem reddi',
    () async {
      final db = newTestDatabase();
      addTearDown(db.close);
      await seedDesignFixture(db);
      final sessions = await db.workoutDao.getAllSessions();
      final data = AssistantData(
        now: DateTime.now(),
        sessions: sessions,
        sets: await db.workoutDao.getSetsForSessions(
          sessions.map((s) => s.id).toList(),
        ),
        exercises: {
          for (final e in await db.workoutDao.getAllExercises()) e.id: e,
        },
        points: await db.workoutDao.getWeightedSetPointsInRange(
          DateTime(1970),
          DateTime(2100),
          onlyComplete: true,
        ),
        logs: await db.nutritionDao.getLogsInRange(
          DateTime(1970),
          DateTime(2100),
        ),
        measurements: await db.bodyDao.getAllMeasurements(),
        profile: await db.userProfileDao.getProfile(),
      );
      for (final q in AssistantQuery.values.where(
        (q) => q != AssistantQuery.outOfScope,
      )) {
        final result = calculateAssistant(
          AssistantSelection(
            query: q,
            period: q.periods.first,
            exerciseId: data.exercises.keys.first,
          ),
          data,
        );
        expect(result.selection.query, q);
        expect(result.records, greaterThanOrEqualTo(0));
        final plain = calculateAssistant(
          AssistantSelection(
            query: q,
            period: q.periods.first,
            exerciseId: data.exercises.keys.first,
            interpretation: false,
          ),
          data,
        );
        expect(plain.comments, isEmpty);
        expect(plain.details.every((d) => d.comments.isEmpty), true);
      }
      expect(
        () => calculateAssistant(
          const AssistantSelection(
            query: AssistantQuery.weightTrend,
            period: InsightPeriod.allTime,
          ),
          data,
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'kilo yorumu haftalık pencereyi kendiliğinden uzatmaz; boş veri ayrı durum',
    () {
      final data = AssistantData(
        now: now,
        measurements: [
          for (final day in [1, 5, 10])
            BodyMeasurement(
              id: day,
              date: DateTime(2026, 10, day),
              weightKg: 80 - day / 10,
            ),
        ],
      );
      final result = calculateAssistant(
        const AssistantSelection(
          query: AssistantQuery.weightTrend,
          period: InsightPeriod.thisWeek,
        ),
        data,
      );
      expect(result.records, 2);
      expect(result.status, AssistantDataStatus.insufficientData);
      expect(result.comments.single.key, CommentKey.weightNotEnoughData);
      final empty = calculateAssistant(
        const AssistantSelection(
          query: AssistantQuery.workoutSummary,
          period: InsightPeriod.thisWeek,
        ),
        AssistantData(now: now),
      );
      expect(empty.status, AssistantDataStatus.noData);
    },
  );
}
