# A2 — Çalışan uygulamada yolculuk denemesi (Android emülatör)

18 Ekim 2026 · kaynak `main` = `07104d1` · debug APK, Supabase **Dev** (`qecbnrkbordkqeogmevi`)
Ekran görüntüleri: `review/runtime/` (97 dosya; adlar `yolculuk-adım` biçiminde).

## Karar özeti

1. Beş yolculuğun (A–E) beşi de ve yeni kullanıcı kurulumu gerçekten çalıştırıldı. Çökme (crash) yok; senkron Dev'e doğru yazdı (1 seans, 5 set, 3 öğün kaydı, SQL ile doğrulandı). **G**
2. 04'teki belirlenimci dokunuş sayılarının çoğu **doğru çıktı** (A tekrar seans 4, B hızlı + 3/4, B Home öğün 2/3, D son seans 2, D hareket grafiği 4, E yeniden açılış 1). Ama hemen hepsi **en az 1 kaydırma** istiyor: Home'daki asıl eylem düğmesi ilk ekranda yüzen alt menünün **arkasında** kalıyor. **G**
3. İlk kez yapılan rutinde ✓ "öneriden doldurma" yok; ilk set **KG alanı + TEKRAR alanı + ✓ = 3 dokunuş + yazma**; sonraki setler hayalet değerle 1 dokunuş. **G**
4. 02/U04'teki hedef boyutları birebir doğrulandı: ✓ **38×34 dp**, ± **36×30 dp**; mola −15s/+15s/Atla **49/46×31 dp**. **G**
5. U01 doğrulandı ve ağırlaştı: çıkış diyaloğunda **yıkıcı "Çık" dolu ana düğme**, "Devam et" düz metin; ayrıca **Bitir onaysız** (20 setin 5'i bitmişken tek dokunuşla seans kapandı). **G + K**
6. Süreç ölümü (process death) sonrası taslak, setler ve **mola kalan süresi doğru** geri geldi (57 sn sonra 2:03). Fakat açılış Home'a düşüyor, sistem bildirimi kayboluyor. **G**
7. Yeni hatalar: Antrenman sekmesinde ekran dışını hedefleyen ipucu kartı (ekran kararıyor, metin görünmüyor); hareket 1RM grafiği aynı günün setlerini "gelişim" diye çiziyor ve eksen etiketleri tekrar ediyor; Türkçe büyük harf hatası ("TERCIHLER", "KIMLIK"); sunucu hata metni İngilizce. **G**
8. Önceki değerle 1-dokunuş akışında bir **veri riski**: 2. seansta set 1'i 40 kg ile ✓ edince, geçen sefer 42.5 kg olan set 3–4'ün hayalet değeri 40'a düştü; sadece ✓'ye basan kullanıcı geçen seferden düşük kaydeder. **G**

## Yöntem ve sınırlar

- **Ortam:** AVD `FitPack`, 1080×2400 px, yoğunluk 420 dpi → 1 dp = 2.625 px; uygulama dili `cmd locale set-app-locales … tr-TR` ile Türkçe (sistem İngilizce kaldı). Hep `adb -s emulator-5554`; gerçek telefonlara dokunulmadı, üretim Supabase'ine yazılmadı, repo dosyası değişmedi (`git status` yalnız mevcut izlenmeyen dosyaları gösteriyor).
- **Hesap:** Uygulama içinden kayıt. `fitpack.walk.…@example.com` sunucu tarafından reddedildi (bkz. hata 4). `fitpack.gate.test+walk24357@gmail.com` ile kayıt oldu; e-posta doğrulaması gerektiği için Supabase MCP ile **yalnız Dev'de** `auth.users.email_confirmed_at` güncellendi (kullanıcı `ba9228f1-…`).
- **Dokunuş sayımı:** 04'ün sözleşmesine uyuldu (yazma tuşları, izin pencereleri, kaydırma ayrı). Metin alanına odaklanma dokunuşlarını ayrıca gösterdim, çünkü fiziksel olarak gereklidirler. Kaydırmalar "swipe" olarak ayrıca sayıldı.
- **Koordinat doğrulama:** Her dokunuştan önce `screencap` + `uiautomator dump` sınırları. İki istisna kayda geçti: (a) klavye açılınca liste kaydığı için bir zincir yanlış alana "5038" yazdı (`E-15-row-typed`), düzeltildi; (b) bir dokunuş, Flutter erişilebilirlik ağacının **gecikmeli/eski** dökümü yüzünden Beslenme sekmesine düştü (`E-12-mistap-landed-on-nutrition-coachmark`). Sonuç: Flutter'da `uiautomator dump` tek başına güvenilir değil; ekran görüntüsü esas alındı.
- **Yapılamayanlar:** TalkBack turu yapılmadı (yalnız uiautomator etiketleri incelendi). Süreler ölçülmedi (debug derleme yavaş; soğuk açılış ~10 sn beyaz ekran, sürüm derlemesini temsil etmez). Barkod, Google girişi, kilit ekranı kumandaları denenmedi. Arada ~1,5 saatlik zorunlu duraklama oldu; bu, seans süresine istemeden "boşta bekleme" testi ekledi (bkz. E).
- `am kill` ön plan servisi (mola bildirimi) yüzünden süreci öldürmedi (`E-04-am-kill-noop-app-still-alive`); gerçek süreç ölümü `run-as … kill -9` ile yapıldı.

## Kurulum (yeni kullanıcı) — ek yolculuk

| Adım | Ekran | Dokunuş |
|---|---|---|
| Hoş geldin → Hesap oluştur | `00-welcome-tr` | 1 |
| E-posta alanı, şifre alanı (odak) | `01-onb-signup-filled` | 2 |
| Kayıt Ol → "Kayıt alındı. E-postanı doğrulayıp giriş yapabilirsin." | `01-onb-confirm-needed` | 1 |
| (dış adım: e-posta doğrulama — burada SQL ile) | — | — |
| Giriş Yap (alanlar dolu kalıyor, iyi) | — | 1 |
| Deneyim + gün sayısı + İleri | `02-onb-first`, `02-onb-q1-selected` | 3 |
| Program önerisi (Üst/Alt · Orta ön seçili) → İleri | `03-onb-page2` | 1 |
| Kilo + hedef kilo (odak), "Kilo Ver" ön seçili → İleri | `04-onb-page3-filled` | 3 |
| Kalori/protein önerisi → Başlayalım | `05-onb-page4` | 1 |

**Toplam 13 dokunuş** (alan odakları hariç 9) + e-posta doğrulama. **G**
Sürtünmeler:
- Kayıt sonrası e-posta doğrulaması zorunlu; uygulama dışına çıkmadan ilerlenemiyor. **G**
- Program kartında "Bu programla başla" metni bir bağlantı gibi duruyor, oysa ilerletme alttaki "İleri". **G**
- Son sayfada iki eşit güçlü düğme yarışıyor ("Evet, hatırlat" ve "Başlayalım"). Hatırlatma atlanırsa bildirim izni **ilk set ✓'sinde, set ortasında** sistem penceresiyle soruluyor (`A-05-notif-permission-midset`). **G**
- Son sayfa "Sonradan Ayarlar'dan da güncelleyebilirsin" diyor; kalori/protein hedefleri gerçekte **Profil**'de (`C-03-profile`). **G** (U03'ün kurulumdaki karşılığı)

