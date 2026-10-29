import 'dart:async';

import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/sync_meta_dao.dart';
import 'package:fit_pack/features/nutrition/nutrition_entry_scope.dart';
import 'package:fit_pack/features/sync/sync_ownership.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  const userA = 'nutrition-user-a';
  const userB = 'nutrition-user-b';
  final day = DateTime(2026, 10, 28);
  late AppDatabase db;
  late int foodId;
  String? session;

  setUp(() async {
    db = newTestDatabase();
    session = userA;
    foodId = await db.nutritionDao.insertFood(
      FoodsCompanion.insert(
        name: 'Test yoğurt',
        kcalPer100g: 65,
        proteinPer100g: 4,
        carbPer100g: 5,
        fatPer100g: 3,
      ),
    );
  });

  tearDown(() => db.close());

  NutritionEntryScope scope() =>
      NutritionEntryScope(SyncOwnership(db, sessionUserId: () => session));

  Future<void> setOwner(String user) =>
      db.syncMetaDao.write(SyncMetaDao.keyLastUser, user);

  Future<int> addLog() => db.nutritionDao.insertFoodLog(
    FoodLogsCompanion.insert(
      date: day,
      mealType: 'lunch',
      foodId: foodId,
      grams: 150,
      computedKcal: 97.5,
      computedProtein: 6,
      computedCarb: 7.5,
      computedFat: 4.5,
    ),
  );

  test('aynı hesapta kayıt günü, miktarı ve makroları korunur', () async {
    await setOwner(userA);

    final id = await scope().run(addLog);

    final log = (await db.nutritionDao.getLogsForDate(day)).single;
    expect(log.id, id);
    expect(log.date, day);
    expect(log.mealType, 'lunch');
    expect(log.foodId, foodId);
    expect(log.grams, 150);
    expect(log.computedKcal, 97.5);
    expect(log.computedProtein, 6);
    expect(log.computedCarb, 7.5);
    expect(log.computedFat, 4.5);
  });

  test('oturum ve yerel sahip yokken sentetik kayıt eklenebilir', () async {
    session = null;

    final id = await scope().run(addLog);

    expect((await db.nutritionDao.getLogsForDate(day)).single.id, id);
    expect(await db.syncMetaDao.read(SyncMetaDao.keyLastUser), isNull);
  });

  test('çıkış yapılmış oturum sahipli veriye kayıt ekleyemez', () async {
    await setOwner(userA);
    session = null;
    var called = false;

    await expectLater(
      scope().run(() async {
        called = true;
        return addLog();
      }),
      throwsA(isA<NutritionEntryAccountChanged>()),
    );

    expect(called, isFalse);
    expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
  });

  test('oturum ile yerel veri sahibi farklıysa yazma başlamaz', () async {
    await setOwner(userA);
    session = userB;
    var called = false;

    await expectLater(
      scope().run(() async {
        called = true;
        return addLog();
      }),
      throwsA(isA<SyncOwnershipLost>()),
    );

    expect(called, isFalse);
    expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
    expect(await db.syncMetaDao.read(SyncMetaDao.keyLastUser), userA);
  });

  test('giriş var ama yerel sahip henüz atanmadıysa yazma başlamaz', () async {
    await expectLater(scope().run(addLog), throwsA(isA<SyncOwnershipLost>()));

    expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
  });

  test('hesap değişimi tamamlanmadan mevcut sahip de yazamaz', () async {
    await setOwner(userA);
    await db.syncMetaDao.write(SyncMetaDao.keySwitchInProgress, userB);

    await expectLater(scope().run(addLog), throwsA(isA<SyncOwnershipLost>()));

    expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
    expect(await db.syncMetaDao.read(SyncMetaDao.keySwitchInProgress), userB);
  });

  test('sahipsiz veride de yarım hesap değişimi yazmayı engeller', () async {
    session = null;
    await db.syncMetaDao.write(SyncMetaDao.keySwitchInProgress, userB);

    await expectLater(
      scope().run(addLog),
      throwsA(isA<NutritionEntryAccountChanged>()),
    );

    expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
  });

  test('panel açıldıktan sonra değişen hesap eski taslağı ekleyemez', () async {
    await setOwner(userA);
    final entry = scope();
    session = userB;
    await setOwner(userB);
    var called = false;

    await expectLater(
      entry.run(() async {
        called = true;
        return addLog();
      }),
      throwsA(isA<NutritionEntryAccountChanged>()),
    );

    expect(called, isFalse);
    expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
    expect(await db.syncMetaDao.read(SyncMetaDao.keyLastUser), userB);
  });

  test(
    'ekleme await sırasında hesap değişirse yazılan kayıt geri alınır',
    () async {
      await setOwner(userA);
      final entry = scope();
      final inserted = Completer<void>();
      final finishWrite = Completer<void>();

      final check = expectLater(
        entry.run(() async {
          final id = await addLog();
          inserted.complete();
          await finishWrite.future;
          return id;
        }),
        throwsA(isA<NutritionEntryAccountChanged>()),
      );
      await inserted.future;
      session = userB;
      finishWrite.complete();
      await check;

      expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
      expect(await db.nutritionDao.getFoodById(foodId), isNotNull);
      expect(await db.syncMetaDao.read(SyncMetaDao.keyLastUser), userA);
    },
  );

  test('hesap değişince eski panelin geri al işlemi kayıt silemez', () async {
    await setOwner(userA);
    final entry = scope();
    final id = await entry.run(addLog);
    session = userB;
    await setOwner(userB);
    var called = false;

    await expectLater(
      entry.run(() async {
        called = true;
        await db.nutritionDao.deleteFoodLogs([id]);
      }),
      throwsA(isA<NutritionEntryAccountChanged>()),
    );

    expect(called, isFalse);
    expect((await db.nutritionDao.getLogsForDate(day)).single.id, id);
  });

  test(
    'geri al await sırasında hesap değişirse silinen kayıt korunur',
    () async {
      await setOwner(userA);
      final entry = scope();
      final id = await entry.run(addLog);
      final before = (await db.nutritionDao.getLogsForDate(day)).single;
      final deleted = Completer<void>();
      final finishUndo = Completer<void>();

      final check = expectLater(
        entry.run(() async {
          await db.nutritionDao.deleteFoodLogs([id]);
          deleted.complete();
          await finishUndo.future;
        }),
        throwsA(isA<NutritionEntryAccountChanged>()),
      );
      await deleted.future;
      session = userB;
      finishUndo.complete();
      await check;

      expect((await db.nutritionDao.getLogsForDate(day)).single, before);
    },
  );

  test('A → B → A dönüşü eski panelin kapsamını yeniden açmaz', () async {
    await setOwner(userA);
    final entry = scope();
    session = userB;
    entry.observeAccount(session);
    await setOwner(userB);
    session = userA;
    entry.observeAccount(session);
    await setOwner(userA);
    var called = false;

    expect(entry.isCurrent, isFalse);
    await expectLater(
      entry.run(() async {
        called = true;
        return addLog();
      }),
      throwsA(isA<NutritionEntryAccountChanged>()),
    );

    expect(called, isFalse);
    expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
    expect(await db.syncMetaDao.read(SyncMetaDao.keyLastUser), userA);
  });

  test('ekleme beklerken A → B → A olursa kayıt geri alınır', () async {
    await setOwner(userA);
    final entry = scope();
    final inserted = Completer<void>();
    final finishWrite = Completer<void>();

    final check = expectLater(
      entry.run(() async {
        final id = await addLog();
        inserted.complete();
        await finishWrite.future;
        return id;
      }),
      throwsA(isA<NutritionEntryAccountChanged>()),
    );
    await inserted.future;
    session = userB;
    entry.observeAccount(session);
    session = userA;
    entry.observeAccount(session);
    finishWrite.complete();
    await check;

    expect(entry.isCurrent, isFalse);
    expect(await db.nutritionDao.getLogsForDate(day), isEmpty);
    expect(await db.nutritionDao.getFoodById(foodId), isNotNull);
  });

  test('aynı hesaba ait token yenileme olayları kaydı engellemez', () async {
    await setOwner(userA);
    final entry = scope();
    entry.observeAccount(session);
    final inserted = Completer<void>();
    final finishWrite = Completer<void>();

    final write = entry.run(() async {
      final id = await addLog();
      inserted.complete();
      await finishWrite.future;
      return id;
    });
    await inserted.future;
    entry.observeAccount(session);
    entry.observeAccount(userA);
    finishWrite.complete();
    final id = await write;

    expect(entry.isCurrent, isTrue);
    expect((await db.nutritionDao.getLogsForDate(day)).single.id, id);
  });
}
