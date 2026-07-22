import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/providers.dart';
import 'supabase_sync_remote.dart';
import 'sync_controller.dart';
import 'sync_push.dart';

/// Sunucu yüzeyi. Supabase başlatılamadıysa (ağ yok / yanlış config) yine de
/// nesne kurulur — çağrı hata fırlatır, satırlar kuyrukta kalır.
final syncRemoteProvider = Provider<SyncRemote>(
  (ref) => SupabaseSyncRemote(Supabase.instance.client),
);

final syncPushProvider = Provider<SyncPush>(
  (ref) => SyncPush(ref.watch(databaseProvider), ref.watch(syncRemoteProvider)),
);

/// Senkron zamanlayıcısı. **`autoDispose` DEĞİL** — ekran değişince yok olup
/// gönderimi yarıda kesmemeli (bkz. autoDispose + navigasyon dersi).
///
/// Kullanıcı kimliği doğrudan Supabase'in **kalıcı oturumundan** okunur; ağa
/// sorulmaz. Böylece çevrimdışıyken de "oturum var" bilinir ve kuyruk ağ
/// gelir gelmez boşalır (docs/18 §5.1 Kural 1).
final syncControllerProvider = Provider<SyncController>((ref) {
  final controller = SyncController(
    db: ref.watch(databaseProvider),
    push: ref.watch(syncPushProvider),
    currentUserId: () {
      try {
        return Supabase.instance.client.auth.currentSession?.user.id;
      } catch (_) {
        return null; // Supabase init edilemedi → oturumsuz say
      }
    },
  );
  ref.onDispose(controller.stop);
  return controller;
});

/// Oturum durumunu izleyip senkronu başlatır/durdurur.
///
/// - Giriş → dinlemeye başla + bekleyen kuyruğu gönder
/// - Çıkış → dur (satırlar kuyrukta kalır, tekrar girişte gider)
final syncLifecycleProvider = Provider<void>((ref) {
  final controller = ref.watch(syncControllerProvider);

  void apply(Session? session) {
    if (session != null) {
      controller.start();
    } else {
      controller.stop();
    }
  }

  try {
    apply(Supabase.instance.client.auth.currentSession);
    final sub = Supabase.instance.client.auth.onAuthStateChange
        .listen((state) => apply(state.session));
    ref.onDispose(sub.cancel);
  } catch (_) {
    // Supabase yok → senkron pasif, uygulama yerelde normal çalışır.
  }
});
