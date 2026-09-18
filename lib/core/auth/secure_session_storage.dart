import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/sync/sync_controller.dart' show syncLog;

/// Oturum belirteçlerinin saklandığı yer (docs/18 güvenlik maddesi).
///
/// **Neden:** supabase_flutter varsayılanı oturumu `shared_preferences`'e
/// **düz metin** yazar (iOS'ta `.plist`, Android'de XML). Telefonu ele geçiren
/// ya da yedeği okuyan biri belirteci alıp hesaba erişebilir. Burada iOS'ta
/// **Keychain**, Android'de **Keystore destekli şifreli depo** kullanılır.
///
/// **Göç:** ilk açılışta eski düz metin değer okunur, kasaya yazılır, geri
/// okunarak doğrulanır ve ancak o zaman silinir. Doğrulama başarısızsa eski
/// değer YERİNDE bırakılır — kullanıcı oturumundan olmaz (güvenlik iyileştirmesi
/// kullanıcıyı dışarı atmamalı).
///
/// **Geri düşüş:** kasa okunamaz/yazılamazsa (üretici hatası, kilitli cihaz)
/// eski davranışa dönülür. Oturum kaybetmektense düz metinde kalmak yeğdir;
/// durum günlüğe yazılır.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    required this.persistSessionKey,
    SecureStore? store,
    Future<SharedPreferences> Function()? prefs,
  }) : _store = store ?? const FlutterSecureStore(),
       _prefs = prefs ?? SharedPreferences.getInstance;

  /// supabase_flutter'ın kullandığı anahtarın aynısı: göç eski değeri bununla
  /// bulur (bkz. [supabasePersistSessionKey]).
  final String persistSessionKey;

  final SecureStore _store;
  final Future<SharedPreferences> Function() _prefs;

  /// Kasa çalışmıyorsa `shared_preferences`'e düşülür.
  bool _fallback = false;

  @override
  Future<void> initialize() async {
    try {
      if (await _store.read(persistSessionKey) != null) return; // göç bitmiş
    } catch (e) {
      _fallback = true;
      syncLog('güvenli depo okunamadı, düz metne düşüldü', error: e);
      return;
    }
    await _migrateFromPlainText();
  }

  Future<void> _migrateFromPlainText() async {
    final prefs = await _prefs();
    final sourceKey = [persistSessionKey, ...legacySessionStorageKeys]
        .where((k) => prefs.getString(k) != null)
        .firstOrNull;
    if (sourceKey == null) return; // taşınacak oturum yok
    final legacy = prefs.getString(sourceKey)!;

    try {
      await _store.write(persistSessionKey, legacy);
      if (await _store.read(persistSessionKey) != legacy) {
        throw StateError('kasaya yazılan değer geri okunamadı');
      }
      await prefs.remove(sourceKey);
      syncLog('oturum belirteci güvenli depoya taşındı');
    } catch (e) {
      _fallback = true;
      syncLog('oturum belirteci taşınamadı, düz metin korundu', error: e);
    }
  }

  @override
  Future<bool> hasAccessToken() async => (await accessToken()) != null;

  @override
  Future<String?> accessToken() async {
    if (!_fallback) {
      try {
        final value = await _store.read(persistSessionKey);
        if (value != null) return value;
      } catch (e) {
        _fallback = true;
        syncLog('güvenli depo okunamadı, düz metne düşüldü', error: e);
      }
    }
    return (await _prefs()).getString(persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (!_fallback) {
      try {
        await _store.write(persistSessionKey, persistSessionString);
        return;
      } catch (e) {
        _fallback = true;
        syncLog('güvenli depoya yazılamadı, düz metne düşüldü', error: e);
      }
    }
    await (await _prefs()).setString(persistSessionKey, persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    // Çıkışta her iki yerden de sil — göç yarıda kalmışsa artık kalmasın.
    try {
      await _store.delete(persistSessionKey);
    } catch (e) {
      syncLog('güvenli depodan silinemedi', error: e);
    }
    final prefs = await _prefs();
    for (final k in [persistSessionKey, ...legacySessionStorageKeys]) {
      await prefs.remove(k);
    }
  }
}

/// supabase_flutter'ın oturumu yazdığı anahtar (`supabase.dart:128` ile aynı
/// türetme). Cihazda doğrulandı: `sb-<proje>-auth-token`.
/// Kütüphanenin `supabasePersistSessionKey` sabiti ESKİ sürümlerin anahtarıdır
/// (bkz. [legacySessionStorageKeys]) — karışmasın diye ayrı ad.
String sessionStorageKey(String supabaseUrl) =>
    'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

/// Göçte ayrıca aranan eski anahtarlar (supabase_flutter 1.x).
const legacySessionStorageKeys = <String>['SUPABASE_PERSIST_SESSION_KEY'];

/// Anahtar kasası yüzeyi — testte taklit edilebilsin diye ayrı.
abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore();

  static const _storage = FlutterSecureStorage(
    // Android: paketin v11 varsayılanı zaten Keystore destekli AES/GCM
    // şifreleme (API 23+; bizim minSdk 24 ✓) — ek ayar gerekmiyor.
    aOptions: AndroidOptions(),
    // iOS: cihaz kilidi açıldıktan sonra erişilebilir, yedeklere GİTMEZ →
    // başka cihaza kopyalanan yedekten oturum çalınamaz.
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
