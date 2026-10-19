# 12 — Son öneri (2. sürüm, derin incelemeden sonra)

18 Ekim 2026 · kaynak `07104d1` · üretim kodu değişmedi.

Yazım:
- 02–10: Codex.
- 01, 11, 12: Claude.
- 1. sürüm hızlı yazıldı ve yetersiz bulundu. Arşiv: [review/12_v1_hizli_surum.md](review/12_v1_hizli_surum.md).

Bu sürüm, yedi bağımsız incelemenin sentezine dayanır:
[review/00_SYNTHESIS.md](review/00_SYNTHESIS.md).

## Karar özeti

**Yön: B — Rafine Performans (değişmedi).** Lime/karbon kimliği, dört sekme ve
Beslenme'nin sıcak teması kalır. Değişen iki şey var:
- Ayrı "odak modu" yerine tablo içinde **büyütülmüş etkin set kartı**.
- İlk iş görsel yenileme değil, **güven kusurlarını** kapatmak.

**Faz 1 ikiye bölündü.** İkisinde de şema, senkron ve hesap kapısı değişmez.
- **1a — Deneme haftası güveni** (önce, ucuz): kullanıcıya söz verip tutmadığımız
  yerler.
- **1b — Set etkileşim güveni**: her sette dokunulan yüzeyin isabeti,
  kararlılığı ve erişilebilirliği.

**Tahmin (kabul ölçütü değil):** her dilim ayrı raporlanır: kod oturumu +
otomatik kontroller + cihaz turu + kullanıcı gözlemi. 1a'nın dar kısmı ~1 kod
oturumu. 7 ve 14 günlük pilotlar bu tahminin dışındadır (A6, Codex R6, H).

**İki iş ayrı karar notuna alındı** (Codex ikinci incelemesi, R2/R3): haftalık
hedefin veri anlamı (K7) ve "küçült / taslağı koruyarak çık" sözleşmesi (K8).
İkisi de "ucuz arayüz işi" değil.

## 1. Bu sürümde düzeltilenler (1. sürüme göre)

| 1. sürüm | Doğrusu | Kanıt |
|---|---|---|
| Yeni kullanıcıda halka "130 / 2400" | 0 / hedef; 1. gün ana sayfası boş ve kalabalık | A4 |
| K4: "± satırda kalsın mı, panele mi taşınsın" | ± zaten satırda değil, aktif setin altındaki yardım satırında. Dar ekrandaki asıl düğüm 56 pt'lik "Önceki" sütunu. Adım paneli en yavaş seçenek. | A5, A6, A7 (K + 20 render) |
| "Mola sayacı her saniye anons edilmesin" | Sayaç hiç anons etmiyor; başlangıç ve bitiş duyurusu eklenmeli | A6 (`SemanticsService`/`liveRegion` = 0) |
| P02 "okunur öneri + etiket" | Aktif sette etiket var; eksik olanlar alan ipucunun kontrastı (alfa 0,4 → koyuda ≥0,82, açıkta ≥0,96) ve ekran okuyucunun öneriyi girilmiş değerden ayırması | A1, A6 |
| Faz 1 = 6 madde | 6 madde set ekranının yarısını kapsıyordu. Mola kayması, mola düğmeleri, klavye, büyük yazı düzeni ve açık tema kontrastı eksikti. Deneme haftası kusurları hiç yoktu. | A1, A2, A4, A5, A6 |
| §3.4 "kart kaldırmak bilgi kaybı" | Verisi olmayan kart için geçersiz; ilk haftada gizlemek bilgi kaybı değil | A4 |
| Rakip emsali Hevy/Strong | Premium emsali MacroFactor (ücretsiz katman yok, 7 gün deneme, Türkçe yok) | A3 |
| "Altı iddianın altısı doğru" | 195 iddia kontrol edildi: 180 doğru, 13 kısmen, 1 yanlış | A1 |

## 2. Faz 1a — Deneme haftası güveni

