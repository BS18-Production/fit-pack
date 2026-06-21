# Fit Pack — Claude Design Prompt / Tasarım Brief'i (V2)

> Bu dosya, **Claude Design** (Figma/UI üretimi) için hazırlanmış kopyala-yapıştır prompt'tur.
> Amaç: mevcut tüm fonksiyonları **doğru** aktarmak + Apple Fitness ferahlığında modern bir tasarıma evriltmek.
> Kapsam: tüm ekranlar · Dark + Light · Indigo/Teal paleti korunur.

---

## 📋 KOPYALANACAK PROMPT (buradan aşağısı)

Bir fitness takip uygulaması olan **Fit Pack** için baştan sona modern bir UI/UX tasarımı üret. Bu kişisel, tek kullanıcılı (offline) bir Android/iOS uygulaması. Aşağıda mevcut uygulamanın **tüm fonksiyonları** ve **ekranları** var. Önce bunları birebir koru, sonra çok daha pürüzsüz, modern ve kolay kullanılır hale getir.

### Tasarım Yönü (Vibe)
- **Referans his: Apple Fitness / Apple Health.** Ferah, bol beyaz/negatif alan, yumuşak köşeler, sakin tipografi hiyerarşisi, canlı ama az sayıda vurgu rengi. Veri yoğun değil; her ekran tek bir ana işe odaklanır.
- Büyük, okunabilir sayılar (kalori, kilo, hacim "hero metric" gibi öne çıkar).
- Yumuşatılmış kartlar (16–20px köşe), nazik gölge/yükseklik, ince ayraçlar.
- Mikro etkileşim hissi: dolum halkaları, ilerleme çubukları, yumuşak geçişler.
- **Hem Dark hem Light** tema tasarla (Dark öncelikli, ama ikisi de tam).

### Renk Paleti (KORUNACAK — Indigo/Teal "Pro")
Marka:
- Indigo (primary): `#6366F1` · parlak `#818CF8` · koyu `#4F46E5`
- Teal (secondary): `#14B8A6` · parlak `#2DD4BF`

Dark tema:
- Zemin (scaffold): `#101218` · Kart yüzeyi: `#1B1E27` · Yükseltilmiş yüzey: `#232734` · Input dolgu: `#262A38`
- Ayraç/outline: `#2F3442` · Ana metin: `#E7E9EE` · İkincil metin: `#9BA1B0`
- primary: `#6366F1` · primaryContainer: `#3730A3` / onPrimaryContainer: `#E0E1FF`

Light tema:
- Zemin: `#F6F7F9` · Kart: `#FFFFFF` · Yükseltilmiş: `#EEF0F4` · Ayraç: `#D8DCE4`
- Ana metin: `#1A1C22` · İkincil metin: `#5A6072` · primary: `#4F46E5`

Anlamsal (semantic) renkler:
- Başarı: `#22C55E` · Uyarı: `#F59E0B` · Hata: `#EF4444` · Bilgi: `#38BDF8`
- **Makro renkleri (önemli, tutarlı kullan):** Kalori = Indigo `#6366F1` · Protein = Teal `#14B8A6` · Karbonhidrat = `#38BDF8` (açık mavi) · Yağ = `#FBBF24` (amber)

### Tipografi & Düzen İlkeleri
- 8pt tabanlı boşluk ritmi (4/8/12/16/20/24/32). Çıplak rastgele değer kullanma.
- Köşe yarıçapı: küçük 8, orta 12, büyük 16, xl 20, pill 999.
- Minimum dokunma hedefi 48dp.
- Dil: **Türkçe** (tüm metinler Türkçe).
- Tipografi: temiz, modern sans-serif; net başlık/gövde/etiket hiyerarşisi. Hero sayılar büyük ve kalın.

### Navigasyon Yapısı
- Alt navigasyon, 4 sekme: **Ana Sayfa · Antrenman · Beslenme · İlerleme**
- Ana sayfa üst sağ köşede: Dışa Aktar ikonu + Ayarlar ikonu.
- İkinci seviye ekranlar (push): Antrenman Önizleme, Antrenman Seansı, Antrenman Geçmişi, Yemekler (besin DB), Dışa Aktar, Ayarlar, Onboarding.

---

