# Fit Pack — Sıradaki İşler (NEXT_TASKS)

> **Son güncelleme:** 2026-05-18
> **Bağlı doküman:** [PROJECT_STATE.md](PROJECT_STATE.md), [docs/04-roadmap.md](docs/04-roadmap.md)

Bu doküman, Samet'in **bir sonraki session'da neye dokunacağını** netleştirir. Roadmap büyük resmi, bu doc bugün/yarın yapılacakları gösterir.

---

## 🎯 BUGÜN / YARIN

### 1. ⏳ Bekleyen Doc Okumaları (Samet'in işi — engelleyici DEĞİL)

6 dokümanın hepsi hazır. Samet okuyup değişiklik notu alır; istediğinde ilgili doc v1.x bump edilir. Kod paralel başlayabilir.

- [ ] `docs/01-product-spec.md` (PRD v1.1) — final onay
- [ ] `docs/02-architecture.md` (Mimari v1.0) — onay
- [ ] `docs/03-ux-flows.md` (UX v1.0) — onay
- [ ] `docs/04-roadmap.md` (Roadmap v1.0) — onay
- [ ] `docs/05-testing.md` (Test v1.0) — onay
- [ ] `docs/06-workflow.md` (Workflow v1.0) — onay

### 2. ✅ Dokümanlar TAMAM (6/6)

- [x] `docs/05-testing.md` — Test stratejisi ✅ (2026-05-18, v1.0 taslak)
- [x] `docs/06-workflow.md` — DevOps workflow ✅ (2026-05-18, v1.0 taslak — 18 bölüm)

> **Dokümantasyon fazı bitti.** Sıradaki = KOD.

---

## ✅ Sprint N — Beslenme V2 TAMAM (2026-05-18)

Pilot geri bildirimi (P-1/2/3, [docs/07-nutrition-v2.md](docs/07-nutrition-v2.md)). **Commit'lendi + push'landı** (2026-05-20, `9ceb223`, dal `feat/sprint-0.1-migration`).

- [x] **T-050** Şema **v1→v2**: `foods.defaultPortionGrams` + `unitLabel` (nullable, additive) · `app_database.dart` schemaVersion 2 + onUpgrade · `drift_schema_v2.json` · migration_test tripwire→2 + `migrations/migration_v1_to_v2_test.dart` (SchemaVerifier lossless)
- [x] **T-051** `turkish_foods.json` 111 yemek porsiyon/birim · `seed_manager` map · **+ `_backfillFoodUnits()`** (mevcut DB'lerde birimi NULL local yemekleri JSON'dan doldurur, idempotent)
- [x] **T-052** DAO `updateFood` + `foodLogCount` + `deleteFood` (FK guard)
- [x] **T-053** Add-food sheet adet/g birim seçici + custom dialog birim alanları
- [x] **T-054** `foods_screen.dart` (Yemekler: listele/ara/değer gör/custom düzenle-sil) + `/foods` route + Settings "Beslenme → Yemekler" girişi
- [x] **T-055** `http` 1.6.0 + `mobile_scanner` 7.2.0 · `OpenFoodFactsService` · `BarcodeScanScreen` · `barcode_flow` (lokal→OFF→ekle) · add-food + Yemekler barkod butonu · AndroidManifest CAMERA/INTERNET
- [x] **T-056** Doğrulama: `flutter analyze` **0** · `flutter test` **18/18** (SchemaVerifier lossless göç, OFF mapping 5, birim dönüşüm, DAO FK guard, seed bütünlük) · APK build (mobile_scanner native dahil) · **gerçek v1 cihaz DB'sinde** (111 yemek/6 log/3 antrenman) v1→v2 göç + backfill **kayıpsız**, launch logcat temiz

> **Doğrulama kanıtı:** emülatörde gerçek bir v1 DB (`user_version=1`) yerleştirildi → uygulama açıldı → `user_version=2`, foods'a 2 kolon eklendi, 111 yemek + 6 log + 3 session **aynen korundu**, backfill sonrası 111/111 yemekte birim (Yumurta 1 adet=50g, Ekmek 1 dilim=30g, Avokado 1 adet=150g, Tavuk 1 porsiyon=150g). Crash/exception yok.

**Bilinen sınır:** Barkod tarama gerçek kamerayla emülatörde test edilemedi (kamera + laggy emülatör); veri yolu (OFF mapping, lokal eşleme, ekleme) unit-test ile kanıtlandı, UI derleniyor + native build geçiyor. Samet gerçek cihazda (R96YB00XJPB) barkod akışını deneyince teyit edilecek.

---

## 🚀 SONRAKİ MILESTONE: Aşama 0 — Sağlamlaştırma

Doc'lar bitince **kod yazımı başlıyor.** Aşama 0 Sprint 0.1 task'ları:

