import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/sync_meta_dao.dart';
import '../../data/database/tables/sync_columns.dart';
import '../sync/sync_controller.dart' show syncLog;
import '../workout/workout_draft.dart';

/// Girişte hesap değişimi kontrolünün sonucu (docs/18 §5.1 Kural 3).
enum AccountSwitch {
  /// Cihazda kayıt yoktu → mevcut yerel veri bu hesaba bağlanır (§8.2 (a)).
  adopted,

  /// Aynı kullanıcı tekrar girdi → yerel veri korunur.
  sameUser,

  /// Başka bir kullanıcı girdi → yerel kullanıcı verisi temizlendi.
  wiped,

  /// Başka bir kullanıcı girdi **ama kuyrukta gönderilmemiş kayıt var** →
  /// temizlik YAPILMADI, karar kullanıcıya bırakıldı (docs/20 §7.4).
  pendingConflict,
}

/// Hesap değişimi bekçisi (docs/18 §5.1 **Kural 3**).
///
/// Çıkışta yerel veri SİLİNMEZ — hızlı yeniden giriş ve çevrimdışı erişim için.
/// Ama tek başına bırakılırsa **aynı cihazda ikinci bir kullanıcı giriş yapınca
/// öncekinin antrenmanlarını, öğünlerini ve ölçümlerini görür**. Bu gerçek bir
/// veri sızıntısıdır, o yüzden karar girişte verilir: cihazda kayıtlı son
/// `user_id` ile şimdi giren aynı mı?
class AccountSwitchGuard {
  /// Cihazda en son hangi hesabın verisi duruyor.
  static const lastUserKey = 'last_user_id';

  const AccountSwitchGuard._();

  /// Girişte bir kez çalışır. Farklı kullanıcıysa yerel kullanıcı verisini
  /// temizler ve kimliği günceller.
  ///
  /// **Yarıda kalmaya dayanıklı (docs/20 §7.3):** temizlikten ÖNCE
  /// `switch_in_progress` yazılır, bittikten sonra silinir. Uygulama arada
  /// ölürse bir sonraki açılışta [resumeIfInterrupted] temizliği baştan yapar
  /// — yarım temizlik, önceki hesabın verisinin yeni kullanıcıya görünmesi
  /// demektir.
  static Future<AccountSwitch> apply(AppDatabase db, String userId) async {
    final meta = db.syncMetaDao;
    await _migrateLastUserFromPrefs(db);
    final last = await meta.read(SyncMetaDao.keyLastUser);

    if (last == userId) return AccountSwitch.sameUser;

    if (last == null) {
      // İlk giriş: cihazdaki veri sahipsizdi, bu hesaba bağlanır. Satırlar
      // göçte zaten kuyruğa alındı (§8.3) → ilk turda sunucuya yüklenirler.
      await meta.write(SyncMetaDao.keyLastUser, userId);
      syncLog('hesap bağlandı: $userId (yerel veri korundu)');
      return AccountSwitch.adopted;
    }

    // §7.4: kuyrukta bekleyen kayıt varsa sessizce silme — kullanıcı
    // "bu cihazdaki N kayıt henüz yüklenmedi" uyarısını görüp karar versin.
    if (await pendingRowCount(db) > 0) {
      syncLog('hesap değişimi bekletildi: gönderilmemiş kayıt var '
          '($last → $userId)');
      return AccountSwitch.pendingConflict;
    }

    await meta.write(SyncMetaDao.keySwitchInProgress, userId);
    await wipeLocalUserData(db);
    await meta.write(SyncMetaDao.keyLastUser, userId);
    await meta.remove(SyncMetaDao.keySwitchInProgress);
    syncLog('hesap değişti ($last → $userId) — yerel kullanıcı verisi silindi');
    return AccountSwitch.wiped;
  }

  /// Gönderilmeyi bekleyen satır sayısı (giden kutusu + mezar taşları).
  /// Hesap değişiminde "kaç kayıt kaybolacak?" sorusunun cevabı.
  ///
  /// **İlerleme fotoğrafları BİLİNÇLİ olarak sayılır**, senkron göstergesi
  /// onları atladığı halde (docs/19 K-2): sunucuya hiç gitmezler, yani hesap
  /// değişimi temizliği onları **geri dönüşsüz** siler. Sayılmasalardı
  /// kullanıcı "yüklenmemiş kayıt yok" görüp en hassas verisini sessizce
  /// kaybederdi.
  static Future<int> pendingRowCount(AppDatabase db) async {
    var total = 0;
    for (final table in [...syncedTableNames, 'sync_tombstones']) {
      final row = await db
          .customSelect('SELECT COUNT(*) c FROM $table WHERE sync_state = 1')
          .getSingle();
      total += row.read<int>('c');
    }
    return total;
  }

