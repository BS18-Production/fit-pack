# A6 — Erişilebilirlik uzmanı + mobil mühendislik lideri incelemesi

18 Ekim 2026 · kaynak `main` = `07104d1` · üretim kodu değişmedi.
İki bağımsız bakış: (1) erişilebilirlik uzmanı, (2) mobil mühendislik lideri.
Kanıt sınıfları BRIEF'teki gibi; ek olarak **G\*** = Flutter widget testi
ortamında gözlem (gerçek uygulama mantığı + gerçek tema/font, ama gerçek cihaz
ve gerçek ekran okuyucu değil). Kanıt dosyaları: `review/A6_visuals/`.

## Karar özeti

1. **En büyük açık paketin hiç görmediği ekranda:** Araştırmanın 76 render'ı
   aktif seansı içermiyor (`neon_design_test.dart` rota listesinde yok). Aktif
   seansı aynı düzenekte render ettim: **320 genişlik + yazı ×1,6'da set tablosu
   kullanılamaz** — kg/tekrar değerleri "7(" / "1(" diye kesiliyor, mola şeridinde
   "Rest" ve "1:30" harf harf dikey kırılıyor, başlıklar "SE T" / "REP S",
   `_RpeHeader` satırı 5,9 px taşıyor (`active_session_widgets.dart:922`). **G\***
2. **Flutter erişilebilirlik kılavuz testleri (ilk kez) çalıştırıldı:** Ana sayfa
   ve Beslenme'nin ilk görünümü dört kılavuzu da geçiyor; **aktif seans dördünden
   de kalıyor** (≥48 hedef: 24–28 küçük düğüm; adsız düğüm: 3 adet ✓; kontrast:
   RPE "–" 1,48–1,88:1; açık temada mola düğmeleri 3,38–4,16:1). İlerleme ve Yemek
   Ekle panelinde daha küçük ihlaller var. **G\***
3. **Set satırında 48×48 hedef, mevcut sütun yapısıyla 320'de matematiksel olarak
   sığmıyor:** sabit sütunlar 172 px; set/RPE/✓ 48'e çıkınca kg+tekrar alanlarına
   ~29'ar px kalır. "Önceki" sütunu satırdan çıkmadan P01 yapılamaz. 12'deki K4
   kaygısı doğru, ama seçenek "± nerede" değil, **sütun düzeni**. **K + hesap**
4. **Mola sayacı her saniye anons etmiyor — hiç anons etmiyor.** `lib/` içinde
   `SemanticsService` ve `liveRegion` sıfır. 12'nin "her saniye anons" riski
   kodda yok; gerçek açık ekran okuyucu kullanıcısının bitişi duyamaması. **K**
5. **P02 yarı yapılmış:** Aktif sette "✓ ile 70 kg × 10 kaydedilir" etiketi zaten
   var (`active_session_widgets.dart:559–596`, ARB `asSuggestHint`). Eksik:
   alan ipuçları %40 (Q02), ekran okuyucuda öneri "70" ile girilmiş "70" aynı
   okunuyor. **K + G\***
6. **P07 için ara adım öneriyorum (P07a):** "Küçült = taslağı silmeden kapat"
   altyapısı (taslak, resume rotası, ana sayfa devam kartı) zaten var; tam
   controller taşıması (P07b) ~2–4 kod oturumu + 2–3 akşam cihaz turu ister ve
   önce kullanım kanıtı gerekir. **K + H**
7. **Tasarım sistemi beklenenden sağlam:** tema dışında `Color(0x` = **0**,
   `BorderRadius.circular(sayı)` = 2. Sızıntı opaklıkta: tema dışında 116
   `withValues(alpha:)`, **32 farklı alfa değeri** (öneri metnindeki 0.4 dahil)
   ve 84 sabit `SizedBox` genişliği/yüksekliği — büyük yazı kırılmasının kaynağı. **K**
8. **Tahmin birimi:** Faz 1 kodu 1–2 AI oturumu; darboğaz Samet'in iki platform
   turu (2 akşam) + en az bir düzeltme turu. Takvimde 4–7 gün gerçekçi. Kanıt:
   benzer ölçekteki Canlı Etkinlik işi 08→12 Ekim, cihazda bulunan 2 hata ile. **K + H**

## Yöntem ve sınırlar

**Yapılan:**
- `lib/` (212 Dart dosyası, üretilmiş/l10n hariç ~48 200 satır) üzerinde
  semantik/hareket/ölçek API'lerinin ve sabit tasarım değerlerinin sayımı
  (Python betiği, salt okunur).
- `active_session_screen.dart` (1131 satır) tamamı; `active_session_widgets.dart`
  ilgili bölümleri; `workout_live_activity.dart`, `session_rest_sound.dart`,
  `app_router.dart`, `app_shell.dart`, yerel köprüler (`AppDelegate.swift`,
  `WorkoutLiveActivityIntents.swift`, `WorkoutNotification.kt`).
