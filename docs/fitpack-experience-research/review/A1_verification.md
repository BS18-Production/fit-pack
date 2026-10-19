# A1 — 02–10 ve workstreams/ raporlarının iddia iddia doğrulaması

18 Ekim 2026 · kaynak anı `main` = `07104d1` (çalışma ağacı temiz; yalnız `CODE_REVIEW_REPORT.md` ve araştırma klasörü izlenmiyor) · yazan: Claude (A1 ajanı) · üretim koduna dokunulmadı.

## Karar özeti

- Paketin FitPack'e dair **kod iddiaları büyük ölçüde doğru**. 195 somut iddia kontrol edildi: **180 Doğru, 13 Kısmen, 1 Yanlış, 1 Doğrulanamadı**. Raporlardaki 382 `dosya:satır` atfının tamamı var olan satırlara işaret ediyor. Kaymalar genelde 1–15 satır: davranış doğru, satır numarası yan satırı gösteriyor.
- **39 rota, U01–U12, P01–P12 ve Q01–Q08'in kanıtları kodla örtüşüyor.** ✓ 38×34, ± 36×30, set türü 30×32 ölçüleri, Beslenme → Hedefler'in Ayarlar'a gitmesi (U03) ve özet hatasında `SizedBox.shrink()` (U07) birebir doğrulandı.
- **Kontrast oranlarının hepsi yeniden hesaplandı ve tuttu.** İpucu metni %40 alfa için koyu temada 2,134:1, açık temada 1,717:1 çıktı; tablodaki diğer 6 satır da aynı. 4,5:1 eşiğine ulaşmak için alfanın koyuda en az 0,82, açıkta en az 0,96 olması gerekiyor.
- **Tek Yanlış iddia** 02'nin girişinde: 6/6 render testinin "rutin/seans akışını kapsadığı" yazıyor. Bu testler aktif seans ekranını hiç açmıyor. 76 görüntünün hiçbiri `/workout/active` değil. Yani en kritik bulgular (U01, U04, Q01–Q03) **görselle değil, yalnız kodla** destekleniyor.
- **Q02/P02'deki çerçeve Kısmen doğru.** Aktif setin altındaki `_ActiveSetAssist` satırı (`active_session_widgets.dart:559–633`), ✓'in kaydedeceği değeri birincil renkte zaten açıkça yazıyor (koyu 13,7:1, açık 6,2:1). %40 soluk olan yalnız alan içi ipucu. Sorun gerçek ama "öneri hiç okunmuyor" değil.
- **Paketin kaçırdıkları:**
  - 48'in altında 10 dokunma hedefi daha var. Bunlardan biri, mola bandındaki −15s/+15s/Atla düğmeleri (yaklaşık 31 px).
  - 3 kontrast açığı daha var: açık temada ÖNCEKİ sütunu (4,278:1), açık temada mola düğmeleri (4,164:1), koyu temada kilo grafiği ipucu (3,059:1).
  - Yemek panelinde adsız ± düğmeleri var.
  - Hatayı sessizce 0'a ya da varsayılana çeviren 10 durum var; en önemlisi `activeDraftProvider` hatasında "Devam et" kartının kaybolması.
  - Altı dosyada `Color(0x…)` hiç yok; renk tokenlarını atlayan kod bulunamadı.

## Yöntem ve sınırlar

- 02, 04, 05, 06, 07, 08, 09, 10, `workstreams/technical-accessibility.md` ve `workstreams/behavioral.md` baştan sona okundu. 03 ve `workstreams/competitive-sources.md` içinde yalnız FitPack'e dair cümleler okundu.
- Her iddia için atıf yapılan satır açıldı (`sed`/`awk`). Hüküm davranışa göre verildi; satır kayması ayrıca not edildi.
- Bütün atıfların var olup olmadığı küçük bir betikle tarandı (382 atıf). 3 "uyarı" yanlış alarm çıktı: router'ın `:109` satırı splash dosyasına bağlanmıştı, iki ayrı `build.gradle.kts` var, `:69` ise `rpe_scale` ile karıştırılmıştı (J24).
- Kontrast hesabı Python ile token değerlerinden yapıldı (aşağıda). Alfa bileşimi sRGB uzayında yapıldı, Flutter/Skia da bu şekilde karıştırıyor.
- Dokunma hedefi ölçüleri **koddan yaklaşık hesap**: dolgu + Plus Jakarta Sans satır yüksekliği (yaklaşık 1,26 × yazı boyu). Çalışan uygulamada ölçülmedi (G yok). `IconButton`/`TextButton` için `MaterialTapTargetSize.padded` varsayılanı hesaba katıldı; bunlar `VisualDensity.compact` olsa bile 48 vuruş alanı korunuyor, o yüzden sayılmadı.
- **Yapılmayanlar:** emülatör/simülatör gezintisi, ekran okuyucu, gerçek render ölçümü. Yalnız `visuals/current/dark-tr-home.png` açılıp bakıldı (G).
- Kanıt sınıfları: **K** = kod (dosya:satır), **G** = görüntü, **S** = standart, **H** = hipotez. Hüküm etiketleri:
  - **Doğru:** davranış ve kanıt kodla örtüşüyor (satır ±15 kayabilir).
  - **Kısmen:** davranış doğru ama satır, koşul ya da kapsam eksik veya yanlış.
  - **Yanlış:** iddia kodla çelişiyor.
  - **Doğrulanamadı:** süreç iddiası, koddan kontrol edilemez.

Aşağıda dosya yolları aksi yazılmadıkça `lib/features/` köküne göredir.

## Özet tablo

| Rapor | Kontrol edilen | Doğru | Kısmen | Yanlış | Doğrulanamadı |
|---|---:|---:|---:|---:|---:|
| 02 Mevcut durum (envanter + U01–U12) | 45 | 41 | 3 | 1 | 0 |
| 03 (yalnız FitPack iddiaları) | 6 | 6 | 0 | 0 | 0 |
| 04 Yolculuklar (dokunuş sayıları) | 24 | 23 | 1 | 0 | 0 |
| 05 Tasarım yönleri | 7 | 6 | 1 | 0 | 0 |
| 06 Bilgi mimarisi | 5 | 5 | 0 | 0 | 0 |
| 07 Tasarım sistemi (token/bileşen) | 18 | 18 | 0 | 0 | 0 |
| 08 Fırsatlar P01–P12 | 13 | 11 | 2 | 0 | 0 |
| 09 Yol haritası | 3 | 2 | 1 | 0 | 0 |
| 10 Doğrulama (test iddiaları) | 11 | 10 | 0 | 0 | 1 |
| workstreams/technical-accessibility (Q01–Q08 + tablo) | 43 | 39 | 4 | 0 | 0 |
| workstreams/behavioral | 18 | 17 | 1 | 0 | 0 |
| workstreams/competitive-sources | 2 | 2 | 0 | 0 | 0 |
| **Toplam** | **195** | **180** | **13** | **1** | **1** |

