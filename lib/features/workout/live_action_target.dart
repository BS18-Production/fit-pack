import 'package:uuid/uuid.dart';

/// Yaşayan kartın hedefini/değerlerini sürümler. Kalıcı veri kimliği değildir:
/// yeniden açılışta eski kart komutları geçersiz kalmalıdır. Aynı görüntü
/// aynı anahtarı korur; farklı set nesnesi veya değer yeni anahtar üretir.
/// Set ve mola için ayrı örnek kullanılır: doğal mola bitişi, native kartın
/// Dart uyurken gösterdiği sıradaki set düğmesini geçersiz kılmamalıdır.
class LiveActionTarget {
  Object? _snapshot;
  String? _key;

  String keyFor(Object snapshot) {
    if (_key == null || _snapshot != snapshot) {
      _snapshot = snapshot;
      _key = const Uuid().v4();
    }
    return _key!;
  }

  void clear() {
    _snapshot = null;
    _key = null;
  }
}
