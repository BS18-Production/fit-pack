import 'package:fit_pack/app.dart';
import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/auth/auth_gate.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_database.dart';

/// Açılış dumanı testi (E-16). Uygulamanın kökü — tema, router, çeviriler,
/// kapı ve sekme kabuğu — gerçekten ayağa kalkıyor mu?
///
/// Supabase testte başlatılmaz: `AuthGate` oturumsuz sayar, senkron pasif
/// kalır. Bu tam da uçağa binmiş kullanıcının (ağsız açılış) yoludur.
void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
  });

  tearDown(() => db.close());

  GoRouter routerOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
          as GoRouter;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const FitPackApp(),
      ),
    );
    // Açılışta profil okuması gibi gerçek G/Ç var: birkaç tur çevir.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('oturumsuz açılış: karşılama ekranı, hata yok', (tester) async {
    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
    // Kapı: oturum yokken karşılamadan başka yere gidilemez.
    expect(
      routerOf(tester).routerDelegate.currentConfiguration.uri.path,
      AppRoutes.welcome,
    );
    // Çeviriler kuruldu mu (ekranda gerçekten karşılama metni var mı).
    final context = tester.element(find.byType(Scaffold).first);
    expect(find.text(AppL10n.of(context).authWelcomeTitle), findsWidgets);
  });

  testWidgets('oturum yokken korumalı rotaya gidilemez', (tester) async {
    await pumpApp(tester);
    final router = routerOf(tester);

    router.go(AppRoutes.home);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.welcome,
      reason: 'gateRedirect kapıyı kapalı tutmalı',
    );
    expect(tester.takeException(), isNull);
  });

  test('kapı kararı açılışta hazır (bootstrap ağı beklemez)', () async {
    final gate = AuthGate(db);
    addTearDown(gate.dispose);

    await gate.bootstrap().timeout(const Duration(seconds: 5));

    expect(gate.signedIn, isFalse);
    expect(gate.onboarded, isFalse, reason: 'boş veritabanı → onboarding');
    expect(gate.busy, isFalse);
  });
}
