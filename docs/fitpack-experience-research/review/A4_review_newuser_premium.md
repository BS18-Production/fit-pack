# A4 — Yeni kullanıcı · sadelik arayan · premium deneme müşterisi incelemesi

18 Ekim 2026 · kaynak `07104d1` · üretim kodu değişmedi · yazar: bağımsız
inceleyici (Claude). Üç bakış açısı: (1) uygulamayı yeni kuran kişi, (2)
karmaşık uygulamadan hoşlanmayan kişi, (3) ~7 günlük deneme süresinde ödeyip
ödemeyeceğine karar veren premium müşteri (konumlandırma: reklamsız, deneme
dışında ücretsiz kullanım yok; ödeme altyapısı henüz yok).

## Karar özeti

1. **Deneme haftasında ürünün asıl değeri geç görünüyor.** İlerleme önerisi
   ("bu sefer X kg dene") ve set önerisi aynı hareketin bir önceki seansını
   ister. Onboarding'in önerdiği programlar A/B dönüşümlü olduğu için ilk öneri
   **en erken 3. antrenmanda** çıkar; haftada 2–3 gün antrenman yapan biri için
   bu, 7 günlük denemenin 5.–6. günü. İlk iki antrenman tamamen elle yazılıyor.
   Paket (01–12) bu zamanlama sorununu hiç ele almıyor.
2. **Kurulum kullanıcıya soru soruyor ama cevabı unutuyor.** "Haftada kaç gün?"
   cevabı kaydedilmiyor. Ritim kartı haftalık hedefi 1 kabul ediyor. 4 gün
   diyen kişi tek antrenmandan sonra "hedef tamam (1/1)" görüyor; render'larda
   "4/1" yazıyor. Premium müşteri için bu bir güven kırılması. Bu doğrudan bir
   kusur ve ucuz düzeltilir.
