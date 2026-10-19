# 07 — Tasarım sistemi önerisi

## Karar özeti

FitPack'in kömür/lime kimliğini koruyup **eylem, veri ve durum dilini** güçlendirmek öneriliyor. Mevcut tokenlar, yerel fontlar ve açık/koyu temalar iyi bir başlangıç. En yüksek değer yeni bir renk paletinden önce aktif seansın dokunma hedefleri, öneri okunurluğu, anlamlı erişilebilir adlar ve kesinti sonrası güven hissinde. Beslenmenin sıcak yüzeyleri ürün içinde bilinçli bir alt ton olarak kalabilir; aynı eylem farklı özelliklerde farklı anlam taşımamalı.

Önerilen seçenek, mevcut Material 3 + Riverpod üstüne aşamalı bileşen sözleşmesi. Baştan tema değiştirme ve tüm ekranları aynı anda yeniden yazma, doğrulanmış kullanıcı yararı olmadan maliyetli. İlk dilim mevcut kayıtlara ve şema v17'ye dokunmaz; görsel geri dönüş mümkündür. Ortak durum verisinin taşınması, taslak kapsamının genişletilmesi veya yeni kalıcı tercihler ayrıca tasarlanır.

**Onay gerektiren tasarım kararları:** aktif set için sabit etiketli eylemin kapsamı; beslenmede sıcak tonların korunması; büyük yazıda etiketli gezinmenin daha fazla yer kaplaması. Bu belge uygulama onayı değildir. Doğrulama; mevcut referans görüntüler, 48×48 hedef ölçümü, kontrast hesabı, Türkçe/İngilizce ve açık/koyu render, kesinti ve ekran okuyucu görevleriyle yapılır.

## 1. Mevcut temelin değerlendirmesi

`lib/core/theme/app_colors.dart` Material renk rolleri ve `AppSemanticColors`; `app_dimens.dart` 4–32 boşluk ölçeği, 12 kontrol köşesi, 150/160/250/400 ms süreler ve 48 hedef; `app_theme.dart` yerel Plus Jakarta Sans ve Material düğme/giriş stilleri içeriyor. `GlassCard` canlı blur'u varsayılan kapalı tutuyor (`lib/shared/widgets/glass.dart:59`); bu yaklaşım korunmalı. Liste kartlarına yaygın blur eklemek kalite hedefi değildir.

`NutritionTheme` yerel bir alt tema (`lib/core/theme/nutrition_theme.dart:22`). Bunu silmek yerine aynı etkileşim sözleşmesi altında tutmak düşük riskli. `VelocityNavigation` seçili durum, semantik ad ve azaltılmış hareket desteği içeriyor (`lib/shared/widgets/velocity_navigation.dart:29`). Eksiklerinin yanında mevcut kazanımlar korunmalı.

Kaynakla doğrulanan açıklar Q01–Q08 [teknik çalışma akışında](workstreams/technical-accessibility.md) puanlı ve izlenebilir biçimde kayıtlı. Örnek: tamamla hedefi 38×34; öneri metni modellenen dolguda 2,134:1 koyu / 1,717:1 açık. Bu belge yeni kullanıcı araştırması sonucu sunmaz; uygulanacak sistem uzman tasarım hipotezidir.

## 2. Görsel ilkeler

1. **Bir bağlam, baskın bir eylem:** antrenmanda set, beslenmede kayıt, ana sayfada sıradaki karar. Bütün kartları lime yapmak yerine vurgu eyleme tahsis edilir.
2. **Kayıt ile öneri görünür ayrılır:** “önceki”, “öneri” ve “bu set” etiketleri; okunurluk düşürerek ayrım yapılmaz.
3. **Sıcaklık içerikte, tutarlılık kontrolde:** beslenmenin sıcak yüzeyi kalabilir; kaydet, iptal, geri al, hata ve seçili durum ürün genelinde aynı davranır.
4. **Ölçüye hizmet eden grafik:** her grafik soru, birim, dönem ve veri yeterliliği taşır; süs grafiği yok.
5. **İlerleme destekleyici:** hedef üstü/altı durumu otomatik başarısızlık veya ahlaki değerlendirme olmaz. Rekor ve tamamlama isteğe bağlı, kısa geri bildirimdir.

## 3. Token sözleşmesi

Aşağıdaki adlar öneridir; üretim dosyaları bu görevde değişmedi. Var olan API (Application Programming Interface; uygulama programlama arayüzü) korunarak rol bazlı adlandırma eklenebilir.

