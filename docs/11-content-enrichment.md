# Fit Pack — İçerik Zenginleştirme PRD (Beslenme + Hareket)

> **PRD = Product Requirements Document (Ürün Gereksinim Dokümanı)**
> **Versiyon:** 1.0 (taslak — onay bekliyor)
> **Tarih:** 2026-06-29
> **Sahibi:** Samet Orhan
> **Durum:** Kararlar kesinleşti (D-1..D-5) → uygulama başlıyor (C-1 şema v7'den)
> **Bağlı:** [PROJECT_STATE.md](../PROJECT_STATE.md), [docs/09-workout-v2.md](09-workout-v2.md), [docs/07-nutrition-v2.md](07-nutrition-v2.md)

---

## 1. Problem & Amaç

Uygulamanın iki içerik havuzu var ve ikisi de elle küratörlü, sınırlı:
- **Beslenme:** `turkish_foods.json` → **111 yemek** (elle yazılmış) + barkod için OpenFoodFacts (OFF).
- **Hareket:** `exercises_seed.dart` → **~200 hareket** (İngilizce, resim/talimat YOK).

**Amaç:** Açık ve ücretsiz veri kaynaklarından çekirdeği büyütmek; özellikle (a) **Türk temel gıdalarını** (OFF'un zayıf olduğu jenerik yemekler) ve (b) hareketlere **form görseli + adım adım talimat** eklemek. Kütüphaneyi "liste"den "rehber"e çıkarmak.

**Başarı ölçütü:** Beslenme çekirdeği 111 → ~500+ gıda; Hareket çekirdeği ~200 → ~800 hareket + görsel + talimat. Hepsi **offline** çalışır, lisanslara uygun, mevcut "özel yemek/hareket" akışını bozmadan.

## 2. Best-practice ilkeleri (araştırma — docs research, 2026-06-29)

1. **Hibrit + offline-first:** Gömülü statik seed (çekirdek, internetsiz) + online API (uzun kuyruk) + **cache** (geleni lokal DB'ye yaz).
2. **Seed > canlı çağrı:** Çekirdek kütüphane build-time'da gömülür → hızlı, limitsiz, offline. Uygulama lokal pilot olduğu için bu kritik.
3. **Lisans + atıf:** Açık veri bedava ama şartlı. Ayarlar'a "Açık veri kaynakları" atıf ekranı eklenir.
4. **Veri kalitesi:** Crowdsource (OFF) doğrulama ister; küratörlü seed tercih, kullanıcı düzenlemesi açık kalır (zaten var).
5. **Localization:** Türkçe öncelik — gıda adları Türkçe (TÜRKOMP); hareket adları İngilizce kanonik (mevcut karar), opsiyonel Türkçe görünen ad.

## 3. Seçilen kaynaklar

### Beslenme
- **TÜRKOMP** (Tarım Bak. + TÜBİTAK, ücretsiz, TR+EN): 14 grup, 645 Türk gıdası, 100 bileşen. → **Seed'e eklenecek** (kcal/protein/karb/yağ alınır). Resmî API yok → veri indirilip JSON'a dönüştürülür. Lisans: bedelsiz; yeniden dağıtım şartı teyit edilecek (D-3).
- **OpenFoodFacts** (mevcut): barkodlu market ürünleri için kalır. Lisans ODbL (atıf + share-alike).
- **USDA FoodData Central** (opsiyonel, sonra): online jenerik gıda arama yedeği; ücretsiz anahtar, 1000 istek/saat.

### Hareket
- **free-exercise-db** (yuhonas, **public domain**): ~800 hareket — kas haritası, ekipman, kategori, seviye, mekanik, **statik resim + adım adım talimat**. → **Ana zenginleştirme kaynağı**, JSON gömülür. Lisans derdi yok.
- **wger** (opsiyonel, sonra): online ekstra + Türkçe çeviri (CC-BY-SA).
- **ExerciseDB** (opsiyonel, sonra): animasyonlu GIF — premium dokunuş; GIF lisansı kontrol edilmeli.

## 4. Veri modeli deltası (şema v6 → v7, additive/lossless)

### Exercises tablosu (yeni nullable kolonlar)
| Kolon | Tip | Açıklama |
|-------|-----|----------|
| `imagePath` | text? | Gömülü asset yolu (`assets/exercise_img/...`) **veya** uzak URL (D-1'e göre) |
| `instructions` | text? | Adım adım talimat (JSON array ya da `\n` ayraçlı) |
| `level` | text? | beginner/intermediate/expert (free-exercise-db'den) |
| `force` | text? | push/pull/static (opsiyonel, filtre potansiyeli) |

> `primaryMuscle`, `equipment`, `category`, `muscleGroups` zaten var → free-exercise-db alanları bunlara eşlenir.

### Foods tablosu
- Şema değişmez — `source` (text) zaten var, yeni değer **`'turkomp'`** kullanılır.
- **Opsiyonel (D-4):** `category` kolonu eklenerek (TÜRKOMP 14 grubu) Yemekler ekranında grup filtresi. Additive.

**Migration:** v6→v7 tek adım, tüm yeni kolonlar nullable → lossless. `migration_v6_to_v7_test` + `drift_schema_v7.json` zorunlu (docs/05 kuralı).

## 5. İçerik hattı (pipeline)

1. **Hareket:** free-exercise-db JSON indir → Fit Pack `ExerciseSeedData` formatına dönüştüren tek seferlik script (`tool/import_exercises.dart`) → genişletilmiş seed + resimler `assets/exercise_img/`. Mevcut Türkçe-aranabilir alanlar korunur.
2. **Gıda:** TÜRKOMP verisi indir/çıkar → `turkish_foods.json` formatına map eden script → `turkish_foods_extended.json`. Mevcut 111 elle küratörlü kayıt **öncelikli** (çakışmada elle yazılmış kazanır).
3. **Seed merge mantığı:** `seed_manager` mevcut backfill desenini izler — yeni kurulumda tümünü yükler, mevcut kurulumda eksikleri ekler (idempotent, kullanıcının özel kayıtlarına dokunmaz).

## 6. UX değişiklikleri

- **Hareket detayı:** üstte **form resmi** + "Nasıl yapılır" talimat bölümü (mevcut Geçmiş/Grafik/Rekorlar sekmelerinin yanına).
- **Hareket kütüphanesi:** kart küçük resim önizleme (opsiyonel), seviye rozeti.
- **Yemekler/Yemek Ekle:** daha zengin arama sonucu; (D-4 ile) grup filtresi.
- **Ayarlar:** "Açık veri kaynakları" atıf ekranı (yeni).

## 7. Kararlar (KESİNLEŞTİ — 2026-06-29)

- **D-1 — Hareket görselleri:** ✅ **(a) Gömülü/offline.** ~800 statik resim APK'ya gömülür. Tamamen offline.
- **D-2 — Mevcut seed:** ✅ **(a) Merge.** free-exercise-db üstüne eklenir; elle girilen TR/MacFit makineleri korunur (ad eşleşmesinde mevcut kazanır).
- **D-3 — TÜRKOMP alımı + lisans:** Resmî API yok → siteden indirme/çıkarma. Yeniden dağıtım şartı netleşene kadar **sadece besin değerleri** (olgusal veri) kullanılır + kaynak atıf verilir.
- **D-4 — Foods'a `category` (gıda grubu):** ✅ **Evet.** TÜRKOMP 14 grubu eklenir, Yemekler ekranında grup filtresi.
- **D-5 — Hareket adı dili:** İngilizce kanonik kalır (docs/09 kararı); Türkçe arama kas/ekipman üzerinden zaten çalışıyor. Türkçe görünen ad ileride wger ile.

## 8. Görev kırılımı (kararlar onaylandıktan sonra)

| ID | İş | Tahmin | Şema |
|----|-----|--------|------|
| C-1 | Şema v7: exercises +imagePath/instructions/level/force (+foods.category, D-4) + migration test + drift_schema_v7.json | ~1 sa | v7 |
| C-2 | Hareket import script + free-exercise-db → genişletilmiş seed + resim assetleri | ~2-3 sa | — |
| C-3 | Hareket detayına form resmi + talimat UI; kütüphane kartı önizleme | ~2 sa | — |
| C-4 | TÜRKOMP gıda import script → turkish_foods genişletme + merge (elle kayıt öncelikli) | ~2-3 sa | — |
| C-5 | (D-4) Yemekler grup filtresi | ~1 sa | — |
| C-6 | Ayarlar "Açık veri kaynakları" atıf ekranı | ~30 dk | — |
| C-V | Doğrulama: analyze 0 · migration testi · seed bütünlük testleri · emülatörde 3 senaryo | — | — |

**Önerilen sıra (en yüksek getiri önce):** C-1 → C-2 → C-3 (hareket görsel+talimat) → C-4 (Türk gıdaları) → C-5/C-6.

## 9. Doğrulama planı

- `flutter analyze` 0.
- Migration: gerçek v6 DB → v7 lossless (kullanıcı verisi + özel kayıtlar korunur).
- Seed bütünlük testleri: hareket sayısı ≥ N, her kayıtta geçerli kategori/ölçüm tipi, resim yolu varsa asset mevcut; gıda sayısı ≥ M, makrolar makul aralıkta, isim tekrarı yok (elle kayıt öncelikli).
- Emülatör: (1) kütüphanede yeni hareket + resim + talimat render; (2) Yemek Ekle'de yeni Türk gıdası arama; (3) mevcut kullanıcının özel yemek/hareketi + logları bozulmamış.

## 10. Lisans & atıf

| Kaynak | Lisans | Gereken |
|--------|--------|---------|
| OpenFoodFacts | ODbL | Atıf + (DB dağıtımında) share-alike |
| free-exercise-db | Public domain (Unlicense) | Gerek yok (yine de atıf nazik) |
| TÜRKOMP | Bedelsiz (devlet) | Atıf; yeniden dağıtım şartı teyidi (D-3) |
| wger (ileride) | CC-BY-SA | Atıf + share-alike |

→ Ayarlar > "Açık veri kaynakları" ekranı bu atıfları listeler (Play Store yayını için de gerekli).

## 11. Bilinçli yapılmayanlar (bu tur)

- Animasyonlu GIF (ExerciseDB) — lisans + boyut; ileride premium.
- USDA/FatSecret online entegrasyon — opsiyonel sonraki tur.
- Hareket adlarının tam Türkçeleştirilmesi — wger ile ayrı iş.
- Tarif (recipe) içeriği üretimi — ayrı kapsam.
