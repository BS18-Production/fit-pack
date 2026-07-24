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
  /// **"Client ID (for OAuth)"** değeriyle AYNI olmalı — `...apps.
  /// googleusercontent.com` biçiminde. Android client değil, Web client:
  /// `signInWithIdToken`'ın doğruladığı `aud` budur.
  ///
  /// **BOŞ bırakılırsa** giriş otomatik olarak eski **tarayıcı akışına** düşer
  /// (çalışıyor, sadece daha az akıcı). Samet bu ID'yi yapıştırınca Android
  /// hesap seçici (native) devreye girer ve izin ekranındaki ham `supabase.co`
  /// sorunu (B-1) ortadan kalkar.
  static const String googleWebClientId = '';
}
