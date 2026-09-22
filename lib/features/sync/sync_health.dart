import '../../data/database/app_database.dart';
import '../../data/database/daos/sync_meta_dao.dart';
import 'sync_errors.dart';

/// Senkronun **sağlık kaydı** — "Son yedekleme" satırı ve uzun kesinti
/// uyarısı bunu okur (docs/20 §9).
///
/// Neden ayrı: gönderim ve çekme ayrı yerlerden çağrılıyor (zamanlayıcı,
/// giriş kapısı). Kaydı çağıranlara bırakmak, birinin unutmasıyla göstergenin
/// yalan söylemesi demekti. Kayıt `SyncPush.pushAll` ve `SyncPull.pullAll`'un
/// SONUNDA, kim çağırırsa çağırsın yapılır.
class SyncHealth {
  final AppDatabase db;

  /// Test için zaman kaynağı.
  final DateTime Function() now;

  SyncHealth(this.db, {DateTime Function()? now}) : now = now ?? DateTime.now;

  SyncMetaDao get _meta => SyncMetaDao(db);

  /// Uzun kesinti eşiği: bu kadar süre sunucuya ulaşılamazsa uyarılır.
  /// Ücretsiz Supabase projesi hareketsizlikte duraklatılıyor; bu uyarı o
  /// durumu da görünür kılar.
  static const longOutage = Duration(days: 3);

  Future<void> recordPushOk() => _recordOk(SyncMetaDao.keyLastPushOk);
  Future<void> recordPullOk() => _recordOk(SyncMetaDao.keyLastPullOk);

  Future<void> _recordOk(String key) async {
    await _meta.write(key, '${now().millisecondsSinceEpoch}');
    // Sunucuyla konuşabildik → kesinti bitti.
    await _meta.remove(SyncMetaDao.keyUnreachableSince);
  }

  /// Hatayı sınıflandırır; sunucuya ulaşılamıyorsa kesintinin BAŞLANGICINI
  /// yazar. Yalnız ilk seferde — sonraki hatalar tarihi ileri kaydırmaz,
  /// yoksa "3 gündür" hiç dolmazdı.
  Future<SyncErrorKind> recordError(Object error) async {
    final kind = classifySyncError(error);
    if (kind == SyncErrorKind.unreachable) {
      final mevcut = await _meta.read(SyncMetaDao.keyUnreachableSince);
      if (mevcut == null) {
        await _meta.write(
            SyncMetaDao.keyUnreachableSince, '${now().millisecondsSinceEpoch}');
      }
    }
    return kind;
  }

  /// Reddedilip sunucudakiyle değiştirilen satırları sayar (docs/23 §2.3).
  /// Turda ret yoksa sayaca dokunulmaz — geçmiş kayıt silinmez.
  Future<void> recordReplaced(int count) async {
    if (count <= 0) return;
    final mevcut = await replacedCount();
    await _meta.write(SyncMetaDao.keyReplacedCount, '${mevcut + count}');
    await _meta.write(
        SyncMetaDao.keyReplacedAt, '${now().millisecondsSinceEpoch}');
  }

  Future<int> replacedCount() async =>
      int.tryParse(await _meta.read(SyncMetaDao.keyReplacedCount) ?? '') ?? 0;

  Future<DateTime?> replacedAt() => _readTime(SyncMetaDao.keyReplacedAt);

  /// Kullanıcı bildirimi gördü → sayaç sıfırlanır.
  Future<void> clearReplaced() async {
    await _meta.remove(SyncMetaDao.keyReplacedCount);
    await _meta.remove(SyncMetaDao.keyReplacedAt);
  }

  Future<DateTime?> lastPushOk() => _readTime(SyncMetaDao.keyLastPushOk);
  Future<DateTime?> lastPullOk() => _readTime(SyncMetaDao.keyLastPullOk);
  Future<DateTime?> unreachableSince() =>
      _readTime(SyncMetaDao.keyUnreachableSince);

  /// Sunucuyla son başarılı temas (gönderim ya da çekme, hangisi yeniyse).
  Future<DateTime?> lastContactOk() async {
    final a = await lastPushOk();
    final b = await lastPullOk();
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  Future<DateTime?> _readTime(String key) async {
    final v = int.tryParse(await _meta.read(key) ?? '');
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }
}
