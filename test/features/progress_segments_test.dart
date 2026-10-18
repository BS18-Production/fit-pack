import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:fit_pack/core/onboarding/first_run_hints.dart';
import 'package:fit_pack/core/router/app_router.dart';
import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/activity/activity_calendar.dart';
import 'package:fit_pack/features/health/step_providers.dart';
import 'package:fit_pack/features/health/step_source.dart';
import 'package:fit_pack/features/insights/weekly_review_screen.dart';
import 'package:fit_pack/features/progress/training_progress_view.dart';
import 'package:fit_pack/features/update/app_version_gate.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:fit_pack/shared/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/design_fixture.dart';
import '../helpers/fake_step_source.dart';
import '../helpers/test_database.dart';

/// İlerleme sekmesi: Antrenman · Vücut · Hafta (docs/56).
void main() {
  late AppDatabase db;

  Future<void> open(
    WidgetTester tester, {
    double width = 393,
    double scale = 1,
    String locale = 'tr',
    String? capture,
  }) async {
    await FirstRunHints.initialize(onboarded: true);
    final gate = DesignFixtureGate(db);
    final update = UpdateGate(AppVersionGate(
        currentBuild: () async => 1, fetchMinimum: () async => null));
    final router = createAppRouter(gate: gate, updateGate: update);
    final boundary = GlobalKey();
    tester.view.physicalSize = Size(width * 2, 1704);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      gate.dispose();
      update.dispose();
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        stepSourceProvider.overrideWithValue(
            FakeStepSource(status: StepPlatformStatus.unavailable)),
      ],
      child: RepaintBoundary(
        key: boundary,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          locale: Locale(locale),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: GlassBackground(child: child!),
          ),
        ),
      ),
    ));
    router.go(AppRoutes.progress);
    await settle(tester);
    final dir = Platform.environment['FITPACK_CAPTURE_DIR'];
    if (capture != null && dir != null) {
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(dir).create(recursive: true);
        await File('$dir/progress-$capture.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
  });
  tearDown(() => db.close());

  testWidgets('ilk açılış Antrenman; Vücut seçilince hatırlanır, FAB yalnız orada',
      (tester) async {
    await seedDesignFixture(db);
    await open(tester, capture: 'training');
    expect(find.byType(TrainingProgressView), findsOneWidget);
    expect(find.text('Ana hareketler'), findsOneWidget);
    expect(find.text('Bench Press'), findsWidgets);
    expect(find.text('Ölçüm Ekle'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('progress.segment.body')));
    await settle(tester);
    expect(find.byType(ActivityCalendar), findsOneWidget);
    expect(find.text('Ölçüm Ekle'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('progress_segment_v1'), 'body');
  });

  testWidgets('kayıtlı seçim Hafta → değerlendirme gömülü açılır',
      (tester) async {
    SharedPreferences.setMockInitialValues({'progress_segment_v1': 'week'});
    await seedDesignFixture(db);
    await open(tester, capture: 'week');
    expect(find.byType(WeeklyReviewView), findsOneWidget);
    expect(find.byType(TrainingProgressView), findsNothing);
  });

  testWidgets('antrenman verisi yoksa ilk açılış Vücut', (tester) async {
    await db.userProfileDao.ensureProfile();
    await open(tester);
    expect(find.byType(ActivityCalendar), findsOneWidget);
    expect(find.byType(TrainingProgressView), findsNothing);
  });

  testWidgets('tek antrenman günü → Antrenman boş durumu', (tester) async {
    SharedPreferences.setMockInitialValues({'progress_segment_v1': 'training'});
    await db.userProfileDao.ensureProfile();
    final ex = await db.workoutDao.insertCustomExercise(ExercisesCompanion.insert(
        name: 'Squat', category: 'compound', muscleGroups: 'legs'));
    await db.workoutDao.insertSessionWithSets(
      WorkoutSessionsCompanion(
          date: Value(DateTime.now()),
          phase: const Value(0),
          workoutType: const Value('Alt')),
      (id) => [
        WorkoutSetsCompanion(
            sessionId: Value(id),
            exerciseId: Value(ex),
            setNumber: const Value(1),
            weightKg: const Value(80),
            reps: const Value(5),
            isComplete: const Value(true)),
      ],
    );
    await open(tester, capture: 'empty');
    expect(find.text('Karşılaştırma için 1 antrenman daha'), findsOneWidget);
    expect(find.text('Antrenmana git'), findsOneWidget);
  });

  for (final seg in ['training', 'body', 'week']) {
    testWidgets('320 · 1,6× yazı: $seg taşmaz', (tester) async {
      SharedPreferences.setMockInitialValues({'progress_segment_v1': seg});
      await seedDesignFixture(db);
      await open(tester, width: 320, scale: 1.6, locale: 'en',
          capture: 'large-$seg');
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(tester.takeException(), isNull);
}
