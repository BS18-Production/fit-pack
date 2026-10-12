import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_session_release.dart';
import 'rest_sound.dart';

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
/// `rest_<ses>.m4a`: 0, 1, 2. sn'de tık, 3. sn'de bitiş (bkz. [RestSound]).
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
  // Geri sayım oynatıcısına yüklü ses (Ayarlar'dan değişebilir).
  RestSound _loaded = RestSound.fallback;
  Future<void>? _ready;
  StreamSubscription<void>? _completeSub;
  // Her çal/durdur isteğinde artar: bekleyen eski bir istek (yükleme
  // sürerken "Atla" geldi) yeni durumu bozmasın — her beklemeden sonra
  // kontrol edilir.
  int _playGen = 0;
  // Geri sayım oynatıcısının işlemleri sırayla çalışır: eşzamanlı iki
  // `setSource` (ses değişimi + mola başı) birbirini ezmesin (Codex
  // incelemesi, 2026-10-12).
  Future<void> _ops = Future.value();

  Future<AudioPlayer>? _previewPlayer;
  StreamSubscription<void>? _previewSub;
  int _previewGen = 0;
  // Önizleme işlemleri de sıralı: A yüklenirken B seçilirse A geç bitip
  // B'yi ezmesin.
  Future<void> _previewOps = Future.value();
  bool _disposed = false;

  Future<void> _serial(Future<void> Function() op) => _ops = _ops
      .then((_) => _disposed ? null : op())
      .catchError((Object _) {});

  Future<void> _previewSerial(Future<void> Function() op) => _previewOps =
      _previewOps
          .then((_) => _disposed ? null : op())
          .catchError((Object _) {});

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
    await p.setSource(AssetSource(_loaded.countdownSource));
    if (_disposed) {
      // Kurulum sürerken servis kapandı: oynatıcı açık kalmasın.
      await p.dispose();
      return;
    }
    _completeSub = p.onPlayerComplete.listen((_) => _release(_playGen));
    _countdown = p;
  }

  /// Sesi oynatıcıya yükler (değiştiyse). Yalnız [_serial] içinden.
  Future<void> _load(RestSound sound) async {
    await _ensureReady();
    final p = _countdown;
    if (p == null || _loaded == sound) return;
    await p.setSource(AssetSource(sound.countdownSource));
    _loaded = sound;
  }

  /// Seans ekranı açılınca çağrılır — ilk çalışta yükleme gecikmesi olmasın.
  void warmUp([RestSound sound = RestSound.fallback]) =>
      unawaited(_serial(() => _load(sound)));

  /// Ayarlar → Mola sesi: sesi baştan sona bir kez çalar (geri sayım +
  /// bitiş). Önceki önizlemeyi keser; seans geri sayımına dokunmaz.
  /// Hata en iyi çaba — ses servisi yoksa sessiz geçer.
  Future<void> preview(RestSound sound) {
    final gen = ++_previewGen;
    return _previewSerial(() async {
      await _ensureReady(); // ses bağlamı (müziği kısma) kurulmuş olsun
      final p = await (_previewPlayer ??= _newPreviewPlayer());
      if (gen != _previewGen) return; // panel kapandı ya da yeni önizleme
      await p.stop();
      await p.setSource(AssetSource(sound.countdownSource));
      if (gen != _previewGen) return;
      await p.resume();
    });
  }

  Future<void> stopPreview() {
    _previewGen++;
    return _previewSerial(() async {
      await (await _previewPlayer)?.stop();
      unawaited(_releaseSession());
    });
  }

  /// Önizleme oynatıcısı bir kez kurulur (hızlı iki dokunuşta iki oynatıcı
  /// açılmasın); kurulum hatasında sonraki deneme yeniden kurar.
  Future<AudioPlayer> _newPreviewPlayer() async {
    try {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      if (defaultTargetPlatform == TargetPlatform.android) {
        await p.setAudioContext(_audioContext);
      }
      _previewSub = p.onPlayerComplete.listen((_) => unawaited(_releaseSession()));
      return p;
    } catch (_) {
      _previewPlayer = null;
      rethrow;
    }
  }

  /// Geri sayım sesini [offsetMs]'den başlatır (bkz. [countdownPlan]).
  /// Tek dosya olduğu için tıklar arası aralık oynatıcı gecikmesinden
  /// etkilenmez — eski "her saniye durdur/başlat" yolunda 2. ve 3. bip
  /// kayıyordu (Samet, 2026-09-30).
  void playCountdown({int offsetMs = 0, RestSound? sound}) {
    final gen = ++_playGen;
    unawaited(_serial(() async {
      try {
        await _load(sound ?? _loaded);
        final p = _countdown;
        if (p == null || gen != _playGen) return; // arada durduruldu
        await p.stop();
        if (offsetMs > 0) await p.seek(Duration(milliseconds: offsetMs));
        if (gen != _playGen) return;
        await p.resume();
      } catch (_) {
        // Ses en iyi çaba: çalınamazsa (ses servisi yok, dosya açılamadı)
        // titreşim yine verilir; hata mesajı seansı bozar. Bilinçli sessiz.
      }
    }));
  }

  /// Süre değişti ya da mola atlandı: çalan (ya da yüklenmeyi bekleyen)
  /// geri sayımı kes.
  void stopCountdown() {
    // Nesil her durumda artar: kuyrukta bekleyen (henüz başlamamış) çalma
    // da iptal olsun (Codex 2. tur).
    final gen = ++_playGen;
    if (_countdown == null && _ready == null) return;
    unawaited(_serial(() async {
      await _countdown?.stop();
      _release(gen);
    }));
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
    // Bekleyen kurulum/çalma kaynak açık bırakmasın: önce iptal, sonra bekle.
    _disposed = true;
    _playGen++;
    _previewGen++;
    await _ops;
    await _previewOps;
    try {
      await _ready;
    } catch (_) {}
    await _completeSub?.cancel();
    await _previewSub?.cancel();
    await _countdown?.dispose();
    await (await _previewPlayer)?.dispose();
    await _releaseSession();
  }
}

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final service = FeedbackService();
  ref.onDispose(service.dispose);
  return service;
});
