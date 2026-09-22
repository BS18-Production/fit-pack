import '../../data/database/app_database.dart';
import '../../data/database/daos/sync_meta_dao.dart';
import 'sync_controller.dart' show syncLog;

/// Cihaz saati ile sunucu saati arasındaki farkı öğrenir ve saklar
/// (docs/23 §2).
///
/// **Neden gerekli.** `changed_at_ms` cihaz saatinden damgalanır ve sunucudaki
/// çakışma kuralının tek girdisidir. Sunucu ileri sapmayı kırpar, geri sapmayı
/// kırpmaz: saati geride olan telefonun gerçek düzenlemesi "eski" sayılıp
/// reddedilir ve yerel kopya sunucununkiyle değiştirilir — kullanıcı için
/// sessiz bir düzenleme kaybı (docs/23 §2.1).
///
/// **Fark nereden geliyor.** Sunucu kabul ettiği her satıra `updated_at =
/// now()` yazıyor (`sync_guard`) ve bunu `RETURNING` ile geri veriyor. Yani
/// fark **ek tur atmadan**, gönderim cevabından öğrenilir.
///
/// Farkı tetikleyiciler `sync_meta`'dan okur (SQLite tetikleyicisi Dart
/// değişkeni göremez), o yüzden değer veritabanında tutulur.
class SyncClock {
  final AppDatabase db;

  /// Test için zaman kaynağı.
  final DateTime Function() now;

  SyncClock(this.db, {DateTime Function()? now}) : now = now ?? DateTime.now;

  SyncMetaDao get _meta => SyncMetaDao(db);

  /// Bu eşiğin altındaki fark yok sayılır.
  ///
  /// Neden: ağ gidiş-dönüşü ve sunucunun işlem süresi zaten birkaç yüz
  /// milisaniye oynatır. Her turda damgayı oynatmak `changed_at_ms`'i gereksiz
  /// gürültülü yapar ve gerçek bir sapma ile ölçüm gürültüsünü ayırt
  /// edilemez hale getirir. 30 sn, "kullanıcının saati bozuk" ile "ağ yavaş"
  /// arasındaki güvenli sınır.
  static const threshold = Duration(seconds: 30);

  /// Saçma farkları reddetme sınırı.
  ///
  /// Bir günü aşan fark, sunucunun değil **cihazın** takvimi yanlış demektir
  /// (kullanıcı tarihi elle 2020'ye almış). Böyle bir farkı uygulamak bütün
  /// damgaları bozar; düzeltmeden bırakmak daha az zararlı — satır yine
  /// gönderilir, yalnız çakışmada kaybedebilir.
  static const sanityLimit = Duration(days: 1);

  /// Gönderim cevabından farkı öğrenir.
  ///
  /// [serverMs] sunucunun damgası, [sentAtMs] isteğin gönderildiği andaki
  /// cihaz saati. Gidiş-dönüş süresi farkı şişirmesin diye cevabın geldiği an
  /// değil, **gönderim anı** kullanılır: fark gerçekte ikisinin arasında bir
  /// yerdedir ve gönderim anı alt sınırdır; eşik zaten gürültüyü eliyor.
  Future<void> learn({required int serverMs, required int sentAtMs}) async {
    final fark = serverMs - sentAtMs;
    if (fark.abs() > sanityLimit.inMilliseconds) {
      syncLog('saat farkı yok sayıldı (${fark}ms) — cihaz takvimi bozuk olmalı');
      return;
    }
    final mevcut = await offsetMs();
    if ((fark - mevcut).abs() < threshold.inMilliseconds) return; // önemsiz
    await _meta.write(SyncMetaDao.keyClockOffsetMs, '$fark');
    syncLog('saat farkı güncellendi: ${mevcut}ms → ${fark}ms');
  }

  /// Saklanan fark (ms). Okunamıyorsa 0 — düzeltme yokmuş gibi davranılır.
  Future<int> offsetMs() async =>
      int.tryParse(await _meta.read(SyncMetaDao.keyClockOffsetMs) ?? '') ?? 0;

  /// Düzeltilmiş "şimdi" — Dart tarafında damga gerekirse (tetikleyiciler
  /// aynı hesabı SQL'de yapar).
  Future<DateTime> correctedNow() async =>
      now().add(Duration(milliseconds: await offsetMs()));
}
