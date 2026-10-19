# 03 — Rakip araştırması ve FitPack için çıkarımlar

> **Derin inceleme notu (18 Ekim 2026):** Bu raporun düzeltilen iddiaları için bkz. [review/00_SYNTHESIS.md](review/00_SYNTHESIS.md) "Diğer raporlara düzeltmeler".

Araştırma tarihi: **18 Ekim 2026**. Kapsam: Strong, Hevy, Fitbod, MyFitnessPal, MacroFactor, Nike Training Club, Strava, Gentler Streak; kategori dışı referans Todoist. Üretim kodu değiştirilmedi.

## Karar özeti

FitPack için en güçlü yön, **salonda hızlı kayıt + beslenmede anlaşılır günlük + haftada bir anlamlı değerlendirme** birleşimidir. Strong ve Hevy'den set kaydının işlevsel ekonomisi; MacroFactor'dan sayıların açıklanması ve yargılamayan dil; Gentler Streak'ten dinlenmeyi başarısızlık saymayan motivasyon; Todoist'ten bağlama göre sıradaki eylemi öne çıkarma öğrenilmeli. Her ürünün bütün gezinmesini birleştirmek, FitPack'i daha karmaşık yapar.

Bu bir kullanıcı araştırması veya rakip uygulamalar üzerinde cihaz testi değildir. Resmî yardım sayfaları gerçek ürün davranışını belgelese de davranışın bu cihazda, bölgede ve hesap planında aynı olduğunu kanıtlamaz. Rakiplerin hızları, görev başarı oranları, erişilebilirlik uyumu ve kullanıcı tercihleri ölçülmedi. Öneriler test edilecek tasarım hipotezleridir.

