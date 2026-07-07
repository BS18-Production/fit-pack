import 'package:flutter/material.dart';

/// Fit Pack renk sistemi — "Pro" kimliği (Indigo/Teal).
///
/// İki katman:
/// 1. [ColorScheme] — Material 3'ün standart rolleri (primary, surface, ...).
///    Widget'lar `Theme.of(context).colorScheme.X` ile okur.
/// 2. [AppSemanticColors] — M3'te rolü olmayan ama uygulamaya özgü renkler
///    (success, warning, info, makro renkleri). `ThemeExtension` ile taşınır;
///    `Theme.of(context).extension<AppSemanticColors>()!` ile okunur.
///
/// KURAL: Ekranlarda `Colors.blue/grey/...` HARDCODE EDİLMEZ. Renk hep
/// buradan gelir → dark/light tutarlılığı + tek noktadan kontrol.
class AppColors {
  AppColors._();

  // ─── Çekirdek palet (marka) ──────────────────────────────────────
  static const indigo = Color(0xFF6366F1);
  static const indigoBright = Color(0xFF818CF8);
  static const indigoDeep = Color(0xFF4F46E5);
  static const teal = Color(0xFF14B8A6);
  static const tealBright = Color(0xFF2DD4BF);

  /// İndigo gradient yüzeylerin (CTA kartları, GradientButton) üstündeki
  /// içerik rengi. Gradient tema-bağımsız sabit olduğundan bu da sabit beyaz —
  /// `context.colors.onPrimary` DEĞİL (o light temada değişebilir). Tek yerden
  /// yönetilir ki tüm gradient yüzeyler tutarlı kalsın (L-03).
  static const onGradient = Color(0xFFFFFFFF);

  // ─── DARK (öncelikli) ────────────────────────────────────────────
  static const _dBg = Color(0xFF101218); // scaffold
  static const _dSurface = Color(0xFF1B1E27); // kart
  static const _dSurfaceHi = Color(0xFF232734); // yükseltilmiş yüzey
  static const _dSurfaceInput = Color(0xFF262A38); // input dolgu
  static const _dOutline = Color(0xFF2F3442);
  static const _dOnSurface = Color(0xFFE7E9EE);
  static const _dOnSurfaceVar = Color(0xFF9BA1B0); // ikincil metin

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: indigo,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF3730A3),
    onPrimaryContainer: Color(0xFFE0E1FF),
    secondary: teal,
    onSecondary: Color(0xFF03201D),
    secondaryContainer: Color(0xFF0F5249),
    onSecondaryContainer: Color(0xFFB8FFF3),
    tertiary: indigoBright,
    onTertiary: Color(0xFF1A1B4B),
    error: Color(0xFFEF4444),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFFE2E2),
    surface: _dSurface,
    onSurface: _dOnSurface,
    surfaceContainerLowest: _dBg,
    surfaceContainerLow: _dSurface,
    surfaceContainer: _dSurfaceHi,
    surfaceContainerHigh: _dSurfaceInput,
    surfaceContainerHighest: _dSurfaceInput,
    onSurfaceVariant: _dOnSurfaceVar,
    outline: _dOutline,
    outlineVariant: Color(0xFF252A36),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: _dOnSurface,
    onInverseSurface: _dBg,
    inversePrimary: indigoDeep,
  );

  // ─── LIGHT ───────────────────────────────────────────────────────
  static const _lBg = Color(0xFFF6F7F9);
  static const _lSurface = Color(0xFFFFFFFF);
  static const _lSurfaceHi = Color(0xFFEEF0F4);
  static const _lOutline = Color(0xFFD8DCE4);
  static const _lOnSurface = Color(0xFF1A1C22);
  static const _lOnSurfaceVar = Color(0xFF5A6072);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: indigoDeep,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE0E1FF),
    onPrimaryContainer: Color(0xFF1A1B4B),
    secondary: Color(0xFF0D9488),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFB8FFF3),
    onSecondaryContainer: Color(0xFF03201D),
    tertiary: indigo,
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: _lSurface,
    onSurface: _lOnSurface,
    surfaceContainerLowest: _lBg,
    surfaceContainerLow: _lBg,
    surfaceContainer: _lSurfaceHi,
    surfaceContainerHigh: _lSurfaceHi,
    surfaceContainerHighest: _lSurfaceHi,
    onSurfaceVariant: _lOnSurfaceVar,
    outline: _lOutline,
    outlineVariant: Color(0xFFE7E9EE),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: _lOnSurface,
    onInverseSurface: _lSurface,
    inversePrimary: indigoBright,
  );

  // ─── Semantik ek renkler (ThemeExtension) ────────────────────────
  static const AppSemanticColors darkSemantic = AppSemanticColors(
    success: Color(0xFF22C55E),
    onSuccess: Color(0xFF03210F),
    warning: Color(0xFFF59E0B),
    onWarning: Color(0xFF2A1A00),
    info: Color(0xFF38BDF8),
    onInfo: Color(0xFF04212E),
    macroCalories: indigo,
    macroProtein: teal,
    macroCarbs: Color(0xFF38BDF8),
    macroFat: Color(0xFFFBBF24),
  );

  static const AppSemanticColors lightSemantic = AppSemanticColors(
    success: Color(0xFF16A34A),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFD97706),
    onWarning: Color(0xFFFFFFFF),
    info: Color(0xFF0284C7),
    onInfo: Color(0xFFFFFFFF),
    macroCalories: indigoDeep,
    macroProtein: Color(0xFF0D9488),
    macroCarbs: Color(0xFF0284C7),
    macroFat: Color(0xFFD97706),
  );
}

