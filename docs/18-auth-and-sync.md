# 18 — Zorunlu Hesap + Supabase Senkron (Faz 2)

> **Durum:** Tasarım — onay bekliyor. Kod BAŞLAMADI.
> **Tarih:** 2026-07-21
> **İlgili:** [13-cloud-backup.md](13-cloud-backup.md) · [15-onboarding.md](15-onboarding.md) · [02-architecture.md](02-architecture.md) · [CONVENTIONS.md](../CONVENTIONS.md)

---

## 1. Amaç & kapsam

Samet kararı (2026-07-21): **uygulamanın kullanılabilmesi için hesap zorunlu olsun.**
Tüm kullanıcı verisi Supabase'de tutulsun, tüm tablolarda RLS (Row Level Security —
satır bazlı erişim güvenliği) aktif olsun.

**Bu doküman [docs/13](13-cloud-backup.md)'ün öngördüğü "Faz 2"yi hayata geçirir.**
docs/13 §2'de iki seçenek tartışılmış ve şöyle denmişti:

> **Karar: A (Storage blob).** … Faz 2 sync gelince **mirror tablolar** o zaman
> kurulur (zaten büyük iş, baştan yapmak israf).

Artık Faz 2 zamanı. Yani bu bir çelişki değil, planlanmış geçiş.