| Grup | Önerilen sözleşme | Mevcut karşılık / gerekçe |
|---|---|---|
| Zemin | canvas / surface / elevated / overlay | `surfaceContainerLowest`, `surface`, container rolleri; 4 seviye yeterli |
| Metin | primary / secondary / supportive / onAccent | `onSurface`, `onSurfaceVariant`, `onPrimary`; destek bilgisi de normal boyutta ≥4,5:1 |
| Eylem | primary / quiet / destructive / focus | Lime birincil; dolgusuz ikincil; hata rengi yalnız yıkıcı/gerçek hata |
| Veri | energy / protein / carbohydrate / fat / strength / weight | Mevcut makro renkleri; çizgide doğrudan etiket+farklı desen gerektiğinde eşlik eder |
| Durum | success / warning / error / info / pending | Mevcut semantik uzantı; success ile primary aynı renk olsa bile ikon ve metin durumu açıklar |
| Boşluk | 4, 8, 12, 16, 20, 24, 32; gerektiğinde 48 bölüm arası | `AppSpacing`; özel 26 gibi değerler kullanım envanteriyle sadeleştirilir |
| Köşe | control 12; card 20/24; sheet 24; pill yalnız kısa filtre/rozet | Mevcut `AppRadius`; amaç bazlı kullanım, her kutuya farklı köşe yok |
| Kontrol | en az 48×48; birincil yükseklik en az 54; yoğun olmayan satır 56+ | Mevcut `AppA11y` ve `AppNavigation`; yükseklik metinle büyür |
| Kenar | dekoratif 1; focus 2; focus ofseti 2 | Focus yüzey sınırını görünür yapar; yalnız gölgeye güvenilmez |
| Yükselti | düz içerik 0; dokunulan kart hafif; yüzen bar; modal | Mevcut gölge ayarı temel; çoklu yoğun gölgeler hiyerarşiyi azaltır |
| Hareket | immediate 0; feedback 120–160; expand 180–250; progress ≤360 | Mevcut süreler yeniden kullanılır; reduced motion statik alternatif |

Renk örnekleri **mevcut üretim değerleridir**: koyu canvas `#121212`, onSurface `#F5F5F1`, lime `#CCFF00`, koyu onPrimary `#171C03`; açık primary `#526900`, yüzey `#FFFFFF`. Koyu birincil çift 14,845:1 ve açık birincil çift 6,214:1 hesaplandı; bütün disabled/pressed/focus kombinasyonları bununla otomatik geçmez. Hata, odak ve grafik kenarlarında komşu renge karşı ayrıca kontrol gerekir. Kontrast eşikleri [W3C 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) ve [1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html) ile çapraz kontrol edilir.

## 4. Tipografi ve veri biçimi

Plus Jakarta Sans dosyaları korunur; font değiştirmek kullanıcı deneyimi kazanımı sayılmaz. Önerilen roller: sayfa başlığı 22–26/700, bölüm 16–19/700, ana gövde 16/400, ikincil gövde 14/400, kısa metadata 12,5/500, ana ölçüm 32–40/700. Bunlar başlangıç boyutlarıdır; sistem yazı ölçeklemesi uygulanır. `labelSmall` 11,5 yalnız yardımcı veri içindir; ağırlık veya tekrar gibi antrenman kararını taşıyan bilgi bu role sıkıştırılmaz.

Sayılar tabular figures (eş genişlikli rakamlar) kullanır; sayaç her saniye yatay zıplamaz. Birim sayıdan ayrılmaz: “80 kg”, “8 tekrar”, “01:15 dinlenme”. “Kalan” ve “hedef üstü” sözcükleri korunur; tek işaret/renk anlamı taşımaz. Ondalık virgül/nokta ve tarih kullanıcı dilinden gelir. Veri kaynağı ve tahmin bilgisi gerektiğinde küçük ama erişilebilir metinle gösterilir. RPE ilk açıklamada “Algılanan zorluk”; TDEE (Total Daily Energy Expenditure; toplam günlük enerji harcaması) gerekli yerde açık anlamıyla sunulur.

## 5. Bileşen mimarisi ve uygulama eşlemesi

