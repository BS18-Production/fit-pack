import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/core/prefs/training_prefs.dart';
import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/health/step_providers.dart';
import 'package:fit_pack/features/health/step_source.dart';
import 'package:fit_pack/features/home/first_week.dart';
import 'package:fit_pack/features/home/home_screen.dart';
import 'package:fit_pack/features/home/today_lines.dart';
import 'package:fit_pack/features/home/week_ready.dart';
import 'package:fit_pack/features/insights/insight_queries.dart';
import 'package:fit_pack/features/workout/progression.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_step_source.dart';
import '../helpers/test_database.dart';

/// Ana Sayfa "Bugün" satırları + "Haftan hazır" kartı (docs/50 Faz 1–2).
void main() {
  TodayRemaining kalan({double? kcal, double? protein}) => TodayRemaining(
        kcalGoal: 2200,
        proteinGoal: 180,
        loggedKcal: 0,
        loggedProtein: 0,
        remainingKcal: kcal,
        remainingProtein: protein,
        suggestions: const [],
      );

  group('beslenme satırı', () {
    test('kayıt yoksa ilk öğün', () {
      expect(buildNutritionLine(hasLogsToday: false, remaining: kalan()),
          isA<NutritionLineFirstMeal>());
    });
    test('kalan protein ve kalori yuvarlanır', () {
      final l = buildNutritionLine(
          hasLogsToday: true, remaining: kalan(kcal: 640.4, protein: 84.6));
      expect(l, isA<NutritionLineRemaining>());
      l as NutritionLineRemaining;
      expect(l.proteinG, 85);
      expect(l.kcal, 640);
    });
    test('hedef tuttuysa ya da hedef yoksa satır yok', () {
      expect(
          buildNutritionLine(
              hasLogsToday: true, remaining: kalan(kcal: -20, protein: 0)),
          isNull);
      expect(buildNutritionLine(hasLogsToday: true, remaining: kalan()),
          isNull);
    });
    test('yalnız protein kaldıysa kalori boş', () {
      final l = buildNutritionLine(
              hasLogsToday: true, remaining: kalan(kcal: -5, protein: 30))
          as NutritionLineRemaining;
      expect(l.proteinG, 30);
      expect(l.kcal, isNull);
    });
  });

  group('"Haftan hazır" aralığı (hafta Pazartesi başlar)', () {
    // 2026-10-18 Pazar, 2026-10-19 Pazartesi.
    final pazar21 = DateTime(2026, 10, 18, 21);
    final pazar19 = DateTime(2026, 10, 18, 19, 59);
    final pazartesi = DateTime(2026, 10, 19, 10);
    final sali = DateTime(2026, 10, 20, 10);
    final buHafta = DateTime(2026, 10, 12);

    test('Pazar 20:00 sonrası kapanan hafta bu hafta', () {
      expect(closedWeekStart(pazar21, 1), buHafta);
      expect(weekReadyOffset(pazar21, 1), 0);
    });
    test('Pazar 20:00 öncesi görünmez', () {
      expect(closedWeekStart(pazar19, 1), isNull);
    });
    test('Pazartesi kapanan hafta geçen hafta (offset 1)', () {
      expect(closedWeekStart(pazartesi, 1), buHafta);
      expect(weekReadyOffset(pazartesi, 1), 1);
    });
    test('Salı kalkar', () {
      expect(closedWeekStart(sali, 1), isNull);
    });
    test('açıldıysa görünmez', () {
      expect(
          weekReadyVisible(now: pazartesi, weekStart: 1, openedWeek: null),
          isTrue);
      expect(
          weekReadyVisible(now: pazartesi, weekStart: 1, openedWeek: buHafta),
          isFalse);
    });
    test('hafta Pazar başlarsa Cumartesi kapanır', () {
      final cumartesi = DateTime(2026, 10, 17, 20, 30);
      expect(closedWeekStart(cumartesi, 7), DateTime(2026, 10, 11));
      expect(closedWeekStart(pazar21, 7), DateTime(2026, 10, 11));
    });
  });

  group('veritabanıyla', () {
    late AppDatabase db;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = newTestDatabase();
    });
    tearDown(() => db.close());

    /// Tek hareketli rutin; geçen seans [sets] (kg, tekrar), hedef 8–12.
    Future<void> rutin(List<(double, int)> sets) async {
      final exId = await db.workoutDao.insertCustomExercise(
        ExercisesCompanion.insert(
          name: 'Squat',
          category: 'compound',
          muscleGroups: 'legs',
        ),
      );
      final routineId = await db.workoutDao.createRoutine(
        RoutinesCompanion.insert(name: 'Bacak', createdAt: DateTime(2026, 9, 1)),
      );
      await db.workoutDao.addRoutineExercise(
        RoutineExercisesCompanion.insert(
          routineId: routineId,
          exerciseId: exId,
          targetSets: Value(sets.length),
          targetRepsMin: const Value(8),
          targetRepsMax: const Value(12),
        ),
      );
      final sessionId = await db.into(db.workoutSessions).insert(
            WorkoutSessionsCompanion(
              date: Value(DateTime.now().subtract(const Duration(days: 2))),
              phase: const Value(0),
              workoutType: const Value('Bacak'),
              routineId: Value(routineId),
            ),
          );
      for (final (i, (kg, reps)) in sets.indexed) {
        await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
              sessionId: sessionId,
              exerciseId: exId,
              setNumber: i + 1,
              weightKg: Value(kg),
              reps: Value(reps),
              isComplete: const Value(true),
            ));
      }
    }

    Future<TrainingLine?> antrenmanSatiri() async {
      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        effectiveIncrementKgProvider.overrideWithValue(2.5),
      ]);
      addTearDown(c.dispose);
      final sub = c.listen(todayTrainingLineProvider, (_, _) {});
      addTearDown(sub.close);
      // todayRoutineProvider önce yüklenir, sonra satır yeniden hesaplanır.
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return c.read(todayTrainingLineProvider).valueOrNull;
    }

    test('üst sınıra ulaşıldıysa kilo artışı (canlı seansla aynı kural)',
        () async {
      await rutin([(80, 12), (80, 12)]);
      final l = await antrenmanSatiri();
      expect(l?.kind, ProgressionKind.increaseWeight);
      expect(l?.exerciseName, 'Squat');
      expect(l?.weightKg, 82.5);
    });

    test('aralık içindeyse +1 tekrar, aynı kilo', () async {
      await rutin([(80, 10), (80, 9)]);
      final l = await antrenmanSatiri();
      expect(l?.kind, ProgressionKind.addRep);
      expect(l?.weightKg, 80);
    });

    test('aralığın altındaysa satır yok', () async {
      await rutin([(80, 6), (80, 7)]);
      expect(await antrenmanSatiri(), isNull);
    });

    test('bugün antrenman yapıldıysa satır yok', () async {
      await rutin([(80, 12), (80, 12)]);
      await db.into(db.workoutSessions).insert(WorkoutSessionsCompanion(
            date: Value(DateTime.now()),
            phase: const Value(0),
            workoutType: const Value('Bacak'),
          ));
      expect(await antrenmanSatiri(), isNull);
    });
  });

  group('Ana Sayfa', () {
    late AppDatabase db;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = newTestDatabase();
    });
    tearDown(() => db.close());

    Future<void> ac(WidgetTester tester, {required DateTime now}) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await db.userProfileDao.ensureProfile();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          stepSourceProvider.overrideWithValue(
            FakeStepSource(status: StepPlatformStatus.unavailable),
          ),
          accountCreatedProvider.overrideWithValue(null),
          weekReadyClockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: AppColors.lightScheme,
            extensions: [AppColors.lightSemantic],
          ),
          locale: const Locale('tr'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: const Scaffold(body: HomeScreen()),
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('öğün yokken "İlk öğününü ekle" satırı', (tester) async {
      await ac(tester, now: DateTime(2026, 10, 15, 10));
      await tester.scrollUntilVisible(
          find.byKey(const ValueKey('home.todayLine.food')), 150,
          scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const ValueKey('home.todayLine.food')), findsOneWidget);
      expect(find.text('İlk öğününü ekle.'), findsOneWidget);
    });

    testWidgets('Pazartesi "Haftan hazır" görünür', (tester) async {
      await ac(tester, now: DateTime(2026, 10, 19, 10));
      expect(find.byKey(const ValueKey('home.weekReady')), findsOneWidget);
      expect(find.text('Haftalık değerlendirmen hazır'), findsOneWidget);
    });

    testWidgets('Pazar 21:00 görünür', (tester) async {
      await ac(tester, now: DateTime(2026, 10, 18, 21));
      expect(find.byKey(const ValueKey('home.weekReady')), findsOneWidget);
    });

    testWidgets('hafta ortası görünmez', (tester) async {
      await ac(tester, now: DateTime(2026, 10, 15, 21));
      expect(find.byKey(const ValueKey('home.weekReady')), findsNothing);
    });

    testWidgets('açılmış haftada görünmez', (tester) async {
      SharedPreferences.setMockInitialValues({
        'week_ready_opened': DateTime(2026, 10, 12).toIso8601String(),
      });
      await ac(tester, now: DateTime(2026, 10, 19, 10));
      expect(find.byKey(const ValueKey('home.weekReady')), findsNothing);
    });
  });
}
