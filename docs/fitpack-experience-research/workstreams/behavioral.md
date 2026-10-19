# Davranışsal deneyim ve sürdürülebilir kullanım

18 Ekim 2026 · bağımsız kaynak incelemesi ve literatür taraması · üretim kodu değişmedi. Rol: davranışsal ürün tasarımı. Teslim: mevcut mekanizmalar, ihtiyaç çerçevesi, geri bildirim dili, deney hipotezleri ve ölçüm planı. Sınır: kullanıcı görüşmesi, klinik etki, alışkanlık oluşumu veya elde tutma artışı ölçülmedi. Mevcut özelliklerin varlığı kaynakla; davranışsal etki önerileri hipotezle işaretlenir.

## Ürün ilkesi

Amaç daha çok açılış değil, kullanıcının kendi amacına daha az çabayla ilerlemesi. İyi kayıt yapıp uygulamayı kapatmak başarılı deneyimdir. “Tüm hedefleri bitirmeden çıkma”, günlük seri kaybetme tehdidi, telafi antrenmanı, beden üzerinden suçlama, rastgele ödül ve sosyal kıyas önermiyoruz. Buradaki araştırma kullanıcıya yeni sağlık hedefi/reçete vermek değildir.

**Literatür dayanağı:** Teixeira ve arkadaşlarının 66 çalışmayı inceleyen araştırması, daha özerk motivasyon ile egzersiz davranışı arasında genel olarak olumlu ilişki buluyor; çalışmaların çoğu betimleyici, dolayısıyla bu bulgu belirli FitPack ekranının elde tutmayı artıracağını kanıtlamaz. Çerçeve özerklik, yeterlik ve ilişki ihtiyaçlarını görünür tasarım sorularına dönüştürmek için kullanılır. [Araştırma, 2012](https://selfdeterminationtheory.org/SDT/documents/2012_TeixeiraEtAl_IJBNPA.pdf), erişim 18 Ekim 2026.

[NICE davranış değişimi rehberi](https://www.nice.org.uk/guidance/ph49/chapter/recommendations) ortak hedef/plan, izleme ve geri bildirim, kişiye uyarlama ve değerlendirmeyi birlikte ele alır. FitPack'e çıkarım: hedefi görünür yap, küçük bir sonraki eylem sun, sonucu kendi geçmişiyle göster, etkiyi ölç. Bu klinik rehberin bir uygulama tasarımına doğrudan etkililik garantisi değildir; erişim 18 Ekim 2026.

[Lally ve arkadaşlarının gerçek yaşam alışkanlık araştırması](https://onlinelibrary.wiley.com/doi/abs/10.1002/ejsp.674) tek bir fırsatı kaçırmanın alışkanlık oluşumunu belirgin etkilemediğini raporlar. Bir çalışma tüm fitness davranışlarına genellenmez; tasarım çıkarımı kaçırılan tek günü kalıcı kayıp veya karakter kusuru gibi sunmamaktır. “21 günde alışkanlık” gibi kesin süre vaadi verilmez; erişim 18 Ekim 2026.

## Mevcut motivasyon mekanizmaları: yeniymiş gibi önermemek

| Kaynakla doğrulanan mekanizma | Kullanıcıya olası değer / hipotez | Korunacak sınır / değerlendirme |
|---|---|---|
| Deneyim + gün → hazır program önerisi; kendim kuracağım | Seçenek karmaşasını azaltıp ilk eyleme güven | Zorunlu program yok; öneri tıbbi uygunluk iddiası değil. `onboarding/program_recommendation.dart`, `onboarding_screen.dart:253` |
| İlk 14 gün üç adımlı rehber | Yeni kullanıcının nereye gideceğini öğrenmesi | Üçü bitince kaybolur, tekrar rozet/puan sistemi yapılmaz. `home/first_week.dart:14`, `:29` |
| Kendi geçmişinden set önerisi + tek ✓ + otomatik mola | Yeterlik ve düşük kayıt maliyeti | Öneriyi değiştirme açık; zorluk isteğe bağlı; U04 hedef boyutu çözülmeli. `workout/active_session_screen.dart:604` |
| Artır/tekrar ekle/aynı kal/azalt ilerleme mantığı | Gelişimin nedenini anlama | Kullanıcı onayı olmadan program değişmez; öneri ve gerçekleşen değer ayrılır. `workout/progression.dart`, `active_session_widgets.dart:758` |
| Rekor işareti ve seans özeti | Somut, kişisel kazanımı görme | İlk kez yapılan hareketi sahte rekor olarak kutlama yok; her seansı rekor zorunluluğuna çevirme. `active_session_screen.dart:575`, `record_calc.dart` |
| Haftalık ritim | Dinlenme günleri yüzünden günlük serinin bozulmaması | Haftayı sıfırlayan sayının baskı yaratıp yaratmadığı ölçülmeli. `home/streak_calc.dart:6`, `rhythm_state.dart:101` |
| Haftalık değerlendirme: tek odak, veri kaynağı | Sonucun ve belirsizliğin anlaşılması | “Kayıt yok” ile kötü sonuç ayrılır; kayıtsız günü başarısız sayma. `insights/weekly_review_screen.dart:25` |
| Alışılmış öğün, son kullanılan porsiyon, kopyalama | Günlük rutine daha az sürtünme | Önceden otomatik kaydetme yok; açık Ekle ve geri al. `nutrition/nutrition_habit_widgets.dart:148`, `add_food_sheet.dart:516` |
| Beslenme günü tamam işareti | Günün verisinin tam olduğunu kullanıcı belirtir | Hedefe ulaşmak veya az yemekle eşitlenmez. `nutrition/day_complete.dart:11` |
| Günlük antrenman/beslenme satırı, Haftan hazır | Yoruma ulaşmak için soru sorma gereksinimini azaltır | İki satır zaten var; ikinci bir AI Koç sekmesi gerekmiyor. `home/today_lines.dart`, `home/week_ready.dart` |
| Verime sor: hazır sorular ve anlaşılan soru düzeltmesi | Kayıtların faydasını kullanıcının sorusunda açığa çıkarır | Yanlış eşleme düzeltilebilir; güven ve gizlilik korunur. `assistant/assistant_screen.dart:250`, `:559` |
| Ara uzadı / planlı gün / ilk hafta hatırlatmaları | Kullanıcının niyetine uygun geri dönüş | Zaten uygulanmış; yenisini eklemeden toplam dikkat yükünü ölç. `workout/recall_reminders.dart`, `recall_missed_day.dart`, `recall_first_week.dart` |
| Ölçüm trendi/fotoğraf/sağlık kaynağı | Tek tartı ölçümünün ötesinde kişisel görünüm | Veri yok ile 0 ayrı; fotoğraf paylaşımı varsayılan değil. `body_metrics_screen.dart`, `progress_photos_screen.dart` |

## Motivasyon çeşitliliği: aynı kişide birden fazlası olabilir

| Kullanıcının ifade edebileceği amaç | Fayda kanıtı | Görünür küçük eylem | Kaçınılacak yorum |
|---|---|---|---|
| Güçlenmek | Aynı hareket/benzer koşulda set ve rekor geçmişi | Sıradaki rutin; önceki uygun değer | Her seferinde kilo artırmak zorundasın |
| Kas geliştirmek | Yapılan setlerin sürekliliği, hedef rutin, kendi gelişimi | Rutin planını gör/uygula | Fotoğraftan otomatik beden puanı |
| Kilo yönetimi | Uygun veri yeterliğiyle trend ve hedef yönü | Kayıt ekle, günün verisini tamamla | Tek ölçüm arttı → başarısızsın |
| Beslenme alışkanlığı | Kaydın tamamlığı ve tekrar kolaylığı | Alışılmış öğünü onayla/düzelt | Eksik kayıt = öğün atladın veya protein eksik yedin |
| Düzenli egzersiz | Seçtiği haftalık planla anlamlı dönem | Uygunsa bir sonraki seansa dön | Ara verdin, serin yandı |
| Basit kayıt | Hızlı, güvenilir, geri alınabilir defter | Sonraki set/öğün | Her açılışta analiz okumak zorundasın |

Bunlar persona araştırma sonucu değildir; görüşmede sınanacak iş hipotezleridir. İlk günden ilave motivasyon anketi zorunlu yapılmaz. Mevcut deneyim/gün ve kullanıcının açık tercihi yeterli başlangıçtır; ileri kişiselleştirme ancak ölçülebilir faydayla eklenir.

## Özerklik, yeterlik ve ilişki için tasarım kararları

**Özerklik:** program önerisini reddet; hedefi kolay düzenle (U03); öneriyi uygula/geri al; bildirimi ertele/kapata ulaş; seansı veri kaybetmeden terk edebil (U01). İzin vermeyi ilerlemenin ön koşulu yapma. Hedefler kullanıcının seçimi, sıralama mantığı açıklanabilir olmalı.

**Yeterlik:** önceki değer → uygun öneri → gerçekleşen set → geri bildirim döngüsü. Set onayını güvenilir büyüklükte yap (U04), kaydın kalıcı olduğunu göster, kayıtsız dönemleri bilinmiyor de. Haftalık odak kişisel ve somut olmalı; her özetin sonunda üç yeni hedef üretme. Küçük kazanımı göstermek için confetti veya yeni oyun ekonomisi gerekmez.

**İlişki / görülmüş hissetme:** kişinin kendi seçimine ve kaydına duyarlı, yargısız dil kullan. Bu uygulama arkadaş/uzman ilişkisi varmış gibi rol yapmaz. Sosyal feed, sıralama veya koç persona'sı mevcut ihtiyaç kanıtı olmadan eklenmez. Gerekiyorsa kullanıcı kendi isteğiyle kaydını paylaşabilir; bu çalışma paylaşım özelliğini zorunlu önermiyor.

Bu üç paragraf araştırma çerçevesinden FitPack'e tasarım çıkarımıdır; tek bir etkileşimin psikolojik ihtiyacı karşıladığını ölçmüş değiliz.

## Sinyal → eylem → geri bildirim → uzun dönem değer

1. Kullanıcı uygun zamanda uygulamayı açar: aktif seansa dönüş veya sıradaki rutin görülür. Açılış yoksa ve izinliyse mevcut hafif hatırlatıcı; birden fazla bildirimle baskı kurulmaz.
2. Bir küçük işi yapar: seti onaylar veya öğünü kaydeder. Önceki değer, hızlı porsiyon ve geri al maliyeti düşürür.
3. Sonucu anlar: kaydedildi, mola başladı, bugün kayıt tamam. Sistem kendi verisinin güvenilirliğini belirtir.
4. Yeterli geçmişte fayda görür: haftalık tek odak, hareket grafiği, trend veya kendi sorusuna yanıt. Başka kullanıcıya göre sıralama gerekmez.
5. Ara verdiyse geri dönmesi kolaydır: tarihsel verisi yerindedir; “yeniden başlamak” sıfırdan kurulum değildir. Geçmiş kazanımlar kaybolmuş gibi sunulmaz.

Bu döngü için ürün farklılaştırması “daha zeki görünen asistan” değil, antrenman + öğün + kendi geçmişi arasında anlaşılır bağlantı olabilir. Bu rekabet üstünlüğü henüz pazar araştırmasıyla kanıtlanmadı.

## Bildirimler: mevcut sınırlar ve U10 araştırma konusu

Mevcut kod: 2 gün ara sonrası, en çok 2/gün ve 6/7 gün; sessiz saat 22–08; tepkisiz 3 gün sonrası 14 gün susturma (`recall_reminders.dart:19–31`). Planlı gün + ara uzadı ortak sınıra tabi (`recall_missed_day.dart:99`). İlk hafta ikinci gün 19.00'da, bir kez; zaman kaçarsa geç göndermez (`recall_first_week.dart:10`). Öğün ve haftalık hatırlatmaların toplam dikkat yükü ayrıca düşünülmeli.

Önemli ürün nüansı: `recall_offer.dart:24` onboarding sonunda da teklif var; yalnız ilk antrenmandan sonra demek eski bilgi olur. Aynı dosya `:103–110`, mola bildirimi zaten açıksa antrenman hatırlatıcısını ayrıca sormadan açar ve bilgi verir. **Gözlem** bu; **çıkarım** kullanıcı sistem bildirim izni ile tüm amaçları kabul etmeyi aynı saymayabilir. Kullanıcı onayıyla alınmış docs/51 kararını araştırmada habersiz “düzeltme” olarak geri çevirmiyoruz. Öneri, izin anlayışı ve frekans kontrolünü gerçek kişiyle sınamak; uygulanacak değişim ayrıca onaylanır.

| U10 alt hipotezi | Karşılaştırma | Birincil ölçüm | Zarar/yan etki kontrolü |
|---|---|---|---|
| Tek açık fayda, tekrarlı hatırlatmadan daha yararlı | Mevcut sınır vs kullanıcının seçtiği daha seyrek kip | Bildirimden sonra kullanıcının istediği görevi yapma + yararlılık değerlendirmesi | Bildirimi kapama, rahatsızlık, yanlış bağlam |
| Mola izni tüm hatırlatmaları beklemek demek olmayabilir | Mevcut otomatik açıklama vs amaçları açık seçme prototipi | Kullanıcı hangi tür mesaj geleceğini doğru öngörüyor mu | İzin dönüşümü tek başarı sayılmaz |
| Ara sonrası yargısız dil geri dönüşü kolaylaştırabilir | Mevcut “Yarın da olur” ve bağlamsal kayıt/plan bağlantısı | Uygun göreve başarılı dönüş, anlaşılma hissi | Zorunluluk, suçluluk, fazla antrenman baskısı |

Bildirim açma ve tıklama tek başına motivasyon/retention kanıtı değildir. Retention = elde tutma / kullanıcının sonraki dönemlerde geri dönmesi. Ölçümün kullanıcıya yardım etmesi gerekir; toplam gösterim ve tıklama hedeflerini bağımsız büyütmeyiz.

## Mikro metin örnekleri ve belirsizlik

| Durum | Örnek öneri | Neden |
|---|---|---|
| Veri yok | “Bugün henüz öğün kaydı yok.” | Yenmediğini iddia etmez |
| Ara sonrası dönüş | “Kayıtların burada. Uygunsa sıradaki antrenmanla devam edebilirsin.” | Kazanımı silmez, seçim bırakır |
| Planlı dinlenme | “Bugün planında dinlenme var.” | Dinlenmeyi başarısızlık yapmaz |
| Başarılı set | “Set kaydedildi · dinlenme başladı.” | Eylem sonucu somut |
| Yeni rekor | “Bu harekette kayıtlı en yüksek ağırlığın.” | Kapsamı açık, evrensel performans iddiası yok |
| Yetersiz trend | “Eğilimi göstermek için henüz yeterli kayıt yok.” | Sahte kesinlik üretmez |
| Hedef üstü kayıt | “Hedefin üzerinde kaydettin.” | Ahlaki yargı ve telafi emri yok |
| İlk hafta tamam | Kart sakin biçimde kapanır; gerekirse “İlk kayıtların hazır.” | Sürekli ödül beklentisi yaratmaz |

Bunlar uygulama metni olarak eklenmedi; marka dili/kullanıcı testinde değerlendirilecek örneklerdir. Mevcut `app_tr.arb:578–579` “Yarın da olur” tonu zaten bu yönde. `homeRhythmRestartSub` geçmiş haftanın tamamlanmadığını söylüyor; bu nötr veriyi kaldırmak zorunlu değil, baskı algısını araştırmak gerekir.

## Ölçüm planı: sağlık verisini büyütmeden faydayı görmek

| Soru / hipotez | Tanım ve payda | Başlangıç bilgisi | Doğrulama yöntemi |
|---|---|---|---|
| İlk değer daha çabuk oluşuyor mu? | Hesabı tamamlayanlardan ilk geçerli seans/öğün kaydı yapanlar; süre ayrı | Ölçülmedi; docs/49 az sayıdaki ürün örneği temsilî kullanıcı araştırması değildir | Yeni kullanıcı görev denemesi; 1 ve 7 gün takip |
| Kayıt kolaylaştı mı? | Görev başına süre, hata/düzeltme ve başarı; 1 ve 3 besinli öğün ayrı | Otomatik widget başarı testleri var, insan baseline yok | Aynı verili önce/sonra prototip denemesi |
| U01 güven sağladı mı? | Koruyarak çıkanlardan bire bir aynı setlerle dönenler; veri farkı 0 zorunlu | Mevcut normal geri çıkış taslağı siler | Durum/cihaz test matrisi + kullanıcı güven sorusu |
| U04 yanlış dokunmayı azalttı mı? | Başarısız/yanlış hedef dokunuşu ÷ tüm set onay/düzeltme denemesi | Bilinmiyor | Tek el, ıslak ekranı taklit etmeden güvenli fiziksel görev; cihaz sınırı kaydı |
| Haftalık fayda anlaşılır mı? | Değerlendirmeyi açan kişinin dönem, veri kapsamı ve odak cümlesini doğru anlatması | İçerik var, anlama ölçülmedi | “Bu sayı neye göre?” görevi; kaydı az ve çok hesap |
| Kullanıcı kontrol hissediyor mu? | Bildirim kaynağı/sıklığı ve kapatma yerini bulma başarısı; kısa gönüllü değerlendirme | Bilinmiyor | İzin açıklaması prototipi ve 1 hafta günlük kullanım notları |
| D7/D28 geri dönüş yararlı mı? | Kayıt yapmaya niyetli yeni grubun 7/28 günde anlamlı işlem yapması; pencere ve kohort sabit | Ölçülmedi | Yeterli örneklem sonrası; hasta/tatil/dinlenme yüzünden açmama başarısızlık sayılmaz |

Tıklama/olay kaydı gerekiyorsa sadece görev türü, başarı/hata sınıfı, anonim süre gibi gerekli olay tasarımı önerilir; kilo, kalori, sağlık kaydı, fotoğraf veya serbest asistan sorusunu analitiğe taşımak bu araştırmanın parçası değildir. Yeni analitik kurmak ayrı ürün/veri kararı gerektirir. Pilot aşamada gözlem notu ve gönüllü kısa günlük yeterli olabilir; sunucu eklemek ön koşul yapılmaz.

**Hipotez sırası:** önce güven/erişim (U01–U04), sonra bilginin bulunması (U05/U06/U11), en son motivasyon dili/bildirim yoğunluğu (U10). Kırık kayıt akışını yeni motivasyon metniyle örtmek yarar sağlamaz. Her deneyin hem yarar ölçümü hem rahatsızlık/hata kontrolü olmalı.

## Davranışsal önerilerin tahmini puanı

1 düşük, 5 yüksek; karmaşıklık ve risk yüksekse maliyetli. Bunlar ölçüm sonucu değildir; mevcut kaynak ve araştırma çerçevesinden tahmin.

| Öneri | Etki | Kullanılabilirlik | Görsel | Kullanım | Ayrışma | Karmaşıklık | Risk | Güven |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Mevcut ilk hafta/ilk değer akışını sade bağlamda koru | 5 | 4 | 3 | 3 | 3 | 2 | 2 | 4 |
| Kaydı onaylayan kısa geri bildirim, geri alma | 5 | 5 | 3 | 5 | 3 | 2 | 1 | 4 |
| Kendi geçmişiyle somut haftalık odak | 4 | 4 | 4 | 3 | 4 | 2 | 2 | 4 |
| Kaçırılan gün yerine esnek dönem ve yargısız dönüş | 4 | 4 | 3 | 3 | 3 | 2 | 2 | 3 |
| Kullanıcı seçimiyle daha seyrek bildirim | 4 | 4 | 2 | 3 | 3 | 3 | 3 | 3 |
| Kullanım niyetine göre ileri kişiselleştirme | 3 | 3 | 3 | 4 | 4 | 4 | 4 | 2 |

İlk üçü büyük ölçüde mevcut yeteneklerin doğru sunumu; eksik özellik listesi değildir. Otomatik “iyi/kötü gün” puanı, yeni sosyal akış, günlük seri ekonomisi ve onaysız AI program üretimi bu öneri setine dahil edilmez.