| # | İş | Neden | Kanıt |
|---|---|---|---|
| a1 | Eksik set varken **Bitir onayı**, içinde "Tamamlananlarla bitir" seçeneği; tam seansta 1 dokunuş kalır | 20 setin 5'i yapılmışken tek dokunuşla kapandı | A2 G, K `active_session_screen.dart:902` |
| a2 | Çıkış penceresi: yalnız **görsel öncelik**. "Devam et" ana düğme, "Sil ve çık" ikincil ve kırmızı. "Taslağı koruyarak çık" bu dilimde YOK (bkz. K8). | Yıkıcı eylem şu an ana düğme | A2 G |
| a4 | **1. gün ana sayfası**: eylem en üstte ve alt menünün arkasında değil; veri yokken halka yerine tek satır; boş istatistik, grafik ve asistan ilk kayda kadar gizli | İlk izlenim boş ve kalabalık; asıl düğme menü arkasında | A2 G, A4 |
| a5 | Beslenme → Hedefler Profil'e gider; kurulumdaki "Ayarlar'dan güncelle" metni düzelir | U03 | A1, A2 |
| a6 | Hata durumları: beslenme özeti ve **taslak okuma hatası** "Tekrar dene" gösterir; sonsuz iskelet olmaz | U07, E3 | A1 K |
| a7 | **Cila**: Türkçe büyük harf (`context.upper()`), sayı biçimi (`numFmt`, virgül), İngilizce Supabase hata metni, ekran dışını gösteren Antrenman ipucu | Premium algısı; birkaç satırlık işler | A1, A2, A4 |
| a8 | Bildirim izni seans ortasında değil, seans başlamadan ya da ilk seans bitince sorulur | İlk sette seansı kesiyor | A2 G |
| a9 | E-posta doğrulama ekranı: adres, yeniden gönder, Google ile devam, spam uyarısı | En büyük terk adayı. SMTP ayrı iş, Samet'te. | A4 |

Haftalık hedef kusuru ("4/1", A4) gerçek, ama kaynağı karar ister. Sorular: kurulum
cevabı mı, program gün sayısı mı? Özel rutinde, program değişince ya da başka
cihazda ne olur? Ana sayfa ve haftalık değerlendirme aynı kaynağı okumalı
(`home_providers.dart:87–95`, `weekly_review_providers.dart:65–89`). → **K7**,
CONVENTIONS §7b gereği kısa karar notu + hesap testleri.

**Çıkış kapısı:** Berna sıfırdan hesap açar ve 7 gün kullanır. Kurulum → ilk
antrenman → ilk öğün akışı yardımsız tamamlanır.

## 3. Faz 1b — Set etkileşim güveni

