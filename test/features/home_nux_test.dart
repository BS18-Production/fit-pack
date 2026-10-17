import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/health/step_providers.dart';
import 'package:fit_pack/features/health/step_source.dart';
import 'package:fit_pack/features/home/first_week.dart';
import 'package:fit_pack/features/home/home_screen.dart';
import 'package:fit_pack/features/workout/routine_providers.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_step_source.dart';
import '../helpers/test_database.dart';

/// Yeni kullanıcı deneyimi — Ana Sayfa "Bugün" kartı ve ilk hafta rehberi
/// (docs/49 §3).
void main() {
  Routine rutin(int id, String name) => Routine(
        id: id,
        name: name,
        createdAt: DateTime(2026),
        isArchived: false,
        orderIndex: id,
        syncState: 0,
        changedAtMs: 0,
        localSeq: 0,
      );

  RoutineExercise hareket({int? sets, int? rest}) => RoutineExercise(
        id: 1,
        routineId: 1,
        exerciseId: 1,
        orderIndex: 0,
        targetSets: sets,
        targetRestSec: rest,
        syncState: 0,
        changedAtMs: 0,
        localSeq: 0,
      );

  group('döngüde sıradaki rutin', () {
    final a = rutin(1, 'A'), b = rutin(2, 'B'), c = rutin(3, 'C');

    test('hiç yapılmadıysa ilk rutin', () {
      expect(rotationNext([a, b, c], null), a);
    });
    test('son yapılandan sonraki, sonda başa sarar', () {
      expect(rotationNext([a, b, c], 1), b);
      expect(rotationNext([a, b, c], 3), a);
    });
    test('son yapılan artık listede değilse ilk rutin', () {
      expect(rotationNext([a, b, c], 99), a);
    });
    test('rutin yoksa null', () {
      expect(rotationNext(const [], 1), isNull);
    });
  });

  group('rutin süresi tahmini', () {
    test('hedef yoksa 3 set × (40 + 90 sn)', () {
      // 6 hareket × 3 × 130 sn = 39 dk → 40.
      expect(estimateRoutineMinutes(List.filled(6, hareket())), 40);
    });
    test('hedefler kullanılır, 5 dakikanın altına inmez', () {
      expect(estimateRoutineMinutes([hareket(sets: 1, rest: 20)]), 5);
      expect(estimateRoutineMinutes(const []), isNull);
    });
  });

  group('ilk hafta görünürlüğü', () {
    final bugun = DateTime(2026, 10, 17);
    const yarim = FirstWeekProgress(workout: true);

    test('ilk 14 gün içinde ve adımlar bitmediyse görünür', () {
      expect(
          showFirstWeek(
              accountCreated: DateTime(2026, 10, 4, 23),
              today: bugun,
              progress: yarim),
          isTrue);
    });
    test('14. günden itibaren gizlenir', () {
      expect(
          showFirstWeek(
              accountCreated: DateTime(2026, 10, 3),
              today: bugun,
              progress: yarim),
          isFalse);
    });
    test('üç adım bitince gizlenir', () {
      expect(
          showFirstWeek(
              accountCreated: bugun,
              today: bugun,
              progress: const FirstWeekProgress(
                  workout: true, meal: true, weight: true)),
          isFalse);
    });
    test('oturum yoksa gizlenir', () {
      expect(
          showFirstWeek(accountCreated: null, today: bugun, progress: yarim),
          isFalse);
    });
    test('gün farkı yaz saatinden etkilenmez', () {
      expect(calendarDaysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)),
          2);
    });
  });

  group('Ana Sayfa', () {
    late AppDatabase db;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = newTestDatabase();
    });
    tearDown(() => db.close());

    Future<void> ac(WidgetTester tester, {DateTime? hesap}) async {
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
          accountCreatedProvider.overrideWithValue(hesap),
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

    Future<int> rutinEkle(String name, int order) =>
        db.into(db.routines).insert(RoutinesCompanion.insert(
              name: name,
              createdAt: DateTime.now(),
              orderIndex: Value(order),
            ));

    testWidgets('rutin yoksa iki başlangıç yolu', (tester) async {
      await ac(tester);
      expect(find.byKey(const ValueKey('home.noRoutine')), findsOneWidget);
      expect(find.text('Hazır program seç'), findsOneWidget);
      expect(find.text('Kendi rutinini kur'), findsOneWidget);
    });

    testWidgets('güne bağlı olmayan rutinlerde sıradaki gösterilir',
        (tester) async {
      final a = await rutinEkle('Tüm vücut A', 0);
      await rutinEkle('Tüm vücut B', 1);
      await db.into(db.workoutSessions).insert(WorkoutSessionsCompanion(
            date: Value(DateTime.now().subtract(const Duration(days: 1))),
            phase: const Value(0),
            workoutType: const Value('Tüm vücut'),
            routineId: Value(a),
          ));
      await ac(tester);

      expect(find.text('SIRADAKİ ANTRENMAN'), findsOneWidget);
      expect(find.text('Tüm vücut B'), findsOneWidget);
      expect(find.byKey(const ValueKey('home.noRoutine')), findsNothing);
    });

    testWidgets('ilk hafta: yeni hesapta görünür, adımlar veriden işaretlenir',
        (tester) async {
      await db.into(db.bodyMeasurements).insert(BodyMeasurementsCompanion(
            date: Value(DateTime.now()),
            weightKg: const Value(80),
          ));
      await ac(tester, hesap: DateTime.now());

      await tester.scrollUntilVisible(find.text('İlk antrenmanını bitir'), 150,
          scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const ValueKey('home.firstWeek')), findsOneWidget);
      expect(find.text('1/3 tamam'), findsOneWidget);
      expect(find.text('İlk antrenmanını bitir'), findsOneWidget);
    });

    Future<FirstWeekProgress?> kart(DateTime? hesap) async {
      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        accountCreatedProvider.overrideWithValue(hesap),
      ]);
      addTearDown(c.dispose);
      await c.read(firstWeekProgressProvider.future);
      return c.read(firstWeekCardProvider);
    }

    test('ilk hafta: eski hesapta ya da oturumsuz görünmez', () async {
      expect(await kart(DateTime.now()), isNotNull);
      expect(
          await kart(DateTime.now().subtract(const Duration(days: 30))), isNull);
      expect(await kart(null), isNull);
    });

    test('ilk hafta: üç adım bitince kart kalkar', () async {
      final foodId = await db.into(db.foods).insert(FoodsCompanion.insert(
            name: 'Yulaf',
            kcalPer100g: 380,
            proteinPer100g: 13,
            carbPer100g: 67,
            fatPer100g: 7,
          ));
      await db.into(db.foodLogs).insert(FoodLogsCompanion.insert(
            date: DateTime.now(),
            mealType: 'breakfast',
            foodId: foodId,
            grams: 50,
            computedKcal: 190,
            computedProtein: 6.5,
            computedCarb: 33.5,
            computedFat: 3.5,
          ));
      await db.into(db.workoutSessions).insert(WorkoutSessionsCompanion(
            date: Value(DateTime.now()),
            phase: const Value(0),
            workoutType: const Value('Tüm vücut'),
          ));
      expect((await kart(DateTime.now()))?.doneCount, 2);
      await db.into(db.bodyMeasurements).insert(BodyMeasurementsCompanion(
            date: Value(DateTime.now()),
            weightKg: const Value(80),
          ));
      expect(await kart(DateTime.now()), isNull);
    });

    test('ilk hafta: gizlenmiş tartı ölçümü kilo adımını tamamlamaz', () async {
      await db.into(db.bodyMeasurements).insert(BodyMeasurementsCompanion(
            date: Value(DateTime.now()),
            weightKg: const Value(80),
            hidden: const Value(true),
          ));
      expect((await kart(DateTime.now()))?.weight, isFalse);
    });
  });
}
