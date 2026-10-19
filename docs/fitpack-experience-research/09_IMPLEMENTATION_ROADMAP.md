# Uygulama yol haritası — onay bekleyen öneri

> **Derin inceleme notu (18 Ekim 2026):** Bu raporun düzeltilen iddiaları için bkz. [review/00_SYNTHESIS.md](review/00_SYNTHESIS.md) "Diğer raporlara düzeltmeler".

## Karar özeti

İlk dilim **“Temel etkileşim güveni”**: set hedefleri, öneri okunurluğu, kritik semantik etiketler, ana sayfada antrenman eyleminin önceliği, Beslenme→Hedefler doğru yönlendirme. Tam seans küçültme veya tam görsel yenileme ilk dilimde yoktur. Bu dar dilim gerçek kullanıcı görevlerini kolaylaştırır ve sonraki tasarımın güvenli temelini kurar.

Bu araştırmada uygulama kodu uygulanmadı. Aşağıdaki kapsam onaydan sonra ayrı dal ve çalışma kopyasında yürütülür. Tahminler tek Flutter geliştiricisi için inceleme/cihaz testi dahil **iş günü aralığı**, taahhüt değildir; paralel iş, mağaza yayını ve kullanıcının bekleme süresi dahil değil. Önce bir dilim bitirilir, gerçek hız görülünce sonraki tahmin güncellenir.

Veri etkisi: ilk iki faz şemasız; mevcut kayıt, taslak ve bulut protokolü korunur. İlerleyen aşama hesap/veri anlamını değiştirirse yeni tasarım belgesi ve göç kontrol listesi uygulanır. Geri dönüş: ekran düzeni önceki sürüme alınabilir; P07'nin durum sahipliği ayrı risk incelemesine tabidir.

## Fazlar ve çıkış kapıları

| Faz | İş / kapsam | Bağımlılık | Tahmin | Başlıca risk | Çıkış / doğrulama |
|---|---|---|---|---|---|
| **1 Temel kullanıcı deneyimi** | P01/02/03/05, P04 sıra, P11 kritik hareket tercihi | Milestone onayı, cihaz kilidi | 3–6 gün | Büyük hedeflerin dar ekrana sığmaması, yanlış set komutu | 320/393 TR/EN açık/koyu; klavye ve okuyucu; mevcut seans/beslenme testleri + gerçek cihaz turu |
| **2 Görsel sistem** | P06 token/bileşen galerisi; buton, giriş, satır, sheet, state; P11 ortak hareket politikası | B görsel yönünün onayı, Faz 1 sözleşmeleri | 3–5 gün | Tema ayrışması; görsel regresyon | 07 durum matrisi; kontrast/hedef denetimi; uygulama genelinde örnek ekran |
| **3 Çekirdek deneyim** | P04 tam Bugün; P07 küçült/devam ve odak+tablo; P08 besin akışı; P09/10 ilerleme | Faz 2; P07 sahiplik notu; her alt dilim ayrı kabul | 10–18 gün | Seans motoru/native yarışları; sayısal anlam kaybı | Aşağıdaki üç alt dilim; kesinti ve veri eşitliği testi; her dilimde cihaz doğrulaması |
| **4 İnce işçilik** | P11 bütün hareketler, boş/hata/başarı; P12 haftalık dil ve bildirim amacı | Çekirdek davranışlar stabil | 3–5 gün | Kozmetik işin görevi yavaşlatması, fazla hatırlatma | Azaltılmış hareket, duyusal alternatifler; rahatsızlık/sadelik pilotu; bildirim sayısı artmaz |
| **5 Doğrulama/iyileştirme** | Görev karşılaştırması, performans ve erişilebilirlik regresyonu | Baseline + her dilim sonrası ölçüm | 3–5 gün + 2 hafta gözlem | Küçük örneklemi istatistiksel kanıt sanmak | 10'daki kabul listesi, kritik görev engeli yok; bulgularla bir düzeltme turu |

Toplam 22–39 iş günü genişlik tahminidir. Sürekli beş hafta kodlamak için toplu onay istenmiyor: ilk 3–6 günlük dilim, ardından kanıta göre devam kararı. Faz 5 sona bırakılan kalite değil; faz içi doğrulamaların son toplu kontrolüdür.

## İlk dilimin kesin sınırı

### Problem ve beklenen davranış

1. Set tamamla, ±, set türü gerçek hit alanı minimum 48×48. Dar ekranda ihtiyaç varsa alanlar iki satıra geçer; sayı girişleri küçültülmez.
2. Önceki/önerilen değer normal metinde en az 4,5:1; “Öneri/Önceki” görünür etiket. Girilmiş değer ve kayda girecek değer anlaşılır; veri doldurma kuralları aynı kalır.
3. Her set kontrolü hareket, set, birim ve durumla adlandırılır; okuyucuyla bağımsız erişim. Gereksiz tekrarlı ikon anonsları temizlenir.
4. Ana sayfada devam eden antrenman/bugünün eylemi enerji kartından önce görünür; ilk hafta/haftalık kartlar bunu aşağı itmez. Mevcut plan/dinlenme/döngü mantığı korunur.
5. Beslenme “Hedefler” Profil'deki gerçek kcal/protein düzenleme alanına eriştirir. Geri dönüşte seçili gün bozulmaz.
6. Değişen bileşenlerde sistem azaltılmış hareket tercihi izlenir; onay geribildirimi hareket olmadan da görünür.

