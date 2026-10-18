import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/health/step_providers.dart';
import 'package:fit_pack/features/health/step_source.dart';
import 'package:fit_pack/features/home/home_screen.dart';
import 'package:fit_pack/features/home/today_task.dart';
import 'package:fit_pack/features/workout/routine_providers.dart';
import 'package:fit_pack/features/workout/workout_draft.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_step_source.dart';
import '../helpers/test_database.dart';

/// Ana sayfa birincil görevi (docs/54 §2): öncelik tablosu + tek birincil kart.
void main() {
  final draft = WorkoutDraft(
      title: 'Push',
      routineId: 1,
      startedAtMs: 0,
      sessionDateMs: 0,
      exercises: const []);
  final session = WorkoutSession(
      id: 7,
      date: DateTime(2026, 10, 18, 18),
      phase: 0,
      workoutType: 'Push',
      durationMin: 52,
      kneeStatus: 'ok',
      isDeload: false);
  Routine r(int id, String name) => Routine(
      id: id,
      name: name,
      createdAt: DateTime(2026, 10, 1),
      orderIndex: 0,
      isArchived: false);

  TodayTask task({
    bool draftLoading = false,
    bool draftError = false,
    WorkoutDraft? d,
    WorkoutSession? done,
    bool routineLoading = false,
    bool routineError = false,
    TodayRoutine? routine,
  }) =>
      todayTask(
        draftLoading: draftLoading,
        draftError: draftError,
        draft: d,
        finishedToday: done,
        routineLoading: routineLoading,
        routineError: routineError,
        routine: routine,
      );

  group('öncelik tablosu', () {
    test('0 taslak okunuyor → iskelet, yeni Başlat yok', () {
      expect(task(draftLoading: true, routine: TodayRoutine(today: r(1, 'A')))
          .kind, TodayTaskKind.loading);
    });
    test('1 taslak hatası → tekrar dene', () {
      expect(task(draftError: true).kind, TodayTaskKind.draftError);
    });
    test('2 süren seans her şeyi bastırır', () {
      final t = task(
          d: draft, done: session, routine: TodayRoutine(today: r(1, 'A')));
      expect(t.kind, TodayTaskKind.resume);
      expect(t.draft, same(draft));
    });
    test('3 bugün bitti → özet, planlı rutin yarışmaz (D1)', () {
      final t = task(done: session, routine: TodayRoutine(today: r(1, 'A')));
      expect(t.kind, TodayTaskKind.finishedToday);
      expect(t.session!.id, 7);
    });
    test('3 bitmiş seans, rutinler hâlâ yüklenirken de özet', () {
      expect(task(done: session, routineLoading: true).kind,
          TodayTaskKind.finishedToday);
    });
    test('rutin okunuyor → iskelet; hata → tekrar dene', () {
      expect(task(routineLoading: true).kind, TodayTaskKind.loading);
      expect(task(routineError: true).kind, TodayTaskKind.routineError);
    });
    test('4 hiç rutin yok → program seç', () {
      expect(task(routine: const TodayRoutine()).kind, TodayTaskKind.noRoutine);
      expect(task().kind, TodayTaskKind.noRoutine);
    });
    test('5 bugüne planlı', () {
      final t = task(routine: TodayRoutine(today: r(1, 'A'), next: r(2, 'B')));
      expect(t.kind, TodayTaskKind.plannedToday);
      expect(t.routine!.name, 'A');
    });
    test('6 döngüde sıradaki', () {
      final t = task(
          routine: TodayRoutine(hasRoutines: true, upNext: r(3, 'C')));
      expect(t.kind, TodayTaskKind.upNext);
      expect(t.routine!.id, 3);
    });
    test('7 planlı dinlenme günü sıradakinin adını taşır', () {
      final t = task(routine: TodayRoutine(next: r(2, 'B')));
      expect(t.kind, TodayTaskKind.restDay);
      expect(t.nextName, 'B');
    });
  });

  group('Ana Sayfa birincil kart', () {
    late AppDatabase db;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = newTestDatabase();
    });
    tearDown(() => db.close());

    Future<void> ac(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await db.userProfileDao.ensureProfile();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          stepSourceProvider.overrideWithValue(
              FakeStepSource(status: StepPlatformStatus.unavailable)),
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

    Future<void> planliRutin() => db.into(db.routines).insert(
        RoutinesCompanion.insert(
            name: 'Üst A',
            createdAt: DateTime.now(),
            scheduledWeekday: Value(DateTime.now().weekday)));

    for (final size in [const Size(393, 852), const Size(320, 640)]) {
      testWidgets('planlı gün: Başlat ilk ekranda, menünün üstünde ($size)',
          (tester) async {
        await planliRutin();
        await ac(tester, size);
        final start = find.text('Antrenmanı başlat');
        expect(start, findsOneWidget);
        // Yüzen alt menü ~96 pt: düğmenin altı onun üstünde kalmalı.
        expect(tester.getBottomLeft(start).dy, lessThan(size.height - 96));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('bugün bitti: tek birincil kart özet, Başlat yok (D1)',
        (tester) async {
      await planliRutin();
      await db.into(db.workoutSessions).insert(WorkoutSessionsCompanion(
            date: Value(DateTime.now()),
            phase: const Value(0),
            workoutType: const Value('Üst A'),
            durationMin: const Value(48),
          ));
      await ac(tester, const Size(393, 852));
      expect(find.byKey(const ValueKey('home.finishedToday')), findsOneWidget);
      expect(find.text('Özeti gör'), findsOneWidget);
      expect(find.text('Kaydedildi · 48 dk'), findsOneWidget);
      expect(find.byKey(const ValueKey('home.trainAnyway')), findsOneWidget);
      expect(find.text('Antrenmanı başlat'), findsNothing);
    });

    testWidgets('beslenme satırında + Ekle (D2), adlı ve 48 pt', (tester) async {
      final handle = tester.ensureSemantics();
      await ac(tester, const Size(393, 852));
      final add = find.byKey(const ValueKey('home.todayLine.addMeal'));
      expect(add, findsOneWidget);
      final size = tester.getSize(add);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(find.byTooltip(RegExp('^Öğün ekle: ')), findsOneWidget);
      handle.dispose();
    });
  });
}
