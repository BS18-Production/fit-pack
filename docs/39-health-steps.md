# 39 — Sağlık entegrasyonu Faz 0–1: adım

> **Durum:** Faz 0 ✅ · Faz 1 ✅ (2026-10-11) — iPhone 17'de doğrulandı: adım
> sayısı Sağlık uygulamasıyla tutarlı (Samet). Sıradaki: Faz 1b (tartıdan kilo).
> **Tarih:** 2026-10-11 · **Sahip:** Claude-2 · **İnceleyen:** Codex
> (`collab/threads/saglik-entegrasyonu.md`)
> **Araştırma raporu:** [FitPack Sağlık Verisi Entegrasyonu](https://claude.ai/code/artifact/47047c15-7754-46fb-87df-294b300de472)

---

## 0. Karar özeti

**Ne değişecek.** Fit Pack telefonun sağlık deposundan (iOS HealthKit,
Android Health Connect) **yalnız günlük adım sayısını okur** ve Ana Sayfa'da
tek bir aktivite hücresinde gösterir: bugünkü adım, (varsa) hedefe ilerleme,
dokununca son 7 gün.

**Neden yalnız adım.** Adım hiçbir mevcut hesabı (kalori hedefi, TDEE, kilo
eğilimi, haftalık değerlendirme) değiştirmez; tek başına değer üretir. Kilo
(Faz 1b) ve antrenman yazma (Faz 2) ayrı dokümanla gelir.

**Seçilen yol:** `health` paketi (CARP, pub.dev). *Elenen:* kendi native
kanalımız — iki dilde bakım, ilk sürüm için pahalı.

**Gerçek veriye etkisi.** Yok. Şema değişmez, Supabase'e hiçbir sağlık verisi
gitmez, kalori hedefi değişmez. Adımlar okunduğu anda hesaplanır, bellekte
durur; uygulama silinse de kaynak (Sağlık deposu) yerinde kalır.

## 1. Samet'in kararları (2026-10-11)

1. ✅ Android `minSdk` 24 → **26** (`health` paketinin alt sınırı; Health
   Connect zaten Android 9+ / API 28).
2. ✅ Önce Android; iOS denensin, ücretli Apple hesabı gerekirse ayrı karar.
   **Faz 0 sonucu: gerekmiyor** — ücretsiz Personal Team profili
   `com.apple.developer.healthkit` ve `healthkit.background-delivery`
   içeriyor (derlenen `Runner.app`, profil 2026-10-18'e kadar).
3. ✅ Faz 1 = yalnız adım, cihazda, kalori hedefine etkisiz. Adım hedefi
   **boş başlar**; kullanıcı Ayarlar'dan koyar.
4. Samet Apple Watch + akıllı tartı kullanıyor → Faz 1b (kilo) ve Faz 2
   (antrenman yazma) sonraki sırada.

## 2. Kurallar

| # | Kural | Neden |
|---|---|---|
| S-1 | Günlük adım = platformun **tekilleştiren toplam** sorgusu (iOS `HKStatisticsCollectionQuery` `.cumulativeSum`, Android `aggregate(COUNT_TOTAL)`); ham kayıt toplanmaz | Telefon + saat aynı yürüyüşü sayar; platform çözer (paket kaynağında doğrulandı) |
| S-2 | Gün penceresi `[00:00, ertesi gün 00:00)`, takvim günüyle (CONVENTIONS §3) | Gece yarısı / yaz saati |
| S-3 | **0 adım = "veri yok"**, ortalamaya girmez; hücre "0" yazmaz | iOS izin reddini bildirmez, reddedilen izin 0 döner; taşınan telefonda gerçek 0 günü pratikte olmaz |
| S-4 | 7 günün hepsi veri yoksa durum `noData`: "Sağlık izinlerini kontrol et" | Reddi boş günden ayıramıyoruz; kullanıcıyı izne yönlendir |
| S-5 | Hedef yoksa ilerleme çizgisi yok; yalnız sayı | Varsayılan hedef dayatılmaz (karar 3) |
| S-6 | Adım hiçbir hesaba (kalori hedefi, TDEE, antrenman kalorisi, yorum katmanı) girmez | Çift sayım (rapor §6–7) |
| S-7 | Hiçbir sağlık değeri Supabase'e, analitiğe ya da dışa aktarmaya gitmez | KVKK, Apple 5.1.3, Play sağlık politikası |
| S-8 | Bağlantı tercihi ve hedef `SharedPreferences`'ta; hesap değişiminde silinir | Şema kilidi gerekmez; hesaplar arası sızma yok |
| S-9 | Okuma: uygulama açılınca ve öne gelince; arka plan yok | Faz 1 için yeterli; arka plan izni = ek izin |
| S-10 | İzin **ihtiyaç anında** istenir (hücredeki "Bağlan"), açılışta değil; önce Fit Pack'in tek ekranlık açıklaması | Apple/Google yönergesi, güven |

## 3. Uygulama

- `lib/features/health/step_stats.dart` — saf hesap (S-2…S-5): gün
  pencereleri, 7 günlük seri, ortalama, hedef ilerlemesi. Birim testli.
- `lib/features/health/step_source.dart` — `StepSource` arayüzü + `health`
  paketli gerçekleme (S-1). Testlerde sahte kaynak.
- `lib/features/health/health_prefs.dart` — bağlantı tercihi + hedef (S-8).
- `lib/features/health/step_providers.dart` — Riverpod sağlayıcıları.
- Ekran (Ana Sayfa hücresi, Ayarlar bağlantı satırı, izin açıklaması) —
  **çeviri kilidi** (Codex) bırakılınca.
- Yapılandırma (Faz 0): Android `READ_STEPS`, Health Connect `queries`,
  izin gerekçesi `intent-filter`, `ViewPermissionUsageActivity` takma adı,
  `FlutterFragmentActivity`; iOS `Runner.entitlements` (HealthKit),
  `NSHealthShareUsageDescription` (TR/EN). Yazma izni açıklaması yok (Faz 2).

## 4. Doğrulama

- Birim: S-2…S-5 (`test/features/step_stats_test.dart`).
- Cihaz (Samet onayıyla kurulum): iPhone'da bugünkü adım Sağlık uygulamasındaki
  sayıyla **aynı**; tekrar açınca büyümüyor; izin kaldırılınca hücre bağlantı
  durumuna dönüyor. Samsung'da Health Connect yoksa Play'e yönlendiriyor.
- Ağ: hiçbir sağlık değeri Supabase isteğinde yok (S-7).
