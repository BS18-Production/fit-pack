import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/calendar/calendar_screen.dart';
import 'package:fit_pack/features/calendar/week_strip.dart';
import 'package:fit_pack/features/home/home_screen.dart';
import 'package:fit_pack/features/workout/workout_draft.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_database.dart';

/// Ana sayfa haftalık şeridi + bugünün eylemi (docs/24 §2) — gerçek
/// bellek-içi veritabanı, gerçek sağlayıcılar.
void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
  });
  tearDown(() => db.close());

  Future<void> ac(WidgetTester tester, Widget home,
      {List<Override> overrides = const []}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), ...overrides],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: AppColors.lightScheme,
          extensions: [AppColors.lightSemantic],
        ),
        locale: const Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: home),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  // Sabit "şimdi": 2026-09-23 Çarşamba; hafta Pzt 21 → Paz 27.
  final now = DateTime(2026, 9, 23, 10);

  Future<void> seans(DateTime date, String name) =>
      db.into(db.workoutSessions).insert(WorkoutSessionsCompanion(
            date: Value(date),
            phase: const Value(0),
            workoutType: Value(name),
          ));

  testWidgets('geçmiş haftaya git → "Bugüne dön" görünür, geri gelir',
      (tester) async {
    await ac(tester, WeekStrip(now: now));

    expect(find.text('21–27 Eylül'), findsOneWidget);
    expect(find.text('Bugüne dön'), findsNothing);
    final ileri = find.byKey(const ValueKey('weekStrip.next'));
    expect(tester.widget<IconButton>(ileri).onPressed, isNull,
        reason: 'gelecek haftaya gidilmez');

    await tester.tap(find.byKey(const ValueKey('weekStrip.prev')));
    await tester.pump();
    expect(find.text('14–20 Eylül'), findsOneWidget);
    expect(find.text('Bugüne dön'), findsOneWidget);
    expect(tester.widget<IconButton>(ileri).onPressed, isNotNull);

    await tester.tap(find.text('Bugüne dön'));
    await tester.pump();
    expect(find.text('21–27 Eylül'), findsOneWidget);
    expect(find.text('Bugüne dön'), findsNothing);
  });

  testWidgets('ay sınırını geçen hafta iki ayı birlikte yazar', (tester) async {
    await ac(tester, WeekStrip(now: DateTime(2026, 10, 1)));
    expect(find.text('28 Eyl – 4 Eki'), findsOneWidget);
  });

  testWidgets('güne dokun → o günün kayıtları; gelecek gün açılmaz',
      (tester) async {
    await seans(DateTime(2026, 9, 21, 18), 'Push day');
    await ac(tester, WeekStrip(now: now));

    await tester.tap(find.text('25'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing,
        reason: 'gelecek gün dokunulmaz');

    await tester.tap(find.text('21'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Push day'), findsOneWidget);
  });

  testWidgets('kayıtsız geçmiş gün: "kayıt yok" der, başarısız demez',
      (tester) async {
    await ac(tester, WeekStrip(now: now));
    await tester.tap(find.text('22'));
    await tester.pumpAndSettle();
    expect(find.text('Bu gün için kayıt yok.'), findsOneWidget);
  });

  testWidgets('geçmiş haftaya gitmek bugünün eylemini DEĞİŞTİRMEZ',
      (tester) async {
    // Bugüne planlı rutin (Ana Sayfa gerçek saati kullanır).
    await db.into(db.routines).insert(RoutinesCompanion.insert(
          name: 'Üst Vücut A',
          createdAt: DateTime.now(),
          scheduledWeekday: Value(DateTime.now().weekday),
        ));
    await db.userProfileDao.ensureProfile();
    await ac(tester, const HomeScreen());

    expect(find.text('BUGÜNÜN PLANI'), findsOneWidget);
    expect(find.text('Üst Vücut A'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('weekStrip.prev')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('weekStrip.prev')));
    await tester.pump();

    expect(find.text('Bugüne dön'), findsOneWidget);
    // Enerji kartı önde; eylem yeni yerleşimde aşağı kaydırılarak görülür.
    await tester.scrollUntilVisible(find.text('Üst Vücut A'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('BUGÜNÜN PLANI'), findsOneWidget,
        reason: 'eylem kartı yalnız bugüne bakar');
    expect(find.text('Üst Vücut A'), findsOneWidget);
  });

  testWidgets('devam eden seans varken eylem "Seansa dön" olur',
      (tester) async {
    await db.into(db.routines).insert(RoutinesCompanion.insert(
          name: 'Üst Vücut A',
          createdAt: DateTime.now(),
          scheduledWeekday: Value(DateTime.now().weekday),
        ));
    await db.userProfileDao.ensureProfile();
    final draft = WorkoutDraft(
      title: 'Bacak günü',
      routineId: null,
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
      sessionDateMs: DateTime.now().millisecondsSinceEpoch,
      exercises: [
        DraftExercise(
            exerciseId: 1,
            restSec: 90,
            previous: null,
            sets: [DraftSet(weight: 60, reps: 8, done: true)]),
      ],
    );
    await ac(tester, const HomeScreen(), overrides: [
      activeDraftProvider.overrideWith((ref) async => draft),
    ]);

    expect(find.text('Seansa dön'), findsOneWidget);
    expect(find.text('Bacak günü'), findsOneWidget);
    expect(find.text('BUGÜNÜN PLANI'), findsNothing,
        reason: 'yeni antrenman başlatma yarışmaz');
  });

  testWidgets('hiç kayıt yok: ritim kartı başlatma metni + son 30 gün 0',
      (tester) async {
    await db.userProfileDao.ensureProfile();
    await ac(tester, const HomeScreen());

    await tester.scrollUntilVisible(find.text('Ritmini başlat'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Ritmini başlat'), findsOneWidget);
    expect(
        find.text(
            'Haftalık hedef: 1 antrenman · dinlenme günleri seriyi bozmaz'),
        findsOneWidget);
    expect(find.text('SON 30 GÜN'), findsOneWidget);
  });

  testWidgets('dinlenme günü: dinlenme kartı + sıradaki rutin',
      (tester) async {
    // Rutin YARINA planlı → bugün dinlenme.
    final yarin = DateTime.now().weekday % 7 + 1;
    await db.into(db.routines).insert(RoutinesCompanion.insert(
          name: 'Alt Vücut',
          createdAt: DateTime.now(),
          scheduledWeekday: Value(yarin),
        ));
    await db.userProfileDao.ensureProfile();
    await ac(tester, const HomeScreen());

    expect(find.text('Bugün dinlenme günü'), findsOneWidget);
    expect(find.text('Sıradaki: Alt Vücut'), findsOneWidget);
    expect(find.text('BUGÜNÜN PLANI'), findsNothing);
  });
  // Küçük ekran + büyük yazı: en dar yaygın telefon (320 pt) ve %130 yazı
  // boyutunda hiçbir satır taşmamalı (taşma testte hata olarak düşer).
  Future<void> dar(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: AppColors.lightScheme,
          extensions: [AppColors.lightSemantic],
        ),
        locale: const Locale('tr'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(body: home),
      ),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('dar ekran + büyük yazı: ana sayfa taşmaz', (tester) async {
    await db.into(db.routines).insert(RoutinesCompanion.insert(
          name: 'Üst Vücut A — Göğüs, Omuz ve Kol Günü',
          createdAt: DateTime.now(),
          scheduledWeekday: Value(DateTime.now().weekday),
        ));
    await seans(DateTime.now(), 'Üst Vücut A');
    await db.userProfileDao.ensureProfile();
    await dar(tester, const HomeScreen());
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('BUGÜNÜN PLANI'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
    expect(find.text('BUGÜNÜN PLANI'), findsOneWidget);
  });

  testWidgets('dar ekran + büyük yazı: ay görünümü taşmaz', (tester) async {
    await seans(DateTime(2026, 9, 16, 12), 'Push day');
    await seans(DateTime(2026, 9, 16, 20), 'Pull day');
    await dar(
        tester,
        CalendarScreen(
            now: now, initialDate: DateTime(2026, 9, 16)));
    expect(tester.takeException(), isNull);
    // Dar ekranda kayıtlar görünür alanın altında: listeyi oraya kaydır.
    await tester.scrollUntilVisible(find.textContaining(' +1'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
    expect(find.textContaining(' +1'), findsOneWidget,
        reason: 'iki seanslı gün adı +N ile yazılmalı');
  });
}
