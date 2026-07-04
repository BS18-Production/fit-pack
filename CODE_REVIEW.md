# Fit Pack — Kod İncelemesi (Code Review)

> **Tarih:** 2026-07-04 · **İnceleyen:** Claude (Faz 1 denetimi, salt-okunur)
> **Kapsam:** `lib/` el yazımı ~15.000 satır (64 dosya), testler, pubspec, Android yapılandırması
> **Temel:** `fix/active-session-persistence` dalı (`595f465`)

---

## Yönetici Özeti

Uygulama, "vibe coding" ile yazılmış bir proje için **beklenenin çok üzerinde düzenli**: tutarlı klasör yapısı, örnek nitelikte veritabanı migration zinciri (v1→v8, kayıpsız), her ekranda hata/boş/yükleniyor durumları, 90 adet geçen test ve sıfır analiz uyarısı var. Çöp kod, debug print, TODO kalıntısı yok denecek kadar az.

Buna rağmen **1 kritik, 5 yüksek** öncelikli sorun bulundu. En önemlileri: (1) yedekten geri yükleme sırasında işlem yarıda kesilirse **son verilerin kalıcı kaybolabilmesi**, (2) gün sınırındaki bir sorgu hatası yüzünden **geçmişe girilen yemeklerin iki güne birden sayılması** (kalori istatistikleri sessizce yanlışlanıyor), (3) aktif antrenmanda ortadaki bir hareketi silince **ekranda görünen sayıların kayıtla uyuşmayabilmesi**. Ayrıca uygulama şu an **Play Store'a çıkamaz** (debug imzası + eski targetSdk).

Orta seviyede en yaygın yapısal borç: veri değişince ekranların elle tek tek "tazele" komutuyla güncellenmesi — bir yer unutulunca ekranlar eski veri gösteriyor (örnek: kilo girince Ana Sayfa güncellenmiyor). Bu, gelecekte en çok hata üretecek kalıp.

---

## Bulgular Tablosu