### EKRAN EKRAN — Mevcut Fonksiyonlar (hepsini koru) + İyileştirme Niyeti

**1) Onboarding (İlk Açılış) — 3 adım**
- Adım 1: Hoş geldin ekranı (ikon + başlık + kısa açıklama).
- Adım 2: "Seni tanıyalım" — Mevcut kilo (zorunlu, kg), Boy (opsiyonel, cm), Hedef kilo (opsiyonel, kg) + **Hedef seçimi** (3 kart radyo): Kilo Ver / Koru / Kütle Al (her birinde kısa açıklama).
- Adım 3: "Günlük hedeflerin" — Kalori (kcal) ve Protein (g) alanları, seçilen hedefe göre otomatik ön-dolu, düzenlenebilir.
- Üstte adım ilerleme çubuğu (dot'lar). Altta Geri / İleri / Tamamla.
- *İyileştir:* daha davetkâr, görsel, "1 dakikada bitir" hissi; segmentli hedef seçici daha şık olabilir.

**2) Ana Sayfa**
- Tarih başlığı ("Pazar, 21 Haziran").
- **Faz/Hafta kartı**: aktif program adı + faz + hafta (ör. "İleri Upper/Lower (Faz 3) · Hafta 1").
- **Büyük "Antrenmanı Başlat" CTA kartı** (gradient, ok ikonu) → antrenmana götürür.
- **Bugünkü Beslenme kartı**: ortada dairesel "kcal kaldı" halkası + Protein / Karbonhidrat / Yağ ilerleme satırları (X / hedef g, makro renkleriyle).
- İki küçük kart yan yana: **Seri (streak)** ("Seri yok / Bugün başlat" veya "🔥 N gün") + **Son Kilo** ("55.0 kg / Son Kilo").
- Boş haller aksiyona davet eder (seri yoksa "Bugün başlat", kilo yoksa "İlk kilonu gir"); kartlar tıklanır. 7+ gün ara olunca yumuşak motivasyon mesajı.
- *İyileştir:* Apple Health tarzı "bugün özeti" hissi; halkalar daha canlı; kartlar daha hafif ve dokunulası.

**3) Antrenman — Liste**
- Üstte faz adı + "Hafta N".
- Her antrenman bir kart: ikon rozeti + ad + gün (ör. "Pazartesi") + "N hareket" + ilk 4 hareketin chip'leri. Karta dokun → Önizleme.
- Altta "Antrenman Geçmişi" butonu.
- Antrenman tipleri: Full Body, Upper/Lower, Cardio gibi (plan JSON'dan gelir; ikonlar tipe göre değişir).

**4) Antrenman — Önizleme** (karta dokununca)
- Seçilen antrenmanın hareket listesi + her hareket için **geçen seansın değerleri** ("Geçen seans: 60×8 · …"). Altta büyük **"Başla"** butonu.

**5) Antrenman — Seans (canlı)**
- Hareket hareket ilerleme. Her hareket kartında setler: **kg × tekrar** girişleri.
- **Ghost değerler**: geçen seansın kg/tekrarı alan ipucu olarak ("placeholder") gösterilir.
- **Set ekle / Set çıkar** butonları.
- Geri tuşunda **çıkış onayı** (set girilmişken "Antrenmandan çık?").
- Seansı bitir → kaydet.
- *İyileştir:* set girişini çok hızlı yap (büyük dokunma alanları, +/- adımlayıcılar), tamamlanan set'e onay hissi (check), dinlenme arası için yer ayır.

**6) Antrenman — Geçmiş**
- Geçmiş seanslar listesi (açılır-kapanır / ExpansionTile): her seansın set dökümü + **toplam hacim** (kg×tekrar toplamı).

**7) Beslenme — Günlük**
- Üstte günün toplamı: **kalori + P/K/Y** (protein/karbonhidrat/yağ) makro renkleriyle, hedefe göre ilerleme.
- Öğün bölümleri (kahvaltı/öğle/akşam/atıştırma) — her öğüne eklenen yemekler listelenir.
- **Yemek Ekle** akışı (bottom sheet): arama + **son kullanılanlar chip şeridi** + **adet/gram birim seçici** (ör. "1 dilim = 30g") + **barkod tarama** butonu + özel yemek ekleme.
- Gün boşken **"Dünün öğünlerini kopyala"** kısayolu.
- *İyileştir:* yemek eklemeyi sürtünmesiz yap; makroları görsel halka/bar ile özetle; öğün kartları sade.

