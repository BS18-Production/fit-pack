# Performans Günlüğü — Neon tasarım geçişi

## Karar özeti

Samet 2026-10-04'te Ana Sayfa prototipini onayladı ve aynı tasarım dilinin
tüm uygulamaya, mevcut işlevler korunarak uygulanmasını istedi. Mat kömür
zemin (`#121212`), neon lime (`#CCFF00`) ana eylem, elektrik turuncusu
(`#FF5E00`) enerji/karbonhidrat vurgusu; okunaklı tipografi, yuvarlatılmış
opak kartlar, hafif gölge, cam hissi veren kalori halkası kullanılacak.

**Seçim:** Flutter'ın mevcut Material tema rollerini ve ortak bileşenlerini
yenilemek, Ana Sayfa'yı onaylı kompozisyona taşımak. Her ekrana ayrı renk
yazmak elendi; böylece girişten set paneline kadar aynı dil korunur.

**Gerçek veriye etkisi:** şema, sunucu, senkron, hesap sahipliği, kayıt ve
hesap kuralları değişmez. Mevcut kayıtlar aynı sağlayıcılardan okunur.
Yeni kullanıcı için koyu tema varsayılandır; kayıtlı tema tercihleri ve
Açık / Koyu / Sistem seçenekleri korunur. Renk değişimi geri alınabilir.

**Gereken karar:** tasarım ve tüm uygulama geçişi bu sohbet içinde onaylandı.

**Doğrulama:** analiz, tüm mevcut testler, dar ekran/büyük metin/açık-koyu
görünümler; gerçek Flutter render'larında Ana Sayfa, dört sekme ve giriş,
form, panel, aktif seans ekranlarını kontrol et. Cihaz/simülatör erişim
engeli varsa hangi doğrulamanın tamamlanamadığı açıkça kaydedilecek.

## Görsel kurallar

- Material `primary`: koyuda lime, açıkta metin kontrastı için koyu zeytin.
  Lime dolgu üzerinde koyu içerik. İkincil marka vurgusu turuncu.
- Semantik başarı, hata ve bilgi rolleri ayrı kalır; anlam yalnız renkle
  verilmez. Makrolar: protein lime, karbonhidrat turuncu, yağ sıcak nötr.
- Mat opak kartlar; liste kartlarında canlı arka plan bulanıklığı kapalı.
  Sayfa zemininde büyük renkli ışıma bulutları kaldırılır.
- Kart, düğme, input, panel, dialog, menü, tarih seçici ve gezinme temaları
  aynı renk ve köşe token'larını kullanır.
- Tema rolleri, AppSpacing / AppRadius ve lokalizasyon mevcut kurallarla
  kullanılır; kamera ve fotoğraf üstü okunabilirlik ayrı tutulur.

## Ana Sayfa

1. Fitpack marka başlığı, bugünün tarihi, profil bağlantısı.
2. Haftalık şerit: önceki/sonraki hafta, gün kayıtları, ay görünümü aynen.
3. Günlük enerji ve makrolar: gerçek beslenme kaydı ve kişisel hedef;
   kalan/aşım metni, tüketilen ve hedef enerji, üç makro ilerlemesi.
4. Bugünün antrenmanı: devam eden taslak > plan > dinlenme > başlangıç.
   Mevcut önizleme ve devam rotaları kullanılır.
5. Öğün günlüğü: üretilmiş somon salatası görseli yalnız temsili öğün fikri;
   kayıtlı yemek, kişisel tavsiye veya hesaplanmış porsiyon gibi gösterilmez.
   Yemek ekle mevcut paneli açar; alışılmış öğün ve geri alma korunur.
6. Aktivite grafiği: prototipteki saatlik örnek değerler üretime taşınmaz.
   Mevcut gerçek antrenmanlardan son yedi günün tahmini yakımı gösterilir.
   Kayıt olmayan gün ile tahmin hesaplanamayan seans ayrılır; veri yoksa
   boş durum. Tahmin mevcut kalori motorunu kullanır.
7. Haftalık ritim, son 30 gün, içgörü, su ekle/sıfırla ve son kilo korunur.

## Uygulama genelinde kapsam

| Alan | Ortak geçiş + korunacak işlevler |
|---|---|
| Kabuk | Dört sekme, canlı dal durumu, kaydırma ve geri davranışı |
| Antrenman | Rutinler, önizleme, oluşturma, ısınma, kütüphane, geçmiş, özet |
| Canlı seans | Set girişi, sayaç, mola sesi, sıra, kilo adımı, efor seçici |
| Beslenme | Kalori/makro, tarih, öğünler, arama, porsiyon, barkod, kopyalama |
| İlerleme | Kilo/hedef, ölçüm, grafik, fotoğraf ve karşılaştırma |
| Takvim/hafta | Gün kayıtları, haftalık değerlendirme, veri kaynakları |
| Profil/ayarlar | Hedefler, birim, dil, tema, bildirim, atıf/lisans |
| Hesap | Karşılama, giriş, parola, kurulum, bulut ve hesap kapıları |
| Sistem | Açılış, hata, yükleme, boş durum, güncelleme kapısı |

Temalar bu ekranların tümüne uygulanır. Durum makineleri, veritabanı
işlemleri, bildirim yaşam döngüsü ve navigasyon sözleşmeleri değiştirilmez.

## Kaynak

Onaylı interaktif prototip: `fitpack-performance-journal.html` (bu sohbet).
Somon görseli aynı prototip için üretildi; JPEG mobil boyutta yerel asset
olarak paketlenir, ağ bağımlılığı eklenmez.

