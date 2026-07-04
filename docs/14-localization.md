# 14 — Çok Dilli Destek (Localization / i18n)

> **Durum:** Faz A (arayüz) uygulanıyor · Faz B (içerik) tasarlandı, ertelendi
> **Karar tarihi:** 2026-07-05
> **İlgili:** [CONVENTIONS.md](../CONVENTIONS.md), [PROJECT_STATE.md](../PROJECT_STATE.md)

Uygulama İngilizce + Türkçe olacak. **İngilizce öncelikli** (template/kaynak
dil İngilizce; desteklenmeyen tüm cihaz dilleri İngilizce'ye düşer).

**Kısaltmalar:** i18n = internationalization (uluslararasılaştırma), l10n =
localization (yerelleştirme), ARB = Application Resource Bundle (Flutter'ın
çeviri dosya formatı, JSON tabanlı), ICU = çoğul/cinsiyet kuralları için
mesaj biçimi standardı.

---

## Karar Özeti

| Konu | Karar |
|------|-------|
| Yaklaşım | Flutter resmi `gen-l10n` (flutter_localizations + ARB) |
| Diller | `en` (template), `tr` |
| Varsayılan | **Cihaz dilini takip et**; desteklenmeyen → `en` fallback |
| Elle seçim | Ayarlar → Görünüm → Dil (Sistem / English / Türkçe), kalıcı |
| Kalıcılık | `shared_preferences` `app_locale` (tema deseninin aynısı) |
| Tarih/sayı | Aktif locale'e bağlı (`tr_TR` sabiti kaldırılır) |

---

## Faz A — Arayüz (bu tur)

Kullanıcıya görünen tüm **arayüz metinleri** (menü, buton, başlık, boş hal,
uyarı/hata/snackbar, ayarlar, onboarding) ARB anahtarlarına taşınır.

### Altyapı
1. `pubspec.yaml`: `flutter_localizations` (sdk) + `flutter: generate: true`.
2. `l10n.yaml`: `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`,
   `output-class: AppL10n`, `nullable-getter: false`.
3. `lib/l10n/app_en.arb` (kaynak) + `lib/l10n/app_tr.arb` (çeviri).
4. `lib/core/i18n/locale_provider.dart` — `localeProvider` (Notifier<Locale?>;
   `null` = cihazı takip et). Kalıcı.
5. `app.dart`: `MaterialApp.router`'a `localizationsDelegates`,
   `supportedLocales: [en, tr]`, `locale: ref.watch(localeProvider)`.
   `en` listede ilk → fallback İngilizce.
6. `main.dart`: `initializeDateFormatting` hem `en` hem `tr` için.
7. `lib/core/i18n/formatting.dart` — `context.localeName` (`'en'`/`'tr'`) +
   locale-duyarlı `dateFmt`, `numFmt` yardımcıları. Kod içindeki
   `DateFormat(..., 'tr_TR')` ve `NumberFormat.decimalPattern('tr_TR')`
   bunlarla değişir.

### Metin taşıma (screen-by-screen)
Erişim: `AppL10n.of(context).<key>`. Parametreli metinlerde ICU placeholder
(`{count}`) ve gerekli yerde `plural`. Anahtar adı: `alanEkran_amac`
(camelCase), ör. `home_streakTitle`, `common_save`, `nutrition_addFood`.

**Sıra (görünürlük önceliği):**
1. Alt navigasyon + rota başlıkları
2. Ayarlar (dil seçici burada)
3. Ana Sayfa
4. Beslenme
5. Onboarding
6. Antrenman (en büyük — çok ekran)
7. İlerleme / Vücut / Aktivite
8. Dışa Aktar / Bulut / Yedekleme
9. Ortak widget'lar + dialog'lar

**"Bitti" tanımı (Faz A):** `flutter analyze` 0 · tüm testler geçer · her iki
dilde emülatörde ana akışlar ekran görüntüsüyle doğrulanır · kalan hardcode
Türkçe UI metni yok (yorumlar hariç).

---

## Faz B — İçerik (ertelendi, çok turlu)

Veritabanı içeriği çift dilli. Şu an **karışık**: egzersizler
`exercises_extended.json` (free-exercise-db, İngilizce) + küratörlü Türkçe
seed; besinler `turkish_foods.json` (Türkçe).

### Zorluklar
- ~1000+ egzersiz adı + adım talimatları çevrilmeli.
- Küratörlü Türkçe egzersizlerin İngilizcesi gerekli.
- Türkçe besinlerin İngilizcesi gerekli.
- **Kullanıcının girdiği** özel egzersiz/besin/rutin tek dilli kalır (otomatik
  çeviri yok) → resolver fallback ile tek-dilli ada düşer.

### Tasarım
- Şema **v9**: `Exercises`/`Foods`/`Routines` tablolarına `nameEn`, `nameTr`
  (nullable) + talimat için `instructionsEn`/`instructionsTr`. Mevcut `name`
  korunur (kullanıcı verisi + fallback). Migration lossless + test.
- Seed asset'leri çift dilli JSON'a dönüştürülür (çeviri LLM batch + gözden
  geçirme; lisans: free-exercise-db public domain, çeviri türev serbest).
- `localizedName(exercise, locale)` resolver: `nameXx ?? name`.
- OpenFoodFacts ürünleri: API'nin döndürdüğü dilde kalır (dinamik).

Faz B ayrı PRD + roadmap kalemi olarak NEXT_TASKS'e işlenir.

---

## Konvansiyon (CONVENTIONS'e eklenecek)

- **Yeni kullanıcı-metni hardcode edilmez** → ARB anahtarı açılır (`en`+`tr`).
- Anahtar adı `alanEkran_amac` camelCase; parametre ICU placeholder.
- Tarih/sayı biçimi daima aktif locale (`context.localeName`), asla `'tr_TR'`.
