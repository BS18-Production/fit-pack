/// Supabase bağlantı bilgileri (docs/13-cloud-backup.md).
///
/// publishable (anon) key uygulamaya gömülmek için tasarlıdır — RLS (Row Level
/// Security) verileri korur, bu yüzden istemcide bulunması güvenlidir. Yine de
/// `service_role` / secret anahtarı BURAYA ASLA konmaz (sadece sunucu tarafı).
class SupabaseConfig {
  static const String url = 'https://jkviihbyogktwboreydn.supabase.co';
  static const String anonKey =
      'sb_publishable_kOvpAdgwp-WCV7erTa1baw_lfexIr-t';

  /// Google yerel (native) giriş için **Web** OAuth client ID'si (docs/18
  /// §5.2.1 D). Supabase → Authentication → Providers → Google'daki
  /// **"Client ID (for OAuth)"** değeriyle AYNI olmalı. Platform client'ı
  /// değil, Web client'ı: `signInWithIdToken`'ın doğruladığı `aud` budur.
  ///
  /// **BOŞ bırakılırsa** giriş her platformda **tarayıcı akışına** düşer.
  static const String googleWebClientId =
      '1090099755341-i184afject30b47qr60r6sjeote3palb.apps.googleusercontent.com';

  /// iOS yerel akışının hazır olup olmadığı. Asıl client ID `ios/Runner/
  /// Info.plist` içindeki `GIDClientID`'de durur (eklenti yapılandırmayı
  /// oradan okur) — burada yalnız akış seçimi için bayrak tutulur.
  static const bool googleNativeOnIos = true;

  /// Android yerel akışı **kapalı**: Google'ın Android client'ı (paket adı +
  /// SHA-1 imza parmak izi) henüz oluşturulmadı. Bayrak açılmadan yerel akış
  /// denenirse giriş `ApiException: 10` ile başarısız olur; kapalıyken
  /// Android bugün çalışan tarayıcı akışında kalır (docs/18 §5.2.1 D).
  static const bool googleNativeOnAndroid = false;
}
