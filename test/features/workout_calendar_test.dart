import 'package:drift/drift.dart' hide isNull;
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/workout/history_providers.dart';
import 'package:fit_pack/features/workout/history_summary.dart';
import 'package:fit_pack/features/workout/workout_calendar_screen.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// docs/45 §4 — antrenman takvimi. Hata: Antrenman sekmesindeki takvim
/// düğmesi "Geçmiş antrenman ekle" formuydu; kayıtlı gün seçilince boş
/// form açılıyordu. Takvim artık o günün seanslarını listeler.
void main() {
  WorkoutSession session(int id, DateTime date) => WorkoutSession(
        id: id,
        date: date,
        phase: 0,
        workoutType: 'S$id',
        kneeStatus: 'normal',
        isDeload: false,
        uid: 'u$id',
        updatedAt: date,
        syncState: 0,
      );

  HistoryEntry entry(int id, DateTime date) => HistoryEntry(
        session: session(id, date),
        exercises: const [],
        totals: sessionTotals(const []),
        records: 0,
      );

  group('gün filtresi', () {
    final entries = [
      entry(1, DateTime(2026, 10, 4, 23, 50)), // gece yarısına 10 dk
      entry(2, DateTime(2026, 10, 5, 0, 5)), // ertesi gün
      entry(3, DateTime(2026, 10, 5, 18)),
      entry(4, DateTime(2026, 9, 30, 18)),
    ];

    test('gece yarısına yakın seans kendi gününde kalır', () {
      expect(entriesOnDay(entries, DateTime(2026, 10, 4)).map((e) => e.session.id),
          [1]);
      expect(entriesOnDay(entries, DateTime(2026, 10, 5)).map((e) => e.session.id),
          [2, 3]);
      expect(entriesOnDay(entries, DateTime(2026, 10, 6)), isEmpty);
    });

    test('ayın antrenman günleri', () {
      expect(workoutDaysInMonth(entries, DateTime(2026, 10)), {4, 5});
      expect(workoutDaysInMonth(entries, DateTime(2026, 9)), {30});
    });
  });

  group('ekran (gerçek veritabanı)', () {
    late AppDatabase db;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = newTestDatabase();
    });
    tearDown(() => db.close());

    Future<void> seed() async {
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
      for (final (name, date) in [
        ('İtme', DateTime(2026, 10, 3, 18)),
        ('Çekme', DateTime(2026, 10, 3, 20)),
      ]) {
        await db.workoutDao.insertSessionWithSets(
          WorkoutSessionsCompanion(
            date: Value(date),
            phase: const Value(0),
            workoutType: Value(name),
            durationMin: const Value(45),
          ),
          (id) => [
            WorkoutSetsCompanion(
              sessionId: Value(id),
              exerciseId: Value(ex),
              setNumber: const Value(1),
              weightKg: const Value(80),
              reps: const Value(8),
            ),
          ],
        );
      }
    }

    Future<void> pump(WidgetTester tester, DateTime day) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('tr'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: WorkoutCalendarScreen(
              initialDate: day, now: DateTime(2026, 10, 11, 12)),
        ),
      ));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('kayıtlı gün: iki seans da listelenir', (tester) async {
      await tester.runAsync(seed);
      await pump(tester, DateTime(2026, 10, 3));
      expect(tester.takeException(), isNull);
      expect(find.text('İtme'), findsOneWidget);
      expect(find.text('Çekme'), findsOneWidget);
      expect(find.byKey(const ValueKey('wcal.empty')), findsNothing);
      expect(find.text('Bu ay 1 antrenman günü'), findsOneWidget);
    });

    testWidgets('kayıtsız gün: boş durum + o güne ekleme', (tester) async {
      await tester.runAsync(seed);
      await pump(tester, DateTime(2026, 10, 4));
      expect(find.byKey(const ValueKey('wcal.empty')), findsOneWidget);
      expect(find.text('Bu güne antrenman ekle'), findsOneWidget);
      expect(find.text('İtme'), findsNothing);
    });

    testWidgets('tarih değişince liste güncellenir', (tester) async {
      await tester.runAsync(seed);
      await pump(tester, DateTime(2026, 10, 4));
      expect(find.byKey(const ValueKey('wcal.empty')), findsOneWidget);
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(find.text('İtme'), findsOneWidget);
      expect(find.byKey(const ValueKey('wcal.empty')), findsNothing);
    });
  });
}
