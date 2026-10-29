import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'package:fit_pack/core/feedback/feedback_service.dart';
import 'package:fit_pack/core/feedback/rest_sound.dart';
import 'package:fit_pack/core/live_activity/workout_live_activity.dart';
import 'package:fit_pack/core/notifications/notification_service.dart';
import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/cloud/auth_service.dart';
import 'package:fit_pack/features/workout/active_session_screen.dart';
import 'package:fit_pack/features/workout/active_session_widgets.dart';
import 'package:fit_pack/features/workout/workout_draft.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../helpers/test_database.dart';

final _testUser = StateProvider<User?>((ref) => _user('account-a'));
User _user(String id) => User(
  id: id,
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-10-01T00:00:00Z',
);

void main() {
  late AppDatabase db;
  late Exercise original, replacement;
  late int routineId;
  late _ControlledDrafts drafts;
  final shown = <Map<Object?, Object?>>[];
  late ProviderContainer container;
  ProviderContainer? scopeContainer;

  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<WorkoutDraft?> readDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return WorkoutDraftService().load();
  }

  // `previous` is a legacy cached history label, recomputed on resume.
  // Cancellation/failure must preserve user data, not that derived cache.
  Map<String, dynamic> userData(WorkoutDraft draft) {
    final value = draft.toJson();
    for (final exercise in value['exercises'] as List) {
      (exercise as Map<String, dynamic>).remove('prev');
    }
    return value;
  }

  Future<void> seed(
    List<DraftSet> sets, {
    bool duplicate = false,
    bool replacementInRoutine = false,
  }) async {
    final originalId = await db.workoutDao.insertCustomExercise(
      ExercisesCompanion.insert(
        name: 'Bench Press',
        category: 'compound',
        muscleGroups: 'chest',
      ),
    );
    final replacementId = await db.workoutDao.insertCustomExercise(
      ExercisesCompanion.insert(
        name: 'Dumbbell Press',
        category: 'compound',
        muscleGroups: 'chest',
      ),
    );
    original = (await db.workoutDao.getExerciseById(originalId))!;
    replacement = (await db.workoutDao.getExerciseById(replacementId))!;
    routineId = await db.workoutDao.createRoutine(
      RoutinesCompanion.insert(name: 'Push', createdAt: DateTime(2026, 9, 1)),
    );
    for (final id in [originalId, if (replacementInRoutine) replacementId]) {
      await db.workoutDao.addRoutineExercise(
        RoutineExercisesCompanion.insert(
          routineId: routineId,
          exerciseId: id,
          targetSets: const Value(3),
          targetRestSec: const Value(0),
        ),
      );
    }
    await db.workoutDao.insertSessionWithSets(
      WorkoutSessionsCompanion(
        date: Value(DateTime(2026, 10, 1)),
        phase: const Value(0),
        workoutType: const Value('Before replacement'),
      ),
      (id) => [
        for (final ex in [originalId, replacementId])
          WorkoutSetsCompanion(
            sessionId: Value(id),
            exerciseId: Value(ex),
            setNumber: const Value(1),
            weightKg: Value(ex == originalId ? 60 : 24),
            reps: const Value(8),
            isComplete: const Value(true),
          ),
      ],
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    await WorkoutDraftService().save(
      WorkoutDraft(
        title: 'Push',
        routineId: routineId,
        startedAtMs: now,
        sessionDateMs: now,
        exercises: [
          DraftExercise(
            exerciseId: originalId,
            restSec: 0,
            previous: null,
            sets: sets,
          ),
          if (duplicate)
            DraftExercise(
              exerciseId: originalId,
              restSec: 0,
              previous: null,
              sets: [DraftSet(weight: 99, reps: 4, done: true), DraftSet()],
            ),
        ],
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const ActiveSessionScreen(resume: true),
        ),
        GoRoute(
          path: AppRoutes.exercisesSelect,
          builder: (context, _) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  key: const ValueKey('picker.new'),
                  onPressed: () => context.pop(replacement),
                  child: const Text('Choose replacement'),
                ),
                TextButton(
                  key: const ValueKey('picker.same'),
                  onPressed: () => context.pop(original),
                  child: const Text('Choose original'),
                ),
                TextButton(
                  key: const ValueKey('picker.cancel'),
                  onPressed: () => context.pop(),
                  child: const Text('Cancel picker'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(1000, 2800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    if (scopeContainer == null) {
      final created = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          workoutDraftServiceProvider.overrideWithValue(drafts),
          currentUserProvider.overrideWith((ref) => ref.watch(_testUser)),
          feedbackServiceProvider.overrideWithValue(_SilentFeedback()),
          notificationServiceProvider.overrideWithValue(_NoNotifications()),
        ],
      );
      scopeContainer = created;
      addTearDown(created.dispose);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scopeContainer!,
        child: MaterialApp.router(
          theme: ThemeData(
            colorScheme: AppColors.lightScheme,
            extensions: [AppColors.lightSemantic],
          ),
          locale: const Locale('tr'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(0.7)),
            child: child!,
          ),
        ),
      ),
    );
    await flush(tester);
    container = ProviderScope.containerOf(
      tester.element(find.byType(ActiveSessionScreen)),
    );
    expect(find.byType(ExerciseBlock), findsWidgets);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await flush(tester);
  }

  Future<void> explain(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Hareket seçenekleri').first);
    await flush(tester);
    await tester.tap(find.text('Hareketi değiştir'));
    await flush(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
  }

  Future<void> picker(WidgetTester tester) async {
    await explain(tester);
    await tester.tap(find.text('Hareket seç'));
    await flush(tester);
    expect(find.byKey(const ValueKey('picker.new')), findsOneWidget);
  }

  Future<void> choose(WidgetTester tester, {String action = 'new'}) async {
    await tester.tap(find.byKey(ValueKey('picker.$action')));
    await flush(tester);
  }

  List<ExerciseBlock> blocks(WidgetTester tester) =>
      tester.widgetList<ExerciseBlock>(find.byType(ExerciseBlock)).toList();

  Future<Object?> act(WidgetTester tester, String action, String key) async {
    const codec = StandardMethodCodec();
    Object? reply;
    await tester.runAsync(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            WorkoutLiveActivity.channel.name,
            codec.encodeMethodCall(
              MethodCall('action', {'action': action, 'setKey': key}),
            ),
            (data) => reply = data == null ? null : codec.decodeEnvelope(data),
          ),
    );
    await flush(tester);
    return reply;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
    drafts = _ControlledDrafts();
    scopeContainer = null;
    shown.clear();
    _mockWakelock();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(WorkoutLiveActivity.channel, (call) async {
          if (call.arguments is Map) shown.add(call.arguments as Map);
          return true;
        });
  });
  tearDown(() => db.close());

  testWidgets(
    'completed and entered sets stay original; blanks use own history',
    (tester) async {
      await seed([
        DraftSet(weight: 65, reps: 7, rpe: 8, done: true, isRecord: true),
        DraftSet(weight: 70, reps: 5),
        DraftSet(),
        DraftSet(),
      ]);
      final beforeSets = await db.select(db.workoutSets).get();
      final beforeRoutine = await db.select(db.routineExercises).get();
      await open(tester);
      await picker(tester);
      await choose(tester);
      final draft = (await tester.runAsync<WorkoutDraft?>(readDraft))!;
      expect(draft.exercises.map((e) => e.exerciseId), [
        replacement.id,
        original.id,
      ]);
      final retained = draft.exercises.singleWhere(
        (e) => e.exerciseId == original.id,
      );
      final changed = draft.exercises.singleWhere(
        (e) => e.exerciseId == replacement.id,
      );
      expect(retained.sets.map((s) => s.weight), [65, 70]);
      expect(retained.sets[0].done, isTrue);
      expect(retained.sets[0].rpe, 8);
      expect(retained.sets[0].isRecord, isTrue);
      expect(retained.sets[1].done, isFalse);
      expect(changed.sets, hasLength(2));
      expect(changed.sets.every((s) => s.weight == null && !s.done), isTrue);
      expect(blocks(tester).first.ex.lastSets.single.weightKg, 24);
      expect(
        await tester.runAsync(() => db.select(db.workoutSets).get()),
        beforeSets,
      );
      expect(
        await tester.runAsync(() => db.select(db.routineExercises).get()),
        beforeRoutine,
      );
      await close(tester);
    },
  );

  testWidgets('only selected duplicate exercise block changes', (tester) async {
    await seed([DraftSet()], duplicate: true);
    await open(tester);
    await picker(tester);
    await choose(tester);
    final draft = (await tester.runAsync<WorkoutDraft?>(readDraft))!;
    expect(draft.exercises.map((e) => e.exerciseId), [
      replacement.id,
      original.id,
    ]);
    expect(draft.exercises[1].sets.first.weight, 99);
    expect(draft.exercises[1].sets.first.done, isTrue);
    expect(draft.exercises[1].sets, hasLength(2));
    await close(tester);
  });

  testWidgets(
    'explanation cancel, picker cancel and same selection are no-ops',
    (tester) async {
      await seed([DraftSet(weight: 75, reps: 6), DraftSet()]);
      await open(tester);
      final before = userData((await tester.runAsync<WorkoutDraft?>(readDraft))!);
      await explain(tester);
      await tester.tap(find.text('İptal'));
      await flush(tester);
      expect(userData((await tester.runAsync<WorkoutDraft?>(readDraft))!), before);
      await picker(tester);
      await choose(tester, action: 'cancel');
      expect(userData((await tester.runAsync<WorkoutDraft?>(readDraft))!), before);
      await picker(tester);
      await choose(tester, action: 'same');
      expect(userData((await tester.runAsync<WorkoutDraft?>(readDraft))!), before);
      expect(drafts.candidateCalls, 0);
      await close(tester);
    },
  );

  testWidgets(
    'replacement remains session-only after resume for routine target',
    (tester) async {
      await seed([DraftSet()], replacementInRoutine: true);
      final beforeRoutine = await db.select(db.routineExercises).get();
      await open(tester);
      await picker(tester);
      await choose(tester);
      expect(
        (await tester.runAsync<WorkoutDraft?>(readDraft))!.exercises.single.sessionOnly,
        isTrue,
      );
      await close(tester);
      await open(tester);
      expect(blocks(tester).single.ex.inRoutine, isFalse);
      expect(blocks(tester).single.ex.advice, isNull);
      await tester.tap(find.byTooltip('Dinlenme süresini değiştir'));
      await flush(tester);
      expect(find.text('Bu antrenman için geçerli.'), findsOneWidget);
      expect(
        find.text(
          'Rutine de kaydedilir — sonraki antrenman bu süreyle başlar.',
        ),
        findsNothing,
      );
      await tester.tap(find.text('0:30'));
      await flush(tester);
      expect(
        await tester.runAsync(() => db.select(db.routineExercises).get()),
        beforeRoutine,
      );
      await close(tester);
    },
  );

  testWidgets(
    'failed candidate save leaves old screen and draft, retry succeeds',
    (tester) async {
      await seed([DraftSet(weight: 75, reps: 6), DraftSet()]);
      await open(tester);
      final before = userData((await tester.runAsync<WorkoutDraft?>(readDraft))!);
      drafts.failNext = true;
      await picker(tester);
      await choose(tester);
      expect(blocks(tester).single.ex.exercise.id, original.id);
      expect(userData((await tester.runAsync<WorkoutDraft?>(readDraft))!), before);
      expect(
        find.text(
          'Hareket değiştirilemedi. Mevcut setlerin korundu. Tekrar dene.',
        ),
        findsOneWidget,
      );
      await picker(tester);
      await choose(tester);
      expect(
        (await tester.runAsync<WorkoutDraft?>(readDraft))!.exercises.first.exerciseId,
        replacement.id,
      );
      await close(tester);
    },
  );

  testWidgets(
    'pending save keeps old view; lifecycle cannot overwrite candidate',
    (tester) async {
      await seed([DraftSet()]);
      await open(tester);
      drafts.hold = Completer<void>();
      await picker(tester);
      final stale = shown.last['setKey'] as String;
      await choose(tester);
      expect(drafts.candidateCalls, 1);
      expect(blocks(tester).single.ex.exercise.id, original.id);
      expect(await act(tester, 'completeSet', stale), isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await flush(tester);
      drafts.hold!.complete();
      await flush(tester);
      expect(
        (await tester.runAsync<WorkoutDraft?>(readDraft))!.exercises.single.exerciseId,
        replacement.id,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await close(tester);
    },
  );

  testWidgets(
    'clear while picker is open rejects selection without recreation',
    (tester) async {
      await seed([DraftSet()]);
      await open(tester);
      await picker(tester);
      await tester.runAsync(() => WorkoutDraftService().clear());
      await choose(tester);
      expect(await tester.runAsync<WorkoutDraft?>(readDraft), isNull);
      expect(drafts.candidateCalls, 0);
      expect(blocks(tester).single.ex.exercise.id, original.id);
      await close(tester);
    },
  );

  testWidgets('account change while picker is open rejects the old selection', (
    tester,
  ) async {
    await seed([DraftSet()]);
    await open(tester);
    await picker(tester);
    container.read(_testUser.notifier).state = _user('account-b');
    await flush(tester);
    await choose(tester);
    expect(drafts.candidateCalls, 0);
    expect(
      (await tester.runAsync<WorkoutDraft?>(readDraft))!.exercises.single.exerciseId,
      original.id,
    );
    await close(tester);
  });

  testWidgets(
    'clear during pending save prevents replacement draft resurrection',
    (tester) async {
      await seed([DraftSet(weight: 60, reps: 8, done: true), DraftSet()]);
      await open(tester);
      drafts.hold = Completer<void>();
      await picker(tester);
      await choose(tester);
      expect(drafts.candidateCalls, 1);
      await tester.runAsync(() => WorkoutDraftService().clear());
      drafts.hold!.complete();
      await flush(tester);
      expect(await tester.runAsync<WorkoutDraft?>(readDraft), isNull);
      expect(blocks(tester).single.ex.exercise.id, original.id);
      await close(tester);
    },
  );

  testWidgets(
    'disposal during pending save keeps replacement for next resume',
    (tester) async {
      await seed([DraftSet(weight: 60, reps: 8, done: true), DraftSet()]);
      await open(tester);
      drafts.hold = Completer<void>();
      await picker(tester);
      await choose(tester);
      expect(drafts.candidateCalls, 1);
      await close(tester);
      drafts.hold!.complete();
      await flush(tester);
      final saved = (await tester.runAsync<WorkoutDraft?>(readDraft))!;
      expect(saved.exercises.map((e) => e.exerciseId), [
        original.id,
        replacement.id,
      ]);
      expect(saved.exercises.first.sets.single.done, isTrue);
      await open(tester);
      expect(blocks(tester).last.ex.exercise.id, replacement.id);
      await close(tester);
    },
  );

  testWidgets('account switch after disposal rejects pending replacement', (
    tester,
  ) async {
    await seed([DraftSet(weight: 60, reps: 8, done: true), DraftSet()]);
    await open(tester);
    drafts.hold = Completer<void>();
    await picker(tester);
    await choose(tester);
    expect(drafts.candidateCalls, 1);
    await close(tester);
    container.read(_testUser.notifier).state = _user('account-b');
    await flush(tester);
    drafts.hold!.complete();
    await flush(tester);
    final saved = (await tester.runAsync<WorkoutDraft?>(readDraft))!;
    expect(saved.exercises.single.exerciseId, original.id);
    expect(saved.exercises.single.sets.first.done, isTrue);
  });

  testWidgets(
    'account switch during pending replacement leaves original draft',
    (tester) async {
      await seed([DraftSet()]);
      await open(tester);
      drafts.hold = Completer<void>();
      await picker(tester);
      await choose(tester);
      container.read(_testUser.notifier).state = _user('account-b');
      await flush(tester);
      drafts.hold!.complete();
      await flush(tester);
      expect(
        (await tester.runAsync<WorkoutDraft?>(readDraft))!.exercises.single.exerciseId,
        original.id,
      );
      expect(blocks(tester).single.ex.exercise.id, original.id);
      await close(tester);
    },
  );

  testWidgets('switching account away and back does not revive picker action', (
    tester,
  ) async {
    await seed([DraftSet()]);
    await open(tester);
    await picker(tester);
    container.read(_testUser.notifier).state = _user('account-b');
    await flush(tester);
    container.read(_testUser.notifier).state = _user('account-a');
    await flush(tester);
    await choose(tester);
    expect(drafts.candidateCalls, 0);
    expect(
      (await tester.runAsync<WorkoutDraft?>(readDraft))!.exercises.single.exerciseId,
      original.id,
    );
    await close(tester);
  });

  for (final failDrain in [false, true]) {
    testWidgets(failDrain
        ? 'failed timer drain retries once on disposal and preserves entered duration'
        : 'another block timer finishing during save survives disposal', (tester) async {
    await seed([DraftSet()]);
    final timedId = await db.workoutDao.insertCustomExercise(
      ExercisesCompanion.insert(
        name: 'Plank',
        category: 'calisthenics',
        muscleGroups: 'core',
        measurementType: const Value('time'),
      ),
    );
    await db.workoutDao.insertSessionWithSets(
      WorkoutSessionsCompanion(
        date: Value(DateTime(2026, 10, 2)),
        phase: const Value(0),
        workoutType: const Value('Timer history'),
      ),
      (id) => [
        WorkoutSetsCompanion(
          sessionId: Value(id),
          exerciseId: Value(timedId),
          setNumber: const Value(1),
          durationSec: const Value(1),
          isComplete: const Value(true),
        ),
      ],
    );
    final initial = (await readDraft())!;
    await WorkoutDraftService().save(
      WorkoutDraft(
        title: initial.title,
        routineId: initial.routineId,
        startedAtMs: initial.startedAtMs,
        sessionDateMs: initial.sessionDateMs,
        exercises: [
          ...initial.exercises,
          DraftExercise(
            exerciseId: timedId,
            restSec: 0,
            previous: null,
            sets: [DraftSet()],
          ),
        ],
      ),
    );
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('set-timer-start')));
    await flush(tester);
    drafts.hold = Completer<void>();
    if (failDrain) drafts.failCandidate = 2;
    await picker(tester);
    await choose(tester);
    expect(drafts.candidateCalls, 1);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    await tester.pump(const Duration(seconds: 1));
    await flush(tester);
    expect(blocks(tester).last.ex.sets.single.durationSec, 1);
    if (!failDrain) await close(tester);
    drafts.hold!.complete();
    await flush(tester);
    if (failDrain) {
      expect(drafts.candidateCalls, 2);
      final beforeRetry = (await tester.runAsync<WorkoutDraft?>(readDraft))!;
      expect(beforeRetry.exercises.last.sets.single.durationSec, isNull);
      expect(blocks(tester).last.ex.sets.single.durationSec, 1);
      await close(tester);
    }
    final saved = (await tester.runAsync<WorkoutDraft?>(readDraft))!;
    expect(saved.exercises.map((e) => e.exerciseId), [replacement.id, timedId]);
    expect(saved.exercises.last.sets.single.durationSec, 1);
    expect(saved.exercises.last.sets.single.done, isFalse);
    expect(
      drafts.candidateCalls,
      failDrain ? 3 : 2,
      reason: 'timer result must survive the candidate and one failed drain',
    );
  });
  }

  testWidgets('timed source does not expose replacement during running timer', (
    tester,
  ) async {
    await seed([DraftSet(durationSec: 30)]);
    await (db.update(db.exercises)..where((row) => row.id.equals(original.id)))
        .write(const ExercisesCompanion(measurementType: Value('time')));
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('set-timer-start')));
    await flush(tester);
    expect(find.byKey(const ValueKey('set-timer-stop')), findsOneWidget);
    await tester.tap(find.byTooltip('Hareket seçenekleri'));
    await flush(tester);
    expect(find.text('Hareketi değiştir'), findsNothing);
    await close(tester);
  });

  testWidgets('auth transition rejects native command before any draft clear',
      (tester) async {
    await seed([DraftSet()]);
    await open(tester);
    final oldKey = shown.last['setKey'] as String;
    final clearCount = drafts.clearCount;
    final publications = shown.length;
    container.read(_testUser.notifier).state = _user('account-b');
    // No frame pump and no draft clear between auth transition and command.
    expect(await act(tester, 'completeSet', oldKey), isFalse);
    expect(await act(tester, 'stepUp', oldKey), isFalse);
    expect(drafts.clearCount, clearCount);
    final saved = (await tester.runAsync<WorkoutDraft?>(readDraft))!;
    expect(saved.exercises.single.sets.single.done, isFalse);
    expect(saved.exercises.single.sets.single.weight, isNull);
    expect(shown.length, publications,
        reason: 'old session must not republish while cleanup has not run');
    await close(tester);
  });

  testWidgets('A to B to A cannot revive original native command without clear',
      (tester) async {
    await seed([DraftSet()]);
    await open(tester);
    final oldKey = shown.last['setKey'] as String;
    final clearCount = drafts.clearCount;
    container.read(_testUser.notifier).state = _user('account-b');
    expect(await act(tester, 'completeSet', oldKey), isFalse);
    container.read(_testUser.notifier).state = _user('account-a');
    expect(await act(tester, 'completeSet', oldKey), isFalse);
    expect(await act(tester, 'stepUp', oldKey), isFalse);
    expect(drafts.clearCount, clearCount);
    expect((await tester.runAsync<WorkoutDraft?>(readDraft))!
        .exercises.single.sets.single.done, isFalse);
    await close(tester);
  });

  for (final ending in ['cancel', 'failure', 'pending']) {
    testWidgets('native command stays invalid after $ending replacement and auth gap',
        (tester) async {
      await seed([DraftSet()]);
      await open(tester);
      final oldKey = shown.last['setKey'] as String;
      final clearCount = drafts.clearCount;
      if (ending == 'failure') drafts.failNext = true;
      if (ending == 'pending') drafts.hold = Completer<void>();
      await picker(tester);
      if (ending != 'cancel') await choose(tester);
      container.read(_testUser.notifier).state = _user('account-b');
      expect(await act(tester, 'completeSet', oldKey), isFalse);
      if (ending == 'cancel') await choose(tester, action: 'cancel');
      if (ending == 'pending') {
        drafts.hold!.complete();
        await flush(tester);
      }
      expect(find.byWidgetPredicate((widget) =>
          widget is LinearProgressIndicator && widget.value == null), findsNothing,
          reason: 'rejection after this point cannot rely on replacement busy flag');
      expect(await act(tester, 'completeSet', oldKey), isFalse);
      container.read(_testUser.notifier).state = _user('account-a');
      expect(await act(tester, 'stepUp', oldKey), isFalse);
      expect(drafts.clearCount, clearCount);
      final saved = (await tester.runAsync<WorkoutDraft?>(readDraft))!;
      expect(saved.exercises.single.exerciseId, original.id);
      expect(saved.exercises.single.sets.single.done, isFalse);
      expect(saved.exercises.single.sets.single.weight, isNull);
      await close(tester);
    });
  }

  testWidgets(
    'old widget command is rejected and current command uses new history',
    (tester) async {
      await seed([DraftSet()]);
      await open(tester);
      final stale = shown.last['setKey'] as String;
      await picker(tester);
      expect(await act(tester, 'completeSet', stale), isFalse);
      await choose(tester);
      final current = shown.last['setKey'] as String;
      expect(current, isNot(stale));
      expect(await act(tester, 'completeSet', stale), isFalse);
      expect(await act(tester, 'completeSet', current), isTrue);
      final saved = (await tester.runAsync<WorkoutDraft?>(readDraft))!;
      expect(saved.exercises.single.exerciseId, replacement.id);
      expect(saved.exercises.single.sets.single.done, isTrue);
      expect(saved.exercises.single.sets.single.weight, 24);
      await close(tester);
    },
  );
}

class _ControlledDrafts extends WorkoutDraftService {
  bool failNext = false;
  int? failCandidate;
  Completer<void>? hold;
  int candidateCalls = 0;

  @override
  Future<bool> saveIfCurrent(
    WorkoutDraft draft, {
    required int expectedClearCount,
    bool Function()? isCurrent,
  }) async {
    if (draft.exercises.any((e) => e.sessionOnly)) {
      candidateCalls++;
      if (failNext || candidateCalls == failCandidate) {
        failNext = false;
        failCandidate = null;
        throw StateError('synthetic replacement save failure');
      }
      if (hold != null) await hold!.future;
    }
    return super.saveIfCurrent(
      draft,
      expectedClearCount: expectedClearCount,
      isCurrent: isCurrent,
    );
  }
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
}

void _mockWakelock() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMessageCodec();
  for (final name in ['toggle', 'isEnabled']) {
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$name',
      (_) async =>
          codec.encodeMessage(<Object?>[name == 'isEnabled' ? false : null]),
    );
  }
}