| # | İş | Kanıt |
|---|---|---|
| b1 | **Etkin set kartı** (K4 yönü: Seçenek 1 + 1b; kesin düzen tam render'dan sonra):<br>• ± düğmeleri aktif setin yardım satırında, 48×48.<br>• ✓ 48×48.<br>• 360 pt'den dar ekranda "Önceki" sütunu yardım satırına iner. Böylece 320'de kg alanı 33 → 61 pt olur.<br>• Diğer setler tek satır.<br>• **Uyarı:** 61 pt ölçümünde set rozeti 30 ve RPE 38 genişlikteydi. İkisi 48'e çıkınca kg alanı ~50 pt'ye iner (Codex R4); ≥56 ölçütü sağlanmaz. Uygulamadan önce bütün kontrolleri 48 olan tam varyant 320 / 1,3×'te, açık ve koyu temada render edilir; gerekirse rozet/RPE ikinci satıra alınır. | A5, A6, A7 render, Codex R4 |
| b2 | 48'in altındaki diğer hedefler: mola −15s/+15s/Atla, RPE, set rozeti, dinlenme çipi | A1, A2, A7 |
| b3 | **Kaymayan mola göstergesi**: sabit yükseklikli alt çubuk | A5 G (68 pt kayma) |
| b4 | **Klavye**: ✓ her zaman kapatır, kaydırınca kapanır, iPhone'da "Sonraki / Bitti" çubuğu | A5 |
| b5 | **Büyük yazı düzeni**: sabit 30/56/44/42 sütunları esner; `_RpeHeader` taşması ve mola metninin harf harf kırılması giderilir | A6, A7 G |
| b6 | **Ekran okuyucu**: ✓, ± ve sayı alanlarına hareket, set, birim ve durum adı; öneri girilmiş değerden ayrı okunur; mola başlangıcı ve bitişi duyurulur | A2, A6 |
| b7 | **Kontrast**: alan ipucu ≥4,5:1; açık temada ÖNCEKİ ve mola düğmeleri ≥4,5:1; RPE "–" ≥4,5:1 | A1, A6 |
| b8 | Boş set ✓'lenemez; geçerlilik **ölçüm türüne göre** (tekrar, süre, mesafe, ek ağırlıksız hareket). Genel bir "0 kg yasak" kuralı yok. | A2 G, Codex |

**Kabul ölçütleri (ölçülebilir):**
- Aktif seans ve mola durumunda Flutter'ın dört erişilebilirlik kılavuz testi
  geçer. Kombinasyonlar: koyu ve açık tema; 393 genişlik; 320 genişlik / 1,6× yazı.
- 320 / 1,3×'te kg alanı ≥56 pt ve "62,5" kırpılmaz.
- ✓'e basınca bir sonraki ✓'in ekrandaki konumu değişmez.
- `neon_design_test` rota listesine aktif seans ve mola durumu eklenir;
  görüntüler `visuals/current/` altına yazılır.
- Seans kaydı, taslak, set kopyalama, RPE (Rating of Perceived Exertion,
  algılanan zorluk), süre/mesafe ve geri alma davranışı değişmez. Testler yeşil,
  `flutter analyze` 0.
- iPhone'da gözle kontrol: iki alanı yaz → ✓ → klavye kapanır. VoiceOver ile
  değer gir → tamamla → geri al.

**Çıkış kapısı:** Samet'in iki haftalık kullanımı, iki platformda.

## 4. Revize yol haritası

| Faz | Kapsam | Kod | Cihaz turu |
|---|---|---|---|
| **1a** | §2 | ~1 oturum | 1 akşam + Berna'nın 7 günü |
| **1b** | §3 | 1–2 oturum | 1–2 akşam |
| **2 — Günlük sürtünme** | • Besin kaydı düzenleme (DAO + senkron güncelleme yolu, küçük tasarım notu).<br>• "Dünkü gibi" öğün.<br>• İlk ekranda kalan protein.<br>• Barkod bulunamadı → kendi besinini oluştur.<br>• Seans süresinde boşta kalma.<br>• 1RM grafiği günlük en iyi değer olarak.<br>• İlk seans kilo rehberi ve "öneri 3. antrenmanda gelecek" beklentisi.<br>• Opaklık tokenları (32 farklı alfa → birkaç adlandırılmış değer). | 2–3 oturum | 1–2 akşam |
| **3A — Bugün** | Tam "Bugün" hiyerarşisi, ana sayfada beslenme "+ Ekle" | 1–2 oturum | Berna + Samet |
| **3B — Seans küçültme (P07b)** | Uygulama ömrü boyunca yaşayan seans denetleyicisi. Önce teknik not (iskelet: A6 §2.2'deki 10 madde + 14 senaryo). | not + 2–4 oturum | 2–3 akşam |
| **3C — İlerleme** | Antrenman / Vücut / Haftalık girişleri | 1–2 oturum | 1 akşam |
| **Doğrulama (her fazla birlikte)** | Android'deki mevcut bildirim eylemleri (± kilo, seti tamamla, mola ekle/atla; `WorkoutNotification.kt:129–145`) Samsung'da kilit ekranı, arka plan ve süreç ölümü koşullarında denenir; yalnız bulunan açıklar düzeltilir. | — | 1 akşam |
| **4 — Ürün fırsatları** | • Türkçe metinle yapay zekâ öğün kaydı: rakipte olduğu için zorunlu sayılmaz. Kullanıcı ihtiyacı, doğruluk ve maliyet ayrı değerlendirilir.<br>• Azaltılmış hareket (10/13 animasyon). | — | Monetizasyon kararına bağlı |

## 5. Rakip bağlamı (A3 özeti)

- **Emsal:** MacroFactor + MacroFactor Workouts. Ücretsiz katman yok, 7 gün
  deneme var, Türkçe yok. Fit Pack'in modeline en yakın örnek. Fiyatlar
  (18 Ekim 2026):
  - İki uygulama paketi: ABD'de $89,99/yıl ([resmî sayfa](https://macrofactor.com/workouts/price/)). Türkiye fiyatı **bilinmiyor**.
  - Tek uygulama: ABD'de $71,99/yıl. Türkiye App Store'unda ₺649,99 ve ₺749,99 görünüyor; hangisinin yeni hesaba sunulan teklif olduğu belli değil.
- **Türkiye fiyat zemini düşük.** Strong ₺84,99–164,99, Hevy ₺159,99,
  Diyetkolik ₺250–499,99/yıl. Kuvvet kaydedicilerin ücretsiz katmanı sınırsız
  kayıt veriyor. Premium konum ancak "bütünleşik + açıklanabilir + Türkçe"
  değerle savunulur (H). Bu bir monetizasyon kararı değildir; yalnız fiyat
  zeminidir.
- **Masa bahisleri:**
  - Kilit ekranından set kaydı: iOS'ta var (Live Activity); Android'de bildirim eylemleri olarak var (`WorkoutNotification.kt:129–145`). Android tarafı cihazda doğrulanmadı.<br>  (1. düzeltme: önceki sürüm "Android'de yok" diyordu; yanlıştı.)
  - Health Connect: var.
  - Saat uygulaması: yok; zorunlu değil.
- **Fark:** Türkçe arayüz ve Türk yemekleri. Kuvvet + beslenme alanında Türkçe
  bütünleşik ürün bulunamadı.

## 6. Samet'ten gereken kararlar

- **K1 — Yön:** B onaylanıyor mu? Odak modu yerine etkin set kartı.
- **K2 — Faz 1 yapısı:** 1a (§2, 8 iş) önce, 1b (§3, 8 iş) sonra, onaylanıyor mu?
- **K3 — Beslenme teması:** Sıcak Günlük kalsın mı? Önerim: kalsın.
- **K4 — Set satırı:** yön Seçenek 1 + 1b mi? Önerim: evet. Kesin düzen, bütün
  kontroller 48 olduğunda yeniden yapılacak render'dan sonra onaylanır.
  Bugünkü render'lar: `review/k4/`.
- **K5 — Test katılımcısı:** Berna dışında 2–3 gönüllü var mı?
- **K6 — Öneri kaynağı (yeni):** Bu seansta set 1'e daha düşük kilo yazıldığında
  set 3–4 neyi önersin?
  - (a) Bugünkü gibi üstteki seti.
  - (b) Geçen seansın aynı setini.
  - (c) Üstteki seti, ama yardım satırında "Geçen sefer 42,5" de yazsın.

  Önerim: (c). Düz setlerde bugünkü davranış korunur, piramitte düşük kayıt
  görünür hâle gelir.
- **K7 — Haftalık hedefin kaynağı (yeni):** Hedef nereden gelsin? Önerim, öncelik
  sırasıyla:
  1. Kullanıcının seçtiği hedef.
  2. Programın gün sayısı.
  3. Planlı günler.
  4. Varsayılan 3.

  Kurulum cevabı birinci kaynak olur. Nerede saklanacağı (yerel tercih mi, senkronlanan profil mi) karar notunda yazılır.
- **K8 — Seanstan çıkış sözleşmesi (yeni):** "Taslağı kaydet ve çık" mı (mola
  uyarısı ve kilit ekranı kartı durur, değerler kalır) yoksa "Antrenman sürerken
  küçült" mü (sayaç, mola alarmı ve kart çalışmaya devam eder)? Bugün ekran
  kapanınca sayaçlar, ses ve canlı kart kapanıyor
  (`active_session_screen.dart:483–498`). Önerim: önce "kaydet ve çık", kısa
  teknik not ve iki platformda kesinti testiyle. "Küçült" P07b'de.

## 7. İkinci inceleme (Codex) sonrası düzeltmeler

Codex 2. sürümü inceledi ([review/CODEX_SECOND_REVIEW.md](review/CODEX_SECOND_REVIEW.md)).
Claude beş maddeyi kodda ve ölçümlerde yeniden kontrol etti; beşi de doğru.

| # | Bulgu | Kontrol | Değişiklik |
|---|---|---|---|
| R1 | Android'de etkileşimli bildirim zaten var | `WorkoutNotification.kt:129–145` addRest/skipRest, stepDown/stepUp/completeSet | Yeni özellik kaldırıldı, cihaz doğrulaması eklendi. **Claude hatası:** A3'ün "grep ile bulunamadı (H)" notu kontrol edilmeden kesin yazılmıştı. |
| R2 | Koruyarak çıkış ucuz değil | `active_session_screen.dart:483–498` dispose: sayaç, ses, canlı kart kapanıyor | a2 yalnız görsel öncelik; K8 eklendi |
| R3 | Haftalık hedefin kaynağı belirsiz | Ana sayfa ve haftalık değerlendirme ayrı okuyor | a3 kaldırıldı; K7 eklendi |
| R4 | 61 pt tam 48'li düzeni doğrulamıyor | `k4/olcumler.json`: 1b'de rozet 30, RPE 38 | b1'e uyarı; K4 "yön" onayına indi |
| R5 | MacroFactor fiyatı karışık | A3 tablosu: paket TR fiyatı "Bilinmiyor" | §5 ayrı satırlar. **Claude hatası:** tek uygulama fiyatı pakete yazılmıştı. |
