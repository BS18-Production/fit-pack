import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/database/app_database.dart';
import '../../data/database/tables/sync_columns.dart';
import 'sync_push.dart';

/// Senkron günlüğü. Hatalar sessizce yutulursa "neden gitmiyor" sorusuna
/// cevap veremeyiz — ilk canlı turda tam bunu yaşadık.
///
/// `debugPrint` kullanılıyor çünkü `dart:developer`'ın `log()`'u VM servis
/// kanalına gider ve **logcat'te görünmez** — cihazda hata ayıklarken işe
/// yaramaz. `debugPrint` stdout'a yazar, `adb logcat` yakalar.
void syncLog(String message, {Object? error}) {
  debugPrint('[fitpack.sync] $message${error != null ? ' | HATA: $error' : ''}');
}

/// Senkronun ne zaman çalışacağını yöneten katman (docs/18 §6).
///
/// Sorumlulukları:
/// - **Tek seferde bir tur** — eşzamanlı iki gönderim aynı satırı iki kez
///   yollar, gereksiz yük ve yarış yaratır
/// - **Artan bekleme** — hata sonrası 1sn → 5sn → 30sn → 5dk. Asla pes etmez,
///   satır kuyrukta kalır (docs/18 §6.3 kural 5)
/// - **Geciktirme (debounce)** — yazma fırtınasında (seans kaydederken 20 set)
///   her yazma için ayrı istek atma, topla
/// - **Oturum yoksa çalışmaz** — satırlar kuyrukta bekler, girişte gider
class SyncController {
  final AppDatabase db;
  final SyncPush push;

  /// O anki kullanıcı kimliği; oturum yoksa `null`. Doğrudan Supabase'in
  /// kalıcı oturumundan okunur — ağ sorulmaz (docs/18 §5.1 Kural 1).
  final String? Function() currentUserId;

  /// Yazma sonrası bekleme — art arda yazmalar tek tura toplanır.
  final Duration debounce;

  /// Hata sonrası bekleme basamakları.
  static const _backoff = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 5),
    Duration(seconds: 30),
    Duration(minutes: 5),
  ];

  SyncController({
    required this.db,
    required this.push,
    required this.currentUserId,
    this.debounce = const Duration(seconds: 2),
  });

  Timer? _debounceTimer;
  Timer? _retryTimer;
  StreamSubscription<void>? _writes;
  bool _running = false;
  int _failures = 0;

  /// Son turun sonucu — arayüz (Aşama G) buradan okuyacak.
  final ValueStream<PushResult?> last = ValueStream();

  /// Yazmaları dinlemeye başlar. Giriş yapıldığında çağrılır.
  void start() {
    syncLog('senkron başlatıldı (yazma dinleyicisi kuruldu)');
    _writes ??= db
        .tableUpdates()
        .listen((_) => schedule());
    schedule();
  }

  /// Dinlemeyi bırakır ve bekleyen zamanlayıcıları iptal eder (çıkışta).
  Future<void> stop() async {
    await _writes?.cancel();
    _writes = null;
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _failures = 0;
  }

  /// Geciktirmeli tetikleme — yazma fırtınasını tek tura toplar.
  void schedule() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, syncNow);
  }

  /// Hemen bir tur dener. Eşzamanlı çağrılarda ikincisi sessizce döner.
  Future<void> syncNow() async {
    if (_running) return;
    final userId = currentUserId();
    if (userId == null) {
      syncLog('atlandı: oturum yok — kuyruk bekliyor');
      return;
    }

    // ⚠️ Bayrak İLK await'ten ÖNCE set edilmeli. Sonra set edilirse eşzamanlı
    // çağrıların hepsi kontrolden geçer (hepsi `hasPending`i beklerken hiçbiri
    // bayrağı görmez) ve aynı satır birden fazla kez gönderilir.
    _running = true;
    try {
      // Boşa tur atma: bekleyen yoksa çık. Bu aynı zamanda döngü korumasıdır —
      // temiz işaretleme de bir yazmadır ve `tableUpdates` tetikler.
      final waiting = await pendingCount();
      if (waiting == 0) {
        syncLog('atlandı: kuyruk boş');
        return;
      }
      syncLog('tur başlıyor — $waiting satır bekliyor, kullanıcı $userId');
      final result = await push.pushAll(userId: userId);
      last.value = result;
      syncLog('tur bitti — gönderilen ${result.pushed}, '
          'kalan ${result.failed}', error: result.error);

      if (result.ok) {
        _failures = 0;
        _retryTimer?.cancel();
      } else {
        _scheduleRetry();
      }
    } catch (e, st) {
      last.value = PushResult(failed: 1, error: e);
      syncLog('TUR HATASI: $e\n$st', error: e);
      _scheduleRetry();
    } finally {
      _running = false;
    }
  }

  /// Kuyrukta bekleyen satır var mı?
  Future<bool> hasPending() async {
    for (final table in syncPushOrder) {
      final r = await db
          .customSelect(
              'SELECT EXISTS(SELECT 1 FROM $table WHERE sync_state = 1) e')
          .getSingle();
      if (r.read<int>('e') == 1) return true;
    }
    return false;
  }

  /// Kuyrukta bekleyen toplam satır — arayüzde "N kayıt yüklenecek" için.
  Future<int> pendingCount() async {
    var total = 0;
    for (final table in syncPushOrder) {
      final r = await db
          .customSelect('SELECT COUNT(*) c FROM $table WHERE sync_state = 1')
          .getSingle();
      total += r.read<int>('c');
    }
    return total;
  }

  void _scheduleRetry() {
    final delay = _backoff[_failures.clamp(0, _backoff.length - 1)];
    _failures++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, syncNow);
  }

  /// Test/hata ayıklama için: kaçıncı hata basamağındayız.
  int get failureCount => _failures;
}

/// Minik değer yayını — son senkron sonucunu dinlenebilir tutar.
/// (Riverpod'a bağlamadan da test edilebilsin diye bağımsız.)
class ValueStream<T> {
  final _controller = StreamController<T>.broadcast();
  T? _value;

  T? get value => _value;
  set value(T? v) {
    _value = v;
    if (v is T) _controller.add(v);
  }

  Stream<T> get stream => _controller.stream;
  void dispose() => _controller.close();
}
