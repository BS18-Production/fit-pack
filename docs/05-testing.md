# Fit Pack — Test Stratejisi (Testing Strategy)

> **Doküman versiyonu:** 1.0 (taslak)
> **Tarih:** 2026-05-18
> **Sahibi:** Samet Orhan
> **Durum:** Onay bekliyor
> **Bağlı doküman:** [01-product-spec.md](01-product-spec.md) (PRD v1.1), [02-architecture.md](02-architecture.md), [03-ux-flows.md](03-ux-flows.md), [04-roadmap.md](04-roadmap.md)

Bu doküman, **Fit Pack V2'nin hangi seviyede, neyi, hangi araçla test edeceğini** tanımlar. Mimari "nasıl yapılır"ı söyler; bu doküman "yaptığımız şey çalışıyor mu, ve bozulmadan duruyor mu"yu nasıl bileceğimizi söyler.

> **Kısaltma sözlüğü:** PRD = Product Requirements Document (Ürün Gereksinim Dokümanı) · DAO = Data Access Object (Veri Erişim Nesnesi) · CI = Continuous Integration (Sürekli Entegrasyon) · E2E = End-to-End (Uçtan Uca) · DoD = Definition of Done (Bitti Tanımı) · RIR = Reps in Reserve (Yedek Tekrar) · SUT = System Under Test (Test Edilen Sistem) · TDD = Test-Driven Development (Test Güdümlü Geliştirme).

---

## 1. Test Felsefesi (Bu Proje İçin)

Fit Pack **tek kullanıcılı, lokal, solo geliştirici** bir uygulama. Bu üç gerçek test stratejisini şekillendirir:

