# 10 — Doğrulama stratejisi

> **Derin inceleme notu (18 Ekim 2026):** Bu raporun düzeltilen iddiaları için bkz. [review/00_SYNTHESIS.md](review/00_SYNTHESIS.md) "Diğer raporlara düzeltmeler".

## Karar özeti

Yeni deneyim, aynı işi daha az hata ve daha az çabayla yaptırıyorsa başarılıdır. Görsel tercih puanı, kayıt doğruluğunu veya erişilebilirliği telafi etmez. Önce güncel sürümün ölçülmemiş başlangıç değerleri toplanmalı, ardından aynı görev ve veriyle önerilen deneyim karşılaştırılmalı. **Bu raporda mevcut başlangıç süreleri, hata oranları, tutma oranı veya memnuniyet puanı uydurulmadı.** Sayısal hedefler aşağıda test edilecek hipotezlerdir.

Öneri: üç kavramın kısa görev karşılaştırması → seçilen yönde aktif seansın etkileşim prototipi → mevcut veriyle aşamalı uygulama → gerçek cihaz ve pilot günlük kullanım → gerekirse düzeltme. Üretim verisi üzerinde silme/geri yükleme deneyi yapılmaz. Tasarım çalışması bu aşamada durur; yeni test kodu ve üretim uygulaması eklenmez.

Samet'ten gereken kararlar: ilk uygulama diliminin kapsamı; pilot dışında gönüllü test katılımcısı bulunması; varsa mahremiyet gözeten ölçüm toplamanın kapsamı. Uygulama içi analitik altyapısı başlangıç gereksinimi değildir; süre ve dokunma sayıları elle, gönüllü kayıtla ölçülebilir.

## 1. Bu çalışmada ne doğrulandı, ne doğrulanmadı?

| Kanıt | Durum | Söylenebilecek sonuç / sınır |
|---|---|---|
| Kaynak, tema ve bileşen incelemesi | Yapıldı; [teknik bulgular](workstreams/technical-accessibility.md) | Hedef kutusu, token, durum kodu ve test kapsamı hakkında kaynak gözlemi; gerçek kullanıcı başarısı değil |
| Renklerin deterministik kontrast hesabı | Yapıldı; Q02 | Belirtilen dolgu/ön renkler için oran; tüm rendered states veya tüm ekranlar geçer/kalır denemez |
| Mevcut kaynakla render testleri | Ana araştırma oturumunda `neon_design_test.dart` + `warm_nutrition_test.dart`, **6/6 geçti**; 76 görüntü üretildi | 393 genişlik koyu TR / açık EN; 320 genişlikte TR %130 / EN %160 kapsamı. Görseller [visuals/current](visuals/current/) içinde. Otomatik gerçek cihaz veya erişilebilirlik sertifikası değil |
| Render logu | `/tmp/fitpack-experience-render.log`; SVG style öğesi için tek uyarı, testler yeşil | “unhandled element <style/>; Picture key: Svg loader” görsel karşılaştırmada ayrıca incelenmeli; tek başına görüntünün bozuk olduğunu kanıtlamaz |
| Simulator çalıştırma | Ana oturum mevcut eski build 1'i açabildi | Güncel main'in tüm yazma/kesinti görevleri simulator üzerinde doğrulanmış sayılmaz |
| Yeni konsept kullanılabilirlik deneyi | Yapılmadı | Öneriler uzman hipotezi; tıklanabilir prototip mevcutsa ayrıca etiketlenir |
| TalkBack / VoiceOver uçtan uca | Yapılmadı | Adsız kontrol riski var; belirli ekran okuyucu başarısızlığı henüz kanıtlanmadı |
| Gerçek telefon tek el / salon / ses / pil testi | Bu araştırmada yapılmadı | Fiziksel erişim, ekran parlaklığı ve ses güvenilirliği için açık doğrulama |
| Davranışsal analitik / anket başlangıcı | Verilmedi, toplanmadı | Bugünkü süre/başarı/tutma oranı bilinmiyor |

