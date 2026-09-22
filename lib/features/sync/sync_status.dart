import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'sync_health.dart';
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

  /// Kalıcı hata yüzünden kuyruktan ayrılmış satır sayısı (docs/20 §9).
  final int failed;

  /// Sunucuyla son başarılı temas — "Son yedekleme: bugün 14:32".
  final DateTime? lastOk;

  /// Sunucuya ilk ulaşılamadığı an; ulaşılabiliyorsa `null`.
  final DateTime? unreachableSince;

  /// Yerel düzenlemesi sunucudaki daha yeni sürümle değiştirilen satır sayısı
  /// (docs/23 §2.3). Hata değil, ama kullanıcı açısından "yazdığım kayboldu"
  /// demek — sessiz kalmamalı.
  final int replaced;

  /// Karşılaştırma için "şimdi" — test edilebilirlik ve tutarlılık için
  /// hesaplandığı anda sabitlenir.
  final DateTime now;

  SyncStatus({
    required this.pending,
    required this.state,
    this.failed = 0,
    this.replaced = 0,
    this.lastOk,
    this.unreachableSince,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  /// Kesinti uyarı eşiğini (3 gün) aştıysa kaç gündür sürdüğü; aşmadıysa
  /// `null`. Daha kısa kesintiler için uyarı yok: telefon bir gün çevrimdışı
  /// kaldı diye kullanıcıyı korkutmanın anlamı yok.
  int? get longOutageDays {
    final since = unreachableSince;
    if (since == null) return null;
    final gecen = now.difference(since);
    if (gecen < SyncHealth.longOutage) return null;
    return gecen.inDays;
  }
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
  final health = SyncHealth(db);
  final out = StreamController<SyncStatus>();

  Future<void> recompute() async {
    if (out.isClosed) return;
    final pending = await controller.pendingCount();
    final failed = await controller.failedCount();
    final lastOk = await health.lastContactOk();
    final unreachableSince = await health.unreachableSince();
    final replaced = await health.replacedCount();
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
    if (!out.isClosed) {
      out.add(SyncStatus(
        pending: pending,
        state: state,
        failed: failed,
        replaced: replaced,
        lastOk: lastOk,
        unreachableSince: unreachableSince,
      ));
    }
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
