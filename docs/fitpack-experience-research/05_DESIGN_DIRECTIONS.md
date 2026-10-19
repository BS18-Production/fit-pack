# Üç ürün ve görsel tasarım yönü

> **Derin inceleme notu (18 Ekim 2026):** Bu raporun düzeltilen iddiaları için bkz. [review/00_SYNTHESIS.md](review/00_SYNTHESIS.md) "Diğer raporlara düzeltmeler".

## Karar özeti

**Öneri: B — Rafine Performans.** FitPack'in mevcut lime/karbon kimliğini ve dört sekmesini koru; bilgiyi sık kullanılan eylemin arkasında sırala. Aktif seansta güçlü odak, beslenmede kayıt verimliliği, gün sonunda sakin değerlendirme. C'nin destekleyici dilini al; A'nın gereksiz yüzeyleri kaldırma disiplinini uygula. Bu seçim henüz kullanıcı tercihiyle doğrulanmış değildir.

Üretim kodu değişmedi. [Dokuz ekranlı etkileşimli tasarım](visuals/concepts.html) ve [ana sayfa](visuals/concept-home.png), [antrenman](visuals/concept-workout.png), [beslenme](visuals/concept-nutrition.png) karşılaştırmaları üretildi. Bunlar kurgu verili öneridir; çalışan Flutter ekran görüntüsü değildir. Aynı veri ve an karşılaştırılır. Gerçek uygulama görüntüleri ayrı [current](visuals/current/) klasöründedir.

Onay gerektirenler: B yönü, mevcut dört sekmenin korunması, ilk uygulama diliminin 09'daki sınırı. Tüm yönler mevcut kullanıcı kayıtlarını korur; navigasyon veya görsel düzen değişimi tek başına veri göçü gerektirmez.

## Mevcut görsel kimliğin denetimi

| Gözlem | Kanıt | Kullanıcı etkisi / tasarım karşılığı |
|---|---|---|
| Mat karbon, lime ve özgün simgeler tanınabilir bir başlangıç | `app_colors.dart:6–12`, `fitpack_icon.dart`; current/dark-tr-home.png | Kimliği sıfırlamak için yeterli gerekçe yok. Vurgunun sıklığını azaltmak daha anlamlı. |
| Başlık + tarih + haftalık şerit + büyük çift halka, birincil antrenman eyleminden önce geliyor | `home_screen.dart:76–87`, güncel 393×852 görünüm | Eylemi görmek için kaydırma gerekiyor. İlk ekranı bir karar alanı yap. |
| Enerji ve protein iki eşmerkezli halkada; ayrıca üç makro çubuğu var | `nutrition_summary_card.dart:63–78,95+`; current/dark-tr-home.png | Protein için ikinci gösterim, açıklama satırı gerektiriyor. Ana sayfada satır/çubuk, detayda gerekirse tek halka. |
| Beslenme sıcak ayrı tema, ortak gezinme lime/karbon | `nutrition_theme.dart:5–9`; current/dark-tr--nutrition.png | Kendi içinde rafine; sekmeler arasında ürün kişiliği değişiyor. Ortak semantik rollere ve aynı kontrole bağla. Bu bir uzman tutarlılık değerlendirmesi; kullanıcı şikâyeti ölçülmedi. |
| Aynı büyüklükte yuvarlak, çerçeveli kartlar çok farklı önemleri eşitliyor | current/dark-tr-activity.png ve dark-tr-home.png | Kartı seçilebilir veya anlamlı bir gruba ayırıcı olarak kullan; her metin bloğunu kartlaştırma. |
| Tahmini antrenman kalorisi yumuşatılmış çizgiyle gösteriliyor | `workout_activity_card.dart:170–198` | Günlük ayrık kayıtlar sürekli ölçüm gibi algılanabilir. Süre/seans sütunu veya nokta tercih et; nedenini test et. Veri hatası iddiası değil. |
| Plus Jakarta Sans yerel paketli ve Türkçe karakterleri destekleyen mevcut altyapı | `app_theme.dart:10–14,36–108`, assets/fonts/ | Yeni font bağımlılığı yerine boyut/ağırlık hiyerarşisini düzelt. |

Güçlü mevcut parçalar: çevrimdışı yerel font, açık/koyu tema, dört sekmede durum koruma, platforma göre sayfa geçişi, beslenmede sabit ekle/barkod alanı, gerçek veriden türetilen özet. Bunlar yeniden keşfedilecek özellikler değildir.

