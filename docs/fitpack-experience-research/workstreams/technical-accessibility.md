# Teknik, erişilebilirlik ve kalite çalışma akışı

18 Ekim 2026 · Salt okunur kaynak incelemesi + resmî kaynak araştırması. Üretim kodu, bağımlılık, şema ve test dosyası değişmedi. Bu çalışma akışı cihazı kontrol etmedi; çalışma zamanı gözlemleri ana araştırma ekibinin kanıtlarıyla ayrıca birleştirilmeli.

## Gerçek teknik zemin

- Yerel kurulu Flutter **3.41.1**, Dart **3.11.0**: `/opt/homebrew/share/flutter/bin/cache/flutter.version.json` salt okunur kontrol edildi. Bu sürüm, kaynak deposunun başkalarının makinesinde de aynı sürümle açıldığını kanıtlamaz.
- Kilitlenmiş sürümler: Riverpod 2.6.1 (`pubspec.lock:606`), Drift 2.28.2 (`:428`), GoRouter 14.8.1 (`:720`), fl_chart 0.70.2 (`:516`). `pubspec.yaml` aralıkları kurulu sürümle karıştırılmamalı.
- Şema **17** (`lib/data/database/app_database.dart:124`), Android en düşük sistem sürümü **26** (`android/app/build.gradle.kts:31`). Kullanıcı iletilerindeki eski v8/minSdk24 bilgisi güncel kodu tarif etmiyor.
- Material 3, yerel Plus Jakarta Sans, açık/koyu temalar, semantik renk uzantısı zaten var (`lib/core/theme/app_theme.dart:27`, `:35`; `lib/core/theme/app_colors.dart:128`). Yeni görsel sistem kurmak için mevcut altyapıyı atmak gerekmiyor.
- Sayısal boşluk/köşe/ikon/süre ve 48 mantıksal piksel dokunma tokenı var (`lib/core/theme/app_dimens.dart:7`, `:43`, `:64`, `:75`, `:85`). Sorun token yokluğu değil, özel kontrollerde sözleşmenin eksik uygulanması.
- Türkçe/İngilizce yerelleştirme `MaterialApp` içinde bağlı (`lib/app.dart:143`). Yeni metinler ARB (Application Resource Bundle; uygulama kaynak paketi) dosyalarına gitmeli; sayı/tarih aktif dilde biçimlenmeli.

## Kanıt ve puan okuma kuralı

**Gözlem** kodda doğrudan görüleni, **hesap** belirtilen renklere uygulanan deterministik işlemi, **çıkarım** olası kullanıcı etkisini, **hipotez** önerinin beklenen sonucunu belirtir. Görsel/screen reader deneyi yapılmadıysa erişilebilirlik sertifikası veya kesin kullanıcı başarısızlığı iddia edilmez.

Puan sırası: **E/K/G/S/A/Z/R/C** = etki, kullanılabilirlik, görsel kalite, kullanım sıklığı, ayrışma, uygulama zorluğu, teknik risk, kanıt güveni. Her biri 1–5 uzman tahmini. İlk beşinde 5 yüksek fayda/sıklık, Z/R'de 5 yüksek maliyet/risk, C'de 1 spekülasyon ve 5 doğrudan kaynak/tekrarlanabilir hesap demektir. C puanı tasarımın başarısını doğrulamaz.

## Bulgu kaydı

