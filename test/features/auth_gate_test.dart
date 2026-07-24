import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/features/auth/account_switch.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
