import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/sync_meta_dao.dart';
import 'package:fit_pack/features/sync/sync_controller.dart';
import 'package:fit_pack/features/sync/sync_pull.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:fit_pack/features/sync/sync_refresh.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_sync_server.dart';

/// Çekme tetikleyicileri (docs/20 §6.5).
///
/// Tasarım §6.5'te dört tetikleyici sayıyor; giriş ve ret kodlanmıştı, **öne
/// gelme** ve **"Şimdi eşitle"** kodlanmamıştı. Bu testler o ikisini kilitler:
/// telefonun buluttaki değişikliği ancak soğuk açılışta görmesi hatasının
/// geri gelmemesi için.
///
/// Çekme hattının kendisi `sync_pull_test.dart`'ta ölçülüyor; burada ölçülen
/// **ne zaman çekildiği** ve inen verinin ekrana yansıtılıp yansıtılmadığı.
void main() {
  late AppDatabase db;
  late FakeSyncServer remote;
  const user = '00000000-0000-4000-8000-000000000001';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get(); // şema + tetikleyiciler kurulsun
    remote = FakeSyncServer();
  });

  tearDown(() => db.close());

  /// Çekme hattı yerine, sonucu testin belirlediği bir dublör. Gerçek hattın
  /// davranışı ayrı dosyada ölçülüyor; burada `SyncRefresh`'in KARARI test
  /// ediliyor, o yüzden çekmenin ne döndüreceği sabitleniyor.
  _StubPull stub({PullResult result = const PullResult(), Object? throws}) =>
      _StubPull(db, remote, result: result, throws: throws);

  SyncController controllerFor() => SyncController(
        db: db,
        push: SyncPush(db, remote),
        currentUserId: () => user,
      );

  SyncRefresh refreshWith(
    SyncPull pull, {
    required DateTime Function() now,
    void Function()? onChanged,
  }) =>
      SyncRefresh(
        db: db,
        pull: pull,
        controller: controllerFor(),
        onChanged: onChanged ?? () {},
        now: now,
      );

  Future<void> setLastPull(DateTime t) =>
      SyncMetaDao(db).write(SyncMetaDao.keyLastPullOk, '${t.millisecondsSinceEpoch}');

  group('öne gelme — pullIfStale (§6.5)', () {
    test('hiç çekilmemişse çeker', () async {
      final pull = stub(result: const PullResult(inserted: 3));
      final refresh = refreshWith(pull, now: () => DateTime(2026, 9, 22, 10));

      final result = await refresh.pullIfStale(user);

      expect(result, isNotNull, reason: 'ilk kurulumda beklemeden çekmeli');
      expect(pull.calls, 1);
    });

    test('son çekmeden 5 dakika geçmediyse ÇEKMEZ', () async {
      final now = DateTime(2026, 9, 22, 10);
      await setLastPull(now.subtract(const Duration(minutes: 4, seconds: 59)));
      final pull = stub();
      final refresh = refreshWith(pull, now: () => now);

      expect(await refresh.pullIfStale(user), isNull);
      expect(pull.calls, 0,
          reason: 'set aralarında uygulamaya bakan kullanıcı her seferinde '
              'ağ isteği üretmemeli');
    });

    test('son çekmeden 5 dakika geçtiyse çeker', () async {
      final now = DateTime(2026, 9, 22, 10);
      await setLastPull(now.subtract(const Duration(minutes: 5, seconds: 1)));
      final pull = stub(result: const PullResult(updated: 1));
      final refresh = refreshWith(pull, now: () => now);

      expect(await refresh.pullIfStale(user), isNotNull);
      expect(pull.calls, 1);
    });

    test('tam sınırda (5 dakika) çeker — eşitlik bekletmez', () async {
      final now = DateTime(2026, 9, 22, 10);
      await setLastPull(now.subtract(SyncRefresh.foregroundInterval));
      final pull = stub();
      final refresh = refreshWith(pull, now: () => now);

      expect(await refresh.pullIfStale(user), isNotNull);
      expect(pull.calls, 1);
    });
  });

  group('inen veri ekrana yansır (CONVENTIONS §2)', () {
    test('değişiklik indiyse tazeleme çağrılır', () async {
      var refreshed = 0;
      final refresh = refreshWith(
        stub(result: const PullResult(inserted: 1, updated: 2)),
        now: DateTime.now,
        onChanged: () => refreshed++,
      );

      await refresh.pullNow(user);

      expect(refreshed, 1);
    });

    test('değişiklik yoksa tazeleme çağrılmaz', () async {
      var refreshed = 0;
      final refresh = refreshWith(
        stub(result: const PullResult(skipped: 5)),
        now: DateTime.now,
        onChanged: () => refreshed++,
      );

      await refresh.pullNow(user);

      expect(refreshed, 0,
          reason: 'boş turda ekranı tazelemek gereksiz yeniden çizim');
    });

    test('çekme patlarsa hata yutulur, tazeleme çağrılmaz', () async {
      var refreshed = 0;
      final refresh = refreshWith(
        stub(throws: Exception('ağ yok')),
        now: DateTime.now,
        onChanged: () => refreshed++,
      );

      final result = await refresh.pullNow(user);

      expect(result.ok, isFalse);
      expect(refreshed, 0);
      // Yereldeki veri doğru → çağıran çökmemeli (docs/18 Kural 1).
    });
  });

  group('"Şimdi eşitle" (§6.5)', () {
    test('önce gönderir, SONRA çeker', () async {
      // Kuyrukta bir satır olsun ki gönderim gerçekten çağrı yapsın.
      await db.customStatement(
          "INSERT INTO routines (name, created_at) VALUES ('Push day', 1700000000)");
      final pull = stub();
      final refresh = refreshWith(pull, now: DateTime.now);

      await refresh.syncNow(user);

      expect(remote.calls, contains('routines'),
          reason: 'kuyruktaki satır gönderilmeli');
      expect(pull.calls, 1);
      expect(pull.pulledAfterPush, isTrue,
          reason: 'çekme önce olsaydı sunucunun eski kopyası inip gereksiz '
              'ret turu doğardı');
    });

    test('kuyruk boşaldıysa sonuç temiz', () async {
      final refresh = refreshWith(stub(), now: DateTime.now);

      final result = await refresh.syncNow(user);

      expect(result.pending, 0);
      expect(result.ok, isTrue);
    });

    test('kuyruk boşalmadıysa sonuç temiz DEĞİL', () async {
      await db.customStatement(
          "INSERT INTO routines (name, created_at) VALUES ('Push day', 1700000000)");
      remote.fail = true; // ağ yok → satır kuyrukta kalır
      final refresh = refreshWith(stub(), now: DateTime.now);

      final result = await refresh.syncNow(user);

      expect(result.pending, greaterThan(0));
      expect(result.ok, isFalse,
          reason: 'kullanıcıya "eşitlendi" denmemeli — henüz gitmedi');
    });
  });
}

/// Çekme hattının dublörü: sonucu test belirler, çağrı sayısını ve gönderimden
/// sonra mı çağrıldığını kaydeder.
class _StubPull extends SyncPull {
  final PullResult result;
  final Object? throws;

  int calls = 0;

  /// Çekme çağrıldığında sunucuya gönderim yapılmış mıydı.
  bool pulledAfterPush = false;

  final FakeSyncServer fake;

  _StubPull(
    AppDatabase db,
    this.fake, {
    required this.result,
    this.throws,
  }) : super(db, fake);

  @override
  Future<PullResult> pullAll({required String userId, bool full = false}) async {
    calls++;
    pulledAfterPush = fake.upsertCalls > 0;
    if (throws != null) throw throws!;
    return result;
  }
}
