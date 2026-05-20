# Fit Pack — Mimari Doküman (Architecture Document)

> **Doküman versiyonu:** 1.0 (taslak)
> **Tarih:** 2026-05-13
> **Sahibi:** Samet Orhan
> **Durum:** Onay bekliyor
> **Bağlı doküman:** [01-product-spec.md](01-product-spec.md) (PRD v1.1)

Bu doküman, **Fit Pack uygulamasının teknik mimarisini, katmanlarını, modüller arası iletişimi, veri akışını ve karar gerekçelerini** tanımlar. PRD "ne yapacağı"nı söyler; bu doküman "nasıl yapacağı"nı söyler. Kod yazımı sırasında uyulacak yapı buradadır.

---

## 1. Genel Bakış (High-Level Overview)

Fit Pack, **tek kullanıcılı, lokal-öncelikli (local-first) bir Flutter mobil uygulamasıdır.** Tüm veri cihazda yaşar, internet sadece **AI (Artificial Intelligence — Yapay Zeka) provider**'ı için gereklidir.

### Mimari Tarz: Katmanlı + Feature-First Hibrit

```
┌─────────────────────────────────────────────────────────┐
│                  PRESENTATION (UI)                       │
│  features/  ←  ConsumerWidget'lar, ekran widget'ları    │
│  shared/    ←  Ortak UI bileşenleri (AppShell, vb.)    │
└────────────────────────┬────────────────────────────────┘
                         │ Riverpod Provider ile okuma/yazma
                         ▼
┌─────────────────────────────────────────────────────────┐
│              DOMAIN (İş Mantığı — Business Logic)         │
│  features/.../providers/  ← Notifier, AsyncNotifier      │
│  core/services/           ← Yatay servisler (AI, vb.)    │
└────────────────────────┬────────────────────────────────┘
                         │ DAO çağrısı (Data Access Object)
                         ▼
┌─────────────────────────────────────────────────────────┐
│                     DATA                                 │
│  data/database/   ←  Drift tabloları + DAO'lar           │
│  data/services/   ←  Export, foto, AI provider           │
│  data/seed/       ←  İlk açılışta yüklenen başlangıç veri│
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
                ┌──────────────────┐
                │ SQLite (SQLCipher │
                │ ile şifrelenmiş)  │
                │ + Telefon galerisi│
                │ + AI API (Gemini) │
                └──────────────────┘
```

### Temel Prensipler