- Scratch `git worktree` (`07104d1`, commit'siz, iş sonunda kaldırıldı) içinde
  geçici test: gerçek router + gerçek tema + yerel fontlar + tasarım fikstürü;
  `androidTapTargetGuideline`, `iOSTapTargetGuideline`,
  `labeledTapTargetGuideline`, `textContrastGuideline` ve semantik ağaç dökümü.
  Senaryolar: koyu-TR 393/×1,0 · açık-EN 393/×1,0 · koyu-EN 320/×1,6. Ekranlar:
  `/home`, `/nutrition`, `/progress`, Yemek Ekle paneli, aktif seans (rutin 1),
  aktif seans + mola. Test kaynağı ve ham çıktı: `A6_visuals/a11y_audit_test.dart.txt`,
  `A6_visuals/a11y_guideline_output.txt`; seans görüntüleri `A6_visuals/*.png`.
- Mevcut testler aynı worktree'de: `velocity_navigation_test`,
  `warm_nutrition_test`, `neon_design_test`, `rpe_picker_test`,
  `active_session_draft_test` → **28/28 geçti** (bu turda yeniden çalıştırıldı).
- Paketin `visuals/current/large-en-*` ve `narrow-tr-*` görüntüleri gözle tarandı.

**Yapılamayan / sınırlar:**
- Gerçek cihaz, gerçek TalkBack/VoiceOver, donanım klavyesi, Switch Access yok
  (BRIEF kuralı 2). Okuyucunun **ne söyleyeceği** H; semantik ağaçta **ne
  olduğu** G\*.
- Kılavuz testleri yalnız ekrana çizilmiş kısmı denetler; ana sayfanın kaydırma
  altı denetlenmedi. `textContrastGuideline` metin alanı ipuçlarını
  ölçmüyor (öneri ipucu %40 burada görünmedi; Q02 hesabı geçerli kalır).
- Test fontunda "✓" karakteri "≡" gibi çizildi; cihazda sistem yedek fontu
  muhtemelen doğru çizer (H).
- `TextScaler.linear(1.6)` platformun doğrusal olmayan ölçeklemesi değildir;
  iOS en büyük erişilebilirlik boyutu daha sert olabilir.

---

## Bölüm 1 — Erişilebilirlik uzmanı

### 1.1 Semantik API kullanımının genel resmi (K)

| API | Kullanım | Dosya |
|---|---:|---:|
| `Semantics(` | 13 | 9 |
| `ExcludeSemantics` / `excludeSemantics:` | 3 / 2 | 2 / 2 |
| `MergeSemantics` | 0 | 0 |
| `semanticLabel` / `semanticsLabel` | 8 / 4 | 2 / 4 |
| `tooltip:` | 54 | 23 |
| `SemanticsService` (duyuru) / `liveRegion` | **0 / 0** | 0 |
| `MediaQuery.disableAnimationsOf` | 4 | 3 |
| `IconButton` toplam / tooltip'siz | 54 / **9** | — |

Tooltip'siz `IconButton`'lar (K): `activity_calendar.dart:75,89` (ay ileri/geri),
`add_food_sheet.dart:1312,1348` (porsiyon −/+), `foods_screen.dart:222`,
`exercise_library_screen.dart:190`, `routine_builder_screen.dart:491,660,671`.
**Aktif seans dosyalarında (`active_session_screen.dart` + `_widgets.dart`, 2502
satır) tek bir `Semantics(` yok**; tek semantik ad kupa ikonu
(`active_session_widgets.dart:1206`).

### 1.2 Akış bazında adsız / zayıf adlı kontroller

Semantik ağaç dökümünden (G\*) ve koddan (K). "Ad" = label/value/tooltip/hint.

| Akış | Kontrol | Ölçülen hedef | Ekran okuyucuya giden | Sorun | Kanıt |
|---|---|---|---|---|---|
| Aktif seans | Seti tamamla ✓ | 38×34 | **adsız**, durum (tamamlandı mı) yok | Hangi set, ne yapar, yapıldı mı bilinmez | G\*, K `:1234–1249` |
| Aktif seans | Set no / tip rozeti | 30×32 | "1" | Dokununca tip değiştiği (ısınma/drop) söylenmez | G\*, K `:1186` |
| Aktif seans | kg / tekrar alanı | 75×40 (393), **38×54** (320/×1,6) | boşken öneri "70", doluyken değer "70" | Birim, hareket, set yok; öneri ile girilmiş değer **aynı sayı** olarak okunur | G\*, K `:1257–1300` |
| Aktif seans | RPE hücresi | 38×36 | "–" | "RPE" adı yok; RPE (Rating of Perceived Exertion; algılanan zorluk) | G\*, K `:1303` |
| Aktif seans | Kilo ± | 36×30 | yalnız tooltip "Kiloyu 2,5 kg artır" | Ad iyi, hedef küçük | G\*, K `:636–664` |
| Aktif seans | Dinlenme çipi | 59×21 | "1:30 · Dinlenme süresini değiştir" | Hedef çok kısa | G\* |
| Aktif seans | RPE başlığı (?) | 44×17 | "RPE" | Hedef çok kısa; 320/×1,6'da taşıyor | G\*, K `:913–922` |
| Mola şeridi | −15s / +15s / Atla | 49×31, 46×31 | "−15s" | Hedef kısa; "eksi on beş s" okunabilir (H) | G\*, K `:204–227` |
| İlerleme | Ay ileri/geri | 40×40 | **adsız** | Tooltip yok | G\*, K `activity_calendar.dart:75` |
| İlerleme | Gün hücresi | 45×45 | yalnız "12" | Dört halka (kcal/protein/antrenman/su) ve "gün tamam" işareti okunmaz | G\*, K `:292–319` |
| Yemek Ekle | Öğün seçici | 92×32 | "Öğle · Öğünü değiştir" | Hedef kısa | G\* |
| Yemek Ekle (porsiyon) | −/+ | tema 48 | **adsız** | Tooltip yok | K `add_food_sheet.dart:1312,1348` |
| Ana sayfa | Su kartı sıfırlama | — | yalnız uzun basma | Keşfedilemez, odaklanamaz | K `home_screen.dart:1267` |
| Beslenme | Öğe sil | 40×35 | yalnız tooltip "Sil" | Ad var, hedef küçük | G\* |

Ana sayfa (ilk görünüm), Beslenme (ilk görünüm), Vücut ölçümleri listesindeki
sil/gizle düğmesi (`body_metrics_screen.dart:628`, tooltip var) iyi durumda.

### 1.3 Kılavuz testi sonuçları (G\*)

| Ekran | 48 hedef (Android) | 44 hedef (iOS) | Etiketli hedef | Metin kontrastı |
|---|---|---|---|---|
| `/home` (3 senaryo) | Geçti | Geçti | Geçti | Geçti |
| `/nutrition` (3 senaryo) | Geçti | Geçti | Geçti | Geçti |
| `/progress` | Kaldı (19 küçük: takvim günleri 45×45, ay okları 40×40) | Kaldı | Kaldı (ay oku) | Kaldı — gelecek günler %35 opak (1,16–3,02:1); devre dışı istisnası savunulabilir. "1"/"7" için 1,16–1,26 halka çizgisinden ölçüm yanılgısı olabilir (H) |
| Yemek Ekle | Kaldı (öğün seçici) | Kaldı | Geçti | Geçti |
| Aktif seans | **Kaldı** (24–25 küçük) | **Kaldı** | **Kaldı** (3× ✓) | **Kaldı** — RPE "–" koyu 1,88, açık 1,48 |
| Aktif seans + mola | **Kaldı** (27–28) | **Kaldı** | **Kaldı** | **Kaldı** — açık temada −15s/+15s **4,16**, Atla **3,38** |

Sonuç: Paket "Q08: `meetsGuideline` yok" diyordu (doğru). Ekleyince ilk dilimin
kabul ölçütü olarak **otomatik**, tekrar edilebilir bir kapı elde edilir;
bu dört kılavuzun aktif seans için geçmesi Faz 1'in nesnel bitiş ölçütü olabilir.

### 1.4 Yazı ölçeği (K + G\*)

- Global kısıt **yok** (`app.dart`'ta `textScaler` müdahalesi yok) → kullanıcı
  tercihine saygılı. 12 dosya eşik bazlı (×1,1–×1,3) düzen değiştiriyor
  (ör. `workout_activity_card.dart:50`, `nutrition_summary_card.dart:38`).
- Aktif seans sabit sütun genişlikleriyle kurulu: set 30, önceki 56, RPE 44,
  ✓ 42 (`active_session_widgets.dart:266,284,434–440,1060,1186,1214,1226`).
  320/×1,6'da gözlenen kırılmalar (`A6_visuals/large-en-session-rest.png`):
  değerler kesik, başlıklar heceleniyor, mola şeridi metni dikey, egzersiz adı
  "Bench Pr…", ekipman "Ba…", `RenderFlex` 5,9 px taşma. **G\***
- Paketin kendi görüntülerinde de var ama raporlarda geçmiyor (G\*, dosya):
  `large-en--progress.png` — 20–28. günler "2" diye kesik, gün başlıkları
  "Mo n"/"We d"; `large-en-food-sheet.png` — kısayollar "Barco…", "Quick …",
  "Your o…", makro "P8 C1…". `neon_design_test` bunları yakalamaz, çünkü
  ellipsis ve kırpma istisna fırlatmaz.
- `nutrition_screen.dart:123`: sabit yükseklik `76 × ölçek.clamp(1, 1.6)` →
  ×1,6 üstünde kırpılma riski (H; ×2,0 test edilmedi).

### 1.5 Azaltılmış hareket (K)

13 animasyon noktası; **3'ü** sistem tercihini okuyor (`velocity_navigation.dart:33`,
`warm_nutrition_summary.dart:370`, `exercise_demo.dart:142`). Okumayanlar:
sürekli dönen iskelet (`app_state_views.dart:150–152`, tek sonsuz animasyon),
seans ilerleme çubuğu (`active_session_widgets.dart:40`), `CalorieRing`
(`progress_indicators.dart:67,293`), ana sayfa halkaları (`home_screen.dart:953,1308`),
RPE seçici, öğün kartı, kurulum `AnimatedContainer`'ları. Q04 doğru ve tam;
düzeltme küçük (ortak bir `motionDuration(context, d)` yardımcısı).

### 1.6 Canlı sayaç anonsları (K + H)

- Dinlenme sayacı `RestBanner` içinde her saniye yeniden çizilen düz `Text`
  (`active_session_widgets.dart:178–188`, `active_session_screen.dart:861–878`);
  AppBar'daki geçen süre de her saniye (`:127–129`, `:1006`).
- `SemanticsService` duyurusu ve `liveRegion` hiç yok → **sayaç kendiliğinden
  hiçbir şey anons etmiyor**. Odak sayacın üstündeyken TalkBack/VoiceOver'ın
  değişen etiketi yeniden okuyup okumadığı platform davranışı (H, cihazda
  sınanmalı).
- Bitiş: ses/titreşim (`session_rest_sound.dart`) ve arka planda bildirim var;
  ön planda ekran okuyucuya metin duyurusu yok.
- **Öneri:** 3 olay duyurusu: "Dinlenme 1:30 başladı" (✓ sonucu ile birlikte),
  isteğe bağlı tek "10 saniye kaldı", "Dinlenme bitti". 12'deki "son 10
  saniyede" ifadesi geri sayımın 10 kez okunması diye anlaşılmamalı.

### 1.7 Yalnız renkle anlam (K + G\*)

- **Set tamamlandı:** aynı ✓ ikonu; fark dolgu rengi + satır tonu
  (`active_session_widgets.dart:1180,1231,1244`). Görsel olarak parlaklık farkı
  büyük (gri ↔ lime/yeşil dolgu, render'larda net) → renk körlüğünde muhtemelen
  ayırt edilir (H). **Ekran okuyucuda durum hiç yok** (seçili/işaretli bayrağı
  yok) — asıl açık bu.
- **Makrolar:** Beslenme ve ana sayfada etiketli (render'larda "Protein" vb.) — sorun yok.
  Yemek Ekle'de makro kısaltmaları "P8 C1…" renkle de kodlu; büyük yazıda
  kesildiği için hangi harfin ne olduğu kaybolabiliyor.
- **Aktivite takvimi:** dört halka yalnız renk + konumla; açıklama noktaları
  da yalnız renk; gün hücresinin semantiği yalnız gün numarası; "gün tamam"
  ikonu adsız (`activity_calendar.dart:312–319`). 12 §3.7'nin "makro sorun yok"
  sonucu bu bileşen için geçerli değil.

### 1.8 Odak / donanım klavyesi / Switch Access (K + H, asgari)

- 42 `InkWell` odaklanabilir (dökümde `isFocusable`); 3 `GestureDetector`
  odaklanamaz, biri tek yollu (su kartı uzun basma).
- Özel `Shortcuts` / `FocusTraversalGroup` yok; set satırında alanlarda
  `textInputAction` yok → klavyeden "sonraki alan" zinciri kurulmamış
  (`_NumCell`, `:1257–1300`).
- Odak kaybı riski: öneri/±/✓ sonrası alanlar `ValueKey('$field-${set.fillGen}')`
  ile **yeniden oluşturuluyor** (`:1038`) → erişilebilirlik odağı ve klavye
  odağı düşebilir (H; cihazda doğrulanmalı). P03'te dikkat edilmesi gereken
  teknik tuzak.
- Switch Access semantik eylemlerle çalışır; adsız ✓ "düğme" diye seçilir,
  hangi set olduğu bilinmez (H).

---

## Bölüm 2 — Mobil mühendislik lideri

### 2.1 P01–P12 uygulanabilirlik ve risk

"Kod" = AI oturumu; "Cihaz" = Samet'in iPhone + Samsung denemesi. Tahminler H;
kalibrasyon §2.4'te.

| ID | Uygulanabilirlik | Teknik risk | Kod | Cihaz | Not / ön koşul |
|---|---|---|---|---|---|
| P01 48 hedef | Orta — **sütun düzeni değişmeden imkânsız** | Orta | 1 | 1 akşam | 320'de hesap: kart iç genişliği ≈258 (ölçülen alanlardan); sabit sütunlar 172 → alan başı 43 (ölçülen 38). Set/RPE/✓ 48 olursa alan başı ~29. "Önceki" sütunu satır altına/ipucuna taşınmalı. Büyük yazı düzeltmesiyle **aynı işte** yapılmalı, yoksa ×1,6 daha da kötüleşir. |
| P02 öneri okunurluğu | Yüksek | Düşük | 0,25 | 15 dk | Aktif set etiketi zaten var; kalan: `_hintStyle` alfa, RPE "–", açık tema mola düğmeleri. |
| P03 ekran okuyucu sözleşmesi | Yüksek | Düşük–orta | 0,5–1 | 1 akşam (öğrenme dahil) | `fillGen` ile alan yeniden kurulumu odak kaybı yaratabilir. Otomatik: `labeledTapTargetGuideline` + semantik eşleşme testleri. Samet okuyucu kullanıcısı değil: ilk VoiceOver/TalkBack turu öğrenme süresi ister (H). |
| P04 ana sayfa sırası | Yüksek | Düşük | 0,25 | 15 dk | `home_screen.dart:76–102` sabit liste; yalnız sıra. |
| P05 Hedefler rotası | Yüksek | Düşük | 0,25 | 15 dk | Profil'de bölüme kaydırma için küçük parametre gerekebilir. |
| U07 özet hatası | Yüksek | Düşük | <0,25 | 5 dk | Tema dışında `error: … SizedBox.shrink()` 1 yer (`nutrition_screen.dart:242`); `ErrorState` 18 yerde zaten kullanılıyor. |
| P06 ortak sistem | Orta | Orta (görsel regresyon) | 2–4 | 2–3 akşam | 277 widget sınıfı, 19'u `shared/widgets`'ta; golden test **0**. Ekran ekran geçiş şart. |
| P07 küçült | P07a yüksek / P07b orta | P07a orta / **P07b yüksek** | 1 / 2–4 (+not) | 1 / 2–3 akşam | §2.2. |
| P08 besin akışı | Orta | Orta | 2–3 | 1–2 akşam | `add_food_sheet.dart` 1701 satır — en büyük dosya; önce bölme. |
| P09 ilerleme girişi | Orta | Düşük–orta | 1–2 | 1 akşam | `body_metrics_screen.dart` 919 satır; rotalar mevcut. |
| P10 grafik sözleşmesi | Orta | Orta–yüksek | 2–3 | 1 akşam | fl_chart 0.70.2; hesap anlamı değişirse §7b dokümanı. |
| P11 hareket | Yüksek (kritik alt küme) | Düşük | 0,5 | 30 dk | 10 nokta; ortak yardımcı. |
| P12 ritim/tercih | Yüksek (kod) | Düşük (kod) / ürün kararı | 1 | iki haftalık kullanım | Darboğaz karar ve pilot. |

### 2.2 P07 — seansı koruyarak küçültme

**Bugünkü sahiplik (K):**
- Tek sahip `_ActiveSessionScreenState`: hareket listesi (değişken nesneler,
  `setState` ile), başlık, rutin, başlangıç, gün; zamanlayıcılar `_ticker` (1 sn),
  `_restTimer` (deadline'dan yeniden hesaplanan tek atımlık), `_draftDebounce`
  (500 ms); `SessionRestSound`; kilit ekranı köprüsü `attach/detach`;
  `WakelockPlus`; uygulama yaşam döngüsü gözlemcisi; bitirme transaction'ı
  (`active_session_screen.dart:65–132, 482–498, 902–945`).
- Rota kök navigatörde, kabuğun **dışında** (`app_router.dart:248–262`). Sekmeye
  geçmenin tek yolu pop → `dispose`: süre sayacı durur, **çalan mola alarmı
  durdurulur** (`:487`, `session_rest_sound.dart:120–127`), kilit ekranı kartı
  kapanır (`:493`), ekran uyanıklığı kapanır. Uygulama içi çıkış onaylanırsa
  taslak silinir (`:986`).
- Yerel eylemler: iOS `LiveActivityIntent.perform` → `AppDelegate` → kanal
  `action` → Dart'ta **yalnız ekran bağlıysa** işlenir, aksi hâlde `false`
  (`workout_live_activity.dart:242–254`). Android'de motor yoksa bildirim
  kaldırılır (`WorkoutNotification.kt:150–158`).
- Ekran dışı parçalar zaten var: taslak (`workout_draft.dart`, SharedPreferences),
  `/workout/active/resume` rotası, ana sayfa ve Antrenman sekmesinde devam kartı
  (`home_screen.dart:319`, `workout_list_screen.dart:701`), sahipsiz kart temizliği
  (`WorkoutLiveActivity.endAll`).

**P07a — ucuz ara adım (öneri):** Çıkış diyaloğuna "Küçült" eklenir: taslak
silinmeden pop; `dispose`'ta mola sürüyorsa alarm/bildirim **durdurulmaz**
(Android ön plan servisi zaten deadline'a kurulu), kilit ekranı kartı kapatılır
(eylemlerin işleyicisi olmayacağı için bayat kart bırakılmaz). Devam: mevcut
resume yolu (`_restoreFromDraft` molayı deadline'dan sürdürür, `:399–403`).
- Kazanç: beslenmeye bakıp geri dönme bugün mümkün olur; şema/yeni durum yok.
- Kayıp: küçükken kilit ekranı kontrolleri yok; dönüşte DB'den yeniden yükleme
  (öneri/rekor hesapları yeniden yapılır).
- Risk: iOS'ta uygulama ön plandayken mola bitişi uygulama içi sesle
  çalınıyordu; ekran kapanınca bu yol kalkar → ön planda yerel bildirim
  gösterimi gerekir (H). 1 kod oturumu + 1 akşam.
- Amaç: Samet küçültmeyi gerçekten kullanıyor mu, iki haftada görülür; P07b'ye
  ancak o zaman yatırım yapılır.

**P07b — tam mimari (taslak):**
1. **Sahip:** uygulama ömürlü `ActiveSessionController` (Riverpod `Notifier`,
   **autoDispose değil** — bu projede `autoDispose` + `pushReplacement` çökme
   dersi var). Durum: seans kimliği (yeni yerel UUID), hareketler, deadline'lar.
   Değişken model korunacaksa `revision` sayacıyla yayın; yeni ikinci state
   kütüphanesi yok.
2. **Komutlar controller'da:** tamamla/geri al, ±, tip, set ekle/sil, hareket
   ekle/taşı/sil, mola ±15/atla, bitir (transaction → taslak sil → özet), sil.
   `setKey` koruması (`:190–218`) aynen taşınır.
3. **Zaman:** controller'da periyodik ticker **yok**; geçen süre `startedAt`'tan,
   mola deadline'dan türetilir. Saniyelik yeniden çizim yalnız görünür widget'ta
   (ekran ve mini şerit kendi küçük ticker'ı). Böylece "çift timer" sınıfı hata
   yapısal olarak önlenir.
4. **Yerelleştirme:** `_syncLive`, `_armRestAlarm`, `_syncRestNotification`
   `AppL10n.of(context)` kullanıyor (`:293, 836, 182`) → controller'a
   `lookupAppL10n(locale)` ile bağlam dışı erişim gerekir. Gizli ama zorunlu
   refaktör.
5. **Kilit ekranı:** işleyici uygulama açılışında bir kez controller'a bağlanır;
   ekran açık olmasa da eylem uygulanır (küçültmenin asıl anlamı). Soğuk
   başlatmada (süreç ölmüş) ilk sürümde mevcut davranış korunur: reddet,
   kartı kaldır, uygulama açılınca taslaktan kur.
6. **Mini şerit:** `AppShell`'de `bottomNavigationBar` içinde gezinmenin
   üstüne. Avantaj: sekme ekranlarının alt boşluğu `MediaQuery.padding.bottom`'dan
   geldiği için (`app_shell.dart:17–20`) şerit yüksekliği listelere kendiliğinden
   yansır. Kök navigatördeki sayfalarda (Profil, Ayarlar, Besinler…) şerit
   görünmez — karar gerekir (H: kabul edilebilir).
7. **Rotalar:** `/workout/active/:routineId` bugün her `build`'de yeni seans
   kuruyor. Controller'da seans varken bu rota "yeni seans mı, mevcuda dön mü"
   sorusu sormalı; iki seans yarışını rota katmanı değil controller önler.
8. **Ekran uyanıklığı:** yalnız seans ekranı görünürken (küçükken telefon
   uyuyabilmeli).
9. **Hesap değişimi:** `account_switch.dart:170` ve taslak `clearCount`
   mekanizması controller'ı da sıfırlamalı.
10. **Geçmiş kayıt modu** (`manualDate`) controller'a alınmaz; ekran-yerel kalır
    (kapsam küçülür).

**Riskler:** test göçü (`active_session_draft_test.dart` ekranı doğrudan
kuruyor; ~470 satır); ekran ve controller arasında çift kaynak dönemi; yerel
eylem yarışı (eylem gelirken bitirme); Android `RestTimerService` ile bildirim
eylemlerinin uygulama arka plandayken sırası; iOS'ta güncelleme bütçesi.

**Test matrisi (her satır iOS + Android):**

| # | Senaryo | Beklenen |
|---|---|---|
| 1 | Seans → küçült → Beslenme'de yemek ekle → şeritten dön | Aynı setler/değerler, süre kesintisiz |
| 2 | Mola sürerken küçült | Alarm/bildirim deadline'da çalar; dönüşte kalan doğru |
| 3 | Küçükken kilit ekranından ✓ / ± / +15 / Atla | Doğru set; bayat `setKey` reddedilir |
| 4 | Küçükken uygulamayı arka plana al, süreci öldür, aç | Taslaktan kurulur; kart kalmaz/yenilenir |
| 5 | Küçükken ikinci rutini başlatmayı dene | Tek seans; kullanıcıya seçim |
| 6 | Küçükken hesap değiştir | Seans, taslak, kart temizlenir |
| 7 | Bitir → özet → geri | Seans kapalı; şerit yok; kart yok |
| 8 | Sil (onaylı) | Taslak ve kart silinir |
| 9 | Gece yarısını geçen seans | `sessionDate` değişmez |
| 10 | Bildirim izni yok / Canlı Etkinlik kapalı | Uygulama içi akış çalışır |
| 11 | Dil değişimi seans sırasında | Kart etiketleri yeni dilde (veya bilinçli sabit) |
| 12 | Büyük yazı ×1,6 / 320 genişlik | Şerit kesilmez, gezinmeyi örtmez |
| 13 | Küçükken yazı alanında yarım değer (debounce penceresi) | Değer kaybolmaz |
| 14 | Kayıt transaction hatası | Taslak kalır, şerit kalır, tekrar denenebilir |

### 2.3 Tasarım sistemi durumu (K, betik sayımı)

| Ölçüt | Sayı | Yorum |
|---|---:|---|
| Tema dosyaları | 5 dosya, 922 satır | `app_colors`, `app_dimens`, `app_theme`, `nutrition_theme`, `theme_mode_provider` |
| `Color(0x` tema dışında | **0** (temada 122) | Renk disiplini çok iyi |
| `Colors.<ad>` tema dışında | 20 / 4 dosya | Kamera/foto örtüleri ve ipucu katmanı — meşru |
| `withValues(alpha:)` tema dışında | **116 / 38 dosya, 32 farklı değer** | Asıl sızıntı; Q02'nin 0.4'ü buradan |
| `EdgeInsets.*` toplam / sayısal literal içeren | 266 / 78 (%29) | Değerler çoğunlukla 0/2/3 (ince ayar); `AppSpacing` 1037 kullanım; `AppSpacing.x ± n` 17 |
| `BorderRadius.circular(sayı)` | 2 (2 ve 999) | `AppRadius` 165 kullanım — iyi |
| Sabit `SizedBox(width/height: sayı)` | 84 / 35 dosya | Büyük yazı kırılmalarının kaynağı (set tablosu) |
| İkon boyutu literal / `AppIconSize` | 33 / 115 | Orta |
| Süre literal (tema dışı) / `AppDuration` | 8 / 11 | Hareket politikası henüz yok |
| `fontSize:` literal | 4 | İyi |
| `VisualDensity.compact` | 18 / 12 dosya | Tema 48 hedefini deliyor (ör. "Nasıl yapılır" 40×40) |
| Widget sınıfı toplam / `shared/widgets` | 277 / 19 | Ortaklaştırma düşük |
| Ad bazlı yakın kopyalar | `*Card` 42, `*Row` 17, `*Sheet` 15, `*Header` 10, `*Button` 9, `*Chip` 8 | Örn. üç halka (`WarmEnergyRing`, `CalorieRing`, takvim `_RingsPainter`), üç adım düğmesi deseni (`_StepButton`, `IconButton.filledTonal` porsiyon, `_Stepper` rutin) |
| Alt panel | 23 `showModalBottomSheet`, ortak `SheetHeader` yalnız 4 | `AppSheet` önerisi (07) gerekçeli |
| Durum görünümleri | `EmptyState` 16, `ErrorState` 18, ham `CircularProgressIndicator` 33 | Ortak bileşenler var, yükleniyor durumu dağınık |
| Golden / `meetsGuideline` testleri | 0 / 0 | Görsel ve erişilebilirlik regresyonu korumasız |

Sonuç: Paketin "token var, sözleşme eksik uygulanıyor" tespiti doğru ve artık
sayısal. P06'nın en verimli ilk adımı yeni token değil: **alfa rolleri**
(ör. `subtle/muted/disabled/selectedFill`) ve **yoğun tablo için esnek sütun
kuralı**.

### 2.4 Efor — AI'nın yazdığı, sahibin cihazda test ettiği proje

Kalibrasyon (K): son 30 günde 190 commit, 15 etkin gün; seans dosyalarına 18
commit. Canlı Etkinlik + kilit ekranı eylemleri: 08 → 12 Ekim (≈4 takvim günü),
cihazda bulunan iki hata (çift kart, 160 pt kırpılma) ve bir Codex inceleme
turu ile. Ekip modeli: akşam 1–3 saatlik pencere (bellek notu).

| Dilim | Kod (AI oturumu) | Cihaz (akşam) | Beklenen düzeltme turu | Takvim (H) |
|---|---|---|---|---|
| Faz 1 (12'deki 1–6 + kılavuz testleri) | 1–2 | 2 (iOS + Android, okuyucu dahil) | 1 | 4–7 gün |
| P07a | 1 | 1 | 1 | 2–4 gün |
| P06 ilk geçiş | 2–4 | 2–3 | 1–2 | 1,5–2 hafta |
| P07b | not + 2–4 | 2–3 | 2 | 1,5–3 hafta |
| P08 / P09 / P10 | 2–3 / 1–2 / 2–3 | 1–2 / 1 / 1 | 1 | her biri ~1 hafta |

09'un 22–39 iş günü toplamı tek insan geliştirici varsayımı; 12'nin "Faz 1 ~1
oturum" tahmini ise kod için iyimser değil ama **büyük yazı düzeltmesini
saymıyor** — P01 bu ekranda büyük yazıdan ayrılamaz.

---

## Bölüm 3 — 07, 08, 09, 10, 12 ile uyum / anlaşmazlık

| Rapor / iddia | Bulgum | Kanıt | Durum |
|---|---|---|---|
| 10 §1: 320 genişlikte TR ×1,3 / EN ×1,6 render kapsamı; 76 görüntü | Aktif seans kapsamda **yok**; en kritik ekran büyük yazıda kırık | `neon_design_test.dart:171–186`; `A6_visuals/large-en-session-rest.png` | **Eksik — düzeltilmeli** |
| 07 §1, Q-akışı: "sorun token yokluğu değil, uygulama" | Doğru; sayısal: renk 0 sızıntı, alfa 116/32 değer, sabit boyut 84 | §2.3 | Güçlendi |
| 08 P01 / 09 §1: dar ekranda "iki satıra geçer" | Doğru yön; ama "Önceki" sütunu taşınmadan 48'ler sığmaz (hesap) | §2.1 | Netleşti |
| 12 K4: "± satırda mı, adım panelinde mi" | ± zaten satırda değil, aktif setin altındaki yardımcı satırda (`_ActiveSetAssist`). Karar konusu sütun düzeni | `active_session_widgets.dart:559–630` | **Soru yeniden çerçevelenmeli** |
| 08 P02 / 12 madde 2: "Öneri/Önceki" etiketi yok | Aktif sette "✓ ile 70 kg × 10 kaydedilir" etiketi var; eksik alan ipuçları, okuyucu ayrımı, RPE "–" | K + G\* | Kısmen yanlış |
| 08 P11 / 12 §3.7: her saniye anons riski | Kodda hiç anons yok; asıl açık bitişin duyulmaması | §1.6 | **Yanlış öncelik** |
| 12 §3.7: makrolar renk körlüğünde sorunsuz | Beslenmede doğru; aktivite takvimi halkaları yalnız renk + semantiksiz | §1.7 | Eksik |
| 10 Q08: `meetsGuideline` yok | Doğru; eklenince aktif seans 4/4 kalıyor, ana sayfa/beslenme ilk görünüm 4/4 geçiyor | §1.3 | Güçlendi + ölçüldü |
| 08 P07: karmaşıklık 4, risk 4, Faz 3 | Tam versiyon için doğru; P07a ile risk ve maliyet bölünebilir | §2.2 | Revizyon önerisi |
| 12 §3.6: "sayaç ve mola alarmı dispose'a bağlı" | Doğru ve daha keskin: dispose çalan Android alarmını da durduruyor | `:487`, `session_rest_sound.dart:120` | Güçlendi |
| 07 §8: `_ticker` her saniye tüm ekranı `setState` | Doğru (`:127–129`); P07b'de ticker'ı görünür widget'a indirmek hem performans hem doğruluk kazanımı | K | Güçlendi |
| 09 tahminleri (iş günü) | 12'nin itirazına katılıyorum; ek olarak cihaz turu sayısı ve düzeltme turu ayrı yazılmalı | §2.4 | Katılıyorum |
| 12 Faz 1 kabulü: "320'de taşma yok" | Bugün bu ölçüt **seans ekranında zaten kırık** (5,9 px taşma + kırpma) → Faz 1 kapsamı "büyük yazıda seans" düzeltmesini açıkça içermeli | G\* | Kapsam genişlemeli |
| 07 §7 aktif set sözleşmesi | Uygun; `fillGen` yeniden kurulumu odak kaybı riskini eklemeli | K | Ek |

## Pakete etkisi

**Güçlenen:** 07'nin token disiplini tespiti (sayısal kanıtla); Q01 hedef
ölçüleri (widget testiyle aynı sayılar: 38×34, 36×30, 30×32); Q04 hareket
tutarsızlığı (13 noktadan 3'ü); Q08 test açığı; 12'nin P07'yi ilk dilimden
çıkarması ve tahmin birimi eleştirisi.

**Zayıflayan / yanlış çıkan:**
- 10 §1'in "320/büyük yazı kapsamı" iddiası aktif seansı içermediği için
  yanıltıcı. **Düzeltme:** `neon_design_test` rota listesine
  `AppRoutes.workoutActiveRoutine(1)` ve mola durumu eklenmeli; görüntüler
  `visuals/current/`'a.
- P02 "etiket yok" ifadesi → "aktif sette etiket var; alan ipuçları ve okuyucu
  ayrımı eksik" olarak düzeltilmeli.
- P11/12 "her saniye anons" riski → "anons yok; başlangıç/bitiş duyurusu
  eklenmeli" olarak değiştirilmeli.
- 12 K4 sorusu → "Önceki sütunu satırda mı kalsın, set altına mı insin?"
  olarak yeniden yazılmalı.

**Eklenmesi önerilen:**
1. Faz 1 kabulüne: aktif seans + mola için dört Flutter kılavuzunun geçmesi
   (koyu/açık, 393 ve 320/×1,6); ✓ için ad + durum; RPE "–" ≥4,5:1; açık temada
   mola düğmeleri ≥4,5:1.
2. Faz 1 kapsamına: set tablosunun büyük yazı düzeni (sabit 30/56/44/42
   sütunları) ve mola şeridinin dikey kırılması.
3. Takvim/ilerleme: ay okları tooltip, gün hücresi semantik özeti
   ("12 Ekim: antrenman var, protein %80…"), "gün tamam" etiketi — Faz 2'ye.
4. Yemek Ekle porsiyon −/+ tooltip; büyük yazıda kısayol etiketlerinin kesilmemesi — Faz 1 veya 3B.
5. P07'yi P07a (küçült = taslağı koru, alarm sürsün) + kullanım gözlemi + P07b
   (controller) olarak ikiye bölmek; P07b için §2.2'deki 10 maddelik mimari ve
   14 satırlık matris teknik notun iskeleti olabilir.
