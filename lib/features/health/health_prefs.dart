import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sağlık bağlantısı tercihleri (docs/39 S-8): kullanıcı bağlanmayı seçti mi,
/// günlük adım hedefi. Şema yerine `SharedPreferences` — Faz 1 tablo
/// gerektirmez. Hesap değişiminde [clear] ile silinir (hesaplar arası sızma
/// yok).
class HealthPrefs {
  /// Kullanıcı Ana Sayfa'daki "Bağlan" ile izin akışını başlattı. iOS okuma
  /// iznini bildirmediği için "bağlı" bilgisinin tek kaynağı budur.
  final bool connected;

  /// Günlük adım hedefi; `null` = konmadı (varsayılan, karar 3).
  final int? stepGoal;

  const HealthPrefs({this.connected = false, this.stepGoal});

  static const _connectedKey = 'health_connected';
  static const _stepGoalKey = 'health_step_goal';

  /// Hesap değişimi temizliği (`account_switch.dart`).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_connectedKey);
    await prefs.remove(_stepGoalKey);
  }
}

class HealthPrefsNotifier extends Notifier<HealthPrefs> {
  @override
  HealthPrefs build() {
    _load();
    return const HealthPrefs();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getInt(HealthPrefs._stepGoalKey);
    state = HealthPrefs(
      connected: prefs.getBool(HealthPrefs._connectedKey) ?? false,
      stepGoal: (goal != null && goal > 0) ? goal : null,
    );
  }

  Future<void> setConnected(bool v) async {
    state = HealthPrefs(connected: v, stepGoal: state.stepGoal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(HealthPrefs._connectedKey, v);
  }

  /// `null` ya da ≤ 0 hedefi kaldırır.
  Future<void> setStepGoal(int? goal) async {
    final g = (goal != null && goal > 0) ? goal : null;
    state = HealthPrefs(connected: state.connected, stepGoal: g);
    final prefs = await SharedPreferences.getInstance();
    if (g == null) {
      await prefs.remove(HealthPrefs._stepGoalKey);
    } else {
      await prefs.setInt(HealthPrefs._stepGoalKey, g);
    }
  }
}

final healthPrefsProvider = NotifierProvider<HealthPrefsNotifier, HealthPrefs>(
  HealthPrefsNotifier.new,
);
