# Fit Pack — Sıradaki İşler (NEXT_TASKS)

> **Son güncelleme:** 2026-07-04
> **Bağlı doküman:** [PROJECT_STATE.md](PROJECT_STATE.md), [CODE_REVIEW.md](CODE_REVIEW.md), [docs/04-roadmap.md](docs/04-roadmap.md)

---

## 🔍 Kod İncelemesi & Tutarlılık Refactor'u (2026-07-04) — `fix/code-review`

Tam kod denetimi yapıldı → [CODE_REVIEW.md](CODE_REVIEW.md) (bulgular + batch planı orada).

- [x] **Faz 1 — Denetim:** 1 CRITICAL + 6 HIGH + 11 MEDIUM + 9 LOW bulgu, rapor yazıldı
- [x] **Batch 1 — Veri güvenliği:** güvenli geri yükleme (emniyet kopyası + atomik değişim + sürüm kontrolü), kapatılamaz yeniden-başlat diyaloğu, seans/rutin yazımları transaction'lı. analyze 0 · test 96/96
- [x] **Batch 2 — Doğruluk:** H-01 gün sınırı çift sayım, H-02 seans listesi key'leri, H-05 kilo invalidate, M-01 resume routineId, M-10 onboarding, M-11 getSessionById. analyze 0 · test 99/99
- [ ] **Batch 3 — Tazelik & dayanıklılık:** M-02 gece yarısı, M-03 dinlenme sayacı, M-04 açılış seed guard, M-06 ref anti-pattern, L-04
- [ ] **Batch 4 — Temizlik:** M-07 export V2, M-09 ölü kod, L-01/02/03/05/06/08/09
- [ ] **Faz 3 — CONVENTIONS.md + CLAUDE.md güncellemesi**
- [ ] **Samet kararı bekleyen:** H-04 yayın imzası (keystore + targetSdk; telefondaki kurulumu etkiler), M-08 Google girişi (tamamla ya da düğmeyi gizle)

---

## 🔧 Cihaz Geri Bildirimi Düzeltmeleri (2026-06-30) — `fix/active-session-persistence`

Samet Push day'i telefonda yaptı, genel beğendi + bulgular verdi. analyze 0 · test 83/83.
Tasarım notu: [docs/12-session-resilience.md](docs/12-session-resilience.md).

