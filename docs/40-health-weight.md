# 40 — Sağlık entegrasyonu Faz 1b: akıllı tartıdan kilo

> **Durum:** Taslak, incelendi (§6 — Codex kotası dolu, inceleme Claude-2) ·
> Samet kararı bekliyor (§5). Kod yok.
> **Tarih:** 2026-10-11 · **Sahip:** Claude-2 · **İnceleyen:** Codex
> **İlgili:** [docs/39 — adım](39-health-steps.md) · araştırma raporu §3, §7
> ([FitPack Sağlık Verisi Entegrasyonu](https://claude.ai/code/artifact/47047c15-7754-46fb-87df-294b300de472))

---

## 0. Karar özeti

**Ne değişecek.** Akıllı tartının Apple Sağlık'a / Health Connect'e yazdığı
**kilo ve vücut yağ oranı** Fit Pack'e kendiliğinden gelir. Elle kilo girmek
gerekmez; Ana Sayfa'daki son kilo, kilo eğilimi, haftalık değerlendirme, TDEE
(Toplam Günlük Enerji Harcaması) ve yorum katmanı (docs/36) bu değerleri kullanır.

**Neden.** Samet akıllı tartı kullanıyor. Sık ölçüm kilo eğilimini güvenilir
yapar; docs/36'daki kilo yorumu ≥2 ölçüm ve ≥14 gün istiyor, tartı bunu
kendiliğinden sağlar.

**Asıl risk ve çözümü.** Aynı gün hem elle hem tartıdan kilo gelirse bugünkü
hesaplar **satır başına** ortaladığı için haftalık ortalama kayar ve "tek
ölçüm trend değildir" koruması aşılır (Codex incelemesi). Çözüm: hesaplar tek
bir **"kullanılacak kilo serisi"**nden okur — **günde bir değer, elle giriş
kazanır**.

**Önerilen yol (A):** tartı ölçümleri **ayrı, yalnız cihazda duran** bir
tabloda (`health_samples`) tutulur. `BodyDao`'ya **yeni** bir sorgu eklenir
(`getEffectiveWeights`): elle girilenlerle tartıyı birleştirip günde tek değer
döndürür. Hesap yapan dört yer (Ana Sayfa son kilo + eğilim, panolar, haftalık
değerlendirme, TDEE) bu sorguya geçer. Mevcut üç sorgu **değişmez** — vücut
ölçümü ekranı satırları `id` ile siliyor; birleşik seri o sorgulardan dönseydi
tartı satırına "sil" denince başka tablodan aynı numaralı elle ölçüm silinirdi
(§6 bulgu 1).

*Elenen (B):* tartı ölçümünü mevcut `body_measurements` tablosuna "kaynak"
kolonuyla yazmak. Tek tablo daha basit görünür ama tablo Supabase'e
senkronlanıyor: yeni kolon = **sunucu göçü + senkron değişikliği**, sağlık
verisi buluta çıkar (rapor §7–8'e aykırı) ve iki cihaz aynı ölçümü iki kez
içe aktarabilir.

**Gerçek veriye etkisi.** Mevcut elle girilmiş ölçümler **değişmez**, buluta
gidişleri aynı kalır. Yeni tablo yalnız yerel; silinirse Sağlık'tan yeniden
okunur (iOS'ta sınırsız geçmiş, Android'de son 30 gün). Şema v15 → v16
(yeni tablo, yıkıcı değil — ADR-007). Senkron koduna dokunulmaz (§6 bulgu 2).

## 1. Kurallar

| # | Kural | Neden |
|---|---|---|
| W-1 | Okunan türler: `WEIGHT`, `BODY_FAT_PERCENTAGE`. Başka tür yok | En az veri; BMI ve yağsız kütle hesaplanır, içe alınmaz (rapor §3) |
| W-2 | Her örnek platform kimliğiyle (`externalId` = HealthKit örnek UUID'si / Health Connect kayıt kimliği) **tek** tutulur; tekrar okuma kopya üretmez | Yeniden okuma ve öne gelişte tazeleme |
| W-3 | **Fit Pack'in kendi yazdığı** kayıtlar okunurken elenir (kaynak uygulama = Fit Pack) | Yankı (Faz 2'de Fit Pack Sağlık'a yazmaya başlarsa) |
| W-4 | Kullanılacak seri: **gün başına tek kilo**. O gün **kilosu dolu** elle giriş varsa onun **en son kaydedileni**; yoksa tartının **o günkü ilk** (sabah) ölçümü | Elle giriş bilinçli kayıt (MacroFactor ile aynı); aynı gün ikinci elle giriş düzeltme sayılır; yalnız bel çevresi girilmiş satır tartıyı engellemez (§6 bulgu 3) |
| W-5 | Yağ oranı aynı kurala **ayrı** uyar (kilosu olan satır yağ oranı içermeyebilir). iOS yüzdeyi 0–1 kesir verir → ×100 (§6 bulgu 5) | Tek doğruluk kaynağı, tek birim |
| W-6 | Tartı ölçümü Fit Pack'te **silinmez, gizlenir** (gizlenen `externalId` defteri); Sağlık'taki kaydı kullanıcı Sağlık uygulamasından siler | Fit Pack başkasının verisini silmez |
| W-7 | `health_samples` senkron listelerinde **hiç yok** (`syncPushOrder`'a eklenmez, senkron kolonu/tetikleyicisi yok); hesap değişiminde `account_switch.dart` açıkça siler (docs/39 `HealthPrefs.clear` gibi) | Rapor §7: buluta gitmez. Fotoğraf kalıbı (`syncRemoteExcluded`) tetikleyici ve mezar taşı üretiyor (§6 bulgu 2) |
| W-8 | Dışa aktarma (CSV) yalnız elle girilenleri içerir | Sağlık verisi dışarı çıkmaz (docs/39 S-7) |
| W-9 | İlk bağlanışta geçmiş: iOS son 90 gün, Android 30 gün (ek "geçmiş" izni istenmez) | 8 haftalık yorum tabanı için yeterli; en az izin |
| W-11 | Kiloyu okuyan reaktif sağlayıcılar `watchTables` listesine `healthSamples`'ı da ekler | İçe alma sonrası ekran kendiliğinden tazelenir (CONVENTIONS §2) |
| W-10 | Vücut ölçümü ekranında tartı satırı kaynak simgesiyle görünür ("Sağlık · <uygulama>"); düzenlenemez, gizlenebilir | Kullanıcı neyin nereden geldiğini görür |

## 2. Uygulama (onaydan sonra)

1. **Şema v16** (şema kilidi gerekir — şu an asistan işinde): `health_samples`
   (id, `externalId` UNIQUE, tür, değer, birim, `measuredAt`, kaynak uygulama,
   `importedAt`, `hidden`), `onUpgrade` adımı + göç testi aynı commit'te.
2. `step_source.dart` yanına `body_source.dart` (W-1, W-3) + içe alma servisi
   (W-2, W-9); docs/39'daki gibi öne gelişte çalışır.
3. `BodyDao.getEffectiveWeights` (W-4, W-5) + saf birleştirme fonksiyonu
   (birim testli). Hesap yapan sağlayıcılar buna geçer; saf motorlar
   (`weekly_review`, `interpretWeightTrend`) girdi tipi değişmeden sentetik
   satır alır — **asistan dalı da `insights/`e dokunduğu için Claude-1 ile
   sıra konuşulur**. Vücut ölçümü ekranı: grafik birleşik seriden, liste elle
   girilenler + tartı satırları ayrı (W-10).
4. Ekran: Ayarlar → Sağlık'a "Kilo ve yağ oranı" anahtarı (ayrı izin), vücut
   ölçümü ekranında kaynak simgesi + gizle (çeviri kilidi gerekir).

## 3. Doğrulama

- Birim: W-2 (aynı örnek iki kez → tek satır), W-4 (elle + iki tartı aynı gün
  → elle; yalnız tartı → ilk), W-3, W-7 (senkron kuyruğuna satır girmez).
- Göç testi v15 → v16, mevcut ölçümler aynı.
- Mevcut testler: haftalık değerlendirme, kilo eğilimi, yorum katmanı yeşil.
- iPhone: tartı ölçümü Sağlık'ta görünür → Fit Pack'te aynı gün aynı değer;
  elle giriş yapınca o gün elle değer kullanılır.

## 4. Açık riskler

- Tartı uygulaması Sağlık'a geç yazarsa (ör. tartı uygulaması açılmadan) Fit
  Pack o günü elle girilmemiş sanabilir → "son okuma" saati görünür.
- Birden çok tartı uygulaması aynı ölçümü yazarsa farklı `externalId` ile iki
  örnek gelir → W-4 yine günde tek değer seçer, sorun olmaz.

## 5. Samet'ten gereken kararlar

1. [ ] Yol A (ayrı yerel tablo, buluta gitmez) — önerilen. B istenirse sunucu
   göçü + senkron işi ve KVKK etkisi ayrıca yazılır.
2. [ ] Aynı gün kuralı: **elle giriş kazanır** (aynı gün birden çok elle
   girişte **en son kaydedilen**), yoksa **sabah (ilk) tartı ölçümü** — uygun
   mu? Not: bu, yalnız elle giriş yapanlar için de küçük bir değişiklik — bugün
   aynı gün iki elle giriş haftalık ortalamaya iki kez giriyor.
3. [ ] Hangi tartı / uygulama? (ör. Withings Health Mate, Xiaomi Zepp Life,
   Eufy) — Sağlık'a kilo ve yağ oranı yazıyor mu, Samet kontrol etsin.
4. [ ] Şema kilidi asistan işinde (Claude-1). Faz 1b asistan birleşince mi
   başlasın, yoksa kilit sırası değişsin mi?

## 6. İnceleme (2026-10-11, Claude-2 — Codex kotası 21:52'ye kadar dolu)

1. **Kritik — yanlış satır silme:** `body_metrics_screen.dart:151` listeyi
   `getAllMeasurements`'tan alıp `deleteMeasurement(m.id)` ile siliyor. İlk
   taslaktaki "üç sorgu birleşik seri döndürsün" yolu, tartı satırına başka
   tablonun `id`'sini taşırdı → aynı numaralı **elle ölçüm silinirdi**. Düzeltme:
   üç sorgu değişmez; yeni `getEffectiveWeights` (§0, §2.3).
2. **Senkron sızıntısı:** `syncRemoteExcluded` (`sync_columns.dart:126`) tabloyu
   yalnız gönderimden çıkarır; tablo `syncPushOrder`'da kaldığı için tetikleyici
   kurulur (`app_database.dart:188`), silmede mezar taşı yazılır
   (`sync_columns.dart:349`). Düzeltme: tablo senkron listelerinde hiç yok,
   hesap değişiminde açıkça silinir (W-7). Senkron kilidi gerekmez.
3. **Kilosuz elle satır:** ölçüm formu yalnız bel çevresiyle kaydedebiliyor
   (`body_dao.dart:15`). "Elle giriş kazanır" yalnız **kilosu dolu** satır için
   geçerli olmalı (W-4).
4. **Tazelenmeme:** kilo okuyan sağlayıcılar yalnız `bodyMeasurements`'ı
   izliyor (`home_providers.dart:32,48`, `body_metrics_screen.dart:28`) →
   içe almadan sonra ekran eski kalırdı (W-11).
5. **Yağ oranı birimi:** paket iOS'ta `HKUnit.percent()` kullanıyor
   (`SwiftHealthPlugin.swift:232`) → değer 0–1 kesir; Health Connect yüzde
   verir. Normalize edilmeli; cihazda doğrulanacak (W-5).
6. **Dal çakışması:** haftalık değerlendirme ve yorum motoru (`insights/`)
   asistan dalında da değişiyor; Faz 1b'nin sağlayıcı değişikliği asistan
   birleştikten sonra yapılmalı (§5.4).

Doğrulanan, sorun olmayanlar: paket her örnek için tekil kimlik veriyor
(iOS `sample.uuid`, Health Connect `metadata.id`) → W-2 uygulanabilir;
kaynak uygulama (`sourceId`) okunabiliyor → W-3 uygulanabilir; dışa aktarma
ham sorguyla kalır → W-8 kendiliğinden sağlanır.