| Kimlik | Gözlem / kanıt | Kullanıcı problemi / hipotez | Öneri ve beklenen yarar | Bedel / uygulanabilirlik / doğrulama | E/K/G/S/A/Z/R/C |
|---|---|---|---|---|---|
| **Q01** | **Gözlem:** set tamamla `InkWell` 38×34 (`lib/features/workout/active_session_widgets.dart:1234`), adım ± 36×30 (`:651`), set türü 30×32 (`:1186`). Tema minimumu bu özel kutuları büyütmez. | Terli el ve tek elle kullanımda kaçırma/yanlış kontrol riski; gerçekleşme sıklığı ölçülmedi. 48×48 ve aktif set için belirgin eylem daha güvenli olabilir. | Sık eylemler en az 48×48; aktif set altına etiketli bağlamsal tamamla. Tüm satırlara dev düğme koymak yerine aktif set önceliği. | Daha az satır görünür; 320 genişlikte iki satırlı düzen gerekir. Şemasız, orta zorluk. Gerçek hit alanı testi + tek el görevleri. | 5/5/3/5/3/2/2/5 |
| **Q02** | **Hesap:** `_hintStyle` ikincil metni %40 opak yapıyor (`active_session_widgets.dart:1338`); giriş dolgusu `app_theme.dart:236`. Koyu 2,134:1; açık 1,717:1. | Önceki kayıttan gelen öneri, bilgi taşımasına rağmen soluk. Yetersiz görünürlük ihtimali özellikle parlak salonda artar. | Öneriyi en az 4,5:1 tut; “Öneri” etiketi/ince kesik kenar ile girilmiş değerden ayır. | Daha güçlü metin ekranı yoğun gösterebilir. Token/alan bileşeni düzeyinde küçük iş. Render edilmiş tüm durumlarda ölç. | 5/5/3/5/2/1/1/5 |
| **Q03** | **Gözlem:** tamamla ikonu çağrısında ad/durum yok (`active_session_widgets.dart:1241`); sayısal alanlarda `labelText` yok (`:1287`, `:1361`). `FitPackIcon` SVG dalında adsız ikonu semantikten çıkarır (`lib/shared/widgets/fitpack_icon.dart:92`). | Ekran okuyucu set/hareket bağlamını yeterli aktarmayabilir. Semantik ağaç cihazda okunmadı: kanıtlanmış TalkBack engeli değil. | “Bench press, set 2, 80 kilogram, 8 tekrar; tamamla / tamamlandı; geri al” semantik sözleşmesi. Girişlere hareket+set+birim adı. | Yanlış `MergeSemantics` bağımsız alanları birleştirebilir. Orta iş; TalkBack/VoiceOver görev turu ve semantik snapshot. | 5/5/1/4/2/2/2/4 |
| **Q04** | **Gözlem:** azaltılmış hareket Velocity (`velocity_navigation.dart:33`) ve sıcak enerji halkasında (`warm_nutrition_summary.dart:370`) var. Skeleton `repeat()` (`app_state_views.dart:150`), ortak CalorieRing 400 ms (`progress_indicators.dart:67`), RPE (Rating of Perceived Exertion; algılanan zorluk) seçimi 150 ms (`rpe_picker_sheet.dart:171`) doğrudan animasyon kullanıyor. | Tutarsız hareket tercihi; rahatlık ve bekleme algısı riski. | Ortak motion policy: sistem tercihiyle shimmer sabit, halka anında son değerde; geri bildirim metin/renk ile korunur. | Kodun her animasyonu ayrı değerlendirilir; dönen iş göstergesi anlamlıysa sabit metinle eşlenir. Düşük iş, orta tarama alanı; tercihi çalışırken değiştirerek test. | 3/3/3/3/2/2/1/5 |
| **Q05** | **Gözlem:** gezinme %130 üstünde görsel etiketleri saklıyor, erişilebilir ad ve tooltip koruyor (`velocity_navigation.dart:29`, `:60`). RPE sekiz seçeneği tek satırda böler (`rpe_picker_sheet.dart:158`; `rpe_scale.dart:11`); panel kenarları 20'şer (`:69`). | Büyük yazı isteyen gören kullanıcı ikonlardan anlam çıkarmak zorunda kalabilir. 320 genişlikte RPE başına yaklaşık (320−40)/8 = 35 mantıksal piksel düşer. | Gezinmede büyüyen iki satırlı etiketli varyantı ve RPE için kaydırılan 48 genişlikli seçenekleri karşılaştır. | Alt alan büyür; kaydırmalı şeritte uç değerler keşfedilmeyebilir. Orta iş; 320/360 genişlik ve sistemin en büyük yazısı ile görev testi. | 4/4/3/4/2/2/2/4 |
| **Q06** | **Gözlem:** canlı seans taslağı, 500 ms debounce, lifecycle flush ve deadline zaten var (`active_session_screen.dart:152`, `:371`, `:399`). Genel `restorationScopeId` / `Restorable` taraması `lib/` içinde eşleşmedi. | Seans kurtarma güçlü; yemek ekleme, arama veya panelin kapanma sonrası devamlılığı için aynı güvence gösterilmedi. “Seanslar kayboluyor” iddiası yanlış olur. | Önce kesinti testi; yalnız önemli ve başarısız form akışlarına küçük taslak sözleşmesi. Kalıcı seans taslağı ile sayfa restoration ayrılır. | Kişisel alanları gereksiz saklamak ve eski taslak göstermek risk. Yeni kapsam gerekirse ayrıca veri tasarımı. Orta/yüksek; process kill + geri dönüşte değer karşılaştırması. | 4/4/1/3/3/3/3/4 |
| **Q07** | **Gözlem:** iOS Canlı Etkinlik durum/düğmeleri mevcut (`ios/WorkoutLiveActivity/WorkoutLiveActivityWidget.swift:128`); kilit kartı satırları tek satır ve ölçek küçültme kullanıyor (`:115`, `:153`). Köprü hata verirse seans sürüyor (`lib/core/live_activity/workout_live_activity.dart:189`). | Ana uygulamaya eklenen kontrol kilit ekranını kendiliğinden düzeltmez; uzun hareket adları, büyük yazı, ekran okuyucu için ayrı risk. | Ana uygulama ve yerel yüzey aynı eylem/durum sözlüğünü kullanmalı; küçük yerel görünüm tek güvenilir aksiyonu öne almalı. | SwiftUI/Kotlin ayrı geliştirme ve cihaz testi gerektirir. Kartı “tam uygulama”ya çevirmek pahalı. Orta iş; iOS 16.2 görüntü /17+ etkileşim ve Android bildirim testleri. | 4/4/3/4/4/3/3/4 |
| **Q08** | **Gözlem:** büyük yazı testleri 1,3/1,6 (`test/features/neon_design_test.dart:33`), semantik örnekler mevcut (`test/shared/velocity_navigation_test.dart:75`; `test/features/warm_nutrition_test.dart:125`). `test/` taramasında `meetsGuideline` veya kontrast/hedef kılavuzları bulunmadı. | Test sayısı yüksek olmak erişilebilirlik kapsamının tamamlandığını kanıtlamıyor. | Kritik görevlerde hedef+etiket+kontrast testleri; gerçek okuyucu ve sistem yazı boyutu testleri; kaynak kontrast hesabını sakla. | Otomatik test ekran okuyucu deneyimini kapsamaz; görsel golden tek başına doğru referans değildir. Orta iş, düşük risk; sıfır kritik görev engeli yayın kapısı. | 5/5/2/4/2/2/1/5 |

