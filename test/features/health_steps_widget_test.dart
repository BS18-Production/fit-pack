import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/data/database/app_database.dart';
import 'package:fit_pack/data/providers.dart';
import 'package:fit_pack/features/health/health_prefs.dart';
import 'package:fit_pack/features/health/health_settings_section.dart';
import 'package:fit_pack/features/health/step_mini.dart';
import 'package:fit_pack/features/health/step_providers.dart';
import 'package:fit_pack/features/health/step_source.dart';
import 'package:fit_pack/features/home/home_screen.dart';
import 'package:fit_pack/features/settings/settings_screen.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_step_source.dart';
import '../helpers/test_database.dart';

/// Gerçek provider'lar, bellek-içi veritabanı ve sahte platform kaynağı.
/// S-3/4/5/8/10 ve kullanıcı akışları; cihaz/simülatör kurulumu yok.
void main() {
  late AppDatabase db;
  late FakeStepSource source;
  late GlobalKey boundary;

  final mini = find.byKey(const ValueKey('health.stepMini'));
  final goalSetting = find.byKey(const ValueKey('health.goalSetting'));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = newTestDatabase();
    source = FakeStepSource();
    boundary = GlobalKey();
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  }

  Future<void> open(
    WidgetTester tester, {
    Widget screen = const HomeScreen(),
    String locale = 'tr',
    double width = 393,
    double scale = 1,
    bool dark = true,
  }) async {
    tester.view.physicalSize = Size(width * 2, 1704);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await db.userProfileDao.ensureProfile();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          stepSourceProvider.overrideWithValue(source),
        ],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.dark : AppTheme.light,
            locale: Locale(locale),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: screen,
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
    await tester.ensureVisible(finder);
    await settle(tester);
  }

  ProviderContainer container(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(
      find.byType(HomeScreen).evaluate().isNotEmpty
          ? find.byType(HomeScreen)
          : find.byType(HealthSettingsSection),
    ),
    listen: false,
  );

  void connected({int? goal}) => SharedPreferences.setMockInitialValues({
    'health_connected': true,
    'health_step_goal': ?goal,
  });

  Future<void> capture(WidgetTester tester, String name) async {
    final dir = Platform.environment['FITPACK_CAPTURE_DIR'];
    if (dir == null) return;
    await tester.runAsync(() async {
      await GoogleFonts.pendingFonts();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    await tester.pump();
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(dir).create(recursive: true);
      await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('unavailable: Ana Sayfa yalnız su/kilo gösterir, adım okunmaz', (
    tester,
  ) async {
    source.status = StepPlatformStatus.unavailable;
    await open(tester);
    await reveal(tester, find.text('Su'));
    expect(mini, findsNothing);
    expect(find.byType(StepMini), findsNothing);
    expect(source.requests, 0);
    expect(source.reads, isEmpty);
  });

  testWidgets(
    'notConnected: açıklama ihtiyaç anında, Şimdi değil izin istemez',
    (tester) async {
      await open(tester);
      await reveal(tester, mini);
      expect(find.text('Adımlarını gör'), findsOneWidget);
      expect(source.requests, 0);
      expect(source.reads, isEmpty);
      await tester.tap(mini);
      await settle(tester);
      expect(find.text("Adımların Ana Sayfa'da"), findsOneWidget);
      expect(find.text('Yalnız adım sayın okunur.'), findsOneWidget);
      expect(find.text('Adımların yalnız bu telefonda kalır.'), findsOneWidget);
      expect(
        find.text('Kalori hedefin değişmez, kimseyle paylaşılmaz.'),
        findsOneWidget,
      );
      expect(source.requests, 0);
      await tester.tap(find.text('Şimdi değil'));
      await settle(tester);
      expect(source.requests, 0);
      expect(container(tester).read(healthPrefsProvider).connected, isFalse);
    },
  );

  testWidgets('Bağlan: tek izin isteği, tercih kaydı ve Ana Sayfa tazelemesi', (
    tester,
  ) async {
    source.requestCompletion = Completer<bool>();
    await open(tester);
    await reveal(tester, mini);
    await tester.tap(mini);
    await settle(tester);
    await tester.tap(find.text('Bağlan'));
    await tester.pump();
    await tester.tap(find.text('Bağlan'));
    await tester.pump();
    expect(source.requests, 1);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Bağlan'))
          .onPressed,
      isNull,
    );
    source.requestCompletion!.complete(true);
    await settle(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('5.000'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getBool('health_connected'),
      isTrue,
    );
  });

  testWidgets('izin akışı başarısızsa hata gösterir ve yeniden denenebilir', (
    tester,
  ) async {
    source.requestResult = false;
    await open(tester);
    await reveal(tester, mini);
    await tester.tap(mini);
    await settle(tester);
    await tester.tap(find.text('Bağlan'));
    await settle(tester);
    expect(
      find.text('Bağlanamadık. Sağlık izinlerini kontrol edip yeniden dene.'),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(source.reads, isEmpty);
    source.requestResult = true;
    await tester.tap(find.text('Bağlan'));
    await settle(tester);
    expect(source.requests, 2);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets(
    'connected: binlik ayraçlı sayı, 7 okuma, hedef yoksa çizgi yok',
    (tester) async {
      connected();
      source.steps = (_) => 7200;
      await open(tester);
      await reveal(tester, mini);
      expect(find.text('7.200'), findsOneWidget);
      expect(find.byKey(const ValueKey('health.progress')), findsNothing);
      expect(source.reads, hasLength(7));
      expect(source.requests, 0);
    },
  );

  testWidgets('hedef aşılırsa ilerleme 1’de kırpılır', (tester) async {
    connected(goal: 8000);
    source.steps = (_) => 12000;
    await open(tester);
    await reveal(tester, mini);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('health.progress')),
    );
    expect(progress.value, 1);
    expect(find.text('12.000'), findsOneWidget);
  });

  testWidgets('verisiz bugün: —; önceki veri varsa noData değil, çizgi yok', (
    tester,
  ) async {
    connected(goal: 8000);
    final today = DateUtils.dateOnly(DateTime.now());
    source.steps = (day) => day == today ? 0 : 4000;
    await open(tester);
    await reveal(tester, mini);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('health.today'))).data,
      '—',
    );
    expect(find.text('Veri yok — Sağlık izinlerini kontrol et'), findsNothing);
    expect(find.byKey(const ValueKey('health.progress')), findsNothing);
  });

  testWidgets('noData: izin kontrolü metni, hücre ve grafikte 0 yazılmaz', (
    tester,
  ) async {
    connected(goal: 8000);
    source.steps = (_) => 0;
    await open(tester);
    await reveal(tester, mini);
    expect(
      find.text('Veri yok — Sağlık izinlerini kontrol et'),
      findsOneWidget,
    );
    expect(
      find.descendant(of: mini, matching: find.textContaining('0')),
      findsNothing,
    );
    await tester.tap(mini);
    await settle(tester);
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(
        of: sheet,
        matching: find.text('Veri yok — Sağlık izinlerini kontrol et'),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('health.average'))).data,
      '—',
    );
    expect(find.descendant(of: sheet, matching: find.text('0')), findsNothing);
    expect(
      find.descendant(of: sheet, matching: find.text('0 adım')),
      findsNothing,
    );
    expect(
      tester
          .widget<BarChart>(find.byType(BarChart))
          .data
          .barGroups
          .every((g) => g.barRods.isEmpty),
      isTrue,
    );
  });

  testWidgets('grafik: boş gün çubuksuz, ortalama yalnız verili günlerden', (
    tester,
  ) async {
    connected();
    final today = DateUtils.dateOnly(DateTime.now());
    source.steps = (day) => day == today
        ? 4000
        : day == DateTime(today.year, today.month, today.day - 2)
        ? 2000
        : null;
    await open(tester);
    await reveal(tester, mini);
    await tester.tap(mini);
    await settle(tester);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('health.average'))).data,
      '3.000 adım',
    );
    final groups = tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barGroups;
    expect(groups, hasLength(7));
    expect(groups[5].barRods, isEmpty);
    expect(groups[4].barRods.single.toY, 2000);
    expect(groups[6].barRods.single.toY, 4000);
    expect(find.text('—'), findsNWidgets(5));
  });

  testWidgets('needsInstall: Health Connect kurma eylemi, izin isteği yok', (
    tester,
  ) async {
    source.status = StepPlatformStatus.needsInstall;
    await open(tester);
    await reveal(tester, mini);
    expect(find.text("Health Connect'i kur"), findsOneWidget);
    await tester.tap(mini);
    await settle(tester);
    expect(source.installs, 1);
    expect(source.requests, 0);
    expect(source.reads, isEmpty);
  });

  testWidgets('kurulum açılmazsa anlaşılır hata gösterilir', (tester) async {
    source.status = StepPlatformStatus.needsInstall;
    source.failInstall = true;
    await open(tester);
    await reveal(tester, mini);
    await tester.tap(mini);
    await settle(tester);
    expect(
      find.text('Health Connect açılamadı. Yeniden dene.'),
      findsOneWidget,
    );
  });

  testWidgets('okuma hatası: sayı yerine — ve yeniden deneme', (tester) async {
    connected();
    source.failRead = true;
    await open(tester);
    await reveal(tester, mini);
    expect(find.text('Adımlar okunamadı. Yeniden dene.'), findsOneWidget);
    await tester.tap(mini);
    await settle(tester);
    source.failRead = false;
    await tester.tap(find.text('Yeniden dene'));
    await settle(tester);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('health.average'))).data,
      '5.000 adım',
    );
  });

  testWidgets('Ayarlar: unavailable olduğunda Sağlık bölümü yok', (
    tester,
  ) async {
    source.status = StepPlatformStatus.unavailable;
    await open(tester, screen: const SettingsScreen());
    await reveal(tester, find.text('Fit Pack'));
    expect(find.byType(HealthSettingsSection), findsOneWidget);
    expect(find.byKey(const ValueKey('health.settings')), findsNothing);
  });

  testWidgets(
    'Ayarlar: boş başlangıç, hedef kaydedilir ve provider tazelenir',
    (tester) async {
      connected();
      await open(tester, screen: const SettingsScreen());
      await reveal(tester, goalSetting);
      expect(find.text('Hedef yok'), findsOneWidget);
      await tester.tap(goalSetting);
      await settle(tester);
      final input = find.byKey(const ValueKey('health.goalInput'));
      expect(tester.widget<TextField>(input).controller!.text, isEmpty);
      await tester.enterText(input, '8500');
      await tester.tap(find.text('Kaydet'));
      await settle(tester);
      expect(
        (await SharedPreferences.getInstance()).getInt('health_step_goal'),
        8500,
      );
      expect(container(tester).read(healthPrefsProvider).stepGoal, 8500);
      expect(find.text('8.500 adım'), findsOneWidget);
      expect(
        (await container(tester).read(stepWeekProvider.future))!.goal,
        8500,
      );
    },
  );

  for (final text in ['', '0']) {
    testWidgets('Ayarlar: hedef ${text.isEmpty ? "boş" : "0"} ise kaldırılır', (
      tester,
    ) async {
      connected(goal: 9000);
      await open(tester, screen: const SettingsScreen());
      await reveal(tester, goalSetting);
      await tester.tap(goalSetting);
      await settle(tester);
      await tester.enterText(
        find.byKey(const ValueKey('health.goalInput')),
        text,
      );
      await tester.tap(find.text('Kaydet'));
      await settle(tester);
      expect(
        (await SharedPreferences.getInstance()).getInt('health_step_goal'),
        isNull,
      );
      expect(container(tester).read(healthPrefsProvider).stepGoal, isNull);
      expect(find.text('Hedef yok'), findsOneWidget);
    });
  }

  testWidgets('Ayarlar: hedef düzenleme iptal edilince değer korunur', (
    tester,
  ) async {
    connected(goal: 9000);
    await open(tester, screen: const SettingsScreen());
    await reveal(tester, goalSetting);
    await tester.tap(goalSetting);
    await settle(tester);
    await tester.enterText(
      find.byKey(const ValueKey('health.goalInput')),
      '5000',
    );
    await tester.tap(find.text('İptal'));
    await settle(tester);
    expect(
      (await SharedPreferences.getInstance()).getInt('health_step_goal'),
      9000,
    );
  });

  testWidgets('Ayarlar: bağlantıyı kesme notu, tercih temizliği ve durum', (
    tester,
  ) async {
    connected(goal: 9000);
    await open(tester, screen: const SettingsScreen());
    final disconnect = find.byKey(const ValueKey('health.disconnect'));
    await reveal(tester, disconnect);
    expect(
      find.text(
        'İzni ayrıca Sağlık veya Health Connect ayarlarından kaldırabilirsin.',
      ),
      findsOneWidget,
    );
    await tester.tap(disconnect);
    await settle(tester);
    expect(find.text('Bağlı değil · adımlarını gör'), findsOneWidget);
    expect(disconnect, findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('health_connected'), isFalse);
    expect(prefs.getInt('health_step_goal'), 9000);
    expect(await container(tester).read(stepWeekProvider.future), isNull);
  });

  testWidgets('İngilizce: adım sayısı etkin locale ile biçimlenir', (
    tester,
  ) async {
    connected();
    source.steps = (_) => 7200;
    await open(tester, locale: 'en');
    await reveal(tester, mini);
    expect(find.text('7,200'), findsOneWidget);
    await tester.tap(mini);
    await settle(tester);
    expect(find.text('7,200 steps'), findsWidgets);
  });

  for (final scenario in [
    (name: 'dark-tr', width: 393.0, scale: 1.0, locale: 'tr', dark: true),
    (name: 'light-en', width: 393.0, scale: 1.0, locale: 'en', dark: false),
    (name: 'narrow-tr', width: 320.0, scale: 1.6, locale: 'tr', dark: true),
    (name: 'narrow-en', width: 320.0, scale: 1.6, locale: 'en', dark: false),
    (name: 'wide-tr', width: 800.0, scale: 1.0, locale: 'tr', dark: true),
  ]) {
    testWidgets(
      'sağlık render ${scenario.name}: hücre/grafik/ayarlar/izin taşmaz',
      (tester) async {
        connected(goal: 8000);
        source.steps = (_) => 12500;
        await db.userProfileDao.ensureProfile();
        await db.bodyDao.insertMeasurement(
          BodyMeasurementsCompanion.insert(
            date: DateTime.now(),
            weightKg: const Value(82.5),
          ),
        );
        await open(
          tester,
          width: scenario.width,
          scale: scenario.scale,
          locale: scenario.locale,
          dark: scenario.dark,
        );
        await reveal(tester, mini);
        await capture(tester, '${scenario.name}-home');
        await tester.tap(mini);
        await settle(tester);
        await capture(tester, '${scenario.name}-week');
        // Yeni ekran/scope: render'ların birbirine ait durumları taşıması yok.
        await tester.pumpWidget(const SizedBox.shrink());
        await open(
          tester,
          screen: const Scaffold(
            body: SingleChildScrollView(child: HealthSettingsSection()),
          ),
          width: scenario.width,
          scale: scenario.scale,
          locale: scenario.locale,
          dark: scenario.dark,
        );
        await reveal(tester, goalSetting);
        await capture(tester, '${scenario.name}-settings');
        await tester.tap(goalSetting);
        await settle(tester);
        await capture(tester, '${scenario.name}-goal');
        await tester.pumpWidget(const SizedBox.shrink());
        SharedPreferences.setMockInitialValues({});
        await open(
          tester,
          width: scenario.width,
          scale: scenario.scale,
          locale: scenario.locale,
          dark: scenario.dark,
        );
        await reveal(tester, mini);
        await tester.tap(mini);
        await settle(tester);
        await capture(tester, '${scenario.name}-permission');
      },
    );
  }
}