1. **Local-First:** Veri öncelikle cihazda; AI sadece sorgulama için.
2. **Reactive State:** Veri değişince UI **kendiliğinden** güncellenir (Riverpod stream'leri).
3. **Tek Kaynak Doğru (Single Source of Truth):** Veri sadece veritabanında, in-memory cache yok (Riverpod provider'ları zaten cache görevi görür).
4. **Pluggable AI:** LLM (Large Language Model — Büyük Dil Modeli) sağlayıcısı arayüz arkasında, değiştirilebilir.
5. **Schema Versioning:** Veritabanı şeması versiyonlanır, migration (göç) ile güvenli evrim.

---

## 2. Teknoloji Stack'i ve Gerekçeler

| Katman | Teknoloji | Versiyon | Gerekçe |
|--------|-----------|----------|---------|
| Framework | Flutter | 3.x (sdk ^3.11) | Cross-platform, V3'te iOS de hedef |
| Dil | Dart | 3.x | Flutter doğal dili, null-safety |
| State management | Riverpod | ^2.6.1 | Compile-time güvenli, test edilebilir, provider scope'ları temiz |
| Veritabanı | Drift (üzerine SQLite) | ^2.22.1 | Type-safe SQL, reactive stream'ler, code generation, migration desteği |
| Veritabanı şifreleme | drift_sqlcipher | (Aşama 0'da ekl.) | OS-level transparent encryption (Q-05 kararı) |
| Routing | go_router | ^14.8.1 | Declarative, deep-link, type-safe routing |
| Grafikler | fl_chart | ^0.70.2 | Native Flutter, customizable, açık kaynak |
| AI Provider (varsayılan) | Gemini API | google_generative_ai | Samet'in API key'i mevcut, generous free tier |
| Foto sıkıştırma | flutter_image_compress | (Aşama 0'da ekl.) | Hibrit foto saklama için (Q-02 kararı) |
| Galeri kaydetme | gal | (Aşama 0'da ekl.) | Orijinal fotoyu telefon galerisine yazma |
| Bildirim | flutter_local_notifications | (Aşama 2'de ekl.) | Lokal hatırlatma, server gerektirmez |
| Güvenli depolama | flutter_secure_storage | (Aşama 0'da ekl.) | API anahtarını cihazda güvenle saklamak |
| Export | csv + share_plus | mevcut | Markdown/JSON/CSV dışa aktarma |
| Tema | google_fonts | mevcut | Tipografi tutarlılığı |

### Onaylanan Stack Değişiklikleri (PRD'den gelen)

PRD v1.1 ile şu paketler **eklenecek** (Aşama 0 — Sağlamlaştırma):
- `drift_sqlcipher` — Şeffaf DB şifreleme (Q-05)
- `flutter_image_compress` — Foto sıkıştırma (Q-02)
- `gal` (veya alternatif `image_gallery_saver`) — Orijinal foto galeriye (Q-02)
- `flutter_secure_storage` — API key'i güvenli saklamak için
- `google_generative_ai` — Gemini SDK'sı (AI provider)
- `flutter_local_notifications` — Aşama 2'de bildirim

---

## 3. Klasör Yapısı (Folder Structure)

V1'de mevcut yapı **feature-based** + **layered** hibrit. V2'de aynı yapı korunur, sadece yeni feature klasörleri eklenir.

```
lib/
├── main.dart                    # ProviderScope + bootstrap
├── app.dart                     # MaterialApp + router config
│
├── core/                        # Yatay (cross-cutting) altyapı
│   ├── constants/
│   │   └── app_constants.dart   # Sabitler (kalori hedef, vs.)
│   ├── theme/
│   │   └── app_theme.dart       # Light/Dark tema
│   ├── router/
│   │   └── app_router.dart      # go_router config
│   ├── errors/                  # YENİ — Aşama 0
│   │   ├── app_exception.dart   # Domain hataları
│   │   └── error_handler.dart   # Global error catcher
│   └── services/                # YENİ — Aşama 0/1
│       ├── ai_provider.dart     # Interface (soyut sınıf)
│       ├── gemini_provider.dart # Gemini implementasyonu
│       ├── photo_service.dart   # Foto compress + galeri
│       └── notification_service.dart  # Aşama 2
│
├── data/                        # Veri katmanı
│   ├── database/
│   │   ├── app_database.dart    # Drift DB sınıfı + migration'lar
│   │   ├── tables/              # Tablo tanımları
│   │   │   ├── workout_tables.dart
│   │   │   ├── nutrition_tables.dart
│   │   │   ├── body_tables.dart
│   │   │   ├── achievement_tables.dart
│   │   │   ├── daily_log_tables.dart   # YENİ — Aşama 1
│   │   │   ├── supplement_tables.dart  # YENİ — Aşama 1
│   │   │   └── water_log_tables.dart   # YENİ — Aşama 1
│   │   └── daos/                # Data Access Object'ler
│   │       ├── workout_dao.dart
│   │       ├── nutrition_dao.dart
│   │       ├── body_dao.dart
│   │       ├── achievement_dao.dart
│   │       ├── user_profile_dao.dart
│   │       ├── daily_log_dao.dart      # YENİ
│   │       ├── supplement_dao.dart     # YENİ
│   │       └── water_log_dao.dart      # YENİ
│   ├── seed/                    # İlk açılış başlangıç verisi
│   │   ├── seed_manager.dart
│   │   └── exercises_seed.dart
│   ├── services/                # Veri seviyesi servisler
│   │   └── export_service.dart  # MD/JSON/CSV export
│   └── providers.dart           # Global Riverpod provider'ları
│
├── features/                    # Özellik bazlı dikey diler
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── providers/
│   │       └── home_providers.dart
│   ├── workout/
│   │   ├── workout_list_screen.dart
│   │   ├── workout_session_screen.dart
│   │   ├── workout_history_screen.dart  # YENİ — Aşama 0
│   │   └── providers/
│   ├── nutrition/
│   ├── body_metrics/
│   ├── settings/
│   ├── export/
│   ├── photos/                  # YENİ — Aşama 1
│   │   ├── photo_capture_screen.dart
│   │   ├── photo_compare_screen.dart
│   │   └── providers/
│   ├── progress/                # YENİ — Aşama 2
│   │   ├── progress_screen.dart       # fl_chart grafikleri
│   │   └── providers/
│   ├── ai_assistant/            # YENİ — Aşama 1/3
│   │   ├── weekly_summary_screen.dart
│   │   ├── chat_screen.dart           # Aşama 3
│   │   └── providers/
│   └── achievements/            # YENİ — Aşama 2 (UI)
│
└── shared/                      # Birden çok feature'da kullanılan
    └── widgets/
        ├── app_shell.dart       # Bottom nav + scaffold
        ├── empty_state.dart     # YENİ — Aşama 0
        └── error_card.dart      # YENİ — Aşama 0
```

### Klasör Yapısı Kuralları

1. **Bir feature klasörü, kendi içinde dikeydir.** Provider'ları, ekranları, lokal widget'ları kendi içinde tutar.
2. **`shared/` sadece gerçekten 2+ feature'ın kullandığı şeyler için.** Tek bir feature'da kullanılan widget feature içinde kalır.
3. **`core/` business logic'ten bağımsız altyapı için.** Tema, routing, sabitler, base exception'lar.
4. **`data/` veritabanı ve dış servislerin sınırında.** Domain layer (provider'lar) bunu çağırır, UI doğrudan değil.

---

## 4. Katman: Veri (Data Layer)

### 4.1 Drift Veritabanı

**Drift**, SQLite üzerine type-safe bir ORM (Object-Relational Mapping — Nesne-İlişki Eşleme) sağlar. `build_runner` ile kod üretimi yaparız.

#### Mevcut Tablolar (V1, schema versiyon 1)

| Tablo | Sorumluluk |
|-------|------------|
| `exercises` | Hareket kataloğu (squat, bench, vb.) |
| `workout_sessions` | Antrenman seansları (tarih, faz, hafta, energy, RPE) |
| `workout_sets` | Her hareket için set/tekrar/kg kayıtları |
| `foods` | Yemek kataloğu (~600 Türk yemeği) |
| `food_logs` | Günlük yemek log'u (öğün + gram) |
| `recipe_items` | Çoklu malzemeli tarif (V1'de boş, V2 kullanılacak) |
| `body_measurements` | Kilo + ölçüler (bel, göğüs, kol, kalça, boyun, yağ %) |
| `progress_photos` | Foto path + tarih + açı (ön/yan/arka) |
| `achievements` | Rozet/başarı kayıtları |
| `user_profile` | Tek satırlık kullanıcı ayarı (hedef, faz, vb.) |

#### V2'de Eklenecek Tablolar (Aşama 1)

| Tablo | Alanlar | Amaç |
|-------|---------|------|
| `daily_log` | date, stress_level (1-10), sleep_hours, mood_note, knee_pain (0-3), elbow_pain (0-3), water_ml | Günlük sağlık snapshot |
| `supplement_log` | date, supplement_name, dose, time_taken | Takviye alımı (whey, krea, omega, Mg) |
| `water_log` | date, time, amount_ml | Su tüketimi (alternatif: daily_log içine konsolide) |

> **Karar (V2 Aşama 1'de teyit edilecek):** `water_log` ayrı mı, yoksa `daily_log.water_ml`'e mi konsolide olsun? **Önerim:** `daily_log` içine konsolide; günde 3-5 girdiyi alt-detay olarak ayrı tabloda tutmaya değmez.

#### workout_sessions ve workout_sets'e eklenecek alanlar

| Tablo | Alan | Tip | Amaç |
|-------|------|-----|------|
| `workout_sets` | `rir` | int? | Reps in Reserve (Yedek Tekrar) — PRD F-02 |
| `workout_sessions` | `elbow_status` | int? | Sakatlık takibi (knee_status zaten var) |

### 4.2 DAO Pattern (Data Access Object)

Her tablo grubu için bir DAO sınıfı vardır. DAO, **sadece veritabanı sorgularını** içerir; iş mantığı içermez.

**Örnek (mevcut workout_dao.dart felsefesi):**
```dart
@DriftAccessor(tables: [WorkoutSessions, WorkoutSets])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  Stream<List<WorkoutSession>> watchAllSessions() =>
      select(workoutSessions).watch();

  Future<int> insertSession(WorkoutSessionsCompanion entry) =>
      into(workoutSessions).insert(entry);

  // İş mantığı (örn: "geçen haftaki ağırlık") değil!
  // O Notifier'da olur.
}
```

**Kural:** DAO sadece CRUD (Create-Read-Update-Delete) + stream döner. "Geçen haftanın ortalama hacmi" gibi türetilmiş veri Notifier'da hesaplanır.

### 4.3 Migration (Şema Göçü) Stratejisi

**Mevcut durum (V1):** Schema versiyon 1, migration yok. Yeni tablo eklenirse `onCreate` çağırılır ama mevcut DB silinir. **Bu, Aşama 0'da düzeltilecek kritik eksiklik.**

**V2 mimarisi:**

```dart
@override
int get schemaVersion => 2; // V2'de 2'ye çıkar

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll(); // Sıfırdan kurulum
  },
  onUpgrade: (m, from, to) async {
    if (from == 1) {
      // V1 → V2 göçü
      await m.addColumn(workoutSets, workoutSets.rir);
      await m.addColumn(workoutSessions, workoutSessions.elbowStatus);
      await m.createTable(dailyLog);
      await m.createTable(supplementLog);
      // water_log konsolide → ayrı tablo değil
    }
  },
);
```

**Kurallar:**
1. Schema değişince **schemaVersion artırılır.**
2. `onUpgrade` her sürümden bir sonrakine yolu tarif eder.
3. **Yıkıcı migration yapılmaz** (tablo silme, kolon silme). Eski kolonu kullanmamayı seç.
4. Her migration için **integration test** yazılır (eski DB → yeni DB güvenle açılır mı).

### 4.4 SQLCipher ile Şeffaf Şifreleme (Q-05)

`drift_sqlcipher` paketi, SQLite üzerine **AES-256 şifreleme** ekler. Kullanıcı için tamamen şeffaftır.

**Akış:**
1. Uygulama ilk açıldığında, **Android Keystore**'da (iOS Secure Enclave) **256-bit rastgele anahtar** oluşturulur.
2. Bu anahtar OS-level güvenli depoda saklanır; uygulama silinince kaybolur (yedek için export gerekli).
3. DB açılırken Keystore'dan anahtar okunur, `PRAGMA key = '...';` ile DB unlock edilir.
4. Kullanıcı parola girmez — telefon kilidi açıksa app açılır.

**Kod taslağı (app_database.dart'a eklenecek):**
```dart
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fit_pack.db'));
    final key = await SecureKeyManager.getOrCreateKey(); // Keystore
    return SqfliteQueryExecutor(
      path: file.path,
      password: key,
    );
  });
}
```

**Güvenlik notu:** Cihaz root'lanırsa veya kullanıcı root user ile çalışırsa Keystore aşılabilir. **Tehdit modelimiz:** çalıntı cihazda casual saldırgan, root'lu cihazda hedefli saldırgan değil.

---

## 5. Katman: Domain (İş Mantığı)

### 5.1 Riverpod Provider Tipleri

| Provider Tipi | Ne Zaman? | Örnek |
|---------------|-----------|-------|
| `Provider` | Salt okunur, hesaplanmış değer | Toplam haftalık hacim |
| `FutureProvider` | Tek seferlik async fetch | AI özet rapor |
| `StreamProvider` | DB'den canlı stream | Workout listesi (Drift `.watch()`) |
| `NotifierProvider` | Mutasyon + state | Workout session aktif state |
| `AsyncNotifierProvider` | Async mutasyon + loading state | Yemek log'u kaydet |

### 5.2 Provider Naming & Scope

**Kural:**
- Provider isimleri `xxxProvider` ile biter.
- `autoDispose` **shared screens'de KULLANILMAZ** — geçmişte MemoRush'ta crash yaşandı ([feedback hatırası](../../.claude/projects/-Users-sametorhan/memory/feedback_riverpod_autodispose_navigation.md)).
- Sadece **modal/dialog gibi gerçekten kısa ömürlü** provider'larda `autoDispose` kullan.

### 5.3 Notifier Yapısı (örnek)

```dart
// features/workout/providers/workout_session_provider.dart
@riverpod
class WorkoutSessionNotifier extends _$WorkoutSessionNotifier {
  @override
  WorkoutSessionState build() => WorkoutSessionState.initial();

  Future<void> logSet({
    required int exerciseId,
    required int reps,
    required double kg,
    int? rir,
  }) async {
    final dao = ref.read(workoutDaoProvider);
    await dao.insertSet(/* ... */);
    state = state.copyWith(/* ... */);
  }

  // İş mantığı buraya: auto-progression önerisi, vb.
  double suggestNextWeight() { /* ... */ }
}
```

### 5.4 Cross-Provider Bağımlılık

Provider'lar birbirini `ref.watch()` veya `ref.read()` ile çağırabilir:
- **`ref.watch`** — Reactive, kaynak değişince provider yeniden hesaplanır
- **`ref.read`** — Tek seferlik okuma, side-effect içinde (örn: `onPressed`)

---

## 6. Katman: Sunum (Presentation / UI)

### 6.1 Widget Tipleri

- **`ConsumerWidget` / `ConsumerStatefulWidget`** — Provider okuyabilen widget'lar
- **`HookConsumerWidget`** — Kullanılmıyor (flutter_hooks dependency'si eklenmedi, gerek yok)
- Saf Stateless/Stateful — Provider okumayan, tekrar kullanılabilir UI parçaları

### 6.2 Tema & Stil

- `core/theme/app_theme.dart`'ta tek kaynak
- Material 3 (Material You)
- Light/Dark mode otomatik (system follow)
- `google_fonts` ile tipografi (Inter veya benzer modern font)
- Renkler: Türk fitness severlerine hitap eden enerjik palette (kırmızı/turuncu accent)

### 6.3 Navigation (go_router)

```dart
// core/router/app_router.dart
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: ...),
        GoRoute(path: '/workout', builder: ...),
        GoRoute(path: '/nutrition', builder: ...),
        GoRoute(path: '/body', builder: ...),
        GoRoute(path: '/progress', builder: ...),   // YENİ
        GoRoute(path: '/photos', builder: ...),     // YENİ
        GoRoute(path: '/ai', builder: ...),         // YENİ
        GoRoute(path: '/settings', builder: ...),
      ],
    ),
  ],
);
```

**Kural:** Bottom nav'da en fazla 5 sekme. Diğerleri (settings, photos, ai) home'dan veya menüden açılır.

---

## 7. AI Provider Soyutlaması (Pluggable LLM)

PRD F-20: "Switchable LLM provider mimarisi". V1'de Gemini, V3'te belki Claude/GPT.

### 7.1 Interface

```dart
// core/services/ai_provider.dart
abstract class AIProvider {
  String get name; // "gemini", "claude", "gpt"

  Future<String> generateText({
    required String prompt,
    int? maxTokens,
    double? temperature,
  });

  Future<WeeklySummary> generateWeeklySummary({
    required WeeklyData data,
  });

  // Gelecekte: Stream<String> generateTextStream(...)
}
```

### 7.2 Concrete Implementations

```dart
class GeminiProvider implements AIProvider {
  final GenerativeModel _model;

  GeminiProvider(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash-exp',
          apiKey: apiKey,
        );

  @override
  String get name => 'gemini';

  @override
  Future<String> generateText({...}) async {
    final response = await _model.generateContent(...);
    return response.text ?? '';
  }
}
```

### 7.3 Provider Seçimi (Riverpod ile)

```dart
@riverpod
AIProvider aiProvider(AiProviderRef ref) {
  final settings = ref.watch(userProfileProvider);
  final apiKey = ref.watch(secureStorageProvider).geminiKey;

  return switch (settings.aiProviderName) {
    'gemini' => GeminiProvider(apiKey),
    'claude' => ClaudeProvider(apiKey),  // V3+
    _ => GeminiProvider(apiKey),
  };
}
```

### 7.4 Rate Limit Yönetimi (PRD Q-03)

```dart
try {
  final summary = await aiProvider.generateWeeklySummary(...);
  state = AsyncData(summary);
} on RateLimitException catch (e) {
  state = AsyncError(
    AppException.rateLimit('Yapay zekâ günlük limiti doldu, yarın tekrar dene.'),
    StackTrace.current,
  );
  // V2+ : kural tabanlı fallback insight'a düş
}
```

---

## 8. Foto Saklama Mimarisi (Hibrit Yaklaşım — PRD Q-02)

### 8.1 Akış

```
Kullanıcı foto çeker
        │
        ▼
┌──────────────────┐
│ image_picker /   │
│ camera (orijinal)│
└────────┬─────────┘
         │
         ├──→ gal: orijinal kalitede TELEFON GALERİSİNE kaydet
         │
         └──→ flutter_image_compress: 1600px max, JPEG %85, ~500KB
                       │
                       ▼
              UYGULAMA DOCUMENTS klasörü:
              /Documents/fit_pack/photos/2026-05-13_front.jpg
                       │
                       ▼
              DB'ye sadece PATH yaz:
              progress_photos.path = '...front.jpg'
              progress_photos.angle = 'front'
              progress_photos.date = '2026-05-13'
```

### 8.2 Tasarım Kararları

1. **DB'de blob değil, dosya path'i.** SQLite'da büyük blob şişme/yavaşlama yaratır.
2. **Documents/ klasörü uygulama izolasyonu sağlar** (`getApplicationDocumentsDirectory()`).
3. **Galeri yedeği opsiyonel.** Kullanıcı izin reddederse sessizce geç, sadece DB kopyası kalır.
4. **Karşılaştırma ekranı** DB kopyasını yükler (hızlı, küçük). "Tam boy göster" derse galeriden veya orijinal path'ten yükler.

### 8.3 photo_service.dart Sorumluluğu

```dart
class PhotoService {
  Future<String> captureAndSave({
    required String angle, // 'front', 'side', 'back'
    required ImageSource source, // camera or gallery
  }) async {
    final original = await _picker.pickImage(source: source);
    if (original == null) throw AppException.userCancelled();

    // 1. Orijinali galeriye yaz (best-effort)
    try {
      await Gal.putImage(original.path, album: 'Fit Pack');
    } on PermissionException {
      // Sessizce geç, ana akış bozulmaz
    }

    // 2. Sıkıştırılmış kopyayı DB klasörüne yaz
    final compressed = await FlutterImageCompress.compressAndGetFile(
      original.path,
      _generatePath(angle),
      quality: 85,
      minWidth: 1600,
      minHeight: 1600,
    );

    return compressed!.path;
  }
}
```

---

## 9. Error Handling (Hata Yönetimi)

V1'de eksik. Aşama 0'da konacak temel mimari:

### 9.1 Domain Exception'lar

```dart
// core/errors/app_exception.dart
sealed class AppException implements Exception {
  final String userMessage; // Kullanıcıya gösterilecek
  final String? technicalDetail;
  const AppException(this.userMessage, [this.technicalDetail]);

  factory AppException.rateLimit(String msg) = RateLimitException;
  factory AppException.network(String msg) = NetworkException;
  factory AppException.database(String msg) = DatabaseException;
  factory AppException.userCancelled() = UserCancelledException;
  factory AppException.permission(String msg) = PermissionException;
  factory AppException.validation(String msg) = ValidationException;
}
```

### 9.2 UI'da Gösterim

```dart
// shared/widgets/error_card.dart kullanımı:
ref.listen<AsyncValue<T>>(provider, (prev, next) {
  next.whenOrNull(
    error: (err, _) {
      if (err is AppException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.userMessage)),
        );
      } else {
        // Beklenmeyen hata — log + generic mesaj
      }
    },
  );
});
```

### 9.3 Global Catch

`main.dart`'ta:
```dart
FlutterError.onError = (details) {
  // Log dosyasına yaz, kullanıcıya bildirmeden devam
};
PlatformDispatcher.instance.onError = (error, stack) {
  // Beklenmeyen async hatalar
  return true;
};
```

---

## 10. Input Validation (Aşama 0)

V1'de eksik. Aşama 0'da konacak basit kurallar:

| Alan | Kural |
|------|-------|
| Kilo (kg) | 30-300 arası |
| Set ağırlık (kg) | 0-500 arası |
| Tekrar sayısı | 1-100 arası |
| RIR | 0-10 arası |
| Stres seviyesi | 1-10 arası |
| Yemek gramaj | 1-2000 arası |
| Su (ml) | 0-5000 günde |

**Pattern:** Form widget'larında `TextFormField.validator` + Notifier'da double-check.

---

## 11. Bildirim Mimarisi (Aşama 2)

`flutter_local_notifications` ile lokal scheduled notification. Server gerektirmez.

```dart
// core/services/notification_service.dart
class NotificationService {
  Future<void> scheduleSupplementReminder(TimeOfDay time, String name) async {
    await _plugin.zonedSchedule(
      uniqueId,
      'Takviye zamanı 💊',
      '$name almayı unutma',
      _nextInstanceOf(time),
      // ...
    );
  }
}
```

**Kural:** Bildirim izni reddedilirse (PRD Q-04) → sessizce devam, in-app reminder widget'ı home ekranında göster.

---

## 12. Test Mimarisi (Detay: docs/05-testing.md)

| Test Tipi | Hangi Katmanda | Kapsamı |
|-----------|----------------|---------|
| Unit | Notifier'lar | İş mantığı (auto-progression, hesaplamalar) |
| Widget | UI widget'ları | Render + interaction |
| Integration | DAO'lar + DB | Migration test'leri özellikle |
| End-to-end | Kritik akışlar | Workout log → save → grafik göster |

**Aşama 0'da minimum:** Migration test'leri + WorkoutDao integration test'leri.

---

## 13. Build & Code Generation

### 13.1 Drift Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

Bunu **her tablo değişikliğinden sonra** çalıştır. `*.g.dart` dosyaları üretir.

### 13.2 Riverpod Code Generation

`@riverpod` annotation'ı kullanan provider'lar için aynı `build_runner` üretir. `_$XxxNotifier` mixin'leri ve provider sembolleri otomatik gelir.

### 13.3 CI/CD (Aşama 4+)

V2 boyunca yok (lokal pilot). V3 public release öncesi GitHub Actions ile:
- `flutter analyze` + `flutter test` her PR'da
- `flutter build apk --release` tag'lerde

---

## 14. Geleceğe Hazırlık (V3 Forward Compat)

### 14.1 Cloud Sync Hazırlığı

V2 lokal-only ama V3'te bulut senkronu için bugünden hazırlık:
- Tüm tablolarda `updated_at TIMESTAMP` alanı (last-write-wins için)
- Tüm tablolarda `id` olarak `uuid` veya `int` + cihaz prefix (gelecekte çakışma önler)
- **V2'de uygulanmaz, sadece tasarım kararında belgelenir.**

### 14.2 Multi-User Hazırlığı

- `user_profile` tablosu tek satırlı; V3'te `user_id` foreign key tüm tablolara eklenecek.
- V2'de bu kolonun eklenmesi gereksiz overhead, ertelendi.

### 14.3 Premium / Kullanıcı Kendi API Key'i

- AI provider arayüzü zaten soyut; V3'te kullanıcı kendi key'ini girip kendi quota'sını kullanır.
- `secure_storage` zaten key tutuyor; sadece UI eklenecek.

---

## 15. Mimari Karar Kayıtları (ADR Özet)

| ADR | Konu | Karar | Tarih |
|-----|------|-------|-------|
| ADR-001 | State management | Riverpod (bloc/provider yerine) | 2026-05-10 |
| ADR-002 | DB | Drift (hive/isar yerine) | 2026-05-10 |
| ADR-003 | Routing | go_router (Navigator 2.0 yerine) | 2026-05-10 |
| ADR-004 | Foto saklama | Hibrit (DB sıkıştırılmış + galeri orijinal) | 2026-05-13 |
| ADR-005 | DB şifreleme | SQLCipher + Android Keystore (transparent) | 2026-05-13 |
| ADR-006 | AI provider | Switchable interface, Gemini başlangıç | 2026-05-10 |
| ADR-007 | Schema versioning | Drift migration zorunlu, yıkıcı migration yok | 2026-05-13 |
| ADR-008 | Local-first | V1-V2 lokal, V3'te cloud sync düşünülecek | 2026-05-10 |

---

## 16. Riskler ve Azaltma (Architectural Risks)

| Risk | Etki | Azaltma |
|------|------|---------|
| SQLCipher entegrasyonu V1 DB'sini bozar | Yüksek | Aşama 0'da migration script + yedek olarak `.unencrypted.db` üretip karşılaştır |
| Foto sıkıştırma kalitesi yetersiz | Orta | A/B test: %85 vs %90 vs %75; Samet karar versin |
| Gemini API limit dolması | Orta | Rate limit handling + V3'te kullanıcı kendi key |
| Drift code generation hatası | Düşük | `build_runner` cache temizle + Drift versiyon kilidi |
| Riverpod autoDispose ile crash | Orta | MemoRush deneyimi → shared screens'de kullanılmaz, kuralla belgelendi |

---

## 17. Sonraki Adım

Bu doküman onaylanınca:
- `docs/03-ux-flows.md` — Kullanıcı akışları (wireframe seviyesi)
- `docs/04-roadmap.md` — Aşama 0-4 detay zaman planı
- `docs/05-testing.md` — Test stratejisi
- `docs/06-workflow.md` — DevOps + geliştirme şekli

---

## 18. Onay & Versiyon

| Versiyon | Tarih | Değişiklik | Onay |
|----------|-------|------------|------|
| 1.0 (taslak) | 2026-05-13 | İlk taslak — PRD v1.1 üzerine inşa | ⏳ Beklemede |
