# Velocity · FitPack özel ikon ailesi

## Karar özeti

Samet 2026-10-08 tarihinde Signature Icons görselini ve Velocity'nin dolu
lime sekme seçimini onayladı; uygulamaya aktarımı ve iPhone'a güncellemeyi
istedi. Dört ana ikon aynı eğimli/dolu geometrik aileden çizildi. Raster
çalışma uygulama varlığı değildir; 24 birimlik SVG'ler yereldir.

Veri etkisi: yalnız sunum katmanı değişir. Şema v14, hesap, senkron,
seans/öğün/ölçüm kalıcılığı ve rotalar değişmez. Sekmelerin IndexedStack
ile durumu/scroll konumu ve aynı sekmeye dokununca köke dönüş korunur.

## Uygulama

- `assets/icons/fitpack/`: dört ana + 19 eylem/yardımcı SVG.
- `FitPackIcon`: tema rengi, boyut, opaklık ve erişilebilir ad. Mevcut
  IconData kullanan bileşenler adaptörle bağlandı; karşılığı olmayan
  özel anlamlı simgeler eski Material biçimini korur.
- `VelocityNavigation`: dört eşit dokunma alanı; seçili simge ve etiket
  aynı kapsülde. Koyu temada lime/koyu, açık temada yüksek kontrastlı
  primary/onPrimary. Pasifler onSurfaceVariant. Hafif gölge, blur yok.
- Geçiş 160 ms; cihazın azaltılmış hareket tercihinde sıfır süre.
  Büyük metinde görsel etiketler saklanır; Semantics/Tooltip korunur.
- Ortak butonlar: 12 px köşe, birincil minimum 54 px; ikincil opak ve
  nötr. Antrenman ortak başlat/kaydet bileşeni Material FilledButton
  davranışını kullanır; busy/onTap kilidi korunur.
- Antrenman başlık eylemleri dar ekran/büyük metinde ayrı satırdadır;
  rutin oluşturma ve serbest antrenman düğmeleri alt alta durur.

## Doğrulama

Analiz 0 sorun. 740 test geçti. Yeni dört widget testi sekme hedefi/tek
kapsül, 320 pt/%160 metin, iki tema, Semantics, azaltılmış hareket ve
23 SVG'nin çizilmesini doğrular. Mevcut işlem testleri yeni ikon
çiziminden bağımsız kontrol anahtarı/tooltip ile aynı iş akışını sınar.
Gerçek router/örnek verilerle dört sekme ve detaylar TR/EN, koyu/açık,
320 pt ve %130/%160 yazıda render edildi. Son başlık düzeni ayrıca aynı
render testleriyle yeniden kontrol edildi: 8 odaklı test geçti.

## iPhone teslimi

2026-10-08 07:41 tarihinde Xcode arayüzünden yeni Release arşivi üretildi:
`~/Library/Developer/Xcode/Archives/2026-10-08/Runner 8.10.2026, 07.41.xcarchive`.
Bundle kimliği `com.sametorhan.fitPack`, takım `DQBCHYZUU7`, mimari arm64.
Arşivdeki 23 SVG güncel kaynaklarla bayt düzeyinde aynı; mevcut
`WorkoutLiveActivity.appex` eklentisi paket içinde.

Device Hub / Apps / Add ile bu arşivin `Runner.app` paketi Samet'in
**iPhone 17 (iOS 26.6)** cihazına mevcut uygulamanın üzerine yüklendi.
Kurulum ilerlemesi tamamlanıp normal cihaz durumuna döndü; hata yok.
Uygulama kaldırılmadı, container değiştirme/silme yapılmadı.
Ardından Apps / Fit Pack / Launch komutu gönderildi; arayüzde hata yok.

Komut satırı `codesign --verify --deep --strict` bu oturumda sertifika
güven doğrulamasını `CSSMERR_TP_NOT_TRUSTED` ile tamamlayamadı; önceki
başarılı 7 Ekim arşivinde de aynı sonuç var. Bu nedenle bağımsız CLI imza
kontrolü başarılı diye raporlanmaz. Xcode imzalı arşivi oluşturdu ve
Device Hub cihaz kurulumunu tamamladı.

Device Hub ekran paylaşımı iOS 27+ istiyor; telefon iOS 26.6. Yeni sürümün
telefon üzerindeki ekranları Mac'ten görsel olarak kontrol edilemedi.
TR/EN, iki tema ve dar/büyük metin render kontrolleri geçti; gerçek
telefon görünümü ve kayıtların uygulamada görünmesi Samet'in kontrolünde.