1. **%100 kapsama hedefi YOK.** Solo geliştirici + haftada 7-10 saat efor (Roadmap §2). Her satırı test etmek burnout yaratır, değer üretmez.
2. **Test, en çok canın yandığı yere yazılır.** Bu projede o yer net: **veri kaybı.** 3 ay pilot data toplanacak (PRD başarı kriteri). Bir migration hatası 3 ayı siler. Bu yüzden test eforunun çoğu **migration + DAO + şifreleme** katmanına gider.
3. **Manuel test birinci sınıf vatandaş.** Emülatör/cihazda manuel akış testi (Samet'in kuralı: kod değişince otomatik çalıştır) yazılı testin yerini kısmen tutar. Yazılı test, manuelin **kaçırdığı** ve **tekrar tekrar kontrol edilmesi gereken** şeyler için.

### Sonuç: Test "Piramidi" değil, "Test Hedef Tahtası"

```
                  ┌────────────────────┐
                  │  E2E (manuel)      │  ← Az sayıda, kritik akış
                  │  emülatör checklist│     (Samet elle, her sprint sonu)
              ┌───┴────────────────────┴───┐
              │  Widget testleri           │  ← Orta: form validation,
              │  (kritik ekranlar)         │     empty/error state render
          ┌───┴────────────────────────────┴───┐
          │  Integration testleri              │  ← KALIN: DB + DAO +
          │  (DB / DAO / Migration / SQLCipher)│     migration (en kritik)
      ┌───┴────────────────────────────────────┴───┐
      │  Unit testleri                              │  ← Orta-kalın: Notifier
      │  (iş mantığı: progression, hesaplama)       │     iş mantığı, saf fonk.
      └─────────────────────────────────────────────┘
```

> Klasik piramitten farkı: **Integration katmanı bilinçli olarak şişman.** Çünkü bu projenin kritik riski (Mimari §16, Roadmap §11) veri katmanında.

---

## 2. Test Tipleri ve Kapsam

| Test Tipi | Ne Test Eder | Araç | Ne Zaman Yazılır |
|-----------|--------------|------|------------------|
| **Unit** | Saf iş mantığı: auto-progression kg önerisi, haftalık hacim hesabı, skor hesaplama, validasyon kuralları | `flutter_test` | İlgili Notifier/fonksiyon yazılırken |
| **Integration** | DAO sorguları, Drift migration'ları, SQLCipher açılışı, seed yükleme | `drift` test desteği + in-memory/native DB | Tablo/DAO/migration eklenince — **zorunlu** |
| **Widget** | Form validasyon, empty state, error card, kritik ekran render | `flutter_test` + `ProviderScope` override | Aşama 0 sonrası kritik ekranlar için |
| **Golden (opsiyonel)** | Tema tutarlılığı, dark mode kontrast | `flutter_test` golden | Aşama 3 polish; düşük öncelik |
| **E2E (manuel)** | Tam kullanıcı akışı (workout log → kaydet → grafik) | Emülatör + checklist | Her sprint sonu (Roadmap §12.1 Cumartesi) |

**V2 boyunca otomatik E2E (integration_test paketi ile sürücü test) YOK** — kurulum maliyeti solo pilot için ağır. V3 public release öncesi eklenecek (Mimari §13.3).

---

## 3. Katman Bazlı Test Stratejisi

### 3.1 Data Katmanı — DAO & Migration (EN KRİTİK)

**Hedef:** Hiçbir veri kaybolmaz. Hiçbir migration eski veriyi silmez.

#### DAO Testleri

Her DAO için **in-memory veya geçici dosya tabanlı** Drift instance ile test:

```dart
// test/data/daos/workout_dao_test.dart
late AppDatabase db;

setUp(() {
  db = AppDatabase.forTesting(NativeDatabase.memory());
});
tearDown(() async => await db.close());

test('insertSession sonra watchAllSessions onu döner', () async {
  final id = await db.workoutDao.insertSession(
    WorkoutSessionsCompanion.insert(date: DateTime(2026, 5, 18), phase: 1, week: 1),
  );
  final sessions = await db.workoutDao.watchAllSessions().first;
  expect(sessions, hasLength(1));
  expect(sessions.first.id, id);
});
```

**Kural:** Yeni eklenen her DAO için **en az** insert + read + (varsa) update/delete happy-path testi.

#### Migration Testleri (ZORUNLU — bu projenin 1 numaralı testi)

Drift'in resmi migration test helper'ı kullanılır. Her schema versiyon artışı için:

```dart
// test/data/migration_test.dart
test('v1 → v2 göçü veriyi korur', () async {
  // 1. v1 schema ile DB oluştur, veri ekle
  final connection = await verifyDatabaseSchema(/* v1 snapshot */);
  // 2. v2'ye yükselt
  // 3. ASSERT: eski satırlar duruyor + yeni kolon (rir, elbow_status) null değil hata
  // 4. ASSERT: yeni tablolar (daily_log, supplement_log) yaratıldı
});
```

**Kurallar:**
1. **Her `schemaVersion` artışında yeni migration testi zorunlu.** Test yoksa migration merge edilmez.
2. Test her zaman **gerçek bir önceki sürüm verisi** ile başlar (boş DB'de migration test etmek yetersiz).
3. Drift `schema_versions` snapshot mekanizması kullanılır: `drift_dev schema dump` ile her sürüm şeması versiyonlanır.
4. **Yıkıcı senaryo testi:** "Eğer kolon adı çakışırsa / index bozulursa" değil — pozitif lossless yol yeterli (V2 ölçeği için pragmatik).

> Roadmap referansı: T-008 (Aşama 0), T-007 (manuel V1→V2 göç testi). Her Aşama'da yeni migration → yeni test (T-101..T-104 → migration v2→v3 → test).

#### SQLCipher Açılış Testi

```dart
test('şifreli DB doğru key ile açılır, yanlış key ile açılmaz', () async {
  // doğru key → açılır, sorgu çalışır
  // yanlış/eksik key → exception fırlatır (sessizce boş DB AÇMAZ)
});
```

> En tehlikeli sessiz hata: yanlış key'de SQLCipher'ın **yeni boş DB açması**. Bu test onu yakalar. (Mimari §16, Roadmap §3.4 riski.)

### 3.2 Domain Katmanı — Notifier & İş Mantığı

**Hedef:** Hesaplamalar doğru. State geçişleri öngörülebilir.

Test edilecek **saf mantık** örnekleri:
- `suggestNextWeight()` — auto-progression önerisi (RIR + geçen hafta verisine göre) — T-109
- Haftalık toplam hacim hesabı (set × rep × kg) — Aşama 2 grafik kaynağı
- Genel skor hesabı (0-10, kural tabanlı) — T-222
- Pattern detection (örn: "3 hafta üst üste protein az") — T-223
- Input validation kuralları (Mimari §10 tablosu) — T-014

```dart
// test/features/workout/progression_test.dart
test('RIR 3+ ve hedef tamamlandıysa +2.5kg önerir', () {
  final suggestion = ProgressionLogic.suggestNextWeight(
    lastWeight: 60, lastReps: 8, targetReps: 8, lastRir: 3,
  );
  expect(suggestion, 62.5);
});
```

**Riverpod Notifier testi** — `ProviderContainer` ile, DAO mock'lanır (`mocktail`):

```dart
test('logSet çağrılınca DAO insert edilir ve state günceller', () async {
  final mockDao = MockWorkoutDao();
  final container = ProviderContainer(overrides: [
    workoutDaoProvider.overrideWithValue(mockDao),
  ]);
  addTearDown(container.dispose);

  await container.read(workoutSessionProvider.notifier)
      .logSet(exerciseId: 1, reps: 8, kg: 60, rir: 2);

  verify(() => mockDao.insertSet(any())).called(1);
});
```

> **`autoDispose` UYARISI:** Test ederken bile shared-screen provider'larında `autoDispose` kullanılmaz. MemoRush'taki `autoDispose + pushReplacement` crash'i (memory: `feedback_riverpod_autodispose_navigation`) regresyon olarak **bir widget testiyle** kilitlenir: shared ekrana git → başka ekrana `pushReplacement` → geri gel → provider hâlâ canlı mı.

### 3.3 Presentation Katmanı — Widget

**Hedef:** Kullanıcı yanlış veri giremez; hata/boş durumlar düzgün görünür.

Öncelikli widget testleri (yüksek değer, düşük maliyet):
1. **Form validasyon** — kg < 0, rep > 100, RIR > 10 → hata mesajı görünür, kayıt engellenir (Mimari §10).
2. **Empty state** — veri yokken `empty_state.dart` render ediliyor mu (T-012).
3. **Error card** — provider error fırlattığında snackbar/error card görünüyor mu (T-013).
4. **Daily log 30sn akışı** — UX hedefi (PRD); kritik alanların tek ekranda olduğunu doğrula (T-115).

Geri kalan ekranlar için widget testi **opsiyonel** — manuel emülatör testi yeterli kabul edilir (solo pilot pragmatizmi).

---

## 4. Test Araçları ve Paketler

| Amaç | Paket | Notlar |
|------|-------|--------|
| Temel test framework | `flutter_test` (SDK) | Unit + widget |
| Mocking | `mocktail` | `mockito` yerine — code-gen istemez, sade |
| Drift test DB | `drift` (`NativeDatabase.memory()`) | In-memory; hızlı, izole |
| Migration snapshot | `drift_dev` schema tooling | `dart run drift_dev schema dump` |
| Riverpod test | `ProviderContainer` + `overrides` | Ek paket gerekmez |
| Coverage raporu | `flutter test --coverage` + `lcov` | Lokal görüntüleme, CI'sız |

**Eklenecek dev_dependencies (Aşama 0'da):**
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  # drift_dev zaten mevcut (code-gen için)
```

---

## 5. Test Klasör Yapısı

`test/` klasörü `lib/` yapısını **ayna** olarak takip eder:

```
test/
├── data/
│   ├── daos/
│   │   ├── workout_dao_test.dart
│   │   ├── nutrition_dao_test.dart
│   │   ├── daily_log_dao_test.dart      # Aşama 1
│   │   └── ...
│   ├── migration_test.dart              # ZORUNLU, her sürüm
│   └── sqlcipher_test.dart              # Aşama 0
├── features/
│   ├── workout/
│   │   ├── progression_test.dart        # iş mantığı (unit)
│   │   └── workout_session_provider_test.dart
│   ├── body_metrics/
│   └── ...
├── shared/
│   └── widgets/
│       ├── error_card_test.dart
│       └── empty_state_test.dart
├── helpers/
│   ├── test_database.dart               # AppDatabase.forTesting fabrikası
│   ├── fixtures.dart                    # Örnek veri üreticileri
│   └── pump_app.dart                    # ProviderScope + MaterialApp sarmalayıcı
└── drift_schemas/                       # Versiyonlanmış şema snapshot'ları
    ├── drift_schema_v1.json
    └── drift_schema_v2.json
```

**Kural:** Bir dosya `lib/.../x.dart` ise testi `test/.../x_test.dart`. Bulması kolay olsun.

---

## 6. Test Verisi ve Fixture Stratejisi

- **Fixture fabrikaları** (`test/helpers/fixtures.dart`): `makeWorkoutSession()`, `makeFoodLog()` gibi varsayılan-değerli üreticiler. Test sadece ilgilendiği alanı override eder.
- **Seed verisi testte yüklenmez** (600 yemek + egzersiz kataloğu) — hız için. Seed'in kendisi ayrı bir `seed_manager_test.dart` ile bir kez test edilir.
- **Tarih sabitleri** — `DateTime.now()` testte kullanılmaz; sabit tarih (`DateTime(2026, 5, 18)`) enjekte edilir. Flaky test önlenir.

---

## 7. Aşama Bazlı Test Gereksinimleri (Minimum Bar)

Her Aşama'nın "Bitti Tanımı"na (Roadmap DoD) bağlı **zorunlu test minimumu**:

### Aşama 0 — Sağlamlaştırma
- ✅ `migration_test.dart` — v1 → v2 lossless (T-008) **— BU OLMADAN AŞAMA 0 BİTMEZ**
- ✅ `sqlcipher_test.dart` — doğru/yanlış key davranışı
- ✅ `WorkoutDao` integration testi (Mimari §12: "Aşama 0'da minimum")
- ✅ Input validation unit testleri (kg/rep/RIR/stres sınırları)
- ✅ Manuel: emülatörde tüm V1 akışları regresyon (T-017 checklist — §8)

### Aşama 1 — Programa Yansıt
- ✅ Her yeni migration (v2→v3, v3→v4...) için yeni migration testi
- ✅ Yeni DAO'lar (`daily_log_dao`, `supplement_dao`) happy-path
- ✅ `suggestNextWeight()` progression mantığı unit (T-109)
- ✅ Foto: `PhotoService` sıkıştırma çıktısı testi (boyut ~500KB, dosya var) + galeri izni reddi sessiz geçer (mock)

### Aşama 2 — Görselleştirme
- ✅ Haftalık veri agregator unit (doğru toplam/ortalama)
- ✅ Genel skor (0-10) hesaplama unit
- ✅ AI rate limit handling: limit exception → kullanıcı dostu mesaj state'i (Q-03)
- ✅ Achievement tetikleyici: koşul sağlanınca rozet ekleniyor mu

### Aşama 3 — QoL
- ✅ Plate calculator: hedef kg → doğru plaka kombinasyonu unit
- ✅ Alternatif hareket önerisi: knee/elbow durumuna göre doğru liste
- ✅ Bildirim zamanlama fonksiyonu unit (timezone-safe)
- ✅ Golden test (opsiyonel): dark mode kontrast

---

## 8. Manuel Regresyon Checklist (Her Sprint Sonu)

Roadmap §12.1: Cumartesi = test + push. Bu checklist emülatörde (`R96YB00XJPB`) elle koşulur:

| # | Akış | Beklenen |
|---|------|----------|
| R-01 | Uygulama açılır | Crash yok, home dashboard yüklenir, **DB şifreli açıldı** |
| R-02 | Workout başlat → set/rep/kg/RIR gir → kaydet | Veri DB'de, listede görünür |
| R-03 | Rest timer (90/60sn) | Haptic + geri sayım çalışır |
| R-04 | Nutrition: 4 öğüne yemek ekle, sil (dismissible) | Toplam kalori/protein güncellenir |
| R-05 | Body metrics: kilo + ölçü gir | Summary card güncellenir |
| R-06 | Settings: hedef/faz değiştir | Home yansıtır |
| R-07 | Export: md/json/csv × hafta/ay/all | Dosya üretilir, paylaşılır |
| R-08 | Daily log 30sn akışı (Aşama 1+) | Tek scroll, hızlı |
| R-09 | Foto çek → sıkıştır → galeri (Aşama 1+) | DB kopyası + galeri kopyası |
| R-10 | Grafikler (Aşama 2+) | Doğru trend, filtre çalışır |
| R-11 | **Veri kalıcılığı:** uygulamayı kapat-aç | Önceki veri duruyor (kayıp yok) |

> R-01 ve R-11 **her sprintte zorunlu** — şifreleme/migration regresyonunu erken yakalar.

---

## 9. Coverage Hedefleri (Pragmatik)

| Katman | Hedef Coverage | Gerekçe |
|--------|----------------|---------|
| Data — migration & DAO | **Yüksek (~%80+)** | Veri kaybı = pilot ölümü |
| Domain — iş mantığı | Orta (~%60) | Hesaplama hataları sinsi |
| Presentation — widget | Düşük (~%30) | Manuel test kapsıyor |
| **Genel proje** | Hedef değil, **metrik** | Sayı kovalanmaz; kritik path kovalanır |

**Kural:** Coverage **kapı değil, ışık.** "%X altında merge yok" gibi sert kural YOK (CI yok zaten). Ama `flutter test --coverage` ara sıra çalıştırılıp **migration/DAO'da boşluk var mı** gözle bakılır.

---

## 10. CI Yokken Disiplin (V2 Boyunca)

V2 lokal pilot — otomatik CI yok (Mimari §13.3, V3'te gelecek). Disiplin manuel:

**Her commit öncesi (pre-push checklist — Roadmap §12.3 DoD'a ek):**
```
1. flutter analyze        → 0 warning
2. flutter test           → tüm testler yeşil
3. (migration değiştiyse) → migration_test özellikle koş
4. Emülatörde manuel smoke (R-01, R-11 minimum)
5. commit + push
```

> Bu checklist `docs/06-workflow.md`'de commit/branch akışına bağlanacak (sonraki doküman).

**V3'te (Aşama 4) eklenecek:** GitHub Actions — her PR'da `flutter analyze` + `flutter test`, tag'lerde release build.

---

## 11. Test Anti-Pattern'leri (Yapma)

- ❌ **Getter/setter test etme** — değer yok.
- ❌ **Drift'in kendisini test etme** — framework'e güven; senin sorgu mantığını test et.
- ❌ **`DateTime.now()` ile zaman bağımlı test** — flaky; sabit tarih enjekte et.
- ❌ **Tek dev sprint'inde TDD zorunluluğu** — pratik nerede mantıklıysa orada; dogma değil.
- ❌ **Widget testinde tüm pixel'i golden'lama** — bakım yükü; sadece tema/dark mode kritikse.
- ❌ **Mock'u mock'lamak** — iş mantığını gerçek çalıştır, sadece DAO/IO sınırını mock'la.

---

## 12. Riskler ve Test ile Azaltma

| Risk (kaynak: Mimari §16 / Roadmap §11) | Test Azaltması |
|------------------------------------------|----------------|
| SQLCipher migration V1 DB'yi bozar | `migration_test` + `sqlcipher_test` + R-11 manuel; başarısızsa yedek export'tan rollback |
| Yanlış key'de sessiz boş DB | `sqlcipher_test`: yanlış key → exception (boş DB AÇMAZ) assert |
| `autoDispose` + navigation crash (MemoRush geçmişi) | Shared screen → `pushReplacement` → geri dön regresyon widget testi |
| Foto sıkıştırma kalitesi/boyutu tutarsız | `PhotoService` testi: çıktı boyut + dosya varlığı; kalite A/B'si manuel Samet kararı |
| AI rate limit beklenmedik | Rate limit exception → doğru kullanıcı mesajı state testi |
| Migration test yazılmadan sürüm geçilir | **Kural:** schema versiyon artışı + migration testi aynı commit'te; yoksa merge yok |

---

## 13. Sonraki Adım

Bu doküman onaylanınca:
- `docs/06-workflow.md` — DevOps & çalışma şekli: branch/commit kuralları, pre-push checklist'in workflow'a bağlanması, dispatch ile mobilden çalışma, release süreci
- Sonra → **kod yazımı: Aşama 0 Sprint 0.1** (T-001 migration iskeleti). İlk yazılacak kod ile birlikte ilk `migration_test.dart` gelir.

---

## 14. Onay & Versiyon

| Versiyon | Tarih | Değişiklik | Onay |
|----------|-------|------------|------|
| 1.0 (taslak) | 2026-05-18 | İlk taslak — PRD v1.1 + Mimari v1.0 + Roadmap v1.0 üzerine inşa | ⏳ Beklemede |
