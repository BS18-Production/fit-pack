import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mola sayacının bir tikte vermesi gereken işaret (G-1).
enum RestCue { none, tick, done }

/// Geri sayımın tık verdiği son saniyeler.
const restCountdownFrom = 3;

/// Sayaç çoktan dolmuşsa (uygulama arka plandan döndü) bitiş sesi ÇALINMAZ —
/// o anı bildirim karşıladı; dönüşte geç bip kafa karıştırır. Sayaç saniyede
/// bir tıkladığı için doğal gecikme bu eşiğin altında kalır.
const restDoneLateMs = 1500;

/// Kalan süre [prevLeft] → [left] (saniye) geçişinde hangi işaret verilmeli.
/// [overdueMs]: bitiş anının ne kadar geride kaldığı (left == 0 iken).
///
/// - 3, 2, 1'e inerken kısa tık (atlanan saniye olsa da bir kez).
/// - 0'a inerken bitiş — yalnız zamanında yakalandıysa.
/// - Süre artırıldığında (+15 sn) ya da yeni mola başladığında sessiz.
RestCue restCueFor({
  required int prevLeft,
  required int left,
  required int overdueMs,
}) {
  if (left >= prevLeft) return RestCue.none;
  if (left <= 0) {
    return overdueMs <= restDoneLateMs ? RestCue.done : RestCue.none;
  }
  return left <= restCountdownFrom ? RestCue.tick : RestCue.none;
}

/// Uygulama geneli ses + titreşim geri bildirimi (G-1). Ekranlar
/// `HapticFeedback`'i doğrudan çağırmak yerine buradan geçer — ileride seans
/// bitişi, su hedefi gibi anlar aynı tercihleri ve aynı sesleri kullanır.
///
/// **Ses politikası:** medya ses seviyesi; müziği kısıp (duck) üstüne çalar,
/// kulaklık takılıysa kulaklıktan gelir. Telefonun sessiz anahtarını dinlemez
/// — salonda telefon çoğunlukla sessizde, sesin tam gerektiği yer orası.
/// İstemeyen Ayarlar → Bildirimler → "Mola sonu sesi"ni kapatır.
class FeedbackService {
  static const _tickAsset = 'sounds/rest_tick.wav';
  static const _doneAsset = 'sounds/rest_done.wav';

  static final _audioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      // Navigasyon uyarısı gibi: medya sesi, sessiz modda da duyulur.
      usageType: AndroidUsageType.assistanceNavigationGuidance,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.duckOthers},
    ),
  );

  AudioPlayer? _tick;
  AudioPlayer? _done;
  Future<void>? _ready;

  // Kurulum başarısızsa bir sonraki denemede yeniden kurulsun.
  Future<void> _ensureReady() => _ready ??= _init().catchError((Object e) {
    _ready = null;
    throw e;
  });

  Future<void> _init() async {
    // iOS ses bağlamı uygulama geneli; Android'de yeni oynatıcıların
    // varsayılanı olur. Oynatıcılar bundan SONRA kurulur.
    await AudioPlayer.global.setAudioContext(_audioContext);
    final tick = AudioPlayer();
    final done = AudioPlayer();
    for (final p in [tick, done]) {
      await p.setReleaseMode(ReleaseMode.stop);
      if (defaultTargetPlatform == TargetPlatform.android) {
        await p.setAudioContext(_audioContext);
      }
    }
    await tick.setSource(AssetSource(_tickAsset));
    await done.setSource(AssetSource(_doneAsset));
    _tick = tick;
    _done = done;
  }

  /// Seans ekranı açılınca çağrılır — ilk tıkta yükleme gecikmesi olmasın.
  void warmUp() => unawaited(_ensureReady().catchError((_) {}));

  /// Mola sayacı işareti. Titreşim her zaman, ses [sound] açıksa.
  void restCue(RestCue cue, {required bool sound}) {
    switch (cue) {
      case RestCue.none:
        return;
      case RestCue.tick:
        if (sound) _play(() => _tick);
      case RestCue.done:
        // Cepteki telefon için belirgin titreşim (hafif "tık" değil).
        HapticFeedback.vibrate();
        if (sound) _play(() => _done);
    }
  }

  /// Set tamamlandı.
  void setDone() => HapticFeedback.lightImpact();

  /// Kişisel rekor kırıldı.
  void record() => HapticFeedback.heavyImpact();

  void _play(AudioPlayer? Function() player) {
    unawaited(() async {
      try {
        await _ensureReady();
        final p = player();
        if (p == null) return;
        await p.stop();
        await p.resume();
      } catch (_) {
        // Ses en iyi çaba: çalınamazsa (ses servisi yok, dosya açılamadı)
        // titreşim zaten verildi; her saniye hata mesajı göstermek seansı
        // bozar. Bilinçli olarak sessiz geçilir.
      }
    }());
  }

  Future<void> dispose() async {
    await _tick?.dispose();
    await _done?.dispose();
  }
}

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final service = FeedbackService();
  ref.onDispose(service.dispose);
  return service;
});
