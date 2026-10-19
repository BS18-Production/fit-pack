# Öncelikli ürün ve deneyim fırsatları

> **Derin inceleme notu (18 Ekim 2026):** Bu raporun düzeltilen iddiaları için bkz. [review/00_SYNTHESIS.md](review/00_SYNTHESIS.md) "Diğer raporlara düzeltmeler".

18 Ekim 2026 · Kaynak sürümü `07104d1` · Üretim değişikliği yok.

## Puanların anlamı

Tüm puanlar uzman tahmini; ölçülmüş kullanıcı tercihi veya etki büyüklüğü değildir. Her boyutta 1 en düşük, 5 en yüksek. **Karmaşıklık ve riskte yüksek puan maliyettir.** Güvende 1 doğrulanmamış varsayım, 3 kaynak + makul hipotez, 5 doğrudan kaynak/hesapla saptanan sorun; çözümün kullanıcı etkisi yine test ister. Sıklık günlük pilot kullanım varsayımına dayanır; kullanım analitiği yok.

Etki: tek ikincil iş → kritik günlük iş. Kullanılabilirlik: küçük kolaylık → görev engelini azaltma. Görsel: yerel cila → sistemsel hiyerarşi. Sıklık: seyrek ayar → her sette/öğünde. Ayrışma: standart beklenti → ürünün ayırt edici değeri. Karmaşıklık: token/yerel değişiklik → çapraz platform durum sahipliği. Risk: izole görünüm → veri/arka plan davranışı. Güven problem kanıtının gücüdür; başarı garantisi değildir.

| ID / fırsat | Etki | Kullanılabilirlik | Görsel | Sıklık | Ayrışma | Karmaşıklık | Risk | Güven | Faz |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| P01 Set kontrolü erişimi | 5 | 5 | 3 | 5 | 3 | 2 | 2 | 5 | 1 |
| P02 Öneri kontrastı ve anlamı | 5 | 5 | 3 | 5 | 2 | 1 | 1 | 5 | 1 |
| P03 Ekran okuyucu set sözleşmesi | 5 | 5 | 1 | 4 | 2 | 2 | 2 | 4 | 1 |
| P04 Ana sayfada eylem önceliği | 5 | 5 | 5 | 5 | 3 | 2 | 2 | 5 | 1→3 |
| P05 Hedefe doğru rota | 4 | 5 | 1 | 2 | 1 | 1 | 1 | 5 | 1 |
| P06 Ortak görsel/durum sistemi | 4 | 4 | 5 | 5 | 4 | 3 | 2 | 4 | 2 |
| P07 Seansı koruyarak küçültme | 5 | 5 | 3 | 4 | 4 | 4 | 4 | 5 | 3 |
| P08 Besin tekrar girişini rafine et | 5 | 5 | 4 | 5 | 3 | 3 | 3 | 4 | 3 |
| P09 Birleşik ilerleme girişi | 4 | 4 | 4 | 3 | 4 | 3 | 2 | 4 | 3 |
| P10 Grafik sorusu ve veri kapsamı | 4 | 4 | 4 | 3 | 4 | 3 | 3 | 4 | 3 |
| P11 Hareket ve durum geri bildirimi | 3 | 4 | 4 | 4 | 2 | 2 | 2 | 5 | 1 dar / 4 tam |
| P12 Destekleyici ritim ve tercih | 4 | 4 | 3 | 3 | 4 | 2 | 2 | 3 | 4 |

Bir toplam puanı “doğru sıralama” diye sunmuyoruz. P05 sık değil ama ucuz ve açık rota kusuru; erken giderilir. P07 yüksek değerli ama oturum sahipliği riski nedeniyle ilk dilime alınmaz. P03'ün görsel puanı düşük olması önceliğini düşürmez. Veri güvenliği her puanın üzerinde kabul koşuludur.

## P01 — Yorgunken set kaydı için yeterli hedef

**Gözlem / kanıt:** Tamamla `38×34`, ± `36×30`, set tipi `30×32` (`active_session_widgets.dart:651–656,1186–1192,1234–1240`; U04/Q01). **Sorun:** sık kullanılan küçük hedefler hassas dokunuş ister; gerçek yanlış dokunma oranı ölçülmedi. **Hipotez / çözüm:** özel kontrolleri en az 48×48 mantıksal birim yap; 320 genişlikte iki satırlı yerleşim, kalıcı birincil aksiyon daha sonra. **Yarar:** hedefe erişim ve düzeltme kolaylığı; **ödün:** daha uzun liste. **Uygulanabilirlik:** mevcut seans komutlarını koruyan yerel widget değişikliği; şema yok. **Bağımlılık:** hedef/semantik sözleşmesi. **Risk:** hedefler büyürken alanları sıkıştırmak. **Kabul / doğrulama:** hit test sınırları 48+, klavye açıkken veri ve aksiyon görünür; 320/393, TR/EN, büyük yazı; tek elle ardışık set görevi ve mevcut draft testleri. **Faz:** 1.

