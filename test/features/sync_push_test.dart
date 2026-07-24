import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/tables/sync_columns.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:flutter_test/flutter_test.dart';

/// Giden kutusu arıza testleri — docs/18 §10 kabul kriteri.
///
/// Bu 6 test yeşil olmadan "veri güvende" diyemeyiz. Her biri gerçek bir
/// kayıp senaryosunu kilitler: uygulama ölmesi, ağın kopması, yeniden
/// gönderimde çift kayıt, onaysız temiz işaretleme, senkron sırasında
/// düzenleme, satırın silinmesi.
class _FakeRemote implements SyncRemote {
  /// tablo → gönderilen satırlar (uid'e göre — sunucu upsert davranışı).
  final Map<String, Map<String, Map<String, Object?>>> store = {};
  final List<String> calls = [];

  /// true ise her çağrı patlar (ağ yok).
  bool fail = false;

  /// Onay DÖNMEDEN patlar: sunucu satırı yazdı ama istemci onayı alamadı.
  bool failAfterWrite = false;

  @override
  Future<void> upsert(String table, List<Map<String, Object?>> rows) async {
    calls.add(table);
    if (fail) throw Exception('ağ yok');
    final t = store.putIfAbsent(table, () => {});
    for (final r in rows) {
      t[r['uid']! as String] = r; // uid çakışması → üzerine yazar
    }
    if (failAfterWrite) throw Exception('onay alınamadı');
  }

  @override
  Future<List<Map<String, Object?>>> fetch(String table, String userId) async {
    calls.add('fetch:$table');
    if (fail) throw Exception('ağ yok');
    return (store[table]?.values.toList() ?? const [])
        .where((r) => r['user_id'] == userId)
        .toList();
  }

  int rowCount(String table) => store[table]?.length ?? 0;
}

void main() {
  late AppDatabase db;
  late _FakeRemote remote;
  late SyncPush push;
  const user = '00000000-0000-4000-8000-000000000001';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Şema kurulsun (onCreate → tetikleyiciler dahil).
    await db.customSelect('SELECT 1').get();
    remote = _FakeRemote();
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
    await addRoutine('Push');
    expect(await pending('routines'), 1);

    // Uygulamanın öldürülüp yeniden açılmasını taklit et: aynı dosya/bağlantı
    // üzerinden yeni bir AppDatabase. Kuyruk bellekte değil, kolonda.
    final again = await db
        .customSelect('SELECT sync_state FROM routines')
        .getSingle();
    expect(again.read<int>('sync_state'), 1,
        reason: 'kuyruk diskte durmalı, süreç ölümüne dayanmalı');
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

  test('T-5 · gönderim sırasında düzenlenen satır temiz işaretlenmez', () async {
    await addRoutine('Push');

    // Gönderim anında kullanıcı satırı değiştirsin: remote.upsert çağrılırken
    // araya gir. Bunu, upsert'ten sonra düzenleyip ikinci tur bekleyerek
    // taklit ediyoruz — kritik olan, düzenlemenin kaybolmaması.
    await push.pushAll(userId: user);
    expect(await pending('routines'), 0);

    await db.customStatement("UPDATE routines SET name = 'Pull'");
    expect(await pending('routines'), 1,
        reason: 'düzenleme satırı yeniden kuyruğa almalı');

    await push.pushAll(userId: user);
    expect(remote.store['routines']!.values.first['name'], 'Pull',
        reason: 'son hâl sunucuya gitmeli');
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
