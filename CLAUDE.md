# Fit Pack — Claude Code Talimatları

> **⚠️ HER OTURUMDA ÖNCE OKU:** Bu projede kod yazmadan önce
> **[CONVENTIONS.md](CONVENTIONS.md)** dosyasını oku ve kurallarına uy.
> Zorunludur — klasör yapısı, state yönetimi, kalıcılık, navigasyon, hata
> yönetimi ve "bitti" tanımı orada. Kurallara aykırı kod önerme.

## Proje Nedir

Fit Pack — Samet'in kişisel fitness takip uygulaması (antrenman + beslenme +
vücut ölçümü + ilerleme). Türkçe arayüz, şu an tek kullanıcı (Samet pilot).
Flutter · Drift (SQLite, lokal) · Riverpod · GoRouter · fl_chart · Supabase
(opsiyonel bulut yedek).

- **Yol:** `/Users/sametorhan/dev/fit_pack`
- **GitHub:** `anox2077/fit-pack` (private)
- **Package:** `com.sametorhan.fit_pack` · minSdk 24 · şema v8
- **Test cihazı:** SM A075F (Android, ID `R96YB00XJPB`)

## Oturum Başında Oku (bu sırayla)

1. **[CONVENTIONS.md](CONVENTIONS.md)** — kod standartları (ZORUNLU).
2. **[PROJECT_STATE.md](PROJECT_STATE.md)** — projenin canlı durumu.
3. **[NEXT_TASKS.md](NEXT_TASKS.md)** — sıradaki işler (iş sırası ve durumu
   için doğruluk kaynağı; uygulamanın ne yaptığını kod + doğrulama belirler).
4. **[CODE_REVIEW.md](CODE_REVIEW.md)** — kod incelemesi bulguları + batch durumu.

## Çalışma Kuralları (Samet'in tercihleri)

- **İzin sorma, direkt çalıştır** (`--dangerously-skip-permissions` modu gibi).
- **Kısa ve net cevaplar.** Hitap kullanma ("kanka" deme); samimi ama hitapsız.
- **Kısaltmaları aç:** PRD, DAO, RPE, TDEE vb. — açılım + Türkçe anlam yaz.
- **Önce dokümantasyon, sonra kod:** ölçüt işin **etkisi** — veri yapısı,
  hesap/senkron/silme/yedekleme, geri dönüşü pahalı karar ya da birden çok
  özelliği bağlayan kural varsa önce tasarım dokümanı (CONVENTIONS §7b).
  Doküman "Karar özeti" ile başlar. Diğer işlerde problem + beklenen davranış
  + doğrulama yöntemini yazmak yeter.
- **Kod değişince emülatörde/cihazda çalıştır**, görsel doğrula.
- **Oturum sonu:** PROJECT_STATE / NEXT_TASKS / README güncelle.

## Sık Komutlar

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # tablo/DAO değişince
flutter analyze                                             # 0 uyarı hedefi
flutter test
flutter run -d R96YB00XJPB                                  # cihazda çalıştır
```

## Kritik Hatırlatmalar

- **Migration:** Şema değişince `schemaVersion` artır + `onUpgrade` adımı +
  migration testi **aynı commit'te**. Yıkıcı migration YASAK (ADR-007). Detay:
  CONVENTIONS §3.
- **Tarih aralığı sorguları** daima `[start, end)` — bkz. CONVENTIONS §3.
- **Rota adresleri** `AppRoutes`'tan — ham string yazma, bkz. CONVENTIONS §4.
- **Yazmadan sonra** ilgili tüm okuma provider'larını `invalidate` et, bkz.
  CONVENTIONS §2.
