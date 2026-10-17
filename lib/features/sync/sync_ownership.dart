import '../../data/database/app_database.dart';
import '../../data/database/daos/sync_meta_dao.dart';

/// Senkron işinin hâlâ bu hesaba ait olup olmadığı (docs/47, CR-001).
///
/// Kapı ekranı kilitlemek yetmez: arka plandaki gönderim ve çekme de aynı
/// sınırı tanımalı. Bir kullanıcı için iş yalnız şu üçü birlikte doğruysa
/// yapılır:
/// 1. açık oturum bu kullanıcının,
/// 2. cihazdaki verinin kayıtlı sahibi (`last_user_id`) bu kullanıcı,
/// 3. yarım kalmış hesap temizliği yok.
///
/// Çakışma ekranı açıkken (A'nın gönderilmemiş kaydı, B'nin oturumu) sahip A,
/// oturum B → iki taraf için de iş durur. Kullanıcı karar verince sahip
/// güncellenir ve sıradaki tur kendiliğinden çalışır.
///
/// Transaction içinde çağrılırsa okuma o transaction'dan yapılır: kontrol ile
/// ardından gelen yazma arasına hesap temizliği giremez.
class SyncOwnership {
  final AppDatabase db;

  /// Açık oturumun kullanıcısı — ağ sorulmaz (docs/18 §5.1 Kural 1).
  /// `null` verilirse oturum şartı atlanır (yalnız testlerde).
  final String? Function()? sessionUserId;

  SyncOwnership(this.db, {this.sessionUserId});

  Future<bool> owns(String userId) async {
    final session = sessionUserId;
    if (session != null && session() != userId) return false;
    final meta = SyncMetaDao(db);
    if (await meta.read(SyncMetaDao.keySwitchInProgress) != null) return false;
    return await meta.read(SyncMetaDao.keyLastUser) == userId;
  }

  /// Sahiplik bozulduysa [SyncOwnershipLost] fırlatır — süren iş yarıda
  /// bırakılır, hiçbir şey yazılmaz.
  Future<void> ensure(String userId) async {
    if (!await owns(userId)) throw SyncOwnershipLost(userId);
  }
}

/// Senkron işi sürerken hesap değişti; iş bırakıldı. Ağ hatası değildir —
/// "sunucuya ulaşılamadı" sayılmaz.
class SyncOwnershipLost implements Exception {
  final String userId;
  const SyncOwnershipLost(this.userId);

  @override
  String toString() => 'SyncOwnershipLost: senkron işi artık $userId '
      'hesabına ait değil (hesap değişti)';
}
