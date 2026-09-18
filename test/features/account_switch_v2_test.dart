import 'package:drift/native.dart';
import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/database/daos/sync_meta_dao.dart';
import 'package:fit_pack/features/auth/account_switch.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Senkron v2 Aşama 2 — hesap izolasyonu (docs/20 §7.3–§7.5).
///
/// Buradaki üç kural veri güvenliğiyle ilgili: yarım kalan temizlik sızıntı
/// yapar, gönderilmemiş kaydı sessizce silmek veri kaybıdır, doğrulanamayan
/// hesabı içeri almak başkasının verisini gösterir.
void main() {
  late AppDatabase db;
  const userA = '00000000-0000-4000-8000-00000000000a';
  const userB = '00000000-0000-4000-8000-00000000000b';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
  });
  tearDown(() => db.close());

  Future<void> addRoutine(String name) => db.customStatement(
    "INSERT INTO routines (name, created_at) VALUES ('$name', 1700000000)",
  );

  Future<int> count(String table) async {
    final r =
        await db.customSelect('SELECT COUNT(*) c FROM $table').getSingle();
    return r.read<int>('c');
  }

  Future<void> markAllSynced() =>
      db.customStatement('UPDATE routines SET sync_state = 0');

  group('§7.3 yarıda kalan temizlik', () {
    test('işaret bırakılır ve bitince silinir', () async {
      await AccountSwitchGuard.apply(db, userA);
      await addRoutine('A verisi');
      await markAllSynced();

      await AccountSwitchGuard.apply(db, userB);

      expect(await count('routines'), 0, reason: 'A verisi silinmeli');
      expect(await db.syncMetaDao.read(SyncMetaDao.keySwitchInProgress), isNull,
          reason: 'tamamlanan temizlik işareti bırakmaz');
      expect(await db.syncMetaDao.read(SyncMetaDao.keyLastUser), userB);
    });

    test('yarım kalmış temizlik açılışta tamamlanır', () async {
      await AccountSwitchGuard.apply(db, userA);
      await addRoutine('A verisi');
      await markAllSynced();
      // Uygulama tam burada ölmüş gibi: işaret var, veri duruyor.
      await db.syncMetaDao.write(SyncMetaDao.keySwitchInProgress, userB);

      final resumed = await AccountSwitchGuard.resumeIfInterrupted(db);

      expect(resumed, isTrue);
      expect(await count('routines'), 0, reason: 'sızıntı kalmamalı');
      expect(await db.syncMetaDao.read(SyncMetaDao.keyLastUser), userB);
      expect(await db.syncMetaDao.read(SyncMetaDao.keySwitchInProgress), isNull);
    });

    test('yarım iş yoksa açılış ucuz geçer', () async {
      expect(await AccountSwitchGuard.resumeIfInterrupted(db), isFalse);
    });

    test('temizlik mezar taşı ÜRETMEZ', () async {
      // Üretseydi, o izler yeni kullanıcının hesabıyla sunucuya gider ve
      // ONUN kayıtlarını silerdi.
      await AccountSwitchGuard.apply(db, userA);
      await db.customStatement(
        "INSERT INTO routines (name, created_at, uid, user_id) "
        "VALUES ('A', 1700000000, 'uid-a', '$userA')",
      );
      await markAllSynced();

      await AccountSwitchGuard.apply(db, userB);

      expect(await count('sync_tombstones'), 0);
    });
  });

  group('§7.4 gönderilmemiş kayıt + farklı hesap', () {
    test('veri SİLİNMEZ, karar kullanıcıya bırakılır', () async {
      await AccountSwitchGuard.apply(db, userA);
      await addRoutine('Gönderilmemiş'); // tetikleyici kuyruğa aldı

      final outcome = await AccountSwitchGuard.apply(db, userB);

      expect(outcome, AccountSwitch.pendingConflict);
      expect(await count('routines'), 1, reason: 'kayıt durmalı');
      expect(await db.syncMetaDao.read(SyncMetaDao.keyLastUser), userA,
          reason: 'sahiplik değişmedi');
      expect(await AccountSwitchGuard.pendingRowCount(db), 1);
    });

    test('kullanıcı onaylarsa silinir ve yeni hesaba geçilir', () async {
      await AccountSwitchGuard.apply(db, userA);
      await addRoutine('Gönderilmemiş');

      await AccountSwitchGuard.wipeAndAdopt(db, userB);

      expect(await count('routines'), 0);
      expect(await db.syncMetaDao.read(SyncMetaDao.keyLastUser), userB);
      expect(await db.syncMetaDao.read(SyncMetaDao.keySwitchInProgress), isNull);
    });

    test('kuyruk boşsa normal temizlik yapılır', () async {
      await AccountSwitchGuard.apply(db, userA);
      await addRoutine('Gönderilmiş');
      await markAllSynced();

      expect(await AccountSwitchGuard.apply(db, userB), AccountSwitch.wiped);
    });
  });

  test('last_user_id shared_preferences\'tan deftere taşınır', () async {
    SharedPreferences.setMockInitialValues({
      AccountSwitchGuard.lastUserKey: userA,
    });

    // Aynı kullanıcı tekrar giriyor: taşıma olmasaydı "yeni cihaz" sanılıp
    // veri yeni hesaba bağlanırdı.
    expect(await AccountSwitchGuard.apply(db, userA), AccountSwitch.sameUser);
    expect(await db.syncMetaDao.read(SyncMetaDao.keyLastUser), userA);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AccountSwitchGuard.lastUserKey), isNull,
        reason: 'eski yer temizlenir, tek kaynak kalır');
  });

  group('§7.5 kapı kararı', () {
    test('hesap doğrulanamadıysa içeri alınmaz', () {
      expect(
        gateRedirect(
          location: AppRoutes.home,
          signedIn: true,
          onboarded: true,
          accountError: true,
        ),
        AppRoutes.accountError,
      );
      // Hata ekranındayken orada kalınır.
      expect(
        gateRedirect(
          location: AppRoutes.accountError,
          signedIn: true,
          onboarded: true,
          accountError: true,
        ),
        isNull,
      );
    });

    test('gönderilmemiş kayıt çatışması seçim ekranına götürür', () {
      expect(
        gateRedirect(
          location: AppRoutes.home,
          signedIn: true,
          onboarded: true,
          pendingConflict: true,
        ),
        AppRoutes.accountConflict,
      );
    });

    test('hesap hatası çatışmanın önünde gelir', () {
      expect(
        gateRedirect(
          location: AppRoutes.accountConflict,
          signedIn: true,
          onboarded: true,
          accountError: true,
          pendingConflict: true,
        ),
        AppRoutes.accountError,
      );
    });

    test('meşgulken karar ertelenir (ekran titremesin)', () {
      expect(
        gateRedirect(
          location: AppRoutes.home,
          signedIn: true,
          onboarded: true,
          busy: true,
          accountError: true,
        ),
        isNull,
      );
    });

    test('nötr açılış ekranı: oturumsuz → karşılama, oturumlu → ana sayfa', () {
      expect(
        gateRedirect(
          location: AppRoutes.splash,
          signedIn: false,
          onboarded: false,
        ),
        AppRoutes.welcome,
      );
      expect(
        gateRedirect(
          location: AppRoutes.splash,
          signedIn: true,
          onboarded: true,
        ),
        AppRoutes.home,
        reason: 'oturum açıkken Karşılama hiç görünmemeli',
      );
      expect(
        gateRedirect(
          location: AppRoutes.splash,
          signedIn: true,
          onboarded: false,
        ),
        AppRoutes.onboarding,
      );
      // Kapı meşgulken nötr ekranda beklenir (karar verilmedi).
      expect(
        gateRedirect(
          location: AppRoutes.splash,
          signedIn: true,
          onboarded: true,
          busy: true,
        ),
        isNull,
      );
    });

    test('oturum yoksa bu ekranlar gösterilmez', () {
      expect(
        gateRedirect(
          location: AppRoutes.welcome,
          signedIn: false,
          onboarded: false,
          accountError: true,
          pendingConflict: true,
        ),
        isNull,
      );
    });
  });
}
