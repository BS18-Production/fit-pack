import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimens.dart';

/// Sıcak Günlük paleti yalnız Beslenme dalına uygulanır.
/// Ana Sayfa özeti ve ortak Velocity gezinme kendi temasını korur.
class NutritionTheme {
  NutritionTheme._();
  static const summaryRadius = BorderRadius.all(Radius.circular(22));
  static const suggestionRadius = BorderRadius.all(Radius.circular(14));
  static const ringSize = 166.0;
  static const largeRingSize = 192.0;
  static const ringDuration = Duration(milliseconds: 360);
  static const ringStroke = 11.0;
  static const darkSummaryStart = Color(0xFF2E291F);
  static const lightSummaryStart = Color(0xFFFFFAF0);
  static const darkRingEnd = Color(0xFFE6C485);
  static const lightRingEnd = Color(0xFFAD7A2D);
  static const darkTrack = Color(0xFF494636);
  static const lightTrack = Color(0xFFE5E0D3);

  static ThemeData of(ThemeData parent) {
    final dark = parent.brightness == Brightness.dark;
    final c = parent.colorScheme.copyWith(
      primary: dark ? AppColors.lime : const Color(0xFF576D1B),
      onPrimary: dark ? const Color(0xFF1B2307) : const Color(0xFFFFFEF5),
      primaryContainer: dark
          ? const Color(0xFF343C21)
          : const Color(0xFFEAF1D7),
      secondary: dark ? const Color(0xFFDFB77B) : const Color(0xFFA46323),
      secondaryContainer: dark
          ? const Color(0xFF3A3020)
          : const Color(0xFFF8ECD6),
      onSecondaryContainer: dark
          ? const Color(0xFFDFB77B)
          : const Color(0xFFA46323),
      surface: dark ? const Color(0xFF25231C) : const Color(0xFFFFFDF8),
      surfaceContainerLowest: dark
          ? const Color(0xFF171611)
          : const Color(0xFFFAF7F0),
      surfaceContainerHigh: dark
          ? const Color(0xFF302D24)
          : const Color(0xFFF2ECE0),
      surfaceContainerHighest: dark ? darkTrack : lightTrack,
      onSurface: dark ? const Color(0xFFF5F1E7) : const Color(0xFF2C2B23),
      onSurfaceVariant: dark
          ? const Color(0xFFB6B09F)
          : const Color(0xFF696656),
      outlineVariant: dark ? const Color(0xFF373429) : const Color(0xFFE4DED1),
    );
    final semantic = parent.extension<AppSemanticColors>()!.copyWith(
      macroCalories: c.primary,
      macroProtein: c.primary,
      macroCarbs: dark ? const Color(0xFFE8A184) : const Color(0xFFAB5E43),
      macroFat: dark ? const Color(0xFFBCABD0) : const Color(0xFF7A6490),
    );
    final text = parent.textTheme.apply(
      bodyColor: c.onSurface,
      displayColor: c.onSurface,
    );
    return parent.copyWith(
      colorScheme: c,
      scaffoldBackgroundColor: c.surfaceContainerLowest,
      textTheme: text,
      extensions: [
        ...parent.extensions.values.where((e) => e is! AppSemanticColors),
        semantic,
      ],
      appBarTheme: parent.appBarTheme.copyWith(
        backgroundColor: c.surfaceContainerLowest,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: c.secondary),
      ),
      dividerTheme: parent.dividerTheme.copyWith(color: c.outlineVariant),
      iconTheme: IconThemeData(color: c.onSurfaceVariant),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.secondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size(0, AppNavigation.primaryButtonHeight),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.brControl,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.onSurfaceVariant,
          minimumSize: const Size.square(AppA11y.minTapTarget),
        ),
      ),
      cardTheme: parent.cardTheme.copyWith(
        color: c.surface,
        shadowColor: c.shadow.withValues(alpha: .08),
      ),
      bottomSheetTheme: parent.bottomSheetTheme.copyWith(
        backgroundColor: c.surface,
      ),
    );
  }
}