/// Liquid glass yüzey token'ları (premium reskin — 2026-07).
///
/// Tek doğruluk kaynağı: hem `shared/widgets/glass.dart` (GlassBackground /
/// GlassCard) hem tema (`app_theme.dart` — Card/NavigationBar) buradan okur.
/// Böylece "cam" görünümü uygulamanın her yerinde aynı kalır.
class AppGlass {
  AppGlass._();

  // ── DARK ──
  /// Kart dolgu gradyanı (%8 → %3 beyaz).
  static const darkFill = [Color(0x14FFFFFF), Color(0x08FFFFFF)];

  /// Gradyansız yüzeyler (tema `Card`ı) için tek renk dolgu — gradyanın
  /// ortalaması (%6 beyaz). GlassCard ile yan yana dursa bile uyumlu.
  static const darkFillSolid = Color(0x0FFFFFFF);
  static const darkHairline = Color(0x1FFFFFFF); // kenarlık %12
  static const darkHairlineTop = Color(0x3AFFFFFF); // üst parlama %23
  static const darkShadow = Color(0x66000000);
  static const darkBgBase = [Color(0xFF0C0E15), Color(0xFF0A0B12)];
  static const darkGlowIndigo = Color(0x4D6366F1); // indigo %30 ışıma
  static const darkGlowTeal = Color(0x2E14B8A6); // teal %18 ışıma
  /// Alt gezinme çubuğu buzlu dolgusu (blur arkasında).
  static const darkNavFill = Color(0xB80A0C12);

  // ── LIGHT ──
  static const lightFill = [Color(0xE6FFFFFF), Color(0xB3FFFFFF)];
  static const lightFillSolid = Color(0xCCFFFFFF); // %80 beyaz (buzlu)
  static const lightHairline = Color(0xCCFFFFFF);
  static const lightHairlineTop = Color(0xF2FFFFFF);
  static const lightShadow = Color(0x1A1E2240); // yumuşak lacivert gölge
  static const lightBgBase = [Color(0xFFEFF1F6), Color(0xFFE6E9F1)];
  static const lightGlowIndigo = Color(0x243B82F6);
  static const lightGlowTeal = Color(0x1F14B8A6);
  static const lightNavFill = Color(0xC2F4F5F9);
}

/// Material 3 [ColorScheme]'de karşılığı olmayan, uygulamaya özgü renkler.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;
  final Color macroCalories;
  final Color macroProtein;
  final Color macroCarbs;
  final Color macroFat;

  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    required this.macroCalories,
    required this.macroProtein,
    required this.macroCarbs,
    required this.macroFat,
  });

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? macroCalories,
    Color? macroProtein,
    Color? macroCarbs,
    Color? macroFat,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      macroCalories: macroCalories ?? this.macroCalories,
      macroProtein: macroProtein ?? this.macroProtein,
      macroCarbs: macroCarbs ?? this.macroCarbs,
      macroFat: macroFat ?? this.macroFat,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      macroCalories: Color.lerp(macroCalories, other.macroCalories, t)!,
      macroProtein: Color.lerp(macroProtein, other.macroProtein, t)!,
      macroCarbs: Color.lerp(macroCarbs, other.macroCarbs, t)!,
      macroFat: Color.lerp(macroFat, other.macroFat, t)!,
    );
  }
}

/// Kısa erişim: `context.colors` ve `context.semantic`.
extension AppColorsX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>()!;
  TextTheme get texts => Theme.of(this).textTheme;
}
