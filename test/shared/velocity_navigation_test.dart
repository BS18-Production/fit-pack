import 'package:fit_pack/core/theme/app_colors.dart';
import 'package:fit_pack/core/theme/app_theme.dart';
import 'package:fit_pack/l10n/app_l10n.dart';
import 'package:fit_pack/shared/widgets/fitpack_icon.dart';
import 'package:fit_pack/shared/widgets/velocity_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget host(
    Widget child, {
    bool dark = true,
    double scale = 1,
    bool reducedMotion = false,
  }) {
    return MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: const Locale('tr'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(body: child),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reducedMotion,
        ),
        child: child!,
      ),
    );
  }

  testWidgets('sekme dokunuşları doğru hedefi seçer, tek kapsül vurgulanır', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            return VelocityNavigation(
              selectedIndex: selected,
              onSelected: (value) => setState(() => selected = value),
            );
          },
        ),
      ),
    );
    for (final index in [1, 2, 3, 0]) {
      await tester.tap(find.byKey(ValueKey('velocity-tab-$index')));
      await tester.pumpAndSettle();
      expect(selected, index);
      for (var i = 0; i < 4; i++) {
        final tab = tester.widget<AnimatedContainer>(
          find.byKey(ValueKey('velocity-tab-$i')),
        );
        expect(
          (tab.decoration! as BoxDecoration).color,
          i == index ? AppColors.lime : Colors.transparent,
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 pt, büyük metin ve iki temada erişilebilir sekmeler', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    try {
      for (final dark in [true, false]) {
        await tester.pumpWidget(
          host(
            VelocityNavigation(selectedIndex: 2, onSelected: (_) {}),
            dark: dark,
            scale: 1.6,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Beslenme'), findsNothing);
        expect(find.bySemanticsLabel('Beslenme'), findsOneWidget);
        expect(
          tester.getSemantics(find.bySemanticsLabel('Beslenme')),
          matchesSemantics(
            label: 'Beslenme',
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            isFocusable: true,
            hasFocusAction: true,
            hasTapAction: true,
          ),
        );
        for (var index = 0; index < 4; index++) {
          final size = tester.getSize(
            find.byKey(ValueKey('velocity-tab-$index')),
          );
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        expect(tester.takeException(), isNull);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('azaltılmış harekette sekme rengi anında değişir', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        VelocityNavigation(selectedIndex: 1, onSelected: (_) {}),
        reducedMotion: true,
      ),
    );
    await tester.pumpAndSettle();
    final tab = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('velocity-tab-1')),
    );
    expect(tab.duration, Duration.zero);
  });

  testWidgets(
    'vektör ailesinin tüm dosyaları çizilir ve ikon tema rengini kullanır',
    (tester) async {
      for (final glyph in FitPackGlyph.values) {
        await tester.pumpWidget(
          host(
            IconTheme(
              data: const IconThemeData(color: Colors.red, size: 26),
              child: FitPackIcon(glyph),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SvgPicture), findsOneWidget);
        final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
        expect(picture.width, 26);
        expect(
          picture.colorFilter,
          const ColorFilter.mode(Colors.red, BlendMode.srcIn),
        );
        expect(tester.takeException(), isNull, reason: glyph.asset);
      }
    },
  );
}
