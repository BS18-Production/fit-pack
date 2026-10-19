# 00 — Derin inceleme sentezi

18 Ekim 2026 · kaynak `07104d1` · üretim kodu değişmedi, commit yok.
Yedi bağımsız inceleme (A1–A7) ve Claude'un kendi kod kontrolü. Kurallar:
[BRIEF.md](BRIEF.md). Kanıt sınıfları: **K** kod, **G** gözlem (emülatör ya da
render), **Q** resmî kaynak, **S** standart, **H** hipotez.

## Karar özeti

1. **Paketin kod iddiaları sağlam.** 195 iddianın 180'i doğru, 13'ü kısmen doğru,
   1'i yanlış, 1'i doğrulanamadı. 382 `dosya:satır` atfının hepsi var olan
   satırlara işaret ediyor (A1).
2. **Paketin en büyük kör noktası aktif seans ekranı.** 76 render'ın hiçbiri
   `/workout/active` değil (A1, A6). Bu ekran ilk kez emülatörde ve render'da
   incelendi. Dört Flutter erişilebilirlik kılavuzunun dördünden de kalıyor (A6)
   ve 320 genişlik + büyük yazıda kullanılamıyor (A6, A7).
3. **Tasarımdan önce düzeltilmesi gereken güven kusurları var** ve hiçbiri pakette
   yok:
   - "Bitir" eksik setlerde de onaysız.
   - Çıkış penceresinde yıkıcı "Çık" ana düğme.
   - Kurulumda sorulan gün sayısı unutuluyor (hedef 1, render'da "4/1").
   - Antrenman sekmesindeki ipucu ekran dışını gösteriyor.
   - "KIMLIK", "TERCIHLER" yanlış büyük harfle yazılıyor.

   (A2, A4; Claude kodda doğruladı.)
4. **Set kaydı hızlı, sorun isabet ve kararlılıkta.**
   - Set başına 1 dokunuş tutuyor; bu Hevy ile aynı (A5).
   - Mola şeridi listeyi her sette 68 pt aşağı itiyor (A5, G).
   - ✓ klavyeyi her zaman kapatmıyor; iPhone sayı klavyesinde "Bitti" tuşu yok (A5).
5. **Benim ilk 12'mde dört yanlış vardı:**
   - Yeni kullanıcı örneği "130/2400" yanlıştı; doğrusu 0/hedef.
   - K4 sorusu yanlış kurulmuştu. ± düğmeleri satırda değil; asıl sorun "Önceki" sütunu.
   - "Mola sayacı her saniye anons eder" riski yanlıştı; sayaç hiç anons etmiyor.
   - P02 için "etiket yok" dedim; aktif sette etiket zaten var.

   Faz 1 de ikiye bölünmeli: **1a deneme haftası güveni**, **1b set etkileşim
   güveni**.
6. **Rakip tablosu değişti.** En yakın emsal artık MacroFactor (beslenme +
   Workouts paketi, ücretsiz katman yok, 7 gün deneme, Türkçe yok). Kilit ekranından
   set kaydı masa bahsi oldu. Fit Pack'te iOS'ta da Android'de de var (A3
   Android'i bulamamıştı; Codex R1 düzeltti, `WorkoutNotification.kt:129–145`).
7. **Yön B değişmedi**, ama "odak modu" yerine **büyütülmüş etkin set kartı**
   önerilir. Tablo düzeni kalır (A5, A7).

## Yöntem ve sınırlar

| Ajan | Ne yaptı | Çıktı |
|---|---|---|
| A1 Doğrulama | 195 iddia, 382 atıf, kontrast yeniden hesaplandı | [A1](A1_verification.md) |
| A2 Çalışan uygulama | Emülatörde A–E yolculukları + kurulum, Dev Supabase, 97 ekran görüntüsü | [A2](A2_runtime_walkthrough.md), `runtime/` |
| A3 Rakipler | 19 ürün, Türkiye App Store fiyatları, 2025–26 sürüm notları | [A3](A3_competitive_independent.md) |
| A4 Yeni kullanıcı + premium | İlk 7 gün kod ve render üzerinden | [A4](A4_review_newuser_premium.md) |
| A5 Salon + beslenme | Kontrol haritası, dokunuş sayısı, mola kayması ölçümü | [A5](A5_review_gym_nutrition.md), `A5_assets/` |
| A6 Erişilebilirlik + mühendislik | Aktif seans render, Flutter kılavuz testleri, P07 mimarisi | [A6](A6_review_a11y_engineering.md), `A6_visuals/` |
| A7 K4 set satırı | 3 seçenek × 3 düzen, 20 render, ölçümler | [A7](A7_k4_set_row.md), `k4/` |

**Yapılamayanlar:**
- Gerçek telefonda deneme yapılmadı (kural gereği).
- iPhone klavyesi ve VoiceOver/TalkBack uçtan uca denenmedi.
- Rakip uygulamalara girilmedi.
- Gerçek kullanıcı yok.

Bütün etki tahminleri **H**'dir.

## Ajanlar arası çelişkiler ve karar

| Konu | Görüşler | Karar |
|---|---|---|
| "Bitir" onayı | A2: eksik setlerde onay şart (20 setin 5'i varken tek dokunuşla kapandı). A5: onay ekleme, özette "2 set tamamlanmadı" yazsın. | **Yalnız tamamlanmamış set varken onay.** Tam seansta 1 dokunuş kalır. Özet ekranı kayıttan sonra geldiği için yalnız uyarı göstermek geri dönüş sağlamaz. |
| İlk dilimin içeriği | A4: deneme müşterisi için 48×48'den önce kurulum hedefi, 1. gün ana sayfası, e-posta ekranı gelir. A5/A6: set etkileşimi her gün, her sette yaşanıyor. | **İkisi de; iki alt dilim.** 1a ucuz ve hızlı, önce. 1b ardından gelir. |
| Öneri yayılması (A2 hata #4) | A2: set 1 düşük kiloyla girilince set 3–4'ün önerisi geçen seansın 42,5'inden 40'a düştü, "veri riski". | **Bilinçli tasarım, ama karar gerektirir.** `set_prefill.dart:77–96`: aynı seansta üstteki dolu set, geçen seansın aynı setinden önce gelir. Düz setlerde doğru, piramit setlerde düşük kayda yol açar. → **K6** |
| K4 seçeneği | A5: adım paneli en yavaş. A6: sorun sütun düzeni. A7: render'la ölçüldü. | **Seçenek 1 + 1b.** ± aktif setin yardım satırında 48×48. 360 pt'den dar ekranda "Önceki" sütunu satırdan çıkar. |
| Beslenmenin sıcak teması | 05: yaklaştır. 07: kalsın. | **Kalsın** (docs/34, Samet onayı). İnceleme bunu değiştiren bir kanıt bulmadı. |

## Claude'un ek kod kontrolleri

| İddia | Kanıt | Sonuç |
|---|---|---|
| Kurulum gün sayısı kaydedilmiyor | `onboarding_screen.dart:60–63` "Kalıcı değil"; `home_providers.dart:87–95` hedef = `scheduledWeekday` atanmış rutin sayısı, yoksa 1 | **Doğru** |
| Bitir onaysız | `active_session_screen.dart:902–910`: yalnız "hiç veri yok" kontrolü var | **Doğru** |
| Öneri yayılması | `set_prefill.dart:77–96` | **Doğru, ama kasıtlı** (yukarıda) |

## Diğer raporlara düzeltmeler

Codex raporları (02–10) yerinde değiştirilmedi. Her birinin başına bu belgeye
bağlantı eklendi.

| Rapor | Düzeltme | Kaynak |
|---|---|---|
| 02 giriş | "Render'lar seans akışını kapsar" yanlış. Aktif seans görüntüsü yok; U01, U04 ve Q01–Q03 yalnız koda dayanıyor (artık A6/A7 render'ı ve A2 emülatör gözlemi de var). | A1 |
| 02 U01 | Yıkıcı "Çık" ana düğme; Bitir onaysız; ağırlaştı. | A2 |
| 02 U04 | Mola −15s/+15s/Atla 49×31, RPE 38×36, set rozeti 30×32, dinlenme çipi 59×21, ? düğmesi 40×40 da 48'in altında. | A1, A2, A7 |
| 02 mola şeridi | S2'den S3'e (68 pt kayma). | A5 |
| 02 kontrast | Açık temada ÖNCEKİ 4,278:1; açık temada mola düğmeleri 3,38–4,16:1; kilo grafiği ipucu 3,059:1; RPE "–" 1,48–1,88:1. | A1, A6 |
| 02 hata durumları | 10 sessiz hata yolu; en önemlisi `activeDraftProvider` hatasında "Devam et" kartı kayboluyor. | A1 |
| 03 | MacroFactor Workouts, Bevel, kilit ekranı, saat, Health Connect, Türkiye fiyatları ve Türkçe boşluğu eksik. Fotoğrafla kalori kararı yeniden yazılmalı: "önce metin/ses, sonra fotoğraf, tahmin düzenlenebilir". | A3 |
| 04 | Her yolculuk en az 1 kaydırma istiyor (A/C/E +1, D +2). İlk kez yapılan harekette set = 3 dokunuş + yazma. "Bilinmiyor" satırları ölçüldü: değer değiştir 2 + tuş, kopyala 5. | A2, A5 |
| 05 | Kavramların hiçbirinde 1. gün boş durumu yok. Sadelik puanları boş durum çizilmeden verilmiş. | A4 |
| 08 P02 | Aktif sette "✓ ile 70 kg × 10 kaydedilir" zaten var. Eksik olanlar: alan ipucunun %40 alfası ve ekran okuyucunun öneriyi girilmiş değerden ayıramaması. | A1, A6 |
| 08 P07 | P07a ("taslağı koruyarak çık", ucuz) ve P07b (uygulama ömrü boyunca yaşayan seans denetleyicisi) olarak bölünmeli. | A6 |
| 08 P11 | "Her saniye anons" değil; **hiç anons yok** (`lib/` içinde `SemanticsService` ve `liveRegion` sıfır). | A6 |
| 08 yeni | Besin kaydı düzenleme, "Dünkü gibi" öğün, Türkçe metinle yapay zekâ öğün kaydı. (Android etkileşimli bildirimi zaten var, yalnız cihazda doğrulanacak.) | A3, A5, Codex R1 |
| 09 Faz 1 | "Sayı girişleri küçültülmez" kuralı bugün de ihlal ediliyor (320 / 1,3×'te kg 38 pt, "60" kırpılıyor). Ölçülebilir alt sınır gerekli. | A7 |
| 09 tahmin | İş günü değil; kod 1–2 oturum + cihaz turu. Takvimde 4–7 gün. | A6 |
| 10 §1 | 320 / büyük yazı kapsamı aktif seansı içermiyor; `neon_design_test` rota listesine aktif seans ve mola durumu eklenmeli. | A6 |

## Yeni bulgular (paketin hiç anmadığı)

**Güven ve doğruluk**
1. Bitir onaysız (A2 G, K).
2. Çıkışta yıkıcı eylem ana düğme (A2 G).
3. Kurulum gün sayısı kayboluyor, hedef 1 (A4 K).
4. Taslak okunamazsa "Devam et" kartı sessizce kayboluyor (A1 K).
5. Boş 0×0 set ✓'lenip mola başlatıyor (A2 G).
6. Seans süresi boşta geçen zamanı sayıyor: 100 dk, ~735 kcal (A2 G).
7. 1RM (bir tekrar maksimum) grafiği aynı günün setlerini gelişim diye çiziyor (A2 G).
8. "İlk kilonu gir" ipucu kilo girildikten sonra da çıkıyor (A2 G).

**Seans ekranı**
9. Mola şeridi 68 pt kayma (A5 G).
10. Klavye tutarsızlığı; iOS'ta "Bitti" tuşu yok (A5 K+G).
11. 320 / 1,3–1,6×'te tablo bozuk; `_RpeHeader` 5,9 pt taşıyor (A6, A7 G).
12. ✓ ve sayı alanlarının erişilebilir adı yok (A2, A6 G).
13. 10 animasyonun 13'ünden 10'u azaltılmış hareket tercihini yok sayıyor (A6 K).
14. Bildirim izni ilk sette, seansın ortasında soruluyor (A2 G).
15. Süreç ölümünden sonra mola bildirimi kayboluyor; açılış Home'a düşüyor (A2 G).

**İlk izlenim ve cila**
16. Antrenman sekmesi ipucu ekran dışını hedefliyor (A2 G).
17. Türkçe büyük harf hatası (`setting_tiles.dart:119`) (A2, A4).
18. "2270" / "2.270", "84.5" / "84,5" tutarsızlığı (A1, A4).
19. Supabase hata metni İngilizce (A2 G).
20. Hareket adları İngilizce (A2 G; Karar 1+2 ertelendi, docs/48).
21. Asıl eylem düğmesi alt menünün arkasında kalıyor (A2 G).
22. E-posta doğrulaması uygulamadan çıkarıyor; 429 kota riski (A4).

**Değer zamanlaması**
23. İlk ilerleme önerisi en erken 3. antrenmanda, yani 7 günlük denemenin 5.–6.
    gününde (A4 K).

**Beslenme**
24. Girilmiş kayıt düzenlenemiyor; sil + ekle 4–5 dokunuş (A5 K).
25. Dünkü öğünü tekrar girmek 5 dokunuş (A5 K).
26. Kalan protein ilk ekranda görünmüyor (A5 G).
27. Barkod bulunamadığında ölü uç (A5 K).

## Ek — Codex ikinci incelemesi (18 Ekim 2026)

[CODEX_SECOND_REVIEW.md](CODEX_SECOND_REVIEW.md) beş düzeltme önerdi. Claude
hepsini kodda doğruladı ve 12'ye işledi (12 §7):
- **R1:** Android bildirim eylemleri mevcut.
- **R2:** Çıkış sözleşmesi (K8).
- **R3:** Haftalık hedef kaynağı (K7).
- **R4:** Tam 48'li düzen render'ı gerekli.
- **R5:** MacroFactor fiyatı ayrıldı.

A3'ün "Android'de bulunamadı" satırı yanlış; A3 dosyası ajan çıktısı olarak
olduğu gibi bırakıldı.
