# Fit Pack — Geliştirme Kuralları (CONVENTIONS)

> **Amaç:** Bu proje AI-destekli, özellik-özellik büyüdü. Bu dosya, kod
> incelemesi (2026-07-04, [CODE_REVIEW.md](CODE_REVIEW.md)) sonrası oturan
> standartları sabitler. **Yeni kod yazan herkes (insan ya da Claude) önce
> bunu okur, sonra yazar.** Örnekler uydurma değil — bu kod tabanından.

Stack: Flutter · Drift (SQLite, lokal) · Riverpod · GoRouter · fl_chart.

---

## 1. Klasör Yapısı — yeni özellik nereye gider

```
lib/
  core/            # çapraz-kesit altyapı (feature'a bağımsız)
    config/        # SupabaseConfig gibi sabit yapılandırma
    constants/     # AppConstants
    router/        # app_router.dart (tanım) + app_routes.dart (adresler)
    theme/         # app_colors, app_dimens, app_theme
    utils/         # format.dart gibi saf yardımcılar
  data/            # veri katmanı — UI bilmez
    database/
      tables/      # Drift tablo tanımları
      daos/        # DAO'lar (+ üretilen .g.dart)
      app_database.dart
    seed/          # ilk veri + backfill (SeedManager)
    services/      # dış servisler (OpenFoodFactsService, ExportService)
    providers.dart # DB + DAO + servis provider'ları (kök)
  features/<ad>/   # HER ÖZELLİK KENDİ KLASÖRÜNDE
    <ad>_screen.dart
    <ad>_providers.dart   # o özelliğe ait provider'lar
    <yardımcı>.dart       # saf mantık (macro_goals, calorie_estimate...)
  shared/widgets/  # birden çok feature'ın kullandığı widget'lar
```

**Kural:** Yeni bir ekran/özellik = `lib/features/<ad>/` altında yeni klasör.
İş mantığını (hesap, dönüşüm) UI dosyasına gömme; saf fonksiyon olarak ayrı
dosyaya al (örnek: `onboarding_calc.dart`, `macro_goals.dart` — widget'sız,
kolay test edilir). Veri erişimi **her zaman** DAO üzerinden; ekran doğrudan
SQL/tablo görmez.

---

## 2. State Yönetimi — kanonik kalıp

**Tek kalıp: Riverpod.** `setState` yalnız yerel/geçici widget durumu için
(form alanı, açık/kapalı). Kalıcı veri hep provider üzerinden.

### Okuma provider'ı (DAO'yu sarmalar)
```dart
// features/home/providers/home_providers.dart
final latestWeightProvider = FutureProvider<BodyMeasurement?>((ref) {
  return ref.watch(bodyDaoProvider).getLatestMeasurement();
});
```

### Ekranda tüketme
```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(weightTrendProvider).valueOrNull;
    ...
  }
}
```

### Yazma + tazeleme (ÖNEMLİ — en sık hata kaynağı)
Yazdıktan sonra **o veriyi okuyan TÜM provider'ları** `invalidate` et. Bir
tanesini unutmak = ekran eski veri gösterir (kod incelemesi H-05).

```dart
await ref.read(bodyDaoProvider).insertMeasurement(...);
// Kiloyu okuyan HER provider tazelenir:
ref.invalidate(allMeasurementsProvider);
ref.invalidate(weightTrendProvider);   // Home "Son Kilo"
ref.invalidate(latestWeightProvider);  // Ayarlar TDEE + kalori tahmini
```
Bir veri parçasını hangi provider'ların okuduğunu bilmiyorsan, `grep` ile
bul. Yeni bir okuma provider'ı eklerken, o veriyi yazan yerlere invalidate'i
eklemek **senin sorumluluğun**.

### Kurallar
- **Sheet / dialog `ConsumerStatefulWidget` olur.** `WidgetRef`'i parametre
  olarak taşıma (kod incelemesi M-06 — üst ekran kapanınca ref ölür).
- **Ekrandan uzun yaşayan geri-çağrı** (SnackBar "Geri al" gibi) ekranın
  `ref`'ine dokunamaz. DAO'yu ve gerekiyorsa `ProviderScope.containerOf`'u
  önceden yakala:
  ```dart
  final dao = ref.read(nutritionDaoProvider);
  final container = ProviderScope.containerOf(context, listen: false);
  // ... SnackBar action: dao.insert(...); container.invalidate(...);
  ```