## Bulgular — iddia iddia

### 02 — Mevcut deneyim denetimi

| # | İddia | Hüküm | Kanıt (K/G) |
|---|---|---|---|
| A01 | 39 `GoRoute` | Doğru | K `core/router/app_router.dart:92–341`: 8 kapı rotası + 4 shell dalı + 27 kök rota = 39 |
| A02 | Rota kaynağı `:90–340` | Doğru | K `routes: [` 90 → son rota 337–341 |
| A03 | Dört sekme ayrı canlı dal (`:135`, `app_shell.dart:33`) | Doğru | K `:137` `StatefulShellRoute.indexedStack`; `shared/widgets/app_shell.dart:36–39` `goBranch` |
| A04 | Onboarding 4 sayfa (`onboarding_screen.dart:253`) | Doğru | K `:254–276` `_TrainingPage`, `_ProgramPage`, `_AboutYouPage`, `_PlanPage` |
| A05 | İlk hafta rehberi 14 gün | Doğru | K `home/first_week.dart:14` `firstWeekWindowDays = 14`; `home_screen.dart:453` |
| A06 | Günlük satır + "Haftan hazır" var | Doğru | K `home_screen.dart:512`, `:610` |
| A07 | Ara uzadı / planlı gün / ilk hafta hatırlatmaları var | Doğru | K `workout/recall_reminders.dart:11`, `recall_missed_day.dart`, `recall_first_week.dart:10` |
| A08 | Ekleme paneli kapanmadan çoklu kayıt alıyor, son porsiyonu hatırlıyor, geri alma var | Doğru | K `nutrition/add_food_sheet.dart:147–175` (`_add` paneli kapatmıyor), `:214` `_pushRecent`, `:189` `_undo`. `:32` yalnız doküman yorumu |
| A09 | Sabit alttaki Yemek Ekle + barkod | Doğru | K `nutrition/nutrition_screen.dart:164–205` |
| A10 | Önceki set / RPE (Rating of Perceived Exertion; algılanan zorluk) / rekor / ilerleme önerisi var (`widgets:1043`, `:758`) | Kısmen | Davranış doğru (K `active_session_screen.dart:598–616`, `active_session_widgets.dart:758`). `:1043` satırı ise süre sayacı yorumu, iddiayla ilgisiz |
| A11 | Fotoğraflar cihazda; sağlık rızası ve geri alma var | Doğru | K `health/body_consent_sheet.dart:15`, `progress_photos/progress_photos_screen.dart:267` `_DeviceOnlyNote` |
| A12 | Render testleri 6/6 geçti, 76 görüntü üretildi | Doğru | K `/tmp/fitpack-experience-render.log:168` "+6: All tests passed!"; `visuals/current` içinde 76 PNG |
| A13 | "Otomatik widget etkileşimleri … rutin/seans akışını kapsar" | **Yanlış** | K `test/features/neon_design_test.dart:170–190`: gezilen rotalar workout, nutrition, progress, routinePreview(1), routineEdit(1), history, summary(1)… `workoutActive` **yok**. 76 görüntüde aktif seans yok. Testteki dokunuşlar yalnız öğün ve sil/geri al (`:158`; `warm_nutrition_test.dart:72–116`) |
| A14 | #09 Home sırası: hafta → haftalık kart → beslenme → seans → günlük → ritim/asistan → sağlık | Doğru | K `home_screen.dart:76–101` |
| A15 | Home beslenmesinde iskelet/hata/tekrar dene; rutin hatasında genel başlangıç | Doğru | K `home_screen.dart:1093–1097`; `:201` `_StartWorkoutCard` |
| A16 | #11 Beslenme özeti hatada gizleniyor | Doğru | K `nutrition_screen.dart:242` |
| A17 | #12 İlerleme sırası: aktivite → fotoğraf → ölçüm; Y/H/tekrar/B | Doğru | K `body_metrics/body_metrics_screen.dart:75–115` |
| A18 | #18 Geliştirici paneli uzun basmayla açılıyor | Doğru | K `settings/settings_screen.dart:236` |
| A19 | #23 Home "Başla" önce önizlemeyi açıyor | Doğru | K `home_screen.dart:342`, `:368`; `workout/routine_preview_screen.dart:75` |
| A20 | #24 Normal geri dönüş taslağı atıyor; Bitir üstte, ✓ dar | Doğru | K `active_session_screen.dart:980–988`, `:1037`; `active_session_widgets.dart:1238–1240` |
| A21 | #25 Taslak yoksa boş seans açılıyor; yükleme hatası kullanıcıya tekrar sunulmuyor | Doğru | K `active_session_screen.dart:503–513` (try/catch yok); `workout/workout_draft.dart:154–161` (bozuk taslak sessizce `null` dönüyor) |
| A22 | #27 Geçmiş kayıt kip etiketi `:1008` | Kısmen | Etiket `:1006` (`asPastEntry`) ve `SessionDateBar highlight` `:1071`; satır kayık |
| A23 | #32 Seçim kipi tek hareket döndürüyor, çoklu seçim yok | Doğru | K `workout/exercise_library_screen.dart:251–252` `Navigator.pop(context, e)` |
| A24 | #33 Hareket detayında dört iç sekme | Doğru | K `workout/exercise_detail_screen.dart:62–66` |
| A25 | Ekleme paneli %94 yükseklik | Doğru | K `add_food_sheet.dart:376` `initialChildSize: 0.94` |
| A26 | Envanterdeki diğer satır atıfları (örneklem 70 atıf: auth, takvim, asistan, fotoğraf, kurucu, program, özet, besinler, hesap, bildirim…) | Doğru | K hepsi ilgili yapıya işaret ediyor (ör. `cloud/cloud_account_screen.dart:254` `_deleteAccount`, `settings/notifications_screen.dart:230` `SwitchListTile`) |
| A27 | U01 İki seçenekli çıkış diyaloğu; onay `_clearDraft()` + pop | Doğru | K `active_session_screen.dart:947–965`, `:985–988` |
| A28 | U01 Aktif rota kök navigator'da, sekmeler görünmüyor | Doğru | K `app_router.dart:246–250` `parentNavigatorKey: _rootNavigatorKey` |
| A29 | U01 `dispose` canlı kartı sonlandırıyor (`:490`) | Kısmen | `dispose` `:483`, `_live.end()` `:493`; `:490` bekleyen taslak yazımı |
| A30 | U02 Sıra hafta → haftalık özet → beslenme → aktif eylem | Doğru | K `home_screen.dart:79–84` |
| A31 | U02 `_PrimaryActionCard` önce taslağı seçiyor | Doğru | K `home_screen.dart:194–195` |
| A32 | U03 Hedefler Ayarlar'a gidiyor | Doğru | K `nutrition_screen.dart:237` `context.push(AppRoutes.settings)`; düğme metni `settingsSectionGoals` = "Hedefler" (`warm_nutrition_summary.dart:62–63`, `app_tr.arb:520`) |
| A33 | U03 Ayarlar'da hedef alanı yok | Doğru | K `settings_screen.dart:213–224` Beslenme bölümünde yalnız "Besinler" var |
| A34 | U03 kcal/protein düzenleme Profil'de | Doğru | K `profile/profile_screen.dart:221–249` |
| A35 | U04 ✓ 38×34 | Doğru | K `active_session_widgets.dart:1238–1240` |
| A36 | U04 ± 36×30 | Doğru | K `active_session_widgets.dart:654–656` |
| A37 | U04 Özel `InkWell`; IconButton gibi genişlemiyor | Doğru | K `:1234`, `:651` çıplak `InkWell` + `SizedBox` |
| A38 | U05 /progress vücut odaklı; kuvvet `/exercise/:id`'de; haftalık değerlendirme ayrı | Doğru | K `app_router.dart:176`; `exercise_detail_screen.dart:62–66`; `:203` |
| A39 | U06 Gün kayıtlarında antrenmanda "Aç" var, beslenme salt özet | Doğru | K `calendar/day_records.dart:67–72` tek `push`; `:105` beslenme satırının eylemi yok |
| A40 | U07 Özette `SizedBox.shrink()`, günlükte `ErrorState` | Doğru | K `nutrition_screen.dart:242`, `:257` |
| A41 | U08 Önizleme zorunlu ara adım | Doğru | K A19 ile aynı |
| A42 | U09 Keşfet rutinlerden sonra | Doğru | K `workout/workout_list_screen.dart:107` `ExploreSection` (atıf `:120` = `_groupedRoutines`, yakın) |
| A43 | U10 2/gün, 6/7 gün, 22–08 sessiz, 3 gün → 14 gün susturma | Doğru | K `recall_reminders.dart:21–31` |
| A44 | U11 Bütün kartlar aynı `ListView`'da | Doğru | K `home_screen.dart:76–101` |
| A45 | U12 login-callback dışındaki her istisna Home'a gidiyor | Doğru | K `app_router.dart:83–89` |