- [x] **#3 (KRİTİK) Aktif seans kalıcılığı** — arka plana alıp dönünce seans sıfırlanıyordu (process kill). Çözüm: seans `shared_preferences`'e canlı taslak olarak yazılır (paused + yapısal değişiklikte), Antrenman ana ekranında **"Devam eden antrenman" banner'ı** ile kaldığın yerden devam (`/workout/active/resume`). Bitir/çıkış taslağı siler. `workout_draft.dart` + `activeDraftProvider`.
- [x] **#3b Ekran uyanık** — `wakelock_plus` ile canlı seansta ekran kapanmıyor.
- [x] **Geçmiş ekranı layout** — hareket adı/setler sıkışıyordu (Samet ekran görüntüsü). Yeniden kuruldu: ad üstte tam genişlik + **numaralı set satırları** (hizalı) + üst **istatistik şeridi** (süre/hacim/set/~kcal).
- [x] **Kalori tahmini** — seans detayında ACSM `MET×3.5×kilo/200×süre` (RPE'ye göre MET 3.5–6.0, kardiyo 7.0). `calorie_estimate.dart`.
- [x] **Tam günlük harcama BMR/TDEE (şema v8)** — Samet onayladı. `user_profile` +birthDate/+gender/+activityLevel (nullable, migration v7→v8 lossless, tripwire 8). Mifflin-St Jeor BMR + aktiflik çarpanı (TDEE). Ayarlar→Vücut'a cinsiyet/doğum tarihi/aktiflik + "Tahmini Günlük Harcama" kartı; onboarding adım 2'ye cinsiyet+doğum tarihi. **Emülatörde gerçek v7→v8 migration + TDEE doğrulandı** (~2871 kcal/gün, kilo 84.7'den). Minor: aktiflik "—" iken TDEE orta (1.55) varsayılanı kullanır.
- [ ] **#2 Aktif seansta "nasıl yapılır"** — talimat/kas haritası/foto şu an sadece kütüphanede. Seans hareket kartına info erişimi eklenecek (veri hazır). **YAPILMADI.**
- [ ] **#1 Duplike hareketler** — free-exercise-db merge'ünde isim çakışması olabilir; dedupe migration. **YAPILMADI** (önce teşhis).
- **Doğrulama:** analyze 0 · test **90/90** · emülatörde release APK: yedekleme (paylaşım sayfası), v7→v8 migration (veri kaybı yok), Settings BMR/TDEE doğrulandı. **Henüz commit edilmedi** (dal `fix/active-session-persistence`, Samet test edip onaylayınca commit). Geçmiş layout fix görseli emülatörde seans verisi olmadığı için yapılamadı → Samet telefonda teyit edecek.

---

## ✅ Geçmişe Dönük Veri Girişi TAMAM (2026-06-29) — `feat/historical-entry`

Tasarım + uygulama: [docs/10-historical-entry.md](docs/10-historical-entry.md). analyze 0 · test 65/65.
- [x] **H-C** kilo/ölçüm tarih seçici (`738c98b`)
- [x] **H-A/H-B** antrenman bitişte tarih + "Geçmiş Antrenman Ekle" akışı + özet etiketi (`752c277`)
- [x] **H-D** geçmiş seans düzenle (tarih) / sil + regresyon testleri (`b620bc2`)
- Emülatörde doğrulandı (backdate DB'de teyit, gelecek-tarih engeli, silme onayı).
- **Ertelendi:** geçmiş seansta tek tek set düzenleme UI'si (sadece tarih+silme yapıldı).
- **PR/merge bekliyor:** dal henüz `main`'e merge edilmedi.

### 🟢 İçerik Zenginleştirme — büyük kısmı TAMAM, `main`'de (2026-06-30)
PRD: [docs/11-content-enrichment.md](docs/11-content-enrichment.md). analyze 0 · test 76/76. Tüm aşağıdakiler `main`'de + GitHub'da.
- [x] **C-1** Şema v7 (exercises +imagePath/instructions/level/force, foods +category) + migration `011d158`
- [x] **C-2** free-exercise-db → 821 yeni hareket → kütüphane **1022 hareket** `4e6e0db`
- [x] **C-3** "Nasıl" sekmesi (talimat + seviye/kuvvet rozeti) `4e6e0db`
- [x] **C-2b çözüldü** Demo fotoğrafı: free-exercise-db (public domain) jsDelivr CDN'den **lazy-load + cache** (gömmedik → APK küçük). 821 harekette. `31f6bd5`
- [x] **Kas haritası** (yeni): MIT `muscle_selector` human_body.svg, kas verisinden renklenir (birincil koyu/ikincil açık), tüm 1022 harekette. `31f6bd5`
- [x] **C-4 (OFF yönü)** Yemek Ekle'de **OpenFoodFacts metin araması** — "Canga" yaz→internetten paketli ürün makrolarıyla. `699004c` (TÜRKOMP scrape'ten vazgeçildi — gov sitesi zor + lisans belirsiz)
- [x] **perf** JSON minify + arm64 obfuscate release APK **27MB** kuruldu (Samet'in telefonu) `76b8dc3`
- [ ] **C-5** Yemekler grup filtresi (foods.category kolonu hazır, UI kaldı)
- [ ] **C-6** Ayarlar "Açık veri kaynakları" atıf ekranı (OFF=ODbL, free-exercise-db=public domain, muscle_selector=MIT)
- [ ] **Açık karar:** barkod kamera tarayıcısını çıkar → ~5MB küçülür (OFF metin araması yedeklediği için). Samet'e soruldu, beklemede.
- **Doğrulama notu:** kas haritası emülatörde doğrulandı; demo fotoğrafı emülatör DNS'i yüzünden yüklenmedi (CDN host'tan 200, gerçek cihazda çalışır) → Samet telefonunda teyit edecek.

### 🔜 Fikir: Adım sayar (pedometer) — Samet sordu (2026-06-29)
Health Connect (Android) / HealthKit (iOS) `health` paketiyle cihazdan günlük adım okuma → aktivite halkası. Lokal (sunucu yok); merkezi/çoklu-kullanıcı toplama = V3. Doc-first gerekir (yeni sensör+izin+veri tipi+şema). Detay konuşuldu, tasarım yapılmadı.

---

## 🎨 Sprint D — Tasarım Reskin (DEVAM EDİYOR)

Claude Design (Apple Fitness vibe + Indigo/Teal). HTML export: `design/code/`. Brief: `docs/08-design-brief.md`.

- [x] **D-01** Manrope fontu (`app_theme.dart`), `app_dimens` (vGapxl_/brPill token)
- [x] **D-02** Şema v4: su takibi (`water_intake` + `waterGoalMl`), migration lossless test 3/3
- [x] **D-03** Ana Sayfa reskin: header (safe-area fix), dinlenme günü zekası, hero ring 196px, su kartı (DB-backed interaktif), Seri+Kilo satırı — emülatörde dark+light doğrulandı
- [ ] **D-04** Antrenman V2 — Hevy/Strong genişleme. **PRD:** [docs/09-workout-v2.md](docs/09-workout-v2.md). Karar: tam geçiş (sadece rutinler), genel kitle, İngilizce hareketler.
  - [x] **Faz A — Hareket Kütüphanesi** (şema v5, 2026-06-21): exercises +equipment/measurementType/primaryMuscle/isCustom/isArchived; ~100 İngilizce hareket seed (5 kategori); backfill (mevcut kuruluma merge); kütüphane ekranı (`/exercises`, arama+kategori+kas filtre, özel hareket, detay sheet, arşiv); Antrenman app bar girişi. analyze 0 · test 36/36 · emülatörde doğrulandı (migration + arama).
  - [x] **Faz B — Rutinler** (şema v6, 2026-06-21): Routines/RoutineExercises tabloları; Antrenman ana ekranı yeniden kuruldu (Boş Antrenman Başlat + Rutinlerim + Yeni Rutin + bu hafta istatistik + Geçmiş); rutin oluşturucu (ad/gün/hareket+hedef set×tekrar/sürükle-sırala); rutin önizleme; Home dinlenme günü artık rutin `scheduledWeekday`'e bağlı; sabit program (workout_plan.json/faz) Home'dan kaldırıldı.
  - [x] **Faz C — Gelişmiş Seans** (şema v6 ortak): aktif seans ekranı (set tablosu KG/tekrar/RPE/✓, set tipleri ısınma/drop/failure, dinlenme sayacı −15/+15/atla, canlı süre, +set/+hareket, PopScope çıkış onayı); antrenman özeti (süre/hacim/set/hareket dökümü).
  - [x] **Faz D — Hareket Detayı + PR** (2026-06-21): hareket detay ekranı 3 sekme (Geçmiş / Grafik=fl_chart e1RM / Rekorlar=Epley 1RM + en ağır set); kütüphane dokunuşu detaya bağlandı; özel hareket arşivleme detayda.
  - **Doğrulama:** analyze 0 · test 38/38 (v5→v6 lossless göç + rutin DAO dahil) · emülatörde landing/builder/aktif seans/kütüphane render + filtreler doğrulandı; yoğun set-tablosu logging gerçek cihazda teyit edilecek.
  - **Migration:** v5→v6 tek adımda (routines + routine_exercises + session routineId/startedAt/endedAt + sets rpe/setType/isComplete/distanceM/durationSec), lossless test geçti.
- [ ] **D-05** Beslenme ekranı reskin
- [ ] **D-06** İlerleme ekranı reskin
- [ ] **D-07** Ayarlar + Onboarding reskin (Onboarding fonksiyon olarak var, görsel reskin gerek)
- [x] **D-08** P-15: uygulama ikonu TAMAM (2026-06-21) — "Yükseliş" Işıyan varyant (koyu radial zemin + ışıyan chevron + teal spark). `flutter_launcher_icons` ile Android legacy+adaptive + iOS tüm boyutlar. Kaynak: `assets/icon/icon_{full,bg,fg}.png` (headless Chrome ile SVG→PNG). Android label "fit_pack"→"Fit Pack". Emülatörde doğrulandı. Konseptler: `design/icon-concepts.html`

### Antrenman V2 — Hevy/Strong seviyesi (tasarım onaylandı, kod büyük iş)
Samet "tam esnek" + 4 loglama özelliği seçti (önceki seans / dinlenme sayacı / RPE+set tipleri / PR+grafik). Mimari: hareket kütüphanesi (kategori+kas+ekipman+ölçüm tipi), rutin oluşturucu, aktif seans (set tablosu), hareket detayı (geçmiş/grafik/PR), antrenman özeti. Şema v5+ gerektirir. Hareket seed listesi (İngilizce, 5 kategori) `docs/08-design-brief.md`'de. **Önce PRD + şema tasarımı (doc-first), sonra kod.**

---

## ✅ Sprint P — Premium Cila TAMAM (2026-06-11)

Claude'un "premium uygulama" analizinden çıkan bulgular. Doğrulama: analyze 0 · test 24/24 (4 yeni: makro türetme, recents, dünü kopyala, son seans sorgusu) · emülatörde tüm akışlar görsel doğrulandı.

- [x] **P-01** Ghost değerler: `WorkoutDao.getLastSessionWithSets` → seans ekranında alan ipuçları (geçen kg/tekrar) + hareket başına "Geçen seans: 60×8 · …" satırı
- [x] **P-02** Seans başlığı `FullA` → "Full Body A" (plan JSON `name`)
- [x] **P-03** PopScope çıkış onayı — set girilmişken geri tuşu "Antrenmandan çık?" sorar
- [x] **P-04** Set ekle / Set çıkar (hareket kartı altında)
- [x] **P-05** `/workout/history` — Antrenman Geçmişi (ExpansionTile: set dökümü + toplam hacim); ölü "yakında" butonu bağlandı
- [x] **P-06** `/workout/preview/:type` — ön izleme (hareketler + geçen seans + Başla); kart dokunuşu artık seansı direkt başlatmıyor
- [x] **P-07** İlerleme: fl_chart kilo trend grafiği (hedef kilo kesikli çizgi, tooltip) + çift CTA → tek FAB
- [x] **P-08** Beslenme: Son kullanılanlar chip şeridi (`getRecentFoods`), "Dünün öğünlerini kopyala" (`copyDayLogs`), karb/yağ hedef türetme (`macro_goals.dart`), `MacroInlineText` renkli P/K/Y (3 ekranda), placeholder temizliği
- [x] **P-09** Ana sayfa: boş haller aksiyona davet (Seri yok → Bugün başlat, kilo yok → İlk kilonu gir; kartlar tıklanır), 7+ gün "Yeniden başlamak için harika bir gün"

### Sprint P+ — Analizden bilinçli ERTELENENLER (sırada önerilen)

- [ ] **P-10** Onboarding akışı (ilk açılışta hedef kişiselleştirme — V2 release öncesi ŞART; profil tablosuna `onboarded` kolonu = şema v3)
- [ ] **P-11** Dinlenme zamanlayıcısı bildirimi (ekran kapalıyken lokal bildirim — `flutter_local_notifications` + izinler)
- [ ] **P-12** Faz/Hafta otomatik ilerleme (yanlış otomasyon > manuel; tasarım gerekiyor)
- [ ] **P-13** Hareket detay sayfası (hedef kas + form ipuçları — içerik üretimi gerekiyor)
- [ ] **P-14** Achievements kararı: V2'de UI yap YA DA tabloyu kaldır (şema v3 ile birleştirilebilir)
- [ ] **P-15** Uygulama ikonu + splash hâlâ varsayılan Flutter logosu — release öncesi marka ikonu (flutter_launcher_icons)
- [ ] **P-16** Isınma seti işaretleme UI (alan `isWarmup` DB'de var, arayüzü yok)

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
2. `NEXT_TASKS.md`'yi oku — Sprint N (Beslenme V2) + Sprint P (Premium Cila) **TAMAM**
3. **Samet'in cihaz testi geri bildirimini sor** (R96YB00XJPB'de: Beslenme V2 + Sprint P yenilikleri — ghost değerler, geçmiş, grafik). Sorun varsa öncelik düzeltme.
4. Sorun yoksa: **Sprint P+** (P-10 onboarding öncelikli) **veya** **Aşama 0 kalan** (T-002 yedek helper → T-003 `drift_sqlcipher` → T-004 SecureKeyManager → T-006 V1→şifreli göç → T-007/008 test) **veya** Samet'in seçtiği yön.
5. **Commit:** Sprint P commit'lendi (`feat/sprint-0.1-migration` dalı). PR açılmadı — Samet isterse açılır. Yeni iş yeni commit ister.

---

## 📌 Önemli Notlar

- **Roadmap tarihleri esnek.** Aşama 0 başlangıcı 13 Mayıs hedefiyle planlandı ama dispatch ile mobile çalışma süreci uzadı, kayma kabul.
- **Doc-first tamamlandı** — 6/6 doc hazır, artık kod fazı (Samet'in kuralı: önce dokümantasyon, sonra kod → doc bitti).
- **İletişim:** samimi + direkt + hitapsız (memory: feedback_communication_tone).
- **Test cihazı:** `R96YB00XJPB` (SM A075F Android). Kod değişince emülatörde otomatik çalıştır.