Mevcut testlerin varlığı: `test/features/active_session_draft_test.dart:20` taslak durumunu diske yeniden okuyarak kontrol ediyor; `test/features/neon_design_test.dart:33` dar ekran/büyük metin referansı sağlıyor; `test/shared/velocity_navigation_test.dart:75` gezinme semantiği; `test/features/warm_nutrition_test.dart:125` enerji özeti semantiği. Bu araştırmada tüm test takımı yeniden çalıştırılmış gibi bir sonuç sunulmuyor.

## 2. Ölçüm sözlüğü

Tüm süreler **başlangıç olayı → görünür ve kalıcı sonuç** aralığında ölçülür. Ağ gecikmesi, karar süresi ve uygulama gecikmesi ayrı işaretlenir. Yardım istenirse görev “yardımsız başarı” sayılmaz; yardımlı başarı ayrı tutulur. Bir dokunma bir pointer aktivasyonudur; kaydırmalar, klavye vuruşları ve sistem izin adımları ayrı sayılır. Uzun basma veya sürükleme “ücretsiz sıfır adım” sayılmaz.

| Tür / metrik | Tanım ve toplama yöntemi | Başlangıç | Test edilecek hedef / hipotez |
|---|---|---|---|
| Deneyim verimliliği: antrenmana başlama | Açık ana sayfadan doğru önerilen rutinin ilk setinin görünmesine; ekran kaydı ve zaman damgası | Bilinmiyor | Aynı senaryoda medyan süre ≥%20 azalsın; yanlış rutin seçimi artmasın |
| Deneyim verimliliği: set kaydı | Aktif set açık, geçerli değer belirliyken eylemden doğru tamamlanmış duruma; hazırlık/giriş süresi ayrıca | Bilinmiyor | Önceki değerle öneriyi kabul etme için 1 tamamla eylemi korunabilsin; toplam görev süresi ≥%20 azalsın |
| Deneyim verimliliği: sık yemek | Beslenme ekranından bilinen yemeğin doğru miktar/öğüne yazılmasına | Bilinmiyor | Tekrar kullanım senaryosunda medyan ≥%25 azalsın; yanlış miktar oranı artmasın |
| Deneyim verimliliği: dokunma / geri izleme | Doğru kayda kadar dokunma, kaydırma, geri dönüş, düzeltme; gözlemci kodlaması | Bilinmiyor | Birincil görevlerde gereksiz dokunma medyanı ≥%20 düşsün; doğrulama adımları körlemesine kaldırılmasın |
| Görev başarısı | Yardımsız doğru hedefe ulaşan kişi/görev; yanlış veri kaydı başarısız | Bilinmiyor | Kontrollü kritik senaryolarda ≥%90 keşif hedefi; küçük örneklemde popülasyon garantisi değil |
| Hata: yanlış set / miktar / gün | Son kayıt görevin gereğiyle karşılaştırılır; hata türü ve kendiliğinden düzeltme | Bilinmiyor | Her kritik senaryoda 0 fark edilmemiş yanlış kayıt; varsa tasarım revizyonu |
| Keşfedilebilirlik | “Geçen haftayla kıyasla / dünkü öğünü kopyala” görevinde ilk doğru hedef seçimi | Bilinmiyor | En az 8/10 kişi yardımsız doğru alanı bulabilsin; örneklem küçükse sayı mutlak raporlanır |
| Kesintiden dönme | Verilen tüm set/alanlar ve dinlenme deadline'ı dönüşte doğru; cihaz testi | Kaynakta destek var; cihaz oranı bilinmiyor | Test edilen kontrollü senaryoların tamamı doğru; kurtarılamayan son yazım penceresi açık kaydedilir |
| Ürün kullanımı: seans tamamlama | Başlatılan taslaklardan kalıcı kayda dönüşenler; terk/iptal amacı ayrıca | Bilinmiyor | Önce dört haftalık pilot dağılımı; artış hedefi davranış bağlamı görülünce belirlenir |
| Ürün kullanımı: kayıt günleri | Haftada yemek kaydı / tamamlandı işaretli gün; yalnız gönüllü kullanım | Bilinmiyor | Kullanıcının amacına göre yorum; daha fazla kayıt otomatik daha iyi sayılmaz |
| Ürün kullanımı: geri gelme | İlk değerli eylemden sonra 7/28 günlük dönüş, gönüllü yeni kullanıcı grubu | Bilinmiyor | Pilot tek kişide genellenebilir retention (kullanıcıyı tutma) çıkarımı yapılamaz; hedef topluluk oluşunca |
| Memnuniyet: görev kolaylığı | Her görev sonrası 1 çok zor–7 çok kolay tek soru; serbest gerekçe | Bilinmiyor | Medyan ≥6 ve mevcut deneyime göre artış hipotezi; hız artarken kolaylık düşmemeli |
| Memnuniyet: güven | “Kaydın nereye yazıldığını / geri alınacağını biliyorum” 1–7 | Bilinmiyor | Medyan ≥6; yerel ve bulut ayrımını doğru anlatan kişi sayısı ayrıca |
| Kalite: görünür tepki | Dokunmadan ilk görünür değişime; profil build, cihaz frame zamanları | Bilinmiyor | Yerel eylemde p95 ≤100 ms ilk geri bildirim hipotezi; ölçüm koşullarıyla raporla |
| Kalite: kare süresi | UI/raster p95, jank ve en kötü geçiş; Flutter DevTools profile | Bilinmiyor | Cihaz 60 Hz ise 16,7 ms, 120 Hz ise 8,3 ms kare bütçesi referans; yeni sürümde ölçülen jank artmasın |
| Kalite: erişilebilir görev | Okuyucu/büyük yazı/azaltılmış hareketle kritik görevin doğruluğu | Kısmi widget testleri var | Test matrisinde sıfır engelleyici hata; kontrol adı/hedef/kontrast kabulünü ayrı raporla |