- **`build`/render içinde yan etki yok** (DB yazma, invalidate, navigasyon
  build sırasında çağrılmaz — kullanıcı etkileşimi ya da lifecycle içinde).

---

## 3. Kalıcılık (Drift/SQLite) Kuralları

### Erişim
Tüm veri erişimi DAO metotları üzerinden. Provider'lar DAO'yu `databaseProvider`
üzerinden alır (bkz. `data/providers.dart`). Ekran/servis ham `select`/`SQL`
yazmaz.

### Tarih aralığı — DAİMA yarı-açık `[start, end)`
`isBetweenValues` (SQL `BETWEEN`) **iki ucu da dahil eder** → tam gece yarısı
kaydı iki döneme birden sayılır (kod incelemesi H-01). Bunun yerine:
```dart
..where((l) => l.date.isBiggerOrEqualValue(start) &
               l.date.isSmallerThanValue(end))
```
`end` = "sonraki günün/haftanın/ayın ilk anı", ve dışarıda kalır.

### Çoklu yazım = transaction
Bir işlem birden fazla `insert`/`update`/`delete` içeriyorsa hepsi tek
`transaction` içinde. Yarıda kesilirse yarım kayıt kalmasın (kod incelemesi
H-06, M-05). Örnek: `WorkoutDao.insertSessionWithSets`,
`saveRoutineWithExercises`. UI tarafında `try/catch` + hata mesajı + `_saving`
kilidini `finally`/`catch`'te çöz.

### Şema değişikliği kontrol listesi (ADR-007)
Tablo/kolon eklerken **aynı commit'te**:
1. `tables/` içinde alanı ekle (yeni kolon **nullable** ya da `withDefault` —
   mevcut satırlar bozulmasın).
2. `app_database.dart` → `schemaVersion`'ı **1 artır**.
3. `onUpgrade`'e `if (from < N && to >= N) { await m.addColumn(...); }` adımı.
4. `build_runner` çalıştır (`.g.dart` güncellensin).
5. `drift_dev schema dump` + `generate` (snapshot + test şeması — README'deki
   komutlar).
6. `test/data/migration_test.dart` tripwire'ını yeni sürüme çek + kayıpsız göç
   testi.
7. Eski kurulumlara veri doldurma gerekiyorsa `SeedManager`'a idempotent
   backfill ekle **ve** `SeedManager.seedVersion`'ı artır (yoksa backfill hiç
   çalışmaz — kod incelemesi M-04).

**YASAK:** Tablo/kolon silme, tip daraltma, yıkıcı migration (ADR-007). Ölü
tablo kalsa bile şemada durur, yalnız erişim kodu temizlenir + belgelenir
(örnek: `achievements`, `recipe_items`).

### Yedek/geri yükleme
DB dosyasının üstüne yazan her işlem: önce doğrula (imza + şema sürümü, DB
kapanmadan), WAL checkpoint, emniyet kopyası, atomik `rename`, hatada geri al
(bkz. `BackupService.restoreFromFile`). Bağlantı kapandıktan sonraki hata
`showRestartDialog` ile karşılanır (uygulama kapalı-DB ile devam edemez).

---

## 4. Navigasyon (GoRouter) Kuralları

Rota adresi **tek yerde**: `core/router/app_routes.dart`. Ham string
(`context.go('/workout')`) yazma — yazım hatası derlemede yakalanmaz.

**Yeni rota ekleme:**
1. `AppRoutes`'a sabit ekle: `static const foo = '/foo';`
   Parametreliyse hem path hem oluşturucu:
   ```dart
   static const summaryPath = '/workout/summary/:sessionId';
   static String summary(int id) => '/workout/summary/$id';
   ```
2. `app_router.dart` → `GoRoute(path: AppRoutes.foo, ...)` (parametreli:
   `path: AppRoutes.summaryPath`).
3. Çağrı: `context.go(AppRoutes.foo)` / `context.push(AppRoutes.summary(id))`.

Sekme değişimi `context.go` (geçmiş yığmaz), detay/alt sayfa `context.push`.
Kalıcı/kapatılamaz akış (geri yükleme sonrası restart) `PopScope(canPop:false)`.

---

## 5. Sabitler & Tema

