# 40 — Sağlık entegrasyonu Faz 1b: akıllı tartıdan kilo ve yağ oranı

> **Durum:** Samet kararları alındı (2026-10-11, §5) → uygulanıyor.
> **Tarih:** 2026-10-11 · **Sahip:** Claude-2 · **İnceleyen:** Codex (kota
> 21:52'ye kadar dolu; ilk inceleme Claude-2, §6)
> **İlgili:** [docs/39 — adım](39-health-steps.md) ·
> [docs/41 — KVKK / GDPR uyumu](41-privacy-compliance.md) · araştırma raporu
> ([FitPack Sağlık Verisi Entegrasyonu](https://claude.ai/code/artifact/47047c15-7754-46fb-87df-294b300de472))

---

## 0. Karar özeti

**Ne değişecek.** Tartı uygulamalarının Apple Sağlık'a / Health Connect'e
yazdığı **kilo ve vücut yağ oranı** Fit Pack'e kendiliğinden gelir, elle
girilen ölçümlerle **aynı tabloda** (`body_measurements`) durur ve **buluta
senkronlanır** (Samet kararı). Kullanıcı aynı gün istediği kadar elle kilo
girebilir; hesaplar günde tek değer kullanır.

**Tek tek tartı markası yok.** Withings, Renpho, Xiaomi (Zepp Life / Mi
Fitness), Eufy, Garmin, Fitbit, Samsung Health… hepsi ölçümü telefonun sağlık
deposuna yazar; Fit Pack depoyu okuyarak **hepsinden** alır. Markaların kendi
bulut API'leri gereksiz: her biri ayrı hesap, ayrı sözleşme, ayrı gizlilik
yükü demek. Depoya yazmayan bir uygulama varsa kullanıcı o uygulamanın
"Apple Sağlık / Health Connect ile eşitle" ayarını açar.

**Yalnız gerekli veri (KVKK md. 4 / GDPR md. 5 "veri en aza indirme").**
Okunan türler: kilo, yağ oranı. BMI ve yağsız kütle bunlardan hesaplanır;
kas kütlesi, su oranı, kemik kütlesi gibi tartı tahminleri **alınmaz** —
Fit Pack'te bunları kullanan özellik yok.

**Açık rıza kapısı.** Sağlık verisi buluta gittiği için içe aktarma
kullanıcının **açık rızası** olmadan başlamaz (KVKK md. 6, GDPR md. 9/2-a);
rıza kaydedilir, geri alınabilir. Ayrıntı docs/41.

**Seçilen yol (B):** `body_measurements`'a üç kolon: `source` (`manual` /
`health`), `external_id` (platform örnek kimliği), `source_app` (ör. "Withings").
Senkron kendiliğinden taşır. *Elenen (A, ilk taslak):* yalnız cihazda duran
ayrı tablo — Samet bulutu seçti.

**Gerçek veriye etkisi.** Mevcut satırlar `source = manual` olur (NULL =
manual), değerleri değişmez. Şema v16 → v17 (yalnız kolon ekleme, ADR-007);
Supabase'e aynı kolonları ekleyen göç (önce Dev, üretim Samet onayıyla).

## 1. Kurallar

| # | Kural | Neden |
|---|---|---|
| W-1 | Okunan türler yalnız `WEIGHT`, `BODY_FAT_PERCENTAGE` | Veri en aza indirme |
| W-2 | İçe alınan satırın `uid`'i platform kimliğinden **türetilir** (UUID v5: `health:<platform>:<örnek kimliği>`) | İki cihaz aynı örneği alırsa aynı `uid` → sunucu üzerine yazar, kopya olmaz (senkron zaten `uid` ile upsert yapıyor). Yerelde `external_id` tekil |
| W-3 | Fit Pack'in kendi yazdığı örnekler okunurken elenir (kaynak = Fit Pack paket kimliği) | Faz 2'de yazma başlarsa yankı olmasın |
| W-4 | Hesaplar için **günde tek kilo**: o gün kilosu dolu elle giriş varsa **en son kaydedilen** elle giriş; yoksa günün **ilk** tartı ölçümü | Kullanıcı aynı gün düzeltme girebilir (Samet: "belki yanlış girdi"); sabah ölçümü tutarlı; satır başına ortalama haftalık değeri kaydırıyordu |
| W-5 | Yağ oranı aynı kurala **ayrı** uyar. iOS yüzdeyi 0–1 kesir verir → ×100 | Tek kural, tek birim |
| W-6 | İçe alınan satır **düzenlenemez**; silinince `hidden = true` olur (senkronlanır), yeniden içe alınmaz | Tekrar içe almada geri gelmesin; kaynak veriyi kullanıcı Sağlık'ta yönetir |
| W-7 | İçe aktarma ancak **açık rıza** kaydı varsa çalışır; rıza geri alınınca içe aktarma durur ve kullanıcıya "içe alınan ölçümleri sil" seçeneği sunulur | KVKK md. 6, GDPR md. 7/3 (rızayı geri almak vermek kadar kolay) |
| W-8 | İlk bağlanışta geçmiş: son 90 gün (Android'de platform sınırı 30 gün; ek geçmiş izni istenmez) | 8 haftalık yorum tabanı; en az izin |
| W-9 | Kiloyu okuyan reaktif sağlayıcılar içe almadan sonra kendiliğinden tazelenir (aynı tablo → `watchTables` değişmez) | CONVENTIONS §2 |
| W-10 | Vücut ölçümü ekranında içe alınan satır kaynak simgesiyle görünür ("Sağlık · Withings") | Kullanıcı neyin nereden geldiğini görür |
| W-11 | Dışa aktarma (CSV/JSON) içe alınan satırları **kaynak kolonuyla** içerir | GDPR md. 20 taşınabilirlik: kullanıcının verisi eksiksiz |

## 2. Uygulama

1. **Şema v17:** `body_measurements` + `source`, `external_id`, `source_app`,
   `hidden` (hepsi nullable / varsayılanlı); `external_id` için tekil indeks;
   `onUpgrade` + göç testi aynı commit'te. Senkron kolon listeleri
   (`sync_columns.dart`) gerekiyorsa güncellenir.
2. **Supabase göçü:** aynı dört kolon (Dev'de uygulanır + pgTAP/SQL testi);
   üretime Samet onayıyla.
3. **Rıza:** docs/41 §3 — rıza kaydı (`user_profile`'a `health_consent_at`,
   `health_consent_version`; senkronlanır = rıza kanıtı).
4. `body_source.dart` (W-1, W-3, W-5) + içe alma servisi (W-2, W-6, W-8);
   öne gelişte çalışır (docs/39 S-9).
5. **Günde tek değer** saf fonksiyonu (W-4, W-5) + kilo okuyan hesap
   sağlayıcıları bunu kullanır: son kilo, kilo eğilimi, haftalık
   değerlendirme, TDEE, yorum katmanı. Vücut ölçümü listesi tüm satırları
   gösterir (W-10), grafik günde-tek seriden çizer.
6. Ekran: Ayarlar → Sağlık → "Kilo ve yağ oranı" (rıza ekranıyla), vücut
   ölçümü ekranında kaynak simgesi, içe alınanı silince gizleme.

## 3. Doğrulama

- Birim: W-2 (aynı örnek iki kez / iki cihaz → tek `uid`), W-4 (elle + iki
  tartı aynı gün → son elle; yalnız tartı → ilk; yalnız bel girilmiş elle
  satır tartıyı engellemez), W-5 birim dönüşümü, W-6, W-7 (rıza yokken içe
  alma çağrısı hiçbir satır yazmaz).
- Göç testi v16 → v17; mevcut ölçümler aynı, `source` = manual.
- Senkron: içe alınan satır Dev Supabase'e gider, ikinci cihaz aynı satırı
  çeker, kopya yok.
- iPhone: tartı ölçümü Sağlık'ta → Fit Pack'te aynı gün aynı değer.

## 4. Açık riskler

- Tartı uygulaması Sağlık'a geç yazarsa o gün Fit Pack'te geç görünür → "son
  okuma" saati.
- İki tartı uygulaması aynı tartıyı ayrı örnek olarak yazarsa iki satır gelir;
  W-4 hesapta günde tek değer seçer, listede iki satır görünür (gizlenebilir).

## 5. Samet'in kararları (2026-10-11)

1. ✅ İçe alınan kilo **bulutta** tutulur.
2. ✅ Kullanıcı aynı gün birden çok kez kilo girebilir; hesapta **son elle
   giriş** geçerli, elle giriş yoksa **ilk tartı ölçümü**.
3. ✅ **Tüm tartı uygulamaları** — sağlık deposu üzerinden (marka API'si yok);
   gerekli veri = kilo + yağ oranı.
4. ✅ Hemen başla (asistan main'e birleşti, kilitler boş).
5. ✅ Her şey **KVKK** (Türkiye) ve **GDPR** (global) uyumlu → docs/41.

## 6. İnceleme notları (ilk taslak, A yolu — 2026-10-11)

İlk taslağın incelemesinde bulunanlardan B yolunda geçerli kalanlar:
- Yağ oranı birimi (iOS kesir) → W-5.
- Yalnız bel girilmiş elle satır tartıyı engellememeli → W-4 "kilosu dolu".
- Haftalık değerlendirme satır başına ortalıyor → W-4 hesap sağlayıcılarında.
- Vücut ölçümü ekranı `id` ile siliyor → B yolunda içe alınan satır aynı
  tablodadır, `id` doğrudur; silme W-6'ya göre gizlemeye çevrilir.