## P02 — Önceki değer önerisi okunur ve açık olsun

**Gözlem:** öneri metni %40 opak; token hesabı koyuda 2,134:1, açıkta 1,717:1 (`active_session_widgets.dart:1338`; Q02). **Sorun:** bilgi soluk, öneri ile girilmiş değer ayrımı sadece görünüşe kalabilir. **Hipotez / çözüm:** en az 4,5:1 öneri metni ve görünür “Öneri”/“Önceki” etiketi; salt öneri kayıt sayılmaz, mevcut tamamlama/doldurma sözleşmesi korunur. **Yarar:** değerleri okumak ve neyin kayda gireceğini anlamak. **Ödün:** biraz daha fazla metin. **Uygulanabilirlik:** ortak alan stili; düşük. **Bağımlılık:** Q02 hesabı ve gerçek render renkleri. **Risk:** öneriyi yeni varsayılanmış gibi otomatik yazmak. **Kabul:** normal/odak/hata/öneri renkleri gerçek yüzeyde ölçülür; kullanıcı öneri ile kayıtlı değeri ayırır. **Faz:** 1.

## P03 — Setin adı, birimi ve durumu duyulsun

**Gözlem:** özel onay ve alanlarda yerel semantik ad eksikleri var; cihazda okuyucu arızası henüz gözlenmedi (Q03). **Sorun:** sayı/ikon bağlamdan kopabilir. **Çözüm:** “Bench Press, set 3, ağırlık kilogram, tekrar, tamamla/tamamlandı” sözleşmesi; geri alma erişilebilir; tekrar eden ikon anonsu yok. **Yarar:** VoiceOver/TalkBack ile bağımsız görev. **Ödün:** aşırı uzun anons yorabilir, denge test ister. **Uygulanabilirlik:** ayrı kontrol semantiği; orta. **Bağımlılık:** P01 düzeni. **Risk:** tüm satırı birleştirip ayrı alanları gizlemek. **Kabul:** iki okuyucuyla başlat→değer gir→tamamla→geri al görevinde engel yok; otomatik etiket/hedef testleri destekler. **Faz:** 1.

## P04 — Ana sayfa önce sıradaki anlamlı işi göstersin

**Gözlem:** güncel `393×852` fixture görüntüsünde antrenman ana düğmesi ekran altında; enerji kartı önce (`home_screen.dart:76–87`; U02). **Sorun:** uygulamaya antrenman için gelen kullanıcı ana eylemi arar. **Hipotez:** aktif seans/bugünün planını öne almak karar süresini kısaltır. **Çözüm:** Faz 1'de sıralama ve başlık sadeleştirme; Faz 3'te enerji/protein iki satır, kompakt hafta ve ayrıntı bağlantısı. **Yarar:** günün işine hızlı giriş. **Ödün:** beslenme odaklı kullanıcı enerji özetini daha aşağıda bulur; doğrudan Beslenme sekmesi korunur. **Uygulanabilirlik:** mevcut bağlamsal provider'lar yeniden kullanılır; düşük–orta. **Risk:** tarihte gezinirken bugünün eylemini yanlış güne bağlamak. **Kabul:** aktif seans varsa tek baskın devam; plansız/dinlenme gününde zorla başlatma yok; normal ölçekte 360×800'de ana eylem görünür. En büyük yazıda görünürlük için yazı küçültülmez, açık sıralama ve kaydırma korunur. **Faz:** 1/3.

## P05 — Beslenme “Hedefler” doğru düzenleyiciye gitsin

**Gözlem:** `nutrition_screen.dart:237` Ayarlar'a gider, kcal/protein editörü Profil'de (`profile_screen.dart:220–249`; U03). **Sorun:** bağlantı kullanıcıyı ilgili kontrole götürmez. **Çözüm:** mevcut `AppRoutes.profile` üzerinden hedef bölümüne görünür giriş; yeni ham rota yok. İhtiyaç varsa bölüm odağı parametresi tasarlanır. **Yarar:** hedef değiştirme keşfi. **Ödün:** Profil'de hedefleri ayırt etme ihtiyacı; **uygulanabilirlik:** düşük. **Risk:** geri dönüş tarihi/seçili öğünü kaybetmek. **Kabul:** Beslenme→Hedefler→kcal/protein düzenle→geri dön; doğru veri ve seçili tarih korunur. **Faz:** 1.

## P06 — Aynı üründe aynı bileşen aynı şeyi anlatsın

