# A3 — Bağımsız rakip araştırması (derin inceleme turu)

Tarih: **18 Ekim 2026**. Yazar: bağımsız inceleme ajanı (A3). Kapsam: 19 ürün.
`03_COMPETITIVE_RESEARCH.md` ve `workstreams/competitive-sources.md` **araştırma
bittikten sonra** okundu; karşılaştırma en sondaki bölümde. Üretim kodu
değiştirilmedi.

## Karar özeti

1. **En yakın doğrudan rakip artık MacroFactor.** Ocak 2026'da ayrı bir
   **MacroFactor Workouts** uygulaması çıktı; beslenme + kuvvet ikilisini
   (Fit Pack'in tam alanı) iki uygulama ve $89,99/yıl paketle satıyor, ücretsiz
   katman yok, 7 günlük deneme var. Fit Pack'in "deneme dışında ücretsiz yok"
   modeline en yakın emsal budur. MacroFactor Türkçe değil (Q2). 03 bunu hiç anmıyor.
2. **Kilit ekranından set kaydı (Live Activity) premium için masa bahsi
   (table stakes) oldu:** Hevy (ücretsiz katmanda, iOS + Android), Strong
   (6.5.0), MacroFactor Workouts (1.2.0), JEFIT. Fit Pack'te iOS tarafı var ve
   Hevy ile aynı denetimleri sunuyor (K); **Android'de eşdeğeri bulunamadı** (K, grep).
3. **Fotoğraf/yazıyla yapay zekâ (AI) yemek kaydı beslenme uygulamalarında
   standartlaştı:** MyFitnessPal, Cronometer, Lose It!, Lifesum, MacroFactor
   (beta), Bevel ve Türk rakip Diyetkolik (beta). MyFitnessPal, Cal AI'yi satın
   aldı (Mart 2026 duyurusu). Ancak doğruluk zayıf: NIH ön çalışması dört
   uygulamada öğün başına ortalama 250–345 kcal **eksik** tahmin buldu (Q2/Q3,
   hakemsiz). Fit Pack'te yok (K).
4. **Saat uygulaması kuvvet kaydedicilerde yaygın ama zorunlu değil:** Strong,
   Hevy (watchOS + Wear OS), JEFIT, Fitbod var; MacroFactor Workouts'ta
   belgelenmedi. Fit Pack'te yok (K).
5. **Health Connect zorunlu altyapı:** Google Fit API'leri 2026 sonunda
   desteği bitiriyor (Q1). Fit Pack `health` paketiyle adım/kilo/yağ okuyor,
   antrenman yazıyor (K) — doğru yönde.
6. **Türkiye fiyatları çok düşük ve dağınık:** Hevy Pro ₺159,99/yıl, Strong
   ₺84,99–164,99/yıl, MacroFactor ₺649,99–749,99/yıl, Diyetkolik ₺250–499,99/yıl
   (App Store TR, Q2). Kuvvet kaydedicilerin ücretsiz katmanı **sınırsız kayıt**
   veriyor; Fit Pack'in premium konumu ancak MacroFactor tipi "bütünleşik +
   açıklanabilir" değerle savunulur (H).
7. **Türkçe boşluk gerçek:** Strong ve MacroFactor (iki uygulama) Türkçe değil;
   Hevy, MyFitnessPal, Yazio Türkçe. Türk yemekleri veritabanı yerli
   Diyetkolik'in tek belirgin avantajı (Q2); puanı 3,5/5 (927 oy).

## Yöntem ve sınırlar

- Yapılan: resmî ürün sayfaları, yardım merkezleri, App Store listeleri (ABD ve
  TR vitrini; açıklama + uygulama içi satın alma listesi + sürüm notları),
  resmî duyurular; WebSearch/WebFetch ile, hepsi 18 Ekim 2026'da erişildi.
- **Yapılamayan:** hiçbir rakip uygulama cihazda kurulup denenmedi. Bu yüzden
  gezinme sırası, ilk kullanım (onboarding) adım sayısı, dokunma sayısı ve tek
  elle kullanım **gözlem değil**, yalnız belgelenmişse yazıldı; aksi
  "bilinmiyor". Google Play sayfaları araçla okunamadı (içerik kesildi).
  `hevyapp.com/pricing` 404 döndü; Hevy fiyatı App Store'dan alındı.
- App Store satın alma listeleri hangi fiyatın hangi plana/bölgeye ait olduğunu
  söylemiyor; aynı adla birden çok fiyat görünüyor (eski/yerel/kampanya). Tablo
  bu yüzden **aralık** verir. Sayfalarda sürüm tarihleri yılsız ("Oct 8").
- Kanıt sınıfları (BRIEF): **K** kod; **Q1** resmî yardım/geliştirici belgesi;
  **Q2** resmî tanıtım, App Store listesi, resmî blog/duyuru; **Q3** ikincil
  kaynak (inceleme sitesi, haber, karşılaştırma blogu; çoğu taraflı);
  **H** hipotez.

## 1. Karşılaştırma matrisi

Kısaltmalar: LA = Live Activity (iOS kilit ekranı/Dinamik Ada canlı kartı);
HK = HealthKit (Apple Sağlık); HC = Health Connect (Android sağlık veri
merkezi); 1RM = one-rep max, tek tekrar maksimumu; RPE = Rating of Perceived
Exertion, algılanan zorluk; AI = yapay zekâ.

### 1a. Kuvvet antrenmanı odaklı

| Ürün | Ana iş / yapı | Aktif seans etkileşimi | İlerleme | Saat / LA | Ücretsiz vs ücretli | Türkçe | Kanıt |
|---|---|---|---|---|---|---|---|
| **Strong** | Şablon → seans günlüğü | Otomatik mola; ısınma ve plaka hesaplayıcı; RPE | 1RM ve hacim grafikleri, ölçümler | Tam watchOS uygulaması (telefonsuz); mola LA'sı + Dinamik Ada (6.5.0); takvim/aktivite widget'ları | Sınırsız kayıt, **3 özel rutin**; PRO $4,99/ay, $29,99/yıl (ABD açıklaması) | Yok | Q2 App Store |
| **Hevy** | Rutin/boş seans + sosyal akış + Trainer | Hareket başına otomatik mola; LA'dan **set tamamla**, molayı ±15 sn, atla (iOS + Android bildirimi) | Rekor, hacim, grafik (ücretsizde 3 ay) | watchOS (canlı senkron, komplikasyon, nabız) + **Wear OS** (karo, nabız) | Ücretsiz: **4 rutin, 7 özel hareket, 3 ay grafik**; Pro $2,99/ay, $23,99/yıl, $74,99 ömür boyu; LA ücretsiz | Var | Q1 yardım, Q2 App Store |
| **MacroFactor Workouts** (Ocak 2026) | Program üretimi + otomatik ilerleme | Özelleştirilebilir mola; LA (1.2.0) | "Smart Auto-Progression": plan günden güne ayarlanır; 1.4.1'de PPL bölünmesi, statik/doğrusal/ters doğrusal/dalgalı şemalar | LA var; **saat belgelenmedi** | Ücretsiz katman yok, 7 gün deneme; $11,99/ay, $71,99/yıl; paket $89,99/yıl | Yok (Q2 TR vitrini) | Q2 |
| **Fitbod** | Uyarlanan AI antrenman önerisi | Önerilen planı düzenle | Güç ve kas toparlanma modeli | watchOS 10+; LA belirtilmemiş | $12,99–15,99/ay, $79,99–95,99/yıl (listede eski fiyatlar da var); deneme: "3 antrenman" (Q3) vs "7 gün" (Q3) çelişkili | Bilinmiyor | Q2, Q3 |
| **JEFIT** | Kütüphane + Adaptive Plan | Mola/kronometre/geri sayım; set etiketleri (ısınma, drop, failure) | Haftalık kas başına set, toparlanma grafiği, otomatik 1RM | watchOS: canlı senkron, **kilit ekranında set sayısı + mola**, widget | Elite $12,99/ay, $69,99/yıl; Adaptive Plan 7 gün deneme; reklam verisi toplama beyanı var | Bilinmiyor (İng. + 5 dil) | Q2 |
| **Boostcamp** | Program kütüphanesi (14.000+) | RPE, mola, rekor; süperset/drop | Haftalık rapor, Strength Score | Bilinmiyor | **Takip ve kütüphane ücretsiz**, özel program kurucu sınırsız; plaka hesaplayıcı 10 kullanım; Pro $14,99/ay, $59,99/yıl (yalnız yıllıkta 7 gün deneme) | Bilinmiyor | Q2 resmî /pro |
| **Liftosaur** | Metinle program yazma (Liftoscript) | Kurala bağlı ilerleme | Bilinmiyor | Saat: 2026'da eklendiği kullanıcı yorumunda (Q3) | Fiyat resmî sayfada yok; ömür boyu seçeneği kullanıcı yorumlarında | Bilinmiyor | Q2, Q3 |
| **Alpha Progression** | Plan üretici + öneri | Ağırlık/tekrar önerisi | Gelişmiş grafikler (Pro) | Bilinmiyor | ~$12,99/ay, ~$79,99/yıl; ücretsiz kayıt var (kaynaklar çelişkili) | Bilinmiyor | Q3 |
| **Ladder** | Koç liderliğinde "takım" programları | Video yönlendirmeli seans | Bilinmiyor | Bilinmiyor | PRO $29,99/ay, ELITE $44,99/ay, 7 gün deneme (resmî fiyat sayfası arama özetinden, sayfa açılmadı) | Bilinmiyor | Q2 (zayıf), Q3 |
| **Nike Training Club** | Rehberli video içerik | Program/seans takibi | Program sürekliliği | watchOS (nabız, kalori) | **Tamamen ücretsiz** görünüyor (satın alma listelenmemiş) | Bilinmiyor | Q2 |

### 1b. Beslenme odaklı

| Ürün | Kayıt yolları | Ücretli olan kayıt araçları | Uyarlama | Saat | Fiyat (ABD, Q2) | Türkçe | Kanıt |
|---|---|---|---|---|---|---|---|
| **MyFitnessPal** | Today ekranı, arama, barkod, Meal Scan (fotoğraf), ses; AI Coach (çok görsel), buzdolabı tarama (26.41.0) | **Barkod, Meal Scan, ses, özel makro hedefi, reklamsız** Premium'da | Premium+ yemek planı | watchOS 10+ | IAP $19,99/ay, $79,99/yıl (eşleştirme belirsiz); 7 gün deneme | Var | Q2 premium sayfası + App Store |
| **Cal AI** (MFP'nin) | Fotoğraf öncelikli | — | — | — | Fiyat incelenmedi | — | Q2/Q3 duyuru haberleri |
| **MacroFactor** | Barkod, etiket tarama (5.8.3), AI fotoğraf / fotoğraf+metin / galeri (beta), zaman çizelgeli günlük, kopyala-yapıştır | Hepsi ücretli (ücretsiz katman yok) | **Uyarlanan harcama (TDEE) tahmini** ("Expenditure V3") | watchOS: yemek, kilo kaydı, komplikasyon | $11,99/ay, $47,99/6 ay, $71,99/yıl; 7 gün deneme | Yok | Q1 yardım, Q2 |
| **Cronometer** | Arama (1,1 M doğrulanmış), **barkod ücretsiz**, fotoğraf + ses (AI), Siri, saatten kayıt | Fotoğraf/ses, oruç, tarif içe aktarma, reklamsız Gold'da | Crono Coach | watchOS 9+ | Gold $10,99/ay, $59,99/yıl; deneme belirtilmemiş | Bilinmiyor | Q2 |
| **Lose It!** | Arama, barkod, fotoğraf, AI ses ("2 yumurta, tereyağlı tost") | **Barkod, fotoğraf, ses** Premium'da | Diyet planları | Bilinmiyor | $39,99/yıl öne çıkıyor; liste dağınık | Bilinmiyor | Q2 |
| **Lifesum** | Fotoğraf, ses, metin, barkod; sohbet tarzı tek giriş (23.2.0) | Sınırlı ücretsiz; detay belirtilmemiş | Yemek planları | Bilinmiyor | $7,49/ay, $14,99/3 ay, $49,99/yıl ("Trial" etiketli; liste çelişkili) | Bilinmiyor | Q2 |
| **Yazio** | 4 M+ arama, barkod, kopyala; "AI calorie tracker" markası ama fotoğraf belgelenmemiş | PRO: analiz, plan, Garmin/Fitbit senkron, reklamsız | Oruç planları | Var (yorumlarda sorun) | $23,90–47,90/yıl (liste dağınık); **ücretsizde reklam var** | Var | Q2 |
| **Diyetkolik / EatGenius** (Türk) | Arama (Türk yemekleri), barkod, AI fotoğraf + ses/metin (**beta**, 9.4.6), oruç sayacı, diyetisyen | Bilinmiyor | 20+ diyet listesi | Apple Sağlık | ₺89,99/ay, ₺199,99/3 ay, ₺250–499,99/yıl | Ana dil | Q2 App Store TR |

### 1c. Bütünleşik / sağlık katmanı

| Ürün | Ne yapıyor | Fark yaratan | Fiyat | Kanıt |
|---|---|---|---|---|
| **Bevel** | Kuvvet (700+ hareket, rutin, takvim, kas yükü/tazeliği, rekor) + beslenme (barkod, görselle arama, metin, zaman çizelgesi) + toparlanma/uyku/stres skorları + AI koç | Fit Pack'in üçlüsünü tek uygulamada, Apple Watch verisiyle birleştiriyor; yalnız iOS | Pro $14,99/ay, $99,99/yıl + AI kredi paketleri | Q2 |
| **Gentler Streak** | Activity Path, günlük hazır olma (readiness), dinlenmeyi cezalandırmayan seri | Kuvvet günlüğü değil; yalnız Apple ekosistemi (Android belgelenmemiş) | $7,99/ay, $54,99/yıl, $179,99 ömür boyu (Q3, tarihsiz) | Q2, Q3 |
| **Apple Fitness / Sağlık** | iOS 26: Fitness+ Custom Plans; iOS 26.1 elle antrenman kaydı; watchOS 26 **Workout Buddy** (AI sesli motivasyon, kuvvet dahil; Apple Intelligence'lı iPhone ister, başlangıçta yalnız İngilizce) | Platform sahibi; set/tekrar günlüğü sunduğu belgelenmedi | Fitness+ $9,99/ay, $79,99/yıl (Q3) | Q2 (Apple newsroom, arama özeti), Q3 |

## 2. Eğilimler (2025–2026) ve kanıt

| Eğilim | Kanıt | Durum | Sınıf |
|---|---|---|---|
| **Kilit ekranından set kaydı** | Hevy: egzersiz, sonraki set, öneri ağırlık/tekrar, süre, mola; set tamamla, ±15 sn, atla; iOS LA + Android kilit ekranı bildirimi; ücretsiz. Strong 6.5.0 mola LA'sı. MacroFactor Workouts 1.2.0 LA. JEFIT kilit ekranı set/mola. | Kuvvet kaydedicide **masa bahsi** | Q1 (hevyapp.com/features/live-activity), Q2 |
| **AI fotoğraf/ses/metin yemek kaydı** | MFP Meal Scan + Cal AI alımı; Cronometer, Lose It!, Lifesum, Bevel; MacroFactor beta (LLM yerine veritabanı eşleşmesi, düzenlenebilir "Plate"); Diyetkolik beta | Beslenme uygulamasında **masa bahsi**, çoğunda **ücretli** | Q1/Q2 |
| **AI doğruluğu** | NIH (NIDDK) ön çalışması, NUTRITION 2026 (25 Tem 2026): MFP, Lose It!, Cal AI, Appediet; 102 tartılmış öğün; kalori 250–345 kcal, yağ ~30 g eksik; keto öğünlerde daha kötü; hakemli yayın değil | Fotoğraf = **tahmin**, düzenleme ve belirsizlik dili şart | Q2/Q3 (ScienceDaily) |
| **Saat ile kayıt** | Strong (telefonsuz), Hevy (watchOS + Wear OS), JEFIT, Fitbod; MacroFactor beslenmede saat, Workouts'ta belgelenmedi | Kuvvet kaydedicide **beklenen**, ama yeni oyuncu (MF Workouts) onsuz çıktı | Q1/Q2 |
| **Uyarlanan program** | MF Workouts otomatik ilerleme; Fitbod; JEFIT Adaptive Plan + AI aşırı yükleme önerisi; Boostcamp Pro Auto Progression; Alpha Progression; Hevy Trainer (Pro; "algoritma, AI değil") | Premium katmanın **ana satış gerekçesi** | Q1/Q2 |
| **HK / HC entegrasyonu** | Google Fit API desteği 2026 sonunda bitiyor, yerine HC; Hevy Google Fit'e yalnız HC üzerinden bağlanıyor | **Masa bahsi**; Google Fit'e doğrudan bağlanmak artık hata | Q1 (developer.android.com, Hevy yardım) |
| **Dış AI'a veri aktarımı** | Hevy 3.1.x: biten antrenmanı ChatGPT/Claude'a gönder; Hevy API (Pro) ile üçüncü taraf koçlar; MFP ChatGPT Health entegrasyonu | Yeni, henüz masa bahsi değil | Q2, Q3 |
| **Bütünleşik "sağlık OS"** | Bevel (kuvvet + beslenme + toparlanma), MacroFactor iki uygulama paketi | Fit Pack'in kategorisine doğrudan baskı | Q2 |

## 3. Premium uygulama için masa bahisleri (table stakes)

"Masa bahsi" = yokluğu, ücretli bir kuvvet+beslenme uygulamasında şikâyet
nedeni olur; varlığı tek başına fark yaratmaz. Fit Pack durumu kod taramasına
dayanır (kaynak anı `07104d1`); cihaz doğrulaması bu raporda yapılmadı.

| # | Masa bahsi | Dayanak (kaç rakip) | Fit Pack durumu | Sınıf |
|---|---|---|---|---|
| 1 | Önceki değer yanında, hızlı set kaydı | Strong, Hevy, JEFIT, Boostcamp | Var (03 ve 02'de belgeli) | K (başka raporlar) |
| 2 | Otomatik mola + arka planda bildirim | Hepsi | Var: `rest_timer` kanalı, iOS zaman-duyarlı | K `lib/core/notifications/notification_service.dart:55`, `:231` |
| 3 | **iOS LA: set tamamla / mola ±15 sn / atla** | Hevy, Strong, MF Workouts, JEFIT | **Var**, Hevy ile aynı denetim seti | K `ios/Runner/WorkoutLiveActivityIntents.swift:24,42,65,78` |
| 4 | **Android'de etkileşimli seans bildirimi** | Hevy (Android'de aynı denetimler) | **Bulunamadı** — yalnız mola uyarı kanalı | K (grep; H: başka yerde olabilir) |
| 5 | HK + HC: antrenman yaz, kilo oku | Strong, Hevy, MFP, Cronometer, Diyetkolik | Var: antrenman yazma, kilo/yağ/adım okuma | K `lib/features/health/workout_export.dart:65`, `body_import.dart:69-70`, `step_source.dart:46` |
| 6 | Barkod | MFP, Cronometer, Lose It!, Yazio, MacroFactor, Diyetkolik | Var (Open Food Facts) | K `lib/features/nutrition/barcode_flow.dart`, `add_food_sheet.dart:351` |
| 7 | Son/sık yiyecek, öğün kopyalama | MFP, MacroFactor, Yazio | Var (03'e göre) | K (03 ile) |
| 8 | 1RM/rekor grafikleri, vücut ölçümü | Strong, Hevy, JEFIT | Var (03'e göre) | K (03 ile) |
| 9 | Reklamsız | Ücretli katmanların hepsi; Yazio/Cronometer ücretsizde reklamlı | Var (konum gereği) | — |
| 10 | Çevrimdışı çalışma | Sınıfta beklenir, rakipler belgelemiyor | Var, mimari olarak (yerel-öncelikli) | K (CLAUDE.md) |
| 11 | Uyarlanan / önerili ilerleme | MF Workouts, Fitbod, JEFIT, Boostcamp Pro, Hevy Trainer | Kısmen: ilerleme önerisi var (03 C08) | K (03 ile) |
| 12 | Veri dışa aktarma (CSV) | Strong, MFP (ücretli) | Bu turda doğrulanmadı | Bilinmiyor |
| 13 | **AI fotoğraf/metin yemek kaydı** | 7 beslenme rakibi | **Yok** | K (grep: `image_picker` yalnız ilerleme fotoğrafında, `progress_photos_screen.dart:402`) |
| 14 | Saat uygulaması | Strong, Hevy, JEFIT, Fitbod | **Yok** (iOS'ta saat hedefi yok) | K (`ios/` dizini) |

13 ve 14 "yakın masa bahsi": rakiplerin çoğunda var, ama MacroFactor
Workouts'un saatsiz çıkması ve AI fotoğrafın doğruluk sorunu, ikisinin de
**ilk sürümde** zorunlu olmadığını gösteriyor (H).

## 4. Fiyat aralıkları

Bölge uyarısı: ABD fiyatları App Store açıklaması/IAP listesinden; TR fiyatları
`apps.apple.com/tr` IAP listesinden. Listeler hangi fiyatın hangi
plan/kampanya/eski aboneliğe ait olduğunu söylemiyor; Google Play fiyatları
okunamadı. Vergi dahil/haric durumu belirtilmemiş.

| Ürün | ABD aylık | ABD yıllık | TR aylık | TR yıllık | Deneme | Sınıf |
|---|---|---|---|---|---|---|
| Hevy Pro | $2,99 (ikinci $3,99) | $23,99 | ₺19,99 / ₺29,99 | ₺159,99 | Bilinmiyor; ömür boyu $74,99 / ₺3.999,99 | Q2 |
| Strong PRO | $4,99 | $29,99 (listede $23,99) | ₺17,99 / ₺25,99 | ₺84,99–164,99 | Bilinmiyor; ömür boyu $79,99–99,99 / ₺3.999,99–4.999,99 | Q2 |
| MacroFactor (her uygulama) | $11,99 | $71,99 | ₺109,99–122,99 | ₺649,99–749,99 | 7 gün, ücretsiz katman yok | Q2 |
| MacroFactor paket | — | $89,99 | Bilinmiyor | Bilinmiyor | — | Q2 |
| MyFitnessPal Premium | $19,99 | $79,99 | ₺26,99 / ₺134,99 | ₺129,99–2.499,99 | 7 gün (ilk kez) | Q2 |
| Cronometer Gold | $10,99 | $59,99 | — | — | Belirtilmemiş | Q2 |
| Fitbod | $12,99–15,99 | $79,99–95,99 | — | — | Çelişkili (Q3) | Q2, Q3 |
| JEFIT Elite | $12,99 | $69,99 | — | — | 7 gün (Adaptive Plan) | Q2 |
| Boostcamp Pro | $14,99 | $59,99 | — | — | 7 gün (yalnız yıllık) | Q2 |
| Bevel Pro | $14,99 | $99,99 | — | — | Var, süre yok | Q2 |
| Lifesum | $7,49 | $49,99 | — | — | "Trial" etiketi | Q2 (çelişkili) |
| Gentler Streak | $7,99 | $54,99 | — | — | — | Q3 |
| Ladder | $29,99 (PRO) | — | — | — | 7 gün | Q2 zayıf |
| Alpha Progression | ~$12,99 | ~$79,99 | — | — | 14 gün (Q3) | Q3 |
| Apple Fitness+ | $9,99 | $79,99 | — | — | — | Q3 |
| Diyetkolik | — | — | ₺89,99 | ₺250–499,99 | Bilinmiyor | Q2 |

Okuma: ABD'de iki küme var — **ucuz kaydediciler** ($24–30/yıl: Hevy,
Strong) ve **"akıllı" premium** ($60–100/yıl: MacroFactor, MFP, Cronometer,
JEFIT, Fitbod, Boostcamp, Bevel). TR vitrininde aynı ayrım daha keskin: Hevy
₺159,99/yıl ile MacroFactor ₺749,99/yıl arasında ~4,7 kat. MyFitnessPal'ın TR
listesinde ₺129,99 ile ₺2.499,99 yıllık birlikte görünmesi, yeni ve eski
aboneler için çok farklı fiyatlar olduğunu düşündürüyor (H). Fit Pack fiyat
kararı ertelenmiş durumda; bu tablo yalnız kıyas zemini.

## 5. Ürün notları (tabloya sığmayanlar)

- **Gezinme ve ilk kullanım:** cihazda denenmedi. Belgelenmiş olanlar:
  MyFitnessPal 2026'da Today'i açılış ekranı yaptı (03, Q1); Lifesum tek
  sohbet tarzı kayıt girişine geçti (23.2.0, Q2); Bevel 3.2.x'te Fitness
  bölümünü yeniden tasarlayıp Takvim ve yemek Zaman Çizelgesi ekledi (Q2);
  MacroFactor "zaman çizelgeli günlük" kullanıyor (Q2). **Yön:** beslenmede
  öğün kutuları yerine zaman çizelgesi + tek giriş noktası (H).
- **Tek elle kullanım:** hiçbir rakip resmî olarak belgelemiyor. Pratikte
  kilit ekranı denetimleri (Hevy/Strong/JEFIT) ve saat bunun yerine geçiyor (H).
- **Ücretli duvar dağılımı:** MyFitnessPal ve Lose It! **barkodu ücretli**
  yaptı (Q2); Cronometer barkodu açıkça ücretsiz tutup bunu pazarlıyor (Q2).
  Hevy LA'yı ücretsiz bırakıyor (Q1). Boostcamp takip + programları ücretsiz
  verip yalnız kişiselleştirmeyi satıyor (Q2). Eğilim: **temel kayıt hızı
  ücretsiz, "akıl" ücretli** (H).
- **Zayıflıklar (belgeli/yansıyan):** Strong 6.5.1 oturum/senkron kopmalarını
  düzeltiyor — bulut senkronu kırılgan alan (Q2 sürüm notu). Yazio
  yorumlarında saat ve Fitbit yeniden bağlanma şikâyeti (Q3, tekil). Lifesum
  yorumlarında AI odaklı kayıttan rahatsızlık (Q3, tekil). MacroFactor TR
  yorumlarında Türkçe talebi (Q3). Diyetkolik 3,5/5 (Q2). Hevy Trainer
  ilerlemeyi yalnız tüm setlerde aralık tepesine ulaşınca artırıyor (Q1) —
  katı kural. NIH ön çalışması AI fotoğrafın sistematik eksik tahminini
  gösteriyor (Q2/Q3).
- **Apple'ın kendi baskısı:** Workout Buddy kuvvet dahil AI sesli
  motivasyon veriyor ama yalnız İngilizce ve yeni cihazlarda (Q2/Q3). Türkçe
  kullanıcı için Fit Pack'le çakışma şu an düşük (H).

## 6. Fit Pack için farklılaşma fırsatları

Her biri hipotezdir (H); kullanıcıyla doğrulanmadı.

1. **"Tek Türkçe uygulamada antrenman + beslenme + vücut" — MacroFactor'ın
   boşluğu.** MacroFactor aynı vaadi iki ayrı, İngilizce uygulama ve paket
   fiyatla veriyor; Bevel yalnız iOS ve İngilizce odaklı. Türkçe, tek
   uygulama, Android + iOS eşitliği savunulabilir bir konum.
2. **Android eşitliği bir fark olabilir.** Hevy dışında rakiplerin çoğu
   kilit ekranı denetimini yalnız iOS'ta belgeliyor. Fit Pack iOS LA'yı zaten
   Hevy düzeyinde yaptı (K); Android'de etkileşimli seans bildirimi (set
   tamamla / mola ±15 sn / atla) eklemek, Türkiye'de Android payı yüksek
   olduğundan (H, ölçülmedi) en ucuz premium kazanımlardan biri.
3. **Dürüst AI yemek kaydı.** Rakipler fotoğrafı hız vaadiyle satıyor;
   NIH verisi sistematik eksik tahmin gösteriyor. Fit Pack eklerse:
   (a) metin/ses ile Türkçe öğün tarifi ("1 kase mercimek çorbası, yarım
   ekmek") fotoğraftan önce, çünkü porsiyon kullanıcının ağzından gelir;
   (b) sonuç her zaman düzenlenebilir taslak, "tahmin" etiketi; (c) MacroFactor
   gibi LLM çıktısını değil veritabanı kaydını eşleştirme. Türk mutfağı
   (yağlı sulu yemekler, hamur işi) tam da çalışmanın zayıf bulduğu yağ
   tahmini alanı → belirsizlik dili burada bir güven farkı.
4. **Türk yemekleri veritabanı.** Yerli rakibin tek açık avantajı bu
   (Diyetkolik, Q2). Open Food Facts paketli ürün barkodunda iyi, ev yemeğinde
   zayıf olabilir (H). Küratörlü "Türk mutfağı temel 300" seti fark yaratır.
5. **Açıklanabilir uyarlama.** Pazarda uyarlama ya kara kutu (Fitbod, AI)
   ya katı kural (Hevy Trainer). Fit Pack'in mevcut ilerleme önerisini
   "neden + dayanak seans + değiştir" ile sunmak (03 C08 ile aynı yön) premium
   gerekçesi olur.
6. **Çevrimdışı güven.** Strong'un son sürümleri senkron kopmalarını
   düzeltiyor; salonda sinyalsiz kayıt Fit Pack'in mimari üstünlüğü. Tanıtımda
   ve boş durum metinlerinde açıkça söylenebilir.
7. **Kaçınılacak:** fiyatla Hevy/Strong'a yarışmak (TR'de ₺85–160/yıl);
   sosyal akış; video katalog (NTC ücretsiz). Saat uygulaması değerli ama
   Flutter'da yerel watchOS/Wear OS hedefi ayrı büyük iş; Android bildirimi
   ve AI metin kaydından sonra gelmeli (H).

## 7. 03 ile karşılaştırma

### 03'ün doğru bulduğu

- **MyFitnessPal Today** ana ekran değişikliği ve **Hevy Trainer** — doğru,
  güncel (Q1 kaynakları sağlam).
- **Strong 3 şablon / Hevy 4 rutin + 3 ay grafik** ücretsiz sınırları —
  bağımsız olarak doğruladım (Strong App Store; Hevy yardım merkezi).
- Sosyal ağ, yarışma, video katalog, tam otomatik program motorunu ilk
  kapsam dışı tutma — rakip verisi bu kararı destekliyor.
- "Model ≠ ölçüm" ilkesi (Fitbod toparlanma, MacroFactor harcama) — NIH
  verisiyle fotoğraf kalorisi için de güçlendi.
- Fit Pack'in mevcut özelliklerini (ana kart, devam kartı, seri, kopyalama)
  "yeni eksik" saymama dikkati — doğru ve bu raporda da korundu.

### 03'ün kaçırdığı

| Konu | 03 ne diyor | Bulgum | Kanıt |
|---|---|---|---|
| **MacroFactor Workouts** | MacroFactor yalnız beslenme ürünü olarak işleniyor | Ocak 2026'dan beri ayrı kuvvet uygulaması + paket; Fit Pack'in en doğrudan rakibi | Q2 macrofactor.com/workouts/price, App Store |
| **Live Activity / kilit ekranı** | Hiç geçmiyor; mola yalnız uygulama içi (C01) | Rakiplerde masa bahsi; Fit Pack iOS'ta zaten var, Android'de yok | Q1 Hevy, Q2 Strong/MF; K |
| **Saat uygulamaları** | Geçmiyor | Strong, Hevy (Wear OS dahil), JEFIT, Fitbod | Q1/Q2 |
| **Health Connect / Google Fit sonu** | Geçmiyor | 2026 sonunda Google Fit API desteği bitiyor | Q1 |
| **AI fotoğraf kaydı eğilimi** | Yalnız "kapsam dışı" diye tek cümle | 7 beslenme rakibinde var; MFP Cal AI'yi aldı; doğruluk kanıtı karışık | Q1/Q2/Q3 |
| **Fiyat ve deneme modeli** | Bilinçli olarak karşılaştırılmadı | Bölge uyarısıyla aralık verilebiliyor; TR vitrini okunabilir | Q2 |
| **Türkiye pazarı / Türkçe desteği** | Yok | Strong ve MacroFactor Türkçe değil; Diyetkolik yerli rakip | Q2 |
| **Bütünleşik rakipler** | Yok | Bevel kuvvet + beslenme + toparlanmayı birleştiriyor | Q2 |
| **Program odaklı rakipler** | Yok | Boostcamp, JEFIT, Liftosaur, Alpha Progression | Q2/Q3 |
| **Barkodun ücretli duvara geçişi** | MFP için "bazı kayıt araçları ücretli" | MFP ve Lose It! barkodu ücretli; Cronometer ücretsiz | Q2 |

### 03'ün yanlış veya eskimiş kısımları

- **"Fotoğraftan kalori eklenmesin" kararı** — gerekçe (doğrulama yükü) hâlâ
  geçerli, ama 03 bunu düşük öncelikli bir özellik gibi sunuyor. Bulgum:
  beslenmede premium rakiplerin neredeyse tamamında var. **Önerilen düzeltme:**
  "şimdi değil" yerine "ilk sürümde değil; metin/ses ile Türkçe öğün tarifi
  önce, fotoğraf sonra, her zaman düzenlenebilir tahmin" diye yeniden
  yazılsın.
- **MacroFactor kartı eskimiş:** yalnız pano/enerji dengesi anlatılıyor; AI
  kayıt (beta), etiket tarama, saat uygulaması ve Workouts eksik. Karttaki
  "Türk mağaza fiyatı doğrulanmadı" artık doğrulanabilir (₺649,99–749,99/yıl,
  Q2).
- **Gentler Streak'in platform sınırı yazılmamış:** resmî sayfa yalnız
  App Store ve Apple Watch'tan söz ediyor; Android'li Fit Pack kullanıcısına
  doğrudan karşılık gelmediği belirtilmeli.
- **Strava ve Todoist** kategori için zayıf seçim; 10 kayıttan 2'si alana
  dışarıdan. Kuvvet + beslenme rakipleri (MacroFactor Workouts, Bevel,
  Cronometer, Boostcamp) daha çok bilgi verirdi.
- **Kaynak S06 `hevy.com/pricing`:** benim denemem `hevyapp.com/pricing` için
  404 verdi; 03'ün adresini ayrıca açmadım. Hevy sınırları yardım merkezinden
  doğrulandığı için iddia ayakta, ama kaynak satırı yardım makalesiyle
  değiştirilmeli.
- **Fitbod deneme süresi:** 03 "doğrulanmadı" diyor, bu doğru; ikincil
  kaynaklar "3 antrenman" ile "7 gün" arasında çelişiyor (Q3). Hâlâ bilinmiyor.

## Kaynaklar

Hepsine **18 Ekim 2026**'da erişildi. "Arama özeti" = sayfa WebFetch ile
açılmadı, arama sonuç özetinden alındı (daha zayıf).

| # | Kaynak | URL | Sınıf |
|---|---|---|---|
| 1 | Strong App Store (ABD) | https://apps.apple.com/us/app/strong-workout-tracker-gym-log/id464254577 | Q2 |
| 2 | Strong App Store (TR) | https://apps.apple.com/tr/app/strong-workout-tracker-gym-log/id464254577 | Q2 |
| 3 | Strong ürün sayfası | https://www.strong.app/ | Q2 |
| 4 | Hevy App Store (ABD) | https://apps.apple.com/us/app/hevy-workout-tracker-gym-log/id1458862350 | Q2 |
| 5 | Hevy App Store (TR) | https://apps.apple.com/tr/app/hevy-workout-tracker-gym-log/id1458862350 | Q2 |
| 6 | Hevy Live Activity | https://www.hevyapp.com/features/live-activity/ | Q1/Q2 |
| 7 | Hevy Pro kapsamı (yardım) | https://help.hevyapp.com/hc/en-us/articles/35119778922263 | Q1 (arama özeti) |
| 8 | Hevy Wear OS (yardım) | https://help.hevyapp.com/hc/en-us/articles/34895840771479 | Q1 (arama özeti) |
| 9 | Hevy Health Connect (yardım) | https://help.hevyapp.com/hc/en-us/articles/34204824335255 | Q1 (arama özeti) |
| 10 | Hevy Trainer (yardım) | https://help.hevyapp.com/hc/en-us/articles/38385724273047 | Q1 (arama özeti) |
| 11 | Hevy özellik dizini | https://www.hevyapp.com/features/ | Q2 |
| 12 | MacroFactor Workouts fiyat | https://macrofactor.com/workouts/price/ | Q2 |
| 13 | MacroFactor Workouts App Store | https://apps.apple.com/us/app/macrofactor-workouts-tracker/id6737156524 | Q2 |
| 14 | MacroFactor App Store (ABD) | https://apps.apple.com/us/app/macrofactor-macro-tracker/id1553503471 | Q2 |
| 15 | MacroFactor App Store (TR) | https://apps.apple.com/tr/app/macrofactor-macro-tracker/id1553503471 | Q2 |
| 16 | MacroFactor AI food logging (yardım) | https://help.macrofactorapp.com/en/articles/258-ai-food-logging | Q1 (arama özeti) |
| 17 | MacroFactor AI duyurusu | https://macrofactor.com/ai-food-logging/ | Q2 (arama özeti) |
| 18 | MacroFactor Ocak 2026 bülteni | https://macrofactor.com/mm-jan-2026/ | Q2 (arama özeti) |
| 19 | MacroFactor Apple Watch | https://macrofactor.com/apple-watch/ | Q2 (arama özeti) |
| 20 | MyFitnessPal Premium | https://www.myfitnesspal.com/premium | Q2 |
| 21 | MyFitnessPal App Store (ABD) | https://apps.apple.com/us/app/calorie-counter-myfitnesspal/id341232718 | Q2 |
| 22 | MyFitnessPal App Store (TR) | https://apps.apple.com/tr/app/calorie-counter-myfitnesspal/id341232718 | Q2 |
| 23 | MFP–Cal AI satın alma (TechCrunch / Fitt Insider) | https://insider.fitt.co/myfitnesspal-acquires-rival-food-tracker-cal-ai/ | Q3 (arama özeti) |
| 24 | Cronometer App Store | https://apps.apple.com/us/app/cronometer-calorie-counter/id1145935738 | Q2 |
| 25 | Lose It! App Store | https://apps.apple.com/us/app/lose-it-calorie-counter/id297368629 | Q2 |
| 26 | Fitbod App Store | https://apps.apple.com/us/app/fitbod-gym-fitness-planner/id1041517543 | Q2 |
| 27 | Fitbod deneme (Garage Gym Reviews, Dr. Muscle) | https://www.garagegymreviews.com/fitbod-review | Q3 (arama özeti) |
| 28 | Nike Training Club App Store | https://apps.apple.com/us/app/nike-training-club-wellness/id301521403 | Q2 |
| 29 | Gentler Streak ürün | https://gentlerstories.com/gentlerstreak/ | Q2 |
| 30 | Gentler Streak fiyat (BGR, tarihsiz) | https://bgr.com/tech/gentler-streak-gets-a-major-redesign-focused-on-your-wellbeing/ | Q3 (arama özeti) |
| 31 | Bevel App Store | https://apps.apple.com/us/app/bevel-health-fitness-coach/id6456176249 | Q2 |
| 32 | JEFIT App Store | https://apps.apple.com/us/app/jefit-gym-workout-planner/id449810000 | Q2 |
| 33 | Boostcamp Pro | https://www.boostcamp.app/pro | Q2 |
| 34 | Liftosaur | https://liftosaur.com/ | Q2 |
| 35 | Alpha Progression incelemeleri | https://fitnessdrum.com/alpha-progression-app-review/ | Q3 (arama özeti) |
| 36 | Ladder fiyat | https://www2.joinladder.com/pricing | Q2 (arama özeti) |
| 37 | Yazio App Store | https://apps.apple.com/us/app/yazio-calorie-counter-diet/id946099227 | Q2 |
| 38 | Lifesum App Store | https://apps.apple.com/us/app/lifesum-ai-calorie-counter/id286906691 | Q2 |
| 39 | Diyetkolik App Store (TR) | https://apps.apple.com/tr/app/diyetkolik-kalori-hesaplama/id558076089 | Q2 |
| 40 | Apple watchOS 26 duyurusu | https://www.apple.com/newsroom/2025/06/watchos-26-delivers-more-personalized-ways-to-stay-active-and-connected | Q2 (arama özeti) |
| 41 | Workout Buddy dil/cihaz (DC Rainmaker, Tom's Guide) | https://dcrainmaker.com/2025/06/apple-watchos-26-announced-workout-buddy-and-more-explained.html | Q3 (arama özeti) |
| 42 | Google Fit → Health Connect geçişi | https://developer.android.com/health-and-fitness/health-connect/migration/fit | Q1 (arama özeti) |
| 43 | NIH AI fotoğraf doğruluğu (ScienceDaily) | https://sciencedaily.com/releases/2026/07/260726015237.htm | Q2/Q3 |

İkincil fiyat siteleri (sensai.fit, aitoolsbakery, recime, nutrola vb.) yalnız
yön için okundu; nutrola ve arvo rakip pazarlamasıdır, hiçbir iddiada tek
kaynak olarak kullanılmadı.

## Pakete etkisi

- **03_COMPETITIVE_RESEARCH.md — güçlendi:** MFP Today, Hevy Trainer,
  Strong/Hevy ücretsiz sınırları, sosyal/video kapsam dışı kararı, "model ≠
  ölçüm" ilkesi.
- **03 — zayıfladı / eskidi:** MacroFactor kartı (Workouts, AI kayıt, saat
  eksik); fotoğraf kalorisi kararı fazla kesin; Strava/Todoist yerine
  kategori içi rakip gerekir. **Önerilen düzeltme:** MacroFactor Workouts ve
  Bevel kartı eklensin; "Platform yetenekleri" bölümü (LA, saat, HK/HC)
  açılsın; fotoğraf kararı "metin/ses önce, fotoğraf sonra, düzenlenebilir
  tahmin" olarak yeniden yazılsın; S06 kaynağı Hevy yardım makalesiyle
  değiştirilsin.
- **08_FEATURE_OPPORTUNITIES / 09_IMPLEMENTATION_ROADMAP (okunmadı, hipotez):**
  Android etkileşimli seans bildirimi ve Türkçe metinle AI öğün kaydı
  listede yoksa eklenmeli; saat uygulaması ayrı, sonraki fazda.
- **12_FINAL_RECOMMENDATION:** "premium" konumunun kıyas emsali Hevy/Strong
  değil MacroFactor (ücretsiz katmansız, 7 gün deneme) olarak yazılmalı.
  Monetizasyon kararı ertelenmiş; bu rapor kararı yeniden açmıyor, yalnız
  fiyat zemini veriyor.