## A — Antrenman başlat → set → mola → tamamla

**İlk seans (yeni kullanıcı, önceki değer yok):**

| # | Eylem | Ekran | Dokunuş |
|---|---|---|---|
| 1 | Home'da 1 kaydırma (düğme alt menünün arkasında) | `06-home-first`, `A-01-home` | swipe |
| 2 | "Antrenmanı başlat" → **önizleme açılıyor** (başlatmıyor) | `A-02-preview` | 1 |
| 3 | "Antrenmana Başla" | `A-03-active` | 1 |
| 4 | Set 1: KG alanı + yaz, TEKRAR alanı + yaz, ✓ | `A-07-set1-typed` | 3 |
| 5 | Set 2–4: hayalet değer ("↳ ✓ ile 40 kg × 8 kaydedilir") → ✓ | `A-08-set2-done` | 1/set |
| 6 | ± ile kilo artır (42.5) → ✓ | `A-10-plus`, `A-11-set3-done` | 2 |
| 7 | Bitir → Özet → Bitti | `A-12-after-finish` | 2 |

Tek setlik koşullu örnek: **ilk seansta 6 dokunuş** (+1 swipe) özete; tekrar seansta **4** (Home→önizleme→Başla→✓→Bitir; `A-16`, `A-17`'de ✓ tek dokunuşla 40×8 kaydetti). 04'ün "4" sayısı yalnız önceki değeri olan harekette geçerli. **G**

Gözlenen sürtünme:
- Home düğmesinin etiketi "Antrenmanı başlat" ama önizlemeye gidiyor; asıl başlatma ikinci ekranda "Antrenmana Başla". `home_screen.dart:340–343`, `:366–369` (`onTap: context.push(AppRoutes.routinePreview…)`). **G + K**
- **Boş set ✓ kabul ediliyor:** 0 kg/0 tekrar set "tamam" sayıldı, mola başladı, sayaç 1/20 oldu (`A-04-empty-check`). **G** (Bitirirken `_hasData` kontrolü var ama set bazında yok — `active_session_screen.dart:904`.)
- Rutin hedefi (4×6–8) aktif satırlarda görünmüyor; ilk seansta KG/TEKRAR "0" yer tutucu. **G**
- ✓ sonrası klavye açık kalıyor, mola bandı içeriği aşağı itiyor; tamamlanan satır klavyenin altına kayabiliyor (`E-16-row-set1-rest`). Bir hareket bitince sıradakine otomatik kaydırma yok (`E-11-set4-done-rest`). **G**
- 2. seansta öneri kartı "+1.25 kg dene" diyor, ± adımı 2.5 kg, ✓ ise öneriyi değil geçen değeri kaydediyor; set 1'i ✓ edince set 3–4'ün hayalet değeri 42.5'ten 40'a düşüyor (`A-16` → `A-17`). **G**
- **Bitir onaysız:** 20 setin 5'i bitmişken tek dokunuş seansı kapattı (`A-12`). `_finish()` yalnız "hiç set yok" durumunu engelliyor, eksik set için onay yok — `active_session_screen.dart:902–945`. **G + K**
- Süre boşta beklemeyi de sayıyor: 1,5 saat bekleme sonrası özet **100 dk**, seans detayında **~735 kcal** (`D-02-session-detail`). Gerçek kullanıcıda seansı açık unutmak kalori tahminini şişirir. **G**
- Özet sonrası "Bitti" Home'a değil **Antrenman sekmesine** götürdü ve orada bozuk ipucu katmanı açıldı (hata 1). **G**

**Dokunma hedefleri (uiautomator sınırları, px ÷ 2.625):**

| Kontrol | px | dp | 02/04 iddiası | Sonuç |
|---|---|---|---|---|
| Set ✓ | 100×89 | **38.1×33.9** | 38×34 | Doğrulandı |
| Kilo − / + | 95×79 | **36.2×30.1** | 36×30 | Doğrulandı |
| RPE hücresi | 100×95 | 38.1×36.2 | — | 48 altı |
| KG / TEKRAR alanı | 220×105 | 83.8×40.0 | — | yükseklik 48 altı |
| Mola −15s / +15s | 129×81 | 49.1×30.9 | — | yükseklik 48 altı |
| Mola Atla | 120×81 | 45.7×30.9 | — | iki boyut 48 altı |
| Bitir | 156×121 | 59.4×46.1 | — | sınırda |
| Geri, menü, hızlı + (yemek) | 126×126 | 48×48 | — | uygun |

Erişilebilirlik etiketi: ✓ düğmesinin ve KG/TEKRAR alanlarının `content-desc`'i **boş**; ± düğmeleri "Kiloyu 2.5 kg artır/azalt" etiketli. Ekran okuyucu ✓'yi adsız okuyacaktır (TalkBack ile doğrulanmadı → **G** uiautomator / ekran okuyucu davranışı **H**).

## B — Öğün kaydet → kalanı anla

| Yol | Gözlenen dokunuş | 04 | Ekran |
|---|---|---|---|
| Home → Beslenme → Yemek Ekle → satırdaki + | **3** kayıt, **4** Bitti ile | 3 / 4 | `B-03`…`B-05`, `B-09` |
| İlk ziyarette ek ipucu "Anladım" | +1 (bir kez) | — | `B-00-coachmark` |
| Yemek Ekle → arama alanı + yaz → satır → porsiyon "2" → "Ara öğüne ekle" | **4** kayıt (porsiyon değişikliği +1); alan odağı dahil Home'dan **5–6** | 4 / 5 | `B-06`…`B-08` |
| Home → 1 swipe → Kahvaltı "+ Ekle" → hızlı + → Bitti | **2** kayıt, **3** Home'a dönüş | 2 / 3 | `B-11`…`B-14` |

Gözlemler:
- Panel ekledikten sonra kapanmıyor, "Açma · 310 kcal eklendi · Geri al" onayı net; son porsiyon hatırlanıyor (Kahvaltıda "2 adet · 100 g" hazır geldi). 04'ün olumlu değerlendirmesi doğru. **G**
- Ekleme sonrası liste **kayıyor** ("Son ekledikleri" bölümü açılıyor, tüm satırlar ~160 px aşağı); aynı yere ikinci dokunuş başka yiyeceğe gider. **G**
- Kalan net: Beslenme halkası "1.747 kcal kaldı", Home'da "Bugün 138 g protein, 1604 kcal kaldı." satırı. Sayı biçimi tutarsız (1.747 / 1604). **G**
- Panel öğün adı "Atıştırma", düğme "Ara öğüne ekle". 2×72 kcal = "143 kcal" (yuvarlama). Barkod girişi üç yerde (arama ikonu, Barkod kutusu, dış Barkod tara). **G**
- **U03 doğrulandı:** Beslenme → "Hedefler" Ayarlar'ı açıyor; orada hedef yok (`B-10-hedefler-link`). Hedefler Profil'de. **G**
- Yeni kullanıcıya "Dünün öğünlerini kopyala" gösteriliyor (dün kaydı yok). **G**

## C — Home → sonraki eylemi bul

- İlk görünüm (411×914 dp): başlık, hafta şeridi, enerji kartı. "SIRADAKİ ANTRENMAN" kartının yalnız üst bandı görünür; **"Antrenmanı başlat" düğmesi yüzen alt menünün arkasında** (`06-home-first`). Asıl eylem için 1 kaydırma şart. **G**
- Home yaklaşık 4 ekran boyu (3 tam kaydırma, `C-home-scroll1…5`). "İlk öğününü ekle" iki kez görünüyor (tek satır + İlk hafta kartı). **G**
- İçerik durum çubuğunun altına kayıyor, perde yok; metin saat/ikonlarla üst üste biniyor (`C-home-scroll2`, `B-11`). **G**
- Antrenmanı bitirdikten sonra Home aynı gün hemen "SIRADAKİ ANTRENMAN · Alt A · Antrenmanı başlat" gösteriyor; "bugün tamam/dinlen" durumu yok (`C-02-home-after-activity-dark`). Bunun ürün kararı mı eksik mi olduğu **bilinmiyor**; U11 için önemli. **G**
- Haftalık aktivite grafiği (`B-11`) eğri yumuşatması yüzünden Cumartesi'den yükselen bir çizgi çiziyor; Cumartesi kaydı yok. **G**
- Tema: varsayılan **Koyu**, cihaz açık modda (`C-04-theme-picker`). Açık tema Home'da sorunsuz (`C-05-home-light-top`). **G**

## D — Geçmişten ilerlemeyi anla

| Alt görev | Gözlenen | 04 | Ekran |
|---|---|---|---|
| Son seansı aç | Antrenman sekmesi (1) + **2 swipe** + kart (2) | 2 | `D-01-workout-scroll*`, `D-02` |
| Hareket kuvveti | Antrenman → Kütüphane → hareket ("Son kullandıkların" en üstte) → Grafik = **4** | 4 | `D-07`…`D-09` |
| İlerleme sekmesi | Aktivite takvimi + fotoğraf + ölçüm; antrenman ilerlemesi **yok** | U05 | `D-03`, `D-04` |
| İlerleme takviminde gün | Gün → alt panel (kalori, makro, "Üst A · 5 set · 1720 kg"); seansı açan bağlantı **yok** | "kayıt Aç" | `D-05` |

Hatalar / sürtünme:
- **1RM grafiği** (1RM = one-repetition maximum, tek tekrarda kaldırılabilecek tahmini en yüksek ağırlık): tek günün 4 seti 4 nokta olarak "gelişim" çiziliyor, x ekseninde tarih yok, y ekseninde etiketler tekrar ediyor (56, 56, 55, 55…), eğri veri noktasının üstüne taşıyor, grafik ekran altına uzanıyor (`D-09-exercise-chart`). "1RM" kısaltması açıklanmıyor. **G**
- İlerleme'de "İlk kilonu gir — grafiğin buradan başlar." ipucu, kurulumda 84 kg girilmiş ve Home'da "İlk kilonu gir" tamamlanmış görünürken çıkıyor (`D-03`). **G**
- Hacim biçimi tutarsız: "1720 kg" (kart), "1.720 kg" (Antrenman üst kartı), "1.7k kg" (özet). **G**
- Türkçe arayüzde İngilizce içerik: hareket adları, "Chest · Barbell", kütüphane filtreleri (Compound, Isolation, Chest…), "Çalışan kaslar: Chest · 4 set". **G**
- "Antrenman takvimi" (üst ikon) yolu denenmedi → 04'teki "gün → kayıt Aç" iddiası **bilinmiyor**.

## E — Uygulamadan ayrıl → aktif seansa dön

| Ayrılma | Gözlem | Dokunuş | Ekran |
|---|---|---|---|
| Sistem Home, 30 sn, geri | Aynı ekran; mola doğru (beklenen 2:09, görünen 2:08). Bildirimde "Dinlenme · Sıradaki: … Set 4/4 · 42.5 kg × 8" + "+15 sn / Atla" | 0 | `E-02`, `E-03` |
| `am kill` | Süreç ölmedi (ön plan servisi) | — | `E-04-am-kill-noop…` |
| Süreç ölümü (`kill -9`) | Bildirim kayboldu; açılış **Home**'a; "DEVAM EDEN SEANS" kartı alt menü arkasında → swipe + "Seansa dön" | **1** + swipe | `E-06`, `E-07`, `E-08`, `E-10` |
| Molada süreç ölümü | Setler ve **mola korundu**: 16:03:14'te başlayan 3:00 mola, 16:04:11'de 2:03 | 1 + swipe | `E-16`, `E-17b`, `E-19` |
| Uygulama içi geri / sistem geri | "Antrenmandan çık? Girdiğin setler kaydedilmeyecek." — **Çık dolu ana düğme**, Devam et metin; Çık taslağı siliyor (resume kartı kalmadı) | 2 (silerek) | `E-20`, `E-21`, `E-22`, `E-23` |

Ek gözlemler:
- Resume açılışında ~2 sn "Boş Antrenman 0:00" başlıklı yükleme ekranı (`E-09`); yanlış seans açıldı izlenimi verir (debug derleme, sürümde süre **bilinmiyor**). **G**
- Resume kartı uzun beklemeden sonra önce "4 set · 5 dk", sonraki açılışta "5 set · 99 dk" dedi; seans içi sayaç 1:38:13. Kart süresi son taslak kaydı anına bağlı görünüyor (**H**). **G**
- Çıkış diyaloğu kodu: `TextButton` = Devam et, `FilledButton` = Çık (`active_session_screen.dart:949–963`), onay sonrası `_clearDraft()` (`:984–987`). **K**
- Süreç ölümünden sonra mola bitiş bildirimi/sesi gelir mi: **bilinmiyor** (beklenmedi).

## 04 iddiası ↔ gözlem karşılaştırması

| 04 iddiası | Gözlem | Durum |
|---|---|---|
| A başlangıç Home→önizleme→aktif = 2 | 2 + 1 swipe; düğme etiketi "başlat" ama önizleme açıyor | Doğru, eksik (kaydırma, etiket) |
| A Antrenman sekmesinden = 3 | 3 (sekme, rutin, Başla) | Doğru |
| A hazır öneri ✓ = 1/set | Önceki değer varsa 1; ilk seansta ilk set 3 + yazma | Koşullu doğru |
| A tek set koşullu örnek = 4 | Tekrar seansta 4; ilk seansta 6 | Koşullu doğru |
| A mola başlatma = 0 | 0; otomatik, bildirimle | Doğru |
| A bitir = 1, "en az bir set yoksa mesaj" | 1; eksik set için onay yok; boş set ✓'lenebiliyor | Doğru ama risk eksik yazılmış |
| B hızlı + = 3 / 4 | 3 / 4 (+ ilk ziyarette ipucu 1) | Doğru |
| B porsiyonla = 4 / 5 | 4 / 5, arama alanı odağı +1 | Doğru |
| B Home öğün = 2 / 3, "kaydırma bilinmiyor" | 2 / 3 + 1 swipe | Doğru, kaydırma artık ölçüldü |
| B Hedefler → Ayarlar (U03) | Doğrulandı | Doğru |
| C sıradaki rutin = 2 | 2 + 1 swipe; düğme ilk ekranda menü arkasında | Doğru, eksik |
| C aktif seans kartı görünürse 1 | 1 + 1 swipe | Doğru |
| D son seans = 2, "kaydırma bilinmiyor" | 2 + 2 swipe | Doğru |
| D hareket kuvveti = 4 | 4; grafik hatalı | Sayı doğru, içerik sorunlu |
| D gün → kayıt Aç | İlerleme takviminde Aç yok; Antrenman takvimi denenmedi | Bilinmiyor |
| E Home/arka plan: 0 ek seçim | 0; mola doğru | Doğru |
| E süreç ölümü: Home'dan 1 | 1 + swipe; mola kalan doğru | Doğru |
| E geri + çık = 2, görev korunmaz | 2; yıkıcı seçenek görsel olarak ana düğme | Doğru, daha ağır |
| 02/U04 ✓ 38×34, ± 36×30 | 38.1×33.9 / 36.2×30.1 dp | Doğru |

## Hata ve tutarsızlık listesi

| # | Bulgu | Ciddiyet (öneri) | Kanıt |
|---|---|---|---|
| 1 | Antrenman sekmesi ipucu katmanı ekran dışındaki "Keşfet"i hedefliyor: ekran kararıyor, metin görünmüyor (font 1.0); 1.3'te metin kesik. Ekrana dokununca kapanıyor | Yüksek (ilk antrenman sonrası ilk izlenim) | `A-13`, `F-03` **G** |
| 2 | Bitir onaysız; eksik setlerle tek dokunuşta seans kapanıyor | Yüksek | `A-12` **G**, `active_session_screen.dart:902` **K** |
| 3 | Çıkış diyaloğunda yıkıcı eylem ana düğme | Yüksek | `E-20` **G**, `:949–963` **K** |
| 4 | Hayalet değer yayılması önceki seansın daha yüksek değerini ezip düşük kayda yol açıyor | Orta–yüksek | `A-16`→`A-17` **G** |
| 5 | Boş (0×0) set ✓'lenip mola başlatıyor | Orta | `A-04` **G** |
| 6 | 1RM grafiği: set başına nokta, tekrar eden eksen etiketleri, tarihsiz x ekseni | Orta | `D-09` **G** |
| 7 | Türkçe büyük harf: "TERCIHLER", "KIMLIK & ENERJI" | Orta (kolay) | `B-10`, `C-03` **G** |
| 8 | Supabase İngilizce hata metni Türkçe arayüzde, Google düğmesinin altında | Orta | `01-onb-after-signup` **G** |
| 9 | "Antrenmanı başlat" önizleme açıyor | Orta | `A-02` **G**, `home_screen.dart:343` **K** |
| 10 | Home asıl eylem ve resume düğmesi alt menünün arkasında | Orta | `06-home-first`, `E-07` **G** |
| 11 | Süre boşta beklemeyi sayıyor → 100 dk, ~735 kcal | Orta | `A-12`, `D-02` **G** |
| 12 | Bildirim izni ilk set ✓'sinde, seans ortasında | Orta | `A-05` **G** |
| 13 | İlerleme ipucu "İlk kilonu gir" kilo girilmişken | Düşük | `D-03` **G** |
| 14 | Kurulum "Ayarlar'dan güncelle" diyor, hedefler Profil'de | Düşük | `05-onb-page4` **G** |
| 15 | Öneri +1.25 kg ↔ ± adımı 2.5 kg ↔ Ayarlar "Kilo artışı 1.25 kg" | Düşük | `A-16`, `B-10` **G** |
| 16 | Sayı biçimi tutarsız (1720 / 1.720 / 1.7k; 1604 / 1.747) | Düşük | `D-01`, `A-12`, `B-09`, `B-14` **G** |
| 17 | İngilizce hareket/kas/filtre adları | Düşük–orta | `A-02`, `D-07` **G** |
| 18 | Büyük yazı 1.3: "ÖNCE/Kİ" başlığı bölünüyor, alt menü "Antrenma" kesik | Düşük | `F-01`, `F-05` **G** |
| 19 | Durum çubuğu perdesiz, içerik altından geçiyor | Düşük | `C-home-scroll2` **G** |
| 20 | ✓ ve KG/TEKRAR alanlarında erişilebilirlik etiketi yok | Orta | uiautomator dökümü **G** |
| 21 | Süreç ölümünde mola bildirimi kayboluyor | Düşük (bilinmeyen: bitiş alarmı) | `E-06` **G** |

Çökme yok. Bugünkü logcat'te `E/flutter` veya `FATAL EXCEPTION` satırı yok; senkron günlükleri normal (`gönderilen 1, kalan 0`).

## Pakete etkisi

- **04_USER_JOURNEYS:** Dokunuş sayıları büyük ölçüde **güçlendi**. Düzeltme: her satıra ölçülen kaydırma sayısı eklenmeli (A/C/E +1, D +2). A'daki "1/set" ve "4 seçim" yalnız önceki değeri olan harekette geçerli; ilk seans 6 olarak eklenmeli. D'deki "gün → kayıt Aç" iddiası çalışan uygulamada (İlerleme takvimi) bulunamadı; hangi takvimden söz edildiği netleştirilmeli.
- **02_CURRENT_STATE_AUDIT U04:** Ölçüler cihazda **doğrulandı**. Mola kumandaları (31 dp yükseklik) ve RPE/KG alanları da listeye eklenmeli; ✓'nin erişilebilirlik etiketi eksik.
- **02 U01 / 04 E:** **Güçlendi ve ağırlaştı.** Rapor diyaloğun varlığını yazıyor; yıkıcı seçeneğin ana düğme olduğunu ve Bitir'in onaysız olduğunu yazmıyor. Önerilen düzeltme: "Çık" ikincil + "Taslağı koruyarak çık"; eksik setlerde Bitir onayı.
- **02 U03:** Doğrulandı; kurulum metnindeki "Ayarlar" ifadesi de aynı hatanın parçası.
- **02 U05:** Doğrulandı (İlerleme'de antrenman ilerlemesi yok); ayrıca grafik kalitesi sorunu eklenmeli.
- **U11 / Home önerileri:** "Bağlamlar yarışıyor" iddiası güçlendi; ek olarak asıl eylemin ilk ekranda menü arkasında kalması ve antrenman sonrası "bugün tamam" durumunun yokluğu eklenmeli.
- **Yeni, pakette olmayan:** hata 1, 4, 5, 6, 7, 8, 11, 12, 16, 17. Hata 1, 2, 3 ve 4 tasarım çalışmasından önce düzeltilmesi gereken somut kusurlar.
