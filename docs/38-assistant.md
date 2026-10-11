# 38 — Asistan (#10): Verime sor

## Karar özeti

Fit Pack'e **Verime sor** ekranı eklenir. Hazır sorular çevrimdışı, cihazdaki
hesaplarla çalışır. Serbest soruyu ücretsiz **Gemini 3.5 Flash-Lite** hazır
sorgulardan birine eşler; sayı ve yorumları uygulama üretir. Her cevabın ilk
satırı **"Anladığım soru: … · değiştir"** olur.

**Seçilen yol:** dondurulmuş eşleme sözleşmesi + mevcut hesap motoru +
docs/36'daki kural tabanlı yorumlar. Jev kabul alamadı; Claude API kullanılmaz.
Gemini cevap, program veya kişisel reçete yazmaz.

**Gerçek veriye etkisi:** mevcut fitness kayıtları yalnız okunur. K1 için
cihazda metinsiz olay tablosu eklenir (v15 → v16); sunucuda yalnız kota
altyapısı eklenir. Geri dönüş serbest soruyu kapatıp hazır soruları korumaktır;
veritabanı sürümü düşürülmez.

**Samet'in kararları (sohbette onay, 2026-10-11):**

1. ✅ Kullanıcı başına 20 soru/gün; uygulama genelinde 400 soru/gün,
   10 istek/dakika ve 200.000 giriş tokenı/dakika.
2. ✅ K1 kayıtları 90 gün veya 5.000 olay; önce dolan sınır uygulanır.
3. ✅ Taslak onaylandı; ayrı dalda kod aşamasına geçilir. Push, main'e
   birleştirme, üretim Supabase'i ve fiziksel cihaz kurulumu ayrı onay ister.

**Doğrulama:** dondurulmuş karar mantığıyla Dart karşılaştırması, hesap ve
tarih sınırı testleri, kayıpsız v15→v16 göç, oturum/kota testleri, çevrimdışı
kullanım ve iOS Simulator görsel kontrolü.

---

**Durum:** onaylı tasarım; uygulama `feat/assistant` dalında.
**Tarih:** 2026-10-11 · **Sahip:** Codex (ekran/veri/sunucu/test/doküman).
**Dayanak:** [docs/35](35-jev-soru-esleme.md) §14,
[docs/36](36-verime-sor-yorum-katmani.md),
[docs/37](37-nutrition-day-complete.md), `collab/devir-2026-10-11.md`.

## 1. Başlangıç durumu ve kapsam

#10 Samet kararıyla öne alınmıştır; sonraki sıra #5 → #7 → #2 tamdır.
Model yalnız `gemini-3.5-flash-lite`; yorumlar docs/36 kurallarıdır. Hazır
sorular ağdan bağımsızdır. K1 yalnız cihazdadır; K2/K3 ve ham soru paylaşımı
bu sürüme girmez.

Docs/36 saf hesapları main'e birleşmiştir; ekran, sağlayıcılar ve yorum
çevirileri eksiktir. Docs/37 tamamlanan gün hesabı uygulanmıştır; asistanın
genel dönem beslenme hesabı bununla birleştirilmelidir.

## 2. Ekran ve etkileşim

Ana Sayfa'da haftalık değerlendirmeye yakın **Verime sor** kartı ayrı ekranı
açar; yeni ana sekme eklenmez. Ekranda serbest soru alanı, Sor düğmesi,
sekiz öne çıkan hazır soru, Tüm sorular ve sonuç/seçenek alanı bulunur.

- Serbest soru → yerel kontroller → `ask-route` → Gemini → yapı doğrulama
  → Dart karar mantığı → yerel hesap → yerel yorum → sonuç.
- Hazır soru → gerekirse dönem/hareket/öğün seçimi → yerel hesap/yorum.
- Hazır soru ve seçenek değiştirme kota tüketmez.

Her sonuç: **Anladığım soru … · değiştir**, kullanılan tarih aralığı,
kayıt sayısı ve hesap, istenmişse yorum, veri sınırları/kaynaklar ve hedef
ekran düğmesi sırasıyla gösterilir. Devam eden dönem "şu ana kadar"dır.
Değiştir, yerel sorgu/dönem/hareket/öğün seçimini açar; ağ çağrısı yapmaz.
Çoklu niyette en fazla üç destekli sorgudan biri seçilir; önce sayı üretilmez.
Tema tokenları ve Türkçe/İngilizce çeviriler kullanılır; UI emojisi yoktur.

