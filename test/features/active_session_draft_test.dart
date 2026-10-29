import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:fit_pack/core/feedback/feedback_service.dart';
import 'package:fit_pack/core/feedback/rest_sound.dart';
import 'package:fit_pack/core/live_activity/workout_live_activity.dart';
import 'package:fit_pack/core/notifications/notification_service.dart';
import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/workout_dao.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/workout/active_session_screen.dart';
import 'package:fit_pack/features/workout/workout_draft.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// Sağlamlık paketi (2026-09-17) — aktif seans taslağı ekranla aynı kalmalı.
///
/// Taslak her kontrolde **diskten yeniden okunur** (`reloadDraft`):
/// `SharedPreferences.reload()` önbelleği atıp platform deposundan okur —
/// uygulama yeniden açıldığında göreceği değer budur.
void main() {
  late AppDatabase db;
  late int routineId;
  WorkoutDao? overrideDao;
  WorkoutDraftService? overrideDrafts;

  Future<WorkoutDraft?> reloadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return WorkoutDraftService().load();
  }

  /// Geçen seans [lastSets] (kg, tekrar) olan tek hareketli rutin; hedef
  /// 8–12 tekrar, 2 set, mola yok (sayaç zamanlayıcısı testte kalmasın).
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

  Widget app({bool resume = false}) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      if (overrideDao != null) workoutDaoProvider.overrideWithValue(overrideDao!),
      if (overrideDrafts != null)
        workoutDraftServiceProvider.overrideWithValue(overrideDrafts!),
      feedbackServiceProvider.overrideWithValue(_SilentFeedback()),
      notificationServiceProvider.overrideWithValue(_NoNotifications()),
    ],
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: AppColors.lightScheme,
        extensions: [AppColors.lightSemantic],
      ),
      locale: const Locale('tr'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      // Test yazı tipi (Ahem) her harfi kare çizer; 44 px'lik RPE başlığı
      // gerçek yazı tipinde sığarken burada taşar. Mantık testi için küçült.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(0.7)),
        child: child!,
      ),
      home: resume
          ? const ActiveSessionScreen(resume: true)
          : ActiveSessionScreen(routineId: routineId),
    ),
  );

  Future<void> open(
    WidgetTester tester, {
    bool resume = false,
    int exerciseCount = 1,
  }) async {
    await tester.pumpWidget(app(resume: resume));
    // Yükleme DB'den okur; gerçek G/Ç için runAsync, sonra çizim.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(find.text('Bench Press'), findsNWidgets(exerciseCount));
  }

  /// Ekranı kapatır (dispose) — canlı süre sayacı da durur.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  // Set başına iki metin kutusu (kg, tekrar); RPE seçici panelle girilir.
  Finder kgField(int set) => find.byType(TextField).at(set * 2);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
    overrideDao = null;
    overrideDrafts = null;
    _mockWakelock();
  });

  tearDown(() => db.close());

  group('set alanı → taslak', () {
    testWidgets('yazım durunca gecikmeyle kaydedilir', (tester) async {
      await seed([(60, 10), (60, 10)]);
      await open(tester);

      await tester.enterText(kgField(0), '62.5');
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        (await tester.runAsync(reloadDraft))!.exercises.single.sets[0].weight,
        isNull,
        reason: 'her tuşta değil, yazım durunca yazılır',
      );

      await tester.pump(const Duration(milliseconds: 500));
      final d = await tester.runAsync(reloadDraft);
      expect(d!.exercises.single.sets[0].weight, 62.5);
      await close(tester);
    });

    testWidgets('bekleyen yazım arka plana geçişte hemen tamamlanır', (
      tester,
    ) async {
      await seed([(60, 10), (60, 10)]);
      await open(tester);

      await tester.enterText(kgField(1), '70');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(); // gecikme süresi beklenmeden
      final d = await tester.runAsync(reloadDraft);
      expect(d!.exercises.single.sets[1].weight, 70);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await close(tester);
    });

    testWidgets('bekleyen yazım ekran kapanışında tamamlanır', (tester) async {
      await seed([(60, 10), (60, 10)]);
      await open(tester);

      await tester.enterText(kgField(0), '65');
      await close(tester); // gecikme süresi dolmadan ekran kapandı
      final d = await tester.runAsync(reloadDraft);
      expect(d!.exercises.single.sets[0].weight, 65);
    });

    testWidgets('başka yerden silinen taslak (hesap değişimi) geri gelmez', (
      tester,
    ) async {
      await seed([(60, 10), (60, 10)]);
      await open(tester);

      await tester.enterText(kgField(0), '65');
      await tester.runAsync(() => WorkoutDraftService().clear());
      await close(tester);
      expect(await tester.runAsync(reloadDraft), isNull);
    });
  });

  // docs/45 — kilit ekranı eylemleri seans ekranında (Codex kuralları):
  // eylem kartın gösterdiği sete bağlı; ± yalnız o setin tek alanı; ✓
  // kartta görünen değeri kaydeder.
  group('kilit ekranı eylemleri', () {
    final shown = <Map<Object?, Object?>>[];
    const channel = WorkoutLiveActivity.channel;

    setUp(() {
      shown.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (c) async {
            if (c.arguments is Map) shown.add(c.arguments as Map);
            return true;
          });
    });

    Future<Object?> act(WidgetTester tester, String action, String key) async {
      const codec = StandardMethodCodec();
      Object? reply;
      await tester.runAsync(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              channel.name,
              codec.encodeMethodCall(
                MethodCall('action', {'action': action, 'setKey': key}),
              ),
              (d) => reply = d == null ? null : codec.decodeEnvelope(d),
            ),
      );
      await tester.pump();
      return reply;
    }

    testWidgets('aynı hareketin iki bloğu eski tamamla komutunu paylaşmaz', (
      tester,
    ) async {
      await seed([(60, 10)]);
      final first = (await db.workoutDao.getRoutineExercises(routineId)).single;
      await (db.update(
        db.routineExercises,
      )).write(const RoutineExercisesCompanion(targetSets: Value(1)));
      await db.workoutDao.addRoutineExercise(
        RoutineExercisesCompanion.insert(
          routineId: routineId,
          exerciseId: first.exercise.id,
          orderIndex: const Value(1),
          targetSets: const Value(1),
          targetRestSec: const Value(0),
        ),
      );
      await open(tester, exerciseCount: 2);
      final key = shown.last['setKey'] as String;
      expect(await act(tester, 'completeSet', key), isTrue);
      expect(await act(tester, 'completeSet', key), isFalse);
      final draft = (await tester.runAsync(reloadDraft))!;
      expect(draft.exercises[0].sets.single.done, isTrue);
      expect(draft.exercises[1].sets.single.done, isFalse);
      await close(tester);
    });

    testWidgets(
      'değer değişince eski kartın ± ve tamamla komutları reddedilir',
      (tester) async {
        await seed([(60, 10)]);
        await open(tester);
        final key = shown.last['setKey'] as String;
        expect(await act(tester, 'stepUp', key), isTrue);
        final currentKey = shown.last['setKey'] as String;
        final weight = (await tester.runAsync(
          reloadDraft,
        ))!.exercises.single.sets.first.weight;
        expect(await act(tester, 'stepUp', key), isFalse);
        expect(await act(tester, 'completeSet', key), isFalse);
        expect(
          (await tester.runAsync(
            reloadDraft,
          ))!.exercises.single.sets.first.weight,
          weight,
        );
        expect(await act(tester, 'completeSet', currentKey), isTrue);
        await close(tester);
      },
    );

    testWidgets(
      'mola komutu tek sürüme bağlıdır; eski komut yeni molaya işlemez',
      (tester) async {
        await seed([(60, 10)]);
        await (db.update(
          db.routineExercises,
        )).write(const RoutineExercisesCompanion(targetRestSec: Value(60)));
        await open(tester);
        expect(
          await act(tester, 'completeSet', shown.last['setKey'] as String),
          isTrue,
        );
        final firstRestKey = shown.last['restKey'] as String;
        expect(firstRestKey, isNotEmpty);
        final nextSetKey = shown.last['setKey'] as String;
        expect(
          await act(tester, 'completeSet', nextSetKey),
          isFalse,
          reason: 'mola sürerken set onaylanmaz',
        );
        expect(await act(tester, 'addRest', firstRestKey), isTrue);
        final extended = (await tester.runAsync(reloadDraft))!.restEndsAtMs;
        expect(await act(tester, 'addRest', firstRestKey), isFalse);
        expect((await tester.runAsync(reloadDraft))!.restEndsAtMs, extended);
        final currentRestKey = shown.last['restKey'] as String;
        expect(await act(tester, 'skipRest', currentRestKey), isTrue);
        expect(
          shown.last['setKey'],
          nextSetKey,
          reason: 'mola, set anahtarını değiştirmez',
        );
        expect(await act(tester, 'completeSet', nextSetKey), isTrue);
        final secondRestKey = shown.last['restKey'] as String;
        expect(secondRestKey, isNot(currentRestKey));
        expect(await act(tester, 'skipRest', currentRestKey), isFalse);
        expect((await tester.runAsync(reloadDraft))!.restEndsAtMs, isNotNull);
        expect(await act(tester, 'skipRest', secondRestKey), isTrue);
        await close(tester);
      },
    );

    testWidgets('kaldırılıp aynı sıraya eklenen set eski komutu kabul etmez', (
      tester,
    ) async {
      await seed([(60, 10)]);
      await open(tester);
      expect(
        await act(tester, 'completeSet', shown.last['setKey'] as String),
        isTrue,
      );
      final removedKey = shown.last['setKey'] as String;
      await tester.tap(find.text('Çıkar'));
      await tester.pump();
      await tester.tap(find.text('Set Ekle'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(shown.last['setKey'], isNot(removedKey));
      expect(await act(tester, 'completeSet', removedKey), isFalse);
      expect(
        (await tester.runAsync(reloadDraft))!.exercises.single.sets.last.done,
        isFalse,
      );
      await close(tester);
    });

    testWidgets('doğal mola bitişi native karttaki sıradaki seti bayatlatmaz', (
      tester,
    ) async {
      await seed([(60, 10)]);
      await WorkoutDraftService().save(
        WorkoutDraft(
          title: 'Push',
          routineId: routineId,
          startedAtMs: DateTime.now().millisecondsSinceEpoch,
          sessionDateMs: DateTime.now().millisecondsSinceEpoch,
          restStartedAtMs: DateTime.now().millisecondsSinceEpoch,
          restEndsAtMs: DateTime.now()
              .add(const Duration(seconds: 1))
              .millisecondsSinceEpoch,
          exercises: [
            DraftExercise(
              exerciseId: (await db.workoutDao.getRoutineExercises(
                routineId,
              )).single.exercise.id,
              restSec: 0,
              previous: null,
              sets: [DraftSet(weight: 60, reps: 10, done: true), DraftSet()],
            ),
          ],
        ),
      );
      await open(tester, resume: true);
      final key = shown.last['setKey'] as String;
      final restKey = shown.last['restKey'] as String;
      // Gerçek saat ilerler; Dart'ın fake timer/yeniden çizimi çalıştırılmaz.
      // Native staleDate yüzeyi kendi başına bu anahtarı gösterebilir.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      expect(await act(tester, 'completeSet', key), isTrue);
      expect(await act(tester, 'skipRest', restKey), isFalse);
      expect(
        (await tester.runAsync(reloadDraft))!.exercises.single.sets.last.done,
        isTrue,
      );
      await close(tester);
    });

    testWidgets('taslak dışarıdan silinince eski kart yeniden yazamaz', (
      tester,
    ) async {
      await seed([(60, 10)]);
      await open(tester);
      final key = shown.last['setKey'] as String;
      await tester.runAsync(() => WorkoutDraftService().clear());
      expect(await act(tester, 'completeSet', key), isFalse);
      expect(await tester.runAsync(reloadDraft), isNull);
      await close(tester);
    });

    testWidgets('clear sonrası bekleyen alan yazımı kartı yeniden yayımlamaz',
        (tester) async {
      await seed([(60, 10)]);
      await open(tester);
      final publications = shown.length;
      await tester.enterText(kgField(0), '65');
      await tester.runAsync(() => WorkoutDraftService().clear());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 600));
      expect(shown, hasLength(publications));
      expect(await tester.runAsync(reloadDraft), isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await close(tester);
    });

    testWidgets('kilo adımı seçimi kartı yeniler ve eski komutu reddeder',
        (tester) async {
      await seed([(60, 10)]);
      await open(tester);
      final key = shown.last['setKey'] as String;
      await tester.tap(find.byTooltip('Kilo adımını değiştir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '5 kg'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      final updatedKey = shown.last['setKey'] as String;
      expect(updatedKey, isNot(key));
      expect(shown.last['stepUpLabel'], '+5 kg');
      expect(await act(tester, 'stepUp', key), isFalse);
      expect(await act(tester, 'stepUp', updatedKey), isTrue);
      expect((await tester.runAsync(reloadDraft))!
          .exercises.single.sets.first.weight, 65);
      await close(tester);
    });

    testWidgets('taslaktan dönüş eski native kartın komutunu kabul etmez',
        (tester) async {
      await seed([(60, 10)]);
      await open(tester);
      final key = shown.last['setKey'] as String;
      await close(tester);
      await open(tester, resume: true);
      expect(shown.last['setKey'], isNot(key));
      expect(await act(tester, 'completeSet', key), isFalse);
      expect(await act(tester, 'completeSet', shown.last['setKey'] as String),
          isTrue);
      await close(tester);
    });

    testWidgets('son seti geri almak eski tamamla komutunu canlandırmaz',
        (tester) async {
      await seed([(60, 10)]);
      await open(tester);
      expect(await act(tester, 'completeSet', shown.last['setKey'] as String),
          isTrue);
      final lastKey = shown.last['setKey'] as String;
      expect(await act(tester, 'completeSet', lastKey), isTrue);
      await tester.tap(find.byKey(const ValueKey('set.complete.1')));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(shown.last['setKey'], isNot(lastKey));
      expect(await act(tester, 'completeSet', lastKey), isFalse);
      expect((await tester.runAsync(reloadDraft))!
          .exercises.single.sets.last.done, isFalse);
      await close(tester);
    });

    testWidgets('bitiriş yazımı sürerken native komut durumu değiştirmez',
        (tester) async {
      await seed([(60, 10)]);
      final blocking = _BlockingSaveDao(db);
      overrideDao = blocking;
      await open(tester);
      expect(await act(tester, 'completeSet', shown.last['setKey'] as String),
          isTrue);
      final key = shown.last['setKey'] as String;
      await tester.tap(find.text('Bitir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('session.finishAnyway')));
      await tester.pump();
      expect(blocking.started.isCompleted, isTrue);
      expect(await act(tester, 'stepUp', key), isFalse);
      expect((await tester.runAsync(reloadDraft))!
          .exercises.single.sets.last.weight, isNull);
      blocking.release.complete();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      // Başarısız kayıt sonrasında kilit çözülür, seans düzeltilebilir kalır.
      expect(await act(tester, 'stepUp', key), isTrue);
      await close(tester);
    });

    testWidgets('ilk native komut yazımı beklerken ikinci komut reddedilir',
        (tester) async {
      await seed([(60, 10)]);
      final paused = _PausedDraftWrites();
      overrideDrafts = paused;
      await open(tester);
      final firstKey = shown.last['setKey'] as String;
      paused.pause = true;

      Future<Object?> send(String key) async {
        const codec = StandardMethodCodec();
        final reply = Completer<Object?>();
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          WorkoutLiveActivity.channel.name,
          codec.encodeMethodCall(MethodCall('action',
              {'action': 'completeSet', 'setKey': key})),
          (data) => reply.complete(data == null ? null : codec.decodeEnvelope(data)),
        );
        return reply.future;
      }

      var firstCompleted = false;
      final first = send(firstKey).then((value) {
        firstCompleted = true;
        return value;
      });
      await tester.pump();
      try {
        expect(paused.started.isCompleted, isTrue);
        final nextKey = shown.last['setKey'] as String;
        expect(nextKey, isNot(firstKey));
        final second = send(nextKey);
        await tester.pump();
        expect(await second, isFalse,
            reason: 'ilk komut hâlâ taslak yazımını bekler');
        expect(firstCompleted, isFalse);
      } finally {
        paused.release.complete();
      }
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(await first, isTrue);
      final draft = (await tester.runAsync(reloadDraft))!;
      expect(draft.exercises.single.sets.first.done, isTrue);
      expect(draft.exercises.single.sets.last.done, isFalse);
      await close(tester);
    });

    testWidgets('bayat set kimliği yok sayılır; ± ve ✓ görünen değerle', (
      tester,
    ) async {
      await seed([(60, 10), (60, 10)]);
      await open(tester);
      final first = shown.last;
      final key = first['setKey'] as String;
      expect(first['canComplete'], isTrue);
      expect(first['stepUpLabel'], startsWith('+'));

      // Gecikmiş/çift dokunuş: başka setin kimliği → hiçbir şey olmaz.
      expect(await act(tester, 'completeSet', 'baska:9'), isFalse);
      var d = await tester.runAsync(reloadDraft);
      expect(d!.exercises.single.sets.where((s) => s.done), isEmpty);

      // + : yalnız bu setin kilosu, öneriden bir adım yukarı.
      expect(await act(tester, 'stepUp', key), isTrue);
      d = await tester.runAsync(reloadDraft);
      final w = d!.exercises.single.sets[0].weight!;
      expect(w, greaterThan(60));
      expect(
        d.exercises.single.sets[1].weight,
        isNull,
        reason: 'sonraki sete dokunulmaz',
      );
      expect(
        shown.last['target'] as String,
        contains(w.toString().replaceAll('.0', '')),
      );

      // ✓ : kartta görünen kilo kaydedilir, sıradaki sete geçilir.
      final updatedKey = shown.last['setKey'] as String;
      expect(await act(tester, 'completeSet', updatedKey), isTrue);
      d = await tester.runAsync(reloadDraft);
      final s0 = d!.exercises.single.sets[0];
      expect((s0.done, s0.weight), (true, w));
      expect(shown.last['setKey'], isNot(key));

      // Aynı (artık bayat) kimlikle ikinci dokunuş 2. seti tamamlamaz.
      expect(await act(tester, 'completeSet', key), isFalse);
      d = await tester.runAsync(reloadDraft);
      expect(d!.exercises.single.sets[1].done, isFalse);
      await close(tester);
    });
  });

  group('sonraki hedef: uygula → geri al', () {
    testWidgets('taslak yeniden yüklenince geri alınmış hali gelir', (
      tester,
    ) async {
      await seed([(15, 10), (15, 10)]); // aralık içinde → +1 tekrar önerisi
      await open(tester);

      await tester.tap(find.text('+1 tekrar'));
      await tester.pump();
      expect(find.text('Uygulandı: her sete +1 tekrar'), findsOneWidget);
      var d = await tester.runAsync(reloadDraft);
      expect(d!.exercises.single.appliedIncrementKg, isNotNull);

      await tester.tap(find.text('Geri al'));
      await tester.pump();
      d = await tester.runAsync(reloadDraft);
      expect(d!.exercises.single.appliedIncrementKg, isNull);

      // Arka plana geçip ekran kapansa da geri alınmış hal korunur.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await close(tester);
      d = await tester.runAsync(reloadDraft);
      expect(d!.exercises.single.appliedIncrementKg, isNull);

      // Taslaktan devam: ekran öneriyi uygulanmamış gösterir, öneriler
      // geçen seansın değerleri (11 değil 10 tekrar).
      await open(tester, resume: true);
      expect(find.text('+1 tekrar'), findsOneWidget);
      expect(find.textContaining('Uygulandı'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('set.complete.0')).first);
      await tester.pump();
      await close(tester);
      d = await tester.runAsync(reloadDraft);
      final first = d!.exercises.single.sets[0];
      expect((first.weight, first.reps, first.done), (15.0, 10, true));
    });

    testWidgets('uygulanmış hal taslaktan devamda korunur', (tester) async {
      await seed([(15, 10), (15, 10)]);
      await open(tester);
      await tester.tap(find.text('+1 tekrar'));
      await tester.pump();
      await close(tester);

      await open(tester, resume: true);
      expect(find.text('Uygulandı: her sete +1 tekrar'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('set.complete.0')).first);
      await tester.pump();
      await close(tester);
      final first = (await tester.runAsync(
        reloadDraft,
      ))!.exercises.single.sets[0];
      expect((first.weight, first.reps), (15.0, 11));
    });
  });

  group('kiloyu artır satırı', () {
    testWidgets('gerekçe, düğme ve uygulanınca öneri', (tester) async {
      await seed([(60, 12), (60, 12)]); // hepsi üst sınırda
      await open(tester);

      // Artış metninde bölünmez boşluk var: "+1.25 kg" satır sonunda
      // "+1.25 / kg" diye ayrılmasın diye (dar ekran cilası).
      const nb = '\u00A0';
      expect(
        find.text(
          'Geçen sefer: 60 kg × 12, 12 — her sette 12 tekrara ulaştın. '
          'Hazırsan +1.25${nb}kg dene.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('+1.25${nb}kg'));
      await tester.pump();
      expect(
        find.text('Uygulandı: her sete +1.25${nb}kg, 8 tekrar'),
        findsOneWidget,
      );
      // Boş alanların ipucu uyarlanmış öneri: 61,25 kg × 8 (yerel ondalık).
      final hints = [
        for (final f in tester.widgetList<TextField>(find.byType(TextField)))
          f.decoration?.hintText,
      ];
      expect(hints.sublist(0, 2), ['61,25', '8']);
      await close(tester);
    });
  });

  // docs/27 F3: canlı süre saati ekranı her saniye yeniden çiziyor; sayaç
  // satırla birlikte yeniden kurulursa (yanlış anahtar) çalışırken sıfırlanır.
  testWidgets('süreli sette sayaç canlı saatin tıklarında sıfırlanmaz', (
    tester,
  ) async {
    final exId = await db.workoutDao.insertCustomExercise(
      ExercisesCompanion.insert(
        name: 'Plank',
        category: 'flexibility',
        muscleGroups: 'core',
        measurementType: const Value('time'),
      ),
    );
    routineId = await db.workoutDao.createRoutine(
      RoutinesCompanion.insert(name: 'Core', createdAt: DateTime(2026, 9, 1)),
    );
    await db.workoutDao.addRoutineExercise(
      RoutineExercisesCompanion.insert(
        routineId: routineId,
        exerciseId: exId,
        targetSets: const Value(1),
        targetRestSec: const Value(0),
      ),
    );
    await tester.pumpWidget(app());
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(find.text('Plank'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('set-timer-start')));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(
      find.byKey(const ValueKey('set-timer-stop')),
      findsOneWidget,
      reason: 'sayaç 3 saat tıkından sonra hâlâ çalışıyor olmalı',
    );
    await close(tester);
  });
}

class _BlockingSaveDao extends WorkoutDao {
  _BlockingSaveDao(super.db);
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<int> insertSessionWithSets(WorkoutSessionsCompanion session,
      List<WorkoutSetsCompanion> Function(int) buildSets) async {
    started.complete();
    await release.future;
    throw StateError('synthetic save failure');
  }
}

class _PausedDraftWrites extends WorkoutDraftService {
  bool pause = false;
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<bool> saveIfCurrent(WorkoutDraft draft, {
    required int expectedClearCount,
    bool Function()? isCurrent,
  }) async {
    if (pause) {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    return super.saveIfCurrent(draft,
        expectedClearCount: expectedClearCount, isCurrent: isCurrent);
  }
}

/// Ses/titreşim yok; ses oynatıcısı test ortamında kurulmaz.
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

/// Bildirim eklentisi test ortamında kurulmaz; mola bildirimi yok sayılır.
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

/// Ekranı uyanık tutma eklentisi test ortamında yok — çağrıları yanıtla.
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
