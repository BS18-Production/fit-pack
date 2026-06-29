# Fit Pack — Geçmişe Dönük Veri Girişi (Historical Entry)

> **Versiyon:** 1.1
> **Tarih:** 2026-06-29
> **Sahibi:** Samet Orhan
> **Durum:** ✅ TAMAM — 4 özellik (H-A/B/C/D) kodlandı, emülatörde doğrulandı, commit'lendi
> **Bağlı:** [PROJECT_STATE.md](../PROJECT_STATE.md), [docs/09-workout-v2.md](09-workout-v2.md)

## ✅ Tamamlanma notu (2026-06-29)

`feat/historical-entry` dalı. analyze 0 · test 65/65 (4 yeni backdate regresyon testi).
- **H-C** kilo/ölçüm tarih seçici → `738c98b`
- **H-A/H-B** antrenman bitişte tarih + "Geçmiş Antrenman Ekle" akışı + özet etiketi fix → `752c277`
- **H-D** geçmiş seans düzenle/sil + DAO + testler → `b620bc2`
- Tasarım dokümanı → `fce8c84`

**Emülatör doğrulaması:** Geçmiş antrenman 20 Haziran'a kaydedildi → DB `date=2026-06-20` (kaydetme anı değil, seçilen gün). Gelecek tarih takvimde devre dışı. Silme onay dialogu çalışıyor. Samet paralel olarak kendi test seansını (2 Haziran) ekledi — bağımsız doğrulama.

**Ertelendi (bilinçli):** Geçmiş seansta tek tek **set düzenleme** UI'si (kg/tekrar değiştirme) yapılmadı — H-D yalnız tarih + silme kapsar. Set düzeltme gerekiyorsa seansı silip yeniden eklemek mevcut yol. İleride istenirse ayrı iş.

---

## 1. Problem

Kullanıcı, gerçekleştirdiği bir aktiviteyi her zaman aynı gün giremiyor. Örnek: "2 gün önce yaptığım sporu ve yediğim yemeği bugün girmek istiyorum." Mevcut durumda:

| Veri | Geçmişe giriş | Not |
|------|---------------|-----|
| 🍽 Beslenme | ✅ Var | Gün gezgini (‹ Bugün ›) + takvim ikonu + "önceki günü kopyala" |
| 💪 Antrenman | ❌ Yok | Canlı seans, kayıt `DateTime.now()` ile atılıyor |
| ⚖️ Kilo/ölçüm | ❌ Yok | Her zaman bugün tarihiyle kaydoluyor |

## 2. Best-practice (araştırma — Hevy, Strong, MyFitnessPal, Apple Health)

1. **Canlı takip ≠ manuel kayıt.** Kronometre zorunlu olmamalı; geçmiş için esnek yol şart. (Hevy/Strong: bitişte "otomatik zamanlamayı kapat" → tarih/saati elle gir.)
2. **Varsayılan "şimdi", değiştirmek 1-2 dokunuş ötede.** Bugünü loglayan çoğunluk sürtünme yaşamamalı.
3. **Mantıksal gün ≠ cihaz saati.** Seri, haftalık hacim, aktivite takvimi kaydın gerçek tarihinden türemeli.
4. **Kaydettikten sonra düzenlenebilmeli** (tarih dahil). (Hevy "Edit Workout".)
5. **Korkuluklar:** gelecek tarih engellensin.
6. **Tutarlılık:** Beslenme = gün gezgini (günlük toplam); Antrenman/Kilo = olay başına tarih seçici (zaman damgalı olay). Sektörün baskın ikili kalıbı; uygulama zaten yarısını böyle yapıyor.

## 3. Veri modeli — KRİTİK BULGU: zaten hazır

