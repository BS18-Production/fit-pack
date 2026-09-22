import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';
import 'package:fit_pack/features/update/app_version_gate.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asgari sürüm kapısı (docs/23 §3).
///
/// Kilitlenen kural: kapı **yalnız sunucu açıkça "çok eskisin" dediğinde**
/// kapanır. Ağ yokluğu, eksik tablo, bozuk cevap ya da okunamayan build
/// numarası kapıyı KAPATMAZ — kullanıcı uçakta ya da sinyalsiz salonda kendi
/// verisinden edilmemeli (docs/18 Kural 1).
void main() {
  AppVersionGate gate({
    int build = 5,
    ({int minBuild, String? message})? minimum,
    Object? fetchThrows,
    Object? buildThrows,
  }) =>
      AppVersionGate(
        currentBuild: () async {
          if (buildThrows != null) throw buildThrows;
          return build;
        },
        fetchMinimum: () async {
          if (fetchThrows != null) throw fetchThrows;
          return minimum;
        },
      );

  group('kapı ne zaman kapanır', () {
    test('build asgarinin ALTINDAysa kapanır', () async {
      final r = await gate(
        build: 4,
        minimum: (minBuild: 5, message: null),
      ).check();
      expect(r.blocked, isTrue);
      expect(r.minBuild, 5);
    });

    test('build asgariye EŞİTse kapanmaz', () async {
      final r = await gate(
        build: 5,
        minimum: (minBuild: 5, message: null),
      ).check();
      expect(r.blocked, isFalse);
    });

    test('build asgarinin ÜSTÜndeyse kapanmaz', () async {
      final r = await gate(
        build: 9,
        minimum: (minBuild: 5, message: null),
      ).check();
      expect(r.blocked, isFalse);
    });

    test('sunucu mesajı taşınır', () async {
      final r = await gate(
        build: 1,
        minimum: (minBuild: 5, message: 'Yeni senkron için güncelle'),
      ).check();
      expect(r.message, 'Yeni senkron için güncelle');
    });
  });

  group('kapı ne zaman KAPANMAZ (docs/18 Kural 1)', () {
    test('sunucuda kayıt yoksa', () async {
      expect((await gate(build: 1, minimum: null).check()).blocked, isFalse);
    });

    test('sunucuya ulaşılamıyorsa', () async {
      final r = await gate(build: 1, fetchThrows: Exception('ağ yok')).check();
      expect(r.blocked, isFalse,
          reason: 'uçakta kullanıcı kendi verisinden edilmemeli');
    });

    test('build numarası okunamıyorsa', () async {
      final r = await gate(
        build: 0,
        minimum: (minBuild: 5, message: null),
      ).check();
      expect(r.blocked, isFalse,
          reason: 'kendi hatamız yüzünden kullanıcıyı dışarı atmayız');
    });

    test('build okuması patlarsa', () async {
      final r = await gate(
        buildThrows: Exception('platform yok'),
        minimum: (minBuild: 5, message: null),
      ).check();
      expect(r.blocked, isFalse);
    });
  });

  group('UpdateGate — yönlendiriciye haber', () {
    test('durum değişince dinleyici uyarılır', () async {
      final g = UpdateGate(gate(build: 1, minimum: (minBuild: 5, message: null)));
      var bildirim = 0;
      g.addListener(() => bildirim++);

      await g.refresh();

      expect(g.blocked, isTrue);
      expect(bildirim, 1);
    });

    test('durum değişmezse gereksiz yeniden çizim yok', () async {
      final g = UpdateGate(gate(build: 9, minimum: (minBuild: 5, message: null)));
      var bildirim = 0;
      g.addListener(() => bildirim++);

      await g.refresh();
      await g.refresh();

      expect(g.blocked, isFalse);
      expect(bildirim, 0);
    });
  });

  group('yönlendirme (gateRedirect)', () {
    test('kapı kapalıysa her yerden güncelleme ekranına', () {
      for (final loc in [AppRoutes.home, AppRoutes.welcome, AppRoutes.auth]) {
        expect(
          gateRedirect(
            location: loc,
            signedIn: true,
            onboarded: true,
            updateRequired: true,
          ),
          AppRoutes.updateRequired,
          reason: '$loc desteklenmeyen sürümde açılmamalı',
        );
      }
    });

    test('oturum açık olmasa bile kapı geçerli', () {
      expect(
        gateRedirect(
          location: AppRoutes.welcome,
          signedIn: false,
          onboarded: false,
          updateRequired: true,
        ),
        AppRoutes.updateRequired,
        reason: 'eski istemci giriş ekranında takılıp kalmamalı',
      );
    });

    test('güncelleme ekranındayken yönlendirme yok', () {
      expect(
        gateRedirect(
          location: AppRoutes.updateRequired,
          signedIn: true,
          onboarded: true,
          updateRequired: true,
        ),
        isNull,
      );
    });

    test('sürüm kapısı hesap kapılarının ÖNÜNDE', () {
      // İkisi birden doğruyken sürüm kazanmalı: eski istemcinin hesap
      // kontrolü de güvenilmez.
      expect(
        gateRedirect(
          location: AppRoutes.home,
          signedIn: true,
          onboarded: true,
          accountError: true,
          pendingConflict: true,
          updateRequired: true,
        ),
        AppRoutes.updateRequired,
      );
    });

    test('kapı açıkken olağan yönlendirme bozulmaz', () {
      expect(
        gateRedirect(
          location: AppRoutes.home,
          signedIn: true,
          onboarded: true,
        ),
        isNull,
      );
    });
  });
}