> **⚠️ COMMIT'SİZ ÇALIŞMA SETİ** (2026-05-18, dal `feat/sprint-0.1-migration` — Samet "temel otursun" dedi, commit bekliyor):
> - **T-001 yapıldı:** `app_database.dart` MigrationStrategy (onUpgrade iskeleti + beforeOpen FK pragma, schemaVersion 1 kilit), `drift_schemas/drift_schema_v1.json`, `mocktail` dep, `test/helpers/test_database.dart`, `test/data/migration_test.dart` (3 test yeşil). analyze 0 uyarı.
> - **CRASH FIX (2026-05-18):** `InheritedElement.debugDeactivated: _dependents.isEmpty` çökmesi → kök neden: `Skeleton` widget'ı `AnimatedBuilder` (sürekli `repeat()`) içinde `context.colors` (=`Theme.of`) okuyordu; hızlı mount/unmount'ta Theme'e dangling dependent. Düzeltme: tema okuması `build()`'e taşındı + RepaintBoundary. Ayrıca `PredictiveBackPageTransitionsBuilder` kaldırıldı (route-transition riski). Emülatörde tüm ağır yollar stres-test edildi (pull-refresh skeleton döngüsü, hızlı sekme, modal sheet, session, push/pop) → temiz. **Bilinen kalan minor:** ekran-kaynaklı SnackBar sekme değişince hemen kapanmıyor (düşük öncelik).
> - **UI/UX overhaul yapıldı (2026-05-18):** Tasarım sistemi "Pro" (Indigo/Teal) — `core/theme/app_colors.dart` (ColorScheme dark+light + AppSemanticColors ThemeExtension), `app_dimens.dart` (spacing/radius/icon token), `app_theme.dart` tam M3 yeniden yazıldı, `app.dart` light+dark+system. `shared/widgets/app_state_views.dart` (EmptyState/ErrorState/Skeleton shimmer/confirmAction). 7 ekran + app_shell geçirildi: **57 hardcoded renk → 0**, spacing token, empty/error/loading state, input validation (range), undo (nutrition), confirm dialog (delete), ≥48pt dokunma hedefi, Semantics/tooltip. Bonus V1 fix: `main.dart` `initializeDateFormatting('tr_TR')`. **Doğrulama:** analyze 0 · test 4/4 · emülatörde (dark+light) tüm ekranlar + workout/nutrition akışları DB yazımıyla test edildi, exception/overflow yok.
> - **Bonus fix (R-01 smoke'da yakalandı):** `main.dart`'a `initializeDateFormatting('tr_TR')` eklendi — V1'de eksikti, home faz kartı `LocaleDataException` ile çöküyordu. Emülatörde doğrulandı (R-01 GEÇTİ, ekran temiz).
> - DB/FK/migration tarafı emülatörde tertemiz — `beforeOpen` FK pragma + seed sorunsuz.

### Sprint 0.1 (Migration + Şifreleme) — Hedef: 1 hafta

- [x] T-001: Drift schema 1'de kilit + MigrationStrategy iskeleti ✅ (commit bekliyor)
- [ ] T-002: Mevcut DB'yi yedek alma helper'ı (export to JSON)
- [ ] T-003: `drift_sqlcipher` paketini ekle, LazyDatabase connection güncelle
- [ ] T-004: SecureKeyManager — Android Keystore'dan key oku/üret
- [ ] T-005: `flutter_secure_storage` paketini ekle (Gemini API key için)
- [ ] T-006: V1 DB → şifreli DB migration script'i
- [ ] T-007: Emülatörde V1 → V2 göç testi
- [ ] T-008: Drift migration integration test örneği

### Sprint 0.2 (Error Handling + Kalan TODO'lar) — Hedef: 1 hafta

- [ ] T-010: `core/errors/app_exception.dart` sealed class hiyerarşisi
- [ ] T-011: Global error handler
- [ ] T-012: `shared/widgets/error_card.dart` + `empty_state.dart`
- [ ] T-013: Snackbar tabanlı UI hata gösterimi
- [ ] T-014: Input validation (kg/rep/RIR/stres)
- [ ] T-015: Workout history screen — TODO bitir
- [ ] T-016: ✅ README gerçek doc (bu session yapıldı)
- [ ] T-017: Emülatörde V1 akışları regression test

---

## 🛑 Paralel Yarıda Kalan (Daha Sonra)

**Antrenman walk-through:** Cuma (Upper B) + Pazar (Lower B) günleri yazılmadı. Samet "sıralı" seçti → PRD bitince tek dosya halinde 4 günlük program çıkacak. Detay: `~/.claude/projects/-Users-sametorhan/memory/project_fitness.md`

---

## 💡 Sonraki Session Açılışında Yapılacaklar

1. `PROJECT_STATE.md`'yi oku — projenin canlı durumu
2. `NEXT_TASKS.md`'yi oku — Sprint N (Beslenme V2) **TAMAM**
3. **Samet'in Beslenme V2 cihaz testi geri bildirimini sor** (R96YB00XJPB'de: birim seçici, Yemekler ekranı, barkod tarama). Sorun varsa öncelik düzeltme.
4. Sorun yoksa **Aşama 0 kalan** (T-002 yedek helper → T-003 `drift_sqlcipher` → T-004 SecureKeyManager → T-006 V1→şifreli göç → T-007/008 test) **veya** Samet'in seçtiği yön.
5. **Commit:** Beslenme V2 commit'lendi + push'landı (`9ceb223`, `feat/sprint-0.1-migration`). PR açılmadı — Samet isterse açılır. Yeni iş yeni commit ister.

---

## 📌 Önemli Notlar

- **Roadmap tarihleri esnek.** Aşama 0 başlangıcı 13 Mayıs hedefiyle planlandı ama dispatch ile mobile çalışma süreci uzadı, kayma kabul.
- **Doc-first tamamlandı** — 6/6 doc hazır, artık kod fazı (Samet'in kuralı: önce dokümantasyon, sonra kod → doc bitti).
- **İletişim:** samimi + direkt + hitapsız (memory: feedback_communication_tone).
- **Test cihazı:** `R96YB00XJPB` (SM A075F Android). Kod değişince emülatörde otomatik çalıştır.
