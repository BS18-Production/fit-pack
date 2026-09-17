# Fit Pack — Proje Durumu (PROJECT_STATE)

> **Son güncelleme:** 2026-09-17
> **Faz:** V2 — **Zorunlu hesap + senkron** (docs/18). Aşama A · B · C · D · E ·
> F · G kodlandı ve akıyor; **epik BİTMEDİ** — dış inceleme (2026-09-15) senkron
> protokolünde 7 P1 açığı buldu (silme yayılmıyor, sürüm damgası saniyelik,
> sunucuda çakışma çözümü yok, sayfalama yok, hesap izolasyonu eksik).
> Ayrıntı: [CODE_REVIEW.md § Dış İnceleme](CODE_REVIEW.md). Sıradaki iş
> **docs/20 — Senkron v2 tasarımı**.
> **Platform:** Android + **iOS** (2026-07-25'ten beri ikisi birden çalışıyor).
> **Sahibi:** Samet Orhan

## ⚡ Hızlı Antrenman Girişi — Arama v2 + Sonraki Hedef — 2026-09-17

docs/21'in ilk paketi (Samet sırayı onayladı, "özellik tarafından başla").

- **Hareket arama v2:** Samet "istediğimi bulamıyorum" dedi; ölçüm "şınav" 0
  sonuç, "lat" 485 sonuç (Lat Pulldown 161.) gösterdi. Yeni arama kelime
  başından eşleşiyor, yazım farklarını yok sayıyor, Türkçe hareket adlarını
  kural dosyasından üretiyor ve alakaya göre sıralıyor; son kullanılanlar öne
  çıkıyor. Şimdi "şınav" → Push-Up 1., "lat" → Lat Pulldown 1.
- **Antrenmanda sonraki hedef:** çift ilerleme kuralıyla her harekette
  gerekçeli öneri; kilo/tekrar artışı yalnız kullanıcı düğmeye basınca
  (varsayılan +1,25 kg, Ayarlar'dan değişir).
- analyze 0 · test **324/324** · iOS simülatöründe doğrulandı.

## 🌙 Gece Görevi — docs/20 + Paket 3 + docs/21 — 2026-09-17

Samet'in verdiği gece görevi (commit edilmedi, sabah incelenecek):

- **[docs/20 — Senkron v2](docs/20-sync-v2.md):** 7 kritik açığın dört kök
  nedeni tek tasarımda. Ana kararlar: üç ayrı sayaç (`changed_at_ms`
  çakışma, `local_seq` gönderim onayı, `server_rev` çekme imleci); çakışma
  kuralı sunucuda Postgres tetikleyicisiyle; silme = yerel silme + mezar taşı,
  sunucuda yumuşak silme; tetikleyiciler çalışma anında hiç düşürülmez
  (`capture` bayrağı); iki aşamalı, sayfalı, artımlı çekme; sunucu anahtarı
  `(user_id, uid)`; su olay kaydına dönüyor. 8 aşama, ~9 gün, 18 yerel +
  sunucu testi. 7 açık soru.
- **Paket 3:** seans başlığında "1/6 set" + uygulama çubuğu altında ilerleme
  çubuğu (C-16); sütun başlıkları, ÖNCEKİ değerleri ve ✓ daha okunur (C-15).
  analyze 0 · test **267/267** · iOS simülatöründe dokunmadan doğrulandı.
- **[docs/21 — Özellik yol haritası](docs/21-feature-roadmap.md):** 10 öneri
  + 2 sonraki aşama güncel koda karşı değerlendirildi. Önerilen ilk üç:
  antrenmanda sonraki hedef → haftalık değerlendirme → ilerleme fotoğrafları.
  Yeni silinebilir senkron verisi üreten özellikler docs/20 Aşama 5'i bekler.

**Not:** simülatörde 2026-09-16 22:23'te başlatılmış açık bir seans var
(kullanıcı denemesi); gece görevi dokunmadı.

## 🧰 Paket 1 — Mola sesi, set doldurma, arayüz düzeltmeleri — 2026-09-16

Samet'in kullanım geri bildirimi (G-1/G-2/G-3) + Codex'in (dış model) iOS
simülatöründe yaptığı arayüz turundan **kodda doğrulanan** hatalar. Codex'in
37 önerisi sınıflandırıldı (NEXT_TASKS § Codex): 9'u bu pakette, kalanlar
Paket 2-4'e; 6'sına katılınmadı ya da zaten vardı.

- **G-1 mola sonu sesi:** kök neden — seans ekranı açık kaldığı için uygulama
  ön planda, yalnız titreşim vardı; arka plan bildirimi de varsayılan
  kapalıydı. Yeni `core/feedback/feedback_service.dart` (ortak ses +
  titreşim): son 3 saniye tık, bitişte çift bip + belirgin titreşim.
  `audioplayers` eklendi; medya sesi, müziği kısıp üstüne çalar. Ayarlar →
  Bildirimler → "Mola sonu sesi" (varsayılan açık).
- **G-2 önceki değeri taşıma:** alanlar kendiliğinden dolmaz (kayıt,
  onaysız ama dolu seti de yazıyor). Soluk öneri + ✓'e tek dokunuşla doldur.
  "ÖNCEKİ" sütunu artık set numarasına göre (`getLastSessionSetsForExercise`).
- **G-3:** varsayılan mola 180/90 → 60 sn (esneme 30).
- **Codex düzeltmeleri:** alt paneller alt çubuğun arkasında kalıyordu
  (`useRootNavigator`), Beslenme FAB payı, öğün seçici satır kırması, Ana
  Sayfa + takvim ızgarasında gizli güvenli alan boşluğu, geçmiş kayıtta tarih
  seçici + "Kaydet", geçmiş kartında yıl + set/hacim özeti, kütüphanede
  iki satırlık ad, kilo farkı hedef yönüne göre renk + "neye göre", hesap
  ekranında çıkış/silme ayrımı, FAB hero etiketi çakışması.

**Doğrulama:** analyze 0 · test **263/263** · iOS simülatöründe ekran ekran.

**Oturumda yaşanan olay:** simülatör otomasyonunda kayan bir dokunma
Samet'in gerçek hesabına bir öğün kaydı ("Armut", 170 g) ekledi. Kayıt
sunucudan kimliğiyle (`uid`), simülatörden uygulama içinden silindi; iki
tarafta da önceki 2 öğün kaldı. Dokunma kayması düzeltildi (Simulator
penceresinde 52 px araç çubuğu + ~0,92 ölçek).

**Operasyon:** Supabase projesi ücretsiz planda **duraklatılmıştı** →
yeniden başlatıldı. Android emülatöründe oturum sunucuda bulunamadı
(`refresh_token_not_found`) → yeniden giriş gerekiyor.

## 🔍 Dış Kod İncelemesi — 2026-09-15

Samet GitHub reposunu dış bir modele (ChatGPT Astra 6 medium) incelettirdi.
**14 bulgunun 14'ü de kod üzerinde doğrulandı** — yanlış pozitif çıkmadı.
Dış inceleyicide Flutter/Dart yoktu; `flutter analyze` (0 uyarı) ve
`flutter test` (215/215 geçer) burada çalıştırıldı. Testler geçiyor ama
raporun en sert tespiti şu: **yanlış şeyi ölçüyorlar** — `sync_push_test`
T-5'in adı "gönderim sırasında düzenlenen satır" ama düzenlemeyi `pushAll`
bittikten sonra yapıyor; T-1 "süreç ölümü" diyor ama veritabanı dosyasını
kapatıp açmıyor.

**Bugün düzeltilenler** (tasarım gerektirmeyen, bağımsız 5 bulgu): kilosuz
ölçümün mevcut kiloyu perdelemesi (#11), aktivite takviminin sekme geçişinde
bayat kalması (#10), "dünü kopyala"nın transaction'sız + çift dokunuşa açık
olması (#12), su kaydının çoklu satırda çökmesi ve oku-değiştir-yaz yarışı
(#8 yerel yarısı), admin panelde geç yanıtın yanlış kullanıcının verisini
yazması (#13). analyze 0 · test **227/227** (12 yeni regresyon testi). #10'un testi, eski
kalıp geçici yeniden kurulup çalıştırılarak doğrulandı — eski kodla kırmızı,
yeniyle yeşil. Emülatörde derlendi, kuruldu, açıldı (çökme yok); değişen
ekranlar zorunlu giriş kapısının arkasında olduğu için görsel tur yapılamadı.

**Açık kalan ve BİRLİKTE tasarlanması gerekenler** (#1-#7): dördü aynı köke
iniyor — satır sürümü yok, silme protokolü yok, ortak katalog kullanıcıya
bağlanıyor, pull ağ beklemesini yazma penceresinden ayırmıyor. En görünür
sonucu: **silinen öğün sonraki açılışta geri geliyor** (tek cihazda bile —
`bootstrap()` arka plan pull'u sunucuda duran satırı yeniden ekliyor).
Bunlara docs/20 yazılmadan kod yazılmayacak.

## 📱 iOS Ayağa Kalktı — 2026-07-25

Detay: **[docs/18 §15](docs/18-auth-and-sync.md)**.

Uygulama bugüne kadar yalnız Android'de çalıştırılmıştı; iOS'ta tek bir derleme
bile yapılmamıştı (`ios/Podfile` yoktu). Kod tarafı taşınabilir çıktı —
`Platform.is*` dallanması **0 yer**, 15 paketin tamamı iOS destekli — eksik olan
**platform yapılandırmasıydı**.

Kapatılan üç sessiz arıza: kamera izni metni yoktu (barkod ekranı iOS'ta
**çökerdi**), `fitpack://` şeması yoktu (Google dönüşü + e-posta doğrulama +
şifre sıfırlamanın üçü de dönemezdi), bildirim servisi tamamen Android'e bağlıydı
ve iOS'ta izni **hiç sormadan "verildi" diyordu**.

Simülatörde doğrulandı: derleme · karşılama ekranı · Google girişi · deep link ·
**senkron indirmesi** · Drift/SQLite · seed v2 · 215/215 test.

**iOS yerel Google girişi de çalışıyor** (aynı gün): Supabase "Client IDs"e iOS
kimliği eklendi + "Skip nonce checks" açıldı. Doğrulandı — `grant_type: id_token`,
`login_method: oidc` → 200, yani Safari'ye çıkmadan giriş. Android hâlâ tarayıcı
akışında (Android istemcisi/SHA-1 yok). docs/18 §15.4.

## 🎞️ İçerik Turu 2 — İki Kareli Form Gösterimi — 2026-07-25

Detay: **[docs/11 §12](docs/11-content-enrichment.md)**.

**Bulgu:** free-exercise-db her harekette **iki kare** tutuyor (`0.jpg`
başlangıç + `1.jpg` bitiş, 873/873'te ikisi de var) ama uygulama yalnız
birincisini gösteriyordu — hareketi anlatan iki kareden biri kullanılmıyordu.

`shared/widgets/exercise_demo.dart` → `ExerciseDemoImage` ikisini dönüşümlü
oynatıyor. Ücretsiz (public domain), ek indirme hareket başına tek görsel.
`ExerciseHowToContent` içinde olduğu için hareket detayı **ve** aktif seans
sheet'i birden kazandı. Geçiş 350→**160 ms** (uzun geçiş çift pozlama hayaleti
üretiyordu; arka plan sabit olduğu için kısa kesme doğru okuma).

**İki kayıt düzeltildi:**
- **D-1 iptal** — doküman "görselleri APK'ya göm" diyordu, kod hep CDN'den
  çekiyordu. Samet offline hedefi olmadığını belirtti → CDN doğru, D-1 kalktı
  (gömmek ~41–83 MB'a mal olurdu).
- **NEXT_TASKS #2 "seansta nasıl yapılır" YAPILMADI kaydı yanlıştı** — özellik
  `active_session_screen.dart:974`'te zaten çalışıyor.

**Araştırma sonucu (docs/11 §12.3):** wger'de Türkçe **yalnız 31 çeviri** → §3
ve D-5'teki "Türkçe wger'den gelir" planı geçersiz. ExerciseDB'nin GitHub
reposu **2 dosyalık boş kabuk**; ticari ürün ayrı (`exercisedb.io`, tek
seferlik satın alma, self-host, fiyat öğrenilemedi). Ücretli alternatifler:
MoveKit ₺1.699/206 animasyon, Exercise Animatic $359/~1.600 klip.

**AÇIK karar:** 814 hareketin Türkçe talimatı (4000 cümle) — 4 seçenek
konuşuldu, karar verilmedi.

analyze 0 · **test 215/215** · emülatörde iki poz da doğrulandı.
**Kapsama onarımı (aynı gün):** Samet "kaç harekette görsel var" diye sordu →
ölçüm 814/1015 (%80) gösterdi ama **eksik 201 tam da temel hareketlerdi**
(Squat, Deadlift, Bench, Leg Press, Overhead Press). Kök sebep: D-2 birleştirme
kuralı küratörlü satırı koruyor, isimler kaynakla tutmuyor; dedupe ise görselli
satırı silip görselsizi koruyordu. Otomatik eşleştirme üç turda da yanlış
hareket eşledi (Back Squat→Hack Squat) → **elle onaylı eşleme tablosu**
(`assets/data/exercise_image_map.json`, 97 kayıt) + `SeedManager.
_backfillExerciseImages()` (idempotent, her iki seed yolunda) + seedVersion
1→2. **814 → 911 görselli (%90)**, temel lift bandı kapsandı. 5 yeni test ·
97 eşlemenin 194 karesi de CDN'de doğrulandı · emülatörde uygulandı.
Kapsanmayan 104: kardiyo/esneme/kalistenik + kaynakta sade sürümü olmayan
~56 kuvvet hareketi (ücretli kütüphane kararına girdi).


## 🔓 Şifre Kurtarma — 2026-07-25

Zorunlu hesap mimarisindeki **son açık delik** kapandı. `sendPasswordReset`
serviste duruyordu ama hiçbir yerden çağrılmıyordu; yani şifresini unutan
kullanıcının antrenman geçmişine dönüş yolu yoktu — epiğin var oluş sebebiyle
(veri kaybını önlemek) çelişen bir boşluk.

**Eklenenler:** giriş ekranında "Şifreni mi unuttun?" bağlantısı (yalnız giriş
sekmesinde) + `_ForgotPasswordDialog` · `AuthGate.recovering` bayrağı ·
`/reset-password` rotası + `ResetPasswordScreen` · `updatePassword`.

**Kritik nokta:** sıfırlama bağlantısı Supabase'de **gerçek oturum** açar.
`recovering` bayrağı yönlendirme tablosunun ÜSTÜNDE olmasaydı kullanıcı
"oturum var + onboarded" kuralıyla doğruca Ana Sayfa'ya düşer ve **şifresi hiç
değişmezdi** → bir sonraki cihazda yine giremezdi. Şifre iki kez sorulur (tek
alanda yazım hatası = kendi bilmediği şifreye geçmek). Onay mesajı hesap
sayımı sızdırmaz. Vazgeçme yolu var (bağlantıyı yanlışlıkla açan kilitli
kalmasın). Deep link Google ile aynı → domain gerekmedi.

**Doğrulama:** analyze 0 · **test 203/203** (5 yeni) · emülatörde gerçek
Supabase'e karşı `POST /recover → 200` + `mail.send / recovery` (docs/18 §14).
⚠️ Test hesabı `fitpack.gate.test@gmail.com` mail ALAMIYOR — Supabase adres
içindeki `.test` yüzünden reddediyor (proje kısıtı değil).

## 🔑 Google Birincil + Zaman Damgası Onarımı — 2026-07-25

**E-posta doğrulama kararı:** AÇIK kalıyor. Kapatmanın kazancı sürtünme, kaybı
geri dönüşü olmayan veri kaybı (hesap = tek kurtarma yolu). Sürtünme çözümü:
**Google girişini birincil buton** yaptık (`auth_screen.dart`) — dolgulu, üstte;
ayırıcı "ya da e-posta ile devam et"; e-posta/şifre ikincil (çerçeveli). Busy
durumu `_Busy` enum'ıyla ayrıştırıldı → doğru butonda yükleniyor göstergesi. Yeni
l10n `cloudOrEmail` (TR/EN). Emülatörde görsel doğrulandı (Google dolgulu birincil).

**Zaman damgası onarımı:** v9 göçü `uid`'i doldurdu ama `updated_at`'i boş bıraktı
→ push'ta sunucunun NOT NULL kolonunda `23502` reddi (yalnız Samet'in v9-öncesi
satırları). Gönderim ön geçişine `_repairMissingTimestamps()` (`sync_push.dart`) +
`backfillUpdatedAtSql` (`sync_columns.dart`) eklendi; NULL damgalar push öncesi
şimdiye ayarlanıyor (idempotent). 1 yeni test.

**Markalı Türkçe doğrulama maili:** şablon hazır (`supabase/emails/confirm_signup_tr.html`)
ama Supabase custom SMTP olmadan template düzenletmiyor + domain yok → yayın
hazırlığına ertelendi (Resend + domain). analyze 0 · **test 198/198**.

## ⚡ Reaktif Veri Katmanı (H-05) — 2026-07-23

20 okuma provider'ı `FutureProvider` → `StreamProvider` (`lib/data/reactive.dart`
`watchTables`): dokundukları tablo değişince ekran **kendiliğinden** tazelenir.
Elle `invalidate` **74 → 38** (kalanlar meşru: onRetry, gün-dönümü, pull güvenliği,
activeDraft, pull-to-refresh). Momentum hero (`last30WorkoutStats`) artık seans
bitince otomatik güncelleniyor — H-05 momentum bug'ı kökten çözüldü. Emülatörde su
widget'ıyla (invalidate'i kaldırıldı) canlı doğrulandı: 0.0 → 0.5 L elle tazeleme
olmadan. **Kanonik okuma kalıbı artık:** `StreamProvider` + `watchTables(db, [tablolar], read)`.

## 📶 Senkron Durumu UI (G) + Google Native Kod (D) — 2026-07-23

**Aşama G:** Hesap ekranına senkron durumu göstergesi (`sync_status.dart`) — 4
durum, mesaj daima "kaydedildi" ile başlar; bekleyen kayıtla çıkışta uyarı
(İptal / Önce senkron et / Yine de çık). Emülatörde "Verilerin güncel" (yeşil ✓)
doğrulandı.

**Aşama D (kod tamam):** `auth_service.dart` iki yollu Google — `googleWebClientId`
doluysa yerel (Android hesap seçici, `signInWithIdToken`), boşsa tarayıcı (regresyon
yok). `google_sign_in ^6.2.1` eklendi. Aktivasyon Samet'in tek satırına bağlı:
`SupabaseConfig.googleWebClientId`'e Supabase Google provider'ının Web client ID'si.
İzin ekranındaki ham `supabase.co` (B-1) bununla biter.

analyze 0 · test **197/197**.

## ⬇️ Çekme (Pull) Kuruldu — Aşama F (2026-07-23)

Senkron artık **iki yönlü**. Girişte sunucudaki veri yerele iner:
`features/sync/sync_pull.dart`. Bu, Samet'in gerçek testinde çıkan hatayı çözer —
verisi silinmiş cihaza girince "sıfır kullanıcı" gibi davranıp onboarding
sormuyor; sunucudaki `onboarded=1` profili + antrenman/ölçüm geçmişini indiriyor.

Dört karar: (1) tetikleyiciler pull boyunca **kapalı** (sunucu `updated_at`'i
korunur, inen satır kuyruğa geri girmez), (2) profil **tekil** → yeniden-onboarding
junk'ı gerçek veriyle kendiliğinden iyileşir, (3) katalog **isimle benimsenir**
(seed hareket ikizlenmez), (4) çakışmada **en son yazan kazanır**. Sunucuda
`user_profile_one_per_user` (user_id UNIQUE, zaten vardı) çift profili DB
seviyesinde de engelliyor.

test **197/197** (6 yeni pull testi) · analyze 0 · **emülatörde gerçek Supabase'e
karşı doğrulandı**: yerel sil → giriş → veri indi, onboarding sorulmadan Ana
Sayfa, Profil'de 2250 kcal (girilmediği hâlde). Detay docs/18 §6.8.

## 🔐 Zorunlu Giriş Kapısı Kuruldu — Aşama C (2026-07-23)

Uygulama artık **hesapsız açılmıyor**. Akış: ① Karşılama (değer + Hesap oluştur /
Giriş yap, "Atla" yok) → ② tam ekran Giriş/Kayıt → ③ Onboarding (4 sayfadan **3**e
indi; A1 Karşılama giriş öncesine taşındı) → ④ Uygulama. Yönlendirme kararı tek
saf fonksiyonda: `gateRedirect` (oturum × onboarded), GoRouter'a `redirect` +
`refreshListenable` ile bağlı → çıkışta kapı **anında** devreye giriyor.

Üç tasarım kuralı da kodda: kapı **ağa değil oturuma** bakar (uçak modunda kendi
verine girersin) · `onboarded` `runApp` ÖNCESİ diskten okunur (tembel provider'ın
varsayılanına güvenilmez) · **hesap değişince yerel kullanıcı verisi silinir**
(aynı cihazda ikinci kullanıcı öncekinin antrenmanlarını göremez); ortak katalog
(1015 hareket) durur.

analyze 0 · **test 191/191** (11 yeni) · emülatörde sıfır kurulumdan Ana Sayfa'ya
uçtan uca yürüdü, senkron yeni kullanıcı kimliğiyle veri yükledi. Detay:
docs/18 §5.4.

**İki açık madde:** Supabase'de **e-posta doğrulama açık** → kayıt oturum açmıyor
(karar gerekiyor) · v9'dan gelen `updated_at` NULL satırlar sunucuca reddediliyor
(`23502`), Aşama F öncesi onarım eklenmeli. İkisi de NEXT_TASKS'te.

## ✅ Senkron CANLI ÇALIŞIYOR (2026-07-22)

Telefondaki gerçek veri Supabase'e ulaşıyor: `tur bitti — gönderilen 15, kalan 0`.
Aşama **A** (şema v9) · **B** (mirror tablolar + RLS) · **E** (giden kutusu) tamam.
Dört canlı arıza aşıldı, **hiçbirinde veri kaybı olmadı** — detay docs/18 §6.7.
En sinsisi: v10 öncesi satırların `uid`'i NULL kalınca 13 kayıt **sessizce**
atlanıyordu (hata yok, sayaç sıfır). Artık gönderim öncesi kimlik onarımı var.

**Operatör panelleri:** `tools/admin/` — kullanıcı listesi + profil sayfası
(antrenman/beslenme/ölçüm logları, 15 alanda filtre) ve kişisel veri panosu.
claude.ai artifact olarak çalışıyorlar.

**Aşama C tamam** (yukarı bak). Sıradaki: **Aşama G** — senkron durumu arayüzü.

## 🔐 Zorunlu Hesap + Senkron — Aşama A (2026-07-22)

Mimari kararı: uygulama **yerel-öncelikli kalır** (Drift doğruluk kaynağı,
salonda sinyalsiz çalışır) ama **hesap zorunlu** olur ve tüm kullanıcı verisi
Supabase'e otomatik senkron edilir. Tasarım: **[docs/18-auth-and-sync.md](docs/18-auth-and-sync.md)**.
Bu, docs/13'ün öngördüğü "Faz 2"dir — docs/13 (Storage blob yedek) yürürlükten
kalktı.

**Bu oturumda biten:**
- **Google girişi uçtan uca çalışıyor** — OAuth kurulumu (Web + Android client),
  Supabase provider, manifest deep link. Test sırasında iki bulgu: giriş sonrası
  "Page Not Found" (GoRouter `onException` ile çözüldü) ve izin ekranında ham
  Supabase alan adı görünmesi (Branding doldurulacak — docs/18 §5.3 B-1 açık).
- **Elle bulut yedekleme KALDIRILDI** — otomatik senkron varken gereksiz.
  `cloud_backup_service.dart` silindi.
- **Ayarlar "Veri & Gizlilik" bölümü komple kaldırıldı** (yedekle/geri yükle/dışa
  aktar + Ana Sayfa'daki dışa aktar butonu + `features/export/`). **Hesap satırı
  Profil'e taşındı** — mağaza hesap-silme zorunluluğu (docs/16 §4) nedeniyle yok
  edilemez.
- **Şema v8 → v9:** 12 tabloya `uid`/`userId`/`updatedAt`/`syncState`
  (`SyncColumns` mixin). Integer PK yerelde korundu, `uid` yalnız sunucu kimliği
  → mevcut kod ve 7 yabancı anahtar dokunulmadı (haftalar yerine gün).
- ⚠️ **Yakalanan üretim hatası:** `m.createTable()` güncel tanımı kullandığı için
  v6 öncesinden yükselen kullanıcı "duplicate column" ile çökerdi. Üç tablo
  artık tarihsel şekliyle oluşuyor + v9 adımında varlık kontrolü var.

**Doğrulama:** analyze 0 · test **156/156** · **emülatörde gerçek v8→v9 göçü**
(profil birebir korundu, 1015 hareket, 1015 benzersiz UUID, katalog kuyruğa
girmedi, 12 unique index) · **telefonda (SM A075F) release APK ile doğrulandı**.

## 🏆 Haftalık Seri + Kişisel Rekor Kutlaması (2026-07-11)

[docs/17-improvement-analysis.md](docs/17-improvement-analysis.md) (kapsamlı
iyileştirme analizi: özellik/teknik/monetizasyon/pazar) yazıldı; 1. adımı
kodlandı: seri artık haftalık hedef bazlı (dinlenme günü KIRMAZ —
`streak_calc.dart` + `weeklyStreakProvider`, hafta-başı tercihi destekli) ve
canlı seansta kişisel rekor kupası + özet ekranında "N yeni rekor" kartı
(`record_calc.dart`, e1RM/en ağır — seans tarihi öncesi geçmişe göre).
analyze 0 · test 154/154 · **emülatörde uçtan uca görsel doğrulama TAMAM**
(sıfır durum → ilk seans kupasız → haftalık seri kartı → ikinci seansta canlı
kupa rozeti → özette "New record" kartı; test verisi temizlendi). Yan bulgu:
`_finish` sonrası momentum istatistikleri bayat kalıyor (H-05) — reaktif veri
katmanı (docs/17 adım 2) çözecek, NEXT_TASKS'te notlu.
Not: yayın konuları Samet kararıyla uygulama hazır olana kadar gündem dışı.

## 🎨 Uygulama Geneli Liquid Glass (2026-07-07)

Tüm ekranlar (18 ekran: tab'lar + push'lu ekranlar) tek tasarım diline geçti.
Üç merkezi kaldıraç: (1) `GlassBackground` `MaterialApp.builder`'da bir kez —
ekranlar kendi zeminini kurmaz; (2) tema `Card`'ı cam yüzey (`AppGlass`
token'ları, app_colors.dart) — Card kullanan her ekran otomatik uyumlu;
(3) buzlu alt gezinme çubuğu (`extendBody` + blur) + edge-to-edge sistem
çubukları. Ayarlar/Profil/Bildirimler `SettingsSection` cam bölüm kartlarına
geçti. analyze 0 · test 137/137 · açık+koyu emülatör turuyla doğrulandı.
Detay: **[NEXT_TASKS.md](NEXT_TASKS.md)** §Liquid Glass Tutarlılığı.
**Kalan risk:** gerçek cihazda (SM A075F) blur performansı — APK testi bekliyor.

## 🌐 Çok Dilli (EN/TR) — Faz A (2026-07-05)

Uygulama iki dilli yapılıyor (İngilizce öncelik, cihaz dilini takip et). Altyapı
(`gen-l10n`+ARB, dil seçici, locale-duyarlı biçim) + ilk dilim (nav, Ana Sayfa,
Ayarlar, CalorieRing) tamam, EN/TR emülatörde doğrulandı. Kalan ekranlar +
Faz B (içerik) → **[NEXT_TASKS.md](NEXT_TASKS.md)** ve
**[docs/14-localization.md](docs/14-localization.md)**. analyze 0 · test 110/110.

Ayrıca **Onboarding V2 UYGULANDI** (glass 4-sayfa kurulum + değer projeksiyonu
+ "İçeride ne var" + sekme başına coach mark + boş hal aksiyonları):
[docs/15-onboarding.md](docs/15-onboarding.md). analyze 0 · test 123/123 ·
sıfır kurulumda EN+TR uçtan uca doğrulandı. Detay NEXT_TASKS §Onboarding V2.

## 🆕 Sprint D — Claude Design Reskin: Ana Sayfa (2026-06-21)

Claude Design'da Apple Fitness vibe + Indigo/Teal paletiyle tasarım yapıldı (HTML export `design/code/`). Mevcut uygulamaya geçirme başladı — **Ana Sayfa tamam**:
- **Font:** Inter → **Manrope** (tasarım fontu, `app_theme.dart`)
- **Şema v3→v4:** `water_intake` tablosu + `user_profile.waterGoalMl` (default 2500). Migration lossless, test 3/3.
- **Onboarding (P-10):** önceki session'dan zaten kodluydu — bu cihazda sıfır kurulumda çalıştı, doğrulandı.
- **Ana Sayfa yeniden kuruldu** (`home_screen.dart`): özel header (BUGÜN + tarih, safe-area fix), durum-duyarlı birincil kart (**dinlenme günü zekası** — plandan türetiliyor: antrenman günü→gradient CTA, dinlenme→sakin kart + "Yarın: X" + yürüyüş önerisi), beslenme hero halkası (196px, ölçeklenen 48px sayı), **su takibi kartı** (+250ml/+1 bardak, DB-backed, uzun bas=sıfırla), sessiz Seri+Kilo satırı (dikey ayraç, ↓0.4 trend rozeti).
- **Doğrulama:** analyze 0 · test 30/30 · emülatörde dark+light + su etkileşimi (0.7L) + dinlenme günü + onboarding akışı ekran görüntüsüyle doğrulandı.
- **Sıradaki reskin ekranları:** Antrenman, Beslenme, İlerleme, Ayarlar (aynı token sistemi hazır).

Bu doküman, projenin **şu andaki canlı durumunu** anlatır. Her session sonunda güncellenir.

---

## 🟢 Aktif Durum

**Şu an neredeyiz:** **Sprint P (Premium Cila) tamam** (2026-06-11). Uygulamanın "premium ürün" analizinden çıkan tüm yüksek öncelikli bulgular kodlandı:
- **Antrenman:** seans ekranında geçen seansın ghost değerleri (alan ipuçları + "Geçen seans" satırı), seans başlığı düzeltildi (FullA → Full Body A), geri tuşunda çıkış onayı (PopScope), set ekle/çıkar, antrenman ön izleme ekranı (`/workout/preview/:type` — karta dokununca kronometre değil önizleme), **Antrenman Geçmişi ekranı** (`/workout/history` — seans listesi + set dökümü + toplam hacim; ölü "yakında" butonu gerçek ekrana bağlandı).
- **İlerleme:** fl_chart kilo trend grafiği (hedef kilo kesikli çizgi, dokunma tooltip'i), çift "Ölçüm Ekle" CTA teke indirildi.
- **Beslenme:** Son kullanılanlar şeridi (Yemek Ekle'de chip'ler), "Dünün öğünlerini kopyala" (gün boşken), karb/yağ hedefi kalori+proteinden türetiliyor (`macro_goals.dart`), P/K/Y kısaltmaları makro renkleriyle kodlu (`MacroInlineText`), arama placeholder temizliği.
- **Ana sayfa:** boş haller davet eder ("Seri yok/Bugün başlat" → Antrenman, "Ekle/İlk kilonu gir" → İlerleme; kartlar tıklanır), 7+ gün arada "Yeniden başlamak için harika bir gün".

Önceki sprint: Beslenme V2 (`9ceb223`), tasarım [docs/07-nutrition-v2.md](docs/07-nutrition-v2.md). Dal: `feat/sprint-0.1-migration`.

**Engelleyici:** Yok. Samet'in 6 doc'a okuma feedback'i bekleniyor (engelleyici değil — kod paralel başlayabilir, doc'lar v1.x bump edilir).

**Aktif geliştirici:** Samet (solo) + Claude Code (dispatch ile mobil destek)

---

## 📊 Versiyon

| Bileşen | Versiyon | Durum |
|---------|----------|-------|
| Uygulama | V1.0.0+1 | Prod (lokal, Samet pilot) |
| V2 hedef | 2.0.0 | Geliştirme — Sprint N (Beslenme V2) tamam |
| DB schema | **v6** | v2(Beslenme), v3(Onboarding), v4(Su), v5(Hareket kütüphanesi), v6(Rutinler+gelişmiş set) — hepsi lossless test geçti |
| GitHub | anox2077/fit-pack | private |

---

## 📄 Dokümantasyon Durumu

| Doc | Versiyon | Durum | Notlar |
|-----|----------|-------|--------|
| `docs/01-product-spec.md` (PRD) | 1.1 | ✅ Hazır, final onay bekliyor | Q-01..Q-05 tüm açık sorular cevaplandı |
| `docs/02-architecture.md` (Mimari) | 1.0 | ✅ Taslak hazır | 18 bölüm; ADR'lar, katmanlar, SQLCipher, foto hibrit detay |
| `docs/03-ux-flows.md` (UX) | 1.0 | ✅ Taslak hazır | 20 bölüm; ASCII wireframe'ler, tüm akışlar |
| `docs/04-roadmap.md` (Yol haritası) | 1.0 | ✅ Taslak hazır | Aşama 0-4, sprint planı, milestone'lar |
| `docs/05-testing.md` (Test) | 1.0 | ✅ Taslak hazır | 14 bölüm; test hedef tahtası, migration testi zorunlu, manuel regresyon checklist |
| `docs/06-workflow.md` (DevOps) | 1.0 | ✅ Taslak hazır | 18 bölüm; branch/commit, pre-push checklist, dispatch, release, secrets, yedekleme |

---

## 🎯 Aktif Hedef

**V2 RELEASE hedef tarihi:** 2026-08-15 (pilot lock)

**Bugünden V2 release'e kadar:**
1. ✅ Dokümantasyon 6/6 + 07-nutrition-v2.md (2026-05-18)
2. ✅ Aşama 0 T-001 (migration iskeleti) + **Sprint N Beslenme V2 tamam** (2026-05-18): şema v1→v2, adet/birim, Yemekler ekranı, OpenFoodFacts/barkod, backfill — analyze 0 · test 18/18 · gerçek cihaz DB'sinde lossless doğrulandı
3. ✅ **Sprint P Premium Cila tamam** (2026-06-11): ghost değerler, geçmiş/ön izleme ekranları, kilo grafiği, beslenme kısayolları, boş hal cilası — analyze 0 · test 24/24 · emülatörde tüm akışlar doğrulandı
4. **← SIRADA:** Premium analizden ertelenenler (NEXT_TASKS "Sprint P+") **veya** Aşama 0 kalan (T-002..T-008: yedek + SQLCipher şifreleme) **veya** Samet'in cihaz testi geri bildirimi
5. Aşama 1, 2, 3 sırayla

---

## ✅ Tamamlanan Karar Noktaları

- ✅ Strateji: Lokal, tek kullanıcı pilot
- ✅ Stack: Flutter + Drift + Riverpod + go_router + fl_chart kilitli
- ✅ AI: Switchable provider, Gemini başlangıç
- ✅ Q-01: Gemini API key var
- ✅ Q-02: Foto saklama hibrit (DB sıkıştırılmış + galeri orijinal)
- ✅ Q-03: API limit dolarsa hata göster + sonraki güne ertele
- ✅ Q-04: Bildirim reddi sessiz devam + in-app reminder
- ✅ Q-05: SQLite şifreleme açık (SQLCipher + Android Keystore)

---

## ⏳ Bekleyen Onaylar (Engelleyici Değil)

Samet 3 doc'u sırasıyla okuyacak ve "değişiklik var mı" diye karar verecek:
- PRD v1.1
- Mimari v1.0
- UX v1.0
- (yeni eklendi) Roadmap v1.0

Değişiklik istenirse v1.x bump yapılır, yoksa final lock.

---

## 🚫 Bilinçli Olarak Yapılmayanlar (V2)

- Çoklu kullanıcı / auth (V3'e)
- Bulut sync (V3'e)
- Social feature (asla)
- Reklam (anti-hedef)
- Apple Watch / Wear OS (V3 sonrası)

---

## 🛠 Mevcut V1 Eksiklikleri (Aşama 0'da Düzeltilecek)

- ✅ Migration sistemi + v1→v2 (Beslenme V2) — lossless, gerçek cihaz DB'sinde doğrulandı
- ❌ Error handling katmanı yok
- ❌ Input validation yok
- ❌ Workout history ekranı TODO durumunda (workout_list_screen.dart:66)
- ❌ Achievements UI yok (tablo var ama ekran yok)
- ❌ Progress analytics dedicated chart yok
- ❌ README boş (Flutter starter) — ✅ Bu session düzeltildi

---

## 🔗 Önemli Yollar

- **Repo:** `/Users/sametorhan/dev/fit_pack`
- **Docs:** `/Users/sametorhan/dev/fit_pack/docs/`
- **Cihazlar:** Android SM A075F `R96YB00XJPB`, iOS sim `92EFAB82-82C1-459D-A925-27DAA867E869`
- **Hafıza:** `~/.claude/projects/-Users-sametorhan/memory/project_fit_pack.md`
