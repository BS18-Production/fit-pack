import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama dili (docs/14). `null` = cihaz dilini takip et (desteklenmeyen
/// diller `en`'e düşer — supportedLocales'te `en` ilk). Kullanıcı Ayarlar'dan
/// zorla `en`/`tr` seçebilir; seçim `shared_preferences`'te kalıcı.
///
/// `theme_mode_provider` ile aynı desen: build() kayıtlı tercihi asenkron
/// yükler, yoksa `null` (sistem) kalır. `app.dart` bunu izler →
/// `MaterialApp.locale`.
class LocaleNotifier extends Notifier<Locale?> {
  static const _key = 'app_locale';

  /// Kullanıcının elle seçebileceği diller (Sistem hariç).
  static const supported = [Locale('en'), Locale('tr')];

  @override
  Locale? build() {
    _load();
    return null; // varsayılan: cihazı takip et
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved.isNotEmpty) state = Locale(saved);
  }

  /// [locale] `null` ise "Sistem"e döner (kayıt silinir).
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
