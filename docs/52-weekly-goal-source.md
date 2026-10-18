# Haftalık hedefin tek kaynağı

## Karar özeti

Kurulumda seçilen sıklık kaybolduğu için ana sayfa yanlış hedef gösteriyor;
haftalık değerlendirme ve asistan başka hesap kullanıyor. Öncelik: kullanıcının
seçimi → aktif programın gün sayısı → benzersiz planlı gün → 3.

Öneri: hesap kimliğine bağlı yerel tercih (`weekly_goal_v1_<userId>`).
Şema ve senkron değişmez. Senkronlanan profil seçeneği bu işte elendi;
başka cihazda seçim yoksa senkronlanan program/plan üzerinden hesaplanır.
Mevcut kayıtlar değişmez; eski sürüme dönmek güvenlidir (tercih yok sayılır).
Samet'in K7 öncelik onayı mevcut; yeni karar gerekmiyor.

Doğrulama: hesap değiştirme, tercih yükleme/yazma hatası, program/plan/fallback
önceliği; ana sayfa, haftalık değerlendirme ve asistanın aynı hedefi okuması.

## Sözleşme

- Kurulum cevapları aralık: 2–3 → 3, 4 → 4, 5–6 → 6. Aralığın üst sınırı
  haftalık hedef olur. Başlangıç programı daha az gün önerse de açık kullanıcı
  tercihi önceliklidir.
- Birden çok aktif program varsa en yüksek `daysPerWeek` alınır; rutin
  kopyaları aynı programı çoğaltmaz. Arşiv program hedefini etkilemez.
- Tercih yalnız giriş yapan hesabın anahtarıyla okunur/yazılır. Oturum yoksa
  yazılmaz. Hesap değişince eski async sonuç yeni hesabın hedefi olmaz.
- Tercih başka cihaza taşınmaz, uygulama verisi temizlenince kaybolur. Hesap
  silinip yeniden oluşturulursa yeni kimlik eski tercihi okumaz.
- Hedef değişikliği mevcut seri hesabına ve eski haftanın değerlendirmesine de
  uygulanır; geçmişe özel hedef tarihçesi bu sürümde yoktur. Günlük plan ve
  kaçırılmış gün hesabı gerçek planlı günleri kullanmaya devam eder.
- Okuma hatası varsayılana çevrilmez; tüketen sağlayıcılara hata taşınır.
