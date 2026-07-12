import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// Fit Pack tema sistemi — Material 3, "Pro" (Indigo/Teal), Plus Jakarta Sans.
/// Dark öncelikli; light de tam destekli (sistem takip eder).
/// Font: Plus Jakarta Sans (premium/glass reskin fontu — geometrik-hümanist,
/// modern, tam Türkçe glyph desteği). Geçiş: Inter → Manrope → Plus Jakarta
/// Sans (2026-07, premium yön).
class AppTheme {
  AppTheme._();

  static ThemeData get dark =>
      _build(AppColors.darkScheme, AppColors.darkSemantic, Brightness.dark);

  static ThemeData get light =>
      _build(AppColors.lightScheme, AppColors.lightSemantic, Brightness.light);

  static ThemeData _build(
    ColorScheme scheme,
    AppSemanticColors semantic,
    Brightness brightness,
  ) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    // Plus Jakarta Sans type scale — okunaklı, hiyerarşik. Başlıklar kalın
    // (800); premium/glass yönüne uygun geometrik-hümanist karakter.
    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleLarge: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
      titleSmall: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
      bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500),
      labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
      labelMedium: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600),
    ).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    // Liquid glass zemin: GlassBackground TÜM ekranların arkasına
    // MaterialApp.builder ile bir kez çizilir (app.dart). Scaffold ve AppBar
    // bu yüzden transparan — ışıma her ekranda kesintisiz görünür.
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: text,
      extensions: [semantic],
      splashFactory: InkSparkle.splashFactory,

      // Push edilen sayfa geçişi — platformun kendi dili (Samet 2026-07-12:
      // tam ekran sağdan-sola kaydırma Android'de yabancı/rahatsız edici):
      // • Android: _FadeOverPageTransitionsBuilder (aşağıda) — FadeForwards
      //   dili (yumuşak fade + süptil ileri hareket) ama alttaki route'a HİÇ
      //   animasyon uygulanmaz. FadeForwards'ın kendisi elendi çünkü
      //   delegatedTransition'ı dönülen sekmeyi de soldurup kaydırıyordu →
      //   glow'lu/gölgeli glass zemin pop sırasında "geç yükleniyor" gibi
      //   görünüyordu (Samet 2026-07-12 geri bildirimi).
      // • iOS: Cupertino yatay kaydırma (orada platform standardı budur).
      // Sekmeler NoTransitionPage kullandığı için etkilenmez (anlık kalır).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeOverPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
        // Hazır .light/.dark sabitleri gesture çubuğunu SİYAH boyar —
        // edge-to-edge glass zemin için ikisi de transparan kalmalı.
        systemOverlayStyle: (brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
      ),

      // Tema `Card`ı = ucuz cam yüzey (blur'suz GlassCard eşdeğeri): yarı
      // saydam dolgu + ince hairline. GlassBackground'un ışıması altından
      // sızar → GlassCard ile yan yana tutarlı. Blur gereken kahraman
      // kartlarda GlassCard kullanılır (shared/widgets/glass.dart).
      cardTheme: CardThemeData(
        color: brightness == Brightness.dark
            ? AppGlass.darkFillSolid
            : AppGlass.lightFillSolid,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: BorderSide(
            color: brightness == Brightness.dark
                ? AppGlass.darkHairline
                : AppGlass.lightHairline,
            width: 1,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppA11y.minTapTarget),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, AppA11y.minTapTarget),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, AppA11y.minTapTarget),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, AppA11y.minTapTarget),
          textStyle: text.labelLarge,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppA11y.minTapTarget, AppA11y.minTapTarget),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),

      // Arka plan transparan: buzlu dolgu + blur, AppShell'deki sarmalayıcıda
      // (içerik çubuğun ALTINDAN akar — extendBody).
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelMedium?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: AppIconSize.md,
          );
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(text.labelMedium),
          minimumSize: const WidgetStatePropertyAll(
              Size(0, AppA11y.minTapTarget)),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.surfaceContainerHigh),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? scheme.onPrimary
                  : scheme.onSurfaceVariant),
          side: WidgetStatePropertyAll(
              BorderSide(color: scheme.outlineVariant)),
          shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: AppRadius.brSm)),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
            color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
        circularTrackColor: Colors.transparent,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHigh,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.16),
        trackHeight: 4,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.surfaceContainerHigh),
      ),
    );
  }
}

/// Android push geçişi: "üstüne fade" — yeni sayfa yumuşak fade + süptil
/// ileri hareketle üste gelir; ALTTAKİ route'a hiç animasyon uygulanmaz
/// (delegatedTransition bilerek null). Böylece push'lu sayfadan sekmeye
/// dönüşte glow'lu/gölgeli glass zemin ANINDA net durur — FadeForwards'ın
/// alttaki sayfayı da soldurması "ışıklar geç yükleniyor" hissi veriyordu
/// (Samet 2026-07-12). Süre: Material varsayılanı (300ms) — FadeForwards'ın
/// 450ms'inden kısa, dönüş daha çevik hissettirir.
class _FadeOverPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeOverPageTransitionsBuilder();

  // Alttaki route'a uygulanan geçiş YOK — dönülen sekme hep tam opak/net.
  @override
  DelegatedTransitionBuilder? get delegatedTransition => null;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Push'ta yumuşak varış (easeOutCubic); pop'ta hızlı kaybolma
    // (easeInCubic tersten) → alttaki sekme bir an önce tam görünür.
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0), // süptil ileri hareket (M3 dili)
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