Yüzdelik iyileşmeler ürün vaadi değildir. Baseline (başlangıç ölçümü) olmadan “%25 hızlandırdık” denemez. Aynı kişi öğrenme etkisiyle hızlanabilir; deney sırası dengelenmeli. Set tamamlama süresi güç egzersizinin fiziksel süresiyle karıştırılmaz.

## 3. Araştırma planı ve örneklem

**Aşama A — mevcut sürüm başlangıcı:** Samet ile 3 normal kullanım oturumu; antrenman, günlük yemek, haftalık değerlendirme. Ekran kaydı isteğe bağlı ve hassas bilgiler maskeli. Önce sessiz gözlem, görev sonunda neden sorusu; gözlemci öğretmez. Bu pilot ürün kullanımını anlamaya yarar, genel kitle tercihini kanıtlamaz.

**Aşama B — kavram eleme:** erişilebilir görev taraması ve 6–8 gönüllü; yeni başlayan, deneyimli salon kullanıcısı, düzenli beslenme kaydeden ve karmaşık uygulamadan hoşlanmayan kişiler arasında kapsama. Bir kişi birden fazla gruba girebilir; grupları istatistiksel alt örneklem diye yorumlama. Üç kavramın aynı görevdeki sırası dönüşümlü. İlk izlenim sorusu ardından gerçek görev; yalnız “hangisi güzel” oylamasıyla seçim yapılmaz.

**Aşama C — önerilen yön:** revizyon sonrası 8–12 kişiyle mevcut/yeni aynı görev karşılaştırması; ilk gruptan farklı kişiler tercih edilir. Tek el, büyük yazı ve en az iki deneyimli ekran okuyucu kullanıcısının gerçek deneyimi planlanır. Katılımcı bulunamazsa bu kısıt açık yazılır; uzmanın okuyucuyu açması gerçek erişilebilirlik kullanıcı araştırması diye sunulmaz.

