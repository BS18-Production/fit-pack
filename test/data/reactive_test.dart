import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/reactive.dart';
import 'package:flutter_test/flutter_test.dart';

/// `watchTables` önce abone olur, sonra okur (CR-008): ilk okuma sürerken
/// gelen yazma kaçmaz.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() => db.close());

  Future<int> count() async {
    final r = await db
        .customSelect('SELECT COUNT(*) c FROM routines')
        .getSingle();
    return r.read<int>('c');
  }

  /// Drift'e tablo değişikliğini bildiren yazma (DAO yazması gibi).
  Future<void> addRoutine(String name) => db.customInsert(
        "INSERT INTO routines (name, created_at) VALUES ('$name', 1700000000)",
        updates: {db.routines},
      );

  Future<void> settle() => pumpEventQueue(times: 50);

  test('ilk okuma sürerken gelen yazma kaçmaz', () async {
    final gate = Completer<void>();
    var calls = 0;
    Future<int> read() async {
      calls++;
      final n = await count();
      if (calls == 1) await gate.future; // eski anlık görüntüyle bekler
      return n;
    }

    final values = <int>[];
    final sub = watchTables(db, [db.routines], read).listen(values.add);
    await settle();

    await addRoutine('Araya giren'); // ilk okuma henüz yayınlanmadı
    gate.complete();
    await settle();

    expect(values, [0, 1], reason: 'yazma yeniden okumayı tetiklemeli');
    await sub.cancel();
  });

  test('okuma sürerken gelen birden çok yazma tek okumada birleşir', () async {
    var gate = Completer<void>();
    var calls = 0;
    Future<int> read() async {
      calls++;
      final n = await count();
      await gate.future;
      return n;
    }

    final values = <int>[];
    final sub = watchTables(db, [db.routines], read).listen(values.add);
    await settle();

    await addRoutine('a');
    await addRoutine('b');
    await addRoutine('c');
    final first = gate;
    gate = Completer<void>()..complete();
    first.complete();
    await settle();

    expect(calls, 2, reason: 'üç yazma → tek yeniden okuma');
    expect(values, [0, 3]);
    await sub.cancel();
  });

  test('iptalden sonra okuma ve yayın yok', () async {
    var calls = 0;
    final values = <int>[];
    final sub = watchTables(db, [db.routines], () async {
      calls++;
      return count();
    }).listen(values.add);
    await settle();
    expect(values, [0]);

    await sub.cancel();
    await addRoutine('iptalden sonra');
    await settle();

    expect(calls, 1);
  });

  test('okuma hatası stream\'i kapatmaz, sıradaki değişiklik yeniden okur',
      () async {
    var fail = true;
    final values = <int>[];
    final errors = <Object>[];
    final sub = watchTables(db, [db.routines], () async {
      if (fail) throw StateError('geçici');
      return count();
    }).listen(values.add, onError: errors.add);
    await settle();
    expect(errors, hasLength(1));

    fail = false;
    await addRoutine('sonra');
    await settle();

    expect(values, [1]);
    await sub.cancel();
  });

  test('izlenmeyen tablo değişince yeniden okumaz', () async {
    var calls = 0;
    final sub = watchTables(db, [db.routines], () async {
      calls++;
      return count();
    }).listen((_) {});
    await settle();

    db.notifyUpdates({TableUpdate.onTable(db.foods)});
    await settle();

    expect(calls, 1);
    await sub.cancel();
  });
}
