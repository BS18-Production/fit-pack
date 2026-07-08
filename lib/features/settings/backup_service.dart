/// Veri yedekleme (docs/12 → veri güvenliği). Uygulama verisi yalnızca cihazdaki
/// `fit_pack.sqlite` dosyasında (bulut yok). Bu servis o dosyanın tutarlı bir
/// kopyasını çıkarır → kullanıcı Drive/Dosyalar/e-postaya kaydeder.
///
/// Yedek = tüm tablolar (antrenman, beslenme, ölçüm, profil) birebir. Geri yükleme
/// dosyayı aynı yere geri kopyalar (sonraki sürüm migration'ları yükseltir).
library;

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/providers.dart';
import '../../data/seed/seed_manager.dart';
import '../../l10n/app_l10n.dart';

/// Yedek doğrulama/işlem hatası türü. Servis katmanında context (dolayısıyla
/// yerelleştirme) yoktur → tipli fırlatılır, UI [backupErrorMessage] ile aktif
/// dile çevirip gösterir (hardcoded metin sızıntısı olmaz).
enum BackupErrorKind { invalidFile, newerVersion, notSignedIn }

class BackupException implements Exception {
  final BackupErrorKind kind;
  const BackupException(this.kind);
  @override
  String toString() => 'BackupException(${kind.name})';
}

/// [BackupErrorKind] → aktif dilde kullanıcı metni. Saf fonksiyon (yalnız
/// çözülmüş [AppL10n] alır) — UI katmanında çağrılır.
String backupErrorMessage(AppL10n l, BackupErrorKind kind) => switch (kind) {
      BackupErrorKind.invalidFile => l.backupErrorInvalidFile,
      BackupErrorKind.newerVersion => l.backupErrorNewerVersion,
      BackupErrorKind.notSignedIn => l.backupErrorSignIn,
    };

/// Geri yükleme, canlı bağlantı KAPANDIKTAN sonra başarısız oldu. Mevcut veri
/// emniyet kopyasından geri kondu ama bağlantı kapalı — uygulamanın yeniden
/// başlatılması gerekir. UI bunu yakalayıp "yeniden başlat" diyaloğu gösterir
/// (normal hatalarda uygulama çalışmaya devam eder, snackbar yeter).
class RestoreNeedsRestartException implements Exception {
  final Object cause;
  RestoreNeedsRestartException(this.cause);
  @override
  String toString() => 'RestoreNeedsRestartException: $cause';
}

class BackupService {
  final Ref _ref;
  BackupService(this._ref);

  Future<File> _dbFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'fit_pack.sqlite'));
  }

  /// Tutarlı yedek için WAL'ı ana dosyaya işle, sonra geçici bir kopya çıkar.
  Future<File> exportToTemp() async {
    // Bekleyen WAL kayıtlarını ana .sqlite'a yaz — kopya eksiksiz olsun.
    final db = _ref.read(databaseProvider);
    await db.customStatement('PRAGMA wal_checkpoint(FULL)');

    final src = await _dbFile();
    final stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 16)
        .replaceAll(':', '-');
    final tmpDir = await getTemporaryDirectory();
    final dest = File(p.join(tmpDir.path, 'fit_pack_yedek_$stamp.sqlite'));
    await src.copy(dest.path);
    return dest;
  }

  /// Yedeği paylaşım sayfasıyla dışa aktar (Drive/Dosyalar/e-posta).
  /// [shareText] UI'dan yerelleştirilmiş gelir (l.backupShareText).
  Future<void> shareBackup(String shareText) async {
    final file = await exportToTemp();
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/x-sqlite3')],
      subject: 'Fit Pack',
      text: shareText,
    );
  }

  /// Seçilen yedek dosyasını canlı veritabanının üstüne yazar.
  /// Dönüş sonrası uygulamanın yeniden başlatılması gerekir (bağlantı tazelensin).
  ///
  /// Güvenlik sırası (C-01):
  /// 1. Doğrulamalar (SQLite imzası + şema sürümü) DB kapatılmadan yapılır —
  ///    geçersiz dosyada uygulama çalışır durumda kalır (FormatException).
  /// 2. WAL checkpoint: onaylanmış son kayıtlar ana dosyaya işlenir; yan
  ///    dosyaları silmek artık veri kaybettirmez.
  /// 3. Mevcut DB'nin emniyet kopyası alınır; kopyalama yarıda kesilirse
  ///    emniyet kopyası geri konur — eski veri korunur.
  Future<void> restoreFromFile(File picked) async {
    if (!await _isSqlite(picked)) {
      throw const BackupException(BackupErrorKind.invalidFile);
    }
    // Şema sürümü uygulamanınkinden YENİ bir yedek yüklenemez — eski kod yeni
    // kolonları tanımaz, tanımsız davranış olur. Eski/eşit sürüm sorunsuz:
    // açılışta migration'lar yedeği günceller.
    final db = _ref.read(databaseProvider);
    final backupVersion = await readSqliteUserVersion(picked);
    if (backupVersion > db.schemaVersion) {
      throw const BackupException(BackupErrorKind.newerVersion);
    }

    // Bekleyen WAL kayıtlarını ana dosyaya işle, sonra bağlantıyı kapat.
    await db.customStatement('PRAGMA wal_checkpoint(FULL)');
    await db.close();

    final dest = await _dbFile();
    final safety = File('${dest.path}.pre-restore');
    if (await dest.exists()) await dest.copy(safety.path);
    try {
      // Yedeği önce geçici ada kopyala; ana dosyayı ancak kopya tamamsa
      // atomik rename ile değiştir (yarım kopya asla canlı dosya olmaz).
      final incoming = File('${dest.path}.incoming');
      await picked.copy(incoming.path);
      for (final ext in ['-wal', '-shm']) {
        final side = File('${dest.path}$ext');
        if (await side.exists()) await side.delete();
      }
      await incoming.rename(dest.path);
    } catch (e) {
      // Kopyalama başarısız (disk dolu vb.) → mevcut veriyi geri koy.
      if (await safety.exists()) await safety.copy(dest.path);
      throw RestoreNeedsRestartException(e);
    }

    // Seed bayrağını sıfırla: geri yüklenen (muhtemelen eski) DB, sonraki
    // açılışta birim/hareket backfill'lerinden yeniden geçsin (M-04).
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SeedManager.seedVersionKey);
  }

  /// SQLite dosya imzası: ilk 16 bayt "SQLite format 3" + NUL.
  Future<bool> _isSqlite(File f) async {
    try {
      final head = await f.openRead(0, 16).first;
      const magic = 'SQLite format 3\x00';
      if (head.length < 16) return false;
      for (var i = 0; i < 16; i++) {
        if (head[i] != magic.codeUnitAt(i)) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

final backupServiceProvider =
    Provider<BackupService>((ref) => BackupService(ref));

/// SQLite başlığındaki user_version (ofset 60, 4 bayt big-endian) — Drift
/// şema sürümünü buraya yazar. Dosyayı açmadan sürüm kontrolü sağlar.
/// Top-level: testlerde Ref/provider kurulumu olmadan doğrulanabilir.
Future<int> readSqliteUserVersion(File f) async {
  final raf = await f.open();
  try {
    await raf.setPosition(60);
    final b = await raf.read(4);
    if (b.length < 4) return 0;
    return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
  } finally {
    await raf.close();
  }
}
