import 'package:drift/drift.dart' hide isNull;
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/workout/workout_session_detail_screen.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// docs/31 — seans detayı: set RPE'si, rekor kupası, geçen sefere göre fark.
void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
  });
  tearDown(() => db.close());

  Future<int> seans(DateTime date, int ex, List<(double, int, double?)> sets) =>
      db.workoutDao.insertSessionWithSets(
        WorkoutSessionsCompanion(
          date: Value(date),
          phase: const Value(0),
          workoutType: const Value('Push'),
          durationMin: const Value(40),
        ),
        (id) => [
          for (var i = 0; i < sets.length; i++)
            WorkoutSetsCompanion(
              sessionId: Value(id),
              exerciseId: Value(ex),
              setNumber: Value(i + 1),
              weightKg: Value(sets[i].$1),
              reps: Value(sets[i].$2),
              rpe: Value(sets[i].$3),
            ),
        ],
      );

  testWidgets('RPE rozeti, rekor kupası ve geçen sefere göre +5 kg',
      (tester) async {
    late int id;
    await tester.runAsync(() async {
      await db.workoutDao.insertExercise(const ExercisesCompanion(
        name: Value('Bench Press'),
        category: Value('compound'),
        muscleGroups: Value('["chest"]'),
        primaryMuscle: Value('chest'),
        equipment: Value('barbell'),
        measurementType: Value('weight_reps'),
      ));
      final ex = (await db.workoutDao.getAllExercises())
          .firstWhere((e) => e.name == 'Bench Press')
          .id;
      await seans(DateTime(2026, 10, 1, 18), ex, [(75, 8, null), (75, 8, null)]);
      id = await seans(DateTime(2026, 10, 4, 18), ex, [(80, 8, 8), (80, 7, 9.5)]);
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: WorkoutSessionDetailScreen(sessionId: id),
      ),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
    expect(find.text('RPE 8'), findsOneWidget);
    expect(find.text('RPE 9.5'), findsOneWidget);
    expect(find.text('Ort. RPE'), findsOneWidget);
    expect(find.textContaining('Geçen sefere göre: +5'), findsOneWidget);
    // 80×8 önceki en iyiyi (75×8) aşar → rekor kartı + setin yanında kupa.
    expect(find.byIcon(Icons.emoji_events_rounded), findsWidgets);
    expect(find.text('Chest · 2 set'), findsOneWidget); // kas adı uygulama genelinde İngilizce
  });
}