### 03 — Rakip araştırması (yalnız FitPack iddiaları)

| # | İddia | Hüküm | Kanıt |
|---|---|---|---|
| B01 | Yerel kanıt `home_screen.dart:188, :297, :349, :453, :512` | Doğru | K `_PrimaryActionCard`, `_ResumeCard`, `_UpNextCard`, `_FirstWeekCard`, `_TodayLines` |
| B02 | Bağlamsal ana kart, dönüş, haftalık seri, rekor, öğün kopyalama, trend/harcama ve asistan zaten var | Doğru | K `home_screen.dart:188`, `:297`; `streak_calc.dart`; `record_calc.dart`; `meal_copy_sheet.dart`; `profile/adaptive_tdee_provider.dart`; `assistant/` |
| B03 | C03 `_PrimaryActionCard` durumları (devam / planlı / döngü) | Doğru | K `home_screen.dart:194–207` |
| B04 | C07 Seri haftalık hedef bazlı | Doğru | K `home_screen.dart:868–870` yorumu; `home/streak_calc.dart:6` |
| B05 | C08 Mevcut ilerleme önerisinde RPE etkisi var | Doğru | K `active_session_widgets.dart:791–794` `topRpe`, `hardIncrease` |
| B06 | C12 "Kendim kuracağım" seçeneği var | Doğru | K `onboarding/onboarding_screen.dart:25` |

Ek bilgi (C02 için): "ÖNCEKİ" değeri **rutinden bağımsız son kayıt**. K `data/database/daos/workout_dao.dart:568–573` sorgusunda yalnız `exerciseId` filtresi var, `limit(1)`. Önerilen "Bu rutinde son / Son kayıt" etiketinin doğru karşılığı "Son kayıt".

### 04 — Kullanıcı yolculukları (dokunuş sayıları)

| # | İddia | Hüküm | Kanıt |
|---|---|---|---|
| C01 | A: Home → önizleme → aktif = **2** | Doğru | K `home_screen.dart:342` (kart ve düğme aynı `onTap`); `routine_preview_screen.dart:75` |
| C02 | A: Antrenman sekmesinden = **3** | Doğru | K sekme + `workout_list_screen.dart:570` + önizleme FAB (yüzen eylem düğmesi) |
| C03 | A: Hazır öneriyi kabul = **1/set** | Doğru | K `active_session_screen.dart:598–603` `_fillFromSuggestion` |
| C04 | A: Mola başlatma = **0** (`restSec > 0` ise otomatik) | Doğru | K `active_session_screen.dart:616` |
| C05 | A: Hareket ekle = **2** | Doğru | K `:1117` + `:768`; `exercise_library_screen.dart:251` |
| C06 | A: Bitir = **1** (onay diyaloğu yok; veri yoksa uyarı şeridi) | Doğru | K `active_session_screen.dart:902–944` |
| C07 | Koşullu örnek 4 seçim / N+3 | Doğru | K C01 + C03 + C06 toplamı |
| C08 | B: Beslenme → Ekle → hızlı + = **3**; Bitti ile **4** | Doğru | K `nutrition_screen.dart:179`; `add_food_sheet.dart:1021–1023`; `:596–597` (Bitti yalnız `sessionCount > 0` iken) |
| C09 | B: Porsiyon yolu **4/5** | Doğru | K `add_food_sheet.dart:522` + `:1384` |
| C10 | B: Home öğün → hızlı + = **2**; dönüş ile **3** | Doğru | K `nutrition/today_meals_card.dart:138–143` |
| C11 | B: Alışılmış öğün = **1** | Doğru | K `nutrition/nutrition_habit_widgets.dart:146–148` |
| C12 | B: Panel ekledikten sonra kapanmıyor | Doğru | K `add_food_sheet.dart:169–175` |
| C13 | C: Home kaynak sırası | Doğru | K `home_screen.dart:76–101` |
| C14 | C: Aktif 1 · sıradaki 2 · rutinsiz 1 · öğün yok 1 · hedef tamamsa satır yok (0) · haftan hazır 1 | Doğru | K `:195`, `:342`, `:424`, `today_lines.dart:116`, `:640–643` |
| C15 | D: Son seans = **2** | Doğru | K `workout_list_screen.dart:391` `_RecentWorkouts`; `history_card.dart:61–62` |
| C16 | D: Tüm geçmiş = **3** | Doğru | K `workout_list_screen.dart:226–230` |
| C17 | D: Hareket grafiği = **4** | Doğru | K kütüphane simgesi + `exercise_library_screen.dart:253` + `exercise_detail_screen.dart:64` |
| C18 | D: Haftalık odak = **1** | Doğru | K `home_screen.dart:1000`, `:642` |
| C19 | D: Kilo/fotoğraf: İlerleme **1** (+1) | Doğru | K sekme; `body_metrics_screen.dart:198` |
| C20 | E: Süreç öldürüldükten sonra Home'dan devam = **1** | Doğru | K `home_screen.dart:318–320` |
| C21 | E: Geri + çık onayı = **2** ve taslak siliniyor | Doğru | K `active_session_screen.dart:980–988` |
| C22 | E: Taslağı koruyarak başka sekmeye geçmenin yolu yok | Doğru | K `:981` `canPop: false`; kök rota |
| C23 | E: Kilit ekranında ±/tamamla, molada +15/atla | Doğru | K `active_session_screen.dart:190–200`; `ios/WorkoutLiveActivity/WorkoutLiveActivityWidget.swift:128–160` |
| C24 | Mola atfı `:620` | Kısmen | `:620` `_fillFromSuggestion` sınırı; otomatik mola `:616` |

