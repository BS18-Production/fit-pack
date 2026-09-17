import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:fit_pack/core/feedback/feedback_service.dart';
import 'package:fit_pack/core/notifications/notification_service.dart';
import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
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

  Future<void> open(WidgetTester tester, {bool resume = false}) async {
    await tester.pumpWidget(app(resume: resume));
    // Yükleme DB'den okur; gerçek G/Ç için runAsync, sonra çizim.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(find.text('Bench Press'), findsOneWidget);
  }

  /// Ekranı kapatır (dispose) — canlı süre sayacı da durur.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  Finder kgField(int set) => find.byType(TextField).at(set * 3);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
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
      await tester.tap(find.byIcon(Icons.check_rounded).first);
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
      await tester.tap(find.byIcon(Icons.check_rounded).first);
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

      expect(
        find.text(
          'Geçen sefer: 60 kg × 12, 12 — her sette 12 tekrara ulaştın. '
          'Hazırsan +1.25 kg dene.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('+1.25 kg'));
      await tester.pump();
      expect(
        find.text('Uygulandı: her sete +1.25 kg, 8 tekrar'),
        findsOneWidget,
      );
      // Boş alanların ipucu uyarlanmış öneri: 61.25 kg × 8.
      final hints = [
        for (final f in tester.widgetList<TextField>(find.byType(TextField)))
          f.decoration?.hintText,
      ];
      expect(hints.sublist(0, 2), ['61.25', '8']);
      await close(tester);
    });
  });
}

/// Ses/titreşim yok; ses oynatıcısı test ortamında kurulmaz.
class _SilentFeedback extends FeedbackService {
  @override
  void warmUp() {}

  @override
  void restCue(RestCue cue, {required bool sound}) {}

  @override
  void setDone() {}

  @override
  void record() {}
}

/// Bildirim eklentisi test ortamında kurulmaz; mola bildirimi yok sayılır.
class _NoNotifications extends NotificationService {
  @override
  Future<void> scheduleRestDone({
    required Duration after,
    required String title,
    required String body,
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
