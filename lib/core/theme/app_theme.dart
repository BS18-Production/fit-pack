import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

/// Fit Pack tema sistemi — Material 3, "Pro" (Indigo/Teal), Manrope.
/// Dark öncelikli; light de tam destekli (sistem takip eder).
/// Font: Manrope (Claude Design onaylı tasarım fontu — yumuşak, modern,
/// tam Türkçe glyph desteği). Inter'den geçiş 2026-06-21.
class AppTheme {
  AppTheme._();

  static ThemeData get dark =>
      _build(AppColors.darkScheme, AppColors.darkSemantic,
          AppColors.darkScaffold, Brightness.dark);

  static ThemeData get light =>
      _build(AppColors.lightScheme, AppColors.lightSemantic,
          AppColors.lightScaffold, Brightness.light);

  static ThemeData _build(
    ColorScheme scheme,
    AppSemanticColors semantic,
    Color scaffold,
    Brightness brightness,
  ) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    // Manrope type scale — okunaklı, hiyerarşik. Tasarım (Claude Design)
    // ağırlıkları daha kalın kullanıyor (başlıklar 800); ona yaklaşıldı.
    final text = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.manrope(
          fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.manrope(
          fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineSmall: GoogleFonts.manrope(
          fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleLarge: GoogleFonts.manrope(fontSize: 19, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
      titleSmall: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
      bodyLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500),
      bodySmall: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w500),
      labelLarge: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
      labelMedium: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600),
      labelSmall: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600),
    ).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      textTheme: text,
      extensions: [semantic],
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: BorderSide(color: scheme.outlineVariant, width: 1),
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

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? AppColors.darkScaffold
            : AppColors.lightScaffold,
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
