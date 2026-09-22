import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../home/providers/home_providers.dart';
import '../update/update_providers.dart';
import '../workout/routine_providers.dart';
import 'sync_controller.dart';
import 'sync_health.dart';
import 'sync_providers.dart';
import 'sync_pull.dart';

/// Çekme tetikleyicileri ve inen verinin ekrana yansıtılması — **tek yerde**
/// (docs/20 §6.5).
///
/// Çekme dört yerden tetiklenir: giriş kapısı, uygulamanın öne gelmesi, hesap
/// ekranındaki "Şimdi eşitle" ve gönderimde ret. İlk üçü indirdiğini ekrana
/// yansıtmak zorunda; uygulama henüz tam reaktif olmadığı için (H-05 ertelendi)
/// okuma provider'ları elle tazelenir. Liste üç dosyaya kopyalansaydı biri
/// eksik kalır ve "veri indi ama ekran eski" hatası doğardı (CONVENTIONS §2).
///
/// Bağımlılıklar `Ref` yerine **açıkça** alınır: sınıf böylece Riverpod
/// kurmadan test edilebilir; tazeleme tek bir geri çağrıya indirgenir.
class SyncRefresh {
  final AppDatabase db;
  final SyncPull pull;
  final SyncController controller;

  /// Çekme yereli değiştirdiğinde çağrılır — okuma önbelleklerini tazeler.
  final void Function() onChanged;

  /// Test için zaman kaynağı.
  final DateTime Function() now;

  SyncRefresh({
    required this.db,
    required this.pull,
    required this.controller,
    required this.onChanged,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  /// Uygulama öne geldiğinde çekme için asgari ara (docs/20 §6.5).
  ///
  /// Neden her öne gelmede değil: uygulamaya gün içinde onlarca kez bakılır
  /// (antrenman sırasında her set arasında). İmleçli çekme değişiklik yoksa
  /// ucuzdur ama bedava değildir — her bakışta bir tur ağ isteği, mobil veride
  /// ve pilde görünür.
  static const foregroundInterval = Duration(minutes: 5);

  /// Çeker ve inen veriyi ekrana yansıtır.
  ///
  /// Hata **yutulur**: yereldeki veri doğru, kullanıcı çalışmaya devam eder
  /// (docs/18 Kural 1). Çağıran isterse sonucu okur.
  Future<PullResult> pullNow(String userId, {bool full = false}) async {
    try {
      final result = await pull.pullAll(userId: userId, full: full);
      if (result.changed > 0) onChanged();
      return result;
    } catch (e) {
      syncLog('çekme başarısız (yerelle devam)', error: e);
      return PullResult(error: e);
    }
  }

  /// §6.5 — uygulama öne geldiğinde çeker, ama yalnız son başarılı çekmeden
  /// bu yana [foregroundInterval] geçtiyse. Çekilmediyse `null` döner.
  ///
  /// Hiç çekilmemişse (yeni kurulum, ya da çekme hep başarısız olmuş) ara
  /// dolmuş sayılır: verisi henüz inmemiş kullanıcıyı beş dakika bekletmek
  /// yanlış olurdu.
  Future<PullResult?> pullIfStale(String userId) async {
    final last = await SyncHealth(db, now: now).lastPullOk();
    if (last != null && now().difference(last) < foregroundInterval) return null;
    return pullNow(userId);
  }

  /// Hesap ekranındaki "Şimdi eşitle" (§6.5): **önce gönder, sonra çek.**
  ///
  /// Sıra önemli: yereldeki değişiklik sunucuya gitmeden çekilirse sunucunun
  /// eski kopyası inip yerele uygulanmaya çalışılır; `changed_at_ms`
  /// karşılaştırması onu eler ama tur boşa gider ve kullanıcı "eşitledim, hâlâ
  /// bekliyor" görür.
  Future<ManualSyncResult> syncNow(String userId) async {
    await controller.syncNow();
    final pending = await controller.pendingCount();
    final pulled = await pullNow(userId);
    return ManualSyncResult(pending: pending, pull: pulled);
  }
}

/// Elle eşitlemenin sonucu — hesap ekranı kullanıcıya bunu anlatır.
class ManualSyncResult {
  /// Gönderimden sonra kuyrukta kalan satır. 0 değilse ağ ya da sunucu sorunu
  /// var; veri yerelde durduğu için kayıp değil, gecikmedir.
  final int pending;

  final PullResult pull;

  const ManualSyncResult({required this.pending, required this.pull});

  /// Hem gönderim hem çekme temiz bittiyse.
  bool get ok => pending == 0 && pull.ok;
}

final syncRefreshProvider = Provider<SyncRefresh>((ref) {
  return SyncRefresh(
    db: ref.watch(databaseProvider),
    pull: ref.watch(syncPullProvider),
    controller: ref.watch(syncControllerProvider),
    // Güne ve kullanıcıya bağlı okuma önbellekleri — tek liste.
    onChanged: () {
      ref.invalidate(userProfileProvider);
      ref.invalidate(latestWeightProvider);
      ref.invalidate(weightTrendProvider);
      ref.invalidate(weeklyStreakProvider);
      ref.invalidate(weekWorkoutStatsProvider);
      ref.invalidate(todayNutritionProvider);
      ref.invalidate(todayWaterProvider);
      ref.invalidate(todayRoutineProvider);
    },
  );
});

/// Uygulama öne geldiğinde senkronu tetikler (docs/20 §6.5).
///
/// **Widget ağacına bağlı değil.** `AppLifecycleListener` platform olaylarını
/// doğrudan dinler; hangi ekranın açık olduğu önemsizdir ve ekran değişimi
/// tetikleyiciyi düşürmez (aynı sebeple `syncControllerProvider` de
/// `autoDispose` değil).
///
/// İki iş yapar, sırayla:
/// 1. **Gönderim** — kuyrukta satır varsa hemen dener. Yazma dinleyicisi
///    yalnız YENİ yazmada tetiklenir; salonda çevrimdışı kaydedip dışarı çıkan
///    kullanıcıda yeni yazma yoktur ve artan bekleme o anda 5 dakikaya çıkmış
///    olabilir. Kuyruk boşsa tur zaten atlanır, bedeli yok.
/// 2. **Çekme** — son çekmeden [SyncRefresh.foregroundInterval] geçtiyse.
final syncForegroundProvider = Provider<void>((ref) {
  final listener = AppLifecycleListener(
    onResume: () {
      // Sürüm kapısı önce (docs/23 §3.2): kullanıcı mağazadan güncelleyip
      // döndüyse kapı açılsın; sunucu bu arada kapıyı yükselttiyse kapansın.
      unawaited(ref.read(updateGateProvider).refresh());

      final userId = ref.read(syncControllerProvider).currentUserId();
      if (userId == null) return; // Oturum yok → kuyruk bekler.
      unawaited(ref.read(syncControllerProvider).syncNow());
      unawaited(ref.read(syncRefreshProvider).pullIfStale(userId));
    },
  );
  ref.onDispose(listener.dispose);
});
