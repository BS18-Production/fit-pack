import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../settings/backup_service.dart';

/// Hesap tabanlı bulut yedek (docs/13-cloud-backup.md, Faz 1).
/// Yerel `.sqlite` yedeğini ([BackupService]) Supabase Storage'a `{uid}/` altına
/// yükler / geri indirir. Tek yön + manuel; local-first doğruluk kaynağı korunur.
class CloudBackupService {
  final Ref _ref;
  CloudBackupService(this._ref);

  static const _bucket = 'backups';
  static const _fileName = 'fit_pack.sqlite';

  SupabaseClient get _client => Supabase.instance.client;
  String? get _uid => _client.auth.currentUser?.id;
  String get _objectPath => '$_uid/$_fileName';

  /// Cihazdaki veriyi buluta yükle (üzerine yazar). Oturum şart.
  Future<void> backupToCloud() async {
    if (_uid == null) {
      throw StateError('Bulut yedek için giriş yapmalısın.');
    }
    final file = await _ref.read(backupServiceProvider).exportToTemp();
    final bytes = await file.readAsBytes();
    await _client.storage.from(_bucket).uploadBinary(
          _objectPath,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'application/x-sqlite3',
          ),
        );
  }

  /// Buluttaki yedeği indirip cihazın üstüne yaz. Dönüş sonrası yeniden başlat.
  Future<void> restoreFromCloud() async {
    if (_uid == null) {
      throw StateError('Geri yükleme için giriş yapmalısın.');
    }
    final Uint8List bytes =
        await _client.storage.from(_bucket).download(_objectPath);
    final tmpDir = await getTemporaryDirectory();
    final tmp = File(p.join(tmpDir.path, 'cloud_$_fileName'));
    await tmp.writeAsBytes(bytes, flush: true);
    await _ref.read(backupServiceProvider).restoreFromFile(tmp);
  }

  /// Buluttaki son yedeğin zamanı (yoksa null). Bilgilendirme amaçlı.
  Future<DateTime?> lastBackupAt() async {
    if (_uid == null) return null;
    try {
      final items = await _client.storage.from(_bucket).list(path: _uid);
      final obj = items.where((f) => f.name == _fileName).firstOrNull;
      final iso = obj?.updatedAt ?? obj?.createdAt;
      return iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    } catch (_) {
      return null; // henüz yedek yok / liste başarısız
    }
  }
}

final cloudBackupServiceProvider =
    Provider<CloudBackupService>((ref) => CloudBackupService(ref));
