import 'dart:io';
import 'dart:ui' as ui;

import 'package:fit_pack/core/feedback/feedback_service.dart';
import 'package:fit_pack/core/feedback/rest_sound.dart';
import 'package:fit_pack/core/notifications/notification_service.dart';
import 'package:fit_pack/core/onboarding/first_run_hints.dart';
import 'package:fit_pack/core/router/app_router.dart';
import 'package:fit_pack/core/router/app_routes.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/health/step_providers.dart';
import 'package:fit_pack/features/health/step_source.dart';
import 'package:fit_pack/features/update/app_version_gate.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:fit_pack/shared/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/design_fixture.dart';
import '../helpers/fake_step_source.dart';
import '../helpers/test_database.dart';

/// Aktif seans ekranının görsel + erişilebilirlik kabulü (deneyim araştırması
/// 12 v2 §3, Faz 1b): neon_design_test'in 76 görüntüsü bu ekranı açmıyordu.
/// Dört düzende (koyu/açık, 393 ve 320 + büyük yazı) set tablosu ve mola
/// çubuğu taşmadan çizilir ve Flutter'ın dört erişilebilirlik kılavuzundan
/// geçer. `FITPACK_CAPTURE_DIR` verilirse PNG yazılır.

class _SilentFeedback extends FeedbackService {
  @override
  void warmUp([RestSound sound = RestSound.fallback]) {}
  @override
  void playCountdown({int offsetMs = 0, RestSound? sound}) {}
  @override
  void stopCountdown() {}
  @override
  void restDone() {}
  @override
  void setDone() {}
  @override
  void record() {}
}

class _NoNotifications extends NotificationService {
  @override
  Future<void> scheduleRestDone({
    required DateTime at,
    required String title,
    required String body,
    String? earlyTitle,
    String? earlyBody,
    RestSound? sound,
  }) async {}
  @override
  Future<void> cancelRestDone() async {}
  @override
  Future<bool> requestPermission() async => false;
}

void _mockPlatform() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMessageCodec();
  for (final name in ['toggle', 'isEnabled']) {
    m.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.$name',
      (_) async =>
          codec.encodeMessage(<Object?>[name == 'isEnabled' ? false : null]),
    );
  }
  for (final ch in [
    'fit_pack/live_activity',
    'fit_pack/rest_timer',
    'fit_pack/audio_session',
  ]) {
    m.setMockMethodCallHandler(MethodChannel(ch), (c) async => false);
  }
}

void main() {
  for (final sc in [
    (name: 'dark-tr', dark: true, locale: 'tr', width: 393.0, scale: 1.0),
    (name: 'light-tr', dark: false, locale: 'tr', width: 393.0, scale: 1.0),
    (name: 'light-en', dark: false, locale: 'en', width: 393.0, scale: 1.0),
    (name: 'narrow-tr', dark: true, locale: 'tr', width: 320.0, scale: 1.3),
    (name: 'narrow-light-tr', dark: false, locale: 'tr', width: 320.0, scale: 1.3),
    (name: 'large-en', dark: true, locale: 'en', width: 320.0, scale: 1.6),
  ]) {
    testWidgets('aktif seans ${sc.name}: taşma yok, erişilebilirlik kılavuzları',
        (tester) async {
      final handle = tester.ensureSemantics();
      _mockPlatform();
      SharedPreferences.setMockInitialValues({});
      await FirstRunHints.initialize(onboarded: true);
      final db = newTestDatabase();
      await seedDesignFixture(db);
      final gate = DesignFixtureGate(db);
      final update = UpdateGate(AppVersionGate(
          currentBuild: () async => 1, fetchMinimum: () async => null));
      final router = createAppRouter(gate: gate, updateGate: update);
      final boundary = GlobalKey();
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (d) {
        errors.add(d);
        previous?.call(d);
      };
      addTearDown(() => FlutterError.onError = previous);
      tester.view.physicalSize = Size(sc.width * 2, 1704);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
        gate.dispose();
        update.dispose();
        await db.close();
      });

      Future<void> settle(String where) async {
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull,
            reason: '$where\n${errors.map((e) => e.toString()).join('\n')}');
        expect(errors, isEmpty,
            reason: '$where\n${errors.map((e) => e.toString()).join('\n')}');
      }

      Future<void> capture(String name) async {
        final dir = Platform.environment['FITPACK_CAPTURE_DIR'];
        if (dir == null) return;
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(dir).create(recursive: true);
          await File('$dir/session-${sc.name}-$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<void> guidelines(String where) async {
        for (final g in [
          androidTapTargetGuideline,
          iOSTapTargetGuideline,
          labeledTapTargetGuideline,
          textContrastGuideline,
        ]) {
          final e = await g.evaluate(tester);
          expect(e.passed, isTrue, reason: '$where · ${g.description}\n${e.reason}');
        }
      }

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          stepSourceProvider.overrideWithValue(
              FakeStepSource(status: StepPlatformStatus.unavailable)),
          feedbackServiceProvider.overrideWithValue(_SilentFeedback()),
          notificationServiceProvider.overrideWithValue(_NoNotifications()),
        ],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: sc.dark ? AppTheme.dark : AppTheme.light,
            locale: Locale(sc.locale),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(sc.scale)),
              child: GlassBackground(child: child!),
            ),
          ),
        ),
      ));
      await tester.runAsync(() async {
        await GoogleFonts.pendingFonts();
        for (final font in [
          ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
          ('packages/phosphor_flutter/PhosphorRegular',
              'packages/phosphor_flutter/lib/fonts/Phosphor.ttf'),
          ('packages/phosphor_flutter/PhosphorFill',
              'packages/phosphor_flutter/lib/fonts/Phosphor-Fill.ttf'),
        ]) {
          await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
        }
      });
      await settle('açılış');
      router.push(AppRoutes.workoutActiveRoutine(1));
      await settle('aktif seans');
      await capture('table');
      await guidelines('aktif seans');

      // İlk seti tamamla → mola çubuğu altta; satırlar yerinden oynamaz.
      final next = find.byKey(const ValueKey('set.complete.1'));
      final before = tester.getTopLeft(next);
      await tester.tap(find.byKey(const ValueKey('set.complete.0')));
      await settle('mola');
      expect(find.byKey(const ValueKey('rest.skip')), findsOneWidget);
      expect(tester.getTopLeft(next), before,
          reason: 'mola başlayınca sıradaki ✓ yer değiştirmemeli (A5)');
      await capture('rest');
      await guidelines('mola');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      handle.dispose();
    });
  }
}
