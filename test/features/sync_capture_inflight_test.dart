import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/tables/sync_columns.dart';
import 'package:fit_pack/features/sync/sync_apply.dart';
import 'package:fit_pack/features/sync/sync_pull.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_sync_server.dart';

/// Yakalama bayrağı ve yoldaki silme (docs/46, CR-003 / CR-004).
void main() {
  const user = '00000000-0000-4000-8000-0000000000aa';

  late AppDatabase db;
  late FakeSyncServer remote;
  late SyncPush push;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeSyncServer();
    push = SyncPush(db, remote);
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() => db.close());

  Future<void> addRoutine(String name) => db.customStatement(
      "INSERT INTO routines (name, created_at) VALUES ('$name', 1700000000)");

  Future<int> count(String table) async {
    final r =
        await db.customSelect('SELECT COUNT(*) c FROM $table').getSingle();
    return r.read<int>('c');
  }

  // ─────────────── CR-003: bayrak transaction içinde ───────────────

  test('bayrak kapalıyken araya giren kullanıcı yazması kuyruğa girer',
      () async {
    // Eskiden bayrak transaction'dan ÖNCE kapanıp SONRA açılıyordu. Aradaki
    // kullanıcı yazması kimliksiz, kuyruksuz kalıyor ve sunucuya hiç
    // gitmiyordu.
    final gate = Completer<void>();
    final apply = SyncApply(db);
    final sunucuYazmasi = apply.withCaptureOff(() => gate.future);
    await pumpEventQueue();

    final kullaniciYazmasi = addRoutine('Arada eklendi');
    await pumpEventQueue();
    gate.complete();
    await sunucuYazmasi;
    await kullaniciYazmasi;

    final row = await db
        .customSelect('SELECT uid, sync_state FROM routines')
        .getSingle();
    expect(row.read<String?>('uid'), isNotNull, reason: 'kimlik almalı');
    expect(row.read<int>('sync_state'), 1, reason: 'kuyruğa girmeli');
  });

  test('gövde hata verirse bayrak açık kalır', () async {
    final apply = SyncApply(db);
    await expectLater(
      apply.withCaptureOff(() async => throw StateError('bozuk satır')),
      throwsStateError,
    );

    await addRoutine('Sonra');
    final row =
        await db.customSelect('SELECT sync_state FROM routines').getSingle();
    expect(row.read<int>('sync_state'), 1);
  });

  // ─────────────── CR-004: yoldayken silme ───────────────

  test('gönderim beklerken silinen yeni kayıt sunucuda kalmaz', () async {
    // Yemek ekle → hemen "Geri al": satır sunucuya giderken silinir.
    await addRoutine('Geri alındı');
    remote.onUpsert = () => db.customStatement('DELETE FROM routines');

    await push.pushAll(userId: user);

    expect(remote.rowCount('routines'), 0,
        reason: 'aynı turun sonunda silme de gitmeli');
    expect(await count('sync_tombstones'), 0);

    await SyncPull(db, remote).pullAll(userId: user);
    expect(await count('routines'), 0, reason: 'çekme geri getirmemeli');
  });

  test('sunucu yazdı, cevap kayboldu — sonra silinen kayıt da silinir',
      () async {
    await addRoutine('Cevapsız');
    remote.failAfterWrite = true;
    await push.pushAll(userId: user);
    expect(remote.rowCount('routines'), 1, reason: 'sunucu yazdı');
    remote.failAfterWrite = false;

    await db.customStatement('DELETE FROM routines');
    await push.pushAll(userId: user);

    expect(remote.rowCount('routines'), 0);
    await SyncPull(db, remote).pullAll(userId: user);
    expect(await count('routines'), 0);
  });

  test('kuyruğa hiç girmemiş seed katalog satırı iz bırakmaz', () async {
    await db.customStatement(
        "INSERT INTO exercises (name, primary_muscle, muscle_groups, category, "
        "equipment) VALUES ('Seed', 'chest', '[\"chest\"]', 'compound', "
        "'barbell')");
    final state = await db
        .customSelect("SELECT sync_state FROM exercises WHERE name = 'Seed'")
        .getSingle();
    expect(state.read<int>('sync_state'), 0, reason: 'seed kuyruğa girmez');

    await db.customStatement("DELETE FROM exercises WHERE name = 'Seed'");

    expect(await count('sync_tombstones'), 0);
  });

  // ─────────────── Tetikleyici sürümü: açılışta yenilenir ───────────────

  test('eski silme tetikleyicisi açılışta yeni kurala geçer', () async {
    final dir = await Directory.systemTemp.createTemp('fitpack_trig');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    // Eski kurulumu taklit et: bugünkü (rev 1) silme kuralı, sürüm anahtarı yok.
    var fileDb = AppDatabase.forTesting(NativeDatabase(file));
    await fileDb.customStatement(dropDeleteTriggerSql('routines'));
    await fileDb.customStatement('''
CREATE TRIGGER routines_sync_del AFTER DELETE ON routines
WHEN (SELECT COALESCE(value,'1') FROM sync_meta WHERE key = 'capture') = '1'
     AND OLD.uid IS NOT NULL
     AND (OLD.server_rev IS NOT NULL OR OLD.user_id IS NOT NULL)
BEGIN
  INSERT INTO sync_tombstones (table_name, uid, changed_at_ms, local_seq, sync_state)
  VALUES ('routines', OLD.uid, 0, 0, 1);
END''');
    await fileDb.customStatement(
        "DELETE FROM sync_meta WHERE key = 'trigger_rev'");
    await fileDb.close();

    fileDb = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(fileDb.close);
    final sql = await fileDb
        .customSelect("SELECT sql FROM sqlite_master WHERE name = ?",
            variables: [Variable('routines_sync_del')])
        .getSingle();
    expect(sql.read<String>('sql'), contains('OLD.sync_state <> 0'));
    final rev = await fileDb
        .customSelect("SELECT value FROM sync_meta WHERE key = 'trigger_rev'")
        .getSingle();
    expect(rev.read<String>('value'), '$syncTriggerRev');

    // Yeni kural gerçekten çalışıyor: gönderilmemiş satırın silmesi iz bırakır.
    await fileDb.customStatement(
        "INSERT INTO routines (name, created_at) VALUES ('x', 1700000000)");
    await fileDb.customStatement('DELETE FROM routines');
    final iz = await fileDb
        .customSelect('SELECT COUNT(*) c FROM sync_tombstones')
        .getSingle();
    expect(iz.read<int>('c'), 1);
  });
}
