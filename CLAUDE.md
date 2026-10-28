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
- **GitHub:** `BS18-Production/fit-pack` (public)
- **Package:** `com.sametorhan.fit_pack` · minSdk 26 · şema: `app_database.dart` → `schemaVersion`
- **Ana cihaz:** iPhone 17 (gerçek, iOS 26.6, ID `00008150-000214C02E03C01C`)
  — Samet'in günlük telefonu, üretim verisi. Ücretli Apple Developer hesabı
  (2026-10-28, Team `DQBCHYZUU7`) → imza 1 yıl. **Dağıtım: TestFlight**
  (iç grup "Ben"); aşağıdaki `ipa` + `altool` komutu. **`flutter install`
  KULLANMA** — önce uygulamayı kaldırır, yerel veri ve gönderilmemiş senkron
  kuyruğu silinir (2026-10-04'te bir silme kaybedildi). Kablolu yerinde
  güncelleme gerekirse: `devicectl` komutu.
- **Test cihazı:** SM A075F (Android, ID `R96YB00XJPB`)

> **Devir (2026-10-29):** Ana geliştirme Codex'e geçti. Güncel ve tam kurallar
> **[AGENTS.md](AGENTS.md)**'de (Claude hafızası oraya taşındı); açık işler
> **[collab/devir-2026-10-29.md](collab/devir-2026-10-29.md)**. Bu dosya ile
> çelişirse AGENTS.md geçerlidir.

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

## Paralel Oturumlar ve Codex (ÖNCE OKU)

Aynı anda birden çok Claude oturumu ve Codex çalışabilir. İşe başlamadan
**[collab/README.md](collab/README.md) "Paralel Claude oturumları"** bölümünü
ve aktif işler defterini (`/Users/sametorhan/dev/fit_pack/collab/aktif-isler.md`)
oku; kendi satırını ekle, kilitli alanlara sahibi varsa dokunma.

Codex aynı projede çalışır. Yazışma `tools/collab.sh codex <konu> "<mesaj>"`
ile; kurallar, rol dağılımı ve worktree kuralı **[collab/README.md](collab/README.md)**.

## Sık Komutlar

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # tablo/DAO değişince
flutter analyze                                             # 0 uyarı hedefi
flutter test
flutter run -d R96YB00XJPB                                  # Android test cihazı
# iPhone (ana) — TestFlight: önce pubspec build numarasını (+N) artır; ASC_KEY_ID/ASC_ISSUER_ID ~/.zshrc
flutter build ipa --release && xcrun altool --upload-app --type ios -f build/ios/ipa/fit_pack.ipa --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
# iPhone (ana) — kablolu, yerinde günceller (TestFlight dışı acil yol)
flutter build ios --release && xcrun devicectl device install app --device 00008150-000214C02E03C01C build/ios/iphoneos/Runner.app
```

## Kritik Hatırlatmalar

- **Migration:** Şema değişince `schemaVersion` artır + `onUpgrade` adımı +
  migration testi **aynı commit'te**. Yıkıcı migration YASAK (ADR-007). Detay:
  CONVENTIONS §3.
- **Tarih aralığı sorguları** daima `[start, end)` — bkz. CONVENTIONS §3.
- **Rota adresleri** `AppRoutes`'tan — ham string yazma, bkz. CONVENTIONS §4.
- **Yazmadan sonra** ilgili tüm okuma provider'larını `invalidate` et, bkz.
  CONVENTIONS §2.