**Gözlem:** merkezi tema/token mevcut; Beslenme ayrı temalı; özel InkWell'ler tema hedefini atlıyor (05/Q01). **Sorun:** tema tek başına bileşen davranışını garanti etmiyor. **Çözüm:** 07'deki ortak button/input/row/sheet/state sözleşmeleri; rol tabanlı tokenlar ve envanter; toplu yeniden yazım değil ekran ekran geçiş. **Yarar:** tutarlılık ve bakım kolaylığı. **Ödün:** ilk geçişte iki dil beraber bulunabilir. **Bağımlılık:** B yönü ve kontrast kabulü. **Risk:** mevcut sıcak beslenme rafinesini kaybetmek; paleti tek başına değiştirmek yeterli değil. **Kabul:** her bileşenin normal, basılı, odak, pasif, yükleniyor, başarı, hata ve boş durumları; açık/koyu/TR/EN örnekleri; yeni görsel bağımlılık gerekmez. **Faz:** 2.

## P07 — Antrenmanı bırakmadan başka bölüme geç

**Gözlem:** uygulama içi çıkış onayı mevcut taslağı temizler; işletim sistemi kesintisinde draft kurtarma zaten var (`active_session_screen.dart:980–988`; U01/Q06). **Sorun:** kullanıcı beslenmeye bakmak için seansı açık tutup sekme değiştiremez. **Çözüm:** “Küçült” kalıcı devam şeridi; “Bitir ve kaydet”, “Antrenmanı sil” ayrı eylemler. Seans state ve timer sahibi ekran lifecycle'ından ayrılır. **Yarar:** mevcut seansı bozmadan bölüm kullanımı. **Ödün:** sekmelerin üstünde kalıcı alan; **zorluk:** yüksek. **Bağımlılık:** controller sahipliği tasarımı, P01/P03, native eylem kimliği. **Risk:** iki seans, çift timer, eski bildirimden yanlış set, dispose sırasında sayacın durması. **Kabul:** küçült→besin ekle→devam; tek seans kimliği; aynı set/değer/deadline; hesap değişimi ve process kill; yeni seans yarışı; native parity. **Faz:** 3, ayrı onaylı teknik notla.

## P08 — Öğün ekleme, tekrar eden alışkanlığa uyum sağlasın

**Gözlem:** son/sık besin, hızlı ekle, art arda kayıt, öğün kopyalama zaten var (`add_food_sheet.dart`; 02/04). **Sorun hipotezi:** son porsiyonun görünürlüğü ve arama/klavye geçişi hâlâ kritik olabilir; kullanıcı süresi ölçülmedi. **Çözüm:** son kullanılan adı + porsiyon + kcal tek satır; açık “200 g ekle” ve ayrı düzenle; öğün bağlamı korunur; birincil arama alanı ve bağımsız barkod. **Yarar:** tekrarlanan öğünün hızlı ve doğru kaydı. **Ödün:** bir dokunuş yanlış porsiyonu da hızlı kaydedebilir. **Bağımlılık:** porsiyon/birim sözleşmesi, mevcut undo. **Risk:** şablon ile tüketilmiş kaydı karıştırmak; çift dokunmada çift kayıt. **Kabul:** son besini tekrar ekle, farklı porsiyon gir, seri ekle, geri al, geçmiş günü kopyala senaryoları; yanlış porsiyon testi. **Faz:** 3.

## P09 — İlerleme tek bir anlaşılır giriş olsun

**Gözlem:** “İlerleme” dalı BodyMetricsScreen; kuvvet/geçmiş, haftalık değerlendirme ve fotoğraflar farklı girişlerde (U05). **Sorun:** etiket ürünün genel ilerlemesini vaat eder ama kök ölçümlerle sınırlı. **Çözüm:** sekme kökünde “Antrenman / Vücut / Haftalık” soru girişleri; fotoğraf Vücut altında; eski detay rotaları korunur. **Yarar:** ilerlemenin nerede bulunacağı anlaşılır. **Ödün:** sürekli kilo giren için fazladan dokunuş riski; son kullanılan alt görünümü hatırlama test edilir. **Zorluk:** orta, sorgu/rotalar çoğunlukla mevcut. **Risk:** ana sayfadaki tüm kartları burada da çoğaltmak. **Kabul:** “Bench Press gelişimimi/kilo eğilimimi/haftalık düzenimi bul” görevi; az veride açık açıklama. **Faz:** 3.

## P10 — Grafikler belirli soruyu doğru veriyle yanıtlasın

