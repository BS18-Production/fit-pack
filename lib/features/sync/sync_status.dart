import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'sync_providers.dart';

/// Senkron durumu göstergesinin (Aşama G, docs/18 §9) mantıksal durumu.
///
/// **Korkutma yok, durum bilgisi var.** Mesaj daima "kaydedildi" güvencesiyle
/// başlar — kullanıcının öğrenmesi gereken ilk şey verinin güvende olduğudur.
enum SyncState {
  /// Bekleyen yok — her şey sunucuda.
  synced,

  /// Bekleyen var, şu an gönderiliyor.
  syncing,

  /// Bekleyen var, henüz gönderilmedi (genelde çevrimdışı) ama kaydedildi.
  pending,

  /// Son tur hata verdi — bekleyen var, bağlantı/sunucu sorunu olabilir.
  failed,
}

class SyncStatus {
  /// Kuyrukta bekleyen (henüz sunucuya gitmemiş) satır sayısı.
  final int pending;
  final SyncState state;

  const SyncStatus({required this.pending, required this.state});
}

/// Senkron durumunu canlı yayınlar (Aşama G). Hesap ekranı bunu izler.
///
/// Uygulama tam reaktif olmadığı için (H-05 ertelendi) durumu iki sinyalden
/// türetiriz: her tablo yazımı (`tableUpdates`) kuyruğu değiştirebilir, her
/// gönderim turu sonucu (`controller.last`) durumu değiştirir. İkisinden birinde
/// yeniden hesaplayıp yayınlarız.
///
/// `autoDispose`: yalnız hesap ekranı açıkken canlı olması yeter; ekran
/// kapanınca dinleyiciler bırakılır (senkron ARKA PLANDA controller ile devam
/// eder, bu provider yalnız görüntüleme).
final syncStatusProvider = StreamProvider.autoDispose<SyncStatus>((ref) {
  final db = ref.watch(databaseProvider);
  final controller = ref.watch(syncControllerProvider);
  final out = StreamController<SyncStatus>();

  Future<void> recompute() async {
    if (out.isClosed) return;
    final pending = await controller.pendingCount();
    final last = controller.last.value;
    final SyncState state;
    if (controller.isRunning && pending > 0) {
      state = SyncState.syncing;
    } else if (pending == 0) {
      state = SyncState.synced;
    } else if (last != null && !last.ok) {
      state = SyncState.failed;
    } else {
      state = SyncState.pending;
    }
    if (!out.isClosed) out.add(SyncStatus(pending: pending, state: state));
  }

  recompute();
  final writes = db.tableUpdates().listen((_) => recompute());
  final rounds = controller.last.stream.listen((_) => recompute());
  ref.onDispose(() {
    writes.cancel();
    rounds.cancel();
    out.close();
  });
  return out.stream;
});