| Önerilen bileşen | Kullanıcı sözleşmesi | Mevcut koddan uygulanacak yer | Bağımlılık / maliyet |
|---|---|---|---|
| `PrimaryAction` | Etiket, anlamlı yüklenme adı, tek işlem kilidi, büyüyen hedef | Material FilledButton teması + `workout_ui.dart` veya ortak widget | Şemasız / düşük |
| `StatusSurface` | Yerel kayıt, sunucuya gönderim, hata ve yeniden denemeyi ayırır | `app_state_views.dart`, `sync_status_tile.dart` | Servis sonucu türü gerekiyorsa orta |
| `MetricSummary` | Değer + birim + dönem + veri yeterliliği | `progress_indicators.dart`, `warm_nutrition_summary.dart` | Aynı hesap motorunu yeniden kullanır / orta |
| `ActiveSetCard` | Önceki/öneri/girilen alanlar + tamamla + geri al | `active_session_widgets.dart` içindeki `_SetRow`, `_NumCell`, `_RpeCell` | Yoğun tabloyu dar ekran için yeniden düzenler / orta |
| `SessionActionBar` | Hangi hareket/seti değiştirdiğini gösteren sabit eylem | `active_session_screen.dart` seans sahibinin callback'leri | Şemasız; yeni ikinci state yok / orta |
| `RestControl` | Dinlenme kalan, +15 sn, atla; hata/izin açıklaması gerektiğinde | `RestBanner`, `session_rest_sound.dart`, yerel bridge | Native parite ayrı iş / orta |
| `FoodLogRow` | Ad, miktar/birim, kalori; ayrıntı isteğe bağlı | `nutrition_screen.dart`, `add_food_sheet.dart` | Mevcut kalıcı modeller / orta |
| `AppSheet` | Başlık, kapat, ilk focus, klavye güvenli alanı, kaydırma | `SheetHeader`, `sheetBottomInset` | Ortak bileşen üzerinden küçük adım / düşük |
| `InsightCard` | Soruya cevap + dönem + kayıt sayısı + dayanak | `features/insights/`, `features/assistant/` | Hesapları UI'da tekrar yazmaz / orta |
| `AccessibleChart` | Görsel grafik + kısa açıklama + veri listesi | Mevcut fl_chart 0.70.2 kullanan ekranlar | Yeni grafik motoru yok / orta |
| `AppNavigation` | Dört sekme, seçili ad, tekrar dokunma davranışı; etiketli büyük yazı | `VelocityNavigation`, `AppShell`, GoRouter shell | Rotaları değiştirmeden önce varyant deneyimi / orta |

Yeni ortak bileşen `lib/shared/widgets/`, tema tokenı `lib/core/theme/`, saf hesap feature içindeki mantık dosyasına gider. Veri erişimi DAO (Data Access Object; veri erişim nesnesi) üzerinden; provider okuma/yazma sözleşmesi korunur. Ürün çapında ikinci state çözümü veya yeni tasarım kütüphanesi önerilmiyor.

## 6. Zorunlu durum matrisi

Her bileşen için tüm sütunlar envanterde doldurulur; uygulanmayan durum gerekçeli `uygulanmaz` olabilir. “Success/empty button” uydurmak yerine işlem/alan/kart düzeyindeki durum doğru yerde tutulur.

| Durum | Düğme / set eylemi | Alan / seçim | Kart / grafik / liste |
|---|---|---|---|
| Varsayılan | Açık eylem adı, ≥48 hedef | Kalıcı etiket + birim; öneri gerçek girişten ayrı | Başlık + dönem + eylem; renk tek başına anlam taşımaz |
| Basılı | Kısa yüzey tepkisi; layout kaymaz | Dokunma geri bildirimi; giriş değeri değişmeden önce görsel tepki | Yalnız dokunulabilir kart tepki verir |
| Odaklı | Görünür çevre çizgisi; etiket okunur | 2 genişlikte focus; hata mesajı silinmez | Klavyeyle hedefe gidilir, ekrana kaydırılır |
| Devre dışı | Eylem yok; gerekiyorsa nedeni yanında | Salt okunur ile devre dışı ayrı adlandırılır | İzin yok kartı sıfır veri göstermez |
| Yükleniyor | Etiket alanı yerinde kalır; tekrar dokunma engellenir; “Kaydediliyor” | Yazılan metin korunur; alanlar gerekmedikçe kilitlenmez | İlk yüklemede iskelet; yenilemede son doğru veri ve küçük durum |
| Başarılı | Yalnız veritabanı onayından sonra; tamamlandı / geri al | Kayıt sonucu görünür, gereksiz alan temizlenmez | Zaman ve kapsam belirtilir; bulut bekliyorsa ayrı |
| Hata | Yeniden dene; işlem kilidi açılır | Alan altında düzeltme önerisi; yalnız kırmızı çerçeve yok | Tam hata ile kısmi hata ayrılır; son doğru veri etiketlenir |
| Boş | İşlem için veri yoksa anlamlı başlangıç eylemi | Öneri yoksa boş alan; uydurma sıfır değer yok | İlk kayıt / filtre sonucu yok / eksik veri / çevrimdışı ayrı |

