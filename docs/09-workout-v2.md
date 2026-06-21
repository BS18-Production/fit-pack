# Fit Pack — Antrenman V2 PRD & Şema Tasarımı

> **Sürüm:** 1.0 (taslak) · **Tarih:** 2026-06-21 · **Sahibi:** Samet Orhan
> **Bağlı:** [docs/08-design-brief.md](08-design-brief.md) (tasarım + hareket seed listesi), [PROJECT_STATE.md](../PROJECT_STATE.md), [NEXT_TASKS.md](../NEXT_TASKS.md)
> **Tasarım referansı:** `design/code/Fit Pack Antrenman.dc.html` (interaktif prototip)

Kısaltmalar: **RPE** (Rate of Perceived Exertion — algılanan zorluk, 1-10) · **RIR** (Reps in Reserve — yedekte kalan tekrar) · **1RM** (One-Rep Max — tek tekrar maksimumu) · **e1RM** (estimated 1RM — tahmini 1RM) · **PR** (Personal Record — kişisel rekor) · **FK** (Foreign Key — yabancı anahtar) · **DAO** (Data Access Object — veri erişim katmanı).

---

## 1. Amaç & Karar

Antrenman sekmesini **Hevy/Strong seviyesi** profesyonel bir takipçiye dönüştürmek. Salondaki her hareket/makine için kg×tekrar takibi, kendi rutinini oluşturma, geçmişe göre ilerleme.

**Ürün kararı (Samet, 2026-06-21): TAM GEÇİŞ — sadece rutinler + GENEL KİTLE.**

> 🔑 **Stratejik dönüş:** Fit Pack artık Samet'in kişisel takipçisi değil, **herkese hitap eden genel bir ürün.** "Kişisel hiçbir şey olmayacak." Bu, Antrenman V2'nin tüm tasarımını yönlendirir.

- Sabit faz/program modeli (`workout_plan.json`, Faz 1/2/3 + sabit haftalık gün) **kaldırılıyor.**
- Her antrenman ya bir **kullanıcı rutini**nden ya da **boş antrenman**dan başlar.
- **Hazır program seed'i YOK** (S-2). Kullanıcı **tüm rutinleri sıfırdan** oluşturur. Uygulama boş rutin listesiyle gelir; tek hazır içerik = hareket kütüphanesi.
- **Kişisel/V1'e özgü alanlar kaldırılıyor** (S-3): `kneeStatus`, `energy`, `isDeload` (sessions), `isPosture`, `isArm` (exercises). Genel üründe yeri yok.
- **Sakatlık notu / kişiselleştirme YOK** (S-4).
- Hareket adları **İngilizce** (S-1, salon standardı), arayüz Türkçe.