## A — Rafine Sadelik / Refined Minimalism

| Boyut | Öneri |
|---|---|
| Ürün felsefesi | Bir kişisel kayıt defteri: az karar, görünür veri, gerektiğinde ayrıntı. |
| Hedef deneyim / duygu | Kontrol, hafiflik, dikkat dağıtmayan doğruluk. Yeni kullanıcı ve karmaşıklıktan kaçınan kişi. |
| Bilgi mimarisi | Bugün → Kayıtlar (Antrenman/Beslenme alt ayrımı) → İlerleme. Profil başlıkta. |
| Navigasyon | Üç sekme; seans küçültülürse devam şeridi. Günlük kayıt türü son seçimi hatırlar. |
| Ana sayfa | Tek plan eylemi, satır tabanlı enerji/protein, haftalık seans sayısı. Takvim ayrıntıda. |
| Antrenman | Tüm hareketler listede, set tablosu ve altta mevcut seti tamamlama. Sıra dışı set girişi doğrudan satırda kalır. |
| Beslenme | Enerji toplamı + üç etiketli ince çubuk; öğün listesi. Halka yok. Son kullanılan porsiyon açık etiketli. |
| İlerleme | Soruya göre sade grafik: “Ağırlığım hangi yönde?”, “Bu hafta kaç seans?”. Her grafikte dönem/birim/veri sayısı. |
| Görsel dil | Açık mineral yüzey, mürekkep metin, koyu orman eylemi. Koyu eşdeğeri ayrıca token olarak tasarlanır. |
| Renkler (öneri) | bg `#FAFBF8`; text `#222820`; secondary `#62685C`; action `#355443`; line `#DFE3D7`. Bunlar otomatik kontrast onayı değildir. |
| Tipografi | Mevcut Jakarta. Başlık 28–32, alt başlık 19, gövde 14–16, yardımcı 12–13; sayılarda tabular rakam. Büyük metinde tek sütun. |
| Izgara / boşluk | 20 yatay; 4/8/12/16/24/32 ölçeği; satırlar 56+, birincil eylem 54–56. |
| Bileşen / köşe / derinlik | Ayırıcı satırlar, 12 kontrol / 16 anlamlı grup. Gölge yalnız örtüşen panelde. |
| Simgeler / grafik | Mevcut FitPack simgeleri + Rounded işlev simgeleri. Grafikler doğrudan etiketli, çoğunlukla tek seri. |
| Hareket | 120–160 ms durum geçişi; tablo satırı konumu sıçramaz. Azaltılmış harekette anında durum değişimi. |
| Kişiselleştirme | Kullanıcının son kayıt türü ve planı; anlaşılır kurallar. Yeni veri modeli/üretken yapay zekâ gerekmez. |
| Güçlü taraf | En düşük görsel gürültü; yoğun kayıtta verimlilik. |
| Zayıflık / risk | Birleştirilen Kayıtlar sekmesi beslenmeye fazladan seçim ekleyebilir; markayı fazla nötrleştirebilir. |
| Teknik etki | Yeni rota gruplama ve eski bağlantıları koruma gerekir; veri şeması gerekmez. Maliyet orta. |

## B — Rafine Performans / Premium Performance

