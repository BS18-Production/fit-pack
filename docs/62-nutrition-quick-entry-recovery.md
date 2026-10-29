# Beslenme hızlı ekleme: güvenli geri dönüş

## Karar özeti

Geçmiş öğünü kopyalama, son kullanılan miktarla tek dokunuşla ekleme ve
porsiyon düzenleme mevcut. Favoriler yok; yeni kalıcı tercih sistemi yerine
mevcut hızlı girişte doğrulanan sürtünme düzeltiliyor: miktar panelinde sistem
Geri listeye dönecek, geri alınan porsiyon sonraki hızlı eklemede kullanılmayacak,
açık panelin hedef günü korunacak. Pozitif kesirli gram girişleri sessizce
1 grama yükseltilmeyecek.

Yazma ve geri alma sürerken ikinci işlem engellenecek. Mevcut hesap sahipliği
kontrolü, hızlı girişin yerel transaction sınırında kullanılacak; eski panelin
ekleme/geri alma işlemi yeni hesaba taşınmayacak. Şema, besin hesabı formülleri,
çeviri, navigasyon ve sunucu değişmez. Kullanıcı yetkisi bu ayrı geliştirme
turunu kapsar; ek karar gerekmiyor.

## Kapsam ve kaynak

- Kaynak: `fit_pack-sprint-integration`, HEAD
  `daf0b92ae58cec98872c02b4cf3b1e70144ba7a5` ve 29 Ekim anlık yerel değişiklikleri.
- Bağımsız kaynak anlık görüntüsü: `fitpack-nutrition-next`, dal
  `codex/nutrition-logging-next`. Kaynağa ve önceki pakete yazılmaz.
- Sahiplik: `lib/features/nutrition/add_food_sheet.dart`, beslenme kapsam
  yardımcısı, odaklı yeni test ve bu belge. Ortak çeviri/rota/şema dosyası yok.
- Dış manifestte dosya SHA-256 değerleri, kaynak durumu ve zaman bilgisi var.

## Doğrulama

Odaklı widget/veri testleri: arama → miktar → Geri → liste → Geri → kapat;
iptal veri yazmaz; yanlış miktarı ekle/geri al/yeniden hızlı ekle; gecikmeli ve
başarısız geri alma; tarih değişimi; hesap değişimi; kesirli gram ve makrolar.
Ardından beslenme testleri, analiz ve tam Flutter test paketi. Render kontrolü
sentetik test verisiyle; native build/gerçek cihaz kurulumu bu turda yok.

## Uygulanan davranış

- Sistem Geri, miktar adımından arama/listesine döner; sonraki Geri kapatır.
- Geri al, yalnız son eklenen kimlikleri siler; önceki son-besin listesini ve
  panel boyunca kullanılan tüm miktar haritasını geri getirir.
- İşlem sürerken ikinci ekleme/geri alma ve kapatma engellenir. Panel kapatma
  yolu Bitti ve sistem Geri'dir; dışarı dokunma ve sürükleyerek kapatma kapalıdır.
- Açık panel hedef gününü korur. Hesap A → B → A olsa bile eski panelin log
  ekleme/geri alma kapsamı kalıcı olarak geçersizleşir. Aynı hesapta token
  yenileme kapsamı bozmaz. Yerel işlem, yazmadan önce/sonra sahipliği kontrol eder.
- Pozitif kesirli gram korunur; azalt düğmesi alt sınırda miktarı artırmaz.
- Uzun porsiyon adı artık miktar giriş kutusunun içinde yer kaplamaz. Birim
  açıklaması ayrı satırda, hazır miktarlar gerektiğinde alt satıra geçer.
- Kategori şeridi 48 dp dokunma alanına çıkarıldı. Çeviri/rota değişmedi.

## Kapsam sınırı

Hesap kontrolü normal besin kaydı, hızlı kalori kaydı ve bu paneldeki geri alma
ile sınırlıdır. Özel besin oluşturma, barkod ve OpenFoodFacts katalog yazmaları
önceden var olan ayrı akışlardır; bu turda güvence altına alındıkları iddia edilmez.
Favoriler için yeni kalıcı model eklenmedi. Üretim/Dev veritabanına, cihazlara,
ana dala veya önceki sprint paketine değişiklik yapılmadı.

Bağımsız incelemede bulunan kesirli azaltma, dokuzuncu besinde miktar unutulması,
ve sürükleyerek kapanma sorunları düzeltildi; her biri regresyonla kapsandı.
Son doğrulama: 27 yeni test (11 widget, 14 hesap kapsamı, 2 büyük yazı render)
geçti. Tam Flutter paketi 1.385/1.385 (2 dk 48 sn), `flutter analyze --no-pub`
0 sorun (9,9 sn), doküman denetimi 117 dosyada 0 sorun. İlk denemelerde iki
test düzeneği bulgusu düzeltildi (tooltip widget türü ve hesap değişiminden
sonra gizlenen düğmeye erişim); son çalıştırmalarda başarısız test yok.

macOS bazı Documents kaynaklarını `dataless` yaptığı için ilk araçlar kaynak
okumada bekledi. Son doğrulama `/tmp/fitpack-nutrition-verify-final` içindeki
birebir kaynak koduyla yapıldı. Doğrulama tabanının ilk anlık görüntüden tek
farkı `docs/61-sprint-integration.md`; uygulama ve test tabanı aynı. Doküman
bağlantı denetimi için kaynakta bulunan 9 git-dışı eski log da doğrulama
kopyasına getirildi. Üretim kaynaklarına yazılmadı.

Render testleri Flutter hatalarını başarısızlık sayar. Ortak
`app_a11y_guidelines_test.dart` testinin hata yakalayıp yalnız yazdırdığı
inceleme notu koordinatöre iletildi; ortak test dosyası bu dalda değiştirilmedi.
Cihaz/emülatör görsel kabul testi, native build yasağı nedeniyle yapılmadı;
izole widget render görüntüleri cihaz kanıtı olarak sunulmaz.