  /// Kullanıcı "kayıtları silip devam et" derse çağrılır — §7.4 seçiminin
  /// ikinci şıkkı. Temizlik yine yarıda kalmaya dayanıklıdır.
  static Future<void> wipeAndAdopt(AppDatabase db, String userId) async {
    final meta = db.syncMetaDao;
    await meta.write(SyncMetaDao.keySwitchInProgress, userId);
    await wipeLocalUserData(db);
    await meta.write(SyncMetaDao.keyLastUser, userId);
    await meta.remove(SyncMetaDao.keySwitchInProgress);
    syncLog('kullanıcı onayıyla yerel veri silindi → $userId');
  }

  /// Açılışta çağrılır: yarıda kalmış bir hesap değişimi varsa temizliği
  /// tamamlar. Hiçbir şey yarıda kalmadıysa ucuz bir okuma.
  static Future<bool> resumeIfInterrupted(AppDatabase db) async {
    final meta = db.syncMetaDao;
    final pending = await meta.read(SyncMetaDao.keySwitchInProgress);
    if (pending == null) return false;
    syncLog('yarım kalmış hesap değişimi bulundu ($pending) — temizlik '
        'tamamlanıyor');
    await wipeLocalUserData(db);
    await meta.write(SyncMetaDao.keyLastUser, pending);
    await meta.remove(SyncMetaDao.keySwitchInProgress);
    return true;
  }

  /// `last_user_id` eskiden `shared_preferences`'taydı; tek seferlik taşıma.
  /// Defterde değer varsa dokunmaz.
  static Future<void> _migrateLastUserFromPrefs(AppDatabase db) async {
    final meta = db.syncMetaDao;
    if (await meta.read(SyncMetaDao.keyLastUser) != null) return;
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(lastUserKey);
    if (legacy == null) return;
    await meta.write(SyncMetaDao.keyLastUser, legacy);
    await prefs.remove(lastUserKey);
    syncLog('last_user_id senkron defterine taşındı');
  }

  /// Cihazdaki kullanıcı verisini siler. **Ortak katalog kalır**: 1015 seed
  /// hareket ve seed besinler kimseye ait değil (docs/18 §3.2), yeniden
  /// indirmek israf olur — yalnız kullanıcının kendi eklediği (`is_custom = 1`)
  /// satırlar gider.
  ///
  /// Silme sırası gönderim sırasının TERSİ: çocuk satır önce gider, yabancı
  /// anahtar kırılmaz.
  static Future<void> wipeLocalUserData(AppDatabase db) async {
    // Temizlik mezar taşı ÜRETMEZ: bu kullanıcı silmesi değil, cihazın
    // önceki hesaptan arındırılması. İz bırakırsa o izler yeni kullanıcının
    // hesabıyla sunucuya gider ve **onun** kayıtlarını siler (docs/20 §7.3).
    await db.customStatement(setCaptureSql(false));
    try {
      await _wipeTables(db);
    } finally {
      await db.customStatement(setCaptureSql(true));
    }
    // Temizlikten arta kalan iz varsa (eski sürümden) da silinir.
    await db.customStatement('DELETE FROM sync_tombstones');
    // Profil satırı silindi → boş profil yeniden kurulur (onboarded = false,
    // yani yeni kullanıcı kendi onboarding'inden geçer).
    await db.userProfileDao.ensureProfile();
    // Yarım kalmış seans taslağı da kullanıcı verisidir; prefs'te durduğu için
    // tablo silmesi ona dokunmaz.
    await WorkoutDraftService().clear();
  }

  static Future<void> _wipeTables(AppDatabase db) async {
    await db.transaction(() async {
      for (final table in syncPushOrder.reversed) {
        if (catalogTableNames.contains(table)) {
          await db.customStatement('DELETE FROM $table WHERE is_custom = 1');
        } else {
          await db.customStatement('DELETE FROM $table');
        }
      }
    });
  }
}