| Boyut | Öneri |
|---|---|
| Ürün felsefesi | O anki işi hızlı yap; ayrıntıya ihtiyacın olduğunda ulaş. |
| Hedef deneyim / duygu | Hazır, kesin, yetkin; bağırmayan spor kimliği. |
| Bilgi mimarisi | Bugün / Antrenman / Beslenme / İlerleme. Sonuncu ölçüm, kuvvet, haftalık değerlendirme ve fotoğrafa açık giriş verir. |
| Navigasyon | Mevcut dört dal korunur; aktif seans ayrı odak ekranı. Küçültme sonraki aşamada kalıcı devam şeridiyle. |
| Ana sayfa | Başlık kısalır; aktif seans varsa önce devam, yoksa plan/sonraki rutin. Beslenme iki satır ve çubuk; haftalık ritim üçüncü. |
| Antrenman | Mevcut set için büyük kg/tekrar kontrolü + önceki seans + sabit “Seti tamamla”. “Tümü” ile tablo/listeden doğrudan düzenleme; zorunlu sihirbaz yok. |
| Beslenme | Sayısal kalan enerji, üç etiketli makro, öğün günlüğü ve ayrı ekle/barkod hedefleri. Önizlemede tek şeritteki barkod etiketi görsel yer tutucudur; üretimde bağımsız 48 hedef olacaktır. |
| İlerleme | Önce anlamlı sonuç cümlesi + veri kapsamı, sonra kanıt grafiği. Tahmini enerji “ilerleme” puanı yapılmaz. |
| Görsel dil | Mat karbon, ölçülü lime; aktif eylem güçlü, tarih/özet sakin. Kahverengi ayrı ürün hissi ortak temaya yaklaşır. |
| Renkler (öneri) | bg `#151713`; text `#F3F5ED`; secondary `#B2B8A7`; action `#D0F34A`; onAction `#20270A`; surface `#23271E`. Mevcut tokenlara yakın. |
| Tipografi | Jakarta korunur. Başlık 28–32, aktif sayı 36–44, gövde 14–16; tek ekranda en fazla iki güçlü yazı ağırlığı. Form etiketi kalıcı, öneri ile girilmiş değer açıkça ayrılır. |
| Izgara / boşluk | 20 yatay; 24 bölüm arası; 12–16 grup içi. 48 minimum özel kontrol; birincil buton 56. |
| Bileşen / köşe / derinlik | 12 kontrol, 16 grup, 24 panel. Yalnız ana bağlam için tonlu yüzey; geri kalan içerik çoğunlukla doğrudan zemin üstünde. |
| Simgeler / grafik | Özgün mevcut ikon dili korunur; ikon + metin, renk tek anlam taşımaz. Ayrık günler sütun/nokta; trend kilo uygun çizgi. |
| Hareket | Set onayı 120–160 ms; sayı değişimi 160–200; panel 200–250. Tamamlamayı bekleten kutlama yok. |
| Kişiselleştirme | Aktif seans > planlı rutin > dinlenme > döngüde sıradaki > kurulum; mevcut kural rafine edilir. Saat tek başına eylem dayatmaz. |
| Güçlü taraf | En sık salon etkileşimine yatırım; mevcut kimlik ve mimariyle uyum. |
| Zayıflık / risk | Odak görünümü setler arası serbestliği gizleyebilir; sabit alt kontroller klavyeyle yarışabilir. Tablo erişimi ve klavye düzeni zorunlu. |
| Teknik etki | İlk hiyerarşi/erişim dilimi düşük; seans küçültme ve ortak canlı durum orta–yüksek. Native bildirim köprüleri yeniden yazılmaz. |

## C — Sakin Yol Arkadaşı / Warm Personal Companion

| Boyut | Öneri |
|---|---|
| Ürün felsefesi | Kayıt alışkanlığını günlük hayatın içine yerleştir; yargılamadan destekle. |
| Hedef deneyim / duygu | Güven, sakin süreklilik, kişisel eşlik. Beslenme kaydında düzen arayan kullanıcı. |
| Bilgi mimarisi | Günüm / Hareket / Günlük. İlerleme, Günüm'den haftalık değerlendirmeye bağlanır. |
| Navigasyon | Üç gündelik etiket; alışkanlık zaman çizgisi. İlerleme için ek yol, keşfedilebilirlik riski. |
| Ana sayfa | Plan eylemi ve günün olayları; kalori ana başlık değildir. Eksik kayıt için sakin davet. |
| Antrenman | Hareket/set kontrol listesi; önceki seans bağlamı. Serbest tablo görünümü alternatif olarak korunur. |
| Beslenme | Önce öğünler, sonra enerji + küçük tek halka, kalıcı makro değerleri. “Henüz kayıt yok” tüketilmedi demek değildir. |
| İlerleme | Haftalık kendi geçmişine göre değerlendirme; sürdürülebilirlik. “Kaçırdın” veya kırılan seri tehdidi yok. |
| Görsel dil | Krem/kâğıt, yumuşak zeytin, sıcak koyu metin. Büyük yuvarlak vurgu yalnız günlük bağlamında. |
| Renkler (öneri) | bg `#FBF6EE`; text `#382D25`; secondary `#79675B`; action `#52694B`; surface `#EEE6D9`; line `#E0D4C5`. |
| Tipografi | Jakarta korunur; başlık 28–32, gövde 16; sayılar bilgi için, tüm ekranın kişiliği için değil. |
| Izgara / boşluk | 20 yatay; zaman çizgisi 16 iç girinti; 24 bölüm arası; eylemler en az 48. |
| Bileşen / köşe / derinlik | Günlük bölümler doğrudan yüzeyde; plan 24, kontrol 12. Sıcaklık gölge/blur ile değil ton ve dille. |
| Simgeler / grafik | Takvim, yapıldı ve sıradaki işaretleri etiketli; halka dekor değil toplam/hedef ilişkisi için. |
| Hareket | 160–220 ms hafif genişleme; zaman çizgisi kalıcı alan tutar. Azaltılmış harekette doğrudan durum. |
| Kişiselleştirme | Günün kayıtları ve kullanıcının seçtiği hatırlatma zamanı; sağlık tavsiyesi üretme yok. |
| Güçlü taraf | Destekleyici dil, günlük beslenmede düşük baskı. |
| Zayıflık / risk | Deneyimli salon kullanıcısı için anlatım ve kontrol listesi ek kaydırma; enerji/makrolar aşağıda kalabilir. |
| Teknik etki | Yeni günlük bileştirme ve ilerleme erişimi; orta maliyet. İlk öneride kapsamlı olay veritabanı gerektirmez, mevcut sorgularla okunur. |

