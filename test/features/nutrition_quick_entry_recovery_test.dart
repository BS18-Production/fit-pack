import 'dart:async';

import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/nutrition_dao.dart';
import 'package:fit_pack/data/database/daos/sync_meta_dao.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/nutrition/add_food_sheet.dart';
import 'package:fit_pack/features/cloud/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_pack/features/nutrition/nutrition_providers.dart';
import 'package:fit_pack/features/sync/sync_ownership.dart';
import 'package:fit_pack/features/sync/sync_providers.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

class _ControlledUndoDao extends NutritionDao {
  _ControlledUndoDao(super.db);
  Completer<void>? release;
  bool fail = false;
  int calls = 0;

  @override
  Future<int> deleteFoodLogs(List<int> ids) async {
    calls++;
    await release?.future;
    if (fail) throw StateError('synthetic undo failure');
    return super.deleteFoodLogs(ids);
  }
}

void main() {
  late AppDatabase db;
  late int foodId;
  late ProviderContainer container;
  final day = DateTime(2026, 10, 28);

  setUp(() async {
    db = newTestDatabase();
    foodId = await db.nutritionDao.insertFood(
      FoodsCompanion.insert(
        name: 'Test yogurt',
        kcalPer100g: 65,
        proteinPer100g: 4,
        carbPer100g: 5,
        fatPer100g: 3,
      ),
    );
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 8; i++) {
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.takeException(), isNull);
  }

  Future<void> open(
    WidgetTester t, {
    List<Override> overrides = const [],
  }) async {
    t.view.physicalSize = const Size(800, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => day),
          ...overrides,
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                container = ProviderScope.containerOf(context);
                return TextButton(
                  onPressed: () => showAddFoodSheet(context, mealType: 'lunch'),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await settle(t);
  }

  Future<void> addAmount(WidgetTester t, String amount) async {
    await t.tap(find.text('Test yogurt').first);
    await settle(t);
    await t.enterText(find.byType(TextField).last, amount);
    await t.tap(
      find.ancestor(
        of: find.textContaining('Add to lunch ·'),
        matching: find.byType(FilledButton),
      ),
    );
    await settle(t);
  }

  Finder quickAdd() => find.byWidgetPredicate(
    (w) => w is IconButton && (w.tooltip?.startsWith('Add ') ?? false),
  );

  testWidgets('Back returns to search before closing; cancel writes nothing', (
    t,
  ) async {
    await open(t);
    await t.enterText(find.byType(TextField), 'yog');
    await t.tap(find.text('Test yogurt'));
    await settle(t);
    await t.enterText(find.byType(TextField).last, '250');
    await t.binding.handlePopRoute();
    await settle(t);
    expect(find.byType(AddFoodSheet), findsOneWidget);
    expect(find.byType(FoodAmountPanel), findsNothing);
    expect(t.widget<TextField>(find.byType(TextField)).controller!.text, 'yog');
    expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
    await t.binding.handlePopRoute();
    await settle(t);
    expect(find.byType(AddFoodSheet), findsNothing);
  });

  testWidgets(
    'Undo restores previous quick portion and preserves prior records',
    (t) async {
      final previousDay = DateTime(2026, 10, 27);
      await db.nutritionDao.insertFoodLog(
        FoodLogsCompanion.insert(
          date: previousDay,
          mealType: 'breakfast',
          foodId: foodId,
          grams: 120,
          computedKcal: 78,
          computedProtein: 4.8,
          computedCarb: 6,
          computedFat: 3.6,
        ),
      );
      await open(t);
      await addAmount(t, '200');
      expect((await db.nutritionDao.getLogsForDate(day)).single.grams, 200);
      await t.tap(find.text('Undo'));
      await settle(t);
      expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
      await t.tap(quickAdd().first);
      await settle(t);
      expect((await db.nutritionDao.getLogsForDate(day)).single.grams, 120);
      expect(
        (await db.nutritionDao.getLogsForDate(previousDay)).single.grams,
        120,
      );
    },
  );

  testWidgets('Pending undo blocks duplicate undo, adding and closing', (
    t,
  ) async {
    final dao = _ControlledUndoDao(db);
    await open(t, overrides: [nutritionDaoProvider.overrideWithValue(dao)]);
    await addAmount(t, '200');
    final undo = t
        .widget<TextButton>(find.widgetWithText(TextButton, 'Undo'))
        .onPressed!;
    final add = t.widget<IconButton>(quickAdd().first).onPressed!;
    dao.release = Completer<void>();
    undo();
    undo();
    add();
    await settle(t);
    expect(dao.calls, 1);
    await t.binding.handlePopRoute();
    await settle(t);
    expect(find.byType(AddFoodSheet), findsOneWidget);
    // Use a screen gesture: the content intentionally absorbs pointer hits.
    await t.dragFrom(t.getCenter(find.text('Add Food')), const Offset(0, 1200));
    await settle(t);
    expect(find.byType(AddFoodSheet), findsOneWidget);
    dao.release!.complete();
    await settle(t);
    expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('More than eight recent foods keep exact amounts after undo', (
    t,
  ) async {
    for (var i = 0; i < 8; i++) {
      await db.nutritionDao.insertFood(
        FoodsCompanion.insert(
          name: 'Extra $i',
          kcalPer100g: 100,
          proteinPer100g: 10,
          carbPer100g: 20,
          fatPer100g: 5,
        ),
      );
    }
    await open(t);
    await t.enterText(find.byType(TextField), 'yog');
    await addAmount(t, '200');
    for (var i = 0; i < 8; i++) {
      await t.enterText(find.byType(TextField), 'Extra $i');
      await t.pump();
      await t.tap(quickAdd().first);
      await settle(t);
    }
    await t.tap(find.text('Undo'));
    await settle(t);
    await t.enterText(find.byType(TextField), 'yog');
    await t.pump();
    await t.tap(quickAdd().first);
    await settle(t);
    final logs = await db.nutritionDao.getLogsForDate(day);
    expect(logs.where((log) => log.foodId == foodId).map((log) => log.grams), [
      200,
      200,
    ]);
  });

  testWidgets('Decrease cannot increase a subgram amount', (t) async {
    await open(t);
    await t.tap(find.text('Test yogurt'));
    await settle(t);
    await t.enterText(find.byType(TextField).last, '0.5');
    await t.pump();
    final decrease = find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Decrease amount');
    expect(t.widget<IconButton>(decrease).onPressed, isNull);
    await t.tap(decrease);
    await t.tap(
      find.ancestor(
        of: find.textContaining('Add to lunch ·'),
        matching: find.byType(FilledButton),
      ),
    );
    await settle(t);
    expect((await db.nutritionDao.getLogsForDate(day)).single.grams, 0.5);
  });

  testWidgets('Failed undo retains the banner and can be retried', (t) async {
    final dao = _ControlledUndoDao(db)..fail = true;
    await open(t, overrides: [nutritionDaoProvider.overrideWithValue(dao)]);
    await addAmount(t, '200');
    await t.tap(find.text('Undo'));
    await settle(t);
    expect((await db.nutritionDao.getLogsForDate(day)).single.grams, 200);
    expect(find.text('Undo'), findsOneWidget);
    dao.fail = false;
    await t.tap(find.text('Undo'));
    await settle(t);
    expect(dao.calls, 2);
    expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
  });

  testWidgets('An open sheet keeps its original target date', (t) async {
    await open(t);
    container.read(selectedDateProvider.notifier).state = DateTime(
      2026,
      10,
      29,
    );
    await addAmount(t, '150');
    final log = (await db.nutritionDao.getLogsForDate(day)).single;
    expect(log.mealType, 'lunch');
    expect(log.grams, 150);
    expect(
      await db.nutritionDao.getLogsForDate(DateTime(2026, 10, 29)),
      isEmpty,
    );
  });

  for (final amount in ['0.5', '0,5']) {
    testWidgets('Fractional grams $amount retain exact amount and macros', (
      t,
    ) async {
      await open(t);
      await addAmount(t, amount);
      final log = (await db.nutritionDao.getLogsForDate(day)).single;
      expect(log.grams, 0.5);
      expect(log.computedKcal, closeTo(0.325, 0.000001));
      expect(log.computedProtein, 0.02);
      expect(log.computedCarb, 0.025);
      expect(log.computedFat, 0.015);
    });
  }

  testWidgets('A to B to A permanently invalidates an open sheet and Undo', (
    t,
  ) async {
    var user = 'account-a';
    final events = StreamController<AuthState>();
    addTearDown(events.close);
    final meta = SyncMetaDao(db);
    await meta.write(SyncMetaDao.keyLastUser, user);
    await open(
      t,
      overrides: [
        syncOwnershipProvider.overrideWithValue(
          SyncOwnership(db, sessionUserId: () => user),
        ),
        authStateProvider.overrideWith((ref) => events.stream),
      ],
    );
    await addAmount(t, '150');
    final undo = t
        .widget<TextButton>(find.widgetWithText(TextButton, 'Undo'))
        .onPressed!;
    final add = t.widget<IconButton>(quickAdd().first).onPressed!;
    void emit(String id) => events.add(
      AuthState(
        AuthChangeEvent.signedIn,
        Session(
          accessToken: 'synthetic-test-token',
          tokenType: 'bearer',
          user: User(
            id: id,
            appMetadata: const {},
            userMetadata: const {},
            aud: 'authenticated',
            createdAt: '2026-10-29T00:00:00Z',
          ),
        ),
      ),
    );
    // The getter is already back to A when the queued B event is delivered.
    user = 'account-b';
    emit(user);
    user = 'account-a';
    emit(user);
    await settle(t);
    expect(find.text("Couldn't verify account"), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
    undo();
    add();
    await settle(t);
    final logs = await db.nutritionDao.getLogsForDate(day);
    expect(logs, hasLength(1));
    expect(logs.single.grams, 150);
    await t.binding.handlePopRoute();
    await settle(t);
    expect(find.byType(AddFoodSheet), findsNothing);
  });

  testWidgets('Account change blocks stale add and undo', (t) async {
    var user = 'account-a';
    final meta = SyncMetaDao(db);
    await meta.write(SyncMetaDao.keyLastUser, user);
    await open(
      t,
      overrides: [
        syncOwnershipProvider.overrideWithValue(
          SyncOwnership(db, sessionUserId: () => user),
        ),
      ],
    );
    await addAmount(t, '150');
    final original = (await db.nutritionDao.getLogsForDate(day)).single;
    final staleAdd = t.widget<IconButton>(quickAdd().first).onPressed!;
    user = 'account-b';
    await meta.write(SyncMetaDao.keyLastUser, user);
    await t.tap(find.text('Undo'));
    await settle(t);
    expect((await db.nutritionDao.getLogsForDate(day)).single.id, original.id);
    staleAdd();
    await settle(t);
    expect((await db.nutritionDao.getLogsForDate(day)).single.id, original.id);
  });
}