**8) Beslenme — Yemekler (Besin Veritabanı)** (Ayarlar veya Beslenme'den)
- Yemek listesi: ara, değerleri gör (/100g kalori-protein-karb-yağ), özel yemeği düzenle/sil, barkodla ekle.

**9) İlerleme (Body Metrics)**
- **Kilo trend grafiği** (çizgi): geçmiş kilolar + **hedef kilo kesikli çizgisi** + dokunma tooltip'i.
- Özet kartı: en güncel vs en eski (değişim).
- Geçmiş ölçümler listesi. Ölçüm alanları: kilo, bel, göğüs, kol, kalça, boyun, vücut yağ %.
- Sağ altta **"Ölçüm Ekle"** FAB → dialog.
- (İleride: ilerleme fotoğrafları — ön/yan/arka.)
- *İyileştir:* Apple Health tarzı büyük, temiz grafik; segment seçici (kilo / bel / yağ%) ; trend oklarıyla "düşüyor/çıkıyor" hissi.

**10) Ayarlar**
- Bölümler: **Hedefler** (Kalori hedefi, Protein hedefi) · **Program** (Faz 1-3, Hafta, Son Deload sıfırla) · **Vücut** (Boy, Hedef Kilo) · **Beslenme** (Yemekler'e git) · **Hakkında** (sürüm) · **Veri Dışa Aktar**.
- Her satır: yuvarlak ikon rozeti + başlık + sağda değer veya ok. Düzenleme dialog ile (aralık doğrulamalı).

**11) Dışa Aktar**
- Tüm veriyi JSON olarak dışa aktarma ekranı.

---

### Çıktı Beklentisi
- Yukarıdaki **11 ekranın hepsini** tasarla; her birinin **Dark + Light** varyantı.
- Bir mini **tasarım sistemi** ver: renk token'ları, tipografi ölçeği, boşluk, buton/kart/input/chip/ilerleme-halkası/alt-nav bileşenleri.
- **Boş, yükleniyor ve hata** durumlarını da göster (özellikle Ana Sayfa, Beslenme, İlerleme, Antrenman listesi).
- Tutarlılık şart: makro renkleri her yerde aynı, dokunma hedefleri ≥48dp, 8pt ritim.
- Tarz: Apple Fitness ferahlığı + Indigo/Teal kimliği. Genel "AI şablonu" görünümünden kaçın; karakterli, premium ve sakin olsun.

## 📋 PROMPT BİTTİ

---

## 🔁 TAM UYGULAMA — İNTERAKTİF PROTOTİP PROMPT'U

> Tüm uygulamayı "çalışıyormuş gibi" interaktif çıkarmak için. Tek seferde zorlanırsa 2 partide: önce 4 ana sekme + navigasyon, sonra ikincil ekranlar.