Güncel iki önemli fark: MyFitnessPal 2026'da günlük kaydını açılış ekranı yapan **Today** modeline geçti; Hevy'nin güncel resmî kılavuzu **Trainer** kişiselleştirilmiş programlarını da anlatıyor. Eski karşılaştırmaların “MyFitnessPal dashboard” ve “Hevy yalnız günlük” kabulleri kullanılmamalı. [MyFitnessPal değişiklik açıklaması](https://support.myfitnesspal.com/hc/en-us/articles/45276346234637-New-App-Experience-Today-Tab-and-More), [Hevy 2026 kılavuzu](https://help.hevyapp.com/hc/en-us/articles/33106320824727-Everything-You-Need-to-Know-About-the-Hevy-App-2026-Features-Guide).

## Kanıt yöntemi

- **B — Belgelenmiş / documented:** üreticinin yardım merkezinde açıkladığı işleyiş. Güven, bu işleyişin belgelendiği konusunda yüksektir; deneyimin iyi olduğu konusunda değildir.
- **P — Pazarlamada belgelenmiş:** üretici sayfasında sunulan özellik veya vaat. Bağımsız performans kanıtı değildir.
- **Ç — Çıkarım / inference:** tasarım değerlendirmesi veya FitPack'e aktarım hipotezi.
- **G — Doğrudan gözlem / observed:** bu alt araştırmada rakip uygulamalar için yoktur. Web sayfasının okunması, uygulamanın kullanılması sayılmaz.
- **Bilinmiyor:** kaynakta yeterli bilgi yoktur veya cihaz testi gerekir. Özelliğin bulunmadığı anlamına gelmez.

Tam kaynak günlüğü: [workstreams/competitive-sources.md](workstreams/competitive-sources.md). Burada fiyat kıyaslaması yapılmadı: bölge, vergi, kampanya ve mağaza planı aynı değil. “Premium kalite”, ücretli olmakla eş tutulmadı.

## Karşılaştırma matrisi

| Ürün | Belgelenen ana iş | Ana etkileşim | İlerleme yaklaşımı | Kişiselleştirme | FitPack'e aktarılacak ilke | Kopyalanmaması gereken varsayım |
|---|---|---|---|---|---|---|
| Strong | Kuvvet antrenmanı günlüğü | Şablon → set → otomatik mola | En iyi set, tahmini tek tekrar maksimumu, ölçüm | Şablon ve hareket molası | Kayıt akışını kesmeden bağlamsal araç | İleri grafiğin her kullanıcı için açılış değeri olması |
| Hevy | Günlük + program + sosyal | Rutin veya boş seans, önceki değer | Rekor, hacim, sıklık, rapor | Rutinler ve Pro Trainer | Önceki performansı kararın yanında göster | Sosyal akışın pilot kullanıcı için şart olması |
| Fitbod | Uyarlanan antrenman önerisi | Önerilen planı düzenle ve uygula | Güç ve kas toparlanması modeli | Hedef, deneyim, ekipman, süre | Öneriyi açıklanabilir ve değiştirilebilir tut | Tahmini toparlanmayı ölçülmüş gerçek gibi sunmak |
| MyFitnessPal | Günlük beslenme kaydı | Today → öğünde Log / hızlı ekleme | Kalori, makro, günlük/haftalık görünüm | Besin panosu seçenekleri | Sık işin doğrudan ana giriş olması | Tek bir ikonun bütün kayıt ihtiyaçlarını açıklaması |
| MacroFactor | Beslenme kaydı ve uyarlanan hedef | Kayıt + hedef/harcama karşılaştırması | Trend ve dönem bağlamı | Pano görünümü, makro programı | “Ne oldu?” ile “ne anlama geliyor?”u bağla | Veri yeterliliği olmadan kesin enerji yorumu |
| Nike Training Club | Rehberli egzersiz içeriği | Program/seans seçimi ve takip | Program üzerinden süreklilik | Hedef ve içerik seçimi | İlk antrenmana hazırlığı kolaylaştır | Aktif kayıt ekranında editoryal içerik yoğunluğu |
| Strava | Aktivite kaydı ve topluluk | Kaydet, incele, karşılaştır | Zaman içinde gelişim, hedef, segment | Geçmişe dayalı içgörü ve rota | Özetin kişisel karşılaştırmaya bağlanması | Rekabetin herkes için doğru motivasyon olması |
| Gentler Streak | Aktivite ve dinlenme dengesi | Activity Path → günlük öneri | Önerilen aralık içinde zaman çizgisi | Geçmiş aktivite ve durum | Dinlenmeyi de geçerli durum olarak göster | FitPack'te bulunmayan sağlık sinyallerini var saymak |
| Todoist | Görev yakalama ve sıralama | Today + Quick Add | Tamamlanacak işler, zaman görünümü | Filtreler, projeler, tarihler | Gereksinim ortaya çıkınca ayrıntı aç | Türkçe doğal dilin otomatik çözüldüğünü varsaymak |

Matris bir kalite sıralaması değildir. Her satırın kaynakları aşağıdaki ürün kartlarında bulunur. Ekran sayısı ve dokunuş sayısı karşılaştırılmadı; cihaz üzerinde doğrulama yoktur.

## Ürün kartları

### Strong

Kaynak: [ürün sayfası](https://www.strong.app/), [mola yardım sayfası](https://help.strongapp.io/article/231-rest-timer), [şablon yardım sayfası](https://help.strongapp.io/article/105-about-templates).

- **Görsel kimlik:** “antrenman defteri” ve sadelik ürünün açık konumlandırmasıdır (P). Güncel uygulama tipografi, renk ve kontrast ölçümleri bilinmiyor.
- **Gezinme / ana ekran:** Start Workout ve History sekmeleri şablon yardımında adlandırılır (B); ilk açılışın tam sekme sırası bilinmiyor.
- **İlk kullanım:** örnek şablonlar bulunur (B); kayıt/izin adımlarının sayısı bilinmiyor.
- **Ana etkileşim / hiyerarşi:** şablon tekrar kullanılır; set bitince mola otomatik başlar, küçük sayaç tam ekrana genişletilebilir (B). İkincil araç ihtiyaç anında büyür (Ç).
- **Aktivite / ilerleme:** ürün en iyi setler, tahmini tek tekrar maksimumu ve vücut ölçümlerini tanıtır (P).
- **Kişiselleştirme:** hareket bazında normal ve ısınma seti molaları ayarlanabilir (B).
- **Mikroetkileşim:** otomatik mola ve genişletme belgeli; animasyon süresi ve dokunsal geri bildirim bilinmiyor.
- **Premium:** ücretsiz üç şablon, Pro'da sınırsız şablon belgeli (B).
- **Erişilebilirlik:** ekran okuyucu ve büyük metin davranışı bilinmiyor; koyu tema tek başına erişilebilirlik kanıtı değildir.
- **Motivasyon / zayıflık:** kendi geçmişini izleme konumlandırması güçlü (Ç); ilk kez program seçen kişinin karar desteği bu kaynaklarla değerlendirilemez.

### Hevy

Kaynak: [kayıt akışı](https://www.hevyapp.com/features/track-workouts/), [2026 kılavuzu](https://help.hevyapp.com/hc/en-us/articles/33106320824727-Everything-You-Need-to-Know-About-the-Hevy-App-2026-Features-Guide).

- **Görsel kimlik:** resmî anlatım eylem düğmesini mavi olarak tanımlar (B); tüm güncel tema ölçümleri bilinmiyor.
- **Gezinme / ana ekran:** Workout sekmesinde rutin ve boş seans başlangıcı; kişiselleştirilmiş sosyal akış da belgeli (B). Hesaba göre açılış sırası bilinmiyor.
- **İlk kullanım:** hazır program, deneyim/hedef/ekipman filtreleri mevcut (B); ilk kurulum adım sayısı bilinmiyor.
- **Ana etkileşim / hiyerarşi:** önceki performans set girişinin yanında; set onayı molayı başlatır (B).
- **Aktivite / ilerleme:** rekor, hacim, sıklık ve kas dağılımı (B).
- **Kişiselleştirme:** rutinler; Pro Trainer hedef ve geçmiş üzerinden program önerir (B).
- **Mikroetkileşim:** set anında kişisel rekor bildirimi belgeli; hareket süresi bilinmiyor.
- **Premium:** ücretsiz dört rutin ve üç aylık istatistik geçmişi; Pro daha geniş sınırlar ve rehberlik sunar (B).
- **Erişilebilirlik:** dokunma hedefi, ekran okuyucu ve hareket azaltma bilinmiyor.
- **Motivasyon / zayıflık:** sosyal etkileşim ve kişisel rekor iki ayrı döngüdür (B); bunların birlikte sunulması dikkat maliyeti doğurabilir (Ç), kullanılabilirlik kusuru olarak doğrulanmadı.

### Fitbod

Kaynak: [çalışma mantığı](https://help.fitbod.me/hc/en-us/sections/360001078993-Understanding-Fitbod-How-It-Works), [Gym Profile](https://fitbod.me/blog/your-gym-profile/), [sık sorular](https://fitbod.me/faqs/).

- **Görsel kimlik:** bu taramada güncel ekran görselleri piksel düzeyinde incelenmedi; renk/tipografi değerlendirmesi bilinmiyor.
- **Gezinme / ana ekran:** My Plan tercihleri ve Body kas haritası belgeli (B); bütün alt sekmelerin sırası bilinmiyor.
- **İlk kullanım:** hedef, deneyim, ekipman ve tercih girdileri planı etkiler (B). Soru sayısı veya terk oranı bilinmiyor.
- **Ana etkileşim / hiyerarşi:** set/tekrar/ağırlık önerilir; hareket değiştirme veya öneriyi düzeltme mümkündür (B).
- **Aktivite / ilerleme:** tahmini güç ve toparlanma yüzdesi model çıktılarıdır (B); doğrudan fizyolojik ölçüm sayılmaz.
- **Kişiselleştirme:** kayıt geçmişi, süre, ekipman ve geri bildirim kullanılır (B).
- **Mikroetkileşim:** planın yeniden oluşturulması belgeli; geçiş, onay ve geri alma hareketleri bilinmiyor.
- **Premium:** üyelik modeli resmî sık sorularda anlatılır (P); yerel güncel fiyat ve deneme akışı doğrulanmadı.
- **Erişilebilirlik:** kas haritasının metin alternatifi, büyük metin ve ekran okuyucu bilinmiyor.
- **Motivasyon / zayıflık:** hazır öneri karar yükünü azaltabilir (Ç). Açıklama olmadan otomatik değişen plan güven sorunu yaratabilir (Ç). FitPack'e algoritmanın tümünü taşımak büyük kapsam ve sağlık yorumu riski taşır.

### MyFitnessPal

Kaynak: [2026 Today değişikliği](https://support.myfitnesspal.com/hc/en-us/articles/45276346234637-New-App-Experience-Today-Tab-and-More), [Today kullanım kılavuzu](https://support.myfitnesspal.com/hc/en-us/articles/39985611667341-Your-Today-tab), [Premium](https://support.myfitnesspal.com/hc/en-us/articles/360032625951-MyFitnessPal-Premium-features).

- **Görsel kimlik:** mavi ekleme kontrolü belgeli; güncel tüm tema/kontrast ölçümleri bilinmiyor.
- **Gezinme / ana ekran:** Today günlük kaydını açılışa getirir; Progress ayrı inceleme alanıdır (B).
- **İlk kullanım:** bu kaynaklar ilk kayıt soru akışını anlatmaz; bilinmiyor.
- **Ana etkileşim / hiyerarşi:** öğün yanından Log doğrudan son/sık yiyeceklere veya aramaya götürür; üstte kalori ve makrolar bulunur (B).
- **Aktivite / ilerleme:** su, adım, egzersiz ve kilo günlükle ilişkilidir (B).
- **Kişiselleştirme:** ücretli besin panosu seçenekleri belgeli (B).
- **Mikroetkileşim:** önceki öğünü kaydırarak getirme belgeli; animasyon ve dokunsal geri bildirim bilinmiyor.
- **Premium:** bazı kayıt araçları ve makro görünüm seçenekleri ücretlidir (B); kullanılabilirlik kalitesi buradan türetilemez.
- **Erişilebilirlik:** kaydırmanın keşfi, ekran okuyucu alternatifi ve hedef boyutları test edilmedi.
- **Motivasyon / zayıflık:** kayıt serisi görünümü mevcut (B); serinin davranış etkisi ölçülmedi. iOS ve Android silme etkileşimleri farklı belgelenir; FitPack aynı işin platforma uygun fakat anlaşılır alternatifini korumalı (Ç).

### MacroFactor

Kaynak: [pano kılavuzu](https://help.macrofactorapp.com/dashboard/consistency/), [enerji dengesi yorumu](https://help.macrofactorapp.com/en/articles/224-interpreting-the-energy-balance-widget), [ürün ve üyelik](https://macrofactor.com/macrofactor/).

- **Görsel kimlik:** nicel veri ve çoklu pano görünümü belgeli (B); güncel renk, yazı ve kontrast ölçümleri bilinmiyor.
- **Gezinme / ana ekran:** üst pano, günlük/haftalık beslenmeyi farklı merceklerden gösterir (B); tam alt sekme sırası bilinmiyor.
- **İlk kullanım:** bu incelemede soru akışı denenmedi; bilinmiyor.
- **Ana etkileşim / hiyerarşi:** Nutrition & Targets, Energy Balance ve Food Log Focus görünüm alternatifleridir (B).
- **Aktivite / ilerleme:** hedefe uyum ile tahmini harcamaya göre enerji dengesi ayrılır; dönemleri farklı hesaplanan değerler aynı sayı gibi yorumlanmaz (B).
- **Kişiselleştirme:** makro programı ve pano düzenlemesi mevcut (B).
- **Mikroetkileşim:** bu kaynaklardan hareket süreleri veya dokunsal geri bildirim belirlenemez.
- **Premium:** reklamsız, ücretli ürün ve ücretsiz deneme sunumu belgeli (P); Türk mağaza fiyatı doğrulanmadı.
- **Erişilebilirlik:** grafiklerin ekran okuyucu özeti ve büyük metin davranışı bilinmiyor.
- **Motivasyon / zayıflık:** uyumdan bağımsız, yargılamayan yaklaşım üreticinin açık ilkesidir (B). Gelişmiş enerji kavramlarını ilk ekranda öğretme ihtiyacı bilişsel yük yaratabilir (Ç); bu bir test bulgusu değildir.

### Nike Training Club

Kaynak: [resmî ürün sayfası](https://www.nike.com/ntc-app), [Nike Kanada ücretsiz üyelik açıklaması](https://www.nike.com/ca/ntc-app?uid=308a89db7f6cfs16).

- **Görsel kimlik:** resmî sayfa eğitmenler, antrenman içeriği ve fotoğraf anlatımıyla kuruludur (P); uygulama tipografi/kontrast denetimi yapılmadı.
- **Gezinme / ana ekran:** antrenman, program ve uzman içeriği tanıtılır (P); güncel uygulama açılış sekmesi bilinmiyor.
- **İlk kullanım:** başlangıç seviyesini karşılayan rehberli içerik konumlandırması vardır (P); kurulum soru sayısı bilinmiyor.
- **Ana etkileşim / hiyerarşi:** program/seans seçimi ve takip; ileriye planlama ve başka ekrana yansıtma tanıtılır (P).
- **Aktivite / ilerleme:** ilerleyen programlar belgeli (P); güç günlüğünün ayrıntısı bu kaynaklarla belirlenemez.
- **Kişiselleştirme:** hedefe ve kendi temposuna uygun içerik seçme vurgusu var (P); otomatik plan algoritması doğrulanmadı.
- **Mikroetkileşim:** canlı kayıt ve hareket zamanlaması bilinmiyor.
- **Premium:** Kanada sayfası eski Premium içeriklerin Nike üyelerine ücretsiz olduğunu söyler; bölgesel eşitlik varsayılmadı.
- **Erişilebilirlik:** videolarda altyazı kapsamı, ekran okuyucu ve çevrimdışı davranış bilinmiyor.
- **Motivasyon / zayıflık:** insan rehberliği yaklaşımı güven verebilir (Ç); kapsamlı içerik üretimi FitPack'in tek kullanıcı pilotunda pahalı ve temel kayıt sorunlarına dolaylıdır (Ç).

### Strava

Kaynak: [özellikler](https://www.strava.com/features), [üyelik yardım sayfası](https://support.strava.com/en-us/articles/15402044-what-features-are-included-in-a-strava-subscription).

- **Görsel kimlik:** bu inceleme resmî metin ve özellik yapısına dayanır; güncel uygulama görsel token'ları bilinmiyor.
- **Gezinme / ana ekran:** kayıt, topluluk, antrenman ve keşif ürünün ana alanlarıdır (P); bütün alt sekmelerin güncel sırası bilinmiyor.
- **İlk kullanım:** hesap ve izin adımlarının sayısı bilinmiyor.
- **Ana etkileşim / hiyerarşi:** aktivite kaydı, rota ve aktivite sonrasında değerlendirme tanıtılır (P).
- **Aktivite / ilerleme:** geçmişle kıyaslama, özel hedefler, segmentler ve ileri analizler belgeli (B/P).
- **Kişiselleştirme:** geçmişe dayalı içgörü ve kişiselleştirilmiş rota önerileri sunulur (P); doğruluk bu araştırmada sınanmadı.
- **Mikroetkileşim:** sosyal etkileşim bulunması, belirli bir animasyon kalitesini kanıtlamaz; hareket/dokunsal davranış bilinmiyor.
- **Premium:** kayıt ve topluluk ile ileri hedef/analiz/rota yetenekleri arasında plan ayrımı belgeli (B).
- **Erişilebilirlik:** harita ve grafiklerin metin alternatifi bilinmiyor.
- **Motivasyon / zayıflık:** kişisel rekor ve topluluk rekabeti iki motivasyon yoludur (P); rekabetten hoşlanmayan kullanıcının deneyimi test edilmedi. FitPack sosyal ağ eklemeden kişisel karşılaştırmadan yararlanabilir (Ç).

### Gentler Streak

Kaynak: [Activity Path yorumu](https://docs.gentler.app/understanding-your-activity-path/interpret-the-activity-path), [günlük öneri akışı](https://docs.gentler.app/daily-workout-recommendations/how-to-find-and-understand-your-daily-workout-recommendation), [2025 görsel/deneyim güncellemesi](https://gentlerstories.com/newsroom/20250911gentlerstreakios26), [ürün sayfası](https://gentlerstories.com/gentlerstreak).

- **Görsel kimlik:** yeşil aralık ve beyaz aktivite çizgisi resmî olarak açıklanır (B); yumuşak arayüz ve Liquid Glass üreticinin tasarım anlatımıdır (P).
- **Gezinme / ana ekran:** Streak sekmesinde Activity Path merkezîdir; günlük öneriler aşağıdadır (B).
- **İlk kullanım:** sağlık verisiyle kişiselleştirme konumlandırılır (P); bütün izin sırası bilinmiyor.
- **Ana etkileşim / hiyerarşi:** öneriye dokunma Go Gentler ayrıntısını açar (B).
- **Aktivite / ilerleme:** aktivite, tek hedefe doğru dolan halka yerine önerilen aralıkta gösterilir (B).
- **Kişiselleştirme:** aktivite geçmişi; ara, hasta ve sakat durumları tanıtılır (B/P).
- **Mikroetkileşim:** yumuşak geçiş iddiası var (P); milisaniye ve kare hızı bilinmiyor.
- **Premium:** ücretsiz görünümde ücretli özellik etiketleri belgeli (B); güncel yerel fiyat bilinmiyor.
- **Erişilebilirlik:** çizgi/aralığın renk dışı semantiği, ekran okuyucu ve büyük metin test edilmedi.
- **Motivasyon / zayıflık:** dinlenmenin seriyi sıfırlamaması açık konumlandırmadır (P). Sağlık sinyalleri ve model sınırlarını açıklamadan bu grafiği kopyalamak FitPack'te sahte kesinlik doğurabilir (Ç).

### Todoist — kategori dışı referans

Kaynak: [ürün](https://www.todoist.com/), [Quick Add](https://www.todoist.com/help/todoist/features/use-task-quick-add-in-todoist-va4Lhpzz), [2026 değişiklik günlüğü](https://www.todoist.com/help/todoist/product-updates/2026-changelog-HD3jJAtLd?rl_entry=e75f0d5e2017).

- **Görsel kimlik:** ürün anlatımı sade görev listesi ve zihinsel açıklık üzerinedir (P); uygulama görsel ölçümleri bilinmiyor.
- **Gezinme / ana ekran:** Today, Upcoming ve filtreler görev bağlamını ayırır (B/P).
- **İlk kullanım:** şablonlar başlangıç desteğidir (P); kayıt akışı denenmedi.
- **Ana etkileşim / hiyerarşi:** Quick Add önce yazmayı açar; ayrıntı eylemleri yazmaya başlayınca belirir (B).
- **Aktivite / ilerleme:** görev ve takvim modeli; fitness ilerleme göstergesi değildir.
- **Kişiselleştirme:** proje, filtre, tarih ve öncelik (B).
- **Mikroetkileşim:** dinamik ekleme ve kademeli açılan ayrıntı belgeli; hareket süresi bilinmiyor.
- **Premium:** Beginner, Pro ve Business katmanları kaynakta görülür; ayrıntılı fiyat karşılaştırılmadı.
- **Erişilebilirlik:** klavye yolları belgeli; mobil ekran okuyucu ve büyük metin kalitesi bilinmiyor.
- **Motivasyon / zayıflık:** sıradaki işin görünür olması FitPack'e aktarılabilir (Ç). Doğal dil tarih girişinin Türkçeyi desteklemediği resmî olarak belirtilir (B); bu yüzden Türkçe yemek/antrenman anlama yeteneği varmış gibi kopyalanamaz.

## Ekranlara göre doğru referans

| FitPack ekranı | İncelenecek referans | Alınacak ilke | Sınır / kaçınılacak maliyet |
|---|---|---|---|
| Ana sayfa | Todoist Today, MyFitnessPal Today | Sık işi görünür, ayrıntıyı erişilebilir tut | Rakip gezinmesini aynen taşıma; FitPack'te bağlamsal kart zaten var |
| Aktif seans | Strong mola; Hevy önceki değer | Birincil set eylemi + ikincil açılabilir mola | Ekranı yalnız tek hareketle kilitleme; superset ve sıra dışı akış korunmalı |
| Antrenman listesi / rutin | Strong şablon; Hevy rutin | Plan ile tamamlanmış kaydı kavramsal olarak ayır | Kullanıcının yaptığı seansı şablon düzenlemesiyle değiştirme |
| Beslenme özeti | MyFitnessPal Today; MacroFactor pano | Tüketilen/hedef ve gram etiketleri + kayıt girişi | Tek toplam “sağlık puanı” oluşturma |
| Yiyecek seçimi | MyFitnessPal son/sık yiyecek; Todoist Quick Add | Geçmiş kullanımı öne getir, ayrıntıyı gerektiğinde aç | Otomatik yiyecek tanımayı doğrulanmış besin değeri sayma |
| İlerleme / kilo | MacroFactor trend ve enerji ayrımı | Soru → dönem → ölçüm → kısa yorum | Verisiz grafiğe sıfır çizgisi veya kesin sağlık hükmü koyma |
| Haftalık değerlendirme | MacroFactor dönem; Gentler süreklilik | Kayıt kapsamını ve dinlenme bağlamını göster | Her eksik kaydı başarısızlık sayma |
| İlk kullanım | Hevy hazır program; Nike rehberlik | İlk yararlı eyleme bağlanan sınırlı seçim | İçerik kataloğunu uzun tanıtım turuna çevirme |
| Profil / ayarlar | Gentler ücretli etiket; Fitbod tercih | Ayarın etkisini, veri/öneri sınırını açıklama | Ayar arkasına kritik aktif seans kontrolü saklama |
| Seans özeti | Hevy özet; Strava kişisel kıyas | Önce kayıt güvencesi, sonra kendi geçmişi | Paylaşımı bitirmenin zorunlu adımı yapma |

## Aktarılabilir bulgular

Aşağıdaki `Cxx` kayıtları rakipte belgelenen davranış ile FitPack hipotezini ayırır. “Problem” aksi söylenmedikçe **muhtemel kullanıcı problemi**dir; FitPack'te gözlemlenmiş kusur olarak okunmamalı. FitPack mevcut durum doğrulaması ana denetim raporuna aittir.

**C01 | documented → inference** | Kanıt: [Strong mola](https://help.strongapp.io/article/231-rest-timer). **Problem:** mola ayrıntısı set girişini örterse tekrar eden iş kesilir. **Hipotez:** küçük durum + isteğe bağlı büyük sayaç aynı bilgiyi daha az engelle sunar. **Çözüm:** FitPack mevcut molasını tek kalıcı satırda durum, kalan süre ve Atla ile değerlendir; ayrıntı dokununca açılsın. **Fayda:** sonraki seti bulma süresi azalabilir. **Ödün:** satır ekran alanı tüketir. **Uygulanabilirlik:** orta; mevcut sayaç/arka plan yaşam döngüsü korunmalı. **Doğrulama:** 3 hareket, 9 set görevinde mola sırasında sonraki seti bulma; çift sayaç/arka plan dönüşü kontrolü.

**C02 | documented → inference** | Kanıt: [Hevy kayıt](https://www.hevyapp.com/features/track-workouts/). **Problem:** önceki ağırlığı hatırlamak seans içinde ayrı inceleme gerektirebilir. **Hipotez:** son değer aynı setin bağlamında görünürse hatırlama yükü azalır. **Çözüm:** FitPack'te mevcut önceki değerlerin kapsam etiketini netleştir: “Bu rutinde son” veya “Son kayıt”. **Fayda:** güvenli karşılaştırma. **Ödün:** dar ekranda yoğunluk. **Uygulanabilirlik:** küçük/orta; sorgu semantiği doğrulanır. **Doğrulama:** aynı hareketi iki rutinde yapan kullanıcı hangi kaydın gösterildiğini doğru açıklayabilsin.

**C03 | documented → inference** | Kanıt: [MyFitnessPal 2026 değişikliği](https://support.myfitnesspal.com/hc/en-us/articles/45276346234637-New-App-Experience-Today-Tab-and-More). **Problem:** açılış ekranı sık eylemin önüne bir gezinme adımı koyabilir. **Hipotez:** kullanıcının sonraki işi ilk bakışta ayırt edilirse başlangıç hızlanır. **Çözüm:** FitPack'in mevcut `_PrimaryActionCard` durumlarını rafine et; seans sürüyorsa Devam et, planlıysa Başlat, ilk haftaysa programı gözden geçir. **Fayda:** daha net yönelim. **Ödün:** beslenme ağırlıklı kullanıcı için öncelik farklı olabilir. **Uygulanabilirlik:** küçük/orta, mevcut durum modeli üzerine. **Doğrulama:** yeni/eski, seanslı/seanssız dört durumda ilk eylemi bulma süresi.

**C04 | documented → inference** | Kanıt: [MyFitnessPal Today](https://support.myfitnesspal.com/hc/en-us/articles/39985611667341-Your-Today-tab). **Problem:** her öğünde aynı yiyeceği yeniden aramak tekrar maliyeti yaratır. **Hipotez:** son kullanılan öğünleri önermek arama ihtiyacını azaltır. **Çözüm:** FitPack mevcut kopyalama akışının görünürlüğünü ölç; ilgili öğünde son kayıtları açık bir eylemle sun, kopyalama sonrası porsiyonu düzenlenebilir tut. **Fayda:** günlük kayıt süresi azalabilir. **Ödün:** eski miktarı kontrolsüz kabul riski. **Uygulanabilirlik:** orta; mevcut kopyalama/veri bütünlüğü korunur. **Doğrulama:** önceki gün kahvaltısını farklı porsiyonla kaydetme, yanlış tarih ve çift kayıt oranı.

**C05 | documented → inference** | Kanıt: [MacroFactor enerji dengesi](https://help.macrofactorapp.com/en/articles/224-interpreting-the-energy-balance-widget). **Problem:** hedefi aşmak ile kilo yönüne göre enerji dengesi aynı hüküm gibi algılanabilir. **Hipotez:** hesap kaynağı ve dönem ayrı açıklanınca kullanıcı doğru yorumlar. **Çözüm:** FitPack mevcut trend/harcama ekranında “tahmini”, tarih aralığı ve yeterli kayıt koşulu görünür olsun. **Fayda:** güven ve yorum doğruluğu. **Ödün:** açıklama alanı gerekir. **Uygulanabilirlik:** orta; hesap değişmeden sunum yapılabilir, hesap değişirse ayrı tasarım gerekir. **Doğrulama:** “Bu sayı ölçüm mü tahmin mi?” ve “hangi günler?” sorularında doğru yanıt.

**C06 | documented → inference** | Kanıt: [Gentler Activity Path](https://docs.gentler.app/understanding-your-activity-path/interpret-the-activity-path). **Problem:** her metriği dolan halka yapmak yön, zaman ve belirsizliği kaybettirebilir. **Hipotez:** soruya göre gösterim seçmek anlamayı kolaylaştırır. **Çözüm:** FitPack'te günlük tüketim için etiketli çubuk/rakam, haftalık plan için N/hedef, kilo için zaman serisi kullan; beslenme halkası A/B prototipte değerlendirilsin. **Fayda:** daha az görsel öğrenme. **Ödün:** tek biçimli marka motifi azalır. **Uygulanabilirlik:** orta. **Doğrulama:** 5 saniyede kalan miktar, hafta tamamlanması ve kilo yönünü ayrı okutma.

**C07 | documented → inference** | Kanıt: [Gentler ürün](https://gentlerstories.com/gentlerstreak). **Problem:** dinlenmeyi “eksik gün” diliyle anlatmak planı takip eden kullanıcıyı cezalandırabilir. **Hipotez:** planlanan dinlenme ile kaçan planı ayırmak baskıyı azaltır. **Çözüm:** FitPack'in zaten haftalık hedef bazlı serisini koru; dinlenme gününü nötr açıklamayla sun; fazla antrenmanı teşvik eden kutlama ekleme. **Fayda:** sürdürülebilirlik. **Ödün:** günlük oyunlaştırma daha az çarpıcıdır. **Uygulanabilirlik:** küçük. **Doğrulama:** hafta içinde dinlenen kullanıcı serinin neden korunduğunu açıklayabilsin; iki hafta nitel günlük.

**C08 | documented → inference** | Kanıt: [Fitbod çalışma mantığı](https://help.fitbod.me/hc/en-us/sections/360001078993-Understanding-Fitbod-How-It-Works). **Problem:** otomatik önerinin nedeni bilinmezse güven veya kontrol kaybolabilir. **Hipotez:** öneri + neden + değiştirme birlikteyse kullanıcı bilinçli karar verir. **Çözüm:** FitPack mevcut ilerleme önerisinde dayanak seansını ve Algılanan Zorluk (Rating of Perceived Exertion, RPE) etkisini gerektiğinde aç; öneriyi zorunlu kılma. **Fayda:** açıklanabilirlik. **Ödün:** açıklama geliştirme maliyeti. **Uygulanabilirlik:** orta, yeni antrenman motoru önerilmiyor. **Doğrulama:** öneriyi kabul/red etme ve nedenini anlama görevi.

**C09 | documented → inference** | Kanıt: [Todoist Quick Add](https://www.todoist.com/help/todoist/features/use-task-quick-add-in-todoist-va4Lhpzz). **Problem:** bütün ileri seçenekler başlangıçta görünürse basit kayıt formu ağırlaşır. **Hipotez:** ilk gerekli alanlar, sonra açık “Diğer seçenekler” daha hızlıdır. **Çözüm:** yiyecek/ölçüm panellerinde zorunlu alanları öncele; gizlenen alan sayısını ve kontrolünü görünür tut. **Fayda:** daha az karar. **Ödün:** uzman için ek açma hareketi. **Uygulanabilirlik:** küçük/orta. **Doğrulama:** yeni ve deneyimli kullanıcıda basit/ileri görev süreleri birlikte ölçülmeli.

**C10 | documented → inference** | Kanıt: [Strava üyelik özellikleri](https://support.strava.com/en-us/articles/15402044-what-features-are-included-in-a-strava-subscription). **Problem:** bağlamsız toplamlar gelişim sorusunu yanıtlamaz. **Hipotez:** aynı hareket ve eş dönem kıyası daha eyleme dönüktür. **Çözüm:** FitPack seans özetinde önce kaydedildi güvencesi, sonra karşılaştırılabilir önceki seans ve gerekirse rekor; kıyas mümkün değilse açık ilk kayıt durumu. **Fayda:** anlamlı kapanış. **Ödün:** eşleştirme semantiği karmaşıklaşır. **Uygulanabilirlik:** orta. **Doğrulama:** değişen hareket sırası, eksik set, ilk seans ve geçmiş düzenleme senaryoları.

**C11 | documented → inference** | Kanıt: [Gentler 2025 güncellemesi](https://gentlerstories.com/newsroom/20250911gentlerstreakios26). **Problem:** kullanıcı ücretli özelliği işlem sonunda öğrenirse boşa emek hisseder. **Hipotez:** açık plan etiketi beklentiyi düzeltir. **Çözüm:** FitPack premium kapsamı kararlaştırılınca giriş noktasında sakin etiket ve anlaşılır kapsam göster; aktif set/yemek kaydını satışla bölme. **Fayda:** güven. **Ödün:** etiket yoğunluğu. **Uygulanabilirlik:** küçük; ürün kapsamı kararı gerekir. **Doğrulama:** kullanıcının hangi özelliğin dahil olduğunu işlem öncesi doğru tahmin etmesi.

**C12 | documented → inference** | Kanıt: [Nike programları](https://www.nike.com/ntc-app), [Hevy 2026 kılavuzu](https://help.hevyapp.com/hc/en-us/articles/33106320824727-Everything-You-Need-to-Know-About-the-Hevy-App-2026-Features-Guide). **Problem:** yeni kullanıcı program seçiminin ilk gerçek antrenmana nasıl bağlandığını anlamayabilir. **Hipotez:** tek öneri ve neden, bütün kataloğa göre daha kolay başlangıç sağlar. **Çözüm:** FitPack'in mevcut önerilen programını süre/ekipman/gün bilgisiyle anlaşılır kıl; Kendim kuracağım seçeneğini koru. **Fayda:** ilk değer anı. **Ödün:** öneri yanlış kişiye fazla otoriter görünebilir. **Uygulanabilirlik:** küçük/orta, mevcut kurulum üzerine. **Doğrulama:** deneyimsiz kullanıcı öneriyi neden aldığını ve nasıl değiştireceğini anlatabilsin.

## Önemli önerilerin puanları

Bütün puanlar uzman tahminidir, ölçülmüş araştırma sonucu değildir. Etki, kullanılabilirlik, görsel kalite, sıklık, farklılaşma ve kanıt güveninde **1 düşük, 5 yüksek**. Karmaşıklık ve teknik riskte **1 düşük/kolay, 5 yüksek/zor**. Kanıt güveni, önerinin FitPack'te beklenen faydasına duyulan güvendir; rakipte özelliğin belgelenme kesinliğiyle aynı değildir. Süreler tek mobil geliştirici için tasarım kabulünden sonra odaklı iş günü aralığıdır; yayın, hesap motoru/şema değişikliği ve dış servis maliyeti dahil değildir. Toplam süre diye toplanamaz; ortak bileşenler paylaşılır.

| Kayıt | Etki | Kullanılabilirlik | Görsel | Sıklık | Farklılaşma | Karmaşıklık | Risk | Güven | Efor | Öncelik |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| C01 Mola/ana eylem ilişkisi | 5 | 5 | 3 | 5 | 3 | 3 | 3 | 4 | 3–6 gün | Faz 1 |
| C02 Önceki değer kapsamı | 4 | 4 | 2 | 5 | 3 | 2 | 2 | 4 | 1–3 gün | Faz 1 |
| C03 Bağlamsal ana kart rafinesi | 5 | 5 | 4 | 5 | 4 | 2 | 2 | 4 | 2–4 gün | Faz 1 |
| C04 Son öğün/kopyalama görünürlüğü | 5 | 5 | 3 | 5 | 3 | 3 | 3 | 4 | 3–6 gün | Faz 3 |
| C05 Tahmin ve veri kapsamı | 5 | 4 | 3 | 3 | 5 | 3 | 3 | 4 | 2–5 gün | Faz 1/3 |
| C06 Soruya göre gösterim | 4 | 4 | 4 | 5 | 4 | 3 | 2 | 3 | 3–6 gün | Faz 3 |
| C07 Dinlenme dili | 3 | 4 | 2 | 4 | 4 | 1 | 1 | 3 | 0,5–1 gün | Faz 1 |
| C08 Açıklanabilir ilerleme | 4 | 4 | 3 | 4 | 5 | 3 | 3 | 3 | 3–7 gün | Faz 4 |
| C09 Kademeli form ayrıntısı | 4 | 4 | 3 | 5 | 2 | 2 | 2 | 3 | 2–4 gün | Faz 1/3 |
| C10 Anlamlı seans kapanışı | 4 | 4 | 4 | 4 | 4 | 3 | 3 | 3 | 3–6 gün | Faz 3 |
| C11 Premium beklenti | 3 | 4 | 2 | 2 | 2 | 1 | 1 | 3 | 1–2 gün | Faz 2/4 |
| C12 Program önerisi açıklaması | 4 | 4 | 3 | 2 | 3 | 2 | 2 | 3 | 1–3 gün | Faz 1 |

Puanlardan yapay bir kesinlik üreten tek toplam hesaplanmadı. C01/C03/C04 yüksek sıklık ve akış etkisiyle, C05 güven/veri anlamı nedeniyle öne çıkar. C07 hızlı kazanımdır; mevcut doğru haftalık seri davranışı değiştirilmez. C06'nın görsel yeniliği, C01'in tekrarlayan iş sürtünmesinin önüne geçmemeli.

## Farklılaşma ve eleme kararları

**Önerilen farklılaşma hipotezi:** “Kendi planını uygula, yemeğini hızlı kaydet, haftanı neyin etkilediğini açıkça gör.” Türkçe yazılmış açıklamalar, yerel kayıtla kesintilere dayanıklılık ve antrenman/beslenme/ölçüm arasında anlamlı bağ, tek başına bir marka rengi veya halka motifinden daha savunulabilir bir ürün vaadidir. Bunun kullanıcılarca tercih edildiği henüz doğrulanmadı.

FitPack'te zaten bağlamsal ana kart, aktif seansa dönüş, haftalık seri, kişisel rekor, öğün kopyalama, trend/harcama ve asistan vardır. Bu rapor bunları yeni keşfedilmiş eksik özellik saymaz. Değer, **aynı veriyi daha az gezinmeyle anlaşılır kılma** ve mevcut doğruluğu koruma hedefindedir. Yerel kanıt: `lib/features/home/home_screen.dart:188`, `:297`, `:349`, `:453`, `:512`; proje canlı durumundaki 17 Ekim 2026 kayıtları.

Şimdi eklenmemesi önerilenler: herkese açık sosyal ağ, yarışma panosu, büyük eğitmen video kataloğu, doğrulanmamış fotoğraftan kalori, yeni toparlanma puanı, tam otomatik program motoru. Bunlar kötü özellik oldukları için değil; pilotun mevcut sık işlerine göre maliyet ve doğrulama yükleri yüksek olduğu için ilk kapsam dışında tutulmalı.

## Araştırma açıkları ve sonraki doğrulama

1. Aynı cihaz/bölgede en az Strong, Hevy ve bir beslenme ürününün eş görevlerini uygulama içinde test et: programı aç, üç set kaydet, molayı değiştir, kapat/dön, yemeği farklı porsiyonla kopyala. İzin/veri alanı ayrı tutulmalı; gerçek kişisel hesap değiştirilmemeli.
2. Rakipte dokunma sayısı, süre, başlangıç verisi, sürüm ve ücretli plan kaydedilmeden “daha hızlı” kıyası yapılmamalı.
3. Dokunma hedefleri, ekran okuyucu sırası, büyük metin, azaltılmış hareket ve açık/koyu kontrast her üründe cihazda bilinmiyor. Pazarlama ödülü veya koyu tema bu kontrolleri ikame etmez.
4. FitPack'in halka/çubuk tercihi iki eş verili prototiple ölçülmeli: miktar ve yönü doğru okuma, süre, kullanıcının açıklaması. “Güzel bulma” tek karar metriği olmamalı.
5. Yeni/deneyimli ve beslenme ağırlıklı kullanıcılar ayrı değerlendirilmeli. Samet pilotundan alınan bulgular genel pazara genellenmemeli.

Bu rapor, yeniden tasarımın uygulanması için onay değildir. Araştırmadan sonra önerilen yön ve ilk kapsam ana karar raporunda onaya sunulur.
