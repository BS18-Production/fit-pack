import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_session_release.dart';

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

/// Bir sonraki mola tıkının ne kadar sonra atılacağı (ms) — [leftMs] kalan
/// süre.
///
/// **Neden sabit 1000 değil.** `Timer.periodic` bir sonraki tıkı callback
/// BİTTİKTEN sonra kuruyor; `setState` + ses çalma süresi kadar gecikme her
/// turda **birikiyor**. Kalan süre `ceil` ile saniyeye yuvarlandığı için
/// birikim 1 sn'yi geçtiğinde bir saniye tamamen **atlanıyor**: sayı 3'ten
/// 1'e düşüyor, o saniyenin sesi hiç çıkmıyor ve kalan sesler geri sayımın
/// gerçek anlarına oturmuyor. Birikim sonda en büyük olduğu için bozulma
/// son saniyelerde duyuluyordu.
///
/// Bunun yerine gecikme her seferinde **hedeften yeniden** hesaplanır: tık
/// geç kalsa bile bir sonraki tık tam saniye sınırına oturur, kayma birikmez.
///
/// Örnek: 3450 ms kaldıysa 450 ms sonra tıkla (kalan tam 3000 olur); sonra
/// 1000'er ms. Tık 40 ms geç düşerse kalan 1960 olur → sonraki gecikme 960 ms
/// → yine tam sınıra oturur.
int restTickDelayMs(int leftMs) {
  if (leftMs <= 0) return 0;
  final kalan = leftMs % 1000;
  return kalan == 0 ? 1000 : kalan;
}

/// Tek parça geri sayım dosyasında bitiş sesinin başladığı an (ms).
/// `rest_countdown.wav`: 0, 1, 2. sn'de tık, 3. sn'de bitiş.
const restCountdownLeadMs = 3000;

/// Geri sayım sesinin ne zaman ve dosyanın neresinden başlayacağı.
/// [leftMs]: bitişe kalan süre. Süre bitmişse null.
///
/// - 3 sn'den fazla kaldıysa: `leftMs - 3000` sonra, baştan.
/// - Daha az kaldıysa (−15 sn ile kısaltıldı): hemen, dosyanın içinden —
///   ör. 1200 ms kaldıysa 1800. ms'den (3. tıktan hemen önce).
({int delayMs, int offsetMs})? countdownPlan(int leftMs) {
  if (leftMs <= 0) return null;
  if (leftMs > restCountdownLeadMs) {
    return (delayMs: leftMs - restCountdownLeadMs, offsetMs: 0);
  }
  return (delayMs: 0, offsetMs: restCountdownLeadMs - leftMs);
}

/// Uygulama geneli ses + titreşim geri bildirimi (G-1). Ekranlar
/// `HapticFeedback`'i doğrudan çağırmak yerine buradan geçer — ileride seans
/// bitişi, su hedefi gibi anlar aynı tercihleri ve aynı sesleri kullanır.
///
/// **Ses politikası:** medya ses seviyesi; müziği kısıp (duck) üstüne çalar,
/// kulaklık takılıysa kulaklıktan gelir. Telefonun sessiz anahtarını dinlemez
/// — salonda telefon çoğunlukla sessizde, sesin tam gerektiği yer orası.
/// İstemeyen Ayarlar → Bildirimler → "Mola sonu sesi"ni kapatır.
///
/// **Android'de mola sesi buradan çalmaz** — yerel servis çalar
/// (bkz. `rest_alarm.dart`, docs/25). Bu yol iOS'ta ve servis
/// başlatılamadığında kullanılır.
class FeedbackService {
  static const _countdownAsset = 'sounds/rest_countdown.wav';

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

  final AudioSessionRelease _releaseSession;

  FeedbackService({AudioSessionRelease release = const AudioSessionRelease()})
      : _releaseSession = release;

  AudioPlayer? _countdown;
  Future<void>? _ready;
  StreamSubscription<void>? _completeSub;
  // Her çalışta artar: eski bir "bırak" isteği yeni başlayan sesi kesmesin.
  int _playGen = 0;

  // Kurulum başarısızsa bir sonraki denemede yeniden kurulsun.
  Future<void> _ensureReady() => _ready ??= _init().catchError((Object e) {
    _ready = null;
    throw e;
  });

  Future<void> _init() async {
    // iOS ses bağlamı uygulama geneli; Android'de yeni oynatıcıların
    // varsayılanı olur. Oynatıcı bundan SONRA kurulur.
    await AudioPlayer.global.setAudioContext(_audioContext);
    final p = AudioPlayer();
    await p.setReleaseMode(ReleaseMode.stop);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await p.setAudioContext(_audioContext);
    }
    await p.setSource(AssetSource(_countdownAsset));
    _completeSub = p.onPlayerComplete.listen((_) => _release(_playGen));
    _countdown = p;
  }

  /// Seans ekranı açılınca çağrılır — ilk çalışta yükleme gecikmesi olmasın.
  void warmUp() => unawaited(_ensureReady().catchError((_) {}));

  /// Geri sayım sesini [offsetMs]'den başlatır (bkz. [countdownPlan]).
  /// Tek dosya olduğu için tıklar arası aralık oynatıcı gecikmesinden
  /// etkilenmez — eski "her saniye durdur/başlat" yolunda 2. ve 3. bip
  /// kayıyordu (Samet, 2026-09-30).
  void playCountdown({int offsetMs = 0}) {
    _playGen++;
    unawaited(() async {
      try {
        await _ensureReady();
        final p = _countdown;
        if (p == null) return;
        await p.stop();
        if (offsetMs > 0) await p.seek(Duration(milliseconds: offsetMs));
        await p.resume();
      } catch (_) {
        // Ses en iyi çaba: çalınamazsa (ses servisi yok, dosya açılamadı)
        // titreşim yine verilir; hata mesajı seansı bozar. Bilinçli sessiz.
      }
    }());
  }

  /// Süre değişti ya da mola atlandı: çalan geri sayımı kes.
  void stopCountdown() {
    final p = _countdown;
    if (p == null) return;
    final gen = _playGen;
    unawaited(p.stop().catchError((_) {}).then((_) => _release(gen)));
  }

  /// Ses bitti/durdu: müziği geri aç — arada yeni çalış başlamadıysa.
  void _release(int gen) {
    if (gen != _playGen) return;
    unawaited(_releaseSession());
  }

  /// Mola bitti — cepteki telefon için belirgin titreşim (hafif "tık" değil).
  void restDone() => HapticFeedback.vibrate();

  /// Set tamamlandı.
  void setDone() => HapticFeedback.lightImpact();

  /// Kişisel rekor kırıldı.
  void record() => HapticFeedback.heavyImpact();

  Future<void> dispose() async {
    await _completeSub?.cancel();
    await _countdown?.dispose();
    await _releaseSession();
  }
}

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final service = FeedbackService();
  ref.onDispose(service.dispose);
  return service;
});