```
Build a fully interactive, multi-screen prototype of "Fit Pack", a personal fitness tracking mobile app, so it behaves like the real running app. Cover ALL screens and make navigation + key interactions actually work (stateful). Produce both Dark and Light themes.

STYLE (consistent with the established design):
- Apple Fitness / Health calmness: generous space, large tabular hero numbers, soft-rounded cards (16–20px), hairline-border depth (no heavy shadows), restrained accents.
- Font: Inter; tabular figures for all metric numbers.
- Palette: Primary Indigo #6366F1 (dark) / #4F46E5 (light); Secondary Teal #14B8A6; Dark bg #101218, card #1B1E27, text #E7E9EE / #9BA1B0; Light bg #F6F7F9, card #FFFFFF, text #1A1C22 / #5A6072. Macro colors: Calories #6366F1, Protein #14B8A6, Carbs #38BDF8, Fat #FBBF24. Water accent #38BDF8.
- All in-app text in Turkish. Start on the Home screen as a returning user. Bottom nav, 4 tabs: Ana Sayfa · Antrenman · Beslenme · İlerleme.

SCREENS & INTERACTIONS:

[Ana Sayfa / Home]
- Date header below the safe area ("Pazar, 21 Haziran"); top-right export + settings icons (open those screens).
- Phase/week row "İleri Upper/Lower · Faz 3 · Hafta 1" → tap opens Antrenman.
- Primary action card, STATE-AWARE: training day → indigo gradient "Antrenmanı Başlat · Upper A · 6 hareket · ~52 dk" → opens Workout Session; rest-day variant → flat (no gradient) "Bugün dinlenme · Yarın: Lower B".
- HERO: "Bugünkü Beslenme" card — calorie ring "1.850 kcal kaldı" + macro bars Protein 142/180, Karbonhidrat 130/360, Yağ 40/90. "Düzenle" → opens Beslenme.
- Water card: "1.4 / 2.5 L" + chips "+250 ml" and "+1 bardak" that actually increment the value and progress (cap at goal).
- Bottom stats: Seri "🔥 5 gün", Son Kilo "84.7 kg ↓0.4" → tap opens İlerleme.

[Antrenman / Workout list]
- Phase name + "Hafta 1". Workout cards: icon, name, day, "N hareket", first exercise chips → tap opens Workout Preview. "Antrenman Geçmişi" button → History.

[Antrenman Önizleme / Workout Preview]
- Exercise list with last-session values ("Geçen seans: 60×8"). "Başla" → Workout Session.

[Antrenman Seansı / Workout Session]
- Per-exercise set rows with kg × reps inputs, ghost placeholders from last session, +Set / −Set, tap a set to mark it done (check). "Antrenmanı Bitir" saves & returns. Back → "Antrenmandan çık?" confirm dialog.

[Antrenman Geçmişi / Workout History]
- Expandable past-session list → set breakdown + total volume.

[Beslenme / Nutrition]
- Day totals (kcal + colored P/K/Y). Meal sections: Kahvaltı, Öğle, Akşam, Atıştırma with logged foods. "+ Yemek Ekle" → bottom sheet. Empty day shows "Dünün öğünlerini kopyala".
- Add-food sheet: search field, recent-foods chips, gram/portion unit selector ("1 dilim = 30g"), barcode scan button, custom food option. Selecting a food adds it to the meal and updates day totals AND the Home ring.

[Yemekler / Foods] (from Beslenme or Ayarlar)
- Searchable food list, /100g macro values, edit/delete custom foods, barcode add.

[İlerleme / Progress]
- Weight line chart with dashed goal-weight line and tappable tooltips. Summary card (latest vs oldest change). Measurement history list. "Ölçüm Ekle" FAB → dialog (kilo, bel, göğüs, kol, kalça, boyun, yağ%) → adds a point to the chart and updates Home's weight.

[Ayarlar / Settings] (from Home gear icon)
- Sections: HEDEFLER (Kalori, Protein), PROGRAM (Faz 1-3, Hafta, Son Deload), VÜCUT (Boy, Hedef Kilo), BESLENME (Yemekler →), HAKKINDA (sürüm), Veri Dışa Aktar →. Tapping a row opens an edit dialog that updates the value.

[Veri Dışa Aktar / Export]
- Simple screen: export all data to JSON (mock confirm).

[Onboarding] (first-launch flow, reachable separately)
- 3 steps with progress dots: 1) welcome, 2) "Seni tanıyalım" (mevcut kilo, boy, hedef kilo + hedef seçimi: Kilo Ver / Koru / Kütle Al), 3) "Günlük hedeflerin" (kalori, protein pre-filled). "Tamamla" → Home.

STATEFUL BEHAVIORS (make it feel alive during the session):
- Bottom nav switches tabs and preserves each tab's state.
- Water chips accumulate and fill the indicator (cap at goal).
- Adding a food updates nutrition totals and the Home calorie ring/macros.
- Finishing a workout adds it to History.
- Adding a measurement updates the chart and Home's "Son Kilo".
- Changing a goal in Settings updates the relevant target (e.g., the kcal ring goal).
- Smooth transitions; back navigation returns correctly.

PROTOTYPE REQUIREMENTS:
- Seed realistic Turkish data (real meal names: Yulaf, Tavuk Göğsü, Yumurta; believable numbers).
- Premium, calm, characterful — avoid the generic AI-template look.
- Deliver as a clickable prototype I can open in Preview and actually use.
```

## 📋 İNTERAKTİF PROMPT BİTTİ
