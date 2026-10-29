import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:fit_pack/core/feedback/feedback_service.dart';
import 'package:fit_pack/core/feedback/rest_sound.dart';
import 'package:fit_pack/core/notifications/notification_service.dart';
import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/workout/active_session_model.dart';
import 'package:fit_pack/features/workout/active_session_screen.dart';
import 'package:fit_pack/features/workout/workout_draft.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// Deneyim araştırması Faz 1a/1b — seanstan çıkış (docs/53), eksik setle
/// bitirme onayı, boş set, süre kuralı ve K6 "geçen sefer" satırı.
void main() {
  group('süre kuralı (docs/53)', () {
    final start = DateTime(2026, 10, 18, 18, 0);

    test('son setten sonra kısa ara → şimdiye kadar', () {
      expect(
        sessionElapsed(
          startedAt: start,
          now: start.add(const Duration(minutes: 50)),
          lastDoneAt: start.add(const Duration(minutes: 45)),
        ),
        const Duration(minutes: 50),
      );
    });

    test('uzun boşluk sayılmaz → son set + 1 dk', () {
      expect(
        sessionElapsed(
          startedAt: start,
          now: start.add(const Duration(minutes: 100)),
          lastDoneAt: start.add(const Duration(minutes: 40)),
        ),
        const Duration(minutes: 41),
      );
    });

    test('hiç set tamamlanmadı → şimdiye kadar', () {
      expect(
        sessionElapsed(
          startedAt: start,
          now: start.add(const Duration(minutes: 30)),
        ),
        const Duration(minutes: 30),
      );
    });

    test('taslak son set anını taşır; eski taslakta alan yok', () {
      final d = WorkoutDraft(
        title: 'Push',
        routineId: 1,
        startedAtMs: 1,
        sessionDateMs: 1,
        lastDoneAtMs: 1234,
        exercises: [],
      );
      expect(WorkoutDraft.decode(d.encode())!.lastDoneAtMs, 1234);
      final old = WorkoutDraft.decode(
          '{"title":"x","startedAtMs":1,"sessionDateMs":1,"exercises":[]}');
      expect(old!.lastDoneAt, isNull);
    });
  });

  late AppDatabase db;
  late int routineId;

  Future<WorkoutDraft?> reloadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return WorkoutDraftService().load();
  }

  /// Tek hareketli rutin (2 set, mola yok); [lastSets] geçen seans.
  Future<void> seed(List<(double, int)> lastSets) async {
    final exId = await db.workoutDao.insertCustomExercise(
      ExercisesCompanion.insert(
        name: 'Bench Press',
        category: 'compound',
        muscleGroups: 'chest',
      ),
    );
    routineId = await db.workoutDao.createRoutine(
      RoutinesCompanion.insert(name: 'Push', createdAt: DateTime(2026, 9, 1)),
    );
    await db.workoutDao.addRoutineExercise(
      RoutineExercisesCompanion.insert(
        routineId: routineId,
        exerciseId: exId,
        targetSets: const Value(2),
        targetRepsMin: const Value(8),
        targetRepsMax: const Value(12),
        targetRestSec: const Value(0),
      ),
    );
    if (lastSets.isEmpty) return;
    await db.workoutDao.insertSessionWithSets(
      WorkoutSessionsCompanion(
        date: Value(DateTime(2026, 9, 10)),
        phase: const Value(0),
        workoutType: const Value('Push'),
      ),
      (id) => [
        for (var i = 0; i < lastSets.length; i++)
          WorkoutSetsCompanion(
            sessionId: Value(id),
            exerciseId: Value(exId),
            setNumber: Value(i + 1),
            weightKg: Value(lastSets[i].$1),
            reps: Value(lastSets[i].$2),
            isComplete: const Value(true),
          ),
      ],
    );
  }

  /// Ana sayfa yerine boş bir kök; seans üstüne itilir (geri tuşu çalışsın).
  Future<void> open(WidgetTester tester, {bool free = false}) async {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('KÖK')),
        routes: [
          GoRoute(
            path: 's',
            builder: (_, _) => ActiveSessionScreen(routineId: free ? null : routineId),
          ),
          GoRoute(
            path: 'workout/summary/:id',
            builder: (_, _) => const Scaffold(body: Text('ÖZET')),
          ),
        ],
      ),
    ]);
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        feedbackServiceProvider.overrideWithValue(_SilentFeedback()),
        notificationServiceProvider.overrideWithValue(_NoNotifications()),
      ],
      child: MaterialApp.router(
        theme: ThemeData(
          colorScheme: AppColors.lightScheme,
          extensions: [AppColors.lightSemantic],
        ),
        locale: const Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        routerConfig: router,
        // Test yazı tipi (Ahem) her harfi kare çizer — mantık testi için küçült.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(0.7)),
          child: child!,
        ),
      ),
    ));
    router.push('/s');
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 600)); // geçiş animasyonu
    if (free) {
      final l = AppL10n.of(tester.element(find.byType(ActiveSessionScreen)));
      expect(find.text(l.workoutAddExercise), findsOneWidget);
    } else {
      expect(find.text('Bench Press'), findsOneWidget);
    }
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  Finder kgField(int set) => find.byType(TextField).at(set * 2);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
    _mockPlatform();
  });

  tearDown(() => db.close());

  testWidgets('serbest seans ilk açılışı yerelleştirmeyi güvenle okur',
      (tester) async {
    await open(tester, free: true);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  group('çıkış penceresi (docs/53)', () {
    testWidgets('ana düğme Devam et; kaydet ve çık taslağı korur', (
      tester,
    ) async {
      await seed([(60, 10), (60, 10)]);
      await open(tester);
      await tester.enterText(kgField(0), '62,5');
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      // Ana düğme Devam et (FilledButton), yıkıcı yol ikincil.
      expect(
        find.descendant(
            of: find.byType(FilledButton), matching: find.text('Devam et')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('session.exit.save')));
      await settle(tester);
      expect(find.text('KÖK'), findsOneWidget, reason: 'ekran kapandı');
      final d = await reloadDraft();
      expect(d, isNotNull);
      expect(d!.exercises.single.sets.first.weight, 62.5);
      expect(d.restEndsAtMs, isNull, reason: 'mola taslağa yazılmaz');
      await close(tester);
    });

    testWidgets('Devam et → ekranda kalır', (tester) async {
      await seed([(60, 10), (60, 10)]);
      await open(tester);
      await tester.enterText(kgField(0), '62,5');
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('session.exit.keep')));
      await settle(tester);
      expect(find.text('Bench Press'), findsOneWidget);
      await close(tester);
    });

    testWidgets('sil ve çık taslağı siler', (tester) async {
      await seed([(60, 10), (60, 10)]);
      await open(tester);
      await tester.enterText(kgField(0), '62,5');
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('session.exit.discard')));
      await settle(tester);
      expect(find.text('KÖK'), findsOneWidget);
      expect(await reloadDraft(), isNull);
      await close(tester);
    });
  });

  group('bitir (A2 #2)', () {
    testWidgets('eksik set varken onay; Devam et kaydetmez', (tester) async {
      await seed([(60, 10), (60, 10)]);
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('set.complete.0')));
      await settle(tester);
      await tester.tap(find.text('Bitir'));
      await settle(tester);
      expect(find.text('Antrenmanı bitir?'), findsOneWidget);
      expect(find.textContaining('1 set tamamlanmadı'), findsOneWidget);
      await tester.tap(find.text('Devam et'));
      await settle(tester);
      expect(await db.workoutDao.getAllSessions(), hasLength(1),
          reason: 'yalnız geçen seans');
      await tester.tap(find.text('Bitir'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('session.finishAnyway')));
      await settle(tester);
      expect(await db.workoutDao.getAllSessions(), hasLength(2));
      await close(tester);
    });

    testWidgets('bütün setler tamamsa tek dokunuş', (tester) async {
      await seed([(60, 10), (60, 10)]);
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('set.complete.0')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('set.complete.1')));
      await settle(tester);
      await tester.tap(find.text('Bitir'));
      await settle(tester);
      expect(find.text('Antrenmanı bitir?'), findsNothing);
      expect(await db.workoutDao.getAllSessions(), hasLength(2));
      await close(tester);
    });
  });

  testWidgets('boş set ✓ ile tamamlanmaz (A2 #5)', (tester) async {
    await seed([]); // geçmiş yok → öneri yok
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('set.complete.0')));
    await settle(tester);
    expect(find.text('Önce bu setin değerini gir'), findsOneWidget);
    expect(find.text('1/2 set'), findsNothing);
    await close(tester);
  });

  testWidgets('K6: öneri geçen seanstan düşükse "geçen sefer" yazar', (
    tester,
  ) async {
    await seed([(42.5, 8), (42.5, 8)]);
    await open(tester);
    await tester.enterText(kgField(0), '40');
    await tester.tap(find.byKey(const ValueKey('set.complete.0')));
    await settle(tester);
    // Set 2 önerisi üstteki setten 40; geçen seans 42,5 → ikisi de yazar.
    expect(find.textContaining('✓ ile 40 kg × 8 kaydedilir · geçen sefer 42'),
        findsOneWidget);
    await close(tester);
  });
}

class _SilentFeedback extends FeedbackService {
  @override
  void warmUp([RestSound sound = RestSound.fallback]) {}
  @override
  void playCountdown({int offsetMs = 0, RestSound? sound}) {}
  @override
  void stopCountdown() {}
  @override
  void restDone() {}
  @override
  void setDone() {}
  @override
  void record() {}
}

class _NoNotifications extends NotificationService {
  @override
  Future<void> scheduleRestDone({
    required DateTime at,
    required String title,
    required String body,
    String? earlyTitle,
    String? earlyBody,
    RestSound? sound,
  }) async {}
  @override
  Future<void> cancelRestDone() async {}
  @override
  Future<bool> requestPermission() async => false;
}

void _mockPlatform() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMessageCodec();
  for (final name in ['toggle', 'isEnabled']) {
    m.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$name',
      (_) async =>
          codec.encodeMessage(<Object?>[name == 'isEnabled' ? false : null]),
    );
  }
  for (final ch in [
    'fit_pack/live_activity',
    'fit_pack/rest_timer',
    'fit_pack/audio_session',
  ]) {
    m.setMockMethodCallHandler(MethodChannel(ch), (c) async => false);
  }
}