### 05 — Tasarım yönleri

| # | İddia | Hüküm | Kanıt |
|---|---|---|---|
| D01 | Mat karbon + lime: `app_colors.dart:6–12` | Kısmen | `:8–13` yalnız lime/amber/onGradient; karbon tonları `:31–38` |
| D02 | Başlık + şerit + büyük halka eylemden önce geliyor; eylemi görmek için kaydırma gerekiyor | Doğru | K `home_screen.dart:77–84`; G `visuals/current/dark-tr-home.png` (393×852): "BUGÜNÜN PLANI" kartı ekranın altında, düğme gezinme çubuğunun altında kalıyor |
| D03 | Enerji + protein eşmerkezli halka + üç makro çubuğu | Doğru | K `nutrition/nutrition_summary_card.dart:63–70` (`CalorieRing` + protein), `:106–122` `MacroBar` |
| D04 | Beslenmenin sıcak ayrı teması | Doğru | K `core/theme/nutrition_theme.dart:5–9`, `:22` |
| D05 | Tahmini kalori kavisli çizgiyle | Doğru | K `home/workout_activity_card.dart:174` `isCurved: true` |
| D06 | Plus Jakarta Sans yerel paketli | Doğru | K `assets/fonts/` 5 TTF, `pubspec.yaml:124`. Not: `GoogleFonts.config.allowRuntimeFetching = false` yalnız testlerde var, `lib/`'de yok |
| D07 | Platforma göre sayfa geçişi | Doğru | K `core/theme/app_theme.dart:110–114` |

### 06 — Bilgi mimarisi

| # | İddia | Hüküm | Kanıt |
|---|---|---|---|
| E01 | Mevcut ağaç (Home → Profil → Ayarlar/Hesap …) | Doğru | K `home_screen.dart:163`; `profile_screen.dart:334` |
| E02 | Kaynak `app_router.dart:135`, `:183–340` | Doğru | K |
| E03 | Yapısal zayıflıklar tablosu (6 satır) | Doğru | K U01/U03/U05/U06/U09/U11 kanıtlarıyla aynı |
| E04 | Bağlam kuralı kaynakları (`home:188`, `first_week:29`, `today_lines:116`, `week_ready:29`, `routine_providers:54`) | Doğru | K |
| E05 | Aktif seans sekmeleri örtüyor, geri onayı taslağı siliyor | Doğru | K A20, A28 |

### 07 — Tasarım sistemi: token ve bileşen envanteri

| # | İddia | Hüküm | Kanıt |
|---|---|---|---|
| F01 | `app_colors.dart` Material rolleri + `AppSemanticColors` | Doğru | K `:15–80`, `:129` |
| F02 | `app_dimens.dart`: 4–32 boşluk, 12 kontrol köşesi, 150/160/250/400 ms, 48 hedef | Doğru | K `:10–16`, `:46`, `:78–81`, `:87` |
| F03 | `app_theme.dart`: yerel Plus Jakarta + Material düğme/giriş stilleri | Doğru | K `:35–89`, `:160–263` |
| F04 | `GlassCard` canlı blur'u varsayılan kapalı | Doğru | K `shared/widgets/glass.dart:59`, `:69` `this.blur = false` |
| F05 | `NutritionTheme` yerel alt tema (`:22`) | Doğru | K |
| F06 | `VelocityNavigation`: seçili durum, semantik ad, azaltılmış hareket | Doğru | K `shared/widgets/velocity_navigation.dart:33–35`, `:60–64` |
| F07 | Tamamla 38×34; 2,134 / 1,717 | Doğru | K + hesap (aşağıda) |
| F08 | Zemin = `surfaceContainerLowest` / `surface` / container rolleri | Doğru | K `app_colors.dart:31–37`; canvas `glass.dart:45` `surfaceContainerLowest` |
| F09 | Köşe: kontrol 12, kart 20/24, panel 24 | Doğru | K `AppRadius` `:46`, `:53–54`; `app_theme.dart:353` |
| F10 | Özel 26 gibi değerler | Doğru | K `app_dimens.dart:35` `vGapxl_`; `home_screen.dart:1130` |
| F11 | Kontrol: `AppA11y` + `AppNavigation` | Doğru | K `app_dimens.dart:85–88`, `:121–126` |
| F12 | Üretim renkleri #121212, #F5F5F1, #CCFF00, #171C03, #526900, #FFFFFF | Doğru | K `app_colors.dart:8`, `:13`, `:32–33`, `:51`, `:65` |
| F13 | 14,845:1 ve 6,214:1 | Doğru | Hesap (aşağıda) |
| F14 | `labelSmall` 11,5 | Doğru | K `app_theme.dart:84–86` |
| F15 | Bileşen eşleme: `workout_ui.dart`, `app_state_views.dart`, `sync_status_tile.dart`, `progress_indicators.dart`, `warm_nutrition_summary.dart`, `_SetRow`/`_NumCell`/`_RpeCell`, `RestBanner`, `session_rest_sound.dart`, `SheetHeader`, `sheetBottomInset`, `insights/`, `assistant/`, fl_chart 0.70.2, `AppShell` | Doğru | K hepsi var (`SheetHeader` `shared/widgets/app_state_views.dart:209`; fl_chart `pubspec.lock:523`) |
| F16 | `fillMissing` + `_shownValues` (`:247`) | Doğru | K `active_session_screen.dart:247–252` |
| F17 | `_ticker` her saniye `setState` (`:127`) | Doğru | K `:127–129` |
| F18 | Odak kenarı 2 | Doğru | K `app_theme.dart:251–253` |

### 08 — Fırsatlar P01–P12

