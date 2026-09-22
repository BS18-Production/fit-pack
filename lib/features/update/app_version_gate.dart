import 'package:flutter/foundation.dart';

import '../sync/sync_controller.dart' show syncLog;

/// "Bu sürüm artık desteklenmiyor" kararı (docs/23 §3).
@immutable
class UpdateRequirement {
  /// Kullanıcı güncellemeden devam edemez.
  final bool blocked;

  /// Sunucunun istediği en düşük build numarası — yalnız günlük/hata ayıklama.
  final int? minBuild;

  /// Sunucudan gelen açıklama. Boşsa istemci kendi yerelleştirilmiş metnini
  /// kullanır (sunucu kullanıcının dilini bilmiyor).
  final String? message;

  const UpdateRequirement({this.blocked = false, this.minBuild, this.message});

  /// Kapı yok — kontrol yapılamadığında da bu döner.
  static const none = UpdateRequirement();
}

/// Asgari sürüm kapısı (docs/23 §3.2).
///
/// **Neden var.** Mağaza güncellemesi kademeli yayılır; "sunucu ile istemci
/// aynı anda güncellenir" varsayımı (docs/20 §11) ticari üründe tutmaz.
/// Eklemeli yapılamayan bir sunucu değişikliği geldiğinde eski istemci
/// sessizce yazamaz hale gelirdi; bu kapı onun yerine açık bir "güncelle"
/// ekranı gösterir.
///
/// **Kapı ağ yokluğunda KAPANMAZ** (docs/18 Kural 1). Sunucuya ulaşılamıyorsa,
/// tablo yoksa ya da cevap bozuksa sonuç [UpdateRequirement.none]: kullanıcı
/// uçakta ya da sinyalsiz salonda kendi verisinden edilmez. Kapı yalnız sunucu
/// açıkça "çok eskisin" dediğinde devreye girer.
class AppVersionGate {
  /// Kurulu sürümün build numarası.
  final Future<int> Function() currentBuild;

  /// Bu platform için sunucudaki asgari sürüm kaydı; yoksa `null`.
  final Future<({int minBuild, String? message})?> Function() fetchMinimum;

  const AppVersionGate({
    required this.currentBuild,
    required this.fetchMinimum,
  });

  Future<UpdateRequirement> check() async {
    try {
      final minimum = await fetchMinimum();
      if (minimum == null) return UpdateRequirement.none; // kayıt yok → kapı yok

      final build = await currentBuild();
      if (build <= 0) {
        // Build numarası okunamadı. Kapatmak, kendi hatamız yüzünden
        // kullanıcıyı uygulamadan etmek olurdu.
        syncLog('sürüm kapısı: build numarası okunamadı → kapı atlandı');
        return UpdateRequirement.none;
      }
      if (build >= minimum.minBuild) return UpdateRequirement.none;

      syncLog('sürüm kapısı: build $build < asgari ${minimum.minBuild}');
      return UpdateRequirement(
        blocked: true,
        minBuild: minimum.minBuild,
        message: minimum.message,
      );
    } catch (e) {
      // Ağ yok / tablo yok / cevap bozuk → kapı yok.
      syncLog('sürüm kapısı kontrol edilemedi (devam ediliyor)', error: e);
      return UpdateRequirement.none;
    }
  }
}

/// Kapının durumunu tutar ve yönlendiriciye haber verir.
///
/// `ChangeNotifier`: GoRouter'ın `refreshListenable`ına `AuthGate` ile birlikte
/// bağlanır, böylece kapı kapandığı anda yönlendirme devreye girer.
class UpdateGate extends ChangeNotifier {
  final AppVersionGate _gate;

  UpdateGate(this._gate);

  UpdateRequirement _state = UpdateRequirement.none;
  UpdateRequirement get state => _state;

  bool get blocked => _state.blocked;

  /// Kapıyı yeniden değerlendirir. Açılışta ve uygulama öne geldiğinde
  /// çağrılır: kullanıcı mağazadan güncelleyip geri döndüğünde kapı
  /// kendiliğinden açılsın.
  Future<void> refresh() async {
    final yeni = await _gate.check();
    if (yeni.blocked == _state.blocked) {
      _state = yeni;
      return; // durum değişmedi → gereksiz yeniden çizim yok
    }
    _state = yeni;
    notifyListeners();
  }
}
