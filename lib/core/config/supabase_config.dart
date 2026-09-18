/// Supabase bağlantı bilgileri (docs/13-cloud-backup.md).
///
/// publishable (anon) key uygulamaya gömülmek için tasarlıdır — RLS (Row Level
/// Security) verileri korur, bu yüzden istemcide bulunması güvenlidir. Yine de
/// `service_role` / secret anahtarı BURAYA ASLA konmaz (sadece sunucu tarafı).
class SupabaseConfig {
  /// Üretim projesi (`Fit Pack`). **Derleme zamanında** değiştirilebilir:
  ///
  /// ```
  /// flutter run \
  ///   --dart-define=SUPABASE_URL=https://qecbnrkbordkqeogmevi.supabase.co \
  ///   --dart-define=SUPABASE_ANON_KEY=sb_publishable_aQZzc4k4q8DSZ5VQdCujTQ_nfOMZmw4
  /// ```
  ///
  /// Böylece senkron değişiklikleri **test projesine** (`Fit Pack Dev`) karşı
  /// denenir; gerçek antrenman verisine dokunulmaz (docs/20 §10.4).
  /// Varsayılan üretimdir — bayrak unutulursa uygulama normal çalışır, yanlış
  /// yere yazmaz.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jkviihbyogktwboreydn.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_kOvpAdgwp-WCV7erTa1baw_lfexIr-t',
  );

  /// Test projesine bağlı mıyız? Arayüzde/günlükte uyarı göstermek için.
  static bool get isDevProject =>
      !url.contains('jkviihbyogktwboreydn');

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
