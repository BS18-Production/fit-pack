import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dinlenme sonu uyarısının Android yerel servisi (docs/25).
///
/// Android'de dinlenme boyunca bir ön plan servisi çalışır: bildirimde canlı
/// geri sayım, bitişten 3 sn önce tek parça geri sayım sesi, bitişte titreşim.
/// Uygulama alttayken ya da ekran kapalıyken de zamanında çalar — Dart
/// zamanlayıcısı üreticinin arka plan dondurucusuna takılıyordu.
///
/// [start] `true` dönerse ses ve titreşim servisten gelir; ekran Dart'ta
/// ÇALMAZ (iki kaynak üst üste binerdi). `false` (iOS, test, servis
/// başlatılamadı) → ekran eski yolla, uygulama içinden çalar.
class RestAlarm {
  static const _channel = MethodChannel('fit_pack/rest_timer');

  /// Testlerde ve Android dışında yerel servis yok.
  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> start({
    required DateTime deadline,
    required bool sound,
    required String title,
    required String doneTitle,
    required String doneBody,
  }) async {
    if (!_supported) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('start', {
        'deadlineMs': deadline.millisecondsSinceEpoch,
        'sound': sound,
        'title': title,
        'doneTitle': doneTitle,
        'doneBody': doneBody,
      });
      return ok ?? false;
    } catch (_) {
      // Ör. Android 12+ arka plandan ön plan servisi başlatma yasağı ya da
      // eklenti yok: uygulama içi yedek yol çalışır.
      return false;
    }
  }

  Future<void> stop() => _call('stop');

  /// "Dinlenme bitti" bildirimini kaldır (uygulama öne geldi).
  Future<void> dismissDone() => _call('dismissDone');

  Future<void> _call(String method) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>(method);
    } catch (_) {
      // En iyi çaba: servis zaten kapalıysa ya da kanal yoksa önemsiz.
    }
  }
}

final restAlarmProvider = Provider<RestAlarm>((ref) => RestAlarm());