3. **İlk dilim (12'deki "Temel etkileşim güveni") doğru işler içeriyor ama
   deneme müşterisi için en önemli işler o listede değil.** 48×48 dokunma
   hedefi, kontrast ve ekran okuyucu her kullanıcının işine yarar. Dönüşümü
   (deneyenin ödemeye geçmesini) ise şunlar belirliyor: ilk antrenmanı
   başarıyla bitirmek, söylenen hedefe sadık kalmak, ilk hafta "aha" anı ve
   görünür kalite. Bu yüzden ilk dilime 3–4 küçük madde eklemeyi öneriyorum.
4. **B yönü bu kişiler için kabul edilebilir, ama "B mi?" sorusu ikincil.**
   Üç kavram da dolu bir günü (1.620/2.400 kcal, "Son seans: Perşembe")
   gösteriyor. Hiçbirinde 1. gün boş durumu, deneme süresi ya da ödeme ekranı
   yok. Yeni kullanıcı için kavram seçiminden önce "1. gün ana sayfası"
   tasarlanmalı.
5. **Render'larda görünür cila sorunları var ve pakette yoklar.** Aynı sayı iki
   ekranda farklı biçimde ("2270" / "2.270"), Türkçe büyük harf hatası
   ("KIMLIK & ENERJI"), 320 px'te kesilen değerler ("2,7… kg", "Üst Vü…"),
   kelime ortasından bölünen "Karbonhi/drat", sıfıra inip çıkan yanıltıcı
   aktivite eğrisi. Premium algısını bunlar düşürür ve çoğu birkaç satırlık iş.
6. Sadelik arayan kişi için ana sayfa 1. gün en kalabalık hâlinde: boş enerji
   halkası, "0 antrenman · 0 kg · 0 kcal", boş aktivite grafiği, verisi olmayan
   "Verime sor". 12 §3.4'teki "kart kaldırmak bilgi kaybıdır" itirazı veri
   olmayan kartlar için geçerli değil. Bu kartları ilk haftada gizlemek bilgi
   kaybı sayılmaz.

## Yöntem ve sınırlar

- **Yaptığım:** BRIEF'i okudum. İlk açılış yolunun kodunu satır satır okudum:
  `welcome_screen.dart`, `auth_screen.dart`, `onboarding_screen.dart`,
  `home_screen.dart`, `first_week.dart`, `today_lines.dart`,
  `recall_offer.dart`, `recall_first_week.dart`, `explore/*`,
  `program_recommendation.dart`, `home_providers.dart`, `set_prefill.dart`,
  `progression.dart` ve `active_session_widgets.dart`'tan ilgili kısımlar.
  `visuals/current/` altında 30'a yakın render inceledim (dört varyantın ana
  sayfa, antrenman, beslenme, öğün, yemek paneli, ilerleme, profil, haftalık
  değerlendirme, özet ve önizleme ekranları), ayrıca `runtime-installed-app.png`,
  üç `concept-*.png` ve `concepts.html`'i (metin taraması). Ardından 01–12'yi
  okudum (03 ile 06/07/10'u ilgili bölümleriyle).
- **Yapmadığım:** Uygulamayı çalıştırmadım, cihaza dokunmadım, hesap açmadım.
  Dokunma sayıları **koddan türetildi** (sayım kuralı 04'teki ile aynı:
  kaydırma, klavye vuruşu ve sistem penceresi dahil değil, ayrıca belirtildi).
  E-posta doğrulama süresi, gelen kutusu/spam davranışı ve gerçek deneme terk
  oranı **bilinmiyor**.
- **Render sınırı:** `visuals/current` bellek içi örnek verilerle üretildi.
  Kurulum, karşılama, giriş ve **boş (1. gün) ana sayfa** için render yok.
  Boş duruma en yakın kanıt `runtime-installed-app.png` (0 / 3.100 kcal).
- Kanıt sınıfları BRIEF'teki gibi: **K** kod, **G** görsel/render gözlemi,
  **S** standart, **H** hipotez. "Proje notu" = MEMORY / PROJECT_STATE'teki
  daha önce gözlenmiş olay.

## 1. İlk 7 gün — somut ekranlarla yürüyüş

### Gün 1 · kurulum → ana sayfa

| Adım | Ekran / davranış | Seçim sayısı (koddan) | Risk | Kanıt |
|---|---|---|---|---|
| Karşılama | Logo, "Fit Pack'e hoş geldin", üç genel değer maddesi, "Hesap oluştur" | 1 | Değer maddeleri her takip uygulamasında olan şeyler ("rutin kur", "kalori takip et", "grafikte gör"). İlerleme önerisi, haftalık değerlendirme, reklamsızlık, gizlilik gibi farklar anlatılmıyor. Deneme süresi ya da ücret hiç anılmıyor. | K `app_tr.arb:716–721`, `welcome_screen.dart:62–83` |
| Giriş — Google | "Google ile devam et" + sistem hesap seçici | 1 (+ sistem penceresi) | En kısa yol. İzin ekranında ham `supabase.co` adı görünüyor; premium algısına zarar. | K `auth_screen.dart:145`; proje notu (Google Cloud Branding açık iş) |
| Giriş — e-posta | E-posta + şifre yaz → "Kayıt ol" → aynı ekranda küçük bir bilgi satırı ("E-postanı doğrula") → **uygulamadan çık**, posta kutusu, bağlantı → geri dön | 2 + uygulama değişimi + 2 alan yazımı | Bilgi satırı `bodySmall` boyutunda ve şifre alanının altında, gözden kaçması kolay. Ekran sessizce "Giriş" sekmesine geçiyor. Bağlantı başka cihazda açılırsa oturum telefona gelmiyor. Dahili SMTP kotası nedeniyle aynı saatte birkaç kayıt `429` alabiliyor. **En büyük terk noktası adayı.** | K `auth_screen.dart:69–77`, `:202–216`; proje notu (canlıda 429 gözlendi); terk oranı H |
| Hata metni | Supabase'in İngilizce `e.message` metni ya da `Bağlanılamadı: <istisna metni>` | — | Teknik olmayan kullanıcıya ham istisna gösteriliyor. Samet'in "gerçek istisnayı göster" kuralı teşhis için doğru; çözüm, dostça bir cümle + açılır "ayrıntı" satırı. | K `auth_screen.dart:81`, `:84`, `:105` |
| Kurulum 1/4 | Deneyim (3 seçenek) + gün sayısı (3 seçenek) | 3 | İyi ve kısa. | K `onboarding_screen.dart:304–370` |
| Kurulum 2/4 | Önerilen program (varsayılan seçili) / "Kendim kuracağım" | 1 | Kartta neden önerildiği, seans süresi ve hangi ekipmanın gerektiği yok (03 C12 ile aynı görüş). | K `:375–427` |
| Kurulum 3/4 | Kilo (zorunlu yazım), hedef kilo (isteğe bağlı), hedef (varsayılan **Kilo Ver**) | 1 + yazım | Varsayılanın "Kilo Ver" olması kas yapmak isteyen birinin fark etmeden kesinti kalorisiyle başlamasına yol açabilir. | K `:69` |
| Kurulum 4/4 | Kcal/protein (düzenlenebilir), tahmini süre, "Hatırlatayım mı?" + sistem izni, "Başlayalım" | 2–3 | Ham kcal/protein alanları sadelik arayan kişiyi ürkütebilir; yine de önceden dolu geliyor. | K `:642–765`, `recall_offer.dart` |
| **Toplam** | Google: ~10–11 seçim + 1 yazım · e-posta: ~11–12 seçim + 3 yazım + uygulama değişimi | | Kurulum yalın. Asıl risk giriş adımında. | K |

**Gün sayısı cevabı kayboluyor.** `_days` yalnız program seçmek için tutuluyor
("Kalıcı değil", `onboarding_screen.dart:60–64`). Program kurulumu rutinlere
hafta günü atamıyor (`program_install.dart`). Ritim hedefi
`scheduledDays == 0 ? 1 : scheduledDays` (`home_providers.dart:95`) olduğu için
hedef 1'de kalıyor. **K.** Sonuç `dark-tr-meal.png`'de "Bu haftanın hedefi
tamam (4/1)", `dark-tr--insights-week.png`'de "4 / 1". **G.**

**İlk ana sayfa görünümü** (`runtime-installed-app.png`, G): logo + "Bugün, bir
adım ileri." + hafta şeridi + **boş** enerji halkası (0 / 3.100) ilk ekranın
tamamını kaplıyor. Antrenman kartı alt menünün altında kalıyor. İlk hafta kartı
(`_FirstWeekCard`) eylem kartından da sonra geliyor (`home_screen.dart:76–102`,
K). Bu ekranda dikkat çeken tek şey dolması gereken boş bir halka.
**12 §3.1'deki "yeni kullanıcıda 130 / 2400" ifadesi düzeltilmeli: yeni
kullanıcı 0 görür.**

### Gün 1 · ilk antrenman

- Ana sayfa → "SIRADAKİ ANTRENMAN" kartı → önizleme → "Antrenmana Başla" = 2
  seçim (K `home_screen.dart:349–373`).
- Başlangıç programı (ör. `fullbody_beginner`, Full Body A): **6 hareket, 15
  set** (K `program_catalog.dart:92–99`).
- İlk seansta öneri yok. Kilo alanında `0` ipucu duruyor (`hint ?? '0'`), tekrar
  ipucu yalnız önceki seanstan geliyor (K `active_session_widgets.dart:1039`,
  `:1140`, `:1288`). Her set için kg + tekrar yazımı + ✓ gerekiyor: 15 sette en
  az ~45 etkileşim ve klavye.
- "Yeni başlıyorum" diyen kişi "Chest Press Machine" için **kaç kilo** gireceğini
  bilmiyor. Başlangıç kilosu rehberi yok; hareket adları ve kas etiketleri
  İngilizce ("Chest · Barbell", K `workout_ui.dart:62–66`, G
  `dark-tr--workout-routine-1-preview.png`). Türkçe talimat kararı ertelendi
  (MEMORY). **Yeni başlayan için 1. günün en zor anı burası (H).**
- Özet ekranı (G `dark-tr--workout-summary-1.png`): onay işareti, süre/hacim/set,
  hareket listesi, "Bitti". Sonraki antrenmanın ne zaman olduğu ya da gelecek
  sefer neyin değişeceği söylenmiyor. İlk antrenmandan sonra hatırlatma teklifi
  burada çıkıyor (K `recall_offer.dart:13–14`), ama kurulumda zaten sorulduysa
  çıkmıyor.

### Gün 1 · ilk öğün

Beslenme → "Yemek Ekle" → arama → besin → porsiyon → Ekle = 3–4 seçim (04 ile
aynı). Yeni kullanıcıda "Son eklediklerin" boş olduğu için aramaya mecbur.
Barkod ve "Hızlı kalori" görünür (G `dark-tr-food-sheet.png`). **Bu akış iyi.**
İlk hafta kartı 2/3'e çıkıyor. Kilo adımı kurulumda yazıldığı için baştan
"1/3 tamam" görünüyor; bu iyi bir başlangıç ilerlemesi (K
`onboarding_screen.dart:184`, `first_week.dart:57`).

### Gün 2–7

| Gün | Ne oluyor | Değer anı mı? | Kanıt |
|---|---|---|---|
| 2 | Antrenman yoksa saat 19:00'da **tek** ilk hafta hatırlatması | Hatırlatma, değer değil | K `recall_first_week.dart:13–18` |
| 2–3 | 2. antrenman = **Full Body B**: yine farklı 6 hareket, yine öneri yok, yine elle yazım | Hayır | K `program_catalog.dart:100–107`, `progression.dart:125–130` |
| 3–6 | Ana sayfada "Bugün X g protein, Y kcal kaldı" satırı | Küçük ama gerçek | K `today_lines.dart:117–128` |
| ~5 (haftada 3 gün) | 3. antrenman = A tekrar: ilk kez soluk öneri, ✓ tek dokunuş, "bu sefer X kg dene" satırı | **Evet, asıl "aha" anı** | K `today_lines.dart:51–96`, `set_prefill.dart` |
| Haftanın son günü 20:00 | "Haftan hazır" kartı. Kurulum günü haftanın neresine denk geldiyse o kadar günlük veriyle | Değişken. Pazartesi kuran tam haftayı görür, Cumartesi kuran 1–2 günü | K `week_ready.dart:15`, `:24`. Etkisi H |
| 7 | Deneme biter. Ödeme ekranı ya da deneme durumu yok | — | K: `lib/`'de satın alma/abonelik kodu yok |

**Değerin ortaya çıktığı yer:** beslenme kaydı 1. günden yararlı. Antrenmandaki
ayırt edici değer (öneri, ilerleme, rekor, haftalık odak) **5.–7. güne**
yığılıyor. **Kullanıcının bırakabileceği yerler:** (a) e-posta doğrulaması, (b)
ilk antrenmanda kilo bilmeme ve elle yazım, (c) 2. antrenmanın 1.'si kadar zor
geçmesi, (d) ana sayfanın boş ve kalabalık görünmesi (sadelik arayan kişi).

## 2. Render'larda görünür kalite sorunları

| # | Sorun | Dosya | Neden (K) | Persona etkisi |
|---|---|---|---|---|
| R1 | Halkada "2270", hemen yanında "2.400"; Beslenme'de aynı değer "2.270". Aynı sayı iki biçimde | `dark-tr-home.png`, `light-en-home.png` ("2270" / "2,400"), `dark-tr--nutrition.png` | `progress_indicators.dart:88` `'$remaining'` biçimsiz; `:282` `'${current.round()} / $goal'` de biçimsiz | Premium: özensizlik izlenimi |
| R2 | "KIMLIK & ENERJI": Türkçe büyük İ yerine I | `dark-tr--profile.png` | `setting_tiles.dart:119` `title.toUpperCase()`. Doğru araç `context.upper()` (`formatting.dart:31`) zaten var | Türk kullanıcı hemen fark eder |
| R3 | "2,7… kg" toplam hacim kesik; "Üst Vü…" rutin adı kesik | `large-en--workout.png` | Büyük yazıda sayı kesilmesi = veri kaybı | Büyük yazı kullanan, sadelik arayan |
| R4 | "Karbonhi / drat" kelime ortasından bölünüyor; "Günlük / hedef" iki satır | `narrow-tr-home.png` | Üç makro sütunu 320 px'e sığmıyor | Dar ekran |
| R5 | Aktivite eğrisi kayıt olmayan günlerde sıfıra inip tepe yapıyor (sinüs gibi) | `dark-tr-meal.png`, `large-en-meal.png` (sağda "Sun" kırpık) | 05/P10'da da var; katılıyorum | Güven: "bu grafik ne diyor?" |
| R6 | Haftalık değerlendirme Türkçe'de "82.2 kg", "−0.4 kg", "Hedef 2400"; Profil "2400 kcal" | `dark-tr--insights-week.png`, `dark-tr--profile.png` | Ondalık ve binlik ayırıcı yerelleştirilmemiş (R1 ile aynı aile) | Tutarsızlık |
| R7 | "+ Ölçüm Ekle" düğmesi ölçüm değerlerinin ve "Kilo Trendi" başlığının üstüne biniyor; trend etiketi "nokta: günlü…" kesik | `dark-tr--progress.png`, `narrow-tr--progress.png` | Alt boşluk FAB'ı hesaba katmıyor | Dar ekranda veri okunmuyor |
| R8 | Son Ölçümler'de "Kilo" sütunu ortalı ve üç satır, "Bel/Kol" başka taban çizgisinde | `dark-tr--progress.png` | Hizasız ızgara | Cila |
| R9 | Seçili çip (Keşfet "Başlangıç") Antrenman sekmesinde kahverengi/turuncu | `dark-tr--workout.png` | Sıcak ikincil renk beslenme dışına taşıyor | 12 K3'ten bağımsız bir tutarlılık hatası |
| R10 | Büyük yazıda hafta şeridinin "<" düğmesi başlığa biniyor. "<" dolgulu, ">" dolgusuz | `large-en-home.png`, tüm home render'ları | Asimetrik kontrol | Cila |
| R11 | Dar ekranda alt menü etiketleri kayboluyor, yalnız ikon kalıyor | `narrow-tr-*.png`, `large-en-*.png` | Etiketsiz ikon, yeni kullanıcı için anlam kaybı | Yeni kullanıcı |
| R12 | Öğün satırında "200 g · P8 K10 Y6" sabit "Yemek Ekle" düğmesinin altında kalıyor; "130 / kcal" iki satıra bölünüyor | `dark-tr--nutrition.png` | Alt boşluk | Cila |
| R13 | Türkçe arayüzde İngilizce kas/ekipman ("Chest", "Barbell") | `dark-tr--workout.png`, `dark-tr--insights-week.png` | `workout_ui.dart:62` bilinçli tercih. Oysa Türkçe kas etiketleri `enum_labels.dart:45`'te var | Yeni başlayan Türk kullanıcı |
| R14 | "1TM +8 kg" kısaltması açıklanmıyor | `dark-tr--insights-week.png` | — | Yeni kullanıcı |

## 3. Kavramlar (A/B/C) ve son öneri — persona değerlendirmesi

- **B bu kişiler için doğru mu?** Kısmen. B'nin ana sayfası (tek güçlü eylem +
  iki satır beslenme) sadelik arayan ve yeni kullanıcıya bugünkü sayfadan
  açıkça daha iyi (G `concept-home.png`). B'nin aktif antrenman ekranı ("Önceki:
  60 kg × 10 · Uygulanmış öneri") yeni kullanıcının ilk iki seansında **boş
  kalır**. Kavram geçmiş verisi olan kullanıcıya göre çizilmiş. **C**'nin dili
  ("Hazır olduğunda başlayabilirsin", "Akşam için yer var") deneme haftasındaki
  yeni kullanıcıya daha uygun. 05'in önerdiği "B + C'nin destekleyici dili"
  birleşimine katılıyorum, ancak ilk hafta için C'nin tonu belirleyici olmalı.
