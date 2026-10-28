# Fit Pack — Codex Talimatları

> **⚠️ HER OTURUMDA ÖNCE OKU:** Bu projede kod yazmadan önce
> **[CONVENTIONS.md](CONVENTIONS.md)** dosyasını oku ve kurallarına uy.
> Zorunludur — klasör yapısı, state yönetimi, kalıcılık, navigasyon, hata
> yönetimi ve "bitti" tanımı orada. Kurallara aykırı kod önerme.
>
> **Devir (2026-10-29):** Samet projenin ana geliştiricisi olarak Codex'e
> geçti. Claude Code'un oturumlar arası hafızasındaki bütün kurallar bu
> dosyaya ve `~/.codex/AGENTS.md`'ye (yerel, repoya girmeyen ayrıntılar)
> taşındı. Açık işler: **[collab/devir-2026-10-29.md](collab/devir-2026-10-29.md)**.

## Proje Nedir

Fit Pack — Samet'in **kişisel** fitness takip uygulaması (antrenman +
beslenme + vücut ölçümü + ilerleme). Türkçe arayüz, pilot (Samet + birkaç
yakın kullanıcı). Flutter · Drift (SQLite, lokal) · Riverpod · GoRouter ·
fl_chart · Supabase (hesap + senkron).

- **Yol:** `/Users/sametorhan/dev/fit_pack`
- **GitHub:** `BS18-Production/fit-pack` (**public** — anahtar, şifre, kimlik
  numarası repoya yazılmaz; yerel ayrıntılar `~/.codex/AGENTS.md`'de)
- **Package:** Android `com.sametorhan.fit_pack` · iOS `com.sametorhan.fitPack`
  · minSdk 26 · iOS hedefi 15.0 · şema: `app_database.dart` → `schemaVersion`
- **Kişisel proje:** Samet'in iş hayatıyla (şirket, yönetici, müşteri)
  hiçbir bağı yok. Paydaş ve karar mercii yalnız Samet; "X'e sor / ekiple
  hizala / onay al" gibi cümle kurma.

## Oturum Başında Oku (bu sırayla)

1. **[CONVENTIONS.md](CONVENTIONS.md)** — kod standartları (ZORUNLU).
2. **[PROJECT_STATE.md](PROJECT_STATE.md)** — projenin canlı durumu.
3. **[NEXT_TASKS.md](NEXT_TASKS.md)** — sıradaki işler (iş sırası ve durumu
   için doğruluk kaynağı; uygulamanın ne yaptığını kod + doğrulama belirler).
4. **[CODE_REVIEW.md](CODE_REVIEW.md)** — kod incelemesi bulguları.
5. Aktif işler defteri `/Users/sametorhan/dev/fit_pack/collab/aktif-isler.md`
   (git dışı) — kendi satırını ekle, kilitli alana dokunma.

## Çalışma Kuralları (Samet'in tercihleri)

- **İzin sorma, direkt çalıştır** — ama aşağıdaki "onay gerektirenler"de dur.
- **Kısa ve net cevaplar.** Hitap kullanma ("kanka" deme); samimi ama hitapsız.
  Samet geliştirici değil: teknik terimi sade Türkçeyle açıkla.
- **Kısaltmaları aç:** PRD, DAO, RPE, TDEE vb. — açılım + Türkçe anlam yaz.
- **Önce dokümantasyon, sonra kod:** ölçüt işin **etkisi** — veri yapısı,
  hesap/senkron/silme/yedekleme, geri dönüşü pahalı karar ya da birden çok
  özelliği bağlayan kural varsa önce tasarım dokümanı (CONVENTIONS §7b),
  "Karar özeti" ile başlar, Samet onayıyla koda geçer. Diğer işlerde problem
  + beklenen davranış + doğrulama yöntemini yazmak yeter.
- **Kod değişince cihazda/emülatörde çalıştır**, görsel doğrula.
- **Oturum sonu:** PROJECT_STATE / NEXT_TASKS / README güncelle.
- **Uygulama içi yapay zekâ:** Claude API'si önerme (Samet pahalı buluyor).
  Başka ücretli sağlayıcı gündeme gelirse önce fiyat + gizlilik özetle,
  Samet'e sor. Varsayılan: yapay zekâsız (kural tabanlı) çözüm.

### Onay gerektirenler (Samet açıkça demeden yapma)

- `main`'e birleştirme ve `git push`.
- Gerçek telefona kurulum (iPhone, arkadaş telefonları) ve TestFlight'a
  yükleme — görev verilirken açıkça istendiyse tekrar sorma.
- Üretim Supabase'ine her yazma (göç, SQL, fonksiyon). Dev projesi serbest.
- Kalıcı veriyi silen/üzerine yazan her işlem.

## Cihazlar ve Kurulum (kritik — veri kaybı riski)

- **Ana cihaz: Samet'in iPhone 17'si** (iOS 26.x, UDID
  `00008150-000214C02E03C01C`) — günlük telefon, **üretim verisi**.
- **`flutter install` ASLA KULLANMA.** Önce uygulamayı kaldırır → yerel
  veritabanı ve gönderilmemiş senkron kuyruğu silinir (2026-10-04'te bir
  silme bu yüzden buluta ulaşmadan kayboldu).
- **Dağıtım: TestFlight** (2026-10-28'den beri; ücretli Apple Developer
  hesabı, Team `DQBCHYZUU7`, imza 1 yıl). İç test grubu "Ben", otomatik
  dağıtım açık. Komut aşağıda; **her yüklemede `pubspec.yaml` build
  numarası (+N) artar** (Apple aynı numarayı reddeder).
- **Kablolu yerinde güncelleme** (acil yol, veri kalır):
  `flutter build ios --release` +
  `xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app`.
  Debug derlemesi bilgisayarsız açılmaz → release.
- Kurulumdan önce yedek: geliştirme imzalı sürümde
  `xcrun devicectl device copy from --domain-type appDataContainer
  --domain-identifier com.sametorhan.fitPack --source / --destination <klasör>`.
  **TestFlight sürümünde bu çalışmaz** (get-task-allow yok). Yedekler
  `~/fitpack-yedek/`.
- "Uygulama açılmıyor / ulaşılamıyor" → önce imza/TestFlight süresini düşün
  (TestFlight sürümü 90 gün geçerli).
- **Test cihazı:** Samsung SM-A075F (`R96YB00XJPB`, Android 16) — Dev
  derlemesi + Dev test hesabı (Google girişi Dev'de kapalı, e-posta ile).
  Görsel doğrulama ve performans testi burada. `scrcpy` ile yansıtma,
  kablosuz adb (`adb tcpip 5555`, IP yerel dosyada).
- **iOS Simulator:** iPhone 17 (`9A4796B8-F70E-4FBC-8DCE-CB0AD328BC9C`) —
  **Samet'in GERÇEK hesabı açık**, yazılan her şey üretime senkron olur.
  Her dokunmadan sonra ekran görüntüsü al; Kaydet/Ekle/+250 ml/Geri al gibi
  yazan düğmelerin yakınına dokunma; seansı bitirme. Dokunma kalibrasyonu:
  ekran grubunun çerçevesi (`AXGroup`) → `x = gx + px*gw/1206`,
  `y = gy + py*gh/2622`.
- **Android emülatörü** AVD `FitPack`; disk dar → release arm64 APK.
- **Dev derlemesi:** `--dart-define=SUPABASE_URL=https://qecbnrkbordkqeogmevi.supabase.co
  --dart-define=SUPABASE_ANON_KEY=<Dev publishable key>`. Varsayılan derleme
  **üretim** Supabase'i.
- **Yeni iPhone'u imzaya ekleme:** `ios/` içinde
  `xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release
  -destination id=<UDID> -allowProvisioningUpdates -allowProvisioningDeviceRegistration build`.
  Kalıcı yol: TestFlight (iç test App Store Connect kullanıcısı ister; dış
  test ilk sürümde Apple incelemesi).
- **Apple hesabı yetkileri:** Time Sensitive bildirim, HealthKit, Live
  Activity, App Intents imzalanıyor. Push (APNs), iCloud, Sign in with
  Apple artık mümkün ama kurulmadı.
- **Xcode lisansı onaylanmamışsa** git/flutter durur: geçici
  `DEVELOPER_DIR=/Library/Developer/CommandLineTools`, kalıcı çözüm Samet'in
  `sudo xcodebuild -license accept` çalıştırması.

## Paralel Oturumlar

- Her iş **ayrı dal + ayrı `git worktree`** (`../fit_pack-<iş>`); ana
  klasörde (`main`) eşzamanlı kod yazılmaz. Kurallar ve kilit tablosu:
  **[collab/README.md](collab/README.md)**.
- Şema değiştiren işler sıralı (iki dal aynı `schemaVersion`'ı artırırsa
  göç zinciri kırılır).
- Commit'te yalnız kendi dosyalarını açık yolla ekle (`git add -A` yok).
- **İkinci göz:** riskli işte (senkron, hesap, veri göçü, sunucu, bildirim
  planlayıcısı) iş bitince **yeni bir Codex oturumunda salt okuma
  inceleme** iste — aynı oturumun kendi işini incelemesi yetmez. Samet'in
  Claude aboneliği sürerken `tools/collab.sh claude <konu> "<mesaj>"` ile
  Claude'a da yazılabilir.

## Sık Komutlar

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # tablo/DAO değişince
flutter gen-l10n                                            # .arb değişince
flutter analyze                                             # 0 uyarı hedefi
flutter test
python3 tools/check_docs.py                                 # doküman bağlantıları
flutter run -d R96YB00XJPB                                  # Samsung test cihazı
# iPhone (ana) — TestFlight. Önce pubspec build numarasını (+N) artır.
# ASC_KEY_ID / ASC_ISSUER_ID ~/.zshrc'de; anahtar ~/.appstoreconnect/private_keys/
flutter build ipa --release && xcrun altool --upload-app --type ios -f build/ios/ipa/fit_pack.ipa --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
```

## Kritik Hatırlatmalar

- **Migration:** Şema değişince `schemaVersion` artır + `onUpgrade` adımı +
  migration testi **aynı commit'te**. Yıkıcı migration YASAK (ADR-007).
  Detay: CONVENTIONS §3.
- **Tarih aralığı sorguları** daima `[start, end)` — CONVENTIONS §3.
- **Rota adresleri** `AppRoutes`'tan — ham string yazma, CONVENTIONS §4.
- **Yazmadan sonra** ilgili okuma provider'larını `invalidate` et, CONVENTIONS §2.
- **Bildirimler** tek planlayıcıdan geçer (docs/57): yeni bildirim türü
  `lib/features/reminders/reminder_sync.dart` üzerinden aday olarak eklenir,
  doğrudan `scheduleOnce` çağrılmaz.
- **Çeviri:** metin `lib/l10n/app_en.arb` (şablon) + `app_tr.arb`; `.arb`
  dosyasını yeniden biçimlendiren araç kullanma (yalnız ilgili satırı değiştir).
