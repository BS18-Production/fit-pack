import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/auth/account_switch.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

/// Zorunlu giriş kapısı (docs/18 §5.1) — yönlendirme tablosu + hesap değişimi.
void main() {
  group('gateRedirect — yönlendirme tablosu', () {
    test('oturum yoksa her yerden karşılamaya', () {
      for (final loc in [AppRoutes.home, AppRoutes.onboarding, '/workout']) {
        expect(
          gateRedirect(location: loc, signedIn: false, onboarded: false),
          AppRoutes.welcome,
          reason: '$loc oturumsuz erişilememeli',
        );
      }
    });

    test('oturum yoksa kapı ekranlarında kalınır', () {
      expect(
        gateRedirect(
            location: AppRoutes.welcome, signedIn: false, onboarded: false),
        isNull,
      );
      expect(
        gateRedirect(
            location: AppRoutes.auth, signedIn: false, onboarded: false),
        isNull,
      );
    });

    test('oturum var + onboarding yoksa onboarding\'e', () {
      expect(
        gateRedirect(
            location: AppRoutes.home, signedIn: true, onboarded: false),
        AppRoutes.onboarding,
      );
      expect(
        gateRedirect(
            location: AppRoutes.onboarding, signedIn: true, onboarded: false),
        isNull,
      );
    });

    test('oturum var + onboarded ise kapıya geri dönülemez', () {
      expect(
        gateRedirect(
            location: AppRoutes.welcome, signedIn: true, onboarded: true),
        AppRoutes.home,
      );
      expect(
        gateRedirect(
            location: AppRoutes.auth, signedIn: true, onboarded: true),
        AppRoutes.home,
      );
      expect(
        gateRedirect(
            location: AppRoutes.onboarding, signedIn: true, onboarded: true),
        AppRoutes.home,
      );
    });

    test('içerideki normal sayfalar serbest', () {
      expect(
        gateRedirect(
            location: '/workout/active', signedIn: true, onboarded: true),
        isNull,
      );
    });

    test('kurtarma oturumu her şeyin önünde — yeni şifre ekranına kilitler',
        () {
      // Sıfırlama bağlantısı GERÇEK oturum açar. Bayrak olmasaydı kullanıcı
      // "oturum var + onboarded" kuralıyla doğruca Ana Sayfa'ya düşer, şifresi
      // değişmemiş olurdu (docs/18 §14).
      for (final loc in [AppRoutes.home, AppRoutes.onboarding, '/workout']) {
        expect(
          gateRedirect(
              location: loc,
              signedIn: true,
              onboarded: true,
              recovering: true),
          AppRoutes.resetPassword,
          reason: '$loc kurtarma sırasında görülmemeli',
        );
      }
    });

    test('kurtarma sırasında yeni şifre ekranında kalınır', () {
      expect(
        gateRedirect(
            location: AppRoutes.resetPassword,
            signedIn: true,
            onboarded: true,
            recovering: true),
        isNull,
      );
    });

    test('oturum düşerse kurtarma ekranında kilitli kalınmaz', () {
      // Bağlantının süresi dolmuş → oturum yok. Kullanıcı şifre yazamayacağı
      // boş ekranda hapsolmamalı, karşılamaya dönmeli.
      expect(
        gateRedirect(
            location: AppRoutes.resetPassword,
            signedIn: false,
            onboarded: true,
            recovering: true),
        AppRoutes.welcome,
      );
    });

    test('kurtarma bitince şifre ekranı erişilemez olur', () {
      expect(
        gateRedirect(
            location: AppRoutes.resetPassword,
            signedIn: true,
            onboarded: true),
        AppRoutes.home,
      );
      // Onboarding'i bitirmemiş kullanıcı önce oraya gider.
      expect(
        gateRedirect(
            location: AppRoutes.resetPassword,
            signedIn: true,
            onboarded: false),
        AppRoutes.onboarding,
      );
    });

    test('hesap değişimi kurtarmanın da önünde — karar ertelenir', () {
      expect(
        gateRedirect(
            location: AppRoutes.home,
            signedIn: true,
            onboarded: true,
            recovering: true,
            busy: true),
        isNull,
      );
    });

    test('hesap değişimi sürerken karar ertelenir', () {
      // Yerel veri silinirken kullanıcı bir an eski hesabın ekranını görmemeli.
      expect(
        gateRedirect(
            location: AppRoutes.home,
            signedIn: false,
            onboarded: true,
            busy: true),
        isNull,
      );
    });
  });

  group('authActionFor — oturum olayı karşılığı', () {
    const user = 'u-1';
    const other = 'u-2';

    test(
      'yeniden açılışta diskten gelen oturum hesap kontrolü BAŞLATMAZ',
      () {
        // 2026-09-16 regresyonu: `initialSession` hesap değişimi sanılıyordu →
        // busy açılıyor, router kararı erteleniyor ve oturum açıkken birkaç
        // saniye Karşılama ekranı görünüyordu.
        expect(
          authActionFor(
            event: AuthChangeEvent.initialSession,
            userId: user,
            appliedUserId: null,
          ),
          AuthAction.markApplied,
        );
      },
    );

    test('bootstrap işaretlediyse aynı olay yalnız haber verir', () {
      expect(
        authActionFor(
          event: AuthChangeEvent.initialSession,
          userId: user,
          appliedUserId: user,
        ),
        AuthAction.notifyOnly,
      );
    });

    test('yeni giriş ve hesap değişimi hesap kontrolü ister', () {
      expect(
        authActionFor(
          event: AuthChangeEvent.signedIn,
          userId: user,
          appliedUserId: null,
        ),
        AuthAction.applyAccount,
      );
      expect(
        authActionFor(
          event: AuthChangeEvent.signedIn,
          userId: other,
          appliedUserId: user,
        ),
        AuthAction.applyAccount,
      );
    });

    test('token yenileme tekrar tekrar gelse de kontrol çalışmaz', () {
      expect(
        authActionFor(
          event: AuthChangeEvent.tokenRefreshed,
          userId: user,
          appliedUserId: user,
        ),
        AuthAction.notifyOnly,
      );
    });

    test('oturum yoksa kapı devreye girer', () {
      expect(
        authActionFor(
          event: AuthChangeEvent.signedOut,
          userId: null,
          appliedUserId: user,
        ),
        AuthAction.signedOut,
      );
    });
  });

  group('AccountSwitchGuard — Kural 3', () {
    late AppDatabase db;
    const userA = '00000000-0000-4000-8000-00000000000a';
    const userB = '00000000-0000-4000-8000-00000000000b';

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async => db.close());

    /// Kullanıcıya ait tipik veri: profil + bir ölçüm + özel bir hareket +
    /// bir de ortak katalog satırı (seed).
    Future<void> seedUserData() async {
      await db.userProfileDao.ensureProfile();
      await db.customStatement(
          'UPDATE user_profile SET onboarded = 1 WHERE id = 1');
      await db.into(db.bodyMeasurements).insert(BodyMeasurementsCompanion(
            date: Value(DateTime.now()),
            weightKg: const Value(84.7),
          ));
      await db.customStatement(
          "INSERT INTO exercises (name, category, muscle_groups, is_custom) "
          "VALUES ('Kendi hareketim', 'compound', '[\"chest\"]', 1)");
      await db.customStatement(
          "INSERT INTO exercises (name, category, muscle_groups, is_custom) "
          "VALUES ('Seed hareketi', 'compound', '[\"chest\"]', 0)");
    }

    Future<int> count(String table, [String where = '1=1']) async {
      final r = await db
          .customSelect('SELECT COUNT(*) c FROM $table WHERE $where')
          .getSingle();
      return r.read<int>('c');
    }

    test('ilk giriş: yerel veri hesaba bağlanır, silinmez', () async {
      await seedUserData();
      final result = await AccountSwitchGuard.apply(db, userA);

      expect(result, AccountSwitch.adopted);
      expect(await count('body_measurements'), 1);
      expect(await count('exercises', 'is_custom = 1'), 1);
    });

    test('aynı kullanıcı tekrar girince veri korunur', () async {
      await seedUserData();
      await AccountSwitchGuard.apply(db, userA);
      final result = await AccountSwitchGuard.apply(db, userA);

      expect(result, AccountSwitch.sameUser);
      expect(await count('body_measurements'), 1);
    });

    test('farklı kullanıcı girince yerel kullanıcı verisi temizlenir',
        () async {
      await seedUserData();
      await AccountSwitchGuard.apply(db, userA);

      final result = await AccountSwitchGuard.apply(db, userB);

      expect(result, AccountSwitch.wiped);
      // Sızıntı yok: önceki hesabın ölçümü ve özel hareketi gitti.
      expect(await count('body_measurements'), 0);
      expect(await count('exercises', 'is_custom = 1'), 0);
      // Ortak katalog KALIR — kimseye ait değil, yeniden indirmek israf.
      expect(await count('exercises', 'is_custom = 0'), 1);
      // Profil sıfırdan kurulur → yeni kullanıcı kendi onboarding'inden geçer.
      final profile = await db.userProfileDao.getProfile();
      expect(profile, isNotNull);
      expect(profile!.onboarded, isFalse);
    });

    test('temizlik sonrası cihaz yeni kullanıcıya kayıtlıdır', () async {
      await seedUserData();
      await AccountSwitchGuard.apply(db, userA);
      await AccountSwitchGuard.apply(db, userB);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AccountSwitchGuard.lastUserKey), userB);
      // B tekrar girerse artık silme olmaz.
      expect(await AccountSwitchGuard.apply(db, userB), AccountSwitch.sameUser);
    });
  });
}