**Aşama D — günlük pilot:** en az iki hafta Samet'in olağan kullanımı; kısa günlük “takıldım / yanlış kaydettim / kolaylaştı” kaydı. Kayıt süresi ile antrenman kalitesi veya sağlık sonucu arasında nedensellik iddia edilmez. Kullanım ölçümü istenecekse önce amacı, veri süresi ve kapatma yolu tasarlanır.

Küçük örneklemde medyan, min–maks, kişi başı fark ve hata sayısı verilir; sahte anlamlılık veya dar güven aralığı üretilmez. İstatistiksel karşılaştırma istenirse güç analizi ve gereken örneklem ayrı araştırma işi olur.

## 4. Sabit görev kartları

Her kartta cihaz/dil/tema/veri seti/izin durumu/sürüm/başlangıç ekranı aynı kaydedilir. Sayılar örnek test verisidir; pilotun gerçek beslenme veya sağlık hedefi değildir.

| Görev | Başlangıç ve beklenen doğruluk | İzlenecek sürtünme |
|---|---|---|
| T1 — sıradaki antrenman | Dolu ana sayfadan önerilen rutini aç, ilk harekete ulaş; öneri döngüsü test verisinde belli | Kartı bulma, yanlış rutin, gereksiz rota |
| T2 — öneriyle set | Önceki 77,5×8, öneri 80×8; boş seti tamamla; kayda 80×8 yazılmalı | Öneriyi gerçek sanma, minik ✓, çift dokunuş |
| T3 — değiştir ve geri al | Ağırlığı 82,5 yap, seti tamamla, sonra geri al; doğru set etkilenmeli | Alan birimi, focus, satır karışması |
| T4 — RPE | Algılanan zorluk 8,5'i seç, açıklamayı anla, onayla, temizle | Sekiz seçenek sığması, büyük yazı, RPE anlamı |
| T5 — dinlenme kesintisi | 90 sn başlat, arka plana al, +15 sn yerel kart eylemi, dön; kalan gerçek deadline ile tutarlı | Sayaç çakışması, çift bildirim, yanlış set |
| T6 — sık yemek | Önceden kullanılan yemeği 150 g olarak öğlen öğününe ekle | Tekrar arama, miktar/birim varsayımı, kaydet sonucu |
| T7 — kopyalama / tarih | Geçmişten öğünü seçip bugüne kopyala; aynı günde çift dokunma yok | Hangi gün/öğün, yinelenen kayıt, geri al |
| T8 — çevrimdışı | Kayıtlı yiyeceği uçak modunda ekle; yerel sonuç doğru; bulut beklediği anlaşılır | İnternet yok=veri yok sanma, sonsuz spinner |
| T9 — veri az / değerlendirme | 1 kilo noktası ve eksik beslenme günü; “ne biliyoruz?” sorusunu yanıtla | Uydurma trend, eksik günü sıfır tüketim sanma |
| T10 — erişilebilir kayıt | Aynı set ve yemek görevini ekran okuyucu veya büyük yazıyla tamamla | Adsız ikon, focus tuzağı, gizli etiket, kapanmayan panel |

## 5. Kesinti ve durum matrisi

Kontrollü sahte veri ve ayrı test veritabanı kullanılır. Çıkış/hesap değişimi veya gün dönümü gibi kritik durumlarda yalnız görsel sonuca değil doğru kullanıcıya ait doğru satıra bakılır.