## Üç yönün karşılaştırması

Uzman tahmini; kullanıcı araştırması puanı değildir. 1 düşük, 5 yüksek. Karmaşıklıkta yüksek sayı daha fazla iş demektir.

| Ölçüt | A | B | C |
|---|---:|---:|---:|
| Deneyimli kullanıcıda kayıt verimi | 5 | 5 | 3 |
| Beslenmeye doğrudan ulaşma | 3 | 5 | 4 |
| İlk kullanımda sade anlaşılma | 4 | 4 | 5 |
| Mevcut kimliğe uyum | 3 | 5 | 2 |
| Ayırt edici spor kimliği | 3 | 5 | 3 |
| Gündelik destekleyici his | 4 | 4 | 5 |
| Tam geçiş karmaşıklığı | 4 | 3 | 4 |

B seçimi matematiksel ispat değildir: mevcut dört sekmeye dokunmadan sık etkileşimleri iyileştirme olanağı ve kaynakla doğrulanmış öncelik problemleri en güçlü dayanak. A/C tercihleri karşılaştırmalı görev testinde üstün gelirse karar yeniden açılır.

## Referans koleksiyonu ve özgünlük

Birincil ürün kaynakları ve değerlendirme [03](03_COMPETITIVE_RESEARCH.md)'te. Fotoğraf/screenshot kopyalanarak FitPack tasarımı üretilmedi; karşılaştırma tasarımları bu çalışma için özgün kodla çizildi.

| Yön | Referansın öğrenilecek ilkesi | Alınmayacak parça |
|---|---|---|
| A | Strong: hızlı kayıt; MacroFactor: sayının anlamını açıklama; Todoist: bağlamsal ekleme | Rakibin ekranının birebir kompozisyonu veya ikonları |
| B | Hevy: set/önceki seans odağı; Strava: etkinlik sonucu ve bağlamı | Sosyal akışı zorunlu ana sayfa veya rekabet puanı yapma |
| C | Gentler Streak: dinlenmeyi tanıma; Nike Training Club: yönlendirme ve açıklık | Sağlık yeterliliği çıkarımı, her güne hedef baskısı |

## Kritik tasarım incelemesi sonrası revizyonlar

İlk odak modeli bütün setleri gizleme riski taşıyordu: B'ye “Tümü” eklendi. Sade ana sayfa haftalık geçmişi kaybettirme riski taşıyordu: kompakt şerit ve değerlendirme bağlantısı korundu. Tek büyük besin ekle alanı barkodun keşfini azaltıyordu: üretim şartnamesinde bağımsız barkod hedefi zorunlu. Renk kimliği tüm anlamı taşıyordu: setlerde etiket/işaret ve ekran okuyucu durumu zorunlu kılındı.

Önizlemede gerçek seans motoru, veri tabanı, arka plan sayacı, gerçek rota ve sistem bildirimi yoktur. 07/09/10 bu davranışları ayrıca şartnameye bağlar; HTML'deki basit buton davranışı üretime hazır mimari sayılmaz.