Ek durumlar: seçili; tamamlanmış; geri alınmış; bekleyen bulut; veri az; izne ihtiyaç; desteklenmeyen platform; kesintiden devam. “0 kayıt” ile “0 kalori”, “0 adım” ile “sağlık verisi okunamadı”, “tamamlanmamış gün” ile “0 tüketim” aynı değildir. Mevcut sağlık platformunun gizlilik sınırlamaları korunur.

## 7. Aktif set için somut düzen sözleşmesi

**Normal genişlik:** hareket adı ve “set 2/3”; altında önceki 77,5 kg × 8; yan yana etiketli ağırlık ve tekrar, isteğe bağlı RPE. Alt satırda “Öneri 80 kg × 8” ve etiketli “Seti tamamla”. Tamamlama sonrası “80 kg × 8 kaydedildi” + “Geri al”. Öneri boş alanı dolduracaksa eylemden önce değer açık gösterilir. Mevcut `fillMissing` ve `_shownValues` hesapları korunur (`active_session_screen.dart:247`).

**320 genişlik veya büyük yazı:** geçmiş bilgi ayrı satıra; ağırlık ve tekrar alanları iki sütun kalabiliyorsa kalır, sığmıyorsa dikey; RPE ikincil etiketli eylem; tamamla tam genişlik. Tüm satırları aynı anda büyütmek yerine geçmiş/tamamlanmış satırlar kompakt özet olabilir. Bağlamsal sabit bar aktif setin adını gösterir; farklı hareket seçilince hedef görünür güncellenir. Kaydırma ve screen reader focus'u kendiliğinden başka sete zorla atlamaz.

**Tek gerçek durum:** sabit bar, satır ve kilit kartı aynı komut yolunu çağırır. Aynı aksiyon hem satırda hem barda olduğunda erişilebilir ad hedefi açıklar; yanlış sete yazmaya karşı mevcut setKey koruması yerel yüzeyde tutulur. Kayıt/öneri davranışını sessiz değiştirmek bu görsel kapsamın dışındadır.

## 8. Hareket ve dokunsal geri bildirim

Süreler ölçülmüş kullanıcı tercihleri değil başlangıç önerileridir. Eylem işlenmesi hiçbir animasyonun bitmesini beklemez. [Flutter disableAnimationsOf](https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html) sistem tercihini okumak için mevcut uygulama kalıbına uygundur.

| Tetik | Amaç / önerilen süre ve eğri | Performans / azaltılmış hareket |
|---|---|---|
| Set tamamla | Durum onayı; 120–160 ms easeOut, renk/ikon | Layout değiştirmeden tek satır; statik “Tamamlandı” + isteğe bağlı dokunsal tepki |
| Dinlenme başlat | Setten molaya geçiş; ≤160 ms kısa geçiş | Sayaç deadline'dan okunur, animasyon saati zaman kaynağı olmaz; statik görünüm |
| +15 saniye / Atla | Hemen sayı + kısa vurgulama | Ses/haptic varsayımları yok; statik güncel değer |
| Enerji/makro güncelle | Eski ve yeni değeri ilişkilendir; 250–360 ms easeOutCubic | Painter sınırında; hareket kapalıysa anında sonuç; değer her zaman son doğru sayı |
| Öğün/hareket aç | İçerik ilişkisi; 180–220 ms easeOut | Büyük uzun listede tüm sayfa yeniden animasyonlanmaz; statik aç/kapa |
| Yüklenme | Yer tutucunun geçici olduğunu anlat | Shimmer yerine azaltılmış harekette sabit blok + “Yükleniyor” semantiği |
| Antrenman bitir | İşlem sonucuna geçiş; ≤250 ms | Uzun konfeti/atlanamayan başarı animasyonu yok; doğrudan özet |

Her saniye sayacı tüm ekranı yeniden kuruyorsa daha ağır görsel sistem eklemeden önce profil alınır. Mevcut `_ticker` seansın `setState`'ini her saniye çağırıyor (`active_session_screen.dart:127`); bu tek başına performans hatası kanıtı değil, ölçüm noktasıdır.

## 9. Erişilebilirlik ve uyarlanabilirlik