| # | İddia | Hüküm | Kanıt |
|---|---|---|---|
| G01 | P01: 38×34, 36×30, 30×32 | Doğru | K `active_session_widgets.dart:651–656`, `:1186–1192`, `:1234–1240` |
| G02 | P02: %40 alfa; 2,134 / 1,717 | Doğru | K `:1338–1339` + hesap |
| G03 | P02: "öneri ile girilmiş değer ayrımı yalnız görünüşe kalabilir" | Kısmen | K `:559–633` `_ActiveSetAssist` aktif sette öneriyi tam renkte metinle gösteriyor (`l.asSuggestHint`). Soluk olan yalnız alan içi ipucu; tamamlanmış/sonraki setlerde açıklama satırı yok |
| G04 | P03: Özel onay ve alanlarda semantik ad eksik | Doğru | K Q03 satırları |
| G05 | P04: 393×852 görüntüde ana düğme ekranın altında | Doğru | G `dark-tr-home.png` |
| G06 | P05: `nutrition_screen:237` → Ayarlar; editör Profil'de | Doğru | K A32–A34 |
| G07 | P06: Beslenme ayrı tema; özel `InkWell`'ler tema hedefini atlıyor | Doğru | K |
| G08 | P07: Çıkış onayı taslağı temizliyor (`:980–988`) | Doğru | K |
| G09 | P08: Son/sık besin, hızlı ekle, art arda kayıt, kopyalama var | Doğru | K |
| G10 | P09: İlerleme dalı `BodyMetricsScreen` | Doğru | K `app_router.dart:176` |
| G11 | P10: Kayıtsız günde segment, kavisli çizgi | Doğru | K `workout_activity_card.dart:54–64`, `:174` |
| G12 | P11: Azaltılmış hareket "bazı yüzeylerde" var; skeleton/halka/RPE'de yok | Kısmen | Doğru ama eksik: `shared/widgets/exercise_demo.dart:142` de tercihe uyuyor. Uymayan, listede olmayan yerler: `home_screen.dart:953–962`, `:1308–1318`; `active_session_widgets.dart:40–49` |
| G13 | P12: Recall kuralları kodda | Doğru | K |

### 09 — Yol haritası

| # | İddia | Hüküm | Kanıt |
|---|---|---|---|
| H01 | İlk dilim dosyaları (`active_session_widgets`, `home_screen`, `nutrition_screen`, Profil) var | Doğru | K |
| H02 | `CODE_REVIEW_REPORT.md` önceki kişisel dosya | Doğru | `git status`: izlenmiyor |
| H03 | "Ortak dosyalarda yalnız araştırma paketi bağlantısı eklenmiştir" | Kısmen | Bağlantı yalnız `collab/aktif-isler.md:36`'da (bu dosya `.gitignore:54` ile dışlanıyor). `PROJECT_STATE.md`, `NEXT_TASKS.md`, `README.md`'de **yok** |

### 10 — Doğrulama stratejisi (test iddiaları)

| # | İddia | Hüküm | Kanıt |
|---|---|---|---|
| I01 | `neon_design_test` + `warm_nutrition_test` 6/6, 76 görüntü | Doğru | K log `:162–168`; neon testi 1 `testWidgets` × 4 senaryo + warm testi 2 |
| I02 | 393 koyu TR / açık EN; 320 TR %130 / EN %160 | Doğru | K `neon_design_test.dart:30–35` |
| I03 | Render logunda SVG `<style/>` uyarısı var | Doğru | K log `:164` |
| I04 | `active_session_draft_test.dart:20` taslağı diskten yeniden okuyor | Doğru | K `:20–24` |
| I05 | `neon_design_test.dart:33` dar ekran / büyük metin | Doğru | K |
| I06 | `velocity_navigation_test.dart:75` gezinme semantiği | Doğru | K `ensureSemantics` |
| I07 | `warm_nutrition_test.dart:125` enerji özeti semantiği | Doğru | K |
| I08 | `active_session_screen.dart:371` 500 ms penceresi | Doğru | K `:40` `_draftSaveDelay = 500 ms` |
| I09 | `step_source.dart:25` iOS izni kesin değil | Doğru | K |
| I10 | TalkBack/VoiceOver yapılmadı; simülatörde eski build 1 açıldı | Doğrulanamadı | Süreç iddiası; kodla kontrol edilemez |
| I11 | "Kısmi widget testleri var" (erişilebilirlik) | Doğru | K I05–I07; `meetsGuideline` 0 eşleşme |

### workstreams/technical-accessibility.md

