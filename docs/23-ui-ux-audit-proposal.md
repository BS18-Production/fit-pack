# Fit Pack — UI/UX incelemesi ve dashboard tasarım önerisi

> 22 Eylül 2026 · **Karar taslağı, uygulama talimatı değil.** Kaynak: mevcut Flutter ekranları, ortak bileşenler, yönlendirme ve Samet'in paylaştığı üç referans görseli. Çalışan simülatör bulunamadığından bu inceleme kod ve referans görselleri üzerindendir; görsel son karar gerçek cihazda verilmeli. Bu belge yeni özellik vaat etmez ve mevcut veriye olmayan anlamlar yüklemez.

**Figma görsel önerisi:** [Güncel ana ekran + ritim + takvim](https://www.figma.com/design/GhsY9rNkdUfikEqwENezfS/Fit-Pack-UI-Kesfi?node-id=11-422). Aynı dosyada [önceki ana ekran + aktif antrenman + beslenme](https://www.figma.com/design/GhsY9rNkdUfikEqwENezfS/Fit-Pack-UI-Kesfi?node-id=7-5) çalışması da var. Bunlar görsel tasarım adaylarıdır; etkileşimli prototip veya birebir Flutter bileşen tarifi değildir.

### Son ürün kararı — 22 Eylül 2026

Samet, ana ekranda mevcut **“N haftadır ritimdesin”**, **haftalık antrenman hedefi** ve **son 30 günün antrenman sayısı / kg hacmi / tahmini kcal** özetinin kalmasını istiyor. Bu karar, aşağıdaki ilk taslakta geçen “yalnız iki sayı göster” ve “30 gün metriklerini ana ekrandan çıkar” önerilerinin önüne geçer. Bilgiler ayrı, eşit ağırlıklı kartlar yerine tek kompakt ritim bölümünde gösterilebilir; dönem ve birimler açık yazılır. Örnek Figma rakamları gerçek kullanıcı verisi değildir.

**Seri kuralı:** Mevcut `weeklyStreakProvider` ve `streak_calc.dart` haftalık antrenman hedefini sayıyor. Günlük uygulama açma veya her gün antrenman serisi gibi sunulmaz; dinlenme günü seriyi bozmaz. Devam eden haftada hedef henüz tamamlanmadı diye kazanılmış seri sıfırlanmaz. İlk hafta/boş veri, hedef tamamlandı ve kaçırılmış önceki hafta durumları ayrı metinlerle ele alınır.

**Takvim akışı:** Ana ekranda seçili hafta ve günler görünür; sol/sağ oklarla haftalar gezilir. Hafta başlığı ay görünümünü açar; ay görünümünde aylar arasında gezinilir ve bir güne dokununca o günün kayıt özeti açılır. Geçmiş hafta seçiliyken “Bugüne dön” görünür. Geçmiş günü incelemek, ana ekrandaki **bugünkü** antrenman eylemini sessizce geçmişe taşımaz. Gelecekte kayıt olmayan gün, başarısızlık olarak işaretlenmez.

## 1. Referanstan alınacak fikir

- Güçlü üst bölüm, seçili gün ve tek baskın eylem; ardından daha küçük, kolay taranan bilgi grupları.
- Koyu zemin üzerinde sınırlı ve amaçlı vurgu; fotoğraf ve grafik ancak gerçek içeriğe yardım ediyorsa.
- Alt gezinmenin tanıdık ve sürekli olması; sık kullanılan eylemin başparmağın erişebileceği bölgede bulunması.
- Sosyal akış, liderlik tablosu, meydan okuma, video antrenman ve profil istatistikleri referansta var diye Fit Pack'e eklenmeyecek. Fosforlu yeşil de renk kararı değil.

## 2. Mevcut uygulamanın ekran ve bileşen envanteri

| Akış | Ekranlar / bileşenler | Tasarımda korunacak iş |
| --- | --- | --- |
| Kapı ve ilk kurulum | Karşılama, giriş/kayıt, şifre sıfırlama, açılış/hesap hata ekranları, onboarding | Kullanıcıyı veri kaybı yaratmadan içeri almak; durdurucu durumları açıkça anlatmak. |
| Ana gezinme | Dört alt sekme: Ana Sayfa, Antrenman, Beslenme, İlerleme; profil ve ayarlar ikincil | Bu dört kavramı korumak; ortadaki renkli daireyi beşinci belirsiz sekme olarak kopyalamamak. |
| Ana Sayfa | Seri/30 gün hero, bugünkü rutin veya dinlenme eylemi, dört haftalık metrik, günlük beslenme, hareket içgörüsü, su ve kilo | Günün eylemini ve birkaç anlamlı durumu göstermek; ayrıntıyı ilgili sekmeye bırakmak. |
| Antrenman | Rutin listesi, seansa devam, rutin önizleme/oluşturma, canlı seans, özet, geçmiş, hareket kütüphanesi ve detay | Salonda hızlı set girişi, arama, geçen değer ve dinlenme akışını korumak. |
| Beslenme | Gün seçimi/özet, dört öğün, besin ekleme paneli, barkod, yemek kataloğu, önceki günden ve öğünden kopyalama | Hangi güne ve hangi öğüne kayıt yapıldığını her adımda anlaşılır tutmak. |
| İlerleme | Aktivite takvimi, ölçüm özeti/grafiği/geçmişi, fotoğraf galerisi/karşılaştırma, haftalık değerlendirme | Eğilim için yeterli veri yoksa bunu açık söylemek; fotoğrafların yalnız cihazda kaldığını görünür tutmak. |
| Kişisel/veri | Profil, hedefler, ayarlar, bildirimler, bulut hesabı, yedekleme/senkron durumu | Hedef değişikliğini bilinçli kılmak; senkron sorununu saklamamak. |
| Ortak görsel dil | `GlassBackground`, `GlassCard`, `CalorieRing`, `MacroBar`, `EmptyState`, `ErrorState`, `Skeleton`, `GradientButton`, ayar satırları, çipler | Renk ve hiyerarşiyi tek merkezden yönetmek; boş/yükleniyor/hata hâllerini tasarıma dahil etmek. |

## 3. Kanıta dayalı sorunlar ve önerilen hareket

1. **Ana eylem geç görünüyor.** Ana Sayfa sırası: başlık → büyük seri/30 gün kartı → bugünkü antrenman → dört haftalık metrik → beslenme → içgörü → su/kilo. Seri yararlı ama kullanıcının o anda yapacağı işi geçiştiriyor. Ana eylemi en üste, haftalık özeti daha aşağıya taşı.
2. **Devam eden seans Ana Sayfa'da yok.** Antrenman sekmesindeki `_ResumeBanner` doğru bir güvenlik ağı. Taslak varsa dashboard'un ilk eylemi “Seansa dön” olmalı; aynı anda “Yeni antrenman başlat” yarışmamalı.
3. **Aynı bilgi birden çok yerde ağır görünüyor.** Ana Sayfa'daki dört metriklik haftalık ızgara ve ayrı haftalık değerlendirme ekranı aynı konuyu iki kez açıyor. Ana Sayfa'da en fazla iki anlamlı sayı + tek “Haftayı gör” bağlantısı; ayrıntı değerlendirmede.
4. **Beslenme eyleminin bağlamı belirsiz.** Genel “Yemek Ekle” düğmesi öğün belirtilmezse `lunch` (öğle) ile açılıyor. Öğün kartındaki `+` doğru bağlamı biliyor. Genel giriş kullanılırsa önce öğün seçtir; mümkünse öğün içi eklemeyi öne çıkar.
5. **Set onayı küçük.** Canlı seans `_SetRow` içindeki ✓ görünür kutusu 38×34; set tipi rozeti 30×32. Spor salonunda sık ve hızlı dokunulan eylemler için hedef alanı Android'de en az 48 dp, iOS'ta en az 44 pt olacak şekilde büyüt; giriş sütunlarının darlığını küçük ikonla çözmeye çalışma.
6. **“Bitir” başlıkta, set işi aşağıda.** Canlı seansta en sık eylem set tamamlamak, en riskli eylem seansı bitirmek. “Bitir”i sürekli başlıkta baskın tutmak yerine, erişilebilir ama ayrışmış bir alt işlem alanı ve bitirmeden önce özet/onay düşün. Alt alan set satırlarını örtmemeli.
7. **İlerleme'de takvim ölçüm hikâyesinden önce.** Aktivite takvimi tüm ekran genişliğinde ilk sırada; kilo/ölçüm özeti ve trendi aşağı itiyor. İlerleme sekmesinde önce son ölçüm ve anlamlı trend, takvim ise ayrı/katlanabilir bölüm olmalı. Tek ölçüm trend sayılmaz.
8. **Efektler hiyerarşinin yerine geçiyor.** Ortak cam yüzey, arka plan parıltısı, gradient düğmeler ve çok sayıda yuvarlak kart bir araya gelince her şey aynı derecede önemli görünüyor. Tek ana vurgu yüzeyi; diğer alanlarda düz yüzey, tipografi ve boşlukla öncelik kur.
9. **Arama doğru yönde.** Hareket kütüphanesinde Türkçe terimler, alaka sırası ve son kullanılanlar var. Arama kutusu ilk odak; kategori/kas filtreleri yardımcı katman. İki filtre şeridi sonuçları ekran dışına itmemeli.
10. **Uzun rapor küçük ekrana sıkışıyor.** Haftalık değerlendirme yedi kartı ardışık çiziyor. Özet önce; antrenman/beslenme/kilo temel bölümleri ardından; kas/fokus gibi ikincil ayrıntılar açılabilir olabilir. “Nereden hesaplandı” kanıtı korunmalı.

## 4. Dashboard'un görevi ve içerik bütçesi

Dashboard üç soruya cevap vermeli: **Şimdi ne yapacağım? Bugün ne kaydettim? Bu hafta ne değişti?** İlk ekranda dört eşit kahraman kartı olmamalı. Telefonun ilk görünür alanında başlık + tek ana eylem + günlük durum özeti bulunmalı.

| Sıra | İçerik | Gösterim kuralı | Dokunma sonucu |
| --- | --- | --- | --- |
| 1 | Kısa tarih, “Bugün”, profil/hesap durumu | Her zaman. Senkron sorunu varsa yalnız eylem gerektiren kısa uyarı. | Profil veya sorun ayrıntısı. |
| 2 | **Tek ana antrenman eylemi** | Taslak varsa “Seansa dön”; yoksa bugünkü rutin; dinlenme gününde sakin bir bilgi + isteğe bağlı serbest antrenman; rutin yoksa “Antrenman seç/oluştur”. | İlgili seans/önizleme. Taslak her zaman diğerinden önce. |
| 3 | Günlük kayıt durumu | En fazla iki güçlü bilgi: kaydedilen kalori ve protein. Su küçük ek eylem. Kayıt yoksa `0 yedin` gibi yorum değil, “Henüz kayıt yok”. | Beslenme; su için doğrudan `+250 ml`. |
| 4 | Bu hafta | Örneğin `2/3 antrenman` ve `4 gün beslenme kaydı`. Hedef ya da veri yoksa ona uygun açıklama. Haftalık seri büyük hero değil. | Haftalık değerlendirme. |
| 5 | İlerleme işareti | Son kilo ve ölçüm tarihi **veya** yeterli verili tek hareket içgörüsü. Boşsa alanı sırf doldurmak için gösterme. | İlerleme veya hareket detayı. |

**Dışarıda kalacaklar:** 30 gün hacim + yakılan kalori + dört haftalık metrik ızgarasının tamamı, büyük halka ile üç makro çubuğunun dashboard'da tekrar çizimi, puan/rozet/leaderboard, hedefe yaklaşma yorumu için yetersiz veriden çıkarım. Bunların yeri ayrıntı ekranlarıdır.

**Durum varyantları:** aktif seans; planlı antrenman; dinlenme; ilk kurulum/boş veri; yükleniyor; bağlantı/senkron sorunu. Her varyantta aynı yerleşim korunmalı, yalnız ilk eylem ve açıklama değişmeli. Bu, sayfanın her açılışta başka bir düzene sıçramasını önler.

## 5. Dokunma ve gezinme kuralları

- Dört mevcut alt sekme kalır. Ortadaki büyük yuvarlak referans düğmesi; Fit Pack'te aynı anda dört farklı “ekle” eylemi olduğu için ne yapacağı belirsiz. Ana eylem, ilgili ekranın bağlamında görünür.
- Sık kullanılan işlem yakınında: öğün kartında “Yemek ekle”, sette ✓, su durumunda `+250 ml`. Nadiren kullanılan geçmişe kayıt, arşiv/sil, ayarlar üst menü veya ayrıntı ekranında.
- Yapıcı eylem en kolay erişilen alanlarda; geri dönüşü zor eylem ayrı ve açıklamalı. Görsel sağ/sol yerleşim tek başına başarı garantisi değildir; Android telefon ve iOS simülatöründe tek elle gerçek deneme yapılmalı.
- Görünür butonlar Android'de ≥48 dp, iOS'ta ≥44 pt dokunma alanı; küçük ikon görünümü korunabilir ama görünmez hit alanı genişletilmeli. Yan yana hedefler yanlış dokunmayı önleyecek aralıkta olmalı.
- Sabit alt eylem, alt gezinti ve klavyeyle çakışmamalı. Kayıt panelinde kaydetme düğmesi klavye açıkken de erişilebilir olmalı.
- Kontrast ve sayı/birim ayrımı korunmalı; renk tek başına durum anlatmamalı. Grafik ancak karar verdirecek kadar veri varsa; başlık, tarih aralığı ve birim açık olmalı.

## 6. Görsel yönü belirleme sırası

1. Önce **gri tonlu** dashboard ve canlı seans iskeleti: sıra, yoğunluk, tuş konumu. Referansın yapısını burada sınarız.
2. Sonra mevcut koyu Fit Pack paletinden iki kontrollü renk çalışması: biri indigo/teal'in daha disiplinli hâli, diğeri daha nötr zemin + tek canlı vurgu. Makro ve durum renkleri işlevleri için sabit kalır. Kullanıcı yeşili seçmedi.
3. Gerçek içerik örnekleriyle test: uzun Türkçe rutin/hareket adı, eksik beslenme günü, tek kilo ölçümü, aktif taslak, küçük Android ekranı, açık/koyu tema.
4. Seçilen dil için yalnız gereken ortak bileşenler (ana eylem, durum satırı, veri özeti, giriş satırı, alt gezinme) tanımlanır; ardından Flutter'a taşınır. Veritabanı ve senkron akışlarına dokunmadan görsel geçiş ayrı işlenir.

## 7. Doğrulama ölçütleri

- İlk bakışta “devam et / başlat” ve “bugün ne kaydettim?” 3 saniyede anlaşılır mı?
- Kullanıcı aktif antrenmana Ana Sayfa'dan tek dokunuşla dönebilir mi?
- Yemek eklerken hedef gün ve öğün her adımda açık mı?
- Seti bir elle ve hedefe bakmadan yanlış satıra dokunmadan tamamlamak mümkün mü?
- Kayıtsız gün “az yedim”, tek ölçüm “trend” veya dinlenme günü “serim bozuldu” gibi okunuyor mu?
- Küçük Android ekranında, büyük yazı ayarında ve iOS güvenli alanlarında içerik/tuş çakışıyor mu?

### Dayanaklar

- [Apple — touch controls / hit targets](https://developer.apple.com/design/tips/): iOS için 44×44 pt alt sınırı, kontrolü değiştirdiği içeriğe yakın tutma.
- [Android — layout and navigation patterns](https://developer.android.com/design/ui/mobile/guides/layout-and-content/layout-and-nav-patterns): 3–5 birincil hedefli alt gezinme, tek baskın sayfa eylemi.
- [Android — minimum touch target](https://developer.android.com/develop/ui/compose/accessibility/api-defaults): etkileşimli hedefler için 48 dp.
- [Apple — charts](https://developer.apple.com/design/human-interface-guidelines/charts): az sayıda anlamlı bilgi, açık birim/zaman bağlamı, erişilebilir grafik.