`WorkoutSessions` tablosunda **`date` = mantıksal gün** ve tüm istatistikler bu alandan türüyor:
- `weekWorkoutStatsProvider` → `getSessionsByDateRange` (`s.date`)
- `workoutStreakProvider` → `s.date`
- Aktivite takvimi → `s.date`
- Geçmiş ekranı → `orderBy(s.date)`
- `startedAt`/`endedAt`/`durationMin` → gerçek zaman damgaları (opsiyonel, v6'da mevcut)
- `updateSession` (DAO `replace`) → düzenleme zaten destekli

**Sonuç:** Şema değişikliği GEREKMİYOR. Geçmişe giriş = kaydederken `date`'i kullanıcının seçtiği güne ayarlamak. Tüm istatistikler otomatik doğru güne yazılır.

`BodyMeasurements.date` de aynı şekilde mevcut; sadece `_save()` `DateTime.now()` yerine seçilen tarihi kullanmalı.

## 4. Kapsam (Samet kararı, 2026-06-29)

- **Antrenman:** İkisi de → (A) bitiş ekranında tarih/saat düzenleme **+** (B) ayrı "Geçmiş antrenman ekle" akışı (kronometresiz).
- **Kilo/ölçüm:** ölçüm formuna tarih seçici.
- **Geçmiş kaydı düzenleme:** antrenman geçmişinden bir seansın tarihini (ve setlerini) sonradan değiştirme.
- **Beslenme:** dokunulmuyor (zaten doğru).

## 5. UX akışları

### 5.1 Antrenman — bitişte tarih/saat (H-A)
- Aktif seans özet/bitiş ekranına satır: **"Tarih · {bugün}"** → dokununca `showDatePicker` (+ opsiyonel `showTimePicker`).
- Varsayılan = seansın `startedAt`'i (bugün). Gelecek tarih kapalı (`lastDate: now`).
- Kaydederken: `date`, `startedAt`, `endedAt` seçilen güne kaydırılır; süre korunur.

### 5.2 Antrenman — "Geçmiş antrenman ekle" (H-B)
- Giriş noktası: Antrenman ana ekranı app bar (geçmiş ikonu yanına **+**) veya Geçmiş ekranı üstünde buton.
- Akış: tarih seç → hareket ekle (kütüphaneden) → set/tekrar/kg gir (kronometre YOK, dinlenme sayacı YOK) → kaydet.
- Aktif seans ekranını yeniden kullan; `manualDate` parametresiyle "geçmiş modu" (timer gizli, tarih satırı ön planda).

### 5.3 Kilo/ölçüm — tarih seçici (H-C)
- Ölçüm ekleme formuna en üste **"Tarih · {bugün}"** satırı → `showDatePicker` (gelecek kapalı).
- `_save()` → `date: Value(_selectedDate)`.

### 5.4 Geçmiş seans düzenleme (H-D)
- Antrenman Geçmişi (`/workout/history`) → seans satırında ⋯ veya kalem → "Düzenle".
- Düzenle: tarih + setler (kg/tekrar/RPE) + sil. DAO `updateSession` + set güncelle/sil mevcut/eklenecek.

## 6. Görev kırılımı

| ID | İş | Tahmin | Şema |
|----|-----|--------|------|
| H-C | Kilo/ölçüm form tarih seçici | ~20 dk | — |
| H-A | Aktif seans bitişine tarih/saat seçici | ~1 sa | — |
| H-B | "Geçmiş antrenman ekle" akışı (manualDate modu) | ~2-3 sa | — |
| H-D | Geçmiş seans düzenleme (tarih + setler + sil) | ~2-3 sa | — |
| H-V | Doğrulama: analyze 0 · testler · emülatörde 3 senaryo | — | — |

**Önerilen sıra:** H-C (hızlı kazanım) → H-A → H-B → H-D. Her biri ayrı küçük commit.

## 7. Doğrulama planı

- `flutter analyze` 0.
- Birim test: geçmiş tarihli seans → `weekWorkoutStats`, `streak`, `getSessionsByDateRange` doğru güne düşüyor.
- Emülatör: (1) kiloyu 2 gün öncesine gir → İlerleme grafiği doğru günde; (2) geçmiş antrenman 2 gün öncesine ekle → aktivite takvimi + haftalık istatistik doğru; (3) bir seansı düzenle → tarih değişince istatistikler kayar.
- Korkuluk: gelecek tarih seçilemiyor.

## 8. Bilinçli yapılmayanlar (bu tur)

- Beslenme'ye değişiklik (zaten doğru).
- Toplu içe aktarma (Strong/Hevy CSV) — V3+.
- Saat dilimi/DST ince ayarı — tek kullanıcı lokal, gerek yok.
