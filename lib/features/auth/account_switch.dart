import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/app_database.dart';
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
  static Future<AccountSwitch> apply(AppDatabase db, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(lastUserKey);

    if (last == userId) return AccountSwitch.sameUser;

    if (last == null) {
      // İlk giriş: cihazdaki veri sahipsizdi, bu hesaba bağlanır. Satırlar
      // göçte zaten kuyruğa alındı (§8.3) → ilk turda sunucuya yüklenirler.
      await prefs.setString(lastUserKey, userId);
      syncLog('hesap bağlandı: $userId (yerel veri korundu)');
      return AccountSwitch.adopted;
    }

    await wipeLocalUserData(db);
    await prefs.setString(lastUserKey, userId);
    syncLog('hesap değişti ($last → $userId) — yerel kullanıcı verisi silindi');
    return AccountSwitch.wiped;
  }

  /// Cihazdaki kullanıcı verisini siler. **Ortak katalog kalır**: 1015 seed
  /// hareket ve seed besinler kimseye ait değil (docs/18 §3.2), yeniden
  /// indirmek israf olur — yalnız kullanıcının kendi eklediği (`is_custom = 1`)
  /// satırlar gider.
  ///
  /// Silme sırası gönderim sırasının TERSİ: çocuk satır önce gider, yabancı
  /// anahtar kırılmaz.
  static Future<void> wipeLocalUserData(AppDatabase db) async {
    await db.transaction(() async {
      for (final table in syncPushOrder.reversed) {
        if (catalogTableNames.contains(table)) {
          await db.customStatement('DELETE FROM $table WHERE is_custom = 1');
        } else {
          await db.customStatement('DELETE FROM $table');
        }
      }
    });
    // Profil satırı silindi → boş profil yeniden kurulur (onboarded = false,
    // yani yeni kullanıcı kendi onboarding'inden geçer).
    await db.userProfileDao.ensureProfile();
    // Yarım kalmış seans taslağı da kullanıcı verisidir; prefs'te durduğu için
    // tablo silmesi ona dokunmaz.
    await WorkoutDraftService().clear();
  }
}
