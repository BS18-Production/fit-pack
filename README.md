# Fit Pack

Sportif gelişimini tek yerde toplayan, AI destekli kişisel fitness asistanı uygulaması. Flutter + Drift + Riverpod.

> **Durum:** V1 prod çalışır; V2 geliştirme — **Beslenme V2 + Premium Cila sprint'i tamam** (ghost değerler, antrenman geçmişi/ön izleme, kilo trend grafiği, son kullanılanlar/dünü kopyala, türetilmiş makro hedefleri).

**2026-10-04 tasarım:** Performans Günlüğü — mat kömür, neon lime ve turuncu;
tüm uygulamada ortak tema, yeni Ana Sayfa/enerji-makro kartı ve gerçek
antrenman aktivitesi. Font ve görseller çevrimdışı paketlenir; kayıtlı tema
tercihi korunur. Analiz temiz, 696 test geçti. 2026-10-07'de iPhone'a
Release güncellemesi yüklendi; Samet yeni görünümü onayladı:
[uygulama rehberi ve doğrulama](docs/30-performance-journal-neon.md).

**2026-10-07 ikon:** Samet'in seçtiği neon lime zeminli siyah FP monogram
iOS ve Android başlatıcı kaynaklarına uygulandı. Kaynak, katmanlar ve
yeniden üretme komutları: [ikon rehberi](assets/icon/README.md). Yeni ikon
iPhone'a yüklenen 2026-10-07 Release arşivinde bulunuyor.

**2026-10-08 Android:** Güncel arm64 debug APK derlendi ve imzası/ikon
kaynakları doğrulandı (`build/app/outputs/apk/debug/app-debug.apk`).
FitPack emülatörüne mevcut uygulamanın üzerine yüklendi ve açıldı. Ana
Sayfa ve Antrenman ekranlarında yeni tema/kartlar/gezinme kontrol edildi;
görünür taşma ve güncel süreçte Flutter/AndroidRuntime hatası yok. Tüm kayıt
akışlarının uçtan uca cihaz QA kontrolü ayrıca açık.

**2026-10-08 geri bildirim turu:** kilit ekranında antrenman (iOS Canlı
Etkinlik), Keşfet'te 9 hazır program, yeni antrenman geçmişi (özet + detay),
RPE'li ilerleme önerisi, arşiv görünür, çeşitli öğün bildirimleri, mola sesi
ve bildirimi düzeltmeleri. Şema v14. Ayrıntı: NEXT_TASKS "Geri bildirim turu".

**2026-10-08 Velocity:** FitPack özel vektör ikonları, dolu lime seçili
sekme ve ortak buton görünümü uygulandı. Analiz temiz, 740 test geçti.
Yeni Release arşivi iPhone 17'ye mevcut uygulamanın üzerine yüklendi
(8 Ekim 07:41 arşivi, Device Hub). Telefon görsel kontrolü Samet'te:
[uygulama ve doğrulama](docs/33-velocity-signature-icons.md).

## Beslenme — Sıcak Günlük (2026-10-09)

Tek enerji halkası, sıcak koyu/açık palet, kompakt makrolar ve aç/kapa öğün
günlüğü; mevcut besin kayıt akışları korunur. 742 test, analiz temiz; iPhone 17
simülatöründe kontrol edildi. 9 Ekim 09:50’de Release sürümü gerçek iPhone
17’ye uygulama kaldırılmadan yüklendi; imza, kurulum ve çalışan süreç
doğrulandı. Android APK derlendi; cihaz görsel kontrolünün sınırları
[docs/34](docs/34-nutrition-warm-diary.md) içinde.

## Hızlı Bağlantılar

- **⭐ Geliştirme kuralları (kod yazmadan önce oku):** [CONVENTIONS.md](CONVENTIONS.md)
- **Kod incelemesi raporu:** [CODE_REVIEW.md](CODE_REVIEW.md)
- **Bekleyen iş ve günlük durum:** [PROJECT_STATE.md](PROJECT_STATE.md)
- **Sıradaki görevler:** [NEXT_TASKS.md](NEXT_TASKS.md)
- **Ürün spec (PRD):** [docs/01-product-spec.md](docs/01-product-spec.md)
- **Mimari:** [docs/02-architecture.md](docs/02-architecture.md)
- **UX akışları:** [docs/03-ux-flows.md](docs/03-ux-flows.md)
- **Yol haritası:** [docs/04-roadmap.md](docs/04-roadmap.md)
- **Test stratejisi:** [docs/05-testing.md](docs/05-testing.md)
- **DevOps/workflow:** [docs/06-workflow.md](docs/06-workflow.md)
- **Beslenme V2 (adet/birim, Yemekler, barkod):** [docs/07-nutrition-v2.md](docs/07-nutrition-v2.md)