| # | İddia | Hüküm | Kanıt |
|---|---|---|---|
| J01 | Flutter 3.41.1, Dart 3.11.0 | Doğru | `/opt/homebrew/share/flutter/bin/cache/flutter.version.json` |
| J02 | Riverpod 2.6.1 (`:606`), Drift 2.28.2 (`:428`), GoRouter 14.8.1 (`:720`), fl_chart 0.70.2 (`:516`) | Doğru | K `pubspec.lock` paket başlığı satırları; sürümler `:613`, `:435`, `:727`, `:523` |
| J03 | Şema 17 (`app_database.dart:124`) | Doğru | K |
| J04 | minSdk 26 (`android/app/build.gradle.kts:31`) | Doğru | K |
| J05 | Material 3 / font / semantik uzantı (`app_theme:27`, `:35`; `app_colors:128`) | Doğru | K |
| J06 | Token satırları `app_dimens:7/43/64/75/85` | Doğru | K |
| J07 | Yerelleştirme `app.dart:143` | Doğru | K `:143–145` |
| J08 | Q01: ✓ 38×34 `:1234`, ± 36×30 `:651`, set türü 30×32 `:1186` | Doğru | K |
| J09 | Q01: Tema minimumu özel kutuları büyütmüyor | Doğru | K çıplak `InkWell` |
| J10 | Q02: `_hintStyle` %40 `:1338`; dolgu `app_theme:236` | Doğru | K `:236` `fillColor: surfaceContainerHigh` |
| J11 | Q02: 2,134 / 1,717 | Doğru | Hesap |
| J12 | Q02: "Önceki kayıttan gelen öneri … soluk" | Kısmen | G03 ile aynı gerekçe |
| J13 | Q03: Tamamla ikonunda ad yok `:1241` | Doğru | K `FitPackIcon.material(Icons.check_rounded)` `semanticLabel` almıyor |
| J14 | Q03: Sayısal alanlarda `labelText` yok `:1287`, `:1361` | Doğru | K |
| J15 | Q03: `FitPackIcon` SVG dalı adsız ikonu semantikten çıkarıyor `:92` | Doğru | K `excludeFromSemantics: semanticLabel == null` |
| J16 | Q04: Velocity `:33`, sıcak halka `:370` azaltılmış hareketi destekliyor | Doğru | K |
| J17 | Q04: Skeleton `repeat()` `:150` | Doğru | K `app_state_views.dart:150–152` |
| J18 | Q04: CalorieRing 400 ms `:67` | Doğru | K `progress_indicators.dart:67–68` `AppDuration.slow` |
| J19 | Q04: RPE 150 ms `:171` | Doğru | K `rpe_picker_sheet.dart:171` (sabit sayı, `AppDuration.fast` değil) |
| J20 | Q04: Hareket envanterinin kapsamı | Kısmen | `exercise_demo.dart:142` atlanmış; G12'deki 3 yer eksik |
| J21 | Q05: Gezinme %130 üstünde etiketleri saklıyor | Kısmen | K `velocity_navigation.dart:30–32`: `> 1,3` **veya** (genişlik < 360 **ve** > 1,15) |
| J22 | Q05: Erişilebilir ad + tooltip korunuyor `:60` | Doğru | K `:60–67` |
| J23 | Q05: RPE sekiz seçenek tek satırda | Doğru | K `rpe_picker_sheet.dart:158–161`; `rpe_scale.dart:11` |
| J24 | Q05: Panel kenarları 20'şer `:69` | Kısmen | Değer doğru (`rpe_picker_sheet.dart:69–70` `AppSpacing.xl`); atıf metinde `rpe_scale.dart`'tan sonra geldiği için o dosyaya bağlanıyor (orada 41 satır var) |
| J25 | Q05: (320 − 40) / 8 = 35 | Doğru | Hesap; şerit `Expanded` |
| J26 | Q06: 500 ms debounce, yaşam döngüsü yazımı, bitiş anı | Doğru | K `:152–160`, `:377–381`, `:399–403` |
| J27 | Q06: `restorationScopeId` / `Restorable` yok | Doğru | `grep` `lib/` → 0 |
| J28 | Q07: Swift `:128`, `:115`, `:153` | Doğru | K `ActionRow`, `lineLimit(1)`, `minimumScaleFactor(0.8)` |
| J29 | Q07: Köprü hata verse de seans sürüyor | Doğru | K `core/live_activity/workout_live_activity.dart:190–193` |
| J30 | Q08: Test satırları `neon:33`, `velocity:75`, `warm:125` | Doğru | K |
| J31 | Q08: `meetsGuideline` yok | Doğru | `grep` `test/` → 0 |
| J32 | Tablo: #A5A5A0 / #282827 = 5,966 | Doğru | Hesap |
| J33 | #171C03 / #CCFF00 = 14,845 | Doğru | Hesap |
| J34 | #526900 / #FFFFFF = 6,214 | Doğru | Hesap |
| J35 | #B84300 / #FFFFFF = 5,467 | Doğru | Hesap |
| J36 | #B6B09F / #302D24 = 6,354 | Doğru | Hesap; `nutrition_theme.dart:42`, `:47` |
| J37 | #696656 / #F2ECE0 = 4,910 | Doğru | Hesap; `nutrition_theme.dart:43`, `:48` |
| J38 | Korunacak: bayat set kimliği reddediliyor `:190` | Doğru | K `:191–199` |
| J39 | Kayıt başarısız olursa taslak kalıyor `:913` | Doğru | K `:913–936` |
| J40 | Gün dönümü bekçisi `app.dart:174`; sekmeler canlı `router:137` | Doğru | K |
| J41 | `SyncStatusTile` yerel / bekleyen / yedek ayrımı `:35` | Doğru | K `:35–60` `SyncState.synced/pending` |
| J42 | `step_source:25` | Doğru | K |
| J43 | Open Food Facts barkod 6 sn, arama 8 sn; boş/null dönüş | Doğru | K `data/services/openfoodfacts_service.dart:47–48`, `:92–93` |

### workstreams/behavioral.md

| # | İddia | Hüküm | Kanıt |
|---|---|---|---|
| K01 | Program önerisi + "kendim kuracağım" | Doğru | K `onboarding/program_recommendation.dart`; `onboarding_screen.dart:25`, `:253` |
| K02 | İlk 14 gün üç adım, bitince kaybolur | Doğru | K `first_week.dart:14`, `:29`; `home_screen.dart:459`, `:487–501` |
| K03 | Tek ✓ + otomatik mola | Doğru | K `active_session_screen.dart:598–616` |
| K04 | İlerleme mantığı, onaysız değişmez | Doğru | K `progression.dart`; `active_session_screen.dart:456–465` |
| K05 | İlk kez yapılan harekette sahte rekor yok | Doğru | K `active_session_screen.dart:580` |
| K06 | Haftalık ritim | Doğru | K `streak_calc.dart:6`, `rhythm_state.dart:101` |
| K07 | Haftalık değerlendirme | Doğru | K `insights/weekly_review_screen.dart` |
| K08 | Alışılmış öğün / son porsiyon / kopyalama | Doğru | K `nutrition_habit_widgets.dart:148`; `add_food_sheet.dart:516–524` |
| K09 | Gün tamam işareti | Doğru | K `day_complete.dart:11` |
| K10 | `today_lines` / `week_ready` | Doğru | K |
| K11 | Asistan hazır soru + düzeltme `:250`, `:559` | Doğru | K |
| K12 | Recall: 2 gün ara, 2/gün, 6/hafta, 22–08, 3 → 14 | Doğru | K `recall_reminders.dart:19–31` |
| K13 | Planlı gün ortak sınıra tabi `recall_missed_day:99` | Doğru | K `:97–101` `accepted` / `fits` |
| K14 | İlk hafta: 2. gün 19:00, bir kez | Doğru | K `recall_first_week.dart:18` `firstWeekHour = 19` |
| K15 | `recall_offer.dart:24` onboarding'de de teklif | Doğru | K `:24–28`, `:81` |
| K16 | `:103–110` mola izni varsa sormadan açıyor | Kısmen | Davranış doğru (K `:21`, `:86`); `:103–110` UI kodu |
| K17 | `app_tr.arb:578–579` "Yarın da olur" | Doğru | K `:579` |
| K18 | `homeRhythmRestartSub` geçen haftayı belirtiyor | Doğru | K `app_tr.arb:854` |

### workstreams/competitive-sources.md

| # | İddia | Hüküm | Kanıt |
|---|---|---|---|
| L01 | Haftalık seri, program önerisi, ana kart, dönüş, kopyalama, trend, yorum zaten var | Doğru | K B02 |
| L02 | Home sınıfları `home_screen.dart`'ta doğrulandı | Doğru | K |

## Kontrast oranlarının yeniden hesabı

Yöntem: `son = alfa × ön + (1 − alfa) × arka` (sRGB kanal) → doğrusallaştırma (`c ≤ 0,04045 ? c/12,92 : ((c+0,055)/1,055)^2,4`) → `L = 0,2126R + 0,7152G + 0,0722B` → `(L1 + 0,05) / (L2 + 0,05)`. Betik: `/private/tmp/claude-501/-Users-sametorhan/904bd870-cf84-4698-938c-5a467cf919e7/scratchpad/contrast.py`. Eşik S: WCAG (Web Content Accessibility Guidelines; Web İçeriği Erişilebilirlik Kılavuzu) 1.4.3 normal metin 4,5:1, 1.4.11 metin dışı 3:1.

