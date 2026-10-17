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
///
/// Codex P1 (2026-10-11): `enqueue` / `flush` / `clear` tek sıraya alınır
/// ([_serial]) — iki `flush` aynı seansı iki kez yazamaz, eski kutu kopyası yeni
/// kaydı ezemez, temizlikten sonra süren iş kutuyu diriltmez. `writing`
/// işaretine bu çalıştırmanın kimliği ([_runId]) yazılır: başka çalıştırmadan
/// kalan `writing` = yazma sırasında kapanmış → atlanır (eksik > çift).
class WorkoutOutbox {
  static const _key = 'health_workout_outbox';
  static final _runId = DateTime.now().microsecondsSinceEpoch.toString();
  static Future<void> _tail = Future.value();

  static Future<T> _serial<T>(Future<T> Function() job) {
    final run = _tail.then((_) => job());
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }

  /// uid → {state: pending|writing, run, w: seans}
  static Map<String, Map<String, dynamic>> _load(SharedPreferences p) {
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

  static Future<void> enqueue(WorkoutExport w) => _serial(() async {
    final p = await SharedPreferences.getInstance();
    final box = _load(p);
    box.putIfAbsent(w.uid, () => {'state': 'pending', 'w': w.toJson()});
    await _save(p, box);
  });

  /// Bekleyenleri yazar. Dönen: başarıyla yazılan sayısı. [stillAllowed]
  /// her yazmadan önce sorulur (hesap değiştiyse dur).
  static Future<int> flush(WorkoutSink sink, {bool Function()? stillAllowed}) =>
      _serial(() async {
        final p = await SharedPreferences.getInstance();
        var written = 0;
        for (final uid in _load(p).keys.toList()) {
          if (stillAllowed != null && !stillAllowed()) break;
          // Her adımda kutu diskten yeniden okunur — eski kopya kaydedilmez.
          final box = _load(p);
          final entry = box[uid];
          if (entry == null) continue;
          if (entry['state'] == 'writing' && entry['run'] != _runId) {
            box.remove(uid); // önceki çalıştırmada yazma sırasında kapanmış
            await _save(p, box);
            continue;
          }
          entry['state'] = 'writing';
          entry['run'] = _runId;
          await _save(p, box); // yazmadan ÖNCE işaretle
          final ok = await sink.write(
            WorkoutExport.fromJson(
              Map<String, dynamic>.from(entry['w'] as Map),
            ),
          );
          final after = _load(p);
          if (ok) {
            after.remove(uid);
            written++;
          } else if (after[uid] != null) {
            after[uid]!['state'] = 'pending'; // net başarısızlık: sonra dene
          }
          await _save(p, after);
        }
        return written;
      });

  static Future<int> pendingCount() =>
      _serial(() async => _load(await SharedPreferences.getInstance()).length);

  static Future<void> clear() =>
      _serial(() async => (await SharedPreferences.getInstance()).remove(_key));
}