- **Sihirli sayı/string yok.** Tekrarlanan değer adlandırılmış sabit olur.
- **Renk:** her zaman `context.colors.X` (Material rolleri) ya da
  `context.semantic.X` (success/warning/makro renkleri). Ekranda
  `Colors.blue`/`Color(0xFF...)` **hardcode edilmez**. Gradient yüzeylerin
  üstü `AppColors.onGradient`. Tek meşru istisna: kamera vizörü (barkod
  ekranı, doğası gereği siyah — kodda belgelenmiş).
- **Ölçü/boşluk/köşe:** `AppSpacing.*`, `AppRadius.*`, `AppIconSize.*`
  (`core/theme/app_dimens.dart`). Ham `EdgeInsets.all(16)` yerine token.
- **Metin stili:** `context.texts.*` (TextTheme).

---

## 5b. Çok Dilli (i18n/l10n) — docs/14

- **Kullanıcı metni hardcode edilmez.** Yeni görünen metin → `lib/l10n/app_en.arb`
  (kaynak) + `app_tr.arb`'ye anahtar açılır, `AppL10n.of(context).<key>` ile
  kullanılır. Anahtar adı `alanEkran_amac` camelCase (ör. `home_streakTitle`).
- **Parametre** ICU placeholder (`{count}`); çoğul gerekiyorsa `plural`.
- **Tarih/sayı biçimi** daima aktif locale: `context.dateFmt('...')`,
  `context.numFmt` (`core/i18n/formatting.dart`). `'tr_TR'` sabiti **yasak**.
- **Enum/DB anahtar etiketleri** (cinsiyet, aktiflik, tema, dil):
  `core/i18n/enum_labels.dart`. Anahtar İngilizce sabit, etiket dile göre çözülür.
- ARB değişince `flutter gen-l10n` (veya `flutter pub get`) çalıştır.

---

## 6. Hata Yönetimi Standardı

- Her I/O (DB, ağ, dosya) çağrısı `try/catch` ile sarılı; kullanıcıya Türkçe,
  anlaşılır mesaj (SnackBar ya da diyalog). Sessizce yutma yok.
- Ağ servisleri offline-first: hata/timeout → `null`/boş liste dön, uygulama
  çalışmaya devam etsin (örnek: `OpenFoodFactsService`).
- `async` işlemlerde `_saving`/`_busy` kilidi kullanıyorsan `finally` ya da
  `catch`'te **mutlaka** geri al (kod incelemesi H-06, M-10) — yoksa düğme
  sonsuza dek dönen çember olur.
- `context.mounted` / `mounted` kontrolü: `await`'ten sonra `context`
  kullanmadan önce daima kontrol et.

---

## 7. "Bitti" Tanımı (her yeni özellik / düzeltme için)

Bir iş şu koşulları sağlamadan "bitti" değildir:

- [ ] `flutter analyze` → **0 uyarı/hata**.
- [ ] `flutter test` → hepsi geçer; yeni mantık için yeni test yazıldı.
- [ ] Kaynaklar `dispose` edildi (Controller, Timer, StreamSubscription,
      WidgetsBindingObserver).
- [ ] `print`/`debugPrint`/geçici bayrak/yorum-satırı kod yok.
- [ ] Şema değiştiyse §3 kontrol listesi uygulandı.
- [ ] Yeni rota eklediyse §4 (AppRoutes) uygulandı.
- [ ] Emülatörde/cihazda çalıştırılıp görsel doğrulandı.
- [ ] `PROJECT_STATE.md` / `NEXT_TASKS.md` güncellendi (Samet'in kuralı:
      oturum sonu dokümantasyon).

---

## 8. Kod Stili Notları

- Türkçe yorum + Türkçe UI metni (kullanıcı Türk). Kod tanımlayıcıları
  (değişken/sınıf) İngilizce.
- Kısaltma kullanınca ilk geçtiği yerde aç (RPE = Algılanan Zorluk, TDEE =
  Toplam Günlük Enerji Harcaması) — Samet developer değil, raporları o okuyor.
- Dinamik liste widget'larına **key ver** (`ObjectKey`/`ValueKey`) — özellikle
  içinde `TextField`/`TextFormField` olan listelerde (kod incelemesi H-02:
  key'siz listede eleman silinince metin kutuları yanlış değere kayar).
- `TextEditingController` daima `initState`'te oluştur, `dispose`'ta kapat.
