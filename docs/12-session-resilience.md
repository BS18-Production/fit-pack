# docs/12 — Aktif Seans Dayanıklılığı (Session Resilience)

> **Durum:** Tasarım v1.0 — 2026-06-30
> **Kaynak:** Samet'in cihaz geri bildirimi (Push day, SM A075F)
> **Bağlı:** [docs/09-workout-v2.md](09-workout-v2.md), [NEXT_TASKS.md](../NEXT_TASKS.md)

## Sorun (cihazda yaşandı)

Antrenman sürerken uygulama arka plana alınıp başka uygulama açılınca, geri
dönüldüğünde **aktif seans sıfırlanıyor** — girilen tüm setler kayboluyor.
Ek olarak antrenman sırasında **ekran kapanıyor**, kullanıcı sürekli dokunmak
zorunda kalıyor.

### Kök neden
`ActiveSessionScreen` durumu **tamamen hafızada** (`_exercises`, `_SetEntry`,
`_startedAt`, `_elapsed`). DB'ye yazma yalnızca "Bitir"de oluyor. Bütçe cihazda
(A07, düşük RAM) Android arka plandaki process'i öldürünce hafıza uçuyor → seans
gidiyor.

## Çözüm

### 1) Taslak kalıcılığı (draft persistence)
Aktif seansı sürekli **`shared_preferences`**'e JSON taslak olarak yaz; uygulama
yeniden açılınca kurtar.

- **Anahtar:** `active_workout_draft_v1`
- **İçerik:** `title`, `routineId`, `startedAtMs`, `sessionDateMs`, ve her hareket
  için `{exerciseId, restSec, previous, sets:[{weight,reps,rpe,durationSec,
  distanceM,type,done}]}`
- **Ne zaman yazılır:**
  - `AppLifecycleState.inactive/paused` (asıl bug — uygulama arka plana alınınca).
    `_SetEntry` alanları giriş anında güncellendiği için yarım yazılmış değerler
    bile yakalanır.
  - Yapısal değişiklikte de yaz (set ekle/çıkar, hareket ekle/kaldır, ✓) — paused
    gelmeden sert kill'e karşı emniyet.
- **Ne zaman silinir:** "Bitir" (DB'ye yazıldıktan sonra) **veya** kullanıcı çıkışı
  onaylayınca (setleri atma).
- **Mod sınırı:** Yalnızca canlı seans (`manualDate == null`). Geçmiş kayıt akışı
  hızlı + tarihli, taslağa gerek yok.

### 2) Kurtarma akışı (resume)
- Antrenman ana ekranında (`workout_list_screen`) taslak varsa en üstte
  **"Devam eden antrenman"** banner'ı: başlık + geçen süre + **Devam et** / **Sil**.
- **Devam et** → `/workout/active/resume` → `ActiveSessionScreen(resume: true)`
  taslaktan state'i kurar (`getExerciseById` ile Exercise nesneleri yeniden çekilir).
- **Sil** → taslağı temizle (onay sorulur).
- Aynı anda tek seans varsayımı: yeni boş/rutin antrenman başlatmak mevcut taslağın
  üstüne yazar (v1 için kabul; kullanıcı tek seferde bir antrenman yapar).

### 3) Ekran uyanık (wakelock)
`wakelock_plus` paketi. Canlı seansta `initState`'te etkinleştir, `dispose`'ta
kapat (manuel/geçmiş kayıt modunda gereksiz).

## Kapsam dışı (sonra)
- Foreground service / kalıcı bildirim (çok uzun seanslarda OS yine de öldürebilir;
  v1 draft + paused yazımı pratikte yeterli).
- Çoklu eşzamanlı taslak.

## Doğrulama
- Emülatör: seans başlat → set gir → home'a dön → uygulamayı süreç olarak öldür
  (`adb shell am kill`) → tekrar aç → banner çıkıyor → Devam et → setler yerinde.
- `flutter analyze` 0 · ilgili testler yeşil (draft serialize/deserialize round-trip).

---

## Ek: Antrenman Geçmişi ekranı + kalori tahmini (2026-06-30)

Samet cihaz geri bildirimi: geçmiş seans detayında yazılar sığmıyor/kayıyor,
hangi set hangisi belli değil; ayrıca daha fazla faydalı bilgi (kalori) istendi.

### Layout düzeltmesi
Eski hâl: `Row(Expanded(ad) + Text(tüm setler tek string))` → ad dar sütunda
sarıyor, setler sağda sıkışıyor. Yeni hâl (`_ExerciseLog`): hareket adı **tam
genişlik başlık**, altında her set kendi satırında **numaralı rozet + hizalı
değer** (tabularFigures). Üstte **istatistik şeridi** (`_StatStrip`): süre ·
hacim · set · ~kcal.

### Kalori tahmini (`calorie_estimate.dart`)
ACSM aktif kalori: `kcal = MET × 3.5 × kilo(kg) / 200 × süre(dk)`.
- MET: kuvvet seansında ortalama RPE'ye göre 3.5–6.0; kardiyo 7.0.
- Kilo: en güncel vücut ölçümünden (`latestWeightProvider`).
- **Aktif yakımda yaş/cinsiyet/boy yok:** bunlar dinlenme metabolizmasını (BMR)
  etkiler, egzersize bağlı aktif yakımı kayda değer değiştirmez.
- UI'de "tahmindir" etiketiyle gösterilir.

### Tam günlük harcama — BMR/TDEE (şema v8, 2026-06-30) ✅
Samet onayladı → eklendi.
- **Şema v8:** `user_profile` +`birthDate` +`gender` +`activityLevel` (nullable).
  Migration v7→v8 additive, lossless test geçti. Tripwire 8.
- **Mifflin-St Jeor BMR:** `10·kg + 6.25·cm − 5·yaş + (erkek 5 / kadın −161)`.
  **TDEE** = BMR × aktiflik çarpanı (hareketsiz 1.2 … çok aktif 1.9, vars. 1.55).
- **Girdi/gösterim:** Ayarlar → Vücut → Cinsiyet / Doğum Tarihi / Aktiflik +
  **"Tahmini Günlük Harcama"** kartı (TDEE + dinlenme BMR; eksik veri varsa neyin
  gerektiğini söyler). Onboarding adım 2'ye cinsiyet + doğum tarihi (opsiyonel).

---

## Ek: Tam Yedek + Geri Yükleme (veri güvenliği, 2026-06-30)

Samet cihazdaki geçmişini kaybetmekten endişe etti. Veri yalnızca cihazda
(`fit_pack.sqlite`, bulut yok).

- **Mevcut "Veri Dışa Aktar"** = rapor (MD/JSON/CSV), okunabilir ama **geri
  yüklenemez**. Yetersiz.
- **Eklenen `backup_service.dart`:**
  - **Yedekle:** `PRAGMA wal_checkpoint(FULL)` → `.sqlite` kopyası → `share_plus`
    ile Drive/Dosyalar/e-postaya. Tam, geri yüklenebilir yedek.
  - **Geri Yükle:** `file_picker` → SQLite başlık doğrulama → `db.close()` →
    wal/shm temizle → dosyayı üstüne yaz → `SystemNavigator.pop()` (yeniden açılışta
    taze bağlantı). Ayarlar → **Verilerim**.
- **İmza notu (kritik):** Uygulama hâlâ **debug anahtarıyla** imzalı (release
  `signingConfig = debug`). Aynı makinede üretilen yeni APK **üstüne kurulunca
  veri korunur**. Play Store'a çıkışta gerçek keystore'a geçince ilk kurulum veri
  taşıması gerektirir → **o aşamadan önce yedek şart**.