## Kurulum

```bash
# Bağımlılıklar
flutter pub get

# Drift code generation (tablo/DAO değişince çalıştır)
dart run build_runner build --delete-conflicting-outputs

# Şema değişince: snapshot + migration test helper (Workflow §4, Testing §3.1)
dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/migrations/schema/

# Android emülatörde çalıştır
flutter run -d R96YB00XJPB

# iPhone 17 (ana telefon) — release, yerinde güncelleme (debug bilgisayarsız açılmaz).
# flutter install KULLANMA: önce kaldırır, yerel veri + senkron kuyruğu silinir.
flutter build ios --release && xcrun devicectl device install app --device 00008150-000214C02E03C01C build/ios/iphoneos/Runner.app

# iOS simulator
flutter run -d 92EFAB82-82C1-459D-A925-27DAA867E869
```

## Xcode 27 ile iPhone güncelleme

1. `ios/Runner.xcworkspace` aç → **Product → Archive** (Release).
2. **Xcode → Open Developer Tool → Device Hub** → iPhone → **Info → Apps**.
3. **Add (+)** → arşivdeki `Products/Applications/Runner.app` dosyasını seç.
   Aynı `com.sametorhan.fitPack` kimliğiyle mevcut kurulumun üzerine yüklenir.
4. Uygulamanın sağ tık menüsündeki **Launch** ile açılabilir.

Arşivler `~/Library/Developer/Xcode/Archives/` altında. **Uninstall** ve
**App Container → Replace** kullanılmaz. Xcode 27 cihaz yönetimi artık
Device Hub'da; eski Window → Devices and Simulators menüsü bulunmuyor.
Mevcut eşleştirmeyle ağ üzerinden güncelleme yapılabilir. Device Hub'ın
ekran paylaşımı iOS 27+ ister; iOS 26.6 telefonda görsel kontrol yapılır.

## Stack

| Katman | Teknoloji |
|--------|-----------|
| Framework | Flutter 3.x |
| State | Riverpod 2.x |
| DB | Drift (SQLite) — şema **v10** (migration'lı) + Supabase senkron |
| Routing | go_router |
| Grafikler | fl_chart |
| Beslenme | OpenFoodFacts (`http`) + barkod (`mobile_scanner`) |
| Ses | `audioplayers` — mola sonu geri sayım/bitiş sesi (`assets/sounds/`) |
| AI | Gemini API (switchable) |

Detaylı stack tablosu ve bağımlılıklar için [Mimari Doküman](docs/02-architecture.md).

## Klasör Yapısı

```
lib/
├── core/          # Tema, routing, sabitler, base servis'ler
├── data/          # Drift DB, DAO'lar, seed, data servis'leri
├── features/      # Feature bazlı dikey diller (home, workout, vb.)
└── shared/        # Birden fazla feature'da kullanılan widget'lar
```

## Cihazlar

- **iPhone 17 (ana, gerçek cihaz):** iOS 26.6 (ID: `00008150-000214C02E03C01C`) — günlük kullanım, üretim verisi. Ücretsiz Apple hesabıyla imzalı → 7 günde bir yeniden kurulmalı (`devicectl` ile; `flutter install` veriyi siler).
- **Android (test):** SM A075F (ID: `R96YB00XJPB`)
- **iOS sim:** iPhone 17 · iOS 26.2 (`9A4796B8-F70E-4FBC-8DCE-CB0AD328BC9C`) — Codex incelemesi burada yapılır
- **AVD:** FitPack (`emulator-5554`)

## Git

- **GitHub:** `BS18-Production/fit-pack` (public)
- **Sahip:** Samet Orhan

## Lisans

Şu an private, V3 public release zamanı karar verilecek.
