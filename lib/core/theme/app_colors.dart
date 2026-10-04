import 'package:flutter/material.dart';

/// Performans Günlüğü: mat kömür, neon lime ve elektrik turuncusu.
/// Material rolleri ve semantik renkler tüm ekranlar için tek kaynaktır.
class AppColors {
  AppColors._();

  static const lime = Color(0xFFCCFF00);
  static const limeBright = Color(0xFFDDFF66);
  static const limeDeep = Color(0xFFA7D400);
  static const amber = Color(0xFFFF5E00);
  static const amberBright = Color(0xFFFF905C);
  static const onGradient = Color(0xFF171C03);

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: lime,
    onPrimary: onGradient,
    primaryContainer: Color(0xFF2C3515),
    onPrimaryContainer: Color(0xFFD5EF95),
    secondary: amber,
    onSecondary: Color(0xFF190900),
    secondaryContainer: Color(0xFF48291B),
    onSecondaryContainer: Color(0xFFFFCCB0),
    tertiary: Color(0xFFC7B58A),
    onTertiary: Color(0xFF2D260F),
    error: Color(0xFFFF7D88),
    onError: Color(0xFF2B1013),
    errorContainer: Color(0xFF52212A),
    onErrorContainer: Color(0xFFFFDADE),
    surface: Color(0xFF1B1B1B),
    onSurface: Color(0xFFF5F5F1),
    surfaceContainerLowest: Color(0xFF121212),
    surfaceContainerLow: Color(0xFF1C1C1C),
    surfaceContainer: Color(0xFF212121),
    surfaceContainerHigh: Color(0xFF282827),
    surfaceContainerHighest: Color(0xFF343431),
    onSurfaceVariant: Color(0xFFA5A5A0),
    outline: Color(0xFF444440),
    outlineVariant: Color(0xFF30302F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF5F5F1),
    onInverseSurface: Color(0xFF121212),
    inversePrimary: Color(0xFF526900),
  );

  // Açık görünümde küçük lime/turuncu metinler için koyu karşılıklar.
  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF526900),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE4F3AD),
    onPrimaryContainer: Color(0xFF293400),
    secondary: Color(0xFFB84300),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFDBC6),
    onSecondaryContainer: Color(0xFF52200A),
    tertiary: Color(0xFF806436),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFBC2937),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDADE),
    onErrorContainer: Color(0xFF52212A),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF23251F),
    surfaceContainerLowest: Color(0xFFF4F4EF),
    surfaceContainerLow: Color(0xFFF8F8F3),
    surfaceContainer: Color(0xFFEEEEE6),
    surfaceContainerHigh: Color(0xFFE8E9DF),
    surfaceContainerHighest: Color(0xFFDEDFD5),
    onSurfaceVariant: Color(0xFF626459),
    outline: Color(0xFFBFC2B5),
    outlineVariant: Color(0xFFDDDFD4),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF23251F),
    onInverseSurface: Color(0xFFF5F5F1),
    inversePrimary: lime,
  );

  static const darkSemantic = AppSemanticColors(
    success: lime,
    onSuccess: onGradient,
    warning: Color(0xFFFFB381),
    onWarning: Color(0xFF321700),
    info: Color(0xFFC2D0D3),
    onInfo: Color(0xFF172326),
    macroCalories: lime,
    macroProtein: lime,
    macroCarbs: amber,
    macroFat: Color(0xFFC7B58A),
  );

  static const lightSemantic = AppSemanticColors(
    success: Color(0xFF526900),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF9B4A0F),
    onWarning: Color(0xFFFFFFFF),
    info: Color(0xFF46636C),
    onInfo: Color(0xFFFFFFFF),
    macroCalories: Color(0xFF526900),
    macroProtein: Color(0xFF526900),
    macroCarbs: Color(0xFFB84300),
    macroFat: Color(0xFF806436),
  );
}

/// Ortak opak kart ve gezinme yüzeyleri. Cam hissi üst ışık ve gradyanla
/// verilir; liste kartları pahalı canlı blur gerektirmez.
class AppGlass {
  AppGlass._();
  static const darkFill = [Color(0xFF242424), Color(0xFF1B1B1B)];
  static const darkFillSolid = Color(0xFF212121);
  static const darkHairline = Color(0xFF30302F);
  static const darkHairlineTop = Color(0x28FFFFFF);
  static const darkShadow = Color(0x44000000);
  static const darkNavFill = Color(0xFF1C1C1C);
  static const lightFill = [Color(0xFFFFFFFF), Color(0xFFF8F9F2)];
  static const lightFillSolid = Color(0xFFFFFFFF);
  static const lightHairline = Color(0xFFE0E2D7);
  static const lightHairlineTop = Color(0xFFFFFFFF);
  static const lightShadow = Color(0x0F23251F);
  static const lightNavFill = Color(0xFFFCFCF7);
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
