# A5 — Salon kullanıcısı ve günlük beslenme kaydı gözüyle bağımsız inceleme

18 Ekim 2026 · kaynak `main` = `07104d1` · üretim kodu değişmedi · yazar: A5 (Claude)

## Karar özeti

1. **Set kaydı bugün zaten hızlı.** Önerildiği gibi set = **1 dokunuş** (✓). Kilo +2,5 = **2**. Farklı tekrar = **2 dokunuş + 1 tuş**. Bu sayılar Hevy'nin belgelediği akışla aynı. Sorun dokunuş sayısında değil; **hedef boyu, yerleşim kayması ve klavye** tarafında.
2. **Yeni ve ölçülmüş bulgu (G):** Mola başlayınca üstte açılan mola şeridi listeyi **68 pt aşağı itiyor**. Bir sonraki ✓ tam parmağın gittiği anda yer değiştiriyor. Raporlarda bu yok. Kalıcı ve sabit yükseklikli bir alt mola çubuğu ilk dilime girmeli.
3. **Klavye (K + G):** ✓'e basmak klavyeyi tutarlı biçimde kapatmıyor. Öneriyle dolan bir alan varsa kapanıyor (alanın anahtarı değişiyor). Kullanıcı iki alanı da elle yazdıysa açık kalıyor. Listede "kaydırınca kapat" yok. Flutter mobilde dışarı dokunmayla odağı kaldırmıyor. iOS ondalık klavyesinde "Bitti" tuşu da yok. Samet'in ana cihazı iPhone. Klavye çubuğu (Sonraki / Bitti) ya da uygulamaya özel sayı paneli gerekli.
4. **12'deki K4 sorusu yanlış kurulmuş.** ± düğmeleri bugün satırda değil. Yalnız **sıradaki setin altındaki ayrı yardım satırında** duruyor, yani "iki satır" zaten var. "Sayıya dokununca açılan adım paneli" bu persona için **daha yavaş**: +2,5 için 2→3, −2 tekrar için 2+tuş→4 dokunuş.
5. **Odak görünümü (B konsepti) ayrı bir mod olarak gereksiz.** Doğrusu **"etkin set kartı"**. Tablo kalır. Yalnız sıradaki set büyür: 48'lik kg ve tekrar ±, 56'lık tam genişlik "Seti tamamla". Biten ve gelecek setler kompakt satır olur. "Tümü" modu ve ek dokunuşu gerekmez.
6. **Beslenmedeki en büyük boşluk raporlarda yok:** girilmiş kayıt **düzenlenemiyor** (K). Porsiyonu düzeltmek için sil + yeniden ekle gerekiyor, bu 4–5 dokunuş. Her gün kayıt tutan kişi için bu, hedef bağlantısından (U03) daha sık yaşanan bir sürtünme.
7. **Dünkü kahvaltıyı yeniden girmek 5 dokunuş** (⋯ → kopyala → Dün → Ekle). "Her zamanki öğün" kartı bu işi **1 dokunuşa** indiriyor, ama yalnız saat dilimine uyan öğünde ve aynı içerik 14 günde en az 2 kez girildiyse görünüyor. Öğün başlığına "Dünkü gibi" kısayolu ucuz ve etkili olur.
8. **Kalan protein anında görünmüyor.** Enerji kartı proteini "8 / 160 g" (alınan/hedef) diye gösteriyor. "Kalan" cümlesi ana sayfada ilk ekranın altında kalıyor (G, `dark-tr-home.png`). Protein hücresine "kalan" eklemek tek satırlık iş.

## Yöntem ve sınırlar