- **Lifecycle:** uygulama açık → bildirim perdesi → arka plan 30 sn / 3 dk → ekran kilidi → geri dönüş; sistemin süreci öldürmesi → yeniden açılış; hızlı girip hemen arka plana geçme. `active_session_screen.dart:371` belgelenmiş 500 ms + yazım süresi penceresini dikkate al. “Her koşulda sıfır kayıp” sözü verilmez.
- **Saat:** dinlenme bitmeden/bitince dönüş; +15 / atla / yeni molaya hızlı geçiş; gece yarısı; saat dilimi değişimi; tarihsel seans kaydı. Mevcut deadline ve gün dönümü düzeltmelerini yeniden bozmama testi.
- **Ağ:** kayıt öncesi/sonrası uçak modu; yavaş yanıt; timeout; eski arama yanıtı; bağlantı geri geldiğinde yinelenen kayıt olmadan tazeleme. Arama sonucu yok ile servis erişilemiyor ürün düzeyinde ayırt edilecekse servis sözleşmesinin buna yeterliliği kontrol edilir.
- **İzin:** kamera ilk istek/ret/sonradan izin; fotoğraf sınırlı erişim; sağlık kullanılamaz/kurulum gerekli/veri yok; bildirim ret; Live Activities kapalı. iOS sağlık okuma reddi kesin bilinemediği için “reddettin” mesajı beklenmez (`step_source.dart:25`).
- **Ses:** müzik çalarken, sessiz mod, Odaklanma, bildirim ses kapalı, uygulama sesi açık/kapalı; +15/atla sonrası eski sesin çalmaması. Sistemin uygulayacağı sessizlik hata ile karıştırılmaz. Android gerçek Samsung pil yönetimi ayrıca gerekir.
- **Yanlışlık:** çift tamamla, eski kilit kartı eylemi, seti silerken başka alana focus, geri tuşu, paneli sürükleyerek kapatma, silme sonrası “Geri al” ve ekran değiştirme. Geri alınabilir işlem için sürekli onay diyaloğu eklemek yerine doğru geri al davranışı tercih edilir.
- **Hata:** veritabanı yazımı başarısız; spinner bitmeli, taslak/input kalmalı, yeniden deneme aynı kaydı çoğaltmamalı. Geri yükleme ve hesap silme gibi riskli akışlar yalnız izole hesapta; bu tasarım diliminde değiştirilmez.

## 6. Erişilebilirlik kabul ölçütleri

Hedef, mobil görev erişilebilirliğidir; WCAG (Web Content Accessibility Guidelines; Web İçeriği Erişilebilirlik Kılavuzu) maddeleri test referansı sağlar. “WCAG sertifikalı” iddiası bu incelemeden çıkmaz.

| Alan | Kabul / yöntem |
|---|---|
| Dokunma alanı | Yüksek sıklıklı özel kontrollerde ≥48×48 mantıksal piksel ve çakışmayan alan. Android 48 dp tavsiyesi; web AA 2.5.8'in 24 CSS piksel eşiği ve istisnaları farklıdır. [Android](https://developer.android.com/guide/topics/ui/accessibility/views/apps-views), [W3C](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) |
| Metin kontrastı | Gerekli normal metin ≥4,5:1; büyük metin ≥3:1. Öneri/placeholder da dâhil; disabled istisnası gerçek devre dışı hâle özgü. Token + alfa + arka yüzey kombinasyonu ölçülür. [W3C kontrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) |
| Metin dışı bilgi | Gerekli kontrol sınırı, focus ve anlam taşıyan grafik parçaları için komşu renge karşı ≥3:1 gereken bağlamlarda kontrol; dekoratif kart kenarının zayıf olması tek başına hata değil. [W3C metin dışı kontrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html) |
| Semantik | Tamamla/geri al hedef hareket+set+durumla okunur; giriş adı+birim; seçili ve disabled durum; dekoratif ikon tekrar okunmaz; işlem sonucu anlaşılır |
| Focus | Mantıklı sıra, görünür focus, modal açılınca içeride kalma ve kapanınca tetikleyiciye dönüş; odaktaki kontrol bar/klavye altında kalmaz |
| Büyük yazı | 320/360/393/430, linear %100/130/160/200 + gerçek sistem en büyük ayar. Kritik etiket/değer/eylem kesilmeden görev biter; yazıyı küçülterek geçme yok |
| Hareket | Sistem tercihi açıkken dekoratif tekrar yok, progress son doğru değeri anında sunar; süre/iş mantığı animasyona bağlı değil |
| Renk | Grayscale ve renk görme benzetimi; trend/seri/uyarı renk dışında etiket/işaret içerir |
| Ses/dokunma | Ses tek doğrulama yolu olmaz; izin yoksa uygulama içi durum çalışır; her saniye ekran okuyucu anonsu yok |