**Korunacaklar (ADR-007 — yıkıcı işlem yasak):**
- Mevcut `workout_sessions` + `workout_sets` **satırları** korunur (eski `workoutType`/`phase` nullable'a düşer). Kaldırılan kişisel kolonlar pre-release olduğu için temizlenebilir; mevcut tek veri Samet'in emülatör pilotu (kritik değil), yine de satır silme yapılmaz.
- Mevcut `exercises` satırları korunur, İngilizce seed ada göre eşlenip genişletilir.

---

## 2. Mevcut Durum (V1 şema)

```
Exercises:        id, name, category(compound/isolation), muscleGroups(JSON),
                  alternatives(JSON), isPosture, isArm, notes
WorkoutSessions:  id, date, phase, workoutType, durationMin, kneeStatus,
                  energy, rpe, notes, isDeload
WorkoutSets:      id, sessionId→, exerciseId→, setNumber, weightKg, reps,
                  isWarmup, restSeconds
```

**Eksikler:** ekipman, ölçüm tipi, geniş kategori (calisthenics/cardio/flexibility), rutin kavramı, set başına RPE, set tipi (drop/failure), PR takibi, canlı seans (timer), dinlenme sayacı.

---

## 3. Hedef Veri Modeli (V2)

### 3.1 Exercises (genişlet — additive)

Yeni kolonlar (hepsi nullable veya default'lu → kayıpsız migration):

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `equipment` | text? | barbell, dumbbell, machine, cable, bodyweight, smith, kettlebell, cardio, none |
| `measurementType` | text | weight_reps (default), reps, time, distance |
| `isCustom` | bool | Kullanıcı eklediyse true (varsayılan false) |
| `isArchived` | bool | Silmek yerine arşivle (geçmiş set'ler FK ile bağlı) |

`category` artık 5 değer: compound, isolation, calisthenics, cardio, flexibility. (Mevcut compound/isolation korunur; backfill ile diğerleri.)

**Seed:** `docs/08-design-brief.md`'deki İngilizce tam liste (~90 hareket, 5 kategori, ekipman+kas+ölçüm tipi). Mevcut Türkçe-bağlamlı seed İngilizce isimlere taşınır; eski hareketler ada göre eşlenip korunur.

### 3.2 Routines (yeni)

```
Routines:  id, name, note?, orderIndex, scheduledWeekday? (1-7, null=programsız),
           colorTag?, createdAt, isArchived
```
- `scheduledWeekday`: opsiyonel haftalık gün ataması → **Home dinlenme günü zekası** bunu kullanır (bugün için atanmış rutin var mı?).
- Silme yerine `isArchived` (geçmiş seanslar `routineId` ile bağlı kalabilir).

### 3.3 RoutineExercises (yeni)

```
RoutineExercises: id, routineId→, exerciseId→, orderIndex,
                  targetSets?, targetRepsMin?, targetRepsMax?, targetRestSec?, note?
```
Bir rutindeki hareketler + hedef set×tekrar. Sürükle-bırak sıralama `orderIndex`.

### 3.4 WorkoutSessions (genişlet)

| Yeni kolon | Tip | Açıklama |
|------------|-----|----------|
| `routineId` | int? FK | Hangi rutinden başladı (null = boş antrenman) |
| `name` | text? | Seans adı (rutin adının snapshot'ı veya "Boş Antrenman") |
| `startedAt` | datetime? | Canlı timer başlangıcı |
| `endedAt` | datetime? | Bitiş → süre hesabı |

`phase` + `workoutType` **nullable'a** düşürülür (eski kayıtlar için kalır, yeni kayıtlarda null). Yıkıcı değil.

### 3.5 WorkoutSets (genişlet)

| Yeni kolon | Tip | Açıklama |
|------------|-----|----------|
| `rpe` | real? | Algılanan zorluk 1-10 (yarım değer destekli) |
| `setType` | text | normal (default), warmup, drop, failure |
| `isComplete` | bool | Set tamamlandı mı (✓ ile işaretlenir) |
| `distanceM` | real? | Mesafe ölçümlü hareketler (kardiyo) |
| `durationSec` | int? | Süre ölçümlü hareketler (plank, kardiyo) |

`isWarmup` korunur ama `setType='warmup'` ile köprülenip terk edilir (backfill: isWarmup=true → setType='warmup').

### 3.6 PR / e1RM (Faz D)

Başlangıçta **tablo yok** — set'lerden hesaplanır:
- e1RM = Epley formülü: `weight × (1 + reps/30)`.
- PR'lar (en iyi set, en yüksek hacim, en yüksek e1RM) sorgu ile türetilir.
- Performans gerekirse `ExercisePRs` cache tablosu eklenir (sonradan, additive).

---

## 4. Ekranlar (tasarımdan)

1. **Antrenman (ana):** "Boş Antrenman Başlat" + "Rutinlerim" (kartlar: ad, hareket sayısı, kas etiketleri, opsiyonel gün) + "Yeni Rutin" + bu hafta istatistik + "Antrenman Geçmişi".
2. **Rutin Önizleme:** rutin hareketleri + hedef set×tekrar + ekipman etiketi + "Antrenmana Başla" + "Düzenle".
3. **Aktif Seans (HERO):** sabit başlık (ad + süre sayacı + Bitir), dinlenme sayacı banner'ı (−15s/+15s/Atla), her hareket için set tablosu `SET · ÖNCEKİ · KG · TEKRAR · RPE · ✓`, set tipi rozeti (ısınma/normal/drop/failure), +Set/−Set, makine notu, "+ Hareket Ekle", geri = "Antrenmandan çık?".
4. **Hareket Kütüphanesi:** arama + kategori filtresi (5) + kas grubu + ekipman çipleri, çoklu seçim, "+ Yeni Hareket".
5. **Hareket Detayı:** Geçmiş / Grafik (çalışma kilosu + e1RM) / Rekorlar sekmeleri.
6. **Rutin Oluşturucu:** ad + kütüphaneden hareket ekle + set×tekrar hedefi + sürükle sırala + (opsiyonel) haftalık gün.
7. **Antrenman Özeti:** süre, toplam hacim, toplam set, kırılan PR'lar (🏆), hareket bazlı özet → Geçmiş'e ekler.

Ölçüm tipi desteği: weight×reps (varsayılan), bodyweight reps, time (plank/kardiyo), distance.

---

## 5. Migration Stratejisi (şema v4 → v5+)

Her faz kendi şema bump'ı (Workflow §4: bump + onUpgrade + lossless test aynı commit'te).

- **v5 (Faz A):** Exercises +equipment/+measurementType/+isCustom/+isArchived. Backfill: mevcut hareketlere ekipman/ölçüm tipi/kategori ata (seed eşlemesi). İngilizce seed listesi yüklenir (yeni hareketler eklenir, mevcutlar ada göre güncellenir).
- **v6 (Faz B):** Routines + RoutineExercises tabloları (createTable). **Program seed YOK** — kullanıcı sıfırdan oluşturur. WorkoutSessions +routineId/+name/+startedAt/+endedAt, phase/workoutType nullable; kişisel alanlar (kneeStatus/energy/isDeload) üründen çıkar.
- **v7 (Faz C):** WorkoutSets +rpe/+setType/+isComplete/+distanceM/+durationSec. Backfill isWarmup→setType.
- **v8 (Faz D, opsiyonel):** ExercisePRs cache (gerekirse).

Her adımda eski `workout_sessions`/`workout_sets`/`exercises` verisi **kayıpsız** korunur (lossless test zorunlu).

---

## 6. Önerilen Fazlama

| Faz | Kapsam | Şema | Çıktı |
|-----|--------|------|-------|
| **A** | Hareket Kütüphanesi | v5 | Genişletilmiş exercises + İngilizce seed + filtreli/aranabilir kütüphane ekranı + özel hareket. **Her şeyin temeli.** |
| **B** | Rutinler | v6 | Routines/RoutineExercises + ana ekran (boş antrenman + rutinlerim, boş başlar) + rutin oluşturucu + önizleme + Home dinlenme günü rutine bağlama |
| **C** | Gelişmiş Seans | v7 | Set tablosu (RPE + set tipi + dinlenme sayacı + ✓) + canlı süre + antrenman özeti |
| **D** | Hareket Detayı + PR | v8? | Geçmiş/grafik/PR + e1RM, tahmini rekorlar |

**Öneri:** Faz A → B → C → D sırayla. Her faz çalışır, test edilir, commit'lenir, emülatörde doğrulanır.

---

## 7. Çözülen Kararlar (Samet, 2026-06-21)

- **S-1 ✅ İNGİLİZCE:** Hareket adları İngilizce (Bench Press), arayüz Türkçe.
- **S-2 ✅ SIFIRDAN:** Hazır program seed'i YOK. Tüm rutinler kullanıcı tarafından sıfırdan oluşturulur. (Home dinlenme günü zekası, kullanıcı rutinlerine `scheduledWeekday` atadıkça çalışır; atama yoksa "bugün antrenman planlı değil".)
- **S-3 ✅ KALDIR:** V1'e özgü kişisel alanlar üründen çıkar (kneeStatus, energy, isDeload, isPosture, isArm).
- **S-4 ✅ HAYIR:** Sakatlık/kişiselleştirme yok — genel ürün.

### Genel kitle dönüşünün diğer etkileri (Antrenman dışı, takip edilecek)
- `workout_plan.json` ve Faz 1/2/3 program mantığı kaldırılır → `userProfile.currentPhase`/`currentWeek` Antrenman'da kullanılmaz olur (Home faz satırı yeniden düşünülecek — rutin bazlı).
- Home "dinlenme günü" kartı rutin `scheduledWeekday`'e bağlanır (Faz B).

---

## 8. Kapsam Dışı (V2 Antrenman)

- Süper-set / dev-set gruplama (V2.x)
- Antrenman şablonu paylaşımı / içe aktarma (çoklu kullanıcı yok)
- Video/animasyon form rehberi (içerik üretimi — V3)
- Otomatik progresyon önerisi (yanlış otomasyon riski — ayrı tasarım)
