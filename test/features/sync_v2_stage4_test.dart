import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/sync_meta_dao.dart';
import 'package:fit_pack/features/sync/sync_pull.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_sync_server.dart';

/// **Senkron v2 — Aşama 4** (docs/20 §5.1, §6.1, §12.1).
///
/// Aşama 3 sunucuya çakışma kuralını koydu; bu aşama istemcinin o kuralla
/// konuşmasını sağlıyor. Ölçülen dört şey:
///
/// 1. **Koşullu gönderim** — sunucu reddederse istemci ne yapar (S-12).
/// 2. **Artımlı çekme** — ikinci turda yalnız değişenler iner.
/// 3. **Sayfalama** — sayfa boyundan çok satır kayıpsız iner (S-10).
/// 4. **İmleç payı** — commit sırası bozulduğunda satır atlanmaz (§12.1).
void main() {
  const user = '00000000-0000-4000-8000-0000000000aa';

  late AppDatabase db;
  late FakeSyncServer remote;
  late SyncPush push;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeSyncServer();
    push = SyncPush(db, remote);
    await db.customSelect('SELECT 1').get(); // şema + tetikleyiciler kurulsun
  });

  tearDown(() => db.close());

  Future<int> addRoutine(String name) => db.into(db.routines).insert(
        RoutinesCompanion.insert(name: name, createdAt: DateTime.now()),
      );

  Future<int> pending(String table) async {
    final r = await db
        .customSelect('SELECT COUNT(*) c FROM $table WHERE sync_state = 1')
        .getSingle();
    return r.read<int>('c');
  }

  Future<Map<String, Object?>> routineRow() async {
    final r = await db
        .customSelect('SELECT * FROM routines LIMIT 1')
        .getSingle();
    return r.data;
  }

  // ─────────────────── 1. Koşullu gönderim (ret işleme) ───────────────────

  test('kabul edilen satıra sunucu sürümü yerele yazılır', () async {
    await addRoutine('Bacak');
    final result = await push.pushAll(userId: user);

    expect(result.pushed, 1);
    expect(result.rejected, 0);
    final row = await routineRow();
    expect(row['server_rev'], isA<int>(),
        reason: 'sunucunun verdiği sürüm yerele yazılmalı');
    expect(row['server_rev'], greaterThan(0));
    expect(row['sync_state'], 0);
  });

  test(
    'S-12 · sunucu REDDEDERSE yerel satır sunucununkiyle değişir ve '
    'tekrar gönderilmez',
    () async {
      // Senaryo: çevrimdışı kalmış cihaz eski bir düzenlemeyi göndermeye
      // çalışıyor, ama başka cihaz aynı satırı daha sonra değiştirmiş.
      // Sunucu yazmayı atlar (RETURNING'de görünmez). İstemci bunu
      // ANLAMAZSA satır sonsuza kadar kuyrukta kalır ve her turda boşuna
      // gönderilir; anlarsa sunucudakini alıp temizler.
      await addRoutine('Eski ad');
      await push.pushAll(userId: user);
      final uid = (await routineRow())['uid']! as String;

      // Bu cihazda bir düzenleme yapılıyor (kuyruğa girer).
      // NOT: `changed_at_ms`'i elle YAZAMAYIZ — tetikleyici her yazmada onu
      // gerçek saatten tazeler. Damgayı ayarlamanın tek yolu SUNUCU tarafı.
      await db.customStatement(
          "UPDATE routines SET name = 'Yerel düzenleme' WHERE uid = ?", [uid]);
      expect(await pending('routines'), 1);

      // Sunucudaki sürüm, bu cihazın göndereceğinden YENİ olsun.
      remote.serverSideWrite('routines', uid, {
        'name': 'Sunucudaki ad',
        'changed_at_ms': 9999999999999,
        'user_id': user,
      });

      final result = await push.pushAll(userId: user);

      expect(result.pushed, 0, reason: 'sunucu kabul etmedi');
      expect(result.rejected, 1, reason: 'ret sayılmalı');

      final row = await routineRow();
      expect(row['name'], 'Sunucudaki ad',
          reason: 'yerel satır sunucununkiyle değişmeli');
      expect(row['sync_state'], 0,
          reason: 'kuyruktan çıkmalı — yoksa sonsuza kadar tekrar gönderilir');

      // İkinci tur hiçbir şey göndermemeli.
      remote.calls.clear();
      final ikinci = await push.pushAll(userId: user);
      expect(ikinci.pushed, 0);
      expect(remote.calls, isEmpty, reason: 'kuyruk boş, sunucuya gidilmez');
    },
  );

  test('ret çözülürken ARADA yapılan düzenleme kuyrukta kalır', () async {
    // Ret işleme satırı temizlerken, kullanıcının o sırada yaptığı düzenlemeyi
    // yutmamalı — `local_seq` kontrolü tam bunun için.
    //
    // Damgaların sıralaması testin özü:
    //   gönderilen (T1)  <  sunucudaki (T1+1)  <  aradaki düzenleme (T2)
    // Sunucu gönderileni reddeder; ama aradaki düzenleme sunucudan yeni
    // olduğu için uygulama kuralı sunucuyu YAZMAZ ve satır kuyrukta kalır.
    // Sunucu ikisinden de yeni olsaydı düzenlemenin atılması ZATEN doğru
    // olurdu (docs/20 §5.2) ve test bir şey ölçmezdi.
    await addRoutine('İlk');
    await push.pushAll(userId: user);
    final uid = (await routineRow())['uid']! as String;

    await db.customStatement(
        "UPDATE routines SET name = 'Yerel düzenleme' WHERE uid = ?", [uid]);
    final t1 = (await routineRow())['changed_at_ms']! as int;

    remote.serverSideWrite('routines', uid, {
      'name': 'Sunucu',
      'changed_at_ms': t1 + 1, // gönderilenden yeni, aradakinden eski
      'user_id': user,
    });

    // Gönderim SÜRERKEN kullanıcı yeniden düzenliyor → tetikleyici
    // `local_seq`'i ve `changed_at_ms`'i tazeler. Bekleme, damganın sunucunun
    // t1+1 değerini kesin geçmesi için (saat çözünürlüğü milisaniye).
    remote.onUpsert = () async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await db.customStatement(
          "UPDATE routines SET name = 'Kullanıcı az önce yazdı'");
    };

    final result = await push.pushAll(userId: user);
    expect(result.rejected, 1, reason: 'gönderilen sürüm reddedilmeliydi');

    expect(await pending('routines'), 1,
        reason: 'aradaki düzenleme kuyrukta kalmalı, sessizce yutulmamalı');
    final row = await routineRow();
    expect(row['name'], 'Kullanıcı az önce yazdı',
        reason: 'aradaki düzenleme sunucununkiyle EZİLMEMELİ — o daha yeni');
  });

  // ─────────────────── 2. Artımlı çekme ───────────────────

  test('ikinci çekme yalnız DEĞİŞENLERİ indirir (imleç ilerler)', () async {
    await addRoutine('Bir');
    await addRoutine('İki');
    await push.pushAll(userId: user);

    final pull = SyncPull(db, remote, cursorLag: 0);
    final ilk = await pull.pullAll(userId: user);
    // İki satır da iner. Damgalar eşit olduğu için kural "sunucu kazanır"
    // der ve satırlar üzerine yazılır (docs/20 §5.2) — veri aynı, tekrar
    // çekme idempotent kalsın diye.
    expect(ilk.inserted, 0, reason: 'yerelde zaten varlar');
    expect(ilk.changed + ilk.skipped, 2, reason: 'ikisi de görülmeli');

    // İmleç yazıldı mı?
    final meta = SyncMetaDao(db);
    final cursor =
        await meta.read(SyncMetaDao.pullCursorKey(user, 'routines'));
    expect(cursor, isNotNull);
    expect(int.parse(cursor!), greaterThan(0));

    // Sunucuda hiçbir şey değişmedi → ikinci turda satır inmemeli.
    remote.calls.clear();
    final ikinci = await pull.pullAll(userId: user);
    expect(ikinci.inserted + ikinci.updated + ikinci.skipped, 0,
        reason: 'değişen yoksa hiçbir satır inmez — eskiden her şey inerdi');
  });

  test('imleç kullanıcıya özeldir — başka hesap sıfırdan başlar', () async {
    const digerKullanici = '00000000-0000-4000-8000-0000000000bb';
    expect(
      SyncMetaDao.pullCursorKey(user, 'routines'),
      isNot(SyncMetaDao.pullCursorKey(digerKullanici, 'routines')),
    );
  });

  test('tam uzlaştırma kendiliğinden vadesinde çalışır (docs/20 §12.1)',
      () async {
    // İkinci katman kimsenin çağırmasına bağlı olmamalı; olsaydı yalnız
    // kâğıt üstünde kalırdı.
    await addRoutine('Bir');
    await push.pushAll(userId: user);

    final meta = SyncMetaDao(db);
    final pull = SyncPull(db, remote, cursorLag: 0);

    // İlk tur: damga yok → tam tur yapılır ve damga yazılır.
    await pull.pullAll(userId: user);
    final damga = await meta.read(SyncMetaDao.fullPullKey(user));
    expect(damga, isNotNull, reason: 'tam tur damgası yazılmalı');

    // Vade dolmadan ikinci tur: imleç kullanılır, her şey baştan okunmaz.
    remote.calls.clear();
    await pull.pullAll(userId: user);
    expect(remote.calls.where((c) => c == 'fetchSince:routines').length, 1,
        reason: 'artımlı tur — imleç kullanılmalı');
    final ikinciTurBos = await db
        .customSelect('SELECT COUNT(*) c FROM routines')
        .getSingle();
    expect(ikinciTurBos.read<int>('c'), 1);

    // Damgayı 8 gün geriye al → vade doldu.
    final sekizGunOnce = DateTime.now()
            .subtract(const Duration(days: 8))
            .millisecondsSinceEpoch ~/
        1000;
    await meta.write(SyncMetaDao.fullPullKey(user), '$sekizGunOnce');

    final ucuncu = await pull.pullAll(userId: user);
    expect(ucuncu.changed + ucuncu.skipped, 1,
        reason: 'vade dolunca satır imleç yok sayılarak yeniden okunmalı');
    expect(
      int.parse((await meta.read(SyncMetaDao.fullPullKey(user)))!),
      greaterThan(sekizGunOnce),
      reason: 'damga tazelenmeli',
    );
  });

  test('yarıda kalan tam tur "yapıldı" sayılmaz', () async {
    await addRoutine('Bir');
    await push.pushAll(userId: user);

    remote.fail = true; // çekme patlasın
    final pull = SyncPull(db, remote, cursorLag: 0);
    final result = await pull.pullAll(userId: user);

    expect(result.ok, isFalse);
    expect(await SyncMetaDao(db).read(SyncMetaDao.fullPullKey(user)), isNull,
        reason: 'hatalı tur damgalanırsa atlanmış satır bir hafta görünmez '
            'kalır');
  });

  test('tam uzlaştırma (full) imleci yok sayar', () async {
    await addRoutine('Bir');
    await push.pushAll(userId: user);

    final pull = SyncPull(db, remote, cursorLag: 0);
    await pull.pullAll(userId: user);

    remote.calls.clear();
    await pull.pullAll(userId: user, full: true);
    expect(remote.calls, contains('fetchSince:routines'),
        reason: 'full=true imleci atlayıp baştan okumalı');
  });

  // ─────────────────── 3. Sayfalama ───────────────────

  test('S-10 · sayfa boyundan çok satır kayıpsız iner', () async {
    // Sunucuda 12 satır, sayfa boyu 5 → üç sayfa. Sayfalama `server_rev`
    // üzerinden olduğu için satır atlanmaz ya da iki kez gelmez.
    for (var i = 0; i < 12; i++) {
      remote.serverSideWrite('routines', 'uid-$i', {
        'uid': 'uid-$i',
        'user_id': user,
        'name': 'Rutin $i',
        'order_index': i,
        'is_archived': false,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'changed_at_ms': 1000 + i,
      });
    }

    final pull = SyncPull(db, remote, pageSize: 5, cursorLag: 0);
    final result = await pull.pullAll(userId: user);

    expect(result.inserted, 12, reason: 'hepsi inmeli');
    final count = await db
        .customSelect('SELECT COUNT(*) c FROM routines')
        .getSingle();
    expect(count.read<int>('c'), 12);

    final sayfaCagrilari =
        remote.calls.where((c) => c == 'fetchSince:routines').length;
    expect(sayfaCagrilari, 3, reason: '12 satır / 5 = 3 sayfa');
  });

  test('sunucu sayfa boyundan fazla döndürürse durur, sessizce atlamaz',
      () async {
    for (var i = 0; i < 4; i++) {
      remote.serverSideWrite('routines', 'uid-$i', {
        'uid': 'uid-$i',
        'user_id': user,
        'name': 'Rutin $i',
        'order_index': i,
        'is_archived': false,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'changed_at_ms': 1000 + i,
      });
    }
    // Sayfa boyu 2 istenirken sunucu 4 döndürürse sayfalama varsayımı çökmüş
    // demektir; sessizce devam etmek satır atlamak olur.
    final pull = SyncPull(db, _TooManyRowsServer(remote), pageSize: 2);
    final result = await pull.pullAll(userId: user);
    expect(result.ok, isFalse, reason: 'hata olarak raporlanmalı');
    expect(result.error, isA<StateError>());
  });

  // ─────────────────── 4. İmleç payı (docs/20 §12.1) ───────────────────

  test('imleç PAYLA geriden saklanır — commit sırası bozulsa da satır atlanmaz',
      () async {
    await addRoutine('Bir');
    await push.pushAll(userId: user);

    final pull = SyncPull(db, remote, cursorLag: 1000);
    await pull.pullAll(userId: user);

    final meta = SyncMetaDao(db);
    final cursor = int.parse(
        (await meta.read(SyncMetaDao.pullCursorKey(user, 'routines')))!);
    // Tek satır var, sürümü küçük → pay onu 0'a çeker (negatife inmez).
    expect(cursor, 0,
        reason: 'pay kadar geriden saklanmalı, 0 tabanında durmalı');
  });

  test('pay sayesinde geç görünen satır bir sonraki turda iner', () async {
    // §12.1'in senaryosu: büyük sürümlü satır önce görünür, imleç ilerler,
    // sonra küçük sürümlü satır ortaya çıkar. Pay olmasaydı o satır bir daha
    // hiç inmezdi.
    remote.serverSideWrite('routines', 'gec-kalan', {
      'uid': 'gec-kalan',
      'user_id': user,
      'name': 'Geç görünen',
      'order_index': 0,
      'is_archived': false,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'changed_at_ms': 1000,
    });
    final gecRev = remote.store['routines']!['gec-kalan']!['server_rev']! as int;

    // Daha büyük sürümlü satır önce görünüyor.
    remote.serverSideWrite('routines', 'once-gorunen', {
      'uid': 'once-gorunen',
      'user_id': user,
      'name': 'Önce görünen',
      'order_index': 1,
      'is_archived': false,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'changed_at_ms': 1000,
    });

    // "Geç kalan" henüz görünmüyormuş gibi gizle.
    final gizli = remote.store['routines']!.remove('gec-kalan')!;

    final pull = SyncPull(db, remote, cursorLag: 1000);
    await pull.pullAll(userId: user);
    expect(
      await db.customSelect('SELECT COUNT(*) c FROM routines').getSingle().then(
          (r) => r.read<int>('c')),
      1,
    );

    // Şimdi commit oldu — küçük sürümüyle ortaya çıkıyor.
    remote.store['routines']!['gec-kalan'] = gizli;

    await pull.pullAll(userId: user);
    final varMi = await db
        .customSelect("SELECT COUNT(*) c FROM routines WHERE uid = 'gec-kalan'")
        .getSingle();
    expect(varMi.read<int>('c'), 1,
        reason: 'pay olmasaydı imleç $gecRev sürümünü çoktan geçmiş olurdu '
            've bu satır bir daha hiç inmezdi');
  });
}

/// İstenenden fazla satır döndüren bozuk sunucu — tutarlılık kontrolünü ölçer.
class _TooManyRowsServer implements SyncRemote {
  _TooManyRowsServer(this.inner);
  final FakeSyncServer inner;

  @override
  Future<List<AcceptedRow>> upsert(
          String table, List<Map<String, Object?>> rows) =>
      inner.upsert(table, rows);

  @override
  Future<List<Map<String, Object?>>> fetchSince(
          String table, String userId, int sinceRev, int limit) =>
      inner.fetchSince(table, userId, sinceRev, 1000); // sınırı yok sayar

  @override
  Future<List<Map<String, Object?>>> fetchByUids(
          String table, String userId, List<String> uids) =>
      inner.fetchByUids(table, userId, uids);

  @override
  Future<List<String>> deleteRows(
          String table, String userId, List<String> uids) =>
      inner.deleteRows(table, userId, uids);
}
