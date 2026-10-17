import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'workout_export.dart';

/// Sağlık bağlantısı tercihleri (docs/39 S-8): kullanıcı bağlanmayı seçti mi,
/// günlük adım hedefi. Şema yerine `SharedPreferences` — Faz 1 tablo
/// gerektirmez. Hesap değişiminde [clear] ile silinir (hesaplar arası sızma
/// yok).
/// **Sağlık dönemi** (Codex P1, 2026-10-11): hesap değişimi ya da sağlık
/// rızasının geri alınması sayacı artırır. Başladığı dönem değişmiş bir
/// içe aktarma / antrenman yazma işi hiçbir şey yazmaz (eski hesabın işi yeni
/// hesaba damgalanmasın); [HealthPrefsNotifier] diskten yeniden okur
/// (bellekte eski tercih kalmasın).
final healthEpoch = ValueNotifier<int>(0);

class HealthPrefs {
  /// Kullanıcı Ana Sayfa'daki "Bağlan" ile izin akışını başlattı. iOS okuma
  /// iznini bildirmediği için "bağlı" bilgisinin tek kaynağı budur.
  final bool connected;

  /// Günlük adım hedefi; `null` = konmadı (varsayılan, karar 3).
  final int? stepGoal;

  /// docs/44: canlı seanslar Sağlık'a yazılsın mı (opt-in).
  final bool writeWorkouts;

  const HealthPrefs({
    this.connected = false,
    this.stepGoal,
    this.writeWorkouts = false,
  });

  static const _connectedKey = 'health_connected';
  static const _stepGoalKey = 'health_step_goal';
  static const _writeWorkoutsKey = 'health_write_workouts';

  /// Hesap değişimi temizliği (`account_switch.dart`).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_connectedKey);
    await prefs.remove(_stepGoalKey);
    await prefs.remove(_writeWorkoutsKey);
    await WorkoutOutbox.clear(); // docs/44: bekleyen yazmalar da bu hesabın
    await prefs.remove(importFloorKey);
    healthEpoch.value++;
  }

  /// Rıza geri alınıp içe alınanlar silinince bu andan önceki tartı örnekleri
  /// yeniden içe alınmaz (Samet kararı: yeniden rızada yalnız yeni örnekler).
  static const importFloorKey = 'health_import_floor_ms';

  static Future<DateTime?> importFloor() async {
    final ms = (await SharedPreferences.getInstance()).getInt(importFloorKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> setImportFloor(DateTime t) async =>
      (await SharedPreferences.getInstance()).setInt(
        importFloorKey,
        t.millisecondsSinceEpoch,
      );

  /// Antrenman yazma tercihi — bellekteki sağlayıcıya değil DİSKE bakar
  /// (hesap değişiminden sonra bellekte eski değer kalabilir).
  static Future<bool> writeWorkoutsOnDisk() async =>
      (await SharedPreferences.getInstance()).getBool(_writeWorkoutsKey) ??
      false;
}

class HealthPrefsNotifier extends Notifier<HealthPrefs> {
  @override
  HealthPrefs build() {
    healthEpoch.addListener(_load);
    ref.onDispose(() => healthEpoch.removeListener(_load));
    _load();
    return const HealthPrefs();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getInt(HealthPrefs._stepGoalKey);
    state = HealthPrefs(
      connected: prefs.getBool(HealthPrefs._connectedKey) ?? false,
      stepGoal: (goal != null && goal > 0) ? goal : null,
      writeWorkouts: prefs.getBool(HealthPrefs._writeWorkoutsKey) ?? false,
    );
  }

  Future<void> setConnected(bool v) async {
    state = HealthPrefs(
      connected: v,
      stepGoal: state.stepGoal,
      writeWorkouts: state.writeWorkouts,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(HealthPrefs._connectedKey, v);
  }

  /// `null` ya da ≤ 0 hedefi kaldırır.
  Future<void> setStepGoal(int? goal) async {
    final g = (goal != null && goal > 0) ? goal : null;
    state = HealthPrefs(
      connected: state.connected,
      stepGoal: g,
      writeWorkouts: state.writeWorkouts,
    );
    final prefs = await SharedPreferences.getInstance();
    if (g == null) {
      await prefs.remove(HealthPrefs._stepGoalKey);
    } else {
      await prefs.setInt(HealthPrefs._stepGoalKey, g);
    }
  }

  /// docs/44: canlı seansları Sağlık'a yaz (opt-in).
  Future<void> setWriteWorkouts(bool v) async {
    state = HealthPrefs(
      connected: state.connected,
      stepGoal: state.stepGoal,
      writeWorkouts: v,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(HealthPrefs._writeWorkoutsKey, v);
  }
}

final healthPrefsProvider = NotifierProvider<HealthPrefsNotifier, HealthPrefs>(
  HealthPrefsNotifier.new,
);