### Değişen
- Hesap **opsiyonel → zorunlu**
- Bulut yedek **blob (.sqlite dosyası) → satır bazlı mirror tablolar + senkron**
- Giriş: **e-posta/şifre + Google** (ikisi de v1'de)
- **Elle yedekleme KALDIRILDI** (aşağıda §1.1)

### 1.1 Elle bulut yedekleme kaldırıldı ✅ UYGULANDI (2026-07-21)

Samet kararı: *"Yok kullanıcı kendi gelip back up yapsın, yok restore etsin —
bunlara gerek yok. Kullanıcı giriş yaptıysa tüm verileri saklanacak."*

Doğru karar: otomatik senkron varken elle "Yedekle"/"Geri Yükle" düğmeleri hem
gereksiz hem kafa karıştırıcı — kullanıcıya olmayan bir sorumluluk yüklüyor.

**Silinenler:**
- `lib/features/cloud/cloud_backup_service.dart` (80 satır — dosya kaldırıldı)
- Hesap ekranından "Buluta Yedekle" + "Buluttan Geri Yükle" düğmeleri, son
  yedek zamanı satırı
- Hesap silme akışındaki `deleteCloudBackup()` adımı → artık gereksiz; mirror
  tablolardaki `on delete cascade` (§7) veriyi zaten temizler
- 9 ölü çeviri anahtarı (EN+TR), metin güncellemeleri: `settingsCloudAccount`
  "Bulut Hesabı" → **"Hesap"**, `cloudIntro` artık otomatik kayıttan bahsediyor

**Kalan ekran:** giriş/kayıt · hesap başlığı · Çıkış · Hesabı Sil.
Senkron durumu göstergesi Aşama G'de eklenecek (§9).

**Doğrulama:** analyze 0 · test 154/154 · emülatörde görsel doğrulandı.

### 1.2 "Veri & Gizlilik" bölümü komple kaldırıldı ✅ UYGULANDI (2026-07-21)

Samet kararı: *"Data & privacy satırını komple kaldır. Backup, account, restore,
export hiçbiri kalmasın."*

**Silinenler:**
| Öğe | Yer |
|---|---|
| Ayarlar → "Veri & Gizlilik" bölümü | `settings_screen.dart` |
| Cihaza Yedekle / Yedekten Geri Yükle | `_backup()` + `_restore()` metotları |
| Dışa Aktar satırı | Ayarlar |
| **Dışa aktar butonu** | **Ana Sayfa üst çubuğu** — Ayarlar'dan başka burada da vardı |
| `features/export/` (ExportScreen) + `AppRoutes.export` rotası | klasör silindi |
| `features/settings/backup_service.dart` | dosya silindi |
| `readSqliteUserVersion` testleri (2) | üretimde çağıranı kalmadı → 154 → **152 test** |
| 22 ölü çeviri anahtarı (EN+TR) | ARB'ler 504=504 |

**Hesap satırı silinmedi — Profil'e taşındı.** Gerekçe: hesap açtıran uygulamalarda
Google Play + Apple **uygulama içi hesap+veri silme** yolunu zorunlu tutuyor
(docs/16 §S4: *"Yüksek — mağaza reddi"* riski; docs/16 §4). Çıkış ve Hesabı Sil
oradan erişilir. Yeni yer: **Profil → ACCOUNT** bölümü (en altta, TDEE kartından
sonra).

**Ayarlar'ın son hâli:** Tercihler → Beslenme → Hakkında.

**Doğrulama:** analyze 0 · test **152/152** · emülatörde üç ekran da görsel
doğrulandı (Ana Sayfa üst çubuğu · Profil ACCOUNT bölümü · Ayarlar).

> ℹ️ `seed_manager.dart`'taki "yedekten geri yükleme bu bayrağı siler" yorumu
> bayatladığı için güncellendi.

### Değişmeyen (kritik)
- **Drift (SQLite) yerel doğruluk kaynağı olarak KALIR.** Uygulama sinyalsiz salonda
  tam çalışır. Supabase kalıcı/kanonik kopyadır, senkronla beslenir.
- Yerel kullanım **token geçerliliğinden bağımsızdır**.

---

## 2. Alınan kararlar

| # | Karar | Gerekçe |
|---|---|---|
| K-1 | Hesap zorunlu, onboarding'de atlanamaz | Samet kararı |
| K-2 | Drift yerel kaynak kalır, Supabase kanonik | Çevrimdışı salon kullanımı |
| K-3 | E-posta/şifre **+ Google** v1'de | Samet kararı |
| K-4 | Oturum **süreye bağlı düşmez** | Çevrimdışıyken giriş yapılamaz → kilitlenme riski |
| K-5 | Kullanıcıya "veri kaybolabilir" uyarısı **gösterilmez** | Doğru değil + güveni zedeler |
| K-6 | Kimlik için **`uid` kolonu eklenir**, integer PK korunur | Aşağıda §4 — göç maliyetini haftalardan güne indirir |
| K-7 | Ortak katalog tabloları kullanıcıya kopyalanmaz | Aşağıda §3 — 1022 satır × N kullanıcı israfı |

---

## 3. Tablo sınıflandırması ⚠️ (kritik bulgu)

13 tablonun hepsi kullanıcı verisi **değil**. İki tablo karma yapıda:

### 3.1 Saf kullanıcı verisi → senkron + RLS
| Tablo | Not |
|---|---|
| `UserProfile` | Kullanıcı başına tek satır |
| `WorkoutSessions` | |
| `WorkoutSets` | |
| `Routines` | |
| `RoutineExercises` | |
| `FoodLogs` | |
| `WaterIntake` | |
| `BodyMeasurements` | |
| `ProgressPhotos` | Görseller Storage'a, satır tabloya |
| `RecipeItems` | Kullanıcı tarifleri |

### 3.2 Karma: ortak katalog + kullanıcı eklemesi
| Tablo | Ortak kısım | Kullanıcı kısmı |
|---|---|---|
| `Exercises` | **1022 hareket** (seed, free-exercise-db) | `isCustom = true` satırlar |
| `Foods` | Seed besinler + OpenFoodFacts sonuçları | `isCustom = true` satırlar |

**Karar (K-7):** Ortak katalog **cihazda seed olarak kalır, senkron edilmez.**
Sadece `isCustom = true` satırlar kullanıcıya ait sayılır ve senkron edilir.

**Neden:** 1022 hareketi her kullanıcının hesabına kopyalamak hem depolama israfı
hem de anlamsız — o veri zaten uygulamayla birlikte geliyor ve herkeste aynı.

### 3.3 Senkron edilmeyen
| Tablo | Sebep |
|---|---|
| `Achievements` | Kullanılmıyor (P-14 kararı bekliyor). Karar verilene kadar kapsam dışı. |

---

## 4. Kimlik stratejisi ⚠️ (kritik bulgu)

### Sorun
Tüm tablolar `integer().autoIncrement()` birincil anahtar kullanıyor. Senkron için
bu tek başına **yetersiz ve tehlikeli**:

- İki cihaz çevrimdışıyken ikisi de "seans #47" üretir → sunucuda çakışır
- Zaman aşımı sonrası yeniden gönderim → **çift kayıt**
- Sunucu ID'si ile yerel ID farklı olur → eşleme tablosu derdi

Ayrıca FK grafiği tamamen integer üstüne kurulu:

```
FoodLogs.foodId          → Foods.id
RecipeItems.recipeId     → Foods.id
RecipeItems.foodId       → Foods.id
WorkoutSets.sessionId    → WorkoutSessions.id
WorkoutSets.exerciseId   → Exercises.id
RoutineExercises.routineId  → Routines.id
RoutineExercises.exerciseId → Exercises.id
```

### İki seçenek

| | **A. UUID'ye tam göç** | **B. `uid` kolonu ekle** ✅ |
|---|---|---|
| Ne | autoIncrement PK → UUID, her yerde | Integer PK kalır, yanına `uid TEXT UNIQUE` |
| FK'ler | Hepsi yeniden yazılır | **Dokunulmaz** |
| DAO / sorgular | Hepsi gözden geçirilir | **Dokunulmaz** |
| Migration | Yıkıcıya yakın, ADR-007 riski | **Additive** (nullable kolon + backfill) |
| Test etkisi | 154 testin çoğu | Yeni senkron testleri |
| Risk | Yüksek | Düşük |
| Süre | Haftalar | Günler |

### Karar: B

Her senkronlanan tabloya eklenir:

```dart
TextColumn get uid => text().nullable().unique()();   // istemci üretimi UUID v4
TextColumn get userId => text().nullable()();         // Supabase auth.uid()
DateTimeColumn get updatedAt => dateTime().nullable()();
IntColumn get syncState => integer().withDefault(const Constant(0))();
// 0 = temiz (senkron), 1 = beklemede, 2 = hata
```

- **Yerelde:** integer PK ve tüm FK'ler aynen çalışmaya devam eder → mevcut kodun
  hiçbiri değişmez
- **Sunucuda:** `uid` birincil anahtardır, FK'ler de `uid` üstünden kurulur
- **Senkron katmanı** çeviriyi yapar: gönderirken `sessionId(int) → session.uid`,
  çekerken `uid → yerel int id`

**Kazanç:** Göç additive kalır (ADR-007 uyumlu — yıkıcı migration yok), mevcut 154
test bozulmaz, karmaşıklık tek bir yerde (senkron katmanı) toplanır.

**Şema sürümü:** v8 → **v9** (additive; `onUpgrade` adımı + migration testi aynı
commit'te — CONVENTIONS §3).

---

### 4.1 Aşama A uygulandı ✅ (2026-07-22)

`SyncColumns` mixin'i (`tables/sync_columns.dart`) 12 tabloya eklendi, şema
**v8 → v9**. Göç: kolonlar + UUID v4 backfill (tek SQL UPDATE) + `uid` unique
index'leri + mevcut satırları kuyruğa alma.

**Yol boyunca çıkan iki gerçek sorun:**

**(1) ⚠️ ÜRETİM HATASI — ara adımların güncel tanımı kullanması.**
`m.createTable(routines)` **güncel** tablo tanımını kullanır. Yani v5→v6 adımı
`routines`'i senkron kolonlarıyla oluşturuyordu; ardından v8→v9 adımı aynı
kolonu ikinci kez ekleyip **"duplicate column" ile çökerdi** (v6 öncesinden
yükselen her kullanıcı). Aynısı `water_intake` (v3→v4) ve `routine_exercises`
için de geçerliydi.

Çözüm iki katmanlı:
- Bu üç tablo artık göç adımında **tarihsel şekliyle** (elle yazılmış CREATE
  TABLE) oluşturuluyor → ara sürüm şeması doğru kalıyor
- v9 adımı kolonu eklemeden önce `PRAGMA table_info` ile **varlık kontrolü**
  yapıyor (`_addColumnIfMissing`) → aynı hata bir daha oluşamaz

**Kural (bundan sonrası için):** göç adımları tarihte donmuştur. Yeni kolon
eklerken, o kolonu taşıyan tablo daha eski bir adımda `createTable` ile
oluşuyorsa o adım GÜNCELLENMEZ — tarihsel şekli korunur.

**(2) `syncState` non-null olamadı.** Üretilen mapper NOT NULL kolonu zorunlu
sayıyor; ara sürüme göç eden eski testler satır okurken patlıyordu. Kolon
nullable yapıldı, **NULL ≡ 0 (temiz)** — projenin "eklenen kolon nullable
olmalı" kuralıyla da tutarlı. Kuyruk sorguları `sync_state = 1` aradığı için
davranış değişmiyor.

**Doğrulama:** analyze 0 · test **156/156** (4 yeni göç testi: yapısal geçerlilik,
lossless + backfill + kuyruk ayrımı, unique index'ler, çift uid reddi) ·
**emülatörde gerçek v8→v9 göçü**: şema 9, profil birebir korundu
(2250/170/180.34/78.0/male), 1015 hareket duruyor, 1015 satırın 1015'i benzersiz
UUID aldı, katalog satırları kuyruğa GİRMEDİ (`sync_state = 0`), 12 unique index
kuruldu, uygulama sorunsuz açıldı.

---

## 5. Auth akışı

### 5.1 Zorunlu hesap — akış tasarımı (Aşama C)

Samet kararı (2026-07-22): *"Giriş yapmadan hiçbir şekilde uygulamayı
kullanamasın."* Konumlandırma **premium** — trial dışında ücretsiz kullanım yok.

> Not: Zorunlu hesap aynı zamanda **para modelinin ön şartı**. 7 günlük trial'ı
> kimin ne zaman başlattığını sunucuda tutmadan uygulayamazsın — anonim
> kullanıcıda trial takip edilemez. Karar monetizasyonla tutarlı.

#### Akış

```
① Karşılama (değer)  →  ② Giriş / Kayıt  →  ③ Onboarding  →  ④ Uygulama
     atlanamaz             atlanamaz          profil          sekmeler
```

**① Karşılama.** Çıplak giriş formuyla açılmıyoruz — kullanıcı **ne için hesap
açtığını** bilmeli. Premium ürün önce ne sattığını söyler. Tek ekran: uygulama
ikonu + ne yaptığı + (varsa) trial vaadi + **Giriş yap / Hesap oluştur**.
**"Atla" YOK.**

Yeni ekran icat edilmiyor: `docs/15` A1 "Karşılama" sayfası onboarding'den
**çıkarılıp** giriş öncesine taşınır, metni buna göre yeniden yazılır. Onboarding
4 sayfadan **3 sayfaya** iner (A2 Seni tanıyalım · A3 Planın hazır · A4 İçeride
ne var).

**② Giriş / Kayıt.** `cloud_account_screen.dart`'taki giriş formu buraya taşınır
(e-posta/şifre + Google). Artık Ayarlar'dan push edilen alt ekran değil, **tam
ekran kapı**.

**③ Onboarding.** Girişten sonra çalışır → topladığı profil verisi (cinsiyet,
doğum tarihi, boy, hedefler) **doğduğu anda hesaba bağlı** olur. Bu sıralama
"anonim veriyi hesaba taşıma" problemini tamamen ortadan kaldırır (§8.1).

#### Yönlendirme tablosu

| Oturum | `onboarded` | Gidilecek yer |
|---|---|---|
| ✗ | — | ① `/welcome` |
| ✓ | ✗ | ③ `/onboarding` |
| ✓ | ✓ | ④ `/home` |

Çıkış yapılınca ①'e döner.

#### ⚠️ Kural 1: Kapı AĞI değil, OTURUMU kontrol eder

Kapıda "internet var mı / token geçerli mi" diye ağa sorulmaz. Sorulursa uçakta,
sinyalsiz salonda kullanıcı **kendi cihazındaki kendi verisine giremez** — yerel
öncelikli mimariyi kurma sebebimizin tam tersi.

- Karar **cihazda kayıtlı oturumdan** okunur
  (`Supabase.instance.client.auth.currentSession`) — `Supabase.initialize()`
  sonrası senkron erişilir, ağ gerektirmez
- Erişim token'ı bayat olsa bile **içeri alınır**; yenileme arka planda, ağ
  gelince olur (§5.3)
- Yalnız **ilk kurulum** internet ister — bilinçli ve kabul edilmiş

#### ⚠️ Kural 2: Kapı kararı gevşek provider'dan okunmaz

Riverpod lazy `Notifier` ilk `ref.read`'de **default state döner** (bilinen ders).
Kapı kararı buna bırakılırsa açılışta bir kare yanlış ekran çizilir ya da
`pushReplacement` ile çökme riski doğar (`autoDispose` dersi).

- **Oturum:** doğrudan Supabase'in kalıcı oturumundan
- **`onboarded`:** açılışta bir kez okunur (`main.dart` zaten yapıyor), basit bir
  `ValueNotifier`'da tutulur, onboarding bitince güncellenir
- GoRouter `redirect` + `refreshListenable` ile tepkisel → çıkışta kapı anında
  devreye girer

#### ⚠️ Kural 3: Hesap değişince yerel veri temizlenir

Çıkışta yerel veri **silinmez** (hızlı yeniden giriş + çevrimdışı güvenlik). Ama
tek başına bırakılırsa **aynı cihazda ikinci bir kullanıcı giriş yapınca
öncekinin verisini görür** — gerçek veri sızıntısı.

Kural: **girişte** oturum açan `user_id`, cihazda kayıtlı son `user_id` ile
karşılaştırılır.

| Durum | Davranış |
|---|---|
| Aynı kullanıcı | Yerel veri korunur (normal yeniden giriş) |
| Farklı kullanıcı | Yerel kullanıcı verisi temizlenir, sunucudan taze çekilir |
| Kayıt yok (ilk giriş) | Mevcut yerel veri o hesaba bağlanır (§8.2 (a)) |

#### `onboarded` hesaba bağlıdır

`user_profile.onboarded` senkron listesinde (§3.1) → telefon değiştiren kullanıcı
onboarding'i **tekrar görmez**. Aşama E'de doğrulanacak.

#### Kapsam dışı (sonra)

- **Trial / paywall:** 7 gün sunucuda, hesaba bağlı tutulur. Aşama C yalnız
  **kapıyı** kurar; trial mantığı ayrı iş.
- E-posta doğrulama zorunlu olsun mu (§13 açık maddesi) — zorunluysa ilk kurulum
  ağırlaşır.

### 5.2 Sağlayıcılar
| Yöntem | Durum | Gereken kurulum |
|---|---|---|
| E-posta + şifre | Kod hazır (`auth_service.dart`) | Supabase'de e-posta doğrulama ayarı |
| **Google** | Kod hazır (tarayıcı akışı), kurulum **yapılıyor** | Google Cloud OAuth client (Web + Android) + Supabase provider + manifest intent-filter |

### 5.2.1 Google: tarayıcı akışı mı, yerel akış mı? ⚠️ AÇIK KARAR

**"Web application" client kafa karıştırıcı ama doğru.** O client senin uygulamanı
değil, **Supabase'in sunucusunu** temsil eder — Google'a dönen adres
`https://<ref>.supabase.co/auth/v1/callback` yani bir web adresi ve secret'ı orada
Supabase tutuyor. Uygulamanın platformuyla ilgisi yok.

| | **A. Tarayıcı akışı** (mevcut kod) | **B. Yerel (native) akış** |
|---|---|---|
| Çağrı | `signInWithOAuth(OAuthProvider.google)` | `google_sign_in` + `signInWithIdToken` |
| Kullanıcı deneyimi | Tarayıcı/özel sekme açılır, geri döner | Cihazdaki hesaplar listelenir, tek dokunuş |
| Gereken client | Sadece **Web** | Web + **Android** + **iOS** |
| Ek paket | Yok | `google_sign_in` |
| Kalite | İdare eder, sıçramalı | Belirgin daha iyi |

**Yönelim: B** (Samet "tam oturtalım" dedi). Karar Aşama D'de kesinleşecek; Android
OAuth client B için zaten oluşturuldu, A'da da zararsız.

### 5.2.2 Platform kimlikleri (mevcut)
| | Değer |
|---|---|
| Android paket | `com.sametorhan.fit_pack` |
| iOS bundle | `com.sametorhan.fitPack` |
| Deep link | `fitpack://login-callback` (manifest'e eklendi) |
| Debug SHA-1 | `FA:45:84:A2:D6:DB:06:A7:FE:D0:92:4A:8D:7B:CF:CA:AF:D6:06:77` |

> ⚠️ **Kimlikler tutarsız:** Android `fit_pack`, iOS `fitPack`. Flutter varsayılanı,
> hata değil — ama marka ismi netleşince **ikisi de değişecek** ve bu ancak
> **Play'e yayınlamadan önce** yapılabilir. Yayından sonra paket adı ASLA
> değişmez. Berna'nın marka ismi task'ı bu yüzden yayın öncesi kritik yolda.

> ⚠️ **Release SHA-1:** Yukarıdaki debug parmak izidir. Yayın keystore'u
> oluşturulunca onun SHA-1'i de Google'a **ayrıca eklenmeli**, yoksa Play'den inen
> sürümde Google girişi çalışmaz. Klasik tuzak.

> 🍎 **iOS notu:** Apple, üçüncü taraf giriş (Google) sunan uygulamalarda
> **"Sign in with Apple"** eklenmesini zorunlu tutuyor. iOS'a çıkılacaksa bu ek bir
> iştir. v1 Android olduğu için iOS OAuth client'ı **henüz oluşturulmadı** (bundle
> ID marka değişiminde değişeceği için erken oluşturmak israf).

### 5.3 Oturum modeli (K-4)

| Katman | Ömür | Rol |
|---|---|---|
| Erişim token'ı (access) | ~1 saat (Supabase varsayılanı) | Sadece Supabase isteklerinde |
| Yenileme token'ı (refresh) | Süresiz | Online olunca sessizce yeniler |
| **Yerel kullanım** | **Süresiz** | **Token'dan bağımsız** |

**Çevrimdışı süreye bağlı çıkış YOK.** Sebep: çıkış için ağ gerekmez ama giriş için
gerekir → kullanıcı çevrimdışıyken çıkarılırsa kendi cihazındaki kendi verisine
erişemez hale gelir.

**Çıkış yalnızca şu durumlarda:**
- Kullanıcı kendi çıkış yaptığında
- Şifre değiştiğinde (diğer cihaz oturumları düşer)
- Hesap silindiğinde
- Sunucu yenileme token'ını reddettiğinde → **yerel veri SİLİNMEZ**, uygulama
  çalışmaya devam eder, sadece *"Senkron duraklatıldı — devam etmek için tekrar
  giriş yap"* gösterilir

---

### 5.3 Google kurulumu — uçtan uca doğrulama (2026-07-21)

Kurulum tamamlandı ve emülatörde test edildi. **Google girişi çalışıyor** —
Bulut Hesabı ekranı `Signed in · sametorhan@gmail.com` gösteriyor.

Test sırasında **iki bulgu** çıktı:

#### B-1 · İzin ekranında ham Supabase alan adı görünüyor ⚠️ AÇIK
Kullanıcı Google izin ekranında şunu görüyor:
> *"Google, **jkviihbyogktwboreydn.supabase.co** hizmetinin … erişmesine izin verecek"*

Güven kırıcı — kullanıcı neye giriş yaptığını anlamıyor. Sebep: Google Cloud
Console'da **Branding** doldurulmamış; Google uygulama adı yoksa yetkilendirilmiş
alan adına düşüyor.

Çözüm sırası:
1. **Branding doldur** (ücretsiz): App name, logo, destek e-postası, ana sayfa +
   **gizlilik politikası + kullanım şartları linkleri**. Not: bu linkler zaten
   mağaza zorunluluğu — iki iş tek hamlede kapanır.
2. **Yerel (native) giriş** (Aşama D): tarayıcı hiç açılmaz, Android'in kendi
   hesap seçicisi çıkar → sorun tamamen ortadan kalkar. B-1, §5.2.1'deki
   **B seçeneğinin lehine ek kanıt**.
3. *(Opsiyonel)* Supabase özel alan adı → `auth.<marka>.com`. Ücretli eklenti,
   marka + alan adı netleşince değerlendirilir.

#### B-2 · Giriş sonrası "Page Not Found" ✅ ÇÖZÜLDÜ
Giriş başarılı oluyordu (log: `supabase_flutter: handle deeplink uri`, oturum
açılıyordu) ama kullanıcı hata ekranı görüyordu:
```
GoException: no routes for location: fitpack://login-callback/?code=...
```
**Kök neden:** Supabase deep link'i kendi dinleyicisiyle işliyor, ancak aynı URI
GoRouter'a da düşüyor ve sayfa adresi olmadığı için istisna fırlatıyor.

**Düzeltme:** `app_router.dart` → `onException` bu URI'yi yutar ve kullanıcıyı
`AppRoutes.cloud` ekranına döndürür. `analyze` 0.

---

## 6. Senkron tasarımı (outbox / giden kutusu)

### 6.1 Yazma yolu
```
Kullanıcı işlemi
   → Drift'e yaz (işlemli, anında)  ← kullanıcı buradan sonra "kaydedildi" görür
   → syncState = 1 (beklemede)
   → kuyruk işleyici tetiklenir
```

Kullanıcı **hiçbir zaman ağı beklemez.** UI yerelden okur.

### 6.2 Gönderim yolu
```
Kuyruk işleyici (ağ varsa)
   → syncState = 1 olan satırları al
   → uid + userId + updatedAt ile Supabase'e UPSERT (uid çakışırsa günceller)
   → SUNUCU ONAYI geldikten SONRA syncState = 0
   → hata → syncState = 2, artan bekleme ile tekrar dene (1s → 5s → 30s → 5dk)
```

### 6.3 Değişmez kurallar (data loss'a karşı)
1. **Kuyruk diskte durur** (Drift kolonu), bellekte değil → uygulama ölse de kalır
2. **Onaysız "gönderildi" işaretlenmez**
3. **`uid` istemcide üretilir** → aynı kayıt iki kez gönderilse sunucuda tek satır
4. **Senkron yerel satırı asla silmez** — sadece `syncState` bayrağını çevirir
5. **Yeniden deneme pes etmez** — kayıt kuyrukta kalır

### 6.4 Çekme (pull) yolu
- Girişte ve periyodik: `updatedAt > sonSenkron` olan sunucu satırlarını çek
- `uid` ile yerelde eşleştir → varsa güncelle, yoksa ekle
- FK'ler `uid` üzerinden yerel integer id'ye çevrilir

### 6.5 Çakışma kuralı
**En son yazan kazanır** (`updatedAt` karşılaştırması). Bu uygulamada veri ağırlıklı
olarak *ekleme* (append) olduğu için çakışma nadir; daha karmaşık bir strateji
(alan bazlı birleştirme) v1 için gereksiz.

---

## 7. RLS politikaları

Her senkronlanan tabloda aynı desen. Örnek:

```sql
alter table public.workout_sessions enable row level security;

create policy "own rows" on public.workout_sessions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

**Kurallar**
- Her senkron tablosunda `user_id uuid not null references auth.users(id) on delete cascade`
- `on delete cascade` → hesap silinince veriler de gider (docs/16 hesap silme ile uyumlu)
- **RLS istisnasız her tabloda açık** — kapalı tablo kalmayacak
- `ProgressPhotos` görselleri Storage'da: mevcut `{user_id}/...` klasör deseni ve
  docs/13 §3.2'deki Storage politikaları korunur

---

## 8. Göç planı

### 8.1 Mevcut kullanıcı yok — büyük avantaj
Uygulama **yayınlanmadı**, gerçek kullanıcı yok. Yani "anonim veriyi hesaba taşıma"
problemi **yok**. Bu işi şimdi yapmak, yayından sonra yapmaktan kat kat ucuz.

### 8.2 Samet'in kendi cihazındaki test verisi
Geliştirme cihazlarında veri var. İki seçenek:
- **(a)** İlk girişte mevcut yerel veriyi hesaba bağla (`userId` backfill + kuyruğa al)
- **(b)** Temiz başlangıç (test verisi zaten atılabilir)

**Öneri: (a)** — çünkü bu kod yolu ileride "hesap değiştirme / yeniden kurulum"
senaryosunda da lazım olacak, bir kez yazılır.

### 8.3 Şema göçü v8 → v9
- Additive: `uid`, `userId`, `updatedAt`, `syncState` kolonları (hepsi nullable)
- Mevcut satırlara backfill: `uid = UUID v4`, `syncState = 1` (girişte kuyruğa girer)
- Yıkıcı işlem yok → ADR-007 uyumlu
- Migration testi aynı commit'te (CONVENTIONS §3)

---

## 9. Senkron durumu arayüzü (K-5)

**Korkutma yok, durum bilgisi var.**

| Durum | Gösterim |
|---|---|
| Her şey senkron | Sessiz (gösterme) veya küçük ✓ |
| Beklemede + çevrimdışı | *"Çevrimdışısın — kaydedildi, bağlantı gelince yüklenecek"* |
| Senkron ediliyor | Küçük dönen ikon |
| Uzun süredir başarısız (7+ gün) | Uyarı — gerçek sorun var demektir |

Mesaj daima **"kaydedildi"** ile başlar. Kullanıcının öğrenmesi gereken ilk şey
verinin güvende olduğudur.

### Gerçek uyarı gereken tek yer: çıkış
Bekleyen kayıt varken çıkış yapılmak istenirse:

> *"3 kayıt henüz yüklenmedi. Şimdi çıkarsan bu veriler kaybolur."*
> `[İptal]` `[Önce senkron et]` `[Yine de çık]`

---

## 10. Test gereksinimleri (kabul kriteri)

Senkron katmanı bu 6 test yeşil olmadan "bitti" sayılmaz:

| # | Test | Beklenen |
|---|---|---|
| T-1 | Yerele yaz → uygulamayı **zorla öldür** → yeniden aç | Kayıt hâlâ kuyrukta |
| T-2 | Gönderim ortasında **ağı kes** | Kuyrukta kalır, tekrar dener |
| T-3 | **Aynı kaydı iki kez gönder** | Sunucuda tek satır (uid idempotency) |
| T-4 | Sunucu onayı gelmeden işaretleme | `syncState` değişmemeli |
| T-5 | Bekleyen veriyle çıkış | Uyarı çıkar |
| T-6 | Senkron sonrası yerel satır | **Silinmemiş**, sadece bayrak değişmiş |

Ayrıca: v8→v9 migration lossless testi (mevcut migration test deseni).

---

## 11. Samet'in manuel yapacakları (Supabase / Google Console)

Kod öncesi ya da paralel:

1. **Supabase projesini restore et** (ücretsiz plan hareketsizlikten duraklattı)
2. **Google OAuth kurulumu:**
   - Google Cloud Console → OAuth client (Web + Android, SHA-1 parmak izi gerekir)
   - Supabase → Authentication → Providers → Google → client id/secret
   - `AndroidManifest.xml` → `fitpack://login-callback` intent-filter
3. **Mirror tabloları oluştur** (SQL, bu dokümanın §7 deseniyle)
4. **`delete_user()` fonksiyonu** (docs/16 §4) — hâlâ kurulmadı
5. **Ücretsiz plan kararı:** Supabase artık kritik yol üstünde. Yayında trafik
   olacağı için duraklama sorunu kalkar, ama **plan limitlerine bakılmalı**

---

## 12. Aşamalar (iş kırılımı)

| Aşama | İçerik | Bağımlılık |
|---|---|---|
| **A** ✅ | Şema v9 (uid/userId/updatedAt/syncState) + migration + test | **TAMAM** |
| **B** | Supabase mirror tablolar + RLS (SQL) | Samet: proje restore |
| **C** | Zorunlu giriş kapısı + onboarding sırası — **tasarım hazır (§5.1)**, kod bekliyor | A ✅ |
| **D** | Google girişi | Samet: OAuth kurulumu |
| **E** | Outbox senkron katmanı (push) + 6 test | A, B |
| **F** | Pull + çakışma çözümü | E |
| **G** | Senkron durumu UI + çıkış uyarısı | E |

**Sıra önerisi:** A → B → C → E → G → F → D
(Google'ı sona koydum: kurulum harici bağımlılık, çekirdek akışı bekletmesin.)

---

## 13. Açık konular

- [ ] **Berna'nın brief'i güncellenmeli** — açık ClickUp task'larında konumlandırma
      *"hesap zorunlu değil, veriler telefonunda kalıyor"* olarak geçiyor. Zorunlu
      hesaba geçince persona / rakip analizi / konumlandırma raporu bu varsayımla
      çelişir. **Berna yanlış varsayımla araştırma yapmasın.**
- [ ] Gizlilik Politikası bu değişikliği yansıtmalı (artık veri sunucuda tutuluyor)
- [ ] `Achievements` tablosu: senkron kapsamına girecek mi? (P-14 kararına bağlı)
- [ ] **Katalog satırındaki kişisel durum senkron edilmiyor (Aşama F'de çöz).**
      Kullanıcı bir katalog hareketini arşivlerse (`exercises.isArchived`) bu
      onun kişisel tercihi, ama katalog satırında duruyor — katalog satırları
      senkron edilmediği için **cihaz değişince bu tercih kaybolur**. Çözüm
      adayları: (a) ayrı `user_exercise_prefs` tablosu (kullanıcı × hareket),
      (b) yalnız değiştirilmiş katalog satırlarını kullanıcıya ait sayıp
      senkronla. Katalog satırlarında `uid` bu yüzden korunuyor (Samet kararı,
      2026-07-22) — ileride lazım olacak.
- [ ] Supabase ücretsiz plan limitleri yayın için yeterli mi?
- [ ] E-posta doğrulama zorunlu olsun mu? (zorunluysa çevrimdışı ilk kurulum daha da zorlaşır)
