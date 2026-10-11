import 'dart:convert';
import 'dart:io' show Platform;

import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **Antrenmanı Sağlık'a yazma** (docs/44). Seansı bitiren cihaz, tercih
/// açıksa canlı seansı Apple Sağlık / Health Connect'e yazar. Kalori yazılmaz,
/// saat uydurulmaz (App Store 5.1.3-ii).

/// Yazılacak seans (Fit Pack verisinden; Sağlık'tan okunmaz).
class WorkoutExport {
  final String uid;
  final DateTime start;
  final DateTime end;
  final String title;
  final bool isCardio;

  const WorkoutExport({
    required this.uid,
    required this.start,
    required this.end,
    required this.title,
    required this.isCardio,
  });

  Map<String, Object> toJson() => {
    'uid': uid,
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'title': title,
    'cardio': isCardio,
  };

  static WorkoutExport fromJson(Map<String, dynamic> j) => WorkoutExport(
    uid: j['uid'] as String,
    start: DateTime.fromMillisecondsSinceEpoch(j['start'] as int),
    end: DateTime.fromMillisecondsSinceEpoch(j['end'] as int),
    title: j['title'] as String,
    isCardio: j['cardio'] as bool,
  );
}

abstract class WorkoutSink {
  Future<bool> requestWriteAccess();
  Future<bool> write(WorkoutExport w);
}

class HealthWorkoutSink implements WorkoutSink {
  HealthWorkoutSink({Health? health}) : _health = health ?? Health();
  final Health _health;
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> requestWriteAccess() async {
    await _ensureConfigured();
    try {
      return await _health.requestAuthorization(
        [HealthDataType.WORKOUT],
        permissions: [HealthDataAccess.WRITE],
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> write(WorkoutExport w) async {
    await _ensureConfigured();
    final type = w.isCardio
        ? (Platform.isIOS
              ? HealthWorkoutActivityType.MIXED_CARDIO
              : HealthWorkoutActivityType.OTHER)
        : (Platform.isIOS
              ? HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING
              : HealthWorkoutActivityType.STRENGTH_TRAINING);
    try {
      return await _health.writeWorkoutData(
        activityType: type,
        start: w.start,
        end: w.end,
        title: w.title,
        recordingMethod: RecordingMethod.manual,
      );
    } catch (_) {
      return false;
    }
  }
}

/// Giden kutusu (H-3) — `SharedPreferences`'ta, hesap değişiminde silinir.
class WorkoutOutbox {
  static const _key = 'health_workout_outbox';

  /// uid → {durum: pending|writing, seans}
  static Future<Map<String, Map<String, dynamic>>> _load(
    SharedPreferences p,
  ) async {
    final raw = p.getString(_key);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {}; // bozuk kayıt: kutuyu sıfırla, uygulama durmasın
    }
  }

  static Future<void> _save(
    SharedPreferences p,
    Map<String, Map<String, dynamic>> box,
  ) => p.setString(_key, jsonEncode(box));

  static Future<void> enqueue(WorkoutExport w) async {
    final p = await SharedPreferences.getInstance();
    final box = await _load(p);
    box.putIfAbsent(w.uid, () => {'state': 'pending', 'w': w.toJson()});
    await _save(p, box);
  }

  /// Bekleyenleri yazar. Dönen: başarıyla yazılan sayısı. `writing`te kalmış
  /// (önceki denemede yazma sırasında kapanmış) olanlar atlanıp silinir —
  /// eksik kayıt, çift kayıttan iyidir.
  static Future<int> flush(WorkoutSink sink) async {
    final p = await SharedPreferences.getInstance();
    final box = await _load(p);
    var written = 0;
    for (final uid in box.keys.toList()) {
      final entry = box[uid]!;
      if (entry['state'] == 'writing') {
        box.remove(uid);
        await _save(p, box);
        continue;
      }
      entry['state'] = 'writing';
      await _save(p, box); // yazmadan ÖNCE işaretle
      final ok = await sink.write(
        WorkoutExport.fromJson(Map<String, dynamic>.from(entry['w'] as Map)),
      );
      if (ok) {
        box.remove(uid);
        written++;
      } else {
        entry['state'] = 'pending'; // net başarısızlık: sonra yeniden dene
      }
      await _save(p, box);
    }
    return written;
  }

  static Future<int> pendingCount() async =>
      (await _load(await SharedPreferences.getInstance())).length;

  static Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}
