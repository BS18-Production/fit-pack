/// Mola sonu sesi seçenekleri (docs/45 §3). Dosyalar
/// `tools/make_rest_sounds.py` ile üretilir (sentetik, telifsiz).
///
/// Her ses için iki dosya:
/// - geri sayım (`rest_<id>.m4a`): 3 tık + bitiş — uygulama içi ve Android
///   dinlenme servisi çalar,
/// - iOS bildirim sesleri (`rest_<id>_countdown.caf`, `rest_<id>_end.caf`):
///   uygulama paketinde, IMA4 (iOS bildirimi AAC kabul etmez).
///
/// [id] kalıcıdır (tercihte saklanır) — değiştirme, yeni ses ekle.
enum RestSound {
  digitalBeep('digital_beep'),
  classicBell('classic_bell'),
  boxingBell('boxing_bell'),
  softChime('soft_chime'),
  strongAlert('strong_alert');

  const RestSound(this.id);

  final String id;

  /// Varsayılan: 2026-09-30'dan beri çalan "yarış" bipi — güncelleyen
  /// kullanıcının sesi değişmez.
  static const fallback = RestSound.digitalBeep;

  /// Bilinmeyen/eski kimlik varsayılana düşer (silinmiş ses, bozuk tercih).
  static RestSound fromId(String? id) =>
      values.where((s) => s.id == id).firstOrNull ?? fallback;

  /// Flutter varlık yolu (pubspec `assets/sounds/`).
  String get countdownAsset => 'assets/sounds/rest_$id.m4a';

  /// audioplayers `AssetSource` öneki `assets/` olmadan ister.
  String get countdownSource => 'sounds/rest_$id.m4a';

  /// iOS bildirim sesi — tam geri sayım (3 tık + bitiş); bitişten 3 sn
  /// önce çalınır (docs/45 §3b). Uygulama paketinde (`ios/Runner/Sounds/`).
  String get countdownNotifFileName => 'rest_${id}_countdown.caf';

  /// iOS bildirim sesi — yalnız bitiş (3 sn'den az kalmışken kurulan
  /// bildirim). Uygulama paketinde (`ios/Runner/Sounds/`).
  String get endFileName => 'rest_${id}_end.caf';
}
