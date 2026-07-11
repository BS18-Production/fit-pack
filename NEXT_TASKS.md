# Fit Pack — Sıradaki İşler (NEXT_TASKS)

> **Son güncelleme:** 2026-07-11
> **Bağlı doküman:** [PROJECT_STATE.md](PROJECT_STATE.md), [CODE_REVIEW.md](CODE_REVIEW.md), [docs/04-roadmap.md](docs/04-roadmap.md), [docs/17-improvement-analysis.md](docs/17-improvement-analysis.md)

---

## ✅ Haftalık Seri + Kişisel Rekor (PR) Kutlaması (2026-07-11)

[docs/17-improvement-analysis.md](docs/17-improvement-analysis.md) analizinin
1. adımı. (Not: yayın konuları Samet kararıyla uygulama hazır olana kadar
gündem dışı — analiz doc'undaki nota bak.)

- [x] **Seri artık haftalık hedef bazlı** (`features/home/streak_calc.dart`
      saf mantık + `weeklyStreakProvider`): eski seri ardışık takvim günü
      sayıyordu — dinlenme günü seriyi kırıyordu (dinlenme günü zekasıyla
      çelişki). Yeni: hafta içinde hedef kadar antrenman günü = hafta tamam;
      seri = ardışık tamam hafta. Hedef = planlanmış rutin günü sayısı
      (plan yoksa 1); hafta sınırı "haftanın ilk günü" tercihine uyar; devam
      eden hafta seriyi kırmaz, tamamlanınca dahil olur. Ana Sayfa hero 3
      durumlu: "{n} haftadır ritimdesin" + "Bu hafta 2/4 antrenman" /
      "İlk haftanı tamamla" / "Serini başlat". `homeStreakKicker` anahtarı
      kaldırıldı, `homeStreakTitle` gün→hafta anlamına döndü.
- [x] **PR kutlaması** (`features/workout/record_calc.dart` saf mantık):
      canlı seansta set tamamlanınca e1RM (Epley) ya da en ağır kilo, seans
      öncesi geçmişin en iyisini aşarsa sol set rozeti KUPAYA döner + güçlü
      titreşim; geri alınca rozet kalkar. Geçmişi olmayan hareket rozetlenmez
      (ilk seansın her seti "rekor" olmasın — Rekorlar sekmesi kuralı).
      Taslak `pr` alanıyla rozetleri resume'da korur (eski taslak uyumlu).
      Özet ekranında "N yeni rekor" kartı — seans TARİHİNDEN önceki geçmişe
      göre hesaplanır (deterministik; geçmişe girilen manuel seans sonraki
      seansları yanlış "rekor" göstermez). Geçmiş kayıt modunda anlık rozet
      yok (özet kartı tarihe göre doğru çalışır).
- [x] analyze 0 · test **154/154** (17 yeni: streak_calc + record_calc)
- [x] **Emülatör görsel doğrulaması TAMAM** (2026-07-11, release APK):
      sıfır durum ("Serini başlat") · seans kayıtla "Bu hafta 1/1" + "1
      haftalık seri"+alev · geçmişi olmayan harekette kupa YOK (kural) ·
      ikinci seansta PREV 60×8 ghost + 70×8 tamamlanınca set rozeti KUPA ·
      özette "New record — Estimated 1RM 89 kg · 70×8" kartı. Test
      seansları emülatörden silindi.
- [ ] **Yan bulgu (H-05 kanıtı):** seans bitişi `_finish` yalnız 3 provider
      invalidate ediyor — `last30WorkoutStatsProvider` / `weekDashboardProvider`
      tazelenmiyor (Ana Sayfa momentum istatistikleri seans sonrası eski
      kalıyor; uygulama yeniden açılınca düzeliyor). Tek tek invalidate
      eklemek yerine **reaktif veri katmanı** (docs/17 adım 2, drift
      `watch()`) bunu kökten çözecek — o işte ele al.

---

## ✅ Uygulama Geneli Liquid Glass Tutarlılığı (2026-07-07)

Samet "tüm uygulamayı tasarım açısından kusursuz, birbiriyle uyumlu yap" dedi.
Ekran ekran zemin kopyalamak yerine **üç merkezi kaldıraç** kuruldu — böylece
18 ekranın tamamı tek hamlede aynı dile geçti:

- [x] **Global zemin:** `GlassBackground` artık `MaterialApp.builder`'da
      (app.dart) navigator'ın ALTINA bir kez çizilir → tab + push'lu tüm
      ekranlar aynı ışıma zeminini paylaşır. Home/Onboarding'deki yerel
      `GlassBackground` sarmalayıcıları kaldırıldı (çift zemin yok).
      **Kural: yeni ekran kendi zeminini KURMAZ.**
- [x] **Tema kaldıracı (app_theme):** `scaffoldBackgroundColor` + AppBar
      transparan; `cardTheme` = ucuz cam yüzey (yarı saydam dolgu + hairline,
      blur'suz GlassCard eşdeğeri) → temadaki `Card` kullanan HER ekran
      otomatik glass oldu. Renk token'ları tek kaynakta: **`AppGlass`**
      (app_colors.dart) — glass.dart da oradan okur.
- [x] **Buzlu gezinme çubuğu:** AppShell `extendBody: true` + navbar
      `BackdropFilter` blur + `AppGlass.navFill` + üst hairline — içerik
      çubuğun altından akar. Tab ekranlarının ListView'ına
      `context.bottomScrollInset` (app_dimens) alt boşluğu eklendi;
      Beslenme/İlerleme FAB'ları `MediaQuery.padding.bottom` ile çubuğun
      üstüne kaldırıldı (iç Scaffold extendBody'yi bilmez — bilinen tuzak).
- [x] **Edge-to-edge:** `SystemUiMode.edgeToEdge` (main.dart) + builder'da
      `AnnotatedRegion` (AppBar'sız ekranlar için) + appBarTheme
      `systemOverlayStyle` transparan `.copyWith` + styles.xml (values +
      values-night) transparan status/nav bar → gri status bandı ve siyah
      gesture şeridi kalktı, zemin sistem çubuklarının arkasına uzanıyor.
- [x] **Ayarlar/Profil/Bildirimler bölüm kartları:** `SettingsSection`
      (setting_tiles.dart) — başlık + cam kartta gruplanmış satırlar, rozet
      hizalı ince ayraçlar (iOS Settings dili). Üç ekran da geçirildi;
      Profil TDEE kartının çift yatay margin'i düzeltildi.
- [x] **Doğrulama:** analyze 0 · test 137/137 · emülatörde uçtan uca görsel
      tur: 4 tab + Profil + Ayarlar + Bildirimler + Foods + Export + Atıf +
      Kütüphane + Hareket Detayı (demo foto + kas haritası) + aktif seans
      (set tablosu + dinlenme banner'ı) + özet + geçmiş — **açık VE koyu**
      temada ekran görüntüleriyle. Emülatör temizlendi (test seansı silindi,
      tema Sistem'e döndü).
- [ ] **Gerçek cihaz performansı:** SM A075F'te blur (navbar + GlassCard)
      akıcılığı test edilmeli; takılırsa `GlassCard.blur=false` +
      navbar blur sigma düşürülebilir. APK kurulunca Samet baksın.

---

## ✅ Geçiş Pürüzsüzlüğü — Tüm Ekranlar (2026-07-07)

Samet fark etti: ekranlar arası geçişte bileşenler saliselik geç yükleniyordu
(pürüzsüz değil). İki ayrı kök neden, iki gezinme türü:

**A) Sekmeler (tab) — `StatefulShellRoute.indexedStack`:**
Router düz `ShellRoute` + `context.go` idi → her geçişte önceki sekme ekranı
yok edilip yenisi sıfırdan inşa ediliyordu; Home dashboard gibi `autoDispose`
provider'lar dispose olup DB'den yeniden (asenkron) fetch ediyordu → o boşlukta
iskelet görünüp gerçek veri "pat" diye geliyordu.
- [x] `StatefulShellRoute.indexedStack`'e geçildi (`app_router.dart`): 4 sekme
      4 `StatefulShellBranch`, her biri kendi navigator'ında, `IndexedStack`
      ile canlı kalır → yeniden inşa yok, autoDispose provider'lar dinleyici
      bağlı kaldığı için dispose olmaz (yeniden fetch yok), scroll korunur.
- [x] `AppShell` artık `Widget child` yerine `StatefulNavigationShell` alır;
      seçili index `navigationShell.currentIndex`, geçiş `goBranch(index)`
      (aynı sekmeye tekrar dokununca `initialLocation:true` ile dalın köküne
      döner). Kullanılmayan `_shellNavigatorKey` kaldırıldı.

**B) Push edilen sayfalar (Profil/Ayarlar/seans/kütüphane/detay…) — geçiş
animasyonu + zemin sızıntısı:** Samet "Ayarlar ve Profil'de aynı sorun sürüyor"
dedi. Bunlar sekme değil, root navigator'a push ediliyor → IndexedStack kapsamaz.
İki katmanlı sorun çıktı:
1. **Geçiş animasyonu:** Android varsayılan Zoom (ölçek + opaklık fade) canlı
   cam (blur) zeminiyle compose edilince ağır + sayfa soluk/gri açılıyordu.
2. **Zemin sızıntısı (bleed-through) — asıl kusur:** Samet ekran kaydı gönderdi;
   geçiş sırasında **eski sayfanın elementleri yeni sayfanın arkasından
   görünüyordu**. Kök neden mimari: `GlassBackground` navigator'ın ALTINDA
   global çizilir + TÜM scaffold'lar transparan → kayan yeni sayfa saydam
   olduğundan altındaki eski sayfa içeriği görünüyordu. (Zoom'da fade
   maskeliyordu; kaydırma açığa çıkardı — "daha kötü" bunun için.)
- [x] Tema seviyesinde tek geçiş: `app_theme.dart` `pageTransitionsTheme` →
      tüm platformlarda `CupertinoPageTransitionsBuilder` (yatay kaydırma,
      iOS diline uygun, opaklık fade'i yok).
- [x] **Sızıntı düzeltmesi:** push edilen her route (+onboarding) `app_router.dart`
      `_glass(...)` helper'ı ile kendi OPAK `GlassBackground`'ıyla sarıldı →
      kayarken alttaki sayfayı kapatır, sızıntı biter. Palet tek kaynak
      (`AppGlass`) olduğundan görsel birebir aynı, dikiş yok. Global zemin
      shell/sekmeler için kalır (onlar kaymaz + NoTransitionPage). Sekmeler
      etkilenmez.
- [x] **Doğrulama:** analyze 0 · test 137/137 · emülatörde ekran kaydı alınıp
      kareler çıkarıldı: (A) 4 sekme ısındıktan sonra hızlı geçişte içerik
      anında dolu, scroll korunuyor; (B) Home→Profil geçiş-ortası karesinde
      Profil artık TAM OPAK sağdan kayıyor + iOS kenar gölgesi; eski sayfa
      yalnız arkada parallax şeridinde, İÇERİ SIZMIYOR.

**C) Ekran içi sekmeler (Hareket Detayı) yatay kayıyordu:** Samet "sekmeler arası
git gel yaparken slayt değiştirir gibi kayıyor, direkt açılsın" dedi. Teşhis
(timeDilation=8 ile emülatörde yavaşlatıp kare kare): alt navbar içeriği ZATEN
anlık (IndexedStack) — kayan yer `exercise_detail_screen.dart`'taki `TabBarView`
(How/History/Chart/Records) idi; TabBarView sekmeye dokununca içeriği yatay
kaydırır.
- [x] `TabBarView` → `IndexedStack` (controller.index'e bağlı, `AnimatedBuilder`
      ile). Sekmeye dokununca içerik KAYMADAN anlık değişir; tüm sekmeler canlı
      kalır (durum/scroll korunur, tekrar fetch yok). TabBar başlık altı çizgisi
      normal kayar (küçük, sorun değil). Emülatörde doğrulandı: Records'a
      dokununca içerik anında geldi, yatay kayma yok. (Onboarding `PageView`
      kasıtlı kaydırmalı — dokunulmadı.)

---

## ✅ Profil + Ayarlar IA Yeniden Yapılanması (2026-07-05) — docs/16

Samet "Ayarlar best practice mi?" diye sordu → analiz: tek ekran 3 iş yapıyordu
(kişisel veri + konfigürasyon + veri araçları). Karar: ayrı Profil. Tasarım
**[docs/16-settings-profile-ia.md](docs/16-settings-profile-ia.md)** →
B1+B2+B3+B4 aynı gün kodlandı. analyze 0 · test **129/129** (6 yeni:
`week_start_test`) · emülatörde EN+TR doğrulandı.

- [x] **B1 — Profil ekranı** (`features/profile/profile_screen.dart`, `/profile`):
      Hedefler + Vücut (+ İlerleme'ye Ölçümler köprüsü) + Kimlik & Enerji + TDEE
      kartı Ayarlar'dan taşındı. Home app bar dişli → **kişi ikonu** (Profil'e),
      Ayarlar'a Profil sağ üst ⚙️'den gidilir. Ortak tile'lar
      `shared/widgets/setting_tiles.dart`'a çıkarıldı (SettingTile/SectionHeader/
      pickOptionDialog/showNumberEditDialog — kopya yok).
- [x] **B2 — Hakkında/Yasal:** Sürüm satırı → `showLicensePage` (tüm paket
      lisansları); **Açık Veri Kaynakları** atıf ekranı (C-6 KAPANDI: OFF ODbL +
      free-exercise-db public domain + muscle_selector MIT, dış linkli);
      Geri Bildirim → mailto (`AppConstants.supportEmail` — yayın öncesi özel
      adresle değiştirilebilir). `url_launcher` eklendi.
- [x] **B4 — Haftanın İlk Günü** (Pzt/Paz): `core/prefs/week_start_provider.dart`
      (+`startOfWeek` yardımcısı, 6 birim test). Bağlanan yerler: Home hafta
      istatistikleri (dashboard_providers), Antrenman "bu hafta"
      (routine_providers), Aktivite takvimi (başlık sırası + gün hizalama).
      Emülatörde Pazar seçimiyle takvim doğrulandı.
- [x] **B3 — Hesap Silme** (mağaza zorunluluğu): Bulut Hesabı ekranında (oturum
      açıkken) kırmızı "Hesabı Sil" + çift onay → önce bulut yedeği silinir
      (`deleteCloudBackup`) → `rpc('delete_user')` → çıkış. Yerel veri kalır.
      ⚠️ **Samet'in işi:** Supabase SQL Editor'de `delete_user()` security-definer
      fonksiyonunu bir kez çalıştır (SQL: docs/16 §4). Kurulmadan basılırsa
      güvenli hata gösterilir. Gerçek hesapla uçtan uca test edilmedi (emülatörde
      oturum yok).
- [ ] **Yayın öncesi kalanlar (docs/16):** Gizlilik Politikası + Kullanım
      Şartları URL'leri (metin yok — yazılınca About'a link eklenecek),
      "Uygulamayı Puanla" (mağaza linki yayında belli olur), destek e-postası
      kararı (şimdilik iş e-postası).
- [x] **B5 — Birim sistemi (Metrik/İmperial) TAMAM (2026-07-06):**
      `core/units/units.dart` (`unitSystemProvider` + `Units` dönüşüm/format
      yüzeyi, 14 birim test). **DB hep metrik** — dönüşüm yalnız görüntü/giriş
      sınırında, şema değişmedi. Ayarlar → Tercihler → **Birimler**
      (Metrik/İmperial). Geçirilen yüzeyler: Profil (boy **ft-in çift alan**
      `_FtInDialog`, hedef kilo lb + dönüştürülen aralık sınırları), Vücut
      (özet/grafik/tooltip/hedef çizgisi/geçmiş kartları/giriş sheet'i lb-in;
      girişler kg-cm'e çevrilip yazılır), Home (momentum hacim + Bu Hafta
      hacim + kilo mini kart + delta chip + içgörü e1RM), Antrenman listesi
      (haftalık hacim), aktif seans (**KG↔LB sütunu**, ağırlık/mesafe hücreleri,
      PREV etiketi), özet + geçmiş (hacim/set metinleri), hareket detayı
      (geçmiş/e1RM grafiği/rekorlar), Onboarding (kilo/boy/hedef girişleri +
      projeksiyon metni). ARB'lerdeki hardcoded "kg" metinleri
      nötrleştirildi/parametrelendi (`homeStatVolume{unit}`, `bmGoalLine{value}`,
      `onbProjection*{goal}`). **Düzeltilen bug:** dönüşüm sonrası ham double
      ("44.0924452436×10") — `Units.weightValue/distanceValue` yuvarlamalı
      formatlayıcılar eklendi. Emülatörde imperial uçtan uca doğrulandı
      (Profil 172 lb + 5'11", İlerleme 187.4 lb, seans LB + PREV 44.1×10).
- [x] **B6 — Bildirimler TAMAM (2026-07-06, P-11 dahil):**
      `flutter_local_notifications` 22 + `timezone` + `flutter_timezone`;
      Android desugaring (`build.gradle.kts`) + manifest izinleri
      (POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, BOOT_COMPLETED + plugin
      receiver'ları — boot sonrası hatırlatıcılar yeniden kurulur).
      `core/notifications/notification_service.dart` (kanallar: rest_timer
      high / reminders default; `scheduleRestDone` exact→inexact fallback,
      `scheduleDaily` matchDateTimeComponents.time) +
      `notification_prefs.dart` (kalıcı tercihler). Ayarlar → Tercihler →
      **Bildirimler** ekranı: dinlenme sayacı anahtarı + antrenman/su günlük
      hatırlatıcı (anahtar + saat seçici; açılışta Android 13 izin isteği).
      **P-11:** aktif seansta dinlenme sürerken uygulama arka plana geçince
      bitişe bildirim kurulur, öne dönünce/atlayınca iptal. Emülatörde
      doğrulandı: izin dialog'u → sistem alarmı `dumpsys alarm`'da (18:00
      günlük + dinlenme exact) + arka planda dinlenme bildirimi düştü.
      **Sınır:** bildirim metinleri kurulum anındaki dille yazılır (statik);
      dil değişince mevcut zamanlanmışlar eski dilde kalır (bilinen minor).
- [x] **Düzeltme (2026-07-06) — Profil "Ölçümler" köprüsü tab'a ışınlıyordu:**
      Samet bildirdi: imperial→metrik dönmek için Profil'de Ölçümler'e dokununca
      Progress sekmesine fırlatıyordu. Kök neden: Ölçümler `context.go(progress)`
      çağırıyordu; `go` push'lu Profil'i (root navigator) yok edip shell'in
      Progress tab'ına geçiyordu. Düzeltme: ölçüm giriş sheet'i artık **yerinde**
      açılıyor — `body_metrics_screen.dart`'a paylaşılan `showAddMeasurementSheet`
      eklendi (İlerleme FAB'ı + Profil aynı formu kullanır, tek giriş noktası
      korunur; `_save` tüm provider'ları invalidate ettiği için İlerleme de
      tazelenir). Subtitle "İlerleme'de kaydedilir" → "girmek için dokun". Emülatörde
      doğrulandı: Profil → Ölçümler → sheet Profil üstünde açıldı, tab değişmedi.
      *Not: B5/B6 kalıcılığı sağlam — testte "imperial kaldı" görüntüsü, ayarı
      değiştirdikten saniyeler sonra `am force-stop` yapmamdan (shared_preferences
      Android'de asenkron flush); force-stop'suz senaryoda anında persist ediyor.*

---

## ✅ Buton/Renk Tutarlılığı Denetimi (2026-07-05)

Samet ekran görüntüsüyle gösterdi: Antrenman boş halinde İKİ "rutin oluştur"
butonu (EmptyState'in kendi + altındaki kesikli "Yeni Rutin") + buton renkleri
tasarımla uyumsuz (mint/teal tonal, indigo marka rengiyle çakışıyor). Tüm
buton/arka plan kullanımını taradım (gradient CTA'lar zaten hepsi tutarlı
indigo — sorun sadece `FilledButton.tonal`'daydı):
- [x] **Duplike buton düzeltildi:** `workout_list_screen.dart` — rutin listesi
      boşken sadece `_NoRoutines` (EmptyState) aksiyonu gösteriliyor; kesikli
      "Yeni Rutin" butonu artık yalnız EN AZ 1 rutin varken (listenin altında,
      "bir tane daha ekle" amacıyla) görünüyor.
- [x] **`EmptyState` paylaşılan bileşeni** (`shared/widgets/app_state_views.dart`)
      — aksiyon butonu `FilledButton.tonal` (mint/teal) → `FilledButton`
      (indigo, marka rengi). Bu TEK değişiklik uygulamadaki **9 ekranın
      hepsindeki** boş-hal butonunu tutarlı hale getirdi (Antrenman, Beslenme,
      Yemekler, Vücut, Antrenman Geçmişi, Hareket Detayı/Kütüphanesi, Rutin
      Önizleme, Ayarlar).
      barcode_scan_screen.dart'taki 2 "Elle gir" tonal butonu da aynı sebeple
      indigo `FilledButton`'a çevrildi.
analyze 0 · test 123/123 · emülatörde doğrulandı (Antrenman boş hal artık tek
buton, indigo).

---

## 🌐 Çok Dilli (EN/TR) — Faz A başladı (2026-07-05) — `feat/glass-redesign`

Tasarım: [docs/14-localization.md](docs/14-localization.md). Yaklaşım: Flutter
`gen-l10n` + ARB. Varsayılan **cihaz dilini takip et**, `en` fallback (İngilizce
öncelik). Ayarlar → Görünüm → **Dil** (Sistem/English/Türkçe), kalıcı. Tarih/sayı
biçimi artık locale-duyarlı (`tr_TR` sabiti kaldırıldı). analyze 0 · test 110/110.

**Altyapı (bitti):** `flutter_localizations` + `generate: true`, `l10n.yaml`,
`lib/l10n/app_en.arb` + `app_tr.arb`, `AppL10n`, `core/i18n/locale_provider.dart`,
`core/i18n/formatting.dart` (`context.dateFmt/numFmt/localeName`),
`core/i18n/enum_labels.dart` (aktiflik/cinsiyet/tema/dil etiketleri). `main.dart`
en+tr tarih verisi yükler; `app.dart` locale + delegates bağlı.

**Migrate edildi (EN/TR emülatörde doğrulandı):**
- [x] Alt navigasyon (`app_shell.dart`)
- [x] Ana Sayfa (`home_screen.dart`) — ICU çoğul (streak), locale sayı/tarih
- [x] Ayarlar (`settings_screen.dart`) + **Dil seçici** eklendi
- [x] `CalorieRing` "kcal kaldı/fazla" (`progress_indicators.dart`)
- [x] Ölü kod temizliği: `themeModeLabelTr`, `activityLabelsTr` kaldırıldı

**✅ UI MIGRATION TAMAM (2026-07-05, aynı oturum):** Beslenme+barkod+Yemekler,
Onboarding (V2 ile), **Antrenman kümesinin tamamı** (liste/builder/aktif
seans/geçmiş/özet/önizleme/kütüphane/detay), İlerleme/Vücut/Aktivite takvimi,
Export, Cloud, ortak widget'lar (Empty/Error/confirm/restart/SheetHeader).
`tr_TR` sabiti lib'de sıfır; haftaiçi adları locale'den
(`context.weekdayName/weekdayShort`). Birim etiketleri (porsiyon/adet…) locale
seçenekli + eski kayıtlı değeri koruyan `unitOptionsWith`. ~300 ARB anahtarı.
analyze 0 · test 123/123 · EN+TR emülatörde doğrulandı (Antrenman, Beslenme,
İlerleme ekran görüntüleri).

**✅ Emoji/sembol denetimi (2026-07-05):** UI'daki tüm emojiler temalı ikonlara
çevrildi: streak 🔥→ alev ikonu (warning tint), 💪→ bolt (indigo), onboarding
✨→ auto_awesome (teal), Rekorlar 🏆🏋️📈→ ikon-rozet, kilo rozeti ↓↑ metin oku →
arrow ikonları. Kural CONVENTIONS §5b'ye eklendi (emoji yasak).
Emülatörde doğrulandı.

**Kalan küçük işler (i18n) — TAMAM (2026-07-08):** Samet "tüm metinleri incele,
hardcoded var mı, kapsayan düzenlemeyi yap" dedi. Türkçe-karakterli string
literal taraması + Text/label/hint/tooltip/throw taraması yapıldı; kalan tüm
UI-seviyesi sızıntılar kapandı:
- [x] `workout_list`: "N rutin"/"N hareket" → ICU plural (`workoutRoutineCount`,
      `workoutExerciseCount`). EN "1 routine/1 exercise" + TR "1 rutin/1 hareket"
      emülatörde doğrulandı.
- [x] Servis istisnaları → **tipli** `BackupException(BackupErrorKind)` +
      `backupErrorMessage(l, kind)` UI eşlemesi (`backup_service` invalidFile/
      newerVersion, `cloud_backup_service` notSignedIn). settings + cloud
      ekranları `on BackupException` yakalar. Paylaşım metni param'la
      yerelleştirildi (`backupShareText`). `workout_summary` iç StateError →
      İngilizce (UI'a düşmüyor, hijyen).
- [x] `export_service` **Markdown raporu** tamamen yerelleştirildi: `exportMarkdown`
      artık `(…, AppL10n l, String localeName)` alır; ~30 `exportRpt*` ARB anahtarı
      (başlıklar, tablo başlıkları, gün adları locale'den, set tipleri, boş-hal
      metinleri). CSV weekday da locale'e bağlandı. JSON/CSV veri anahtarları
      İngilizce kalır (makine-okunur — doğru). export test EN'e güncellendi.
- Kalan hardcoded: yalnız `MaterialApp.title='Fit Pack'` (marka) ve iç hata
  mesajı (görünmez) — kabul edilebilir. analyze 0 · test 137/137.
  **Not:** yemek/egzersiz adları + birim etiketleri (avuç/adet/bardak) hâlâ
  tek dilli — bunlar KOD değil DB içeriği → ayrı **Faz B** (şema v9, aşağıda).

**✅ Kaçan UI-chrome sızıntıları düzeltildi (2026-07-05, aynı gün, ikinci tur):**
Samet "Antrenman/Beslenme/İlerleme Türkçe kalmış" dedi → emülatörde EN modda
uçtan uca tekrar tarandı (üç tab + Add Food/custom food/barkod/aktif
seans/özet). Kök neden 4 gerçek kod-seviyesi sızıntı (içerik değil):
- `MacroInlineText` (`shared/widgets/progress_indicators.dart`) P/K/Y harfleri
  hardcoded Türkçeydi → `macroProteinAbbr/CarbsAbbr/FatAbbr` ARB anahtarı
  (EN: P/C/F, TR: P/K/Y). Beslenme'nin her yerinde makro rozeti etkiliyordu.
- `nutrition_screen.dart` yemek silme SnackBar'ı ("... silindi" + "Geri al")
  hardcoded Türkçeydi (var olan `foodsDeleted` + yeni `commonUndo` anahtarına
  bağlandı — `foods_screen.dart` zaten doğru kullanıyordu, bu ekran atlanmış).
- `workout_summary_screen.dart`: hareket adı bulunamazsa 'Hareket' fallback'i
  hardcoded → `wsUnknownExercise` anahtarına taşındı (nullable `_ExerciseRecap.name`).
- `workout_draft.dart`: bozuk taslak JSON'da başlık fallback'i 'Antrenman' →
  'Workout' (context yok; diğer benzer fallback'lerle tutarlı).
analyze 0 · test 123/123 · emülatörde EN modda doğrulandı (Add Food listesi
P/C/F + silme "deleted"/"Undo", boş antrenman → set → Workout Summary).
**Not:** Yemek adları + birim etiketleri (avuç/adet/bardak/porsiyon — "1 apple"
yerine "1 adet ≈ 170 g") hâlâ Türkçe; bunlar `turkish_foods.json` içeriği,
kod değil → **Faz B** kapsamında (aşağıda).

**Faz B (içerik i18n — ertelendi, çok turlu):** şema v9 + çift dilli seed
(egzersiz/besin adları + birim etiketleri). Detay docs/14 §Faz B. Ayrı PRD
gerekir. Samet'e bunun ayrı/büyük iş olduğu hatırlatılmalı.

---

## ✅ Onboarding V2 TAMAM (2026-07-05) — `feat/glass-redesign`

Tasarım + uygulama aynı gün: **[docs/15-onboarding.md](docs/15-onboarding.md)**.
analyze 0 · test **123/123** · sıfır kurulum emülatörde **EN + TR** uçtan uca
doğrulandı (per-app locale ile TR; ekran görüntüleri alındı).

- [x] **O-1:** A1+A2 glass reskin — Karşılama (gradient marka rozeti) +
      "Seni tanıyalım" (GlassCard grupları), tamamen ARB'li
- [x] **O-2:** A3 "Planın hazır ✨" — kalori/protein + **değer projeksiyonu**
      (`projectWeeks` — kullanıcının girdiği kaloriden; 85→78 kg = 14 hafta
      doğrulandı). `onboarding_calc` görünen metinlerden arındırıldı, 9 birim test
- [x] **O-3:** A4 "İçeride ne var" — 4 sekme haritası, 4 sayfa navigasyon
- [x] **O-4:** Coach mark altyapısı (`core/onboarding/first_run_hints.dart`,
      paketsiz OverlayEntry+CustomPaint spotlight) + 3 ipucu (Antrenman/Beslenme/
      İlerleme FAB-CTA'ları) + **mevcut kullanıcı koruması** (`initialize()` —
      marker'lı, idempotent; 3 test). Balon hedefin boş tarafına yerleşir;
      scrim/Anladım kapatır; tekrar gösterilmez (emülatörde teyit).
      **Düzeltilen bug:** Riverpod lazy provider → ilk okuma "hepsi görüldü"
      varsayılanına takılıyordu; karar artık doğrudan prefs'ten (`isUnseen`).
- [x] **O-5:** Boş hal denetimi — Antrenman "Rutin oluştur" + İlerleme "İlk
      ölçümünü ekle" aksiyonları bağlandı (ikisi aksiyonsuzdu); diğerleri zaten
      uyumluydu. (Bu iki metin ekranlarıyla birlikte i18n batch'inde ARB'ye taşınacak.)

---

## 🎨 Ana Sayfa Dashboard Reskin (2026-07-04) — `feat/home-dashboard`

ChatGPT'de üretilen dashboard tasarımı (`design/current-ui-spec.md` + `fit-pack-ui(1).html`) → farkı bizim tasarım diline (gerçek token + veri) geçirildi. analyze 0 · test 110/110.

- [x] **Momentum hero** — seri ("X gündür ritimdesin 🔥") + son 30 gün özeti (antrenman/hacim/kcal). Provider `last30WorkoutStatsProvider` (takvim ayı yerine kayan pencere — ayın 1'inde de dolu).
- [x] **"Bu Hafta" 2×2 metrik grid** — hacim + geçen haftaya göre % değişim, yakılan kcal, antrenman (planlı güne göre X/Y), protein hedefi ort. Provider `weekDashboardProvider`.
- [x] **Kompakt beslenme** — küçük halka + yan makro barları (tam ekran hero yerine).
- [x] **İçgörü motoru** — `topProgressExercise`: son 6 haftadaki tüm hareketlerin e1RM artışını tarar, en çok gelişeni gösterir; veri yoksa kart gizlenir (sahte içgörü yok). DAO: `getWeightedSetPointsInRange`.
- [x] **Su + Kilo mini kartları** — yan yana; su +250 ml + uzun bas sıfırla, kilo son değer + trend.
- Saf hesap katmanı: `lib/features/home/dashboard_stats.dart` (test: `dashboard_stats_test.dart`).
- **Emülatörde 10 günlük dummy veriyle** görsel doğrulandı (tüm ekranlar dolu). Dummy veri repoda değil (yalnız cihaz DB'sinde).
- **Çıkarılanlar:** mock'taki uydurma "%uyum" rozeti + sabit "~58 dk / +7.5 kg" değerleri (dürüst veri kaynağı yok).

---

## 🔍 Kod İncelemesi & Tutarlılık Refactor'u (2026-07-04) — `fix/code-review`

Tam kod denetimi yapıldı → [CODE_REVIEW.md](CODE_REVIEW.md) (bulgular + batch planı orada).

- [x] **Faz 1 — Denetim:** 1 CRITICAL + 6 HIGH + 11 MEDIUM + 9 LOW bulgu, rapor yazıldı
- [x] **Batch 1 — Veri güvenliği:** güvenli geri yükleme (emniyet kopyası + atomik değişim + sürüm kontrolü), kapatılamaz yeniden-başlat diyaloğu, seans/rutin yazımları transaction'lı. analyze 0 · test 96/96
- [x] **Batch 2 — Doğruluk:** H-01 gün sınırı çift sayım, H-02 seans listesi key'leri, H-05 kilo invalidate, M-01 resume routineId, M-10 onboarding, M-11 getSessionById. analyze 0 · test 99/99
- [x] **Batch 3 — Tazelik & dayanıklılık:** M-02 gece yarısı bekçisi, M-03 dinlenme sayacı duvar saati, M-04 açılış seed guard (seedVersion), M-06 ConsumerStatefulWidget + container yakalama, L-04. analyze 0 · test 99/99
- [x] **Batch 4 — Temizlik:** M-07 export V2, M-09 ölü kod, L-01/02/03/06/08/09 (L-05 phase = şema, V3'e bırakıldı). analyze 0 · test 102/102
- [x] **Faz 3 — CONVENTIONS.md + proje-içi CLAUDE.md oluşturuldu** (standartlar sabitlendi, CLAUDE.md CONVENTIONS'ı zorunlu okuma işaretliyor)
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