## 3. Sorgu ve dönem sözleşmesi

Dondurulmuş sözleşme sürümü **2** korunur.

| Kimlik | Anlam | Desteklenen dönem |
|---|---|---|
| `workout_summary` | Antrenman özeti | Bu hafta, geçen hafta |
| `plan_adherence` | Planlanan günlere uyum | Bu hafta, geçen hafta |
| `strength_progress` | Genel güç gelişimi | Bu hafta, son 30 gün |
| `exercise_history` | Seçilen hareketin gelişimi | Son 30 gün, tüm zamanlar |
| `nutrition_summary` | Beslenme özeti | Bu hafta, geçen hafta |
| `protein_goal` | Protein hedefine ulaşma | Bu hafta, son 30 gün |
| `weight_trend` | Vücut ağırlığı değişimi | Bu hafta, son 30 gün |
| `muscle_balance` | Kas gruplarına göre setler | Bu hafta, geçen hafta |
| `streak` | Düzenli antrenman serisi | Dönem seçimi yok |
| `today_remaining` | Bugünkü hedefe kalan miktar | Bugün |
| `top_exercises` | En çok yapılan hareketler | Bu hafta, son 30 gün, tüm zamanlar |

`out_of_scope` hesap çalıştırmaz. İlk sekiz kart: antrenman, plana uyum,
güç, beslenme, protein, kilo, kas grupları, bugün kalan. Diğer üç sorgu
Tüm sorular altında erişilebilir.

Tarihler `[başlangıç, bitiş)`; hafta başlangıcı mevcut kullanıcı ayarıdır.
Son 30 gün `[bugün − 29 takvim günü, yarın)`; "son 1 ay/son 4 hafta" da
kabul edilmiş sözleşme gereği bu aralıktır ve aralık görünür. Takvim ayı,
diğer gün ve belirsiz dönem sessizce çevrilmez; destekli dönem seçtirilir.
Takvim aritmetiği kullanılır; yaz saati günleri 24 saat varsayılmaz.
Bu haftalık kilo değişimi sayı olarak gösterilebilir; iki ölçüm ve en az
14 gün açıklık olmadan eğilim yorumu yoktur, pencere kendiliğinden uzamaz.

## 4. Hareket, kas grubu ve öğün

Gemini'nin donmuş listesi **20 hareket + 5 aile + none** olarak korunur;
kişisel hareket adları Google'a gönderilmez. Sabit kimlikler yerel kataloğa
açık eşlemeyle bağlanır. Aile için en sık yapılan çeşit seçilir ve görünür
olur; eşitlik deterministiktir. Geçmiş yoksa veri yok durumu; özel/listede
olmayan hareket için yerel seçici vardır. Süre/mesafe hareketinde tahmini
tek tekrar maksimumu (e1RM) üretilmez. Hareket geçen ağırlık sorusu vücut
ağırlığına otomatik gitmez.

Donmuş şemada kas grubu veya öğün alanı yoktur. Kas grupları birlikte
gösterilir ve yerelden süzülür. Bugün kalan önce miktar gösterir; yemek
örnekleri için öğün yerelden seçilir. Modelin döndürmediği alan varsayılmaz.
Donmuş istemi/listeyi değiştirmek yeni sürüm ve kabul ölçümü gerektirir;
ek yerel korumalar çekirdekten ayrı test edilir.

## 5. Gemini ve ask-route

| Alan | Değer |
|---|---|
| Model | `gemini-3.5-flash-lite` |
| Parmak izi | `d879f8993e8be890` |
| Sözleşme | 2 |
| İstek | `store: false`, `thinking_level: low` |
| Çıktı | `gemini_run.py` içindeki donmuş JSON şeması |

Parmak izi 2026-10-11'de yeniden hesaplanmış ve eşleşmiştir. Deney betiğinin
varsayılan 3.8 modeli kullanılmaz. Google'a yalnız soru metni ve kişisel
olmayan sabit sorgu/dönem/hareket tanımları gider; profil, fitness kaydı,
plan veya sohbet geçmişi eklenmez.