- **Eksik olan:** üç kavramda da (a) 1. gün boş durumu, (b) ilk seansta öneri
  olmadığında ne gösterileceği, (c) deneme durumu ("Denemenin 3. günü"), (d)
  ödeme ekranının yeri ve tonu, (e) kurulum/karşılama ekranı yok
  (`concepts.html`'de "boş", "deneme" ya da "trial" geçmiyor; tek eşleşme
  "PREMIUM" başlığı. G). 05'te "İlk kullanımda sade anlaşılma" puanı B=4 ve
  C=5. Bu puanların dayanağı olacak bir boş durum çizimi yok.
- **İlk dilim dönüşümü en çok iyileştiren iş mi?** Hayır, tam olarak değil.
  12'deki 6 maddeden **#4 (eylem önce)** ve **#5 (Hedefler bağlantısı)** deneme
  kullanıcısına doğrudan yarar. #1–#3 (48×48, kontrast, ekran okuyucu)
  doğru ama asıl olarak deneyimli/düzenli kullanıcının set hızına yönelik.
  Deneme müşterisinin kararını etkileyen kusurlar (haftalık hedef, boş ilk
  ekran, ilk seansta kilo rehberi, sayı biçimleri) listede yok.
- **Ödeme ekranının yeri (H, para kazanma kararı ertelendiği için yalnız
  tasarım ilkesi):** Set kaydı ve yemek kaydı sırasında ödeme ekranı
  gösterilmemeli (03 C11 ile aynı görüş). En uygun an, değerin görüldüğü an:
  3. antrenmandaki ilk ilerleme önerisinden sonra ya da haftalık değerlendirme
  açıldığında. Deneme durumu Profil'de sakin bir satır olarak durmalı. Bugünkü
  zamanlamayla bu anlar 7. güne çok yakın. Ya deneme süresi "ilk 3 antrenman ya
  da 7 gün, hangisi sonra gelirse" gibi değere bağlanmalı, ya da değer öne
  çekilmeli (madde 10.3). **Samet kararı.**

