/// Mola sonu sesi seçenekleri (docs/45 §3). Dosyalar
/// `tools/make_rest_sounds.py` ile üretilir (sentetik, telifsiz).
///
/// Her ses için iki dosya:
/// - geri sayım (`rest_<id>.m4a`): 3 tık + bitiş — uygulama içi ve Android
///   dinlenme servisi çalar,
/// - bitiş (`rest_<id>_end.caf`): iOS bildirim sesi (iOS bildirimi AAC
///   kabul etmez; IMA4).
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

  String get endAsset => 'assets/sounds/$endFileName';

  /// iOS bildirim sesi — tam geri sayım (3 tık + bitiş); bitişten
  /// [restCountdownLeadMs] önce çalınır (docs/45 §3b).
  String get countdownNotifAsset => 'assets/sounds/$countdownNotifFileName';
  String get countdownNotifFileName => 'rest_${id}_countdown.caf';

  /// iOS bildirim sesi dosya adı (`Library/Sounds/` altına kopyalanır).
  String get endFileName => 'rest_${id}_end.caf';
}
