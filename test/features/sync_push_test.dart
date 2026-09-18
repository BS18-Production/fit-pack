import 'dart:io';

import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/tables/sync_columns.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_sync_server.dart';

/// Giden kutusu arıza testleri — docs/18 §10 kabul kriteri.
///
/// Bu 6 test yeşil olmadan "veri güvende" diyemeyiz. Her biri gerçek bir
/// kayıp senaryosunu kilitler: uygulama ölmesi, ağın kopması, yeniden
/// gönderimde çift kayıt, onaysız temiz işaretleme, senkron sırasında
/// düzenleme, satırın silinmesi.
void main() {
  late AppDatabase db;
  late FakeSyncServer remote;
  late SyncPush push;
  const user = '00000000-0000-4000-8000-000000000001';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Şema kurulsun (onCreate → tetikleyiciler dahil).
    await db.customSelect('SELECT 1').get();
    remote = FakeSyncServer();
    push = SyncPush(db, remote);
  });

  tearDown(() => db.close());

  Future<void> addRoutine(String name) => db.customStatement(
      "INSERT INTO routines (name, created_at) VALUES ('$name', 1700000000)");

  Future<int> pending(String table) async {
    final r = await db
        .customSelect('SELECT COUNT(*) c FROM $table WHERE sync_state = 1')
        .getSingle();
    return r.read<int>('c');
  }

  test('T-1 · uygulama ölse de kuyruk diskte kalır', () async {
    // Bellek-içi DB süreç ölümünü ölçemez (kapanınca zaten kaybolur) → gerçek
    // dosya: yaz, bağlantıyı KAPAT, yeni AppDatabase ile AÇ.
    final dir = Directory.systemTemp.createTempSync('fitpack_t1');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/fit_pack.sqlite');

    final first = AppDatabase.forTesting(NativeDatabase(file));
    await first.customStatement(
        "INSERT INTO routines (name, created_at) VALUES ('Push', 1700000000)");
    final beforeKill = await first
        .customSelect('SELECT sync_state FROM routines')
        .getSingle();
    expect(beforeKill.read<int>('sync_state'), 1);
    await first.close(); // ← uygulama öldürüldü

    final reopened = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(reopened.close);
    final after = await reopened
        .customSelect('SELECT name, sync_state FROM routines')
        .getSingle();
    expect(after.read<int>('sync_state'), 1,
        reason: 'kuyruk diskte durmalı, süreç ölümüne dayanmalı');
    expect(after.read<String>('name'), 'Push');
  });

  test('T-2 · ağ koparsa satır kuyrukta kalır ve tekrar denenir', () async {
    await addRoutine('Push');
    remote.fail = true;

    final r1 = await push.pushAll(userId: user);
    expect(r1.ok, isFalse);
    expect(await pending('routines'), 1, reason: 'kayıp yok, kuyrukta');

    // Ağ geri geldi.
    remote.fail = false;
    final r2 = await push.pushAll(userId: user);
    expect(r2.pushed, greaterThanOrEqualTo(1));
    expect(await pending('routines'), 0);
    expect(remote.rowCount('routines'), 1);
  });

  test('T-3 · aynı satır iki kez gönderilse sunucuda TEK satır (idempotency)',
      () async {
    await addRoutine('Push');

    // Sunucu yazdı ama onay dönmedi → istemci kuyrukta bıraktı.
    remote.failAfterWrite = true;
    await push.pushAll(userId: user);
    expect(remote.rowCount('routines'), 1);
    expect(await pending('routines'), 1, reason: 'onay gelmedi → kuyrukta');

    // Yeniden gönderim. uid aynı olduğu için sunucuda ÇİFT satır olmamalı.
    remote.failAfterWrite = false;
    await push.pushAll(userId: user);
    expect(remote.rowCount('routines'), 1,
        reason: 'uid çakışması upsert ile çözülür, çift kayıt olmaz');
    expect(await pending('routines'), 0);
  });

  test('T-4 · sunucu onayı gelmeden temiz işaretlenmez', () async {
    await addRoutine('Push');
    remote.failAfterWrite = true;

    await push.pushAll(userId: user);
    expect(await pending('routines'), 1,
        reason: 'onay alınamadıysa satır kirli kalmalı');
  });

  test('T-5 · gönderimden SONRA düzenlenen satır yeniden kuyruğa girer',
      () async {
    await addRoutine('Push');
    await push.pushAll(userId: user);
    expect(await pending('routines'), 0);

    await db.customStatement("UPDATE routines SET name = 'Pull'");
    expect(await pending('routines'), 1,
        reason: 'düzenleme satırı yeniden kuyruğa almalı');

    await push.pushAll(userId: user);
    expect(remote.store['routines']!.values.first['name'], 'Pull',
        reason: 'son hâl sunucuya gitmeli');
  });

  test(
    'T-5b · gönderim SIRASINDA düzenlenen satır temiz işaretlenmemeli',
    () async {
      // E-15: eski T-5 adı bunu vaat ediyordu ama düzenlemeyi `pushAll`
      // BİTTİKTEN sonra yapıyordu — yani hiçbir zaman yarışı ölçmedi.
      //
      // Gerçek yarış: satır sunucuya yazılırken kullanıcı düzenliyor.
      // Eskiden `updated_at` (saniye) karşılaştırılıyordu; düzenleme
      // gönderimle aynı saniyedeyse damga değişmiyor, istemci satırı kendi
      // gönderdiği sürüm sanıp temiz işaretliyor ve **düzenleme sessizce
      // kayboluyordu** (docs/20 §1 hata #3).
      //
      // **2026-09-18'de yeşile döndü:** Aşama 1 cihaz sayacını (`local_seq`)
      // getirdi, temiz işaretleme artık ona bakıyor — saniye çözünürlüğü
      // sorunu ortadan kalktı.
      await addRoutine('Push');
      remote.onUpsert = () async {
        await db.customStatement("UPDATE routines SET name = 'Pull'");
      };

      await push.pushAll(userId: user);

      expect(await pending('routines'), 1,
          reason: 'gönderim sırasındaki düzenleme kuyrukta kalmalı');
      final local =
          await db.customSelect('SELECT name FROM routines').getSingle();
      expect(local.read<String>('name'), 'Pull');
    },
  );

  test('T-5c · yerele ait kolonlar sunucuya gönderilmez', () async {
    // `id` cihaz içi kimlik, `sync_state` giden kutusu bayrağı, `local_seq`
    // cihaz sayacı — üçü de yerele aittir. `server_rev` sunucudan GELİR,
    // istemci göndermez (gönderirse sunucunun atadığı sürümü ezmeye çalışır).
    //
    // `changed_at_ms` ise Aşama 4'ten beri GÖNDERİLİR: sunucudaki çakışma
    // kuralının ölçüsü odur, gönderilmezse sunucu yazmayı "eski" sayıp
    // sessizce reddeder (docs/20 §5.2).
    await addRoutine('Push');
    await push.pushAll(userId: user);

    // `sent` = istemcinin gönderdiği ham yük. `store` sunucunun yazdığı hâl
    // ve orada `server_rev` doğal olarak bulunur.
    final sent = remote.sent['routines']!.single;
    expect(sent.keys, isNot(contains('local_seq')));
    expect(sent.keys, isNot(contains('server_rev')));
    expect(sent.keys, isNot(contains('id')));
    expect(sent['changed_at_ms'], isA<int>(),
        reason: 'çakışma kuralının ölçüsü — gönderilmezse sunucu reddeder');
    expect(sent.keys, isNot(contains('sync_state')));
    // Gitmesi gerekenler yerinde:
    expect(sent['uid'], isNotNull);
    expect(sent['user_id'], user);
    expect(sent['name'], 'Push');
  });

  test('T-6 · senkron yerel satırı SİLMEZ, yalnız bayrağı çevirir', () async {
    await addRoutine('Push');
    await push.pushAll(userId: user);

    final rows = await db.customSelect('SELECT * FROM routines').get();
    expect(rows, hasLength(1), reason: 'yerel satır yerinde durmalı');
    expect(rows.first.data['name'], 'Push');
    expect(rows.first.data['sync_state'], 0);
  });

  // ─────────────── ek: katalog ve referans davranışı ───────────────

  test('katalog satırı KULLANILINCA gönderilir, kullanılmazsa gönderilmez',
      () async {
    await db.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, is_custom) "
      "VALUES ('Bench Press', 'compound', '[\"chest\"]', 0)",
    );
    await db.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, is_custom) "
      "VALUES ('Kullanılmayan', 'compound', '[\"back\"]', 0)",
    );
    await db.customStatement(
      "INSERT INTO workout_sessions (date, phase, workout_type, knee_status, "
      "is_deload) VALUES (1700000000, 0, 'Push', 'normal', 0)",
    );
    await db.customStatement(
      "INSERT INTO workout_sets (session_id, exercise_id, set_number, "
      "is_warmup, set_type, is_complete) VALUES (1, 1, 1, 0, 'normal', 1)",
    );

    await push.pushAll(userId: user);

    expect(remote.rowCount('exercises'), 1,
        reason: 'yalnız sette kullanılan hareket gider — 1015 seed gitmez');
    expect(remote.store['exercises']!.values.first['name'], 'Bench Press');
  });

  test('yabancı anahtarlar uid\'e çevrilir, yerel id sunucuya gitmez',
      () async {
    await db.customStatement(
      "INSERT INTO workout_sessions (date, phase, workout_type, knee_status, "
      "is_deload) VALUES (1700000000, 0, 'Push', 'normal', 0)",
    );
    await db.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, is_custom) "
      "VALUES ('Bench', 'compound', '[\"chest\"]', 1)",
    );
    await db.customStatement(
      "INSERT INTO workout_sets (session_id, exercise_id, set_number, "
      "is_warmup, set_type, is_complete) VALUES (1, 1, 1, 0, 'normal', 1)",
    );

    await push.pushAll(userId: user);

    final sent = remote.store['workout_sets']!.values.first;
    final sessionUid =
        remote.store['workout_sessions']!.values.first['uid'] as String;

    expect(sent['session_uid'], sessionUid, reason: 'int id → uid çevrildi');
    expect(sent.containsKey('session_id'), isFalse);
    expect(sent.containsKey('id'), isFalse, reason: 'yerel kimlik gitmez');
    expect(sent.containsKey('sync_state'), isFalse,
        reason: 'giden kutusu bayrağı cihaza ait');
    expect(sent['user_id'], user, reason: 'RLS için sahiplik damgalanır');
    expect(sent['is_complete'], isTrue, reason: 'SQLite 1 → Postgres true');
  });

  test('KİMLİKSİZ satır onarılır — canlıda 13 satır bu yüzden takılmıştı',
      () async {
    // v10 ÖNCESİ oluşmuş bir katalog satırını taklit et: uid yok.
    await db.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, is_custom) "
      "VALUES ('Eski Hareket', 'compound', '[\"chest\"]', 0)",
    );
    await db.customStatement('UPDATE exercises SET uid = NULL WHERE id = 1');

    await db.customStatement(
      "INSERT INTO workout_sessions (date, phase, workout_type, knee_status, "
      "is_deload) VALUES (1700000000, 0, 'Push', 'normal', 0)",
    );
    await db.customStatement(
      "INSERT INTO workout_sets (session_id, exercise_id, set_number, "
      "is_warmup, set_type, is_complete) VALUES (1, 1, 1, 0, 'normal', 1)",
    );

    final result = await push.pushAll(userId: user);

    // Onarım olmasaydı: hareket kimliksiz → gönderilemez → ona bakan set de
    // gönderilemez → ikisi de SESSİZCE kuyrukta kalırdı.
    expect(result.pushed, greaterThan(0));
    expect(remote.rowCount('exercises'), 1, reason: 'kimlik üretilip gönderildi');
    expect(remote.rowCount('workout_sets'), 1, reason: 'bağımlı satır da gitti');

    final left = await db
        .customSelect('SELECT COUNT(*) c FROM workout_sets WHERE sync_state = 1')
        .getSingle();
    expect(left.read<int>('c'), 0, reason: 'kuyruk boşalmalı');
  });

  test('ZAMAN DAMGASIZ satır onarılır — v9 göçü updated_at boş bıraktı',
      () async {
    // v9 durumunu taklit et: satır tetikleyiciler eklenmeden önce oluşmuş →
    // uid var (v9 backfill etti) ama updated_at YOK. Tetikleyici updated_at'i
    // doldurduğu için, önce onu kaldırıp öyle bir satır üretiyoruz.
    await db.customStatement('DROP TRIGGER IF EXISTS routines_sync_ins');
    await db.customStatement('DROP TRIGGER IF EXISTS routines_sync_upd');
    await db.customStatement(
      "INSERT INTO routines (name, created_at, uid, sync_state) VALUES "
      "('Eski', 1700000000, "
      "'aaaaaaaa-0000-4000-8000-000000000009', 1)",
    );
    // updated_at bilerek verilmedi → NULL (v9 göçünün bıraktığı durum).
    final before = await db
        .customSelect('SELECT updated_at FROM routines')
        .getSingle();
    expect(before.data['updated_at'], isNull, reason: 'kurulum: damga yok');
    // Tetikleyicileri geri kur — push sırasında gerçek hayatta aktifler.
    await db.customStatement(createInsertTriggerSql('routines'));
    await db.customStatement(createUpdateTriggerSql('routines'));

    final result = await push.pushAll(userId: user);

    // Onarım olmasaydı: updated_at NULL → sunucu 23502 (not-null) reddederdi.
    expect(result.error, isNull, reason: 'zaman damgası onarıldı, red yok');
    expect(remote.rowCount('routines'), 1);
    expect(remote.store['routines']!.values.first['updated_at'], isNotNull,
        reason: 'onarım şimdiye ayarladı → sunucuya geçerli damga gitti');
    expect(await pending('routines'), 0, reason: 'kuyruk boşalmalı');
  });

  test('gönderim bağımlılık sırasında: önce ebeveyn, sonra çocuk', () async {
    await db.customStatement(
      "INSERT INTO workout_sessions (date, phase, workout_type, knee_status, "
      "is_deload) VALUES (1700000000, 0, 'Push', 'normal', 0)",
    );
    await db.customStatement(
      "INSERT INTO exercises (name, category, muscle_groups, is_custom) "
      "VALUES ('Bench', 'compound', '[\"chest\"]', 1)",
    );
    await db.customStatement(
      "INSERT INTO workout_sets (session_id, exercise_id, set_number, "
      "is_warmup, set_type, is_complete) VALUES (1, 1, 1, 0, 'normal', 1)",
    );

    await push.pushAll(userId: user);

    expect(remote.calls.indexOf('workout_sessions'),
        lessThan(remote.calls.indexOf('workout_sets')),
        reason: 'set, seansından önce gitmemeli');
  });
}