## 4. Raporlarla uyuşma / ayrılık

| Rapor / iddia | Görüşüm | Kanıt |
|---|---|---|
| 01 "Eksik özellik sorunu yok" | Mevcut kullanıcı için **katılıyorum**. Premium deneme açısından **katılmıyorum**: deneme/ödeme altyapısı hiç yok, kurulum cevabı kalıcı değil, ilk seans için kilo rehberi yok | K `lib/` taraması, `onboarding_screen.dart:60`, `active_session_widgets.dart:1288` |
| 01/12 bulgu 2: ana sayfada eylem ilk görünümde değil | **Katılıyorum**, yeni kullanıcıda daha da ağır: halka tamamen boş | G `runtime-installed-app.png` |
| 12 §3.1 "yeni kullanıcıda 130 / 2400" | **Yanlış örnek.** Yeni kullanıcı 0 / hedef görür; 130 örnek veriden | G `runtime-installed-app.png` |
| 12 §3.4 "kart kaldırmak bilgi kaybıdır; veri olmadan yapılmamalı" | **Katılmıyorum** (ilk hafta için). Sıfır değerli Ritim istatistikleri, boş aktivite grafiği ve verisi olmayan asistan bilgi taşımıyor. Veri yokken gizlemek kayıp değil, sadelik | K `home_screen.dart:871–1009`, `assistant_screen.dart:25` (koşulsuz) |
| 12 §3.5 deneme haftası görevleri (ilk antrenman, ilk öğün, ilk haftalık değerlendirme) | **Katılıyorum, eksik buluyorum.** "İlk haftalık değerlendirmeyi görme" kurulum gününe bağlı. "İlk ilerleme önerisini görme" (3. antrenman) eklenmeli; asıl değer anı bu | K `week_ready.dart:24`, `progression.dart:130` |
| 12 §4 Faz 1 çıkış kapısı: "Samet'in 2 haftalık kullanımı" | **Persona uyuşmazlığı.** Samet yeni kullanıcı değil. Faz 1'in yeni kullanıcı tarafı için kapı Berna'nın sıfır hesapla ilk haftası olmalı (12 §6'da adı geçiyor) | — |
| 12 K3 sıcak beslenme teması | Kararı Samet'e bırakmaya katılıyorum. Ancak sıcak renk Antrenman sekmesine sızıyor (R9); bu karardan bağımsız bir hata | G `dark-tr--workout.png` |
| 05 B seçimi | Katılıyorum (kimlik + dört sekme). C tonu ilk hafta için daha uygun; ilk hafta metinleri C dilinde yazılmalı | G `concept-home.png` |
| 05/08 P10 aktivite eğrisi | **Katılıyorum**; render sorunu açıkça gösteriyor | G `dark-tr-meal.png` |
| 02 U11 / 06 "tek birincil eylem + en çok iki satır" | **Katılıyorum.** Faz 3'e bırakılması deneme müşterisi için geç; ilk hafta için daraltılmış hâli Faz 1'e alınmalı | K `home_screen.dart:76–102` |
| 03 C11/C12 (premium etiketi, program önerisinin nedeni) | **Katılıyorum.** C12 (önerinin nedeni + süre + ekipman) ucuz ve kurulumun 2. sayfasını güçlendirir | K `onboarding_screen.dart:405–417` |
| 02 satır 30: özet ekranı "S0, kullanışlı başarı anı" | **Kısmen katılmıyorum.** İlk seansta bütün değerler doğal olarak "rekor"; özet sonraki adımı göstermiyor ("Sıradaki: Full Body B"). Deneme müşterisi için kaçırılmış bir an | G `dark-tr--workout-summary-1.png` |
| 09 maliyet tahminleri "iş günü" | 12 §3.6'ya katılıyorum: kod hızlı, darboğaz cihaz denemesi | — |
| 10 ölçüm sözlüğü | Güçlü. Eksik: "denemeyi başlatan → 3. antrenmana ulaşan" oranı ve "e-posta doğrulamasında kaybolan" oranı (Supabase'de `email_confirmed_at` boş hesaplar sayılabilir, H) | — |

## 5. Persona özetleri

- **Yeni kullanıcı:** Kurulum hızlı ve iyi. Takıldığı yerler e-posta
  doğrulaması, ilk antrenmanda kilo bilmemek ve İngilizce hareket adları.
  "Haftada 4 gün" dediği hâlde uygulamanın "1/1" demesi kafa karıştırır.
- **Sadelik arayan:** 1. gün ana sayfası boş ama kalabalık (15 bölüm, çoğu
  sıfır). Dar ekranda etiketsiz alt menü. Kurulumdaki kcal/protein alanları
  gereğinden teknik.
- **Premium deneme müşterisi:** Görsel kimlik gerçekten ayırt edici (koyu
  karbon + lime, özgün ikonlar). Buna karşın sayı biçimi tutarsızlıkları,
  Türkçe büyük harf hatası ve kesik değerler "özenli ürün" algısını zedeliyor.
  Antrenman tarafındaki ayırt edici değer denemenin son günlerine kalıyor.
  "Neden para vereyim?" sorusunun cevabı ne karşılamada ne ilk haftada
  söyleniyor.

## 6. Bu personalar için ilk 10 değişiklik (sıralı)

Etki: deneme kullanıcısının ilk haftayı tamamlama ve ödeme kararına beklenen
katkı (**H**, ölçülmedi). Maliyet: kod (yapay zekâ ile) + cihaz denemesi.
Hiçbiri şema değişikliği gerektirmiyor, yalnız 1. madde için not var.

| # | Değişiklik | Neden | Beklenen etki | Maliyet |
|---|---|---|---|---|
| 1 | **Kurulumdaki gün sayısını hedefe bağla.** Haftalık hedef = kurulum cevabı (2–3 → 3, 4 → 4, 5–6 → 5) ya da kurulan programın `daysPerWeek` değeri; ritim/değerlendirme bunu kullanır | Söylenen hedefin unutulması; "4/1" | Yüksek (güven). Ritim ve haftalık odak ilk haftadan doğru | Düşük. Değer kalıcı bir yerde saklanmalı (yerel tercih ya da profil). Profil kolonu gerekiyorsa şema + migration (CONVENTIONS §3); önce `daysPerWeek`'ten türetmek şemasız |
| 2 | **1. gün ana sayfası:** veri yokken enerji halkası yerine tek satırlık "Bugün 0 / 3.100 kcal · İlk öğününü ekle". Eylem kartı ve ilk hafta kartı en üstte. Ritim istatistikleri, aktivite grafiği ve asistan ilk antrenman/öğüne kadar gizli | Boş + kalabalık ilk izlenim | Yüksek (yeni + sadelik) | Düşük–orta. Koşullu gösterim, mevcut provider'lar yeterli |
| 3 | **İlk seans kilo rehberi:** öneri yokken kilo alanında "Hafif başla: 10 tekrarı rahat yapacağın kilo" ipucu, `0` yerine boş + "ilk sefer" etiketi. 2. sette 1. setin değerini öner (aynı seans içi) | Yeni başlayanın en zor anı; ilk seansta ~45 elle etkileşim | Yüksek (yeni başlayan) | Düşük–orta. Seans içi set kopyalama mantığı kısmen var; "veri doğruluğu kuralı" (otomatik doldurma yok, ✓ = onay) korunur |
| 4 | **Sayı ve büyük harf yerelleştirmesi:** `CalorieRing` ve makro metinleri `numFmt`; ondalık ayırıcı; `setting_tiles.dart:119` → `context.upper()`; tüm `toUpperCase()` çağrılarının taranması | R1, R2, R6 | Orta–yüksek (premium algısı), Türk kullanıcı hemen görür | Çok düşük |
| 5 | **Değer anını öne çek:** program kurulumunda A ve B'nin ortak ana hareketleri için "ilk seansın sonucu → sonraki seansta öneri" metni; özet ekranına "Sıradaki: Full Body B · Perşembe · şu hareketlerde öneri gelecek" | Asıl değer 5.–7. güne kalıyor | Yüksek (deneme dönüşümü), H | Düşük (özet metni); orta (öneriyi hareketler arası genelleştirmek; yapılmamalı, yalnız metinle beklenti kur) |
| 6 | **E-posta doğrulama ekranı:** kayıttan sonra küçük satır yerine tam bir "Postanı kontrol et" durumu (adres, "yeniden gönder", "Google ile devam et", spam uyarısı, "başka cihazda açtıysan buraya dönüp giriş yap"). Gerçek kullanıcı öncesi özel SMTP | En büyük terk adayı; 429 riski | Yüksek (kayıt tamamlama) | Düşük (arayüz) + Samet'in manuel SMTP işi (MEMORY'deki bekleyen iş #2) |
| 7 | **320 px / büyük yazı kırpmaları:** hacim değeri kesilmesin (birim alt satıra), rutin adı iki satır, makro etiketleri kısaltma ya da dikey yerleşim, FAB için alt boşluk, hafta şeridi oku | R3, R4, R7, R8, R10, R12 | Orta (sadelik + premium) | Düşük–orta. Mevcut `neon_design_test` dar ekran senaryosu kabul testine dönüşür |
| 8 | **Karşılamada farkı söyle + deneme şeffaflığı:** üç genel madde yerine "Her antrenmanda sana bir sonraki kiloyu söyler", "Haftada bir kısa değerlendirme", "Reklam yok, verin sende". Para kazanma kararı verilince "7 gün ücretsiz, sonra ..." satırı | Premium hikâyesi anlatılmıyor | Orta (beklenti + güven) | Çok düşük (metin). Fiyat satırı karara bağlı |
| 9 | **Aktivite grafiğini ayrık yap** (sütun ya da nokta, kayıt yok ≠ 0) ve haftalık değerlendirmede "1TM"yi aç | R5, R14 | Orta (güven) | Düşük (08 P10'un dar alt kümesi) |
| 10 | **Kurulum küçükleri:** program kartına "neden bu, ~kaç dk, salon ekipmanı"; hedef varsayılanı seçilmemiş olarak gelsin (ya da deneyim cevabına göre); Antrenman sekmesinde sıcak çip rengi lime'a dönsün; dar ekranda alt menü etiketi korunsun ya da seçili sekmenin etiketi görünsün | C12, R9, R11, `:69` | Orta (yeni + sadelik) | Düşük |

**12'nin ilk dilimiyle ilişkisi:** 12'deki #4 ve #5 bu listedeki 2. maddenin
içinde ya da yanında kalmalı. #1–#3 (48×48, kontrast, ekran okuyucu) kalabilir
ama deneme kullanıcısı için 1, 2, 3, 4 ve 6 numaralı maddeler daha öncelikli.
Önerilen birleşik ilk dilim: **12#4 + 12#5 + bu listeden 1, 2, 4, 6(arayüz) ve
7**. 12#1–#3 ikinci dilime alınabilir. Hepsi şemasız (1. madde türetilerek
yapılırsa).

## Pakete etkisi

- **Güçlenen:** 01/12 bulgu 2 (ana sayfada eylem önce): yeni kullanıcıda boş
  halka nedeniyle daha da önemli. 05/08 P10 (grafik): render'da açıkça görülüyor.
  03 C11/C12. 12 §3.5'teki "deneme haftası incelenmemiş" öz eleştirisi doğru;
  bu rapor o boşluğu dolduruyor.
- **Zayıflayan:** 12 §3.4 ("kart kaldırmak bilgi kaybı"): veri yokken geçersiz.
  05 karşılaştırma tablosundaki "İlk kullanımda sade anlaşılma" puanları: boş
  durum çizilmeden verilmiş. 02 satır 30'daki özet ekranının "S0" sayılması:
  deneme müşterisi için kaçırılmış bir an.
- **Yanlış:** 12 §3.1'deki "yeni kullanıcıda 130 / 2400" örneği; doğrusu 0 /
  hedef.
- **Eksik (pakete eklenmeli):** (a) Kurulum cevabının kaybolması ve
  `weeklyGoal = 1` kusuru (`onboarding_screen.dart:60–64`,
  `home_providers.dart:95`). (b) İlerleme önerisinin 3. antrenmana kadar
  görünmemesi ve bunun 7 günlük denemeyle ilişkisi. (c) Render cila listesi
  R1–R14, özellikle R1/R2/R3. (d) E-posta doğrulama akışı ve SMTP kotası
  (02'de "S2, bilinmiyor" denip bırakılmış). (e) Kavramlara 1. gün boş durumu
  ve ilk seans (öneri yok) ekranı eklenmeli. (f) 10'a "3. antrenmana ulaşma"
  ve "doğrulanmamış e-posta" ölçümleri.
- **Önerilen düzeltme:** 12'nin "Faz 1" tanımı ikiye bölünsün: **1a — Deneme
  haftası güveni** (bu raporun 1, 2, 4, 6, 7 numaralı maddeleri + 12#4, #5;
  çıkış kapısı Berna'nın sıfır hesapla 7 günü) ve **1b — Set etkileşim güveni**
  (12#1–#3, #6; çıkış kapısı Samet'in 2 haftası).