**Gözlem:** ayrık tahmini kcal günleri kavisli çizgi, sıfır/kayıtsız ayrımı motorca kısmen mevcut (`workout_activity_card.dart:54–63,170–198`). **Sorun hipotezi:** kavis sürekli ölçüm izlenimi verir; tahmini harcama ana başarı göstergesi olabilir. **Çözüm:** 12'deki grafik sözleşmesi; günlük seans/süre sütunu, kilo ham+trend ve açık örneklem, kuvvette aynı hareket/aynı koşul. “Eksik kayıt” sıfır tüketim değildir. **Yarar:** güvenilir yorum. **Ödün:** daha sakin grafik daha az gösterişli; açıklama alanı ister. **Bağımlılık:** mevcut hesapların eşiği/kalitesi, haftalık completeness bilgisi. **Risk:** hesap anlamını sessiz değiştirmek; bu durumda ayrıca hesap tasarımı/testi gerekir. **Kabul:** boş/1/2/yeterli veri, uç değer, süre/dönem/birim testi; kullanıcı grafiğin ne söylediğini doğru açıklar. **Faz:** 3.

## P11 — Hareket geri bildirimi hızlandırsın; sistem tercihi izlensin

**Gözlem:** reduced motion bazı yüzeylerde var, skeleton/ortak halka/RPE'de tek sözleşme yok (Q04). **Çözüm:** 07 hareket tablosu; “set kaydedildi” anında, animasyon bekletmez; azaltılmış harekette statik son durum; haptic tercihe bağlı, ses tek başına anlam taşımaz. **Yarar:** yanıt hissi ve tutarlılık. **Ödün:** tüm animasyonları kaldırmak da durum değişimini belirsizleştirebilir. **Zorluk:** yerelde düşük, tüm yüzey taraması orta. **Risk:** live timer üzerinde her saniye okuyucu anonsu. **Kabul:** sistem tercihini çalışma sırasında değiştir; timer yalnız anlamlı eşik/eylemde anons; eski Android hedef cihazda profile ölçümü. **Faz:** 1 kritik alt küme / 4.

## P12 — Geri dönüş nedeni fayda olsun; baskı olmasın

**Gözlem:** haftalık değerlendirme, ilk hafta rehberi ve recall kuralları zaten kodlu; bildirim yoğunluğu sınırları mevcut (workstreams/behavioral.md). **Sorun hipotezi:** bildirim tercihi ve içerik anlaşılmazsa güven azalabilir; tercih oranı bilinmiyor. **Çözüm:** mevcut bildirim amaçlarını anlaşılır ayrı tercihlerde doğrula; dinlenme/eksik veri nötr dil; kilometre taşı yalnız gerçek kıyasla; değerlendirme “ne değişti/neyi bilmiyoruz/sonraki seçenek” şeklinde. **Yarar:** öz yeterlik ve sürdürülebilir kullanım. **Ödün:** daha az bildirim kısa vadeli açılışı düşürebilir; hedef açılış değil yararlı görevin tamamlanması. **Bağımlılık:** docs/49–51 ve hesap bazlı tercihler. **Risk:** yeni bildirim katmanı, “AI öneriyor” ile açıklamasız sağlık çıkarımı. **Kabul:** amacı anlama, kapatma/erteleme kolaylığı, rahatsızlık görüşmesi; katılımcı onayıyla iki haftalık pilot. **Faz:** 4, mevcut yoğunluk artırılmaz.

## Hızlı kazanımlar ve büyük işler

**Hızlı:** P02, P05, P01'in yerel hedefleri, P03 kritik set adları, P04 kart sırası, P11 hareket tercihi. “Ucuz” = hatasız veya testsiz demek değildir; native/şema etkisi olmayan dar kapsam demektir.

**Büyük mimari işler:** P07 seans sahipliği; P09 ilerleme girişinin düzenlenmesi; P06 yaygın bileşen geçişi. P08/P10 hesap veya saklanan verinin anlamını değiştirirse CONVENTIONS §7b gereği ayrıca tasarım notu. Hiçbir fırsat şema, senkron, hesap kapısı veya sağlık rızasını yalnız görsellik için değiştirmez.

## Birleştirme ve görüş ayrılıkları

U04 ve Q01 ile C01 aynı hedefi destekliyor → P01. U02/C02 → P04. Q06 mevcut kurtarmanın korunmasını isterken U01 seans küçültmeyi ister: çelişki değil farklı durumlar, P07 ayrı faza alındı. Görsel B odak görünümü deneyimli kullanıcıda tabloyu gizleyebilirdi → “Tümü” ve serbest satır düzenleme korundu. C günlük dili beslenme için destekleyici, fakat ilerlemeyi üst başlığa gömmek U05'i büyütür → önerilen dört sekme korunur. Rakipte AI/program üretimi bulunması FitPack'e yeni üretken yapay zekâ işi açmak için yeterli kanıt sayılmadı.