- **Kod (K):** aktif seans, widget'lar, RPE (Rating of Perceived Exertion, algılanan zorluk) paneli, rutin önizleme, antrenman listesi, özet, canlı etkinlik, beslenme ekranı, ekleme paneli, kopyalama paneli, barkod akışı, ana sayfa öğün ve "kalan" satırları satır satır okundu. Flutter SDK 3.41.1'de `editable_text.dart:6746–6760` (dışarı dokunma davranışı) kontrol edildi.
- **Çalışan uygulama gözlemi (G):** Ayrı bir `git worktree` (07104d1, commit'siz, iş bitince kaldırıldı) içinde, mevcut `active_session_draft_test.dart` düzeneğiyle bir **ölçüm sondası** çalıştırıldı.
  - Senaryo: gerçek `AppTheme.dark`, Plus Jakarta Sans, TR. 393×852 ve 320×852 @1,3 yazı ölçeği. İki hareketli rutin, geçen seans 60×10 ve 22×10.
  - Sonda, kontrollerin gerçek dokunma sınırlarını, ✓ sonrası odak/klavye durumunu ve mola şeridinin kaydırmasını ölçtü.
  - Görüntüler ve ham çıktı: `review/A5_assets/` (`a5-w393-*.png`, `a5-w320s13-*.png`, `*.txt`, sonda kaynağı `a5_review_probe_test.dart.txt`).
  - Bu bir widget testidir, telefon değildir. Gerçek klavye çizilmez; `testTextInput.isVisible` klavyenin açık/kapalı *istendiğini* gösterir.
  - Başlık metninin soluk görünmesi ve "✓" yerine "≣" çizilmesi test ortamının ürünü olabilir (cam arka plan ve yedek font yok). Bulgu sayılmadı.
- **Rakip kaynakları (Q1/Q2):** erişim tarihi 18.10.2026. MyFitnessPal yardım sayfaları bu oturumda **403** döndü. MFP için yalnız 03'ün daha önce eriştiği bağlantılar anılıyor; yeni MFP iddiası yok. Strong'un set kaydı/klavye yardım sayfası bulunamadı. Strong için yalnız mola sayfası var.
- **Yapılamayanlar:** gerçek iPhone/Samsung'da dokunma/süre ölçümü (kural gereği yok), VoiceOver/TalkBack, kamera ile barkod.
- **Dokunuş sözleşmesi:** 04 ile aynı. Klavye tuşları, kaydırma ve izin pencereleri sayılmaz, ayrıca belirtilir. Başlangıç noktası açık uygulamada ilgili ekran. "Uygulamayı aç" sayılmaz.

## 1. Aktif antrenman: kontrol haritası

### 1.1 Set satırı (soldan sağa, 393 genişlikte ölçülen)

| Kontrol | Boyut (G) | Dokununca (K) | Not |
|---|---|---|---|
| Set no / tip rozeti | 30×32 | Tipi döngüyle değiştirir: normal → I → D → F (`active_session_screen.dart:630`) | "Başarısızlık" için 3 dokunuş. Yanlış dokunuşta sessizce tip değişir, geri alma ipucu yok |
| ÖNCEKİ | 56 genişlik, salt metin | Yok | Geçen seansın *aynı numaralı* seti (`active_session_widgets.dart:453`) |
| KG alanı | 74,5×40 (393); **38×47 (320@1,3)** | Klavye açar, `numberWithOptions(decimal:true)` (`:1282`) | 320@1,3'te **öneri ipucu hiç görünmüyor**, alan boş (G, `a5-w320s13-1-initial.png`) |
| TEKRAR alanı | 74,5×40 / 38×47 | Tam sayı klavyesi | Aynı |
| RPE hücresi | 44 genişlik | Panel: değer seç + "Tamam" = 3 dokunuş (`rpe_picker_sheet.dart:117`) | İsteğe bağlı. Ana yolu kesmiyor (S0) |
| ✓ | **38×34** (iki genişlikte de) | Boş alanları öneriyle doldurur, tamamlar, rekor kontrol eder, molayı başlatır (`:598–619`) | 48×48 altında. 02/U04 doğru |

**Sıradaki setin altındaki yardım satırı** (`_ActiveSetAssist`, `:559`): solda "✓ ile 60 kg × 10 kaydedilir", sağda **− [2,5 kg] +**. − ve + **36×30** (G). Ortadaki adım etiketi dokununca adım seçici açılır. Yalnız ağırlıklı ölçümde ve yalnız ilk tamamlanmamış sette çıkar.

**Hareket başlığı:** ekipman simgesi, ad, dinlenme çipi (⏱ 1:30, dokununca süre paneli; rutindeyse rutine de yazar, `:704`), "?" (nasıl yapılır), "⋮" (yukarı/aşağı taşı, kaldır). İlerleme önerisi satırında "+1 tekrar" / "+2,5 kg" uygula ve geri al düğmesi var (`:835`).

**Kart altı:** "Set Ekle" / "Çıkar". Çıkar yalnız *son* seti siler (`:641`). Ortadaki bir set silinemez.

**Üst çubuk:** başlık, canlı süre, "n/m set", ince ilerleme çubuğu, sağda **Bitir** (59×46).

**Mola şeridi** (`RestBanner`, `:138`): tarih çubuğunun da üstünde yer alır. −15 s / +15 s / Atla, boyutları **49×31 / 45,6×31** (393). Ekranın en üst bölgesinde, tek elle başparmaktan en uzak alanda.

**Geri:** `PopScope` her zaman yakalar. Veri varsa "Devam et / Ayrıl" diyaloğu çıkar. "Ayrıl" **taslağı siler** (`:980–988`). Koruyarak çıkma yolu yok (02/U01 doğru).

**Bitir:** onay yok. Veri yoksa uyarı verir. Veri girilmiş ama ✓'lenmemiş set `isComplete=false` olarak kaydedilir. Yalnız öneri olan (dokunulmamış) setler atılır (`active_session_model.dart:225`). Özet ekranında "Tamam" ile Antrenman sekmesine dönülür.

**Kilit ekranı / Dynamic Island (K):** seti tamamla, kilo ±, mola +15 / atla (`active_session_screen.dart:190–218`). Hevy'nin belgelenmiş kilit ekranı aracı **kilo düzenlemiyor**, değerler "uygulama içinden" giriliyor (Q2, [Hevy Live Activity](https://www.hevyapp.com/features/live-activity/)). Bu, FitPack'in rakipten **ileride** olduğu bir nokta ve korunmalı.

### 1.2 Ölçülmüş üç davranış (G)

1. **Mola şeridi yerleşimi kaydırıyor.** 1. setin ✓'si y=281'deyken, ✓ sonrası şerit girince bütün liste **+68 pt** iniyor (`a5-w393-1-initial.png` → `a5-w393-2-after-check.png`). Bir sonraki ✓ hedefi yer değiştiriyor. Mola bitince liste yeniden 68 pt çıkıyor. Bu iki kayma her sette yaşanıyor.
2. **✓ sonrası klavye tutarsız.** Senaryo A'da yalnız tekrar yazıldı, kg öneriden doldu. `fillGen++` alan anahtarlarını değiştiriyor (`active_session_widgets.dart:1038`), odak düşüyor, klavye kapanıyor. Senaryo B'de kg ve tekrar elle yazılıp ✓'lendi. Klavye **açık kalıyor** (iki genişlikte de `isVisible=true`). 320 genişlikte liste sürüklenince de açık kaldı. ListView'da `keyboardDismissBehavior` yok (K).
   - Flutter, iOS/Android'de dokunmatik dışarı dokunuşta odağı **kaldırmıyor** (SDK `editable_text.dart:6749–6756`).
   - iOS'ta `decimal:true` ondalık tuş takımına karşılık gelir ve bu takımda dönüş ("Bitti") tuşu yoktur (S, Apple `UIKeyboardType.decimalPad`; **iPhone'da gözle doğrulanmalı**).
   - Sonuç: iPhone'da iki alanı yazıp ✓'leyen kullanıcının klavyesi açık kalır. Kapatmanın tek yolu `_dismissKeyboard` çağıran bir kontrole (±, dinlenme çipi, ⋮) dokunmak. Bu, istenmeyen bir kilo adımı da yazabilir. **H** (gerçek cihaz doğrulaması gerekli).
