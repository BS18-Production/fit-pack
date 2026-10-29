# 60 — Kilit ekranı komutlarının hedefi

29 Ekim 2026 · Yetki: Samet'in paralel antrenman güvenilirliği sprinti.

## Karar özeti

Aynı hareketin iki ayrı kullanımı `exerciseId:setIndex` anahtarını paylaşır.
Android ayrıca eski PendingIntent'in extras alanını yeni setle değiştirebilir.
Mola eylemleri ise hedef kimliği taşımıyor. Sonuç: gecikmiş dokunuş başka
seti veya molayı değiştirebilir.

Öneri: yaşayan set nesnesi ve kartta gösterilen değerler için opak bir
komut anahtarı; mola bitişi için ayrı anahtar. Aynı görüntü aynı anahtarı
korur, hedef/değer değişince yeni anahtar üretilir. Set ile mola anahtarları
ayrıdır: sistem mola bitince Dart uyanmadan sıradaki seti gösterebilir.

Kalıcı taslak, veritabanı, senkron, kullanıcı hedefleri ve mevcut doldurma
kuralı değişmez. Anahtarlar yalnız yaşayan kart için üretilir; yeniden
açılışta eski kartın komutu reddedilir. Kalıcı UUID/göç gerekmez. Önceki
uygulamaya dönüşte kayıt biçimi aynıdır.

Samet'ten ek karar gerekmiyor: bu, verilen güvenilirlik düzeltmesi kapsamıdır.
Kilidi açmayı aşma, zamanlayıcıyla set tamamlama, seans küçültme, yeni
bildirim veya yeni sağlık/veri erişimi kapsam dışıdır.

## Davranış

- Tamamla ve ± yalnız görünen set/değer anahtarına uygulanır. Son seti
  geri almak önceki tamamla komutunu tekrar geçerli kılmaz.
- ± sonrasında eski kartın tamamla/± komutu reddedilir; güncel kart geçerlidir.
- Mola sırasında set komutu reddedilir; mola doğal bitince önceden kartta
  bulunan sıradaki set anahtarı geçerlidir.
- Mola ekle/atla yalnız etkin molanın anahtarıyla çalışır. Süre eklemek
  anahtarı değiştirir; aynı komut tekrar teslim edilirse iki artış olmaz.
- Android eylem anahtarı PendingIntent kimliğine (data URI) de katılır;
  extras tek başına kimlik değildir.
- Bitiriş, dispose veya dışarıdan taslak silme sırasında native komut yoktur.
- Dış temizlikte yayın nesli değişir. Önceki seansın bekleyen yayını ve
  kapanışı yeni seansa uygulanmaz; yeni seans kendi kartını başlatabilir.
- Taslak yazımı/kart başarı sırasına yönelik geniş refaktör yapılmaz;
  SharedPreferences'in crash-dayanıklılığı hakkında yeni garanti verilmez.

## Doğrulama

Önce kırmızı, sonra yeşil regresyonlar: yinelenen hareket, değişen değere
bayat komut, kaldırılıp yeniden eklenen set, yinelenen mola komutu, eski
moladan yeni molaya gecikmiş komut ve doğal mola bitişi. Mevcut taslak,
doldurma, bitiriş ve canlı köprü testleri; analyze ve tam Flutter testleri.

Fiziksel cihazda gerçek kilit/Face ID, native kart boyutu ve Android
bildirim davranışı ayrıca doğrulanmalıdır. Bu sprintte cihaz kontrolü yok;
main QA başka oturumda. iOS'ta uygulama UI'sinin açılmaması, kimlik
doğrulamanın hiç gerekmemesiyle eş tutulmaz.
