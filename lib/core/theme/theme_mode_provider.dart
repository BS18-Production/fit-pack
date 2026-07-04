import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının tema tercihi (Sistem / Açık / Koyu).
///
/// Ayarlar'dan değişir, `shared_preferences`'te kalıcı. Varsayılan: **sistem**
/// (cihazın açık/koyu ayarını takip eder). Kullanıcı isterse zorla açık ya da
/// koyu seçer. `app.dart` bu değeri izler → `MaterialApp.themeMode`.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _load(); // kayıtlı tercih varsa asenkron uygular (yoksa sistem kalır)
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) state = _parse(saved);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  static ThemeMode _parse(String s) => ThemeMode.values.firstWhere(
        (m) => m.name == s,
        orElse: () => ThemeMode.system,
      );
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// Görünen etiketler docs/14 ile lokalize edildi → `core/i18n/enum_labels.dart`
// `themeModeLabel(l, mode)`.
