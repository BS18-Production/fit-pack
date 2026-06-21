# Fit Pack — Aktivite Takvimi PRD & UX

> **Sürüm:** 1.0 (taslak) · **Tarih:** 2026-06-21 · **Sahibi:** Samet Orhan
> **Bağlı:** [PROJECT_STATE.md](../PROJECT_STATE.md), [docs/08-design-brief.md](08-design-brief.md), [docs/09-workout-v2.md](09-workout-v2.md)
> **Karar (Samet, 2026-06-21):** Konum = **İlerleme sekmesi** · Halkalar = **Kalori + Protein + Antrenman + Su (4)** · Yaklaşım = doküman-önce.

Kısaltmalar: **PRD** (Product Requirements Document — ürün gereksinim dokümanı) · **DAO** (Data Access Object — veri erişim katmanı) · **MVP** (Minimum Viable Product — en küçük çalışır ürün) · **N+1** (her satır için ayrı sorgu atma anti-deseni).

---

## 1. Amaç & Değer

Kullanıcı geçmiş günlerine bakıp **"o gün hedeflerimi tuttum mu?"** sorusunu bir bakışta yanıtlayabilsin. Apple Fitness'in aktivite halkaları gibi: her günün etrafında dolan halkalar, seriyi bozmama motivasyonu yaratır. Uygulamayı *takip aracından* → *alışkanlık aracına* dönüştürür (retention).

**Net davranış:** İlerleme sekmesinde aylık bir takvim. Her gün hücresinde 4 ince halka (Kalori/Protein/Antrenman/Su). Güne dokununca o günün özeti açılır (makrolar + yapılan rutin + hacim + su).

> ⚠️ **Native picker değil.** Kullanıcının gördüğü Android `showDatePicker` takvimi özelleştirilemez. Bu özellik **kendi özel takvim widget'ımızla** yapılır.

---

## 2. Konum & Navigasyon

- **İlerleme sekmesi** (`body_metrics_screen.dart`) en üste **Aktivite Takvimi** bölümü alır; mevcut kilo grafiği + ölçüm listesi altında kalır.
- Ay gezinme: `‹ Haziran 2026 ›` başlığı (önceki/sonraki ay okları). Gelecek aylar/günler soluk + tıklanamaz.
- Güne dokun → **bottom sheet** (gün özeti). İkinci seviye ekran yok.

---

## 3. UX — Ekran Anatomisi

### 3.1 Takvim ızgarası
- 7 sütun (Pzt–Paz, TR hafta başı Pazartesi). Ay başlığı + sağda ay okları.
- Her gün hücresi: ortada gün sayısı, etrafında **4 eş-merkezli (concentric) halka**.
- Bugün: gün sayısı primary renkte + ince çerçeve. Gelecek günler: soluk, halkasız.
- Veri olmayan geçmiş günler: boş (gri) halkalar.

### 3.2 Halka tasarımı (4 metrik)
Küçük hücrede (~40–44px) 4 ince concentric ring. Dıştan içe:

| Sıra | Metrik | Renk (token) | Doluluk = |
|------|--------|--------------|-----------|
| 1 (dış) | Kalori | Indigo `macroCalories` | alınan kcal / hedef (0–1, cap 1) |
| 2 | Protein | Teal `macroProtein` | alınan g / hedef |
| 3 | Antrenman | Yeşil `success` | o gün ≥1 seans → tam (1.0), yoksa 0 |
| 4 (iç) | Su | Açık mavi `macroCarbs`/info | içilen ml / hedef |

- Halka kalınlığı ~2.5–3px, aralık ~1.5px. Tam dolan halka %100'de canlı renk.
- **Erişilebilirlik:** sadece renk değil — gün özetinde metin de var. Hücre min 44dp dokunma hedefi.

### 3.3 Gün özeti (bottom sheet)
Başlık: "19 Haziran, Perşembe". İçerik:
- **Beslenme:** kcal alınan/hedef + P/K/Y satırları (makro renkleriyle, mevcut Home hero stili).
- **Antrenman:** yapılan rutin adı + toplam hacim + set sayısı (yoksa "Antrenman yok").
- **Su:** içilen / hedef L.
- Boş gün: "Bu gün için kayıt yok."

---

## 4. Veri Modeli & Sorgular

**Şema değişikliği YOK.** Tüm veri mevcut tablolardan türetilir:
- Beslenme: `food_logs` (tarih bazlı kcal/protein/karb/yağ toplamı)
- Antrenman: `workout_sessions` + `workout_sets` (o günkü seans + hacim)
- Su: `water_intake` (günlük ml)
- Hedefler: `user_profile` (kcalGoal, proteinGoal, waterGoalMl)

### 4.1 Yeni DAO sorguları (toplu — N+1 yok)
Ay görünümü için **tek seferde** tüm ayın verisi çekilir:
- `NutritionDao.getDailyTotalsInRange(start, end)` → `Map<Date("yyyy-MM-dd"), ({double kcal, protein, carb, fat})>` (GROUP BY gün).
- `WorkoutDao.getSessionDaysInRange(start, end)` → o ayki seansların gün kümesi + (opsiyonel) gün başına hacim/ad.
- `BodyDao`/su: `getDailyWaterInRange(start, end)` → `Map<gün, ml>`.

### 4.2 Provider
- `monthActivityProvider(YearMonth)` → ay için birleşik gün→metrik haritası (FutureProvider.family). Ay değişince yeni fetch; ay-içi gün tıklama lokal (yeni sorgu yok).
- Gün özeti için zaten var olan günlük sağlayıcılar tekrar kullanılır.

---

## 5. Bileşenler
- `ActivityCalendar` (ay ızgarası + ay gezinme). Harici paket yerine hafif **custom grid** (table_calendar bağımlılığı eklemeye gerek yok; ihtiyaç sade).
- `DayRings` (4 concentric ring `CustomPainter`). Home'daki halka mantığına benzer.
- `DaySummarySheet` (bottom sheet).

---

## 6. Fazlama

| Faz | Kapsam | Çıktı |
|-----|--------|-------|
| **A** | Toplu DAO sorguları + `monthActivityProvider` + birim testleri | Veri katmanı |
| **B** | `ActivityCalendar` + `DayRings` (custom painter) → İlerleme sekmesine ekleme | Görsel takvim, halkalar dolu |
| **C** | `DaySummarySheet` (güne dokun → özet) | Etkileşim tam |
| **D** (ops.) | Seri (streak) vurgusu, "bu ay X/30 gün hedef tuttun" başlığı | Motivasyon katmanı |

Her faz: analyze 0 + test + emülatör doğrulaması.

---

## 7. Açık Kararlar
- **Antrenman halkası doluluğu:** MVP'de ikili (seans var/yok → 1.0/0). İleride hedef set sayısına göre kısmi doluluk (Faz D).
- **Hafta başı:** Pazartesi (TR standardı) — Home tarih formatıyla tutarlı.
- **Geriye dönük veri:** sadece kayıt olan günler dolu; eski boş günler gri.

## 8. Kapsam Dışı (V1)
- Halka animasyonu (dolum efekti) — Faz D sonrası cila.
- Takvimden geçmiş güne veri girme/düzenleme (takvim salt-görüntüleme + özet).
- Aylık/haftalık trend grafiği (ayrı iş).
- Bildirim/hatırlatma (hedef serisi) — ayrı tasarım.