Flutter Guideline API; hedef, etiket ve kontrast için hedefli widget testleri önerir. Bunlar tüm yardımcı teknolojileri veya native kilit ekranı ağacını kontrol etmez. [Flutter resmî test rehberi](https://docs.flutter.dev/ui/accessibility/accessibility-testing). Canlı Etkinlik etiketleri ve izin durumları SwiftUI/ActivityKit tarafında ayrı test edilir. [Apple ActivityKit](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities).

## 7. Mühendislik ve yayın kapıları

1. **Araştırma kapısı:** öneri–kanıt bağı, üç yönün trade-off'u (kazanım/bedel), testlenebilir görev; başlangıç verisi bilinmiyorsa açık ifade. Görseller mevcut sürüm / öneri diye etiketli.
2. **Prototip kapısı:** T1–T10'un ilgili alt kümesi; kritik hata yok; büyük yazı ve ekran okuyucu kontrolü; yanlış öneri–giriş anlaşılması revize edilmiş.
3. **Uygulama kapısı:** repository kuralları; `flutter analyze` sıfır; mevcut `flutter test` yeşil; değişen mantık ve kritik semantik/hedef testleri; yaşam döngüsü kaynakları dispose; kayıt provider'ları güncel; rota `AppRoutes` üzerinden. Şema değiştirmeyen ilk dilim göç gerektirmez.
4. **Cihaz kapısı:** iOS + Android'de gerçek build; açık/koyu, Türkçe/İngilizce, dar ekran/büyük yazı; klavye ve geri hareketi; yerel kart/bildirim; screenshot ve sürüm kaydı. Eski simulator build veya widget render testi cihaz kapısını karşılamaz.
5. **Pilot kapısı:** iki hafta günlük kullanım; fark edilmemiş yanlış kayıt veya veri kaybında dağıtım durur; geri dönüş mevcut veriyle güvenli. Lokal kayıt çalışırken bulut kuyruğunun beklemesi farklı durum olarak raporlanır.

`flutter test` sayısı kalite ölçüsü değildir; ilgili davranış kapsama haritası tutulur. Üretim verisine dokunan test ve ayrıntılı analitik varsayılan olarak eklenmez. Prototip için sahte fixture (sabit test verisi) kullanılır.

## 8. Sonuç raporlama şablonu

Her görev için `sürüm / cihaz / dil / tema / yazı ayarı / veri seti / n / yardımsız başarı / medyan süre / dokunma / hata / kolaylık / not` kaydı. Önce kişi bazlı mevcut→yeni fark, sonra toplam medyan. İptal/bitmeyen görevler süre hesabından gizlice çıkarılmaz; ayrı raporlanır. Veri ve ekran kayıtları katılımcı rızası, en az gerekli kapsam ve kararlaştırılmış silme süresiyle tutulur.

Karar kuralları: görünüm beğenisi yüksek ama doğru kayıt azaldıysa tasarım geçmez; hız arttı ama güven düştüyse durum dili revize edilir; tek el kolaylaşıp büyük yazı engellendiyse bileşen varyantı düzeltilir; yeni tasarım anlamlı fark üretmiyorsa daha küçük ve bakımı kolay değişim tercih edilir.

## 9. İlk kilometre taşının başarı tanımı

Q01–Q04 + Q08'in aktif seans kapsamı: belirgin ve erişilebilir tamamla/geri al; okunur öneri–giriş ayrımı; yeterli dokunma hedefi; dinlenme ve taslak davranışının korunması; azaltılmış hareket tutarlılığı. İlk uygulama onayı verilince başlangıç ölçümü T2–T5 ve T10 için alınır. Uygulama sonrasında aynı görev tekrar edilir. Daha hızlı olduğuna ilişkin hipotez sağlanmasa bile doğruluk ve erişilebilirlik kazanımı kanıtlanabilir; bütün sonuçlar ayrı yazılır. Başarılı kabul kararı henüz verilmedi.