| ID | Önem | Dosya | Özet |
|----|------|-------|------|
| C-01 | 🔴 CRITICAL | `settings/backup_service.dart` | Geri yükleme yarıda kesilirse veri kaybı: WAL dosyaları kopyadan ÖNCE siliniyor, mevcut DB'nin emniyet kopyası alınmıyor |
| H-01 | 🟠 HIGH | `daos/nutrition_dao.dart` | Gün sınırı çift sayım: `isBetweenValues` iki ucu da dahil ediyor; gece yarısına yazılan kayıtlar (tarih seçici / "dünü kopyala") bir önceki günün toplamına DA giriyor |
| H-02 | 🟠 HIGH | `workout/active_session_screen.dart` | Dinamik listede `key` yok: seans ortasından hareket silinince metin kutuları yanlış değer gösteriyor (ekran ≠ kayıt) |
| H-03 | 🟠 HIGH | `settings_screen.dart`, `cloud_account_screen.dart` | Geri yükleme sonrası "kapat" diyaloğu geri tuşuyla kapatılabiliyor → uygulama KAPALI veritabanıyla çalışmaya devam ediyor, her ekran hata veriyor |
| H-04 | 🟠 HIGH | `android/app/build.gradle.kts` | Release derlemesi debug anahtarıyla imzalı + targetSdk 34 → Play Store'a çıkılamaz |
| H-05 | 🟠 HIGH | `body_metrics_screen.dart` + genel | Önbellek kopması: ölçüm/kilo girilince `weightTrendProvider`/`latestWeightProvider` tazelenmiyor → Ana Sayfa "Son Kilo" ve Ayarlar TDEE eski değeri gösteriyor |
| H-06 | 🟠 HIGH | `active_session_screen.dart` `_finish()` | Seans kaydı transaction'sız + try/catch'siz: yazım yarıda kesilirse yarım seans DB'de kalır, "Bitir" düğmesi sonsuza dek kilitli kalır |
| M-01 | 🟡 MEDIUM | `active_session_screen.dart`, `workout_draft.dart` | Taslaktan devam edilen seans rutin bağını kaybediyor (`widget.routineId` null geliyor, taslaktaki `routineId` kullanılmıyor) |
| M-02 | 🟡 MEDIUM | `home_providers.dart`, `routine_providers.dart` | "Bugün" verileri gece yarısını geçince bayat kalıyor; Home pull-refresh `todayRoutineProvider`'ı tazelemiyor |
| M-03 | 🟡 MEDIUM | `active_session_screen.dart` | Dinlenme sayacı saniye "tık" sayarak çalışıyor; uygulama arka plana alınınca duruyor, dönüşte kalan süre yanlış |
| M-04 | 🟡 MEDIUM | `main.dart`, `seed_manager.dart` | Her açılışta (ilk kare çizilmeden önce) 1022 hareketlik JSON parse + 2 tam tablo taraması + dedupe çalışıyor — açılışı yavaşlatır, bir kez yapılıp işaretlenmeli |
| M-05 | 🟡 MEDIUM | `routine_builder_screen.dart` `_save()` | Rutin kaydı transaction'sız: önce hareketler siliniyor sonra tek tek ekleniyor; ortada hata = rutinin hareketleri kaybolur; hata yakalanmıyor (`_saving` kilitli kalır) |
| M-06 | 🟡 MEDIUM | `nutrition_screen.dart`, `body_metrics_screen.dart` | `WidgetRef`'in StatefulWidget'a parametre geçilmesi (anti-pattern); "Geri al" SnackBar'ı ekran kapandıktan sonra ölü `ref` kullanabiliyor |
| M-07 | 🟡 MEDIUM | `services/export_service.dart` | Dışa aktarma V2 verilerini içermiyor: RPE, set tipi, süre/mesafe, su, rutinler raporda yok |
| M-08 | 🟡 MEDIUM | `cloud/auth_service.dart`, `AndroidManifest.xml` | Google girişi `fitpack://login-callback`'e yönlendiriyor ama Manifest'te intent-filter yok → OAuth dönüşü uygulamaya asla ulaşamaz; `signOut` hatası yakalanmıyor |
| M-09 | 🟡 MEDIUM | `daos/`, `tables/`, `app_constants.dart` | Ölü kod: `achievements` + `recipe_items` tablo/DAO'ları hiç kullanılmıyor; `progress_photos` DAO'su UI'sız; AppConstants'ın 9 sabitinden 7'si kullanılmıyor |
| M-10 | 🟡 MEDIUM | `onboarding_screen.dart` `_finish()` | `int.parse` boş alanla çökebilir (catch yok, kullanıcıya hata gösterilmiyor); `finally` içinde `_saving=false` `setState`'siz → düğme takılı görünür |
| M-11 | 🟡 MEDIUM | `workout_summary_screen.dart` | Özet TÜM seansları çekip `firstWhere` ile arıyor; DAO'da `getSessionById` eksik |
| L-01 | 🔵 LOW | `pubspec.yaml` | Kullanılmayan bağımlılıklar: `uuid`, `flutter_slidable` |
| L-02 | 🔵 LOW | genel (30 çağrı) | Rota adresleri her yerde elle yazılmış string (`'/workout/active'`) — sabit sınıfı yok, yazım hatası riske açık |
| L-03 | 🔵 LOW | `home_screen.dart`, `workout_list_screen.dart` | Gradient kartlarda 17 adet elle `Colors.white/black` (tema dışı; bilinçli görünüyor ama sabitlenmeli) |
| L-04 | 🔵 LOW | `barcode_flow.dart` | İlerleme diyaloğu: sorgu diyalog kurulumundan önce biterse `progressCtx` null kalır, diyalog açık kalabilir (teorik) |
| L-05 | 🔵 LOW | `active_session_screen.dart`, profil | V1 kalıntısı `phase`/`currentWeek` alanları; yeni seanslara `phase: 0` sihirli değeri yazılıyor |
| L-06 | 🔵 LOW | `app_constants.dart` | `appVersion = '1.0.0'` pubspec'teki sürümün elle kopyası — ikisi ayrışabilir |
| L-07 | 🔵 LOW | `backup_service.dart` | Geri yüklemede şema sürümü kontrolü yok: yeni sürümden alınmış yedek eski uygulamaya yüklenirse tanımsız davranış |
| L-08 | 🔵 LOW | `daos/nutrition_dao.dart` | `like('%$q%')` — `%` ve `_` karakterleri kaçışsız (zararsız ama arama sonucu şaşırtabilir) |
| L-09 | 🔵 LOW | `core/utils/format.dart` | `fmtDuration` 1 saati aşınca "90:00" gösterir (uzun kardiyoda garip); `parseDuration`'da "1.30" = 1,3 dk (kullanıcı 1:30 sanabilir) |

