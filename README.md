# Fit Pack

Sportif gelişimini tek yerde toplayan, AI destekli kişisel fitness asistanı uygulaması. Flutter + Drift + Riverpod.

> **Durum:** V1 prod çalışır; V2 geliştirme — **Beslenme V2 + Premium Cila sprint'i tamam** (ghost değerler, antrenman geçmişi/ön izleme, kilo trend grafiği, son kullanılanlar/dünü kopyala, türetilmiş makro hedefleri).

## Hızlı Bağlantılar

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

# iOS simulator
flutter run -d 92EFAB82-82C1-459D-A925-27DAA867E869
```

## Stack

| Katman | Teknoloji |
|--------|-----------|
| Framework | Flutter 3.x |
| State | Riverpod 2.x |
| DB | Drift (SQLite) — şema **v2** (migration'lı), V2'de SQLCipher |
| Routing | go_router |
| Grafikler | fl_chart |
| Beslenme | OpenFoodFacts (`http`) + barkod (`mobile_scanner`) |
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

## Test Cihazı

- **Android (primary):** SM A075F (ID: `R96YB00XJPB`)
- **iOS sim:** iPhone 17 Pro Sim (`92EFAB82-82C1-459D-A925-27DAA867E869`)
- **AVD:** MemoRush_Test

## Git

- **GitHub:** `anox2077/fit-pack` (private)
- **Sahip:** Samet Orhan

## Lisans

Şu an private, V3 public release zamanı karar verilecek.
