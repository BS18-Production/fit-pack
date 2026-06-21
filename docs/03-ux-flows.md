# Fit Pack — UX Akışları ve Wireframe Dokümanı

> **Doküman versiyonu:** 1.0 (taslak)
> **Tarih:** 2026-05-13
> **Sahibi:** Samet Orhan
> **Durum:** Onay bekliyor
> **Bağlı doküman:** [01-product-spec.md](01-product-spec.md), [02-architecture.md](02-architecture.md)

Bu doküman, **Fit Pack'in her ana kullanıcı yolculuğunu (user journey), ekran akışlarını ve ASCII wireframe'lerini** tanımlar. Görsel tasarım (renk, font detayı) bu dokümanın kapsamı değildir; **bilgi mimarisi (information architecture) ve etkileşim akışları (interaction flows)** burada karar verilir.

---

## 1. UX Prensipleri

1. **Hız > Güzellik:** Yemek/antrenman log'u 3 tap içinde tamamlanmalı.
2. **Veri girişi yorucu olmamalı:** Akıllı varsayılanlar (geçen haftaki ağırlık, son yenen yemek vb.) öne çıksın.
3. **Geri bildirim anında:** Set kaydedilince haptic + ekranda anlık güncelleme. Loading spinner yerine optimistic update.
4. **Yanlışlık kurtarılabilir:** Undo + Dismissible delete pattern (mevcut V1'de zaten var).
5. **Bilgi tek bakışta:** Home ekranı bugünün durumunu tek scroll'da göstersin.
6. **Bildirim spam yok:** Akıllı, bağlamsal hatırlatma — gün boyu pop-up değil.
7. **Karanlık mod öncelikli:** Spor salonu/akşam kullanımı için göz dostu.

---

## 2. Navigasyon Yapısı (Information Architecture)

### 2.1 Ana Bottom Nav (5 Sekme)

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│              [Ana Ekran / Sayfa]                    │
│                                                     │
│                                                     │
├─────────────────────────────────────────────────────┤
│  🏠      💪       🍽️       📊       👤            │
│  Home  Antrenman  Beslenme Gelişim  Profil        │
└─────────────────────────────────────────────────────┘
```

| Sekme | İçerik |
|-------|--------|
| 🏠 **Home** | Bugün durumu (streak, antrenman, nutrition, AI flash insight) |
| 💪 **Antrenman** | Workout listesi → Session → Geçmiş |
| 🍽️ **Beslenme** | Yemek log + su + takviye + günlük kalori/protein |
| 📊 **Gelişim** | Grafikler + foto karşılaştırma + ölçü + AI haftalık özet |
| 👤 **Profil** | Settings, export, AI ayar, hedefler, achievement |

### 2.2 İkinci Seviye Ekranlar

```
Home
├─ Hızlı log shortcuts (yemek, su, takviye)
└─ AI flash insight kartı → tıklanırsa Gelişim/AI sohbet ekranı

Antrenman
├─ Workout listesi (faza göre)
│   └─ Workout session (set/rep/kg/rir log) → Rest timer
├─ Workout history (geçmiş tüm sessionlar)
└─ Auto-progression suggestion modal

Beslenme
├─ Bugünün öğünleri (kahvaltı / öğle / akşam / atıştırma)
│   └─ Yemek arama → Gram input → Kaydet
├─ Su counter (+200ml hızlı butonlar)
├─ Takviye checklist
└─ Günlük log (stres/uyku/mood/ağrılar) — tek ekran tek scroll

Gelişim
├─ Grafikler (kilo / hacim / protein / ağrı trend)
├─ Vücut ölçüm girişi
├─ Fotoğraf
│   ├─ Çekme akışı (ön/yan/arka)
│   └─ Karşılaştırma akışı (önce/sonra)
└─ AI haftalık özet (Pazar açılışında otomatik)

Profil
├─ Settings (hedefler, faz/hafta, deload, height, goal weight)
├─ AI ayarları (provider, API key)
├─ Bildirim ayarları
├─ Export (md/json/csv × hafta/ay/all × all/workout/nutrition)
├─ Achievement listesi
└─ Hakkında / Versiyon
```

### 2.3 Modal & Bottom Sheet'ler

| Modal | Tetikleyici |
|-------|-------------|
| Quick add water (200ml/500ml) | Home/Beslenme → su counter long press |
| Set kaydet | Workout session içinde her hareket için |
| Yemek arama | Beslenme → "+ Öğün ekle" |
| Foto çek/yükle | Gelişim → Fotoğraf → "+" |
| AI sohbet (V2 Aşama 3) | Home AI kartı tap |

---

## 3. Onboarding Akışı (V2 İlk Açılış)

V1'de mevcut user (Samet) için sade — sadece ilk açılışta birkaç ekran.

```
[Splash 1sn]
     │
     ▼
[Welcome ekranı]
"Merhaba! Fit Pack ile gelişimini tek yerde topla."
[İleri →]
     │
     ▼
[Hedef ayarı]
- Boy: 180 cm (pre-fill)
- Mevcut kilo: 84.7 kg
- Hedef kilo: 75 kg
- Faz: Cut / Bulk / Maintenance (radio)
[İleri →]
     │
     ▼
[Hedefler]
- Günlük kalori hedefi: [1800] kcal
- Günlük protein hedefi: [180] gr
(Default Mifflin-St Jeor + 0.8x cut/0.7x aggressive cut)
[İleri →]
     │
     ▼
[AI ayarı]
"Yapay zekâ asistanı kullanmak ister misin?"
- Sağlayıcı: Gemini ✓
- API key gir: [____________]
- Daha sonra ekle [skip]
[Tamamla →]
     │
     ▼
[Bildirim izni] (sistem dialog)
- Reddedilirse → sessizce devam
     │
     ▼
[Home ekranı]
```

**Karar:** Onboarding **kısa, atlanabilir.** Samet pilot için zaten verisi var, onun için "import V1 data" seçeneği konacak (Aşama 0'da).

---

## 4. Akış: Antrenman Log (US-01..US-04)

### 4.1 Workout Session Akışı

```
[Antrenman sekmesi]
     │
     ▼
┌──────────────────────────────────┐
│  Antrenmanlar                    │
│  ─────────────────────────────── │
│  Bu hafta: Faz 2 / Hafta 3       │
│                                  │
│  📅 Pazartesi — Upper A          │
│     [Başla →]                    │
│  📅 Salı — Lower A               │
│     ✓ Bitti (dün)                │
│  ...                             │
│                                  │
│  [Geçmiş antrenmanlar →]         │
└──────────────────────────────────┘
     │ "Başla" tap
     ▼
┌──────────────────────────────────┐
│  Upper A · Faz 2 W3 · ⏱ 00:00   │
│  ─────────────────────────────── │
│  Energy: ●●●○○ (3/5)             │
│  Knee: 🟢 OK   Elbow: 🟡 hafif   │
│                                  │
│  1. Bench Press                  │
│     Geçen hafta: 60kg × 8/8/7    │
│     ─────────────────────────    │
│     Set 1: [60]kg [8] reps RIR[2]│
│     [✓ Kaydet]                   │
│     Set 2: ...                   │
│                                  │
│  [Set ekle +]                    │
│  ─────────────────────────────── │
│  2. Pull-up                      │
│  ...                             │
│                                  │
│  [Antrenmanı Bitir]              │
└──────────────────────────────────┘
     │ "Set kaydet" tap
     ▼
[Haptic feedback + rest timer başlar]
┌──────────────────────────────────┐
│  Set 1 kaydedildi! ✓             │
│  ⏱  Dinlenme: 01:23 / 1:30       │
│                                  │
│  [+15s] [Atla] [+30s]            │
└──────────────────────────────────┘
     │
     ▼
[Timer bittiğinde haptic + ses + bildirim]
"Set 2'ye hazır!"
```

### 4.2 Auto-Progression Önerisi (US-02, F-10)

```
[Yeni set girerken, kg field tap edilince]
┌──────────────────────────────────┐
│  💡 Öneri                        │
│  ─────────────────────────────── │
│  Geçen hafta: 60kg × 8/8/7       │
│  RIR ortalaması: 2.3             │
│                                  │
│  Bu hafta öner: 62.5kg × 8       │
│  Gerekçe: RIR>2 ve tüm setleri   │
│  tamamladın.                     │
│                                  │
│  [Bu öneriyi uygula] [Hayır]     │
└──────────────────────────────────┘
```

### 4.3 Workout History (Aşama 0'da TODO bitir)

```
┌──────────────────────────────────┐
│  Antrenman Geçmişi    [Filtre ▼] │
│  ─────────────────────────────── │
│  Mayıs 2026                      │
│                                  │
│  ✓ 13.05 · Upper A · Faz 2 W3   │
│    8 hareket · 24 set · 45dk    │
│    [Detay →]                     │
│                                  │
│  ✓ 12.05 · Lower A · Faz 2 W3   │
│    ...                           │
│                                  │
│  Nisan 2026                      │
│  ...                             │
└──────────────────────────────────┘
```

---

## 5. Akış: Yemek Log (US-05)

```
[Beslenme sekmesi]
     │
     ▼
┌──────────────────────────────────┐
│  Beslenme — 13 Mayıs             │
│  ─────────────────────────────── │
│  📊 Bugün:                       │
│   Kalori: 1240 / 1800 kcal       │
│   ▓▓▓▓▓░░░░ %69                  │
│   Protein: 95 / 180 gr           │
│   ▓▓▓▓▓░░░░ %53                  │
│                                  │
│  🥗 Öğle (12:30)                  │
│   • Tavuk göğsü — 150gr · 247kcal│
│   • Bulgur pilavı — 200gr · 174kcal│
│   [+ Yemek ekle]                 │
│                                  │
│  🌙 Akşam                         │
│   [+ Yemek ekle]                 │
│                                  │
│  💧 Su: 1500 / 2500 ml            │
│   [+200ml] [+500ml]              │
│                                  │
│  💊 Takviye:                      │
│   ✓ Whey 30gr (öğleden sonra)    │
│   ☐ Magnezyum (akşam)            │
│   ☐ Omega-3 (akşam)              │
└──────────────────────────────────┘
     │ "Yemek ekle" tap
     ▼
┌──────────────────────────────────┐
│  Yemek Ara                       │
│  ─────────────────────────────── │
│  🔍 [tavuk____________]          │
│                                  │
│  Sonuçlar:                       │
│  • Tavuk göğsü (haşlanmış)       │
│    165 kcal · 31 P · 0 K · 4 Y   │
│  • Tavuk but                     │
│    209 kcal · 18 P · 0 K · 14 Y  │
│  • Tavuk şiş                     │
│  ...                             │
│                                  │
│  [+ Yeni yemek ekle]             │
└──────────────────────────────────┘
     │ Yemek tap
     ▼
┌──────────────────────────────────┐
│  Tavuk göğsü                     │
│  ─────────────────────────────── │
│  Miktar: [150]gr                 │
│  Öğün: ○Kahvaltı ●Öğle ○Akşam ○Ara│
│                                  │
│  Hesaplanan:                     │
│  Kalori: 247 kcal                │
│  Protein: 46.5 gr                │
│                                  │
│  [Kaydet]                        │
└──────────────────────────────────┘
```

**Hızlı log shortcut'u:** Home ekranında "son yenen 3 yemek" kartı → 2 tap'te kaydet.

---

## 6. Akış: Su & Takviye Log (US-06)

### 6.1 Su

```
[Beslenme → Su kartı]
"💧 Su: 1500 / 2500 ml"
   [+200] [+500]   long press → custom

[Custom long press]
┌──────────────────────────────────┐
│  Su ekle                         │
│  Miktar: [____] ml               │
│  Saat: [şimdi ▼]                 │
│  [Ekle]                          │
└──────────────────────────────────┘
```

### 6.2 Takviye

```
[Beslenme → Takviye listesi]
┌──────────────────────────────────┐
│  Bugünün takviyeleri:            │
│  ✓ Whey 30gr     (✓ alındı 13:00)│
│  ☐ Kreatin 5gr                   │
│  ☐ Magnezyum                     │
│  ☐ Omega-3                       │
│                                  │
│  [Takviye düzenle →]             │
└──────────────────────────────────┘

[Düzenle → ayarlar]
- Default takviye listesi yönetimi
- Hatırlatma saati
- Dose tahmini
```

---

## 7. Akış: Vücut Ölçümü (US-07)

```
[Gelişim sekmesi → "Ölçüm ekle"]
     │
     ▼
┌──────────────────────────────────┐
│  Yeni Ölçüm — 13 Mayıs           │
│  ─────────────────────────────── │
│  Kilo:     [84.7] kg             │
│  Bel:      [88]   cm             │
│  Göğüs:    [104]  cm             │
│  Kol:      [37]   cm             │
│  Kalça:    [98]   cm             │
│  Boyun:    [40]   cm             │
│  Yağ %:    [25]   % (opsiyonel)  │
│                                  │
│  [Kaydet]                        │
└──────────────────────────────────┘
     │ Kaydet
     ▼
[Snackbar: "Kaydedildi ✓"]
[Otomatik kilo trend grafiğine git önerisi]
```

---

## 8. Akış: İlerleme Fotoğrafı (US-08, Q-02 Hibrit)

### 8.1 Foto Çekme

```
[Gelişim → Fotoğraf → "+"]
     │
     ▼
┌──────────────────────────────────┐
│  Yeni İlerleme Fotoğrafı         │
│  ─────────────────────────────── │
│  Açı seç:                        │
│  ⦿ Ön    ○ Yan    ○ Arka         │
│                                  │
│  Kaynak:                         │
│  [📷 Kamera]  [🖼 Galeri]         │
└──────────────────────────────────┘
     │ Kamera tap
     ▼
[Native kamera UI]
     │ Foto çek
     ▼
┌──────────────────────────────────┐
│  [foto önizleme]                 │
│                                  │
│  ☑ Telefon galerime de kaydet    │
│    (orijinal kalite — yedek)     │
│                                  │
│  [Tekrar çek] [Kaydet]           │
└──────────────────────────────────┘
     │ Kaydet
     ▼
[Arkaplan]
1. Orijinal → telefon galerisine (gal paketi)
2. Sıkıştırılmış (1600px, %85) → app Documents
3. DB'ye path kaydı
     │
     ▼
[Snackbar: "Fotoğraf kaydedildi ✓"]
```

### 8.2 Foto Karşılaştırma (Önce/Sonra)

```
[Gelişim → Fotoğraf → "Karşılaştır"]
     │
     ▼
┌──────────────────────────────────┐
│  Karşılaştır                     │
│  ─────────────────────────────── │
│  Sol:  [Tarih ▼ 01.02.2026]      │
│  Sağ:  [Tarih ▼ 13.05.2026]      │
│  Açı:  ⦿ Ön  ○ Yan  ○ Arka       │
│                                  │
│  ┌─────────┬─────────┐           │
│  │         │         │           │
│  │  Önce   │  Sonra  │           │
│  │  Şubat  │  Mayıs  │           │
│  │  86.4kg │  84.7kg │           │
│  │         │         │           │
│  └─────────┴─────────┘           │
│                                  │
│  Fark: -1.7kg · 3.5 ay           │
│                                  │
│  [Paylaş]  [Tam ekran]           │
└──────────────────────────────────┘
```

---

## 9. Akış: Günlük Log (US-09)

Tek ekran, tek scroll — günde 30 saniye.

```
[Beslenme → Günlük log] veya [Home → "Bugünü kaydet" kart]
     │
     ▼
┌──────────────────────────────────┐
│  Bugün — 13 Mayıs                │
│  ─────────────────────────────── │
│  😴 Uyku                         │
│  [7] saat                        │
│                                  │
│  😰 Stres seviyesi               │
│  ●●●●○○○○○○ (4/10)               │
│                                  │
│  😊 Mood (kısa not)              │
│  [____________________]          │
│                                  │
│  🦵 Sağ diz ağrısı                │
│  ○ Yok  ⦿ Hafif  ○ Orta  ○ Şiddetli│
│                                  │
│  💪 Sağ dirsek ağrısı             │
│  ⦿ Yok  ○ Hafif  ○ Orta  ○ Şiddetli│
│                                  │
│  [Kaydet]                        │
└──────────────────────────────────┘
```

---

## 10. Akış: AI Haftalık Özet (US-10, US-12)

### 10.1 Otomatik Tetikleme

- **Pazar gecesi 21:00** veya **Pazar günü ilk uygulama açılışı**
- Bildirim: "🤖 Haftalık özetin hazır — bak bir kontrol et"

### 10.2 Özet Ekranı

```
┌──────────────────────────────────┐
│  Haftalık Özet — Hafta 19         │
│  6 Mayıs - 12 Mayıs              │
│  ─────────────────────────────── │
│                                  │
│  🎯 Genel skor: 7.5/10           │
│  "Bu hafta sağlam bir hafta"     │
│                                  │
│  💪 Antrenman                    │
│  ✓ 4/4 antrenmanı tamamladın     │
│  ↗ Toplam hacim +5% (geçen haftaya)│
│  ⚠ Dirsek ağrısı 2 antrenmanda  │
│                                  │
│  🍽 Beslenme                      │
│  ⚠ Protein hedefini 3/7 gün tutturamadın│
│  ✓ Kalori hedefine ortalama uygun│
│                                  │
│  📊 Ölçü/Foto                     │
│  Kilo: 85.4 → 84.7 (-0.7kg)      │
│  Bel: 89 → 88 (-1cm)             │
│                                  │
│  🔮 Pattern uyarısı:              │
│  "3 haftadır cumartesi günleri   │
│   uyku 5-6 saat. Pazartesi       │
│   antrenmanların düşük performans│
│   gösteriyor. Cumartesi          │
│   uykuna dikkat."                │
│                                  │
│  💡 Bu hafta için öneri          │
│  • Protein takviyeni öne çek     │
│  • Tricep extensions yerine      │
│    cable pushdown dene           │
│                                  │
│  [AI'ya soru sor →]              │
└──────────────────────────────────┘
```

---

## 11. Akış: AI Sohbet (US-11, V2 Aşama 3)

```
[Gelişim → AI Asistan] veya [Home AI kartı]
     │
     ▼
┌──────────────────────────────────┐
│  AI Asistan                      │
│  ─────────────────────────────── │
│  Önerilen sorular:               │
│  • "Bu hafta neyi yanlış yaptım?"│
│  • "Yarın leg day için ne yiyeyim?"│
│  • "Dirsek ağrısı için ne yapayım?"│
│                                  │
│  ─────────────────────────────── │
│  🤖 Selam Samet, sormak istediğin │
│     bir şey var mı?              │
│                                  │
│  👤 Bu hafta neyi yanlış yaptım?  │
│                                  │
│  🤖 [düşünüyor...]                │
│     Bu hafta protein hedefini 3 gün│
│     tutturamadın (Sal, Per, Cmt).│
│     Antrenman hacmin iyi ama     │
│     toparlanman protein az olduğunda│
│     yetersiz kalmış olabilir...  │
│                                  │
│  [____________________] [Gönder] │
└──────────────────────────────────┘
```

**Context window:** AI'ya son 7 günlük tüm log özeti + kullanıcı sorusu gönderilir. Token tasarrufu için detay log'lar değil, agregat veriler.

---

## 12. Akış: Streak & Achievement (US-13, US-14)

### 12.1 Streak Görüntüleme (Home'da)

```
┌──────────────────────────────────┐
│  🔥 12 günlük seri                │
│  Antrenman + log seri:           │
│  Mayıs 2 - Mayıs 13              │
│                                  │
│  [Detay →]                       │
└──────────────────────────────────┘
```

### 12.2 Achievement Bildirim

```
[Streak 30 günü görünce → modal]
┌──────────────────────────────────┐
│         🏆                       │
│  Yeni Rozet Kazandın!            │
│  ─────────────────────────────── │
│  "Sebatkar"                      │
│  30 gün üst üste log girdin      │
│                                  │
│  [Paylaş]  [Tamam]               │
└──────────────────────────────────┘
```

### 12.3 Achievement Listesi (Profil → Rozet'ler)

```
┌──────────────────────────────────┐
│  Rozetler              7/20      │
│  ─────────────────────────────── │
│  ✓ İlk antrenman                 │
│  ✓ 7 gün seri                    │
│  ✓ İlk 100kg squat               │
│  ✓ İlk fotoğraf yüklendi         │
│  ─ 30 gün seri (12/30)           │
│  ─ İlk 5kg yağ verme (in progress)│
│  🔒 60 gün seri                   │
│  🔒 İlk 100 antrenman             │
│  ...                             │
└──────────────────────────────────┘
```

---

## 13. Akış: Akıllı Bildirim (US-15)

### 13.1 Bildirim Tipleri

| Tip | Tetikleyici | Mesaj örneği |
|-----|-------------|--------------|
| Antrenman hatırlatma | Plan günü + saat 18:00 | "Bugün Upper A günü 💪 Hazır mısın?" |
| Takviye hatırlatma | Kullanıcı saatinde | "Whey zamanı 🥤" |
| Pre-WO checklist | Antrenmandan 1 saat önce | "Antrenman 1 saat sonra, hazırlanalım" |
| Haftalık özet | Pazar 21:00 | "🤖 Haftalık özetin hazır" |
| Pattern uyarısı | AI tespit ettiğinde | "Son 3 gün protein az, dikkat" |
| Streak risk | Gece 22:00, bugün log yoksa | "Serini kaybetme! Bugün log girmedin" |

### 13.2 Bildirim Reddi (PRD Q-04)

Kullanıcı bildirim iznini reddederse:
- Sistem dialog'u kapanır
- **Sessizce devam** — uygulama açılır
- Home ekranında **in-app reminder kartı** belirir:

```
┌──────────────────────────────────┐
│  💡 Bildirimler kapalı            │
│  Hatırlatma için her gün uygulamayı│
│  açman gerekecek.                │
│  [Bildirim aç] [Tamam]           │
└──────────────────────────────────┘
```

---

## 14. Ekran-Bazlı Wireframe Detayı

### 14.1 Home Ekranı (Detaylı)

```
┌──────────────────────────────────┐
│  Fit Pack             ⚙️         │
│  ─────────────────────────────── │
│                                  │
│  Günaydın, Samet! 🌞              │
│  Faz 2 · Hafta 3 · 13 Mayıs Çar  │
│                                  │
│  ╔══════════════════════════════╗│
│  ║ 🔥 12 günlük seri             ║│
│  ║ Bugün log girmeyi unutma     ║│
│  ╚══════════════════════════════╝│
│                                  │
│  📋 Bugünün Planı                │
│  💪 Upper A antrenmanı            │
│  [Başla →]                       │
│                                  │
│  🍽 Beslenme (öğle: 1240 kcal)    │
│  [+ Hızlı log]                   │
│                                  │
│  💧 Su: 1500/2500 ml              │
│  [+200] [+500]                   │
│                                  │
│  ⚖ Bugünkü kilo:                  │
│  Henüz girmedin [+ Ekle]         │
│                                  │
│  🤖 AI Flash Insight              │
│  "Bu hafta antrenman performansın│
│   yüksek, protein takviyeni     │
│   sürdürmen önerilir."           │
│  [Detay →]                       │
│                                  │
│  📊 Son 7 gün                    │
│  [mini sparkline grafiği]        │
└──────────────────────────────────┘
```

### 14.2 Workout Session Ekranı (Detay)

```
┌──────────────────────────────────┐
│  ✕ Upper A · Faz 2 W3            │
│  ⏱  00:23:14                     │
│  ─────────────────────────────── │
│                                  │
│  Pre-WO durumu                   │
│  Energy: ●●●○○                   │
│  Knee: 🟢  Elbow: 🟡 hafif       │
│  [Düzenle ✏️]                     │
│                                  │
│  ─────────────────────────────── │
│                                  │
│  1️⃣ Bench Press                  │
│  Geçen: 60kg × 8/8/7 (RIR 2/2/1) │
│                                  │
│  ┌─────┬─────┬─────┬─────┐       │
│  │ Set │ kg  │ rep │ RIR │       │
│  ├─────┼─────┼─────┼─────┤       │
│  │  1  │ 62.5│  8  │  2  │ ✓     │
│  │  2  │ 62.5│  8  │  2  │ ✓     │
│  │  3  │ 62.5│ [_] │ [_] │       │
│  └─────┴─────┴─────┴─────┘       │
│  [+ Set ekle]                    │
│                                  │
│  ⏱ Dinlenme: 01:23 / 1:30        │
│  [+15s] [Atla] [+30s]            │
│                                  │
│  ─────────────────────────────── │
│                                  │
│  2️⃣ Incline DB Press             │
│  Henüz başlamadın                │
│                                  │
│  ─────────────────────────────── │
│  ...                             │
│                                  │
│  [Antrenmanı Bitir ✓]            │
└──────────────────────────────────┘
```

### 14.3 Gelişim — Grafik Ekranı

```
┌──────────────────────────────────┐
│  Gelişim Grafikleri              │
│  ─────────────────────────────── │
│  Aralık: [Son 30 gün ▼]          │
│  Metrik: ⦿ Kilo  ○ Hacim  ○ Protein│
│                                  │
│  ┌──────────────────────────┐    │
│  │  Kilo (kg)               │    │
│  │   85┤●                    │    │
│  │     │ ●                   │    │
│  │   84┤  ● ●                │    │
│  │     │     ● ●             │    │
│  │   83┤        ● ●          │    │
│  │     └─────────────────    │    │
│  │     1     15    30 Mayıs  │    │
│  └──────────────────────────┘    │
│                                  │
│  📊 Özet                          │
│  Başlangıç: 85.4 kg              │
│  Şu an: 84.7 kg                  │
│  Değişim: -0.7 kg (-0.8%)        │
│  Trend: ↓ Cut hedefi yolunda     │
│                                  │
│  [Foto karşılaştır →]            │
│  [Ölçü trend →]                  │
└──────────────────────────────────┘
```

### 14.4 Settings Ekranı

```
┌──────────────────────────────────┐
│  Ayarlar                  ✕      │
│  ─────────────────────────────── │
│                                  │
│  🎯 Hedefler                      │
│  Boy: 180 cm                     │
│  Hedef kilo: 75 kg               │
│  Günlük kalori: 1800 kcal        │
│  Günlük protein: 180 gr          │
│  Mevcut faz: Cut [değiştir]      │
│  [Detay →]                       │
│                                  │
│  🤖 AI Asistan                    │
│  Sağlayıcı: Gemini               │
│  API key: ●●●●●●●●●● [değiştir]   │
│  Haftalık özet: ✓ Aktif          │
│                                  │
│  🔔 Bildirimler                   │
│  Antrenman hatırlatma: ✓          │
│  Takviye hatırlatma: ✓            │
│  Haftalık özet: ✓                 │
│  Streak risk: ✓                   │
│                                  │
│  📤 Veri                          │
│  [Export →]                      │
│  [Yedek al →] (V3 cloud)         │
│                                  │
│  💪 Antrenman                     │
│  Mevcut faz: 2                   │
│  Hafta: 3                        │
│  [Deload reset]                  │
│                                  │
│  ℹ️ Hakkında                      │
│  Versiyon 2.0                    │
│  [Geri bildirim]                 │
└──────────────────────────────────┘
```

---

## 15. State Geçişleri ve Edge Case'ler

### 15.1 Boş Durumlar (Empty States)

Her ana ekranın **boş durumu** açıkça tasarlanır.

```
[Antrenman geçmişi boş]
┌──────────────────────────────────┐
│                                  │
│         🏋️‍♂️                       │
│                                  │
│  Henüz antrenman yapmadın        │
│  İlk antrenmanını başlat         │
│                                  │
│  [Antrenmana başla →]            │
│                                  │
└──────────────────────────────────┘
```

### 15.2 Hata Durumları (Error States)

```
[AI servisi cevap vermedi]
┌──────────────────────────────────┐
│  ⚠️ Bağlantı sorunu               │
│  Yapay zekâ asistanı şu an       │
│  ulaşılamıyor. İnternet           │
│  bağlantını kontrol et.          │
│                                  │
│  [Tekrar dene]                   │
└──────────────────────────────────┘

[Rate limit dolmuş — PRD Q-03]
┌──────────────────────────────────┐
│  ⏱ Yapay zekâ günlük limiti dolu  │
│  Yarın tekrar dene veya          │
│  ayarlardan farklı bir provider  │
│  seç.                            │
│                                  │
│  [Ayarlar →]  [Tamam]            │
└──────────────────────────────────┘
```

### 15.3 Loading Durumları

- **Optimistik update tercih edilir:** Set kaydedilince anında UI güncellenir, arka planda DB yazılır.
- **Spinner sadece** AI çağrılarında (gerçek async waiting var).
- **Skeleton screen** ilk açılış DB hazırlanırken.

### 15.4 Dismissible Delete (V1'de mevcut, korunur)

```
[Yemek log kaydını sola sürükle]
┌──────────────────────────────────┐
│  🍽 Tavuk göğsü — 150gr           │
│  247 kcal · 46.5 P               │
│  ─────────────────[🗑 Sil]──────  │
└──────────────────────────────────┘
     │ Sil
     ▼
[Snackbar]
"Silindi. [Geri al]"
```

---

## 16. Erişilebilirlik (Accessibility) Notları

- Tüm tap target'lar minimum **44x44 dp**.
- Renk + ikon birlikte kullanılır (sadece renkle ayrım yok — kırmızı/yeşil körlüğe karşı).
- TextField'larda `keyboardType` doğru set edilir (kg/rep için `numberWithOptions(decimal:true)`).
- Screen reader için her ikon `Semantics(label: ...)` ile sarılır (V2 Aşama 3 ileri).
- **Karanlık mod ana hedef** — açık modda da çalışır.

---

## 17. Etkileşim Detayları

### 17.1 Haptic Feedback Kullanımı

| Aksiyon | Haptic |
|---------|--------|
| Set kaydedildi | Medium impact |
| Rest timer bitti | Heavy impact + ses |
| Achievement kazanıldı | Heavy impact × 2 |
| Hata oluştu | Selection click |
| Form submit | Light impact |

### 17.2 Animasyon Felsefesi

- **Hızlı (200-300ms)** geçişler — kullanıcıyı bekletmeyen
- **Reduced motion** sistem ayarına saygı (OS-level)
- Sayfa geçişleri material standard
- Achievement gibi özel anlar için biraz daha gösterişli (confetti gibi değil ama scale + fade)

---

## 18. UX Riskleri ve Azaltma

| Risk | Etki | Azaltma |
|------|------|---------|
| Kullanıcı veri girmeyi sıkıcı bulur | Yüksek | Hızlı log shortcut'lar, son yenen tekrar listesi, otomatik öneri |
| Çok feature → bunaltıcı | Orta | Aşamalı release (V2 Aşama 0/1/2/3), bottom nav 5 tab limiti |
| Bildirim spam algılanır | Orta | Default minimal, kullanıcı detayda açar |
| Foto karşılaştırma çok efor | Orta | Tarih default akıllı (ilk + son), açı default ön |
| Karanlık mod yetersiz kontrast | Düşük | Her ekran karanlıkta test edilir |

---

## 19. Sonraki Adım

Bu doküman onaylanınca:
- `docs/04-roadmap.md` — V2 Aşama 0-4 detay zaman planı, milestone'lar
- `docs/05-testing.md` — Test stratejisi
- `docs/06-workflow.md` — DevOps workflow

---

## 20. Onay & Versiyon

| Versiyon | Tarih | Değişiklik | Onay |
|----------|-------|------------|------|
| 1.0 (taslak) | 2026-05-13 | İlk taslak — PRD + Mimari üzerine inşa | ⏳ Beklemede |