Plus Jakarta Sans Regular / Medium / SemiBold / Bold / ExtraBold font
dosyaları yerel paketlenir. Lisans: `assets/fonts/OFL.txt` (SIL Open Font
License). Font dosyaları Google Fonts paketinin beklediği SHA-256 değerleri
ile doğrulanmıştır; görsel testler bu gerçek fontu yükler.

## Kod rehberi

- Palet: `lib/core/theme/app_colors.dart`; tipografi ve Material bileşenler:
  `app_theme.dart`; köşeler: `app_dimens.dart`.
- Yüzeyler ve dört sekme: `lib/shared/widgets/glass.dart`, `app_shell.dart`.
- Ana Sayfa: `lib/features/home/home_screen.dart`; enerji/makro bileşeni:
  `lib/features/nutrition/nutrition_summary_card.dart` (Beslenme de kullanır).
- Öğün fikri: `meal_idea_card.dart`. Görselden otomatik yemek kaydı oluşmaz.
- Aktivite: `workout_activity.dart` saf hesap, `workout_activity_card.dart`
  grafik, `providers/dashboard_providers.dart` reaktif veri.
- Gün değişiminde yeni grafik sağlayıcısı mevcut DayRolloverGuard içinde
  tazelenir. Seans/set/kilo değişimi `watchTables` üzerinden izlenir.
- Takvim halkaları kalori / protein / antrenman / su için dört ayrı renk
  kullanır; legend ve gün özeti aynı rolleri paylaşır.
- Dar ekran/büyük metinde makrolar, rutin set-tekrar alanları ve grafik
  tarihi ayrı satırlara geçer. Çok büyük metinde alt çubuk ikonlara döner;
  sekme adları erişilebilirlik ve uzun basma açıklamalarında korunur.
- `test/helpers/design_fixture.dart` yalnız bellekte örnek veriler ve test
  kapısı içerir. Üretim giriş kapısı ve `main.dart` değiştirilmemiştir.

### Tekrar doğrulama

```sh
flutter analyze
flutter test
python3 tools/check_docs.py
# Gerçek Flutter widget görüntüleri, isteğe bağlı:
FITPACK_CAPTURE_DIR=/tmp/fitpack-neon-previews flutter test test/features/neon_design_test.dart
```

## Doğrulama kaydı

2026-10-04:

- `flutter analyze`: 0 sorun.
- Tam test paketi: **696/696** geçti (hareket kataloğunun eşzamanlı güncel
  sürümü dahil). Son grafik/sekme metni düzenlemesinden sonra dört görsel
  senaryo yeniden geçti.
- Beş yeni saf hesap testi: yıl sınırı, çoklu seans toplamı, eksik kilo,
  kısmi tahminin toplam gibi gösterilmemesi ve kardiyo tahmini.
- Dört gerçek router/DB widget senaryosu: koyu TR, açık EN, 320 pt/%130 TR,
  320 pt/%160 EN. Ana Sayfa kaydırma, yemek panelini açma, dört sekme,
  rutin önizleme/düzenleme, geçmiş/özet, hareketler, besinler, profil,
  ayarlar, takvim, hafta değerlendirmesi ve fotoğraf sayfası kontrol edildi.
  PNG'ler gerçek Flutter render'ıdır; veriler test örneğidir.
- Dar görünümde öğün başlığı, antrenman düğmesi, rutin tekrar alanı ve ay
  gezinmesinde taşmalar düzeltildi. Büyük metinde grafik etiketlerinin
  çakışması ve sekme adlarının bölünmesi görsel kontrolde giderildi.
- Android debug APK, ayrı önizleme paketinde gerçek ekranlar ve bellekte
  örnek veriler ile başarıyla derlendi. Üretim paketine kurulum yapılmadı.
- **Cihaz kontrolü açık:** çalışan Android emülatörü ADB listesinde görünse
  de shell/kurulum/ekran görüntüsü çağrılarına yanıt vermedi (12 saniyelik
  kontroller de zaman aşımına uğradı). Önizleme kurulumu doğrulanamadı.
- **iPhone/iOS kontrolü açık:** SDK cache ve CoreSimulator dizinlerine yazma
  izni otomatik onay incelemesince reddedildi. Yerel SDK kopyasıyla kod ve
  Android derleme kontrolleri yapıldı; iPhone'a kurulum yapılmadı.

CONVENTIONS §7 cihazda görsel kontrol şartı henüz kapanmadı; kod ve otomatik
kontroller hazır, fiziksel cihaz kontrolü ayrı açık madde olarak tutulur.

### iPhone güncellemesi — 2026-10-07

Neon tasarım ve seçilen FP ikonuyla Xcode 27 Release arşivi derlendi;
imza doğrulaması başarılı. Arşivde Plus Jakarta Sans, somon görseli ve
kaynakla piksel olarak aynı yeni iPhone ikonu bulunuyor. Device Hub / Apps /
Add ile iPhone 17'deki mevcut uygulamanın üzerine yüklendi; kaldırma ve
uygulama veri klasörü değiştirme yapılmadı. Önceki iPhone kurulum maddesi
bu tarihte tamamlandı.

Komut satırındaki Xcode/CoreDevice çağrıları bu oturumda çalışmadı; Xcode
arayüzünde arşiv ve Device Hub'da yükleme tamamlandı. Telefon iOS 26.6
kullanıyor; Device Hub ekran paylaşımı iOS 27+ gerektirdiğini bildirdi.
Bu nedenle gerçek telefonda dört sekme ve işlem akışlarının son görsel
kontrolü açık kalıyor. Kod analizi 0 sorun, 696 test yeşil.
