import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS ses oturumunu bırakır — kısılan müzik eski seviyesine döner.
///
/// Mola geri sayımı müziği kısarak (duck) çalar. audioplayers ses bitince
/// oturumu kapatmadığı için müzik kısık kalıyor, ancak uygulama alta alınınca
/// düzeliyordu (Samet, 2026-10-07). Yerel taraf: `AppDelegate.swift`.
/// Android'de ses odağını oynatıcı kendisi bırakır → işlem yok.
class AudioSessionRelease {
  static const channel = MethodChannel('fit_pack/audio_session');

  const AudioSessionRelease();

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> call() async {
    if (!_supported) return;
    try {
      await channel.invokeMethod<void>('release');
    } catch (_) {
      // En iyi çaba: oturum zaten kapalıysa ya da kanal yoksa önemsiz;
      // en kötü ihtimalle eski davranış (müzik alta alınınca düzelir).
    }
  }
}
