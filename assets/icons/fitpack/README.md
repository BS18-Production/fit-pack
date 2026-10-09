# FitPack · Velocity vektör ailesi

2026-10-08 tarihinde Samet'in onayladığı Signature Icons çalışmasından
uygulama için el ile yeniden çizildi. Raster tasarım görseli uygulamada
kullanılmaz. Her dosya 24 × 24 birim SVG'dir; tema rengi `FitPackIcon` ile
uygulanır. Yeni font/harici servis yok; vektörler çevrimdışı paketlenir.

- Ana aile: `home`, `workout`, `nutrition`, `progress` — dolu siluet,
  ileri eğim, negatif alan; seçili/pasif durumda şekil değişmez.
- Eylemler: ekle, başlat, oklar, düzenle, geçmiş, ayarlar, onay/kapat,
  tarama, kopyalama, silme, takvim, kütüphane, profil, kilo ve su.
- `FitPackIcon.material` mevcut `IconData` kabul eden bileşenleri uyumlar;
  ailede karşılığı olmayan özel anlamlı ikonlar Material olarak çizilir.
- Standart 24 px, gezinmede 26 px; dokunma alanı en az 48 px.
- Seçili sekme koyu temada lime + koyu ikon/metin; açık temada yüksek
  kontrastlı Material `primary/onPrimary`. 160 ms geçiş, azaltılmış
  hareket tercihinde sıfır süre. Büyük metinde etiketin erişilebilir adı
  korunur; görsel etiketler çakışmayı önlemek için saklanır.

Kaynak kontrolü: `test/shared/velocity_navigation_test.dart` tüm SVG'leri
çizdirir; sekme hedefi, seçili kapsül, renk aktarımı, erişilebilirlik,
320 pt/%160 metin ve azaltılmış hareketi doğrular. Gerçek ekran render'ları:
`test/features/neon_design_test.dart`.