3. **320@1,3'te tablo çöküyor.** "ÖNCEKİ" ve "TEKRAR" başlıkları heceye bölünüyor ("ÖNCE / Kİ", "TEKR / AR"). Alanlar 38 genişliğe iniyor ve öneri ipucu görünmüyor. Kullanıcı yalnız yardım satırındaki metinden ne kaydedileceğini anlayabiliyor (`a5-w320s13-1-initial.png`).

### 1.3 Dokunuş sayıları — mevcut ve önerilenler

"Etkin set kartı" = bu raporun önerisi (§1.5). "Odak (B)" = `concept-workout.png` orta kolon. Klavye tuşları parantez içinde.

| Görev | Mevcut (K/G) | Odak görünümü (B) | K4-a: ± satırda, iki satırlı set | K4-b: sayıya dokun → adım paneli | Etkin set kartı (öneri) |
|---|---|---|---|---|---|
| Home'dan rutini başlat | 2 (kart → önizleme "Başla") | 2 | 2 | 2 | 2 (U08 ayrı karar) |
| Seti önerildiği gibi kaydet | **1** (✓ 38×34, satır sonunda) | 1 (alt 56'lık düğme) | 1 | 1 | **1** (alt 56'lık düğme ya da ✓ 48) |
| Kilo +2,5 ve kaydet | **2** (yardım satırında + 36×30, ✓) | 2 | 2 | **3** (sayıya dokun, +, ✓/kapat) | **2** (48'lik +, tamamla) |
| Tekrar 10→8 ve kaydet | **2 (+1 tuş)**: alana dokun, "8", ✓; alan doluysa silme tuşları da eklenir | 3 (−, −, tamamla) | 3 | **4** (dokun, −, −, ✓) | 3 (−, −, tamamla) ya da 2+tuş (sayıya dokununca sayı paneli) |
| Tekrar 10→5 ve kaydet | 2 (+1 tuş) | 6 | 6 | 7 | 2 (+1 tuş) (sayı paneli) |
| Sıradaki olmayan seti düzelt | 2+ (+tuş): alana dokun, yaz | **3+** ("Tümü", sete dokun, yaz) | 2 | 3 | 2 (+tuş): kompakt satıra dokun → açılır |
| Molayı atla | 1 (üstte, 45,6×31) | 1 | 1 | 1 | 1 (altta, ≥48) |
| Seans ortasında hareket ekle | Listenin sonuna kaydır + 3 (Hareket ekle, arama alanı, satır) (+yazım). Arama otomatik odaklanmıyor (`exercise_library_screen.dart:182`) | aynı | aynı | aynı | 3 (+yazım); arama otomatik odak alırsa 2 |
| Bitir | 1 (+1 özetten çıkış) | 1 | 1 | 1 | 1 |
| 5 hareket × 3 set, hepsi önerildiği gibi | **2 + 15 + 1 = 18** | 18 (+ hareket geçişleri otomatikse) | 18 | 18 | 18 |

**Okuma:**
- Sık iş (öneriyi onayla, +bir adım) **her düzende aynı sayıda dokunuş**. Kazanç *isabette* (48'lik hedef, başparmak bölgesi) ve *kayma olmamasında*.
- Odak görünümü ±1–2 tekrarda klavyeden kurtarır ama büyük değişimde (10→5) yavaşlar. Sıradaki dışındaki setlere erişime de bir dokunuş ekler.
- K4-b (adım paneli) her değişikliğe bir aç/kapa dokunuşu ekler. **Bu persona için en yavaş seçenek.**
- 12'nin "satır iki kata çıkar" kaygısı her sete uygulanırsa doğru, ama ± yalnız etkin sette gerekiyor (zaten öyle). 3 set × 2 satır gibi bir maliyet oluşmaz.

### 1.4 Rakip karşılaştırması (set)

| Ürün | Belgelenen davranış | Sınıf | FitPack'e çıkarım |
|---|---|---|---|
| Hevy | ÖNCEKİ sütunu. Daha önce yapılmış hareket eklenince önceki set/kilo/tekrar otomatik gelir. Set "tamamlandı" işaretlenince mola başlar. Mola her hareketin üstünde, −15/+15 | Q1/Q2 · [track-workouts](https://www.hevyapp.com/features/track-workouts/), [rest timer](https://www.hevyapp.com/features/workout-rest-timer/) | FitPack'in "✓ = öneriyi onayla" modeli aynı sınıfta. Fark yaratmak için dokunuş sayısını değil isabeti iyileştir |
| Hevy kilit ekranı | Seti tamamla, mola ±15/atla; kilo/tekrar **yalnız uygulamada** | Q2 · [live-activity](https://www.hevyapp.com/features/live-activity/) | FitPack kilit ekranında kilo ± sunuyor. Bu üstünlük korunmalı ve tanıtılmalı |
| Strong | Mola set tamamlanınca hemen başlar. Çalışırken antrenman ekranının **sol üstünde küçük** durur, dokununca tam ekran, "Skip" | Q1 · [Strong Rest Timer](https://help.strongapp.io/article/231-rest-timer) | Strong da üstte ama *küçük ve yerleşimi itmeyen* bir öğe. FitPack'teki kayma sorunu Strong'da belgelenmiyor |
| Strong set girişi / özel tuş takımı | Resmî yardım sayfası bulunamadı | **bilinmiyor** | Strong'un özel sayı klavyesi olduğu iddiası bu raporda kullanılmadı |

### 1.5 Önerilen düzen: "etkin set kartı" (K4'e cevap)

- **Biten setler:** tek satır "1 · 60 × 10 ✓", yaklaşık 44 pt. Dokununca düzenlenebilir hale gelir.
- **Sıradaki set:** iki satırlı kart.
  - Üst satır: ÖNCEKİ "60×10 · geçen hafta", büyük KG ve TEKRAR değerleri.
  - Alt satır: KG için [−][+], TEKRAR için [−][+], hepsi ≥48×48. Sayıya dokununca bugünkü gibi yazma.
  - En altta **"Seti tamamla · 60 kg × 10"**: 56 pt, tam genişlik, başparmak bölgesinde.
- **Gelecek setler:** tek satır, soluk değil **etiketli** öneri ("öneri 60×10"). P02 kontrast ölçütü burada da geçerli.
- **Mola:** ekranın **altında sabit yükseklikli çubuk** (kalan, −15, +15, Atla, ≥48). Liste kaymaz. Sayaç bitince çubuk "Sıradaki: Incline DB Press 1/3" bilgisine döner.
- **Klavye:** sayı alanlarının üstünde "◀ ▶ Bitti" çubuğu ya da uygulamaya özel sayı paneli. MacroFactor porsiyon girişinde özel klavye kullanıyor (Q2, [new-food-logger](https://macrofactor.com/new-food-logger/)). Asgari çözüm: ✓ ve "Seti tamamla" her durumda `_dismissKeyboard()` çağırsın, ListView `onDrag` ile klavyeyi kapatsın.
- B'nin "Tümü" modu gerekmez: tablo hep orada, yalnız bir satır büyük.

12'nin "odak görünümünü deneye ertele" kararına **katılıyorum**. Ama ertelenen şey ayrı mod olmalı; *etkin satırın büyümesi* Faz 1'in 48×48 işinin doğal çözümü. K4 iki seçenekten biri değil, bu üçüncü yol.

## 2. Beslenme: kontrol haritası ve dokunuş sayıları

**Beslenme sekmesi** (K, `nutrition_screen.dart`): tarih ‹ › → enerji özeti (kalan kcal büyük; makrolar "alınan / hedef") → "Öğün günlüğü" → 4 öğün bölümü (başlık: kcal, **+**, **⋯** → "Başka günden kopyala") → kayıt satırları (ad, gram, makro, kcal, çöp kutusu; sola kaydırınca silme) → o öğün için "Her zamanki" kartı (yalnız bugün ve saat dilimine uyan öğünde) → Gün tamam → haftalık kayıt satırı. Altta sabit **Yemek Ekle** ve **barkod**. Gün boşsa üstte "Dünü kopyala" çıkar.

**Kayıt satırına dokunmak hiçbir şey yapmıyor.** DAO'da `updateFoodLog` yok (K, `grep` boş). Miktar düzeltmenin tek yolu sil + yeniden ekle.

**Ekleme paneli** (`add_food_sheet.dart`):
- Yerleşim: öğün seçici → arama alanı (**otomatik odak yok**, `:743`) → Barkod / Hızlı kalori / Kendi besinin → "Son eklediklerin" (8 kayıt, son gramajla) → tüm besinler + kategori.
- Satırda ⊕ porsiyonu ya da son gramajı **tek dokunuşla** ekler. Satıra dokununca alt miktar paneli açılır: −/+ (10 g ya da 0,5 porsiyon), hazır çipler, "Öğle yemeğine ekle · N kcal".
- Panel ekledikten sonra kapanmaz; üstte "Geri al" şeridi çıkar.

| Görev (başlangıç: uygulama açık, Home) | Mevcut (K) | Önerilen | Kazanç |
|---|---|---|---|
| Dünkü kahvaltıyı yeniden gir | **5**: Beslenme, Kahvaltı ⋯, "Başka günden kopyala", "Dün", Ekle. Koşullu **1**: Home'da "Her zamanki kahvaltı" görünürse Ekle. Gün tamamen boşsa "Dünü kopyala" 2 dokunuş ama **bütün günü** kopyalar | Öğün başlığında "↺ Dünkü gibi (3 besin · 480 kcal)" satırı, geri alınabilir: **2** (Beslenme, satır). Home öğün kutusunda uzun basma ya da kartta aynı satır: **1** | 5→2 |
| Son kullanılan besini aynı porsiyonla ekle | **2**: Home öğün kutusu, ⊕ (+1 "Bitti"). Sekmeden: **3** (Beslenme, Yemek Ekle, ⊕) | Aynı; ⊕ hedefini ≥48'e çıkar | — |
| Yeni besini arayarak ekle (yerel listede var) | **4–5 + yazım**: Beslenme, Yemek Ekle, arama alanına dokun, ⊕ (ya da satır → Ekle) | Arama alanı panel açılınca odak alsın: **3–4** | −1 |
| Yerelde olmayan paketli ürün (metinle) | +2: "İnternette ara", sonuç, sonra Ekle | Aynı | — |
| Barkodla ekle | **3**: Beslenme, barkod, (otomatik okuma) Ekle. Home kutusundan da 3. Bulunamazsa şeritte mesaj çıkar, akış biter. "Kendi besinin" formuna veriyi taşıyan bir yol yok (`barcode_flow.dart:86`) | Bulunamadı → "Bu barkodla kendi besinini oluştur" (barkod önceden dolu) | Ölü uç kalkar |
| Girilmiş kaydın porsiyonunu düzelt | **4–5**: çöp kutusu + Yemek Ekle + satır + miktar + Ekle | Satıra dokun → aynı miktar paneli "Güncelle": **2–3** | Önemli |
| Uygulamayı aç → kalan proteini gör | **0 dokunuş ama görünmüyor**: Home'da "Bugün X g protein, Y kcal kaldı" satırı birincil eylem kartının altında, 393×852'de ilk ekranın dışında (G, `dark-tr-home.png`). Enerji kartı protein için yalnız "8 / 160 g" veriyor | Protein hücresi "152 g kaldı · 8/160": **0, ilk ekranda** | Zihinden çıkarma gerekmez |

### 2.1 Rakip karşılaştırması (beslenme)

| Ürün | Belgelenen davranış | Sınıf | Çıkarım |
|---|---|---|---|
| MacroFactor Favoriler | Kalp ile kaydet. Arama ekranının **en üstünde** Favoriler çubuğu. Tek dokunuşla **kayıtlı porsiyonla** eklenir. Aynı besine birden çok porsiyon ön ayarı | Q2 · [Favorite Foods](https://macrofactor.com/favorite-foods/) | FitPack'in ⊕ + son gramajı "örtük favori". Aynı besin için iki farklı porsiyon (örn. 2 ve 3 yumurta) karşılığı yok. Düşük öncelik |
| MacroFactor kayıt | Yazmadan önce saate göre "go-to"lar ve favoriler yüklenir; "Latest" listesi. Tabak (Plate) ile birden çok besin tek "Log Foods" ile kaydedilir. Hızlı ekle kalıcı besin oluşturmaz | Q1 · [How to log food](https://help.macrofactorapp.com/en/articles/215-how-to-log-food-in-macrofactor) | FitPack paneli bunun eşdeğeri (kapanmayan panel). "Saate göre öneri" yalnız Her zamanki kartta var; panelin içine taşınabilir |
| MacroFactor kopyala/yapıştır | Tek besin, çoklu seçim ya da tüm gün; herhangi bir tarihe ve saate | Q1/Q2 · [Copy and Paste](https://help.macrofactorapp.com/en/articles/95-copy-and-paste), [10 features](https://macrofactor.com/10-macrofactor-features/) | FitPack'in öğün kopyalaması güçlü ama 3 katman derinde |
| MacroFactor özel klavye ve kalan banner | Porsiyon alanına dokununca "custom keyboard". Besin bandı kaydırılınca *günün kalan makroları* görünür | Q2 · [new-food-logger](https://macrofactor.com/new-food-logger/) | Kalan makroyu kayıt anında göstermek doğrulanmış bir kalıp. FitPack panelinde kalan protein yok |
| MyFitnessPal Today | 03'e göre öğün Log, son/sık yiyecekler | Q1 (03 aracılığıyla; bu oturumda 403) | Yeni iddia yok |

## 3. Raporlarla anlaşma ve ayrılıklar

| Rapor / iddia | Bulgum | Kanıt |
|---|---|---|
| **02 U04** (✓ 38×34, ± 36×30, tip 30×32) | **Katılıyorum.** Ölçüm iki genişlikte aynı | G `a5-w393.txt`, `a5-w320s13.txt` |
| 02 U01 (Ayrıl taslağı siliyor) | Katılıyorum | K `active_session_screen.dart:986` |
| 02 "Mola bandı… bandın üst konumu tek el testi ister, S2" | **Eksik:** asıl sorun konum değil, **yerleşimi 68 pt kaydırması**. S3 olmalı, çünkü her sette yanlış dokunma hedefi oluşturuyor | G `a5-w393-2-after-check.png` |
| 04 A "Değeri değiştir: Bilinmiyor" | Belirlenebilir: +adım **2**, farklı tekrar **2 + 1 tuş** | K `:742`, `:1294`; G |
| 04 A "Hareket ekle 2" | Liste sonuna kaydırma ve arama alanına dokunma eklenince **3 + yazım** | K `active_session_screen.dart:1117`, `exercise_library_screen.dart:182` |
| 04 B "Dün/geçmiş gün kopyala: bilinmiyor" | Belirlenebilir: tek öğün **5**, tüm gün **2** | K `nutrition_screen.dart:274,571`, `meal_copy_sheet.dart:230–235` |
| 04 B, 08 P08 (besin akışı güçlü, kaybetme) | Katılıyorum. Ama **kayıt düzenleme yokluğu** hiçbir raporda geçmiyor | K `nutrition_screen.dart:602–678` |
| 05 B "Odak görünümü + Tümü" | **Kısmen katılmıyorum.** Ayrı mod sıradaki dışındaki sete +1 dokunuş ekliyor. Kazanç (büyük hedef, alt eylem) etkin satır büyütmeyle mod olmadan alınabilir | §1.3 tablo |
| 05/07 "sabit alt kontroller klavyeyle yarışabilir" | Katılıyorum. Klavye sorunu bugün de var (✓ sonrası açık kalma) | G senaryo B |
| 07 §7 "Tamamlama sonrası '… kaydedildi' + Geri al" | Katılıyorum. Bugün ✓'ye tekrar basmak geri alıyor ama satırın yanında bir geri bildirim yok | K `:598–611` |
| 08 P01 "320'de iki satırlı yerleşim" | Katılıyorum, yalnız **etkin set** için | §1.5 |
| 09 ilk dilim | Katılıyorum. **Eklenmesini öneriyorum:** (a) alttaki sabit mola çubuğu ya da en azından kaymayan şerit, (b) ✓ / tamamla anında klavyeyi kapatma + `onDrag` | G §1.2 |
| **12 K4** "set satırı (set no · kg · ± · tekrar · ✓)" | **Yanlış:** ± satırda değil, yalnız etkin setin altındaki ayrı satırda (`_ActiveSetAssist`). Önerilen "adım paneli" bu persona için en yavaş seçenek (+2,5: 3; −2 tekrar: 4) | K `active_session_widgets.dart:463–472`; §1.3 |
| 12 §3.2 odak görünümünü deneye ertele | Katılıyorum. Gerekçe değişiyor: tabloyu korumak doğru ama *etkin satır büyümesi* Faz 1'e girmeli | §1.5 |
| 12 §3.3 "Home öğün kartı aşağı iner → Faz 3'te + Ekle" | Katılıyorum. Ek olarak "Dünkü gibi" ve "kalan protein" Faz 1'e alınabilecek kadar ucuz | §2 |
| 03 C01 (Strong: küçük mola göstergesi) | Katılıyorum. Kanıt kaymayı da destekliyor | Q1 Strong |

## 4. Sıralı ilk 10 değişiklik (bu iki persona için)

Sıralama ölçütü: sıklık (her set / her öğün) × hata riski, maliyete bölünür. Şema değişikliği yalnız 6. maddede (DAO güncelleme metodu; tablo değişmez).

| # | Değişiklik | Neden (kanıt) | Maliyet | Doğrulama |
|---|---|---|---|---|
| 1 | **Mola göstergesi listeyi kaydırmasın:** alt sabit çubuk, ya da şerit alanı seans boyunca ayrılsın | Her sette 68 pt kayma (G) | Düşük–orta | Ölçüm sondası: ✓ öncesi/sonrası sonraki ✓ konumu aynı |
| 2 | **Etkin set kartı:** sıradaki set için 48'lik kg/tekrar ±, 56'lık "Seti tamamla · 60×10"; diğer setler tek satır | U04 (G); dokunuş aynı, isabet artar (§1.3) | Orta | 320@1,3 ve 393 render; tek elle 9 set görevi |
| 3 | **Klavye sözleşmesi:** ✓ / tamamla daima klavyeyi kapatsın; ListView `onDrag`; sayı alanında "Sonraki / Bitti" çubuğu (ya da özel sayı paneli) | Senaryo B'de klavye açık kalıyor (G); iOS ondalık takımında Bitti yok (S, H) | Düşük (ilk ikisi), orta (çubuk) | **iPhone'da** iki alanı yaz → ✓ → klavye kapanır |
| 4 | **Girilmiş besin kaydını düzenle:** satıra dokun → mevcut miktar paneli "Güncelle" | Bugün sil + yeniden ekle (4–5 dokunuş) (K) | Orta (DAO `updateFoodLog` + senkron yolu) | Gram değiştir → toplamlar ve senkron kuyruğu doğru |
| 5 | **"Dünkü gibi" öğün kısayolu** (öğün başlığında, geri alınabilir) | 5→2 dokunuş (K); Her zamanki kartının koşulları dar | Düşük (mevcut `copyItems` + `addFoodsToMealIds`) | Kahvaltıyı kopyala → geri al; boş öğünde görünür, doluda gizli |
| 6 | **Kalan protein ilk ekranda:** enerji kartında protein hücresi "X g kaldı" | Bugün alınan/hedef var, kalan cümlesi kıvrımın altında (G) | Çok düşük | 393×852 Home ilk ekranda "kaldı" görünür |
| 7 | **320 / büyük yazıda tablo:** başlık kısaltmaları ("ÖNC.", "TKR") ya da başlıksız etiketli hücre; öneri alan dışında da okunur | Başlıklar heceye bölünüyor, öneri görünmüyor (G) | Düşük | `a5-w320s13` render tekrarı |
| 8 | **Ekleme panelinde arama otomatik odak** (Yemek Ekle'den açılınca; öğün kutusundan açılınca değil) | Her aramada +1 dokunuş (K) | Çok düşük | Panel aç → doğrudan yaz |
| 9 | **Barkod bulunamadı → "Kendi besinini oluştur" (barkod dolu)** | Bugün ölü uç (K `barcode_flow.dart:86`) | Düşük | Bilinmeyen barkod → form → sonraki taramada yerel eşleşme |
| 10 | **Set tipi rozeti:** döngü yerine uzun basma ya da küçük menü; yanlış dokunuşta "Isınma" geri al ipucu | 30×32 hedef, sessiz tip değişimi (K/G) | Düşük | Kazara dokunuşta değer/tip korunur |

Dikkatle *önerilmeyenler*:
- RPE'yi ana yola almak.
- Ayrı odak modu.
- Kilit ekranı kontrollerini değiştirmek. Rakipten iyi; yalnız ± hedeflerinin cihazda doğrulanması gerekiyor.
- Bitir'e onay diyaloğu eklemek. Mevcut 1 dokunuş doğru; ✓'lenmemiş set varsa özet ekranında "2 set tamamlanmadı" bilgisi yeterli (H).

## Pakete etkisi

- **Güçlenen:** 02 U04 ve 08 P01 (ölçümle doğrulandı); 02 U01; 04 B'nin "paneli kaybetme" uyarısı; 12'nin odak görünümünü erteleme kararı; 03 C01.
- **Zayıflayan / düzeltilmesi gereken:**
  - **12 K4** soruyu yanlış kuruyor. ± bugün satırda değil. Seçenek listesine "etkin set kartı" eklenmeli; "adım paneli" bu persona için en yavaş seçenek olarak işaretlenmeli.
  - **02** mola şeridini S2 "konum" sorunu sayıyor. Kayma kanıtıyla S3'e çıkmalı.
  - **04**'teki "Değeri değiştir: Bilinmiyor" ve "kopyala: bilinmiyor" satırları belirlenebilir sayılarla (2; 2+tuş; 5; 2) güncellenmeli. "Hareket ekle 2" → 3 + yazım + kaydırma.
- **Eksik (pakete eklenmeli):**
  - (a) Mola şeridi yerleşim kayması.
  - (b) ✓ sonrası klavye tutarsızlığı ve iOS'ta Bitti tuşu yokluğu. iPhone'da gözle doğrulama 10_VALIDATION'a eklenmeli.
  - (c) Besin kaydı düzenleme yokluğu.
  - (d) 320@1,3'te set tablosu başlık bölünmesi ve öneri ipucunun kaybolması.
  - (e) Barkod bulunamadı ölü ucu.
- **Önerilen düzeltme:** 09 Faz 1'e madde 1, 3 (ilk iki alt adım) ve 6 eklenmeli; maliyetleri düşük. Madde 2 Faz 1'in 48×48 işinin uygulama biçimi olarak tanımlanmalı. Madde 4–5 Faz 3B yerine Faz 1/2'ye çekilebilir. Madde 4 küçük bir tasarım notu ister (senkronda güncelleme yolu).