## Kontrast hesabının yeniden üretimi

Alfa bileşimi önce sRGB kanallarında `son = alfa × ön + (1−alfa) × arka`. Her 0–1 kanal `c ≤ 0,04045` ise `c/12,92`, aksi durumda `((c+0,055)/1,055)^2,4` ile doğrusallaştırıldı. Göreli parlaklık `0,2126R + 0,7152G + 0,0722B`; oran `(L_açık+0,05)/(L_koyu+0,05)`. Python ile salt okunur hesaplandı. Bu, tokenlardan modellenen opak dolgu durumudur; ekran görüntüsü ölçümü veya tüm widget durumlarına dair sonuç değildir.

| Ön / arka | Oran | Yorum |
|---|---:|---|
| `#A5A5A0` %40 / `#282827` | 2,134:1 | Koyu set önerisi normal metin eşiğinin altında |
| `#626459` %40 / `#E8E9DF` | 1,717:1 | Açık set önerisi normal metin eşiğinin altında |
| `#A5A5A0` / `#282827` | 5,966:1 | Aynı ikincil renk tam opak hâlde yeterli |
| `#171C03` / `#CCFF00` | 14,845:1 | Koyu birincil düğmenin temel renk çifti güçlü |
| `#526900` / `#FFFFFF` | 6,214:1 | Açık tema birincil metin çifti güçlü |
| `#B84300` / `#FFFFFF` | 5,467:1 | Açık tema turuncu rol çifti güçlü |
| `#B6B09F` / `#302D24` | 6,354:1 | Beslenme koyu ikincil metni güçlü |
| `#696656` / `#F2ECE0` | 4,910:1 | Beslenme açık ikincil metni temel dolgu üstünde yeterli |