### Teknik alanlar

Öncelikle `lib/features/workout/active_session_widgets.dart`, ilgili semantik/renk tokenları, `lib/features/home/home_screen.dart`, `lib/features/nutrition/nutrition_screen.dart`; gerekirse Profil'de bölüm odağı. Yeni paylaşılan bileşen yalnız birden fazla kullanım gerekçesi varsa `shared/widgets/`. Rotalar `AppRoutes` üzerinden; çeviriler EN/TR ARB; veri erişimi DAO (Data Access Object; veri erişim nesnesi) katmanından kalır. State (durum) Riverpod düzenine uyar.

Şema ve native bildirim sözleşmesi değişmez. Paylaşılan .arb/rota dosyalarına çalışma defterindeki sahiplik/kilit kontrolüyle girilir. Mevcut seans tamamlama komutuna ikinci bir yazma yolu eklenmez. Önceki kişisel dosya `CODE_REVIEW_REPORT.md` bu çalışmanın dışındadır.

### Kabul ölçütleri

- Hedef ölçümü tüm özel hedeflerde 48×48 veya daha büyük; 320 genişlikte taşma/üst üste hedef yok.
- Öneri/odak/hata/normal metin kontrastı gerçek yüzeyde ölçülür; hedef 4,5:1 normal metin, 3:1 büyük metin ve gerekli grafik/kontrol sınırları. Pasif istisnası bilgi taşıyan öneriye uygulanmaz.
- VoiceOver ve TalkBack ile tek hareketin değerini gir, seti tamamla, geri al; kritik görev engeli yok.
- Normal yazıda 360×800 ve 393×852'de ana eylem ilk görünümde; büyük yazıda yazı ölçeği kırpılmaz, doğru sıra ve kaydırma korunur.
- Seansın DB (Database; veritabanı) sonucu ve taslağı önceki hesaplarla aynı; set kopyalama, tür, RPE (Rating of Perceived Exertion; algılanan zorluk), süre/mesafe ve undo davranışında kayıp yok.
- `flutter analyze`: 0; `flutter test`: tüm mevcut + yeni davranışı doğrulayan anlamlı testler. Yalnız görsel değişiklik için uygulamayı kopyalayan test yazılmaz; hit/semantik/regresyon testleri anlamlıdır.
- iPhone ve Samsung'da tek el/klavye kontrolü; cihaz kullanımı ve kurulum yetkisi çalışma anında defterle kontrol edilir. `flutter install` kullanılmaz.
- Kullanıcı görevlerinde başlangıç ölçümü ve son ölçüm birlikte kaydedilir; tasarım hipotezi başarısızsa düzen geri alınır/düzeltilir.

### Kapsam dışında kalanlar

Tam renk/font değişimi, üç sekmeye geçiş, yeni AI, yeni bildirim, sağlık hedefi hesap değişimi, senkron/hesap değişimi, veri göçü ve P07 seans küçültme bu ilk onayın parçası değildir. Kullanıcı kod onayı bu rapor sırasında verilmiş sayılmaz.

## Faz 3 alt dilimleri

**3A — Bugün + seans (5–9 gün):** Önce controller yaşam süresi tasarımı. Seans kimliği, timer deadline, set komutları, taslak persistence (kalıcılık), native intent/actions ve hesap değişimi tek sahipte. Sonra küçült/şerit/devam; odak görünümü + “Tümü”. Kaydet yalnız transaction başarıdan sonra özete gider; bulut beklemek kaydı engellemez. Failure: kayıt hatası, draft hatası, process kill ve eski native eylem.

**3B — Beslenme (3–5 gün):** Son kullanılan porsiyon + açık hızlı ekle; düzenle/ekle ayrımı; bağımsız barkod; mevcut kopyalama, undo ve gün tamamlandı anlamı korunur. Arama yok sonucu ile servis erişim hatası ayrımı mevcut sözleşmeyle mümkün değilse önce servis sonuç türü notu; görselde yanlış kesinlik üretilmez.

**3C — İlerleme (2–4 gün):** Dört sekmeyi koruyarak ölçüm/kuvvet/haftalık giriş; mevcut rotalara bağlan; grafikleri 12'deki sorulara göre düzenle. Mevcut trend/eşikler sessiz değişmez. Sıfır kayıt, az kayıt ve eksik günler zorunlu kabul senaryosu.

## Kilitler, geri dönüş ve kayıt

Her kod dilimi ayrı `codex/` dalında ve ayrı çalışma kopyasında yürütülür. Çeviri/rota/cihaz kilitleri başta kaydedilir. Yeni `docs/` raporları kilitsiz; ortak `PROJECT_STATE`, `NEXT_TASKS`, `README` yalnız birleşme anında güncellenir. Bu oturum kod dalı üretmediği için ortak dosyalarda yalnız araştırma paketi bağlantısı eklenmiştir; mevcut görev sırası yeniden yazılmamıştır.

Riskler [08](08_FEATURE_OPPORTUNITIES.md)'de fırsat bazında, teknik ayrıntılar [07](07_DESIGN_SYSTEM_PROPOSAL.md)'de. Her dilimde gözlem süresi, Samet'in harcadığı dakika, yeniden çalışma ve sonradan bulunan hata NEXT_TASKS kaydına gerçek değerle eklenir. Henüz yapılmayan işe süre/başarı uydurulmaz.