**Dokunma:** ürün genelinde 48×48 mantıksal piksel hedef. Görsel ikon 18/24 olabilir; hit alanı büyük kalır, komşu alanlarla çakışmaz. Web WCAG 2.2 AA temel 24 CSS piksel eşiği ile Android 48 dp önerisi farklıdır. [Android rehberi](https://developer.android.com/guide/topics/ui/accessibility/views/apps-views), [W3C 2.5.8](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html).

**Ekran okuyucu:** işlem adı+nesne+durum; alan adı+birim; başlık sırası; modal açılınca ilk anlamlı odağa geçiş, kapanınca tetikleyiciye dönüş; dakika/saniye anlaşılır okunur. Sayaç her saniye canlı anons edilmez; kullanıcı sorgulayabilir ve bitişte tek anlamlı uyarı alır. Her ikon için ayrıca etiket eklemek yerine dekorasyon hariç bırakılır; ikon düğmesinin anlamı kontrol düzeyinde verilir. [Flutter erişilebilirlik testleri](https://docs.flutter.dev/ui/accessibility/accessibility-testing) otomatik etiket ve hedef kontrollerini destekler; gerçek TalkBack/VoiceOver ayrıca gerekir.

**Büyük yazı:** 320/360/393/430 mantıksal genişlik; %100, %130, %160, %200 ve işletim sisteminin en büyük erişilebilir yazı ayarı. Yalnız `TextScaler.linear` testi platformun doğrusal olmayan ölçeklemesi yerine geçmez. Küçük başlıkları ellipsis ile kesmek, temel eylemi saklamak veya yazıyı kullanıcı tercihinin altına küçültmek varsayılan çözüm olmaz. Etiketli gezinme varyantı prototipte sınanır.

**Grafik:** doğrudan seri adı, birim, dönem, hedef çizgisi açıklaması; renk görme farklılıklarında desen/işaret; veri listesi alternatifi; 0–1 noktada eğri/trend vaadi yok. Kilo hedef yönü “azalması her zaman iyi” diye varsayılmaz. Çizginin ekseni kırpılıyorsa açıkça işaretlenir.

**Dil ve platform:** Türkçe uzun adlar, İngilizce; kg/lb dönüşümü etiket ve erişilebilir adda birlikte; 12/24 saat; klavye açık modal; Android geri hareketi; iOS geri kaydırma; ses/sessiz mod; yüksek kontrast ve kalın metin. Yeni tablet/masaüstü tasarımı ilk kilometre taşına eklenmez; geniş ekranda içerik maksimum genişlik ile okunur kalır.

## 10. Native yüzeyler ve kapsam sınırı

Canlı Etkinlik SwiftUI ve Android bildirim/servis katmanında ayrı çiziliyor. Flutter bileşenini değiştirmek bunları yenilemez. Ortak sözlük: hareket, set kimliği, gösterilen değer, tamamlayabilme, dinlenme başlangıç/bitiş anı, yerelleştirilmiş etiketler. Apple'da kompakt/minimal/genişletilmiş/kilit görünümleri ve kullanıcı tarafından kapatma hâli hesaba katılır. [Apple Live Activities rehberi](https://developer.apple.com/design/human-interface-guidelines/live-activities) bu yüzeylerin kısa, durum odaklı işlevini destekler.

Yeni kilit ekranı düzeni için SwiftUI kodunun yanında hedefli VoiceOver/büyük yazı testi gerekir. Android servis, pil ve bildirim izinleri ayrıca kontrol edilir. Ses veya Canlı Etkinlik izni verilmediyse seans kontrolü uygulama içinde çalışmayı sürdürür; izin vermeyi zorlayan kapanmaz uyarı yok.

## 11. Devreye alma ve kabul

İlk ortaklaştırma sırası: alan/eylem semantiği → hedef/öneri okunurluğu → motion policy → AppSheet → veri özeti/çizelge → görsel rol sadeleştirme. Bir seferde tüm görünümü değiştirmek yerine seans ve bir beslenme akışı üzerinden sözleşme doğrulanır, sonra genişletilir.

Kabul: mevcut kayıt davranışı korunur; bütün yüksek sıklıklı eylemler ≥48×48; gerekli metin normal boyutta ≥4,5:1; metin ve durum ekran okuyucuda anlamlı; büyük yazıda kayıpsız görev; azaltılmış harekette dekoratif sürekli hareket yok; işlem hatasında içerik ve yeniden deneme yolu korunur; mevcut testler + hedefli testler + cihaz görsel kontrolü tamamlanır. Ayrıntılı deney protokolü [10_VALIDATION_STRATEGY.md](10_VALIDATION_STRATEGY.md).
