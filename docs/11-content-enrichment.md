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

---

## 12. Tur 2 — İçerik araştırması + iki kareli form gösterimi (2026-07-25)

Samet "antrenman ve beslenme içeriğini zenginleştirelim, önce araştıralım,
karar vermeden her seçeneği konuşalım" dedi. Bu bölüm o turun bulgularıdır.
**Beslenme tarafı henüz ele alınmadı** (ayrı tur).

### 12.1 Envanter — sorun "veri az" değil

| | Durum |
|---|---|
| Gömülü hareket | **814** (`exercises_extended.json`) · DB'de toplam **1015** |
| Metadata (kas/ekipman/seviye/ölçüm) | %96–100 dolu, kaliteli |
| Adım adım talimat | %99.5 dolu — **tamamı İngilizce** |
| Türkçe içerik | **sıfır** (ne isim ne talimat) |
| Video / animasyon | yok |

### 12.2 ⚠️ D-1 kararı GERÇEKLE UYUŞMUYORDU → resmen tersine çevrildi

§7'deki D-1 *"Gömülü/offline, ~800 statik resim APK'ya gömülür"* diyordu.
**Kod bunu hiç yapmadı:** görseller çalışma anında jsDelivr CDN'inden çekiliyor,
`assets/`'te tek görsel yok (0/814 diskte). Yani doküman bir yıl boyunca
gerçeği yanlış anlattı.

**Samet kararı (2026-07-25): CDN doğru olan, D-1 iptal.**
> *"Offline çalışmalı gibi bir gayemiz yok. İnterneti olan kullansın. Premium
> uygulama yapıyorum, gereksiz şeylerle APK'yı şişiremem."*

Ölçüm bu kararı destekliyor: ortalama görsel 52 KB → hepsini gömmek hareket
başına 1 görselle **~41 MB**, başlangıç+bitiş çiftiyle **~83 MB**.

### 12.3 Kaynak araştırması (2026-07-25)

| Kaynak | Hacim | Lisans | Bulgu |
|---|---|---|---|
| free-exercise-db (mevcut) | 873 | Public domain | Temiz, sorunsuz |
| **wger** | 828 | CC-BY-SA 4.0 | ⚠️ **Türkçe çeviri yalnız 31** (3286 çevirinin içinde). 360 görsel / **78 video**. §3'teki *"wger ile Türkçe"* planı ve D-5'in *"Türkçe görünen ad ileride wger ile"* notu **yanlış varsayıma dayanıyordu** |
| ExerciseDB | 11.000+ | karışık — aşağıda | Üç ayrı şey aynı adı taşıyor |
| MoveKit | 206 (3D animasyon) | ticari | ₺1.699 tam kütüphane, kas vurgulu varyant |
| Exercise Animatic | ~1.600–2.000 | non-exclusive B2B | $359; **4K green screen** → işlenmesi gerekir, drop-in değil |

**ExerciseDB'nin üç ayrı hâli** (karıştırılması kolay):
1. `github.com/ExerciseDB/exercisedb-api` — AGPL-3.0 ama **içinde 2 dosya var**
   (`LICENSE` + `README`, 32 KB), 25 Kas 2025'ten beri tek commit yok. Açık
   kaynak değil, açık kaynak kılığında tanıtım sayfası. 519 yıldız bir README'ye.
2. `exercisedb.dev` — ücretsiz playground API. *"Production için önerilmez"*
   cümlesi buna ait. SSL sertifikası süresi dolmuş durumda.