---

## Detaylı Bulgular

### 🔴 CRITICAL

#### C-01 — Geri yükleme sırasında veri kaybı riski
**Dosya:** `lib/features/settings/backup_service.dart` → `restoreFromFile()` (cloud restore da aynı yoldan geçer)

**Ne oluyor:** Geri yükleme sırası şöyle: (1) canlı veritabanı kapatılır, (2) `-wal`/`-shm` yan dosyaları **silinir**, (3) yedek dosya ana dosyanın üstüne kopyalanır. WAL dosyası, henüz ana dosyaya işlenmemiş **onaylanmış son kayıtları** içerir. Adım 3 başarısız olursa (disk dolu, izin, bozuk kaynak dosya) eski veritabanı WAL'sız kalır → son antrenman/yemek kayıtları sessizce yok olur ve yeni veri de yüklenmemiş olur. Ayrıca üstüne yazmadan önce mevcut verinin emniyet kopyası alınmıyor: yanlış (ama geçerli SQLite imzalı) bir dosya seçilirse tüm veri geri dönüşsüz gider.

**Sade dille:** "Yedekten geri yükle"ye bastığında işlem yarıda kesilirse, hem eski verinin bir kısmını hem yeni yedeği aynı anda kaybedebilirsin.

**Önerilen düzeltme:** (1) Kapatmadan önce `PRAGMA wal_checkpoint(FULL)` çalıştır (WAL'ı ana dosyaya işle), (2) mevcut `fit_pack.sqlite`'ı `fit_pack.sqlite.pre-restore` olarak kopyala, (3) yedeği önce geçici ada kopyala, doğrula, sonra atomik `rename` ile yerine koy, (4) hata olursa emniyet kopyasını geri koy.

**Düzeltme riski:** Düşük — akış tek yerde, test edilebilir; davranış değişmiyor, sadece güvenlik katmanı ekleniyor.

---

### 🟠 HIGH

#### H-01 — Gün sınırında çift sayım (beslenme istatistikleri yanlışlanıyor)
**Dosya:** `lib/data/database/daos/nutrition_dao.dart` → `getLogsForDate`, `getLogsWithFoodForDate` (+ aynı kalıp `getSessionsByDateRange`, `weekWorkoutStatsProvider`)

**Ne oluyor:** Drift'in `isBetweenValues(start, end)` fonksiyonu SQL `BETWEEN` üretir — **iki uç da dahildir**. Gün sorgusu `[gün 00:00, ertesi gün 00:00]` aralığını kullanıyor; yani **ertesi günün tam gece yarısına** yazılmış kayıtlar bir önceki günün listesine ve toplamına da giriyor. Kayıtlar ne zaman tam gece yarısına düşer? (a) Beslenme ekranında tarih seçiciyle geçmiş bir gün seçip yemek girince (`selectedDateProvider` gece yarısı döner), (b) "Dünün öğünlerini kopyala" kullanınca. İkisi de aktif kullanılan özellikler.

**Sade dille:** Dün için sonradan yemek girersen, o yemekler *evvelsi günün* kalori toplamında da görünür — istatistikler sessizce şişer.

**Önerilen düzeltme:** DAO'da tek bir gün-aralığı yardımcı fonksiyonu: `date >= start AND date < end` (`isBiggerOrEqualValue` + `isSmallerThanValue`). Tüm tarih-aralığı sorguları bu kalıba geçirilir.

**Düzeltme riski:** Düşük — sorgu semantiği netleşiyor; tam gece yarısı kayıtları artık tek güne sayılacak (istenen davranış). Regresyon testi eklenmeli.

#### H-02 — Aktif seansta ekran ile kayıt uyuşmazlığı (eksik `key`)
**Dosya:** `lib/features/workout/active_session_screen.dart` → `_ExerciseBlock`/`_SetRow` listeleri

**Ne oluyor:** Hareket ve set satırları `key`'siz üretiliyor ve hücreler `TextFormField(initialValue: ...)` kullanıyor. Flutter, key olmayan listelerde widget durumunu **konuma göre** eşler. Seansın ortasından bir hareket silindiğinde, alttaki hareketin metin kutuları silinen hareketin *yazılı metnini* devralır; model (kaydedilecek veri) ise doğru kalır. Sonuç: kullanıcı ekranda 60 kg görür ama kayda başka değer gider (veya tersi).

**Sade dille:** Antrenman ortasında bir hareketi listeden kaldırırsan, alttaki hareketin kutularında bir anda yanlış sayılar belirebilir ve kaydedilen antrenman ekranda gördüğünle aynı olmayabilir.

**Önerilen düzeltme:** `_SessionExercise` ve `_SetEntry` nesnelerine `ObjectKey`/`ValueKey` ver (`_ExerciseBlock(key: ObjectKey(e), ...)`, set satırlarına da). "Set Çıkar" yalnız son seti sildiği için asıl tetikleyici hareket silme; ikisi de kapsanmalı.

**Düzeltme riski:** Çok düşük — key eklemek davranışı değiştirmez, yalnızca durum eşlemesini düzeltir.

#### H-03 — Geri yükleme sonrası "kapalı veritabanıyla yaşayan uygulama"
**Dosyalar:** `settings_screen.dart` `_restore()`, `cloud_account_screen.dart` `_restore()`

**Ne oluyor:** Geri yükleme veritabanı bağlantısını kapatır, sonra "Uygulamayı Kapat" düğmeli diyalog gösterir. `barrierDismissible: false` yalnız dışarı dokunuşu engeller; **Android geri tuşu diyaloğu kapatır**. Kullanıcı geri tuşuna basarsa uygulama kapalı bağlantıyla çalışmaya devam eder → her ekran hata durumuna düşer, kullanıcı "uygulama bozuldu" sanır (veri sağlamdır ama görünmez).

**Önerilen düzeltme:** Diyaloğu `PopScope(canPop: false)` ile sarmak; ideali diyalog yerine doğrudan yeniden başlatma akışı ya da DB bağlantısını yeniden kurabilen bir mekanizma.

**Düzeltme riski:** Çok düşük.

#### H-04 — Yayın engelleyiciler: debug imzası + targetSdk 34
**Dosya:** `android/app/build.gradle.kts`

**Ne oluyor:** `release` derlemesi `signingConfigs.getByName("debug")` ile imzalanıyor — Play Store debug imzalı paket kabul etmez; ayrıca her `flutter build` ortamında imza değişir, cihazda "uygulama güncellenemiyor" sorunları çıkar. `targetSdk = 34`: Google Play, güncel gereklilik olarak yeni sürümlerde daha yüksek target istiyor (2025 sonundan itibaren 35).

**Sade dille:** Bu haliyle uygulama mağazaya yüklenemez. Kendi telefonunda kullanmak için sorun değil, ama "yayın" hedefi varsa bu ilk iş.

**Önerilen düzeltme:** MemoRush'ta yaptığın gibi `key.properties` + upload keystore oluştur, `signingConfig` bağla; `targetSdk`'yı Flutter'ın önerdiği güncel değere çek ve gerçek cihazda doğrula.

**Düzeltme riski:** Orta — imza değişimi mevcut kurulu (debug imzalı) uygulamanın üstüne güncelleme yüklenememesi demek; telefondaki veriyi önce yedekleyip taşımak gerekir. **Uygulamadan önce sana soracağım.**

#### H-05 — Önbellek kopması: kilo girince Ana Sayfa güncellenmiyor
**Dosyalar:** `body_metrics_screen.dart` (kayıt/silme yalnız `allMeasurementsProvider`'ı tazeler), `home_providers.dart` (`weightTrendProvider`, `latestWeightProvider`)

**Ne oluyor:** Uygulamanın veri-tazeleme deseni "her yazan ekran, etkilenen provider'ları elle `invalidate` eder" şeklinde. Bu desen kırılgan ve burada fiilen kırılmış: yeni kilo ölçümü eklendiğinde Ana Sayfa'daki "SON KİLO", Ayarlar'daki TDEE (Toplam Günlük Enerji Harcaması) kartı ve seans kalori tahmini **eski kiloyu** kullanmaya devam ediyor (pull-refresh yapana ya da uygulamayı yeniden açana kadar).

**Önerilen düzeltme (iki seviye):**
1. *Hızlı yama:* ölçüm ekle/sil noktalarına eksik `invalidate` çağrılarını ekle.
2. *Kalıcı çözüm (önerilen, Faz 2'de ayrıca konuşuruz):* Drift'in `watch()` stream'leri zaten var — okuma provider'larını `StreamProvider`'a çevirince DB değişince ekranlar **kendiliğinden** güncellenir, elle invalidate ağı tamamen ortadan kalkar. Daha büyük ama bu hata sınıfını kökten bitiren iş.

**Düzeltme riski:** Hızlı yama: sıfıra yakın. Stream geçişi: orta — ekran ekran, testle ilerlenmeli.

#### H-06 — Seans kaydı transaction'sız ve hatasız-varsayımlı
**Dosya:** `active_session_screen.dart` → `_finish()`

**Ne oluyor:** "Bitir"e basınca önce seans satırı, sonra her set tek tek `await` ile yazılıyor. (1) Ortada bir hata olursa yarım seans DB'de kalır (seans var, setlerin bir kısmı yok). (2) Hiç `try/catch` yok ve `_saving=true` `finally` ile geri alınmıyor → hata durumunda "Bitir" düğmesi sonsuza dek dönen çember olarak kalır, kullanıcı seansı kaydedemez (taslak durduğu için veri kurtulur ama kullanıcı bunu bilemez). Aynı kalıp `routine_builder._save()`'de de var (M-05).

**Önerilen düzeltme:** Yazımları `db.transaction(...)` içine al; `try/catch/finally` ile hata mesajı göster ve `_saving`'i her durumda kapat. Setleri `insertSets` (batch) ile tek seferde yaz.

**Düzeltme riski:** Düşük — davranış aynı, yalnız atomikleşiyor.

---

### 🟡 MEDIUM

#### M-01 — Taslaktan devam eden seans rutin bağını kaybediyor
`_finish()` ve `_buildDraft()` rutin kimliği için `widget.routineId` kullanıyor; resume rotası (`/workout/active/resume`) bunu null geçer. Taslak `routineId`'yi taşıdığı halde kullanılmıyor → arka planda ölüp geri dönülen seans, kayıtta rutinsiz görünür (geçmiş/istatistik bağı kopar). *Düzeltme:* `_restoreFromDraft` içinde `routineId`'yi state'e al; `widget.routineId` yerine bu state kullanılsın. Risk: düşük.

#### M-02 — "Bugün" önbelleği gece yarısını tanımıyor
`todayNutritionProvider`, `todayWaterProvider`, `todayRoutineProvider`, seçili beslenme günü (`selectedDateProvider`) hepsi kurulduğu andaki `DateTime.now()`'a kilitli. Uygulama gece açık kalır ya da ertesi sabah arka plandan dönerse Ana Sayfa dünün verisini "bugün" diye gösterir. Ek olarak Home pull-refresh listesinde `todayRoutineProvider` yok. *Düzeltme:* uygulama `resumed` olduğunda gün değiştiyse ilgili provider'ları tazeleyen küçük bir lifecycle gözlemcisi + refresh listesine ekleme. Risk: düşük.

#### M-03 — Dinlenme sayacı arka planda şaşıyor
Sayaç her saniye `_restRemaining--` yapıyor; Android arka planda timer'ı dondurur, dönüşte kalan süre gerçek geçen zamanı yansıtmaz. *Düzeltme:* hedef bitiş zamanı (`DateTime deadline`) sakla, tick'te `deadline.difference(now)` göster. Risk: düşük.

#### M-04 — Açılışta gereksiz ağır iş
Her açılışta (runApp'ten önce!): tüm hareket tablosu 2 kez taranıyor, 1022 kayıtlık `exercises_extended.json` parse ediliyor, dedupe kontrolü koşuyor. Kurulum büyüdükçe açılış yavaşlar. *Düzeltme:* `shared_preferences`'e "seedVersion" yaz; sürüm eşleşiyorsa backfill/dedupe hiç çalışmasın (yeni içerik geldiğinde sürüm artırılır). Risk: düşük — idempotent işlemler zaten, sadece atlama koşulu ekleniyor.

#### M-05 — Rutin kaydetme "önce sil sonra yaz" ve korumasız
Düzenlemede `clearRoutineExercises` → döngüyle ekleme, transaction yok, `try/catch` yok. Ortada hata: rutinin hareket listesi kaybolur + `_saving` kilitli kalır. *Düzeltme:* H-06 ile aynı kalıp. Risk: düşük.

#### M-06 — `WidgetRef`'i widget'a parametre geçme + ölü ref riski
`_AddFoodSheet(ref: ref)`, `_AddMeasurementSheet(ref: ref)` — Riverpod'da doğrusu `ConsumerStatefulWidget`. Ayrıca beslenmedeki "Geri al" SnackBar aksiyonu, ekran kapandıktan sonra basılırsa dispose edilmiş `ref` kullanır (hata fırlatır, geri alma çalışmaz). *Düzeltme:* sheet'leri `ConsumerStatefulWidget` yap; SnackBar aksiyonunda DAO referansını önceden yakala. Risk: düşük.

#### M-07 — Dışa aktarma V2 verilerini kapsamıyor
Rapor (MD/JSON/CSV) hâlâ V1 şemasını yansıtıyor: set RPE'si, set tipi (ısınma/drop/failure `setType`'ta ama CSV'de sadece eski `isWarmup` var), süre/mesafe (kardiyo setleri boş görünür), su takibi, rutin tanımları yok. *Düzeltme:* snapshot ve üç formatlayıcıya yeni alanları ekle. Risk: düşük (yalnız çıktı zenginleşir).

#### M-08 — Google girişi teknik olarak tamamlanamaz durumda
`signInWithGoogle` `fitpack://login-callback`'e yönlendiriyor ama `AndroidManifest.xml`'de bu scheme için intent-filter yok — tarayıcıdan dönüş uygulamaya asla ulaşmaz. UI hatayı "yapılandırılmadı" diye yutuyor (tutarlı) ama düğme kullanıcıya boş vaat. Ayrıca `_signOut` try/catch'siz (ağ yokken hata). *Karar noktası:* Google girişi yakın vadede kurulacak mı? Kurulmayacaksa düğmeyi gizlemek en dürüst çözüm. Risk: düşük.

#### M-09 — Ölü kod ve ölü şema üyeleri
- `achievements` tablosu + `AchievementDao`: hiçbir yerden çağrılmıyor (P-14 kararı bekliyor).
- `recipe_items` + DAO metotları: kullanılmıyor.
- `progress_photos` DAO metotları: UI yok (planlı özellik — kalabilir, işaretlenmeli).
- `AppConstants`: 9 sabitten 7'si (rest süreleri, streak eşikleri, deload, faz haftaları) hiçbir yerde kullanılmıyor — V1 kalıntısı.
*Not:* ADR-007 gereği tablolar migration ile SİLİNMEZ; ölü DAO/sabit kodu temizlenir, tablolar "kullanım dışı" olarak belgelenir. Risk: sıfıra yakın.

#### M-10 — Onboarding bitirme akışında kırılganlık
`int.parse(_kcalCtrl.text)` — alan boşsa `FormatException` (akış `_canAdvance` ile korunuyor ama savunmasız), hata kullanıcıya hiç gösterilmiyor, `finally { _saving = false; }` `setState`'siz olduğundan düğme takılı görünür. Ayrıca `onboarding_calc.dart`'taki "profil yaş/cinsiyet tutmadığından" yorumu v8 sonrası bayat. *Düzeltme:* `tryParse` + hata SnackBar'ı + `setState`. Risk: düşük.

#### M-11 — Özet ekranı tüm seansları çekiyor
`_summaryProvider` `getAllSessions()` + `firstWhere` — DAO'ya `getSessionById(int)` eklenmeli. Kayıt bulunamazsa `StateError` (hata durumu ekranda karşılanıyor ama sebepsiz maliyet). Risk: sıfıra yakın.

---

### 🔵 LOW

- **L-01:** `uuid` ve `flutter_slidable` pubspec'te ama hiç import edilmiyor → kaldır.
- **L-02:** 30 çağrı noktasında rota adresi elle string. `AppRoutes` sabit sınıfı (`static const workoutActive = '/workout/active'`) yazım hatası sınıfını bitirir.
- **L-03:** Gradient kartlardaki `Colors.white` kullanımı (17 yer) bilinçli görünüyor; `AppColors.onGradient` gibi tek sabite bağlanmalı.
- **L-04:** `barcode_flow` ilerleme diyaloğu: sorgu diyalog kurulmadan biterse kapanmayabilir (teorik yarış). Diyaloğu `await`'ten önce garanti kurmak ya da `rootNavigator.pop` ile kapatmak yeterli.
- **L-05:** Yeni seanslara `phase: 0` yazılıyor; profildeki `currentPhase/currentWeek` V1 kalıntısı — V3 şema temizliğinde ele alınmalı (yıkıcı migration yasak, şimdilik belgele).
- **L-06:** `AppConstants.appVersion` pubspec ile elle senkron — `package_info_plus` ya da tek kaynak yorum notu.
- **L-07:** Geri yüklemede yedeğin şema sürümü (`user_version`) kontrol edilmiyor; yeni sürüm yedeği eski uygulamaya yüklenirse tanımsız davranış. Kontrol + kullanıcıya net mesaj.
- **L-08:** `searchFoods` LIKE kaçışı yok (`%`/`_`); pratik etkisi ihmal edilebilir.
- **L-09:** `fmtDuration(5400)` → "90:00"; saat desteği eklenebilir. `parseDuration("1.30")` = 78 sn — kullanıcı 1:30 sanabilir; nokta girişini de `:` gibi yorumlamak tartışılır, en azından belgelendi.

---

### ✅ İyi Durumda Olanlar (değişiklik önerilmez)

- **Migration zinciri (v1→v8):** additive, `from/to` korumalı, her adım testli — örnek kalite.
- **OpenFoodFacts servisi:** timeout, hata yutma, offline-first — doğru tasarım.
- **Controller disiplini:** tüm `TextEditingController`'lar dispose ediliyor; sızdıran timer/subscription yok.
- **Tema/token kullanımı:** ~%98 merkezî token (AppSpacing/AppRadius/context.colors).
- **Test altyapısı:** 30 dosya, migration tripwire, lossless göç testleri.
- **Analiz:** `flutter analyze` 0 uyarı; debug print/TODO yok.

---

## Önerilen Düzeltme Planı (Faz 2 batch'leri)

| Batch | Kapsam | İçerik | Not |
|-------|--------|--------|-----|
| **1 — Veri güvenliği** | CRITICAL + veri bütünlüğü | C-01, H-03, H-06, M-05, L-07 | Yedek/geri yükleme + transaction'lar. Cihazda test şart. |
| **2 — Doğruluk** | HIGH | H-01 (gün sınırı), H-02 (key'ler), H-05 hızlı yama, M-01, M-10, M-11 | Regresyon testleri eklenir. |
| **3 — Tazelik & dayanıklılık** | MEDIUM | M-02 (gece yarısı), M-03 (sayaç), M-04 (açılış), M-06 (ref anti-pattern), L-04 | Davranış-koruyucu refactor'lar. |
| **4 — Temizlik & tutarlılık** | MEDIUM/LOW | M-07 (export V2), M-09 (ölü kod), L-01, L-02, L-03, L-05, L-06, L-08, L-09 | Kozmetik + bakım borcu. |
| **Ayrı karar — Yayın** | HIGH | H-04 (imza + targetSdk), M-08 (Google girişi) | Keystore oluşturma + cihazdaki verinin taşınması senin kararını gerektirir. |
| **Ayrı karar — Mimari** | öneri | H-05 kalıcı çözüm: Future+invalidate → Drift `watch()` StreamProvider geçişi | Büyük ama "bayat ekran" hata sınıfını kökten bitirir. İstersen Batch'lerden sonra planlarız. |

---

## Düzeltmeler sırasında keşfedilenler

- **D-01 (Batch 1'de bulundu ve düzeltildi):** `backup_service.dart` kaynak dosyasında, `_isSqlite` doc yorumunun içinde **gerçek bir NUL baytı (0x00)** vardı ("SQLite format 3␀"). Dart derleyicisi şikayet etmiyordu ama `grep` dosyayı ikili (binary) sayıyor, metin araçları şaşıyordu. Yorum `"SQLite format 3" + NUL` olarak yeniden yazıldı.

## Batch Durumu

- ✅ **Faz 3 — Kurallar & guardrail'ler (2026-07-04):** [CONVENTIONS.md](CONVENTIONS.md) oluşturuldu (klasör yapısı, kanonik Riverpod kalıbı, kalıcılık/tarih-aralığı/transaction/şema kuralları, AppRoutes navigasyon kuralı, tema/sabit kuralları, hata yönetimi standardı, "bitti" tanımı — hepsi bu koddan gerçek örneklerle). Proje-içi [CLAUDE.md](CLAUDE.md) oluşturuldu → her oturumda CONVENTIONS.md'yi zorunlu okuma olarak işaretliyor.

- ✅ **Batch 4 — Temizlik & tutarlılık (2026-07-04):** M-07 (export servisi V2 kapsamı: set RPE/tipi/süre/mesafe/isComplete, su takibi, rutin tanımları — MD+JSON+CSV), M-09 (ölü kod: `achievementDaoProvider`, ölü `recipe_items` DAO metotları, kullanılmayan 7 `AppConstants` sabiti — `achievements`/`recipe_items` tabloları ADR-007 gereği belgeli korundu), L-01 (`uuid` + `flutter_slidable` bağımlılıkları kaldırıldı), L-02 (`AppRoutes` merkezi rota sabitleri: router + 10 ekrandaki ~30 çağrı ham string'den kurtuldu), L-03 (`AppColors.onGradient` — gradient yüzeylerdeki `Colors.white` tek sabite bağlandı; barkod kamera ekranı meşru istisna olarak belgelendi), L-06 (appVersion tek-kaynak notu), L-08 (kullanılmayan `searchFoods` kaldırıldı — kaçışsız LIKE riski de gitti), L-09 (`fmtDuration` 1 saati aşınca `s:dk:sn`). Doğrulama: analyze 0 · test 102/102 (3 yeni: `export_v2_test.dart`) · debug APK derlendi.
- ✅ **Batch 3 — Tazelik & dayanıklılık (2026-07-04):** M-02 (`_DayRolloverGuard` app.dart'ta: uygulama öne gelince gün değiştiyse güne bağlı provider'lar tazelenir + beslenme seçili günü bugüne döner; Home refresh listesine `todayRoutineProvider` eklendi), M-03 (dinlenme sayacı `_restDeadline` duvar saatine bağlandı — arka plan dönüşünde doğru), M-04 (`SeedManager.seedVersion` + prefs bayrağı: açılıştaki backfill/dedupe/JSON parse artık tek seferlik; geri yükleme bayrağı siler), M-06 (`_AddFoodSheet`/`_AddMeasurementSheet` → ConsumerStatefulWidget; "Geri al" SnackBar'ı DAO + kök container yakalar — ekran kapansa da çalışır), L-04 (barkod ilerleme diyaloğu yarış koruması). Doğrulama: analyze 0 · test 99/99 · debug APK derlendi.
- ✅ **Batch 2 — Doğruluk (2026-07-04):** H-01 (7 tarih-aralığı sorgusu `[start, end)` yarı-açık kalıba geçti + aktivite takvimindeki `-1ms` hilesi kaldırıldı), H-02 (`_ExerciseBlock`/`_SetRow` ObjectKey), H-05 hızlı yama (ölçüm ekle/sil + onboarding → `weightTrend`/`latestWeight` invalidate), M-01 (`_routineId` state: taslaktan geri yüklenir), M-10 (onboarding `tryParse` + hata SnackBar + `setState`'li finally), M-11 (`getSessionById` DAO metodu, özet artık tüm seansları çekmiyor). Doğrulama: analyze 0 · test 99/99 (3 yeni: `day_boundary_test.dart`) · debug APK derlendi.
- ✅ **Batch 1 — Veri güvenliği (2026-07-04):** C-01 (güvenli geri yükleme: checkpoint → doğrulama → emniyet kopyası → atomik rename → hatada geri alma), L-07 (yedek şema sürümü kontrolü, `readSqliteUserVersion`), H-03 (`showRestartDialog` PopScope'lu ortak diyalog + `RestoreNeedsRestartException` ile hata yolu ayrımı), H-06 (`insertSessionWithSets` transaction + seans ekranında try/catch), M-05 (`saveRoutineWithExercises` transaction + rutin ekranında try/catch). Doğrulama: analyze 0 · test 96/96 (5 yeni: `data_safety_test.dart`) · debug APK derlendi.
