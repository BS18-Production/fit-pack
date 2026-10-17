import 'package:drift/native.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/sync_meta_dao.dart';
import 'package:fit_pack/features/auth/account_switch.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';
import 'package:fit_pack/features/sync/sync_controller.dart';
import 'package:fit_pack/features/sync/sync_health.dart';
import 'package:fit_pack/features/sync/sync_ownership.dart';
import 'package:fit_pack/features/sync/sync_pull.dart';
import 'package:fit_pack/features/sync/sync_push.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_sync_server.dart';

/// Senkronun hesap sahipliği sınırı (docs/47, CR-001).
///
/// Kapı ekranı kilitlerken arka plan senkronu da durmalı: A'nın kayıtları
/// B'nin hesabına gitmemeli, B'nin verisi A'nın veritabanına inmemeli, yolda
/// kalmış eski iş hesap değiştikten sonra yazılmamalı.
void main() {
  const userA = '00000000-0000-4000-8000-00000000000a';
  const userB = '00000000-0000-4000-8000-00000000000b';

  late AppDatabase db;
  late FakeSyncServer remote;
  late SyncOwnership ownership;
  late SyncPush push;
  late SyncPull pull;
  late SyncController ctrl;
  String? session;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    remote = FakeSyncServer();
    session = userA;
    ownership = SyncOwnership(db, sessionUserId: () => session);
    push = SyncPush(db, remote, ownership: ownership);
    pull = SyncPull(db, remote, ownership: ownership);
    ctrl = SyncController(
      db: db,
      push: push,
      currentUserId: () => session,
      debounce: const Duration(milliseconds: 10),
    );
  });

  tearDown(() async {
    await ctrl.stop();
    await db.close();
  });

  Future<void> setOwner(String? user) => user == null
      ? db.syncMetaDao.remove(SyncMetaDao.keyLastUser)
      : db.syncMetaDao.write(SyncMetaDao.keyLastUser, user);

  Future<void> addRoutine(String name) => db.customStatement(
      "INSERT INTO routines (name, created_at) VALUES ('$name', 1700000000)");

  Future<int> count(String table) async {
    final r =
        await db.customSelect('SELECT COUNT(*) c FROM $table').getSingle();
    return r.read<int>('c');
  }

  /// Sunucuda [user]'a ait bir rutin oluşturur (başka bir cihazdan gönderilmiş
  /// gibi).
  Future<void> seedServer(String user, String name) async {
    final other = AppDatabase.forTesting(NativeDatabase.memory());
    await other.customStatement(
        "INSERT INTO routines (name, created_at) VALUES ('$name', 1700000000)");
    await SyncPush(other, remote).pushAll(userId: user);
    await other.close();
  }

  // ─────────────── Gönderim ───────────────

  group('gönderim', () {
    test('çakışmada (sahip A, oturum B) hiçbir şey gönderilmez', () async {
      // A'nın gönderilmemiş kaydı var, B giriş yaptı, çakışma ekranı açık.
      await setOwner(userA);
      await addRoutine('A kaydı');
      session = userB;

      await ctrl.syncNow();

      expect(remote.upsertCalls, 0,
          reason: "A'nın kaydı B'nin hesabına gitmemeli");
      expect(await ctrl.pendingCount(), 1, reason: 'kayıt kuyrukta kalır');
    });

    test('aynı hesapta normal gönderir', () async {
      await setOwner(userA);
      await addRoutine('A kaydı');

      await ctrl.syncNow();

      expect(remote.rowCount('routines'), 1);
      expect(await ctrl.pendingCount(), 0);
    });

    test('yarım kalmış hesap temizliği varken göndermez', () async {
      await setOwner(userA);
      await addRoutine('A kaydı');
      await db.syncMetaDao.write(SyncMetaDao.keySwitchInProgress, userB);

      await ctrl.syncNow();

      expect(remote.upsertCalls, 0);
    });

    test('ilk giriş: sahip yazılmadan beklenir, yazılınca gönderilir',
        () async {
      // Sahipsiz yerel veri; hesap kontrolü henüz bitmedi.
      await addRoutine('Girişten önce');
      await ctrl.syncNow();
      expect(remote.upsertCalls, 0);

      // Kapı veriyi bu hesaba bağladı (AccountSwitch.adopted).
      expect(await AccountSwitchGuard.apply(db, userA), AccountSwitch.adopted);
      await ctrl.syncNow();
      expect(remote.rowCount('routines'), 1);
    });

    test('tur sürerken hesap temizliği başlarsa temiz işaretlenmez', () async {
      await setOwner(userA);
      await addRoutine('Yolda');
      remote.onUpsert = () =>
          db.syncMetaDao.write(SyncMetaDao.keySwitchInProgress, userB);

      final result = await push.pushAll(userId: userA);

      expect(result.ok, isFalse);
      expect(result.error, isA<SyncOwnershipLost>());
      final row =
          await db.customSelect('SELECT sync_state, user_id FROM routines')
              .getSingle();
      expect(row.read<int>('sync_state'), 1,
          reason: 'sahiplik bozulunca yerel yazma yapılmaz');
      expect(row.read<String?>('user_id'), isNull);
      expect(await SyncHealth(db).unreachableSince(), isNull,
          reason: 'hesap değişimi ağ hatası değildir');
    });

    test('başka hesaba ait satır gönderilmez', () async {
      await setOwner(userA);
      await addRoutine('Benim');
      await db.customStatement(
          "INSERT INTO routines (name, created_at, user_id) "
          "VALUES ('Başkasının', 1700000000, '$userB')");
      await db.customStatement(
          "UPDATE routines SET sync_state = 1 WHERE name = 'Başkasının'");

      await push.pushAll(userId: userA);

      final gonderilen = [
        for (final r in remote.sent['routines'] ?? const []) r['name']
      ];
      expect(gonderilen, ['Benim']);
      final kalan = await db
          .customSelect(
              "SELECT sync_state FROM routines WHERE name = 'Başkasının'")
          .getSingle();
      expect(kalan.read<int>('sync_state'), 1, reason: 'kuyrukta bekler');
    });
  });

  // ─────────────── Çekme ───────────────

  group('çekme', () {
    test("çakışmada B'nin verisi A'nın veritabanına inmez", () async {
      await seedServer(userB, 'B rutini');
      await setOwner(userA);
      session = userB;

      await pull.pullAll(userId: userB);

      expect(await count('routines'), 0);
    });

    test('çekme sürerken oturum değişirse hiçbir şey yazılmaz', () async {
      await seedServer(userA, 'A rutini');
      await setOwner(userA);
      remote.onFetch = () async => session = userB;

      await expectLater(
          pull.pullAll(userId: userA), throwsA(isA<SyncOwnershipLost>()));

      expect(await count('routines'), 0);
      expect(
          await db.syncMetaDao
              .read(SyncMetaDao.pullCursorKey(userA, 'routines')),
          isNull,
          reason: 'imleç ilerlemez — bir sonraki tur baştan alır');
    });

    test('aynı hesapta normal çeker', () async {
      await seedServer(userA, 'A rutini');
      await setOwner(userA);

      await pull.pullAll(userId: userA);

      expect(await count('routines'), 1);
    });
  });

  // ─────────────── Açılış ───────────────

  group('açılış çekmesi', () {
    bool karar({AccountSwitch? outcome, bool error = false}) =>
        shouldPullOnBootstrap(
          userId: userA,
          alreadyApplied: false,
          outcome: outcome,
          accountError: error,
        );

    test('çakışma ya da hata varsa çekme başlamaz', () {
      expect(karar(outcome: AccountSwitch.pendingConflict), isFalse);
      expect(karar(error: true), isFalse);
    });

    test('normal açılışta çeker', () {
      expect(karar(outcome: AccountSwitch.sameUser), isTrue);
      expect(karar(outcome: AccountSwitch.adopted), isTrue);
      expect(karar(outcome: AccountSwitch.wiped), isTrue);
    });

    test('oturum yoksa ya da zaten uygulandıysa çekmez', () {
      expect(
          shouldPullOnBootstrap(
              userId: null,
              alreadyApplied: false,
              outcome: null,
              accountError: false),
          isFalse);
      expect(
          shouldPullOnBootstrap(
              userId: userA,
              alreadyApplied: true,
              outcome: AccountSwitch.sameUser,
              accountError: false),
          isFalse);
    });
  });
}