Uygulama soru, istek kimliği ve protokol sürümünü gönderir. Sunucu kullanıcıyı
gövde kimliğinden değil doğrulanmış oturum jetonundan belirler. Geçersiz
oturumda Google çağrısı yoktur; oturum doğrulaması etkin kalır. Anahtar
yalnız sunucu secret'ındadır; uygulamaya/depoya gömülmez. Üretim secret'ı
yerleştirme bu dokümanın onayıyla yetkilendirilmiş sayılmaz.
[Supabase kimlik doğrulama](https://supabase.com/docs/guides/functions/auth).

Modelin zorunlu sekiz alanı: `query`, `period`, `exercise`, `multi_intent`,
`advice`, `wants_interpretation`, `ambiguous`, `alternatives`. İki tarafta
türler, enumlar, ek alan yasağı ve en fazla iki alternatif doğrulanır.
Bozuk/tamamlanmamış çıktı hazır sorulara döner. Sunucu bunları istek kimliği,
model, sözleşme, parmak izi ve varsa token/gecikme bilgisiyle sarar; cevap
cümlesi veya rota modelden alınmaz.

`prefilter`, `mentions_exercise`, `to_pred` uyarlaması ve `decide` Dart'a
taşınır. Sıra: engelleme → çoklu niyet → tavsiye/kapsam dışı/belirsiz →
ağırlık ve bugün dönem kontrolü → hareket/dönem netleştirme → otomatik.
Çoklu niyet UI'sı yalnız destekli yerel sorguları sunar; tıbbi görüş veya
kayıt değiştirme çalıştırmaz. Gemini olasılık döndürmez: `ambiguous` için
0,5/1,0 uyarlaması yalnız teknik değerdir; "yüzde 100 güven" gösterilmez.

## 6. Kota ve hata davranışı

2026-10-11, AI Studio **Fitpacl / Free tier** teyidi:
**15 istek/dakika, 250.000 giriş tokenı/dakika, 500 istek/gün**.
Paneldeki 121/500 günlük tepe kullanımıdır, güncel kalan değildir.
[Proje kota sayfası](https://aistudio.google.com/rate-limit?timeRange=last-28-days&project=gen-lang-client-0137016080).
Sağlayıcı sınırları proje başınadır; günlük yenilenme Pasifik gece yarısıdır.
Dağıtımdan önce yeniden teyit edilir.
[Google kota belgesi](https://ai.google.dev/gemini-api/docs/rate-limits).

Onaylı uygulama sınırı: **20/kullanıcı/gün; 400/toplam/gün;
10/toplam/dakika; 200.000 giriş tokenı/toplam/dakika**. Sayaç günleri
sağlayıcıyla hizalanır; yenilenme yerel saatte gösterilir. Kullanıcı/proje
bütçesi tek atomik sunucu işleminde ayrılır; bellek sayacı kullanılmaz.
İstemci kotayı değiştiremez; kota tablosu fitness senkronuna girmez.
Donmuş istem ve sınırlı soru için temkinli token üst bütçesi ayrılır.
Kota veritabanı erişilemezse model çağrısı yapılmaz.

Aynı projedeki deneyler dışarıdan kota tüketebilir; uygulama sayacı sağlayıcı
erişimini garanti etmez. 429 ayrıca ele alınır. Önerilen operasyon sınırları:
500 karakter soru, 6 saniye model, 10 saniye istemci toplam bekleme; otomatik
tekrar yoktur. Aynı istek kimliği birden fazla model çağrısı başlatmaz;
gönderilmiş başarısız çağrı da bütçe tüketir. Ücretli modele geçiş yoktur.

| Durum | UI |
|---|---|
| Çevrimdışı / oturum yok | Hazır sorular açık; serbest soru için durum açıklaması |
| Günlük kota | Yenilenme zamanı + hazır sorular |
| Dakikalık limit | Bekleme bilgisi + hazır sorular |
| Zaman aşımı / bozuk çıktı | Anlaşılır hata + hazır sorular |
| Desteklenmeyen alan | Yerel seçenek |
| Kapsam dışı | Kısa kapsam açıklaması + hazır sorular |

## 7. Yerel sonuç ve hesap uyumu

Veri, veri erişim nesnelerinden (DAO) toplanır; ekran SQL bilmez. Sonuç:
anlaşılan sorgu/dönem/yerel seçim, **cümle anahtarı + parametreler**, tarih
aralığı ve tamamlanma bilgisi, türüyle kayıt sayıları, veri durumu,
`CommentResult` anahtarları/notları/kaynakları ve yerel hedef rota türüdür.
Veri yok, yorum için yetersiz, hedef yok ve plan yok ayrı durumlardır;
kayıt yok sıfır değer diye sunulmaz. Rotalar `AppRoutes` üzerinden çözülür.

### #8 tamamlanan gün

`nutritionStats` henüz yalnız kayıtlı günleri saymaktadır. Yayından önce
docs/37 ile aynı hesap kullanılır: en az bir tamamlanan gün varsa yalnız
tamamlanan günler; tamamlanan boş gün 0; diğer günler bilinmeyen ve
dışarıda. Tamamlanan gün yoksa yalnız kayıtlı gün özeti, başarı yargısı yok.
Hesap temeli/tamamlanan/dışarıda kalan gün sayıları görünür. Son 30 günlük
protein sorgusu da aynı kuralı kullanır; mevcut kayıtlara yazma gerekmez.

Diğer sınırlar: plana uyum günlerledir ve tarihsel plan yokluğu açıklanır.
Antrenman yorumu önceki sekiz haftanın medyanı/en az dört hafta kuralıdır.
Güç yalnız uygun ağırlık/tekrar setlerindedir. Kalan negatifse aşılan miktar
yargısız gösterilir. Yemek örnekleri seçilen öğünün önceki 30 günündendir;
mevcut fonksiyon kalan **kaloriye** göre süzer, tüm makrolara uyum vaat
edilmez. Yemek otomatik kaydedilmez. Yorum dili docs/36 sınırlarıdır.

## 8. Gizlilik ve ilk gönderim onayı

İlk serbest sorudan önce metin:

> Yazdığın soru, hangi hesabı açacağını belirlemek için Google Gemini'ye
> gönderilir. Fit Pack antrenman, beslenme ve ölçüm kayıtlarını Google'a
> göndermez. Ücretsiz Gemini'de Google soru içeriğini ve model çıktısını
> ürünlerini geliştirmek için kullanabilir; insan incelemesi olabilir.
> Soruna kimlik, hastalık veya özel ölçüm bilgisi ekleme. Hazır soruları
> kullanırsan Google'a soru gönderilmez.

**Kabul et ve gönder / Hazır soruları kullan**. Onay olmadan gönderim yoktur;
onay sürümü hesap kapsamında yereldir, metin değişince yenilenir. Yalnız
soru göndermek kişisel veri yok demek değildir. Açık kimlik/iletişim,
hastalık/belirti ve özel ölçüm paylaşımı saptanırsa yerel seçenekler
gösterilir; kontrol tüm özel bilgileri yakalar iddiası yoktur. Dönem
sayıları ve özel ölçüm paylaşımı ayrı test edilir.

`store: false` geliştirme amaçlı kullanımı kapatmaz; ücretsiz koşullar
hassas bilgi gönderilmemesini ister, onay bunun yerine geçmez.
[Koşullar](https://ai.google.dev/gemini-api/terms),
[Interactions](https://ai.google.dev/gemini-api/docs/interactions).
Soru/cevap/ham sağlayıcı hatası log, hata raporu veya sunucu DB'sine yazılmaz.

## 9. K1 — yerel kalite paneli

Gizli **Geliştirici → Asistan kalitesi** yalnız cihaz sahibinindir; gizli
giriş yetkilendirme sayılmaz. `assistant_quality_events` yerel tablosu
v16'da eklenir; başka şema işi birleşirse sürüm yeniden belirlenir.

Kaydedilen: olay/zaman/yerel hesap kapsamı, hazır-serbest kaynak, sürüm/model/
parmak izi, karar, sorgu/dönem, hareket **türü**, bayraklar, düzeltmenin
sorgu/dönemi veya hareket-değişti bilgisi, netleştirme, tamamlanma/iptal,
gecikme/token ve sınırlı hata nedeni kodu. Bir soru tek olaydır.

Kaydedilmeyen: soru/cevap/metin özeti veya hash, fitness değerleri, gerçek
hareket kimliği/adı, yemek adı, ham sağlayıcı çıktısı.

Panel: haftalık karar dağılımı, gerçekten seçim değiştirilmiş otomatik
cevap oranı, X→Y sorgu değişiklikleri, sorgu dağılımı, medyan/yüzde 95 gecikme,
token ve mevcut ücretsiz maliyet. Hazır sorular model paydasına girmez;
ağ/kota yanlış eşleme sayılmaz. Değiştir'e basmak hata kanıtı, değiştirmemek
doğruluk kanıtı değildir; **düzeltme oranı** gösterilir. Docs/36 iki hafta
üst üste %3 uyarısı korunur; payda görünür, az örnek ayrıca işaretlenir.

Saklama: **90 gün/en çok 5.000 olay**. Senkron/bulut kalite kaydı yoktur.
Hesap değişiminde temizleme/yalıtım açıkça eklenir; mevcut senkron tablosu
temizliği bunu kapsamaz. Tam DB yedekleri tabloyu içerebilir; geri yüklemede
hesap ve saklama sınırı yeniden kontrol edilir. Ham paylaşım anahtarı yoktur.

## 10. Güncellik ve yaşam döngüsü

Fitness verisi/hedef/plan yazımlarında tüm ilgili asistan provider'ları
tazelenir. Senkronun ham yazımları izleyicileri uyandırır varsayılmaz;
mevcut tazeleme akışına eklenir. Sonuç tazeleme yalnız yerel hesap çalıştırır.
Yeni soruda eski ağ sonucu, hesap değişimi/çıkışta önceki hesabın sonucu
atılır. Gün değişiminde bugün hesabı yenilenir. Ekran kapanınca controller/
abonelikler kapatılır; hata/iptalde bekleme çözülür.

## 11. İş düzeni ve uygulama sırası

`feat/assistant`, `/Users/sametorhan/dev/fit_pack-assistant`; başlangıç
`0a8c9de`. Ana klasöre kod yazılmaz; aktif işler defteri mutlak ana yoldadır.
Şema/senkron/sunucu/çeviri/rota/Simulator kilitleri defterde alınır.
Ortak NEXT_TASKS/PROJECT_STATE/README yalnız birleştirme anında güncellenir.

1. Hazır sorular, yerel sonuç, hesap uyumu ve K1.
2. Donmuş eşleme ve sahte sunucu cevaplarıyla UI.
3. Geliştirme ortamı `ask-route`, atomik kota ve entegrasyon testleri.
4. iOS Simulator görsel doğrulama ve Samet incelemesi.
5. Ayrı onaylarla main/push/üretim/fiziksel cihaz.

## 12. Doğrulama kapısı

- Donmuş istem/şema/model/parmak izi ve Python↔Dart karar eşitliği.
- Türkçe ekler/regex, çoklu+tavsiye, enjeksiyon, yük/kilo, dün/yarın.
- Dönem/hareket seçimi, gece yarısı ve yaz saati tarih sınırları.
- Tamamlanan boş/kısmi gün, tamamlanmış gün yok, 30 günlük protein.
- Kayıpsız göç, K1 hesap değişimi/geri yükleme/saklama sınırı.
- Oturum, eşzamanlı kota, tekrar teslim, 429, timeout; anahtar/log sızıntısı yok.
- Çevrimdışı hazır soru/değiştir/netleştirme ağ çağrısı yapmaz.
- Analyze/test, Simulator'da tema/büyük metin/klavye/uzun cevap/boş veri/TR-EN.

Mevcut 120 soru kabul edilmiş başlangıçtır; Jev'de görülmüş set yeni kör
doğrulama sayılmaz. İstem/sözleşme değişince yeni kabul seti gerekir.
İngilizce UI, İngilizce serbest soru kabulü demek değildir; ayrı kayıt tutulur.
Ölçütler: yanlış otomatik ≤%3, geri dönüş ≤%30, kapsam dışı ret ≥%95,
kritik 0; yüzde 95 üst sınır raporlanır, ek geçiş şartı yapılmaz.

## 13. Geri dönüş ve kapsam dışı

Serbest soru kapatılınca hazır sorular kalır; model fitness kaydı yazamaz.
V16 sonrası güvenli geri dönüş v16'yı anlayan sürümde özelliği kapatmaktır;
v15 uygulamasının v16 DB açacağı varsayılmaz. Program seçimi, yeni yemek,
şeker alanı filtresi, sağlık entegrasyonu ve K2/K3 ayrı işlerdir. Docs/37
silinen kayıt sonrası gün durumu ve eski senkron testleri ayrı açık işlerdir.