Rakamlar okuma için yuvarlandı; eşik değerlendirmesi yuvarlanmamış değerle yapılmalı. Placeholder (yer tutucu) ve öneri aktif alan bilgisidir; disabled (devre dışı) istisnası otomatik uygulanmaz. [W3C kontrast açıklaması](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).

**Standartları karıştırma:** 48×48 Android tavsiyesi ve bu ürünün hedefidir. Web İçeriği Erişilebilirlik Kılavuzu (Web Content Accessibility Guidelines; WCAG) 2.2 AA 2.5.8'in temel web eşiği **24×24 CSS piksel ve istisnalar**; 48 diye yazılmaz. Flutter yerleşim birimi, Android dp, Apple pt ve CSS piksel kavramları aynı uygunluk sertifikası değildir. [Android](https://developer.android.com/guide/topics/ui/accessibility/views/apps-views), [W3C hedef boyutu](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html).

## Korunması gereken mühendislik kazanımları

1. Set/hedef doldurma davranışı ve canlı kart eylemi aynı seans sahibinden geçiyor; bayat set kimliği reddediliyor (`active_session_screen.dart:190`). Yeni sabit aksiyon aynı komutu çağırmalı; ikinci seans state'i yaratmamalı.
2. Kaydetme başarısız olursa taslak kalır ve düğme açılır (`active_session_screen.dart:913`). Yeni başarı ekranı yalnız veritabanı işlemi tamamlanınca açılmalı; bulut gönderimi başarı şartı yapılmamalı.
3. Gün dönümü bekçisi var (`lib/app.dart:174`), sekmeler canlı tutuluyor (`lib/core/router/app_router.dart:137`). Eski “bugün yenilenmiyor” ve “sekmeler hep sıfırlanıyor” bulguları doğrulanmadan tekrar yazılmamalı.
4. `SyncStatusTile` yerel kayıt / bulut bekleme / son yedek ayrımını zaten yapıyor (`lib/features/sync/sync_status_tile.dart:35`). Yeniden tasarım bu güveni korumalı.
5. Sağlık adımı izni iOS'ta kesin bilinemiyor (`lib/features/health/step_source.dart:25`). Tasarım “izin reddettin” diye kesin teşhis koymamalı.
6. Open Food Facts servisinde barkod 6 saniye, arama 8 saniye timeout ve boş/null dönüş var (`lib/data/services/openfoodfacts_service.dart:47`, `:92`). Her boş yanıtı “besin yok” diye sunmak yerine hata/no-result ayrımının servis sözleşmesiyle ayrıca tasarlanması gerekebilir; bu rapor mevcut ekranda kesin yanlış mesaj saptamadı.

## Teknik karar önerisi

İlk uygulama dilimi şema, senkron protokolü ve bağımlılık yükseltmeden; Q01–Q04 ve Q08'in kritik seans alt kümesi. Q05 prototip karşılaştırması sonrası. Q06 için gerçek başarısız kesinti görülmeden tüm uygulamayı state restoration ile baştan yazma. Q07 ayrı yerel platform kabul listesiyle ilerlemeli.

Resmî kaynaklar 18 Ekim 2026'da doğrulandı: [Flutter erişilebilirlik testleri](https://docs.flutter.dev/ui/accessibility/accessibility-testing), [Flutter giriş/focus](https://docs.flutter.dev/ui/adaptive-responsive/input), [Flutter azaltılmış hareket API'si](https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html), [Flutter Android state restoration](https://docs.flutter.dev/platform-integration/android/restore-state-android), [Apple Live Activities](https://developer.apple.com/design/human-interface-guidelines/live-activities), [ActivityKit erişilebilir etiketler ve kullanılabilirlik](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities). Bu kaynaklar tasarım sınırlarını destekler; FitPack kullanıcılarında beklenen kazanımı ölçmüş değildir.