| Kullanım (kaynak) | Ön | Alfa | Arka (opak) | Birleşik | Oran | Durum |
|---|---|---:|---|---|---:|---|
| Q02 koyu ipucu (`widgets:1338`; dolgu `app_theme:236`) | #A5A5A0 | 0,40 | #282827 | #5A5A57 | **2,134** | Rapor doğru; eşik altı |
| Q02 açık ipucu | #626459 | 0,40 | #E8E9DF | #B2B4A9 | **1,717** | Rapor doğru; eşik altı |
| Tablo satırları 3–8 | (rapordaki gibi) | 1 | | | 5,966 · 14,845 · 6,214 · 5,467 · 6,354 · 4,910 | 6/6 aynen tuttu |
| **YENİ** ÖNCEKİ sütunu, koyu (`widgets:1218–1223`; kart `AppGlass.darkFillSolid`) | #A5A5A0 | 0,85 | #212121 | #91918D | 5,102 | Geçiyor |
| **YENİ** ÖNCEKİ sütunu, açık (kart #FFFFFF) | #626459 | 0,85 | #FFFFFF | #7A7B72 | **4,278** | **Eşik altı** (bodySmall 12,5 px) |
| **YENİ** Öneri yardım satırı, koyu (`widgets:592–596`) | #CCFF00 | 1 | #212121 | | 13,703 | Geçiyor |
| **YENİ** Öneri yardım satırı, açık | #526900 | 1 | #FFFFFF | | 6,214 | Geçiyor |
| **YENİ** Mola −15s/+15s/Atla, açık (`widgets:213–222`; zemin onPrimary %18 üstü #526900) | #FFFFFF | 1 | #71842E | | **4,164** | **Eşik altı** (labelMedium 12,5 px kalın; "büyük metin" sayılmıyor) |
| **YENİ** Mola düğmeleri, koyu (zemin #ABD601) | #171C03 | 1 | #ABD601 | | 10,279 | Geçiyor |
| **YENİ** Mola "Dinlenme" etiketi, açık (onPrimary %80) | #FFFFFF | 0,80 | #526900 | #DCE1CC | 4,645 | Sınırda geçiyor |
| **YENİ** Kilo grafiği ipucu, koyu (`body_metrics_screen.dart:392–399`; fl_chart 0.70.2 varsayılan `Colors.blueGrey.darken(15)` = #526A76) | #171C03 | 1 | #526A76 | | **3,059** | **Eşik altı** |
| **YENİ** Kilo grafiği ipucu, açık | #FFFFFF | 1 | #526A76 | | 5,703 | Geçiyor |
| **YENİ** Tamamlanmamış ✓ ikonu (metin dışı), koyu: ikon / zemin (onSurface %8 üstü kart = #323232) | #A5A5A0 | | #323232 | | 5,188 | Geçiyor; düğme zemini / kart ayrımı ise 1,255 (zayıf sınır) |
| **YENİ** ± ikonu, açık (primary %10 zemin) | #526900 | | #EEF0E6 | | 5,393 | Geçiyor |

4,5:1 için gereken en düşük ipucu alfası: koyuda **0,82**, açıkta **0,96**. Açık temada ipucunu ayırt etmek için yalnız alfayı azaltmak yetmez; ayrı etiket ya da stil gerekir (P02 önerisiyle uyumlu).

## Paketin kaçırdığı bulgular

Altı dosya tarandı: `home_screen.dart`, `active_session_screen.dart`, `active_session_widgets.dart`, `nutrition_screen.dart`, `add_food_sheet.dart`, `body_metrics_screen.dart`. Ölçüler koddan yaklaşık hesap (K).

### 48 mantıksal pikselin altındaki dokunma hedefleri (raporda olmayanlar)

| # | Yer | Yaklaşık hedef | Not |
|---|---|---|---|
| M1 | `workout/active_session_widgets.dart:204–226` `_MiniBtn` (−15s / +15s / Atla) | ~31 px yükseklik | Molada en sık kullanılan kontrol; dolgu 7 + labelMedium |
| M2 | `active_session_widgets.dart:527–533` `_RestChip` | ~20 px | Dikey dolgu 2 |
| M3 | `active_session_widgets.dart:607–623` adım etiketi ("2,5 kg") | ~25 px | Dolgu 4 |
| M4 | `active_session_widgets.dart:919–935` `_RpeHeader` (RPE ?) | ~16 px | Bilgi ipucu |
| M5 | `active_session_widgets.dart:1311–1320` `_RpeCell` | ~38 × ~40 | `isDense`, dikey 8 |
| M6 | `active_session_widgets.dart:1287–1292` `_NumCell` kg/tekrar alanı | ~40 px yükseklik | Sayı girişinin dokunma alanı |
| M7 | `active_session_widgets.dart:78–82` `SessionDateBar` | ~36 px yükseklik | Tam genişlik ama alçak |
| M8 | `home/home_screen.dart:1354–1356` `_MiniAction` (su ekle) | 34 px | `height: 34` sabit |
| M9 | `nutrition/add_food_sheet.dart:643–672` `_MealPicker` | ~32 px | Öğün değiştirme |
| M10 | `add_food_sheet.dart:1285–1290` porsiyon/g `SegmentedButton` | 40 px | `compact` + `shrinkWrap` 48'i kırıyor |

### Eksik semantik

| # | Yer | Sorun |
|---|---|---|
| S1 | `add_food_sheet.dart:1312–1315`, `:1348–1351` miktar −/+ `IconButton.filledTonal` | `tooltip` yok. `remove_rounded` Material ikonu adsız, `add_rounded` SVG semantikten çıkarılıyor → iki **adsız düğme** |
| S2 | `add_food_sheet.dart:1321–1336` miktar `TextField` | `labelText` yok; okuyucu yalnız son eki okuyor |
| S3 | `home_screen.dart:1267–1268` su sıfırlama | Yalnız uzun basmayla yapılıyor; görünür ya da semantik alternatifi yok |
| S4 | `body_metrics/body_metrics_screen.dart:318–430` kilo grafiği | Metin alternatifi veya `Semantics` özeti yok (07'deki `AccessibleChart` önerisini destekliyor) |
| S5 | `active_session_widgets.dart:1186–1212` set türü düğmesi | Eylem adı ("set türünü değiştir") yok; okuyucu yalnız numarayı duyuyor |
| S6 | `add_food_sheet.dart:678–727` "eklendi" şeridi | `liveRegion` yok; ekran okuyucu eklemeyi duyurmayabilir (H) |

### Hatayı gizleyen ya da 0 / varsayılana çeviren durumlar

| # | Yer | Davranış |
|---|---|---|
| E1 | `nutrition_screen.dart:242` | U07 (raporda var) |
| E2 | `nutrition_screen.dart:232–240` | Profil hatasında `maybeWhen orElse` → **sonsuz iskelet** |
| E3 | `home_screen.dart:194` `activeDraftProvider.valueOrNull` | Taslak okuma hatasında "Devam et" kartı kayboluyor, yerine yeni Başlat sunuluyor. U01/U02 riskini artırıyor |
| E4 | `home_screen.dart:878–881`, `:979–991` | Seri / son 30 gün hatasında 0 seri ve 0 değer gösteriliyor ("0" ile "bilinmiyor" karışıyor) |
| E5 | `home_screen.dart:1261` | Su hatasında 0 ml |
| E6 | `home_screen.dart:1103–1104`; `nutrition_screen.dart:235–236`; `home_screen.dart:1260` | Profil yoksa 2200 kcal / 180 g / 2500 ml varsayılan hedef gerçekmiş gibi çiziliyor |
| E7 | `add_food_sheet.dart:117–129` `_load` | try/catch yok → hata olursa **sonsuz dönen gösterge** (`:410–411`) |
| E8 | `body_metrics_screen.dart:196` | Fotoğraf sayısı okunamazsa "fotoğraf yok" metni çıkıyor |
| E9 | `body_metrics_screen.dart:167–171` | Ölçüm silme/gizleme hatası yakalanmıyor |
| E10 | `active_session_screen.dart:500–513` | Resume yükleme istisnası yakalanmıyor → sonsuz dönen gösterge (A21 ile aynı kök) |
| E11 | `home_screen.dart:1123–1124` | İçgörü hatası "veri yok" ile aynı görünüyor (düşük önem) |

### l10n'da olmayan sabit metin ve biçim

- `active_session_widgets.dart:192`, `:194`: `'−15s'`, `'+15s'`. `:926` `'RPE'` kısaltma olduğu için kabul edilebilir.
- `'kcal'` / `'g'` birimleri: `add_food_sheet.dart:172`, `:264`, `:1014`, `:1054–1055`, `:1214`, `:1278`, `:1293`, `:1335`, `:1365`, `:1398`; `nutrition_screen.dart:496`, `:652`, `:662`.
- **Yerel biçim atlanıyor:** `body_metrics_screen.dart:396` (grafik ipucu) ve `:582` (fark) `toStringAsFixed`. Türkçede ondalık virgül yerine "84.5" çıkıyor.
- `active_session_screen.dart:519` `'Workout'` yedeği (yalnız ekran ağaçtan ayrılmışsa; düşük önem).

### Sabit renk

- Altı dosyada `Color(0x…)` **0** eşleşme; yalnız `Colors.transparent` (`add_food_sheet.dart:955`, `body_metrics_screen.dart:409`).
- `lib/` genelinde `core/theme/` dışında `Color(0x…)` yok. `Colors.black/white` yalnız kamera ve tam ekran fotoğraf yüzeylerinde (`nutrition/barcode_scan_screen.dart:62–158`, `progress_photos_screen.dart:204–338`) ve `core/onboarding/first_run_hints.dart:194`, `:263` örtüsünde. Bu bağlamlarda makul.
- Tokenı atlayan asıl desen renk değil, **sayı**: `150 ms` (`rpe_picker_sheet.dart:172`), `height: 34`, `bottom: 26`, `minHeight: 6`.

### Azaltılmış hareket (Q04/P11'e ek)

Sistem tercihini okumadan animasyon yapan, raporda olmayan yerler:

- `home_screen.dart:953–962` (ritim çubuğu)
- `home_screen.dart:1308–1318` (su çubuğu)
- `active_session_widgets.dart:40–49` (`SessionProgressBar`)

## Pakete etkisi

**Güçlenen iddialar**

- U03, U04/Q01/P01, U07, Q02 sayıları, 39 rota, 04'teki bütün dokunuş sayıları ve 07'nin token envanteri kodla birebir doğrulandı. Ölçülerin hiçbiri yuvarlanmamış ya da uydurulmamış.
- 05/P04'ün "eylem ekranın altında" iddiası fixture görüntüsüyle (G) de doğrulandı.
- E3 (taslak hatasında Devam kartının kaybolması), U01/U02'nin önceliğini ayrıca destekliyor.

**Düzeltilmesi gerekenler**

1. **02 giriş paragrafı (A13):** "rutin/seans akışını kapsar" ifadesi yanlış. Önerilen metin: "Render testleri aktif seans ekranını açmaz; set satırı bulguları (U01, U04, Q01–Q03) yalnız kaynak kanıtına dayanır." 10 §1'e "aktif seans görüntüsü yok" sınırı eklenmeli.
2. **Q02 / P02 / 07 (G03, J12):** "öneri soluk" yerine şu yazılmalı: "aktif sette öneri açıklama satırında tam kontrastla yazılıyor; alan içi ipucu %40 alfa ile koyuda 2,134:1, açıkta 1,717:1". Sonraki/tamamlanmış setlerde açıklama satırı olmadığı ayrıca belirtilmeli.
3. **Q05 (J21):** Etiket gizleme koşulu tam yazılmalı (`> 1,3` veya `< 360 genişlik ve > 1,15`).
4. **Q04/P11 (G12, J20):** Envantere `exercise_demo.dart:142` (uyuyor) ve tercihe uymayan 3 animasyon eklenmeli.
5. **09 (H03):** "Ortak dosyalara bağlantı eklendi" cümlesi "yalnız collab defterine (gitignore'lu) eklendi" diye düzeltilmeli.
6. **Satır kaymaları** (A10, A22, A29, C24, D01, J24, K16): `widgets:1043` → `:598–616` / `:758`; `:1008` → `:1006`; `:490` → `:493`; `:620` → `:616`; `app_colors:6–12` → `:8–13`, `:31–38`; `:69` → `rpe_picker_sheet.dart:69`; `recall_offer:103–110` → `:86`.

**İlk dilime (09) eklenmesi önerilenler (K)**

- M1 mola düğmeleri (aynı dosya, aynı kullanım sıklığı).
- Açık temada ÖNCEKİ sütunu 4,278 ve mola düğmeleri 4,164 kontrastı.
- S1/S2 yemek paneli adsız ±.
- E2/E7/E10 sonsuz iskelet ya da dönen gösterge (her biri birkaç satırlık hata durumu).

Bunlar U03/U04 ile aynı "ucuz, şemasız, düşük risk" sınıfında.

**Hipotez olarak kalanlar (H):** Dokunma hedefi ölçüleri yaklaşık; kesin vuruş alanı için widget testinde `tester.getSize` ya da Android erişilebilirlik denetimiyle ölçülmeli. S6 (`liveRegion`) gerçek okuyucuyla doğrulanmalı.
