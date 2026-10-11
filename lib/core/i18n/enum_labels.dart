import 'package:flutter/material.dart';
import '../../l10n/app_l10n.dart';

/// Veritabanı/enum anahtarlarının locale'e göre görünen etiketleri (docs/14).
/// Anahtarlar İngilizce sabit (`'male'`, `'moderate'`, ...); etiket dile göre
/// çözülür. Önceki `activityLabelsTr` / `themeModeLabelTr` yerine gelir.

/// Aktiflik düzeyi anahtar sırası (seçici + onboarding için).
const activityLevelKeys = [
  'sedentary',
  'light',
  'moderate',
  'active',
  'veryActive',
];

String activityLabel(AppL10n l, String? key) => switch (key) {
  'sedentary' => l.activitySedentary,
  'light' => l.activityLight,
  'moderate' => l.activityModerate,
  'active' => l.activityActive,
  'veryActive' => l.activityVeryActive,
  _ => '—',
};

String genderLabel(AppL10n l, String? key) => switch (key) {
  'male' => l.settingsGenderMale,
  'female' => l.settingsGenderFemale,
  _ => '—',
};

String themeModeLabel(AppL10n l, ThemeMode m) => switch (m) {
  ThemeMode.system => l.themeSystem,
  ThemeMode.light => l.themeLight,
  ThemeMode.dark => l.themeDark,
};

/// Dil seçici etiketi. `null` locale = "Sistem (cihaz)".
String localeLabel(AppL10n l, Locale? locale) => switch (locale?.languageCode) {
  'en' => l.languageEnglish,
  'tr' => l.languageTurkish,
  _ => l.languageSystem,
};

String muscleLabel(AppL10n l, String key) => switch (key) {
  'chest' => l.assistantMuscleChest,
  'upper_chest' => l.assistantMuscleUpperChest,
  'back' => l.assistantMuscleBack,
  'shoulders' => l.assistantMuscleShoulders,
  'front_delt' => l.assistantMuscleFrontDelt,
  'rear_delt' => l.assistantMuscleRearDelt,
  'biceps' => l.assistantMuscleBiceps,
  'triceps' => l.assistantMuscleTriceps,
  'forearms' => l.assistantMuscleForearms,
  'legs' => l.assistantMuscleLegs,
  'quads' => l.assistantMuscleQuads,
  'hamstrings' => l.assistantMuscleHamstrings,
  'glutes' => l.assistantMuscleGlutes,
  'calves' => l.assistantMuscleCalves,
  'core' => l.assistantMuscleCore,
  'full_body' => l.assistantMuscleFullBody,
  'other' => l.assistantMuscleOther,
  _ => l.assistantMuscleOther,
};
