import '../../data/database/daos/sync_meta_dao.dart';
import '../sync/sync_ownership.dart';

/// Açılan hızlı giriş paneli kendi hesabında kalır. Kontrol ve yazma aynı
/// yerel transaction'dadır; hesap değişimi eski taslağı yeni hesaba taşımaz.
class NutritionEntryScope {
  NutritionEntryScope(this._ownership)
    : _userId = _ownership.sessionUserId?.call();

  final SyncOwnership _ownership;
  final String? _userId;
  bool _invalidated = false;

  /// Aynı hesap geri gelse de önceki panel yeniden geçerli olmaz (A → B → A).
  /// Token yenileme gibi aynı kullanıcıya ait olaylar kapsamı bozmaz.
  void observeAccount(String? userId) {
    if (userId != _userId) _invalidated = true;
  }

  bool get isCurrent =>
      !_invalidated && _ownership.sessionUserId?.call() == _userId;

  Future<void> _ensureCurrent() async {
    if (!isCurrent) {
      throw const NutritionEntryAccountChanged();
    }
    final userId = _userId;
    if (userId != null) {
      await _ownership.ensure(userId);
    } else {
      // Hesapsız sentetik/yerel veri desteklenir; sahipli veri üzerinde
      // çıkış yapılmış bir oturumun işlem yapmasına izin verilmez.
      final meta = SyncMetaDao(_ownership.db);
      if (await meta.read(SyncMetaDao.keyLastUser) != null ||
          await meta.read(SyncMetaDao.keySwitchInProgress) != null) {
        throw const NutritionEntryAccountChanged();
      }
    }
    if (!isCurrent) {
      throw const NutritionEntryAccountChanged();
    }
  }

  Future<T> run<T>(Future<T> Function() write) =>
      _ownership.db.transaction(() async {
        await _ensureCurrent();
        final result = await write();
        // Yazma await'i sırasında oturum değişmişse transaction geri alınır.
        await _ensureCurrent();
        return result;
      });
}

class NutritionEntryAccountChanged implements Exception {
  const NutritionEntryAccountChanged();
}
