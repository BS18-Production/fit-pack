/// Supabase bağlantı bilgileri (docs/13-cloud-backup.md).
///
/// publishable (anon) key uygulamaya gömülmek için tasarlıdır — RLS (Row Level
/// Security) verileri korur, bu yüzden istemcide bulunması güvenlidir. Yine de
/// `service_role` / secret anahtarı BURAYA ASLA konmaz (sadece sunucu tarafı).
class SupabaseConfig {
  static const String url = 'https://jkviihbyogktwboreydn.supabase.co';
  static const String anonKey =
      'sb_publishable_kOvpAdgwp-WCV7erTa1baw_lfexIr-t';
}
