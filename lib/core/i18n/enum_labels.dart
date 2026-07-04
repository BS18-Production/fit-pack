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
