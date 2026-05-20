# Fit Pack — Beslenme V2 Genişlemesi (Nutrition V2)

> **Doküman versiyonu:** 1.0 (taslak)
> **Tarih:** 2026-05-18
> **Sahibi:** Samet Orhan
> **Durum:** Onaylandı (3 yön sorusu cevaplandı), kod fazında
> **Bağlı doküman:** [01-product-spec.md](01-product-spec.md), [02-architecture.md](02-architecture.md), [03-ux-flows.md](03-ux-flows.md), [04-roadmap.md](04-roadmap.md), [05-testing.md](05-testing.md)

Bu doküman, pilot kullanım sırasında **beslenme akışında çıkan üç gerçek eksiğin** tasarımını tanımlar. Kuralı (önce doküman, sonra kod) izler — kod bu spec'e göre yazılır.

---

## 1. Problem (Pilot Geri Bildirimi)

Samet uygulamayı kullanırken üç sorun bildirdi:

| # | Şikayet | Kök Neden |
|---|---------|-----------|
| P-1 | "Yemekleri neden frontend'den ekliyorsun?" | Yanlış algı + gerçek bir boşluk. Yemekler aslında lokal SQLite `foods` tablosunda (offline-first, `assets/data/turkish_foods.json`'dan tohumlanır, 111 yemek). Ama kullanıcının bunu **görüp yönetebileceği bir yüzey yok** → "frontend'de" hissi. |
| P-2 | "Değerlerini nasıl takip edeceğim?" | Eklenen yemeğin (özellikle custom) kcal/protein/karb/yağ değerlerini gösteren/düzenleten bir ekran yok. |
| P-3 | "Her şey gramajlı değil, adetli olacak" | Loglama sadece gram. "1 avokado, 3 yumurta, 2 dilim ekmek" gibi doğal porsiyon girişi yok. |

---

## 2. Kararlar (Yön Soruları — 2026-05-18)

Samet'e üç yön sorusu soruldu, cevaplar:

| Soru | Karar | Etki |
|------|-------|------|
| Adet/birim modeli | **Her yemeğe varsayılan porsiyon** (Yumurta = 1 adet ≈ 50 g, Ekmek = 1 dilim ≈ 30 g, Avokado = 1 adet ≈ 150 g). Loglarken birim VEYA gram seç, otomatik çevrilir. | DB şema değişikliği + 111 yemeğe porsiyon verisi |
| Değer görme/düzenleme | **Ayrı "Yemekler" ekranı** (Ayarlar'dan). Listele, değerleri gör, custom düzenle/sil, ara. | Yeni ekran + route + DAO update/delete |
| Veri kaynağı | **OpenFoodFacts + barkod ekle** (şimdi). | `http` + `mobile_scanner` paket, servis, kamera izni |

---

## 3. Mimari (P-1 Cevabı — Veri Nerede?)

```
assets/data/turkish_foods.json (111 yemek, build asset)
        │  ilk açılışta SeedManager.seedIfNeeded()
        ▼
  SQLite `foods` tablosu  ◄── custom yemek (isCustom=true)
        │                 ◄── OpenFoodFacts (source='openfoodfacts', barcode dolu)
        ▼
  FoodLogs (foodId FK → foods.id, grams + computed makro snapshot)
```

- Yemekler **kod içinde sabit (hardcoded) değil** — SQLite'ta veri. Offline-first bilinçli mimari karar (ADR-002, PRD §strateji): sunucu yok, internetsiz çalışır, gizlilik.
- Custom + OpenFoodFacts yemekleri **aynı `foods` tablosuna** yazılır; `source` ve `isCustom` alanları kaynağı ayırır. Şema bunu zaten destekliyordu (`barcode`, `source` kolonları V1'den beri var — bu genişleme için tasarlanmıştı).
- "Yemekler" ekranı bu tabloyu kullanıcıya **görünür ve yönetilebilir** kılar → P-1 + P-2 çözümü.

---

## 4. Veri Modeli Değişikliği (P-3)

### 4.1 `Foods` tablosuna eklenen kolonlar

| Kolon | Tip | Null? | Anlam |
|-------|-----|-------|-------|
| `defaultPortionGrams` | REAL | evet | "1 birim" kaç gram (1 adet yumurta = 50). NULL → birim yok, sadece gram. |
| `unitLabel` | TEXT | evet | Birim adı: `adet`, `dilim`, `porsiyon`, `yemek kaşığı`, `su bardağı`, `avuç`. NULL → birim yok. |

**Neden bu model (alternatifler reddi):**
- ✅ Tek varsayılan porsiyon + etiket → en basit şema, en az migration riski, kullanıcının seçtiği model.
- ❌ Yemek başına çoklu birim tablosu → aşırı mühendislik, pilot için gereksiz.
- ❌ Loglamada serbest birim → her seferinde gram girme yükü (kullanıcı reddetti).

### 4.2 Neden FoodLogs değişmiyor

`FoodLogs.grams` **tek doğruluk kaynağı** kalır. Birim sadece bir **giriş/gösterim kolaylığı**: `gram = adet × defaultPortionGrams`. Loglanan kayıt her zaman gram + hesaplanmış makro snapshot tutar → totaller, geçmiş, migration etkilenmez. Bu, değişikliğin yüzeyini ve riskini minimumda tutar.

### 4.3 Migration (schemaVersion 1 → 2)

- İki kolon da **nullable** → tamamen toplamalı (additive) migration: `m.addColumn(foods, foods.defaultPortionGrams)` + `m.addColumn(foods, foods.unitLabel)`.
- Mevcut V1 satırları NULL alır → otomatik "sadece gram" davranışı, **hiçbir veri bozulmaz/silinmez** (ADR-007 yıkıcı migration yasağına uyumlu).
- Kural (Workflow §4, Testing §3.1): `schemaVersion` 2'ye çıkar + `onUpgrade` adımı + `drift_schema_v2.json` snapshot + v1→v2 lossless göç testi **aynı değişiklik setinde**.
- `migration_test.dart` tripwire'ı (`expect(schemaVersion, 1)`) → 2 olarak güncellenir (bilinçli kırılma).
- **Not:** `app_database.dart`'taki "v2 Aşama 1'de gelecek (rir, daily_log...)" notu güncellenir — beslenme genişlemesi ilk gerçek şema değişikliği olur, Aşama 1 v3+ olur. Migration'lar zincirleme uygulanır, sorun değil.

---

## 5. Tohum Verisi (Seed)

`turkish_foods.json` 111 yemeğe `default_portion_g` + `unit_label` eklenir. Kategori sezgisi:

| Kategori (ad anahtar kelimesi) | Birim | Gram |
|-------------------------------|-------|------|
| Yumurta (bütün) | adet | 50 |
| Yumurta Akı / Sarısı | adet | 33 / 17 |
| Ekmek | dilim | 30 |
| Et / tavuk / balık / köfte | porsiyon | 150 |
| Pilav / makarna / bulgur (pişmiş) | porsiyon | 150 |
| Meyve (elma 180, muz 120, avokado 150, portakal 200, kivi 75…) | adet | meyveye özel |
| Kuruyemiş (badem/ceviz/fındık/fıstık) | avuç | 30 |
| Süt / ayran | su bardağı | 200 |
| Yoğurt / çorba | kâse | 200 |
| Zeytinyağı / sıvı yağ | yemek kaşığı | 15 |
| Tereyağı | yemek kaşığı | 10 |
| Sebze (salatalık/domates/biber/patates…) | adet | sebzeye özel |
| Belirsiz / toz / çay-kahve | — | NULL (sadece gram) |

`seed_manager.dart` yeni alanları **nullable** map eder; JSON'da alan yoksa NULL → güvenli.

---

## 6. UX

### 6.1 Yemek ekleme (birim seçici)

```
┌─ Yemek Ekle ──────────────────── ✕ ─┐
│ [Kahvaltı][Öğle][Akşam][Atıştır.]   │
│ 🔍 Yemek ara… (111)   [⌨ özel][▦ barkod]│
│ ──────────────────────────────────  │
│ ▸ Yumurta (Haşlanmış)   155 kcal /100g│
│ ▸ Avokado               160 kcal /100g│
│ ──────────────────────────────────  │
│ ┌ Yumurta (Haşlanmış) ────────────┐ │
│ │ 155 kcal · 100 g                 │ │
│ │ Birim:  [● adet] [ g ]           │ │
│ │   [ − ]   2 adet   [ + ]         │ │  ← adet modu: 1 adet=50g
│ │   ≈ 100 g                        │ │
│ │ [        Ekle        ]           │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

- Yemeğin `unitLabel` varsa: **adet/g toggle**. Varsayılan = adet modu. Adet modunda ± 1 birim; gram = adet × `defaultPortionGrams`; canlı kcal gramdan.
- `unitLabel` yoksa: mevcut sadece-gram davranışı (değişmez).
- Birim yokken eklenen kayıt aynı (gram). Sayfa açık kalır, çoklu ekleme korunur.

### 6.2 Yemekler ekranı (P-1 + P-2)

```
Ayarlar → "Yemekler / Besin veritabanı"

┌─ Yemekler ──────── [▦ barkod] ─┐
│ 🔍 Ara… (111)                   │
│ ───────────────────────────────│
│ Avokado            160 kcal/100g│
│   1 adet ≈ 150 g · P2 K9 Y15    │
│ Ev Omleti  👤      145 kcal/100g│  ← custom, düzenle/sil
│   1 porsiyon ≈ 220 g            │
│ …                               │
└─────────────────────────────────┘
  (+) Yeni yemek
```

- Tüm yemekleri listeler/arar; değerleri (per-100g + porsiyon) gösterir.
- Custom yemek → satıra dokun → düzenle (ad, değerler, birim, porsiyon) / sil.
- Hazır (local) yemek → salt-okunur detay (seed bozulmasın). Düzenleme sadece custom.
- Silme: `food_logs` referansı varsa **engelle + Türkçe bilgi** (FK bütünlüğü; yıkıcı silme yok).

### 6.3 Barkod akışı

```
[▦ barkod] → kamera ekranı → barkod oku
   │
   ├─ foods.barcode eşleşir → yemeği seç (lokal, internetsiz)
   └─ eşleşmez → OpenFoodFacts API
         ├─ bulundu → foods'a ekle (source='openfoodfacts') → seç
         └─ bulunamadı/çevrimdışı → "Bulunamadı, elle ekle" + custom dialog
```

---

## 7. OpenFoodFacts Entegrasyonu

- Paket: `http` (REST), `mobile_scanner` (kamera barkod).
- Servis: `lib/data/services/openfoodfacts_service.dart` → `Future<Food?> fetchByBarcode(String)`.
  - `GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json?fields=product_name,product_name_tr,brands,nutriments`
  - `User-Agent: FitPack/2.0 (sametorhan@gmail.com)` (OFF zorunlu kılar).
  - Eşleme: ad = `product_name_tr ?? product_name ?? brands`; `nutriments['energy-kcal_100g']`, `proteins_100g`, `carbohydrates_100g`, `fat_100g`. Eksik/`status:0` → `null`.
  - Hata/timeout (5 sn) → typed sonuç (null), UI Türkçe mesaj. Çevrimdışı uygulamayı bozmaz (offline-first korunur).
- Android izinleri (AndroidManifest): `CAMERA` + `INTERNET` + `<uses-feature camera required=false>`.
- Gizlilik: yalnızca taranan barkod numarası OFF'a gider; kişisel veri gitmez. Açık veri kaynağı.

---

## 8. Test Planı (Testing §3.1 + §3.x)

| Test | Tür | Doğruladığı |
|------|-----|-------------|
| v1 → v2 lossless göç | migration (kritik) | Eski veri korunur, yeni kolonlar NULL, schemaVersion 2 |
| Birim → gram dönüşümü | unit | 3 adet × 50 g = 150 g, kcal doğru |
| Custom food + porsiyon | unit (mevcut, güncellenir) | Birim alanlarıyla round-trip |
| OFF JSON → Food eşleme | unit (mocktail http) | nutriments parse, eksik alan → null |
| DAO updateFood/deleteFood | unit | Custom güncelle; loglu yemek silinemez |
| Yemekler ekranı + birim seçici | manuel/emülatör | Görsel + akış (laggy emülatör → kritik yollar) |

Kural: migration testi olmadan schemaVersion artışı commit edilemez (mekanik tripwire).

---

## 9. Yapılmayanlar (Bu Genişleme Kapsamı Dışı)

- Tarif (recipe) bazlı birim hesabı — `RecipeItems` tablosu var ama UI sonraya.
- OpenFoodFacts yazma/katkı — sadece okuma.
- Çoklu birim/yemek (sadece 1 varsayılan porsiyon — pilot için yeterli).
- Porsiyon başına otomatik öneri/ML — manuel seed yeterli.

---

## 10. Onay & Versiyon

| Versiyon | Tarih | Değişiklik | Onay |
|----------|-------|------------|------|
| 1.0 (taslak) | 2026-05-18 | İlk spec — pilot beslenme geri bildirimi (P-1/2/3), 3 yön kararı | ✅ Yön onaylı |