3. `exercisedb.io` — asıl ticari ürün: **tek seferlik veri seti satın alma**,
   JSON+GIF indirilir, ticari kullanım serbest, **self-host** edilir, runtime
   bağımlılığı yok. Fiyat öğrenilemedi (Cloudflare TR IP'sini engelliyor).
   Satın alınacaksa **medya haklarının kimde olduğu yazılı sorulmalı**
   (Samet'in "telif riski varsa girme" kuralı).

### 12.4 ✅ Yapılan: iki kareli form gösterimi (ücretsiz)

**Bulgu:** free-exercise-db her harekette **iki kare** tutuyor — `0.jpg`
başlangıç, `1.jpg` bitiş pozisyonu, **873/873 harekette ikisi de var**.
Uygulama yalnız `0.jpg`'yi gösteriyordu; hareketi anlatan iki kareden biri
kullanılmıyordu.

`lib/shared/widgets/exercise_demo.dart` → `ExerciseDemoImage`: iki kareyi
dönüşümlü oynatır. Ek lisans yok, ek maliyet yok, ek indirme hareket başına
tek görsel. `ExerciseHowToContent` içinde durduğu için **hem hareket detayı
hem aktif seans sheet'i** birden kazandı.

**Tasarım notu — geçiş süresi:** ilk sürüm 350 ms çapraz geçişti; emülatörde
iki gövde üst üste binip **çift pozlama hayaleti** oluşturdu. İki kare aynı
kamera açısından çekildiği için arka plan sabit, yalnız gövde değişiyor;
gerçek egzersiz GIF'leri de dissolve değil sert kesme kullanır. **160 ms**'ye
indirildi — kesmenin sertliğini alır, hayalet göze çarpmaz.

- Kare üretimi saf fonksiyon (`frameUrl`) + **6 test** — yanlış adres üretilirse
  animasyon sessizce ölür, kimse fark etmezdi.
- Erişilebilirlik: sistemde animasyon kapalıysa döngü çalışmaz, tek kare kalır.
- Özel (kullanıcı eklediği) hareketlerde `imagePath` boş → widget çizilmez.
- analyze 0 · test **209/209** · emülatörde iki poz da görsel doğrulandı.

### 12.5 Hâlâ AÇIK karar: Türkçe talimat

814 hareket × ~5 adım ≈ 4000 cümle, tamamı İngilizce. Seçenekler konuşuldu,
**karar verilmedi**: (a) toplu AI çevirisi, (b) AI + Berna gözden geçirmesi,
(c) yalnız en çok kullanılan 100–150 hareket (uzun kuyruk İngilizce kalır),
(d) hiç çevirme. wger üzerinden gelmesi **mümkün değil** (§12.3).

D-5 (hareket ADI İngilizce kanonik kalsın) tartışılmadı, geçerli kabul edildi —
salon dili zaten İngilizce.

### 12.6 Önerilen sıra
Önce ücretsiz derinleşme (iki kare ✅ → Türkçe talimat kararı), **sonra**
gerekirse satın alınan animasyon. Gerekçe: mevcut içeriğin tam hâli görülmeden
yapılan satın alma, neyin eksik olduğunu bilmeden yapılmış olur.

### 12.7 Form görseli kapsama onarımı (aynı gün)

**Bulgu (Samet'in sorusu üzerine ölçüldü):** 1015 hareketin **814'ünde (%80)**
görsel vardı — ama eksik olan 201, tam da salonun **temel hareketleriydi**:
Barbell Back Squat, Conventional/Romanian/Sumo Deadlift, Front Squat, Leg
Press, Overhead Press, Bent-Over Barbell Row… Yani 814 görece bilinmeyen
hareketin görseli varken squat ve deadlift'in yoktu. İstenenin tam tersi.

**Kök sebep iki katmanlı:**
1. **D-2** ("ad eşleşmesinde mevcut kazanır") küratörlü çekirdek listeyi
   korudu; o satırlarda `imagePath` yok ve isimler kaynakla tutmuyordu
   ("Barbell Back Squat" ≠ "Barbell Squat") → zenginleştirme hiç uğramadı.
2. **`_duplicateVariants` dedupe'u** bunu büyütmüştü: free-exercise-db'den
   gelen **görselli** satırı silip küratörlü **görselsiz** satırı koruyordu
   (7 hareket, aralarında Bent-Over Barbell Row).

**Otomatik eşleştirme DENENDİ ve REDDEDİLDİ.** Üç turda da yanlış hareket
eşledi: `Barbell Back Squat → Barbell Hack Squat`, `Bench Press → Guillotine
Bench Press`, `Smith Machine Squat → Smith Machine Pistol Squat`. Skor
fonksiyonu bunun anlam problemi olduğunu göremiyor. **Yanlış form görseli,
görsel olmamasından daha kötüdür** — kullanıcı yanlış hareketi öğrenir.

**Çözüm:** elle onaylanmış `assets/data/exercise_image_map.json` (**97 eşleme**)
+ `SeedManager._backfillExerciseImages()` (idempotent; yalnız `image_path`
boş ve `is_custom = 0` satırlara yazar) + `seedVersion` 1 → **2** (artırılmazsa
mevcut kurulumlarda hiç çalışmaz, M-04 dersi). Backfill **her iki seed yolunda
da** çağrılır — sıfırdan kuran kullanıcı da kapsanır.

**Sonuç:** görselli hareket **814 → 911** (%80 → **%90**), ve daha önemlisi
temel lift bandı artık kapsanıyor. **5 yeni test** (biçim, kaynak tutarlılığı,
idempotentlik, özel harekete dokunmama, temel-lift regresyon bekçisi).

**Kapsanmayan 104** bilinçli bırakıldı: 12 kardiyo + 13 esneme + 23
kalistenik (form görseli anlamsız ya da kaynakta yok) ve **~56 kuvvet
hareketi** — bunlarda free-exercise-db'de sade sürüm yok, yalnız varyant var
(Sumo Deadlift → yalnız "with Bands", Barbell Curl → yalnız grip varyantları).

> 💡 **Satın alma kararına girdi:** kapsanamayan ~56 kuvvet hareketi, ücretli
> bir animasyon kütüphanesinin (MoveKit 206 hareket, ₺1.699) gerçekten değer
> katacağı tek yer. Ücretsiz kaynak buraya kadar getirdi.
