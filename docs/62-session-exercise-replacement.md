# Seans içinde hareket değiştirme

## Karar özeti

Ekipman doluyken mevcut hareket seçicisinden başka hareket seçilir. Tamamlanan
ve herhangi bir değeri/türü girilmiş setler eski hareket altında kalır. Yalnız
boş setlerin sayısı yeni harekete aktarılır; boş set yoksa yeni hareket bir
boş setle başlar. Yük, tekrar ve ilerleme önerisi farklı harekete taşınmaz.
Yeni hareket kendi geçmişini kullanır. İptal ve aynı hareket seçimi değişiklik
yapmaz. Bu davranış, kullanıcının paralel geliştirme yetkisi kapsamındadır.

Geçmiş kayıtlar ve rutin tanımı değişmez. Yalnız seçilen seans bloğu etkilenir.
Taslak önce kaydedilir; yeni durumun yazımı başarılı olmadan ekran değişmez.
Hesap/taslak nesli değişirse işlem uygulanmaz. Hesap kimliği değiştiği anda
eski set/mola komutları ve sıradaki yayınlar geçersizleşir; hesap temizliğinin
bitmesi beklenmez. Aynı hesaba geri dönmek eski seansı canlandırmaz. Hesap
izleyicisi ekran kapansa da bekleyen yazma bitene kadar yaşar. Taslak okuma da
yazma kuyruğundadır; doğrulanmamış önbellek yeniden açılışa taşınmaz. Taslak yazımı ile temizliği
sıralanır; başarısız yazım yeniden denemeyi engellemez. İşlem sırasında seans
etkileşimleri ve native komutlar bekler. Sonrasında set komut anahtarı yenilenir.

İlk dilimde değiştirme menüsü yalnız ağırlık/tekrar ve tekrar ölçümlü kaynak
hareketlerde gösterilir. Seçilen yeni hareket herhangi bir ölçüm tipinde olabilir.
Süre/mesafe kaynaklarında çalışan set sayacını taşıma bu dilimin dışında.
Başka bir hareketin sayacı değişiklik sırasında biterse yeni süresi aday taslağa
ayrıca yazılır. Girilmiş ama tamamlanmamış eski setler yeni hareketin arkasında
kalır; canlı kart önce seçilen hareketi gösterir.

Şema, sunucu, bağımlılık veya rota değişikliği yok. Taslağa isteğe bağlı
`sessionOnly` işareti eklenir: seçilen hareket rutinde zaten olsa bile yeniden
açıldığında seansa özel kalır; mola değişikliği rutine sızmaz. Eski taslaklar
eskisi gibi okunur. Eski uygulama sürümü bu işareti yok sayar; eski sürüme
dönüşte seansa özel mola bağlantısı korunmayabilir. JSON biçimi okunabilir kalır.
SharedPreferences yazımı ani güç kaybına dayanıklı transaction garantisi değildir.

## Kaynak ve sahiplik

- Kaynak: `/Users/sametorhan/dev/fit_pack-sprint-integration`, HEAD
  `daf0b92ae58cec98872c02b4cf3b1e70144ba7a5`, çalışma dosyaları dahil.
- Ayrı snapshot: `task-7/fitpack-workout-replacement`, dal
  `codex/workout-replacement`, başlangıç `2fc63d7d548beae44052bf34bc3ea33aabd3e749`.
- 1.054 dosyanın kopyalama öncesi/sonrası SHA256 değerleri eşleşti.
  `../workout-replacement-baseline.json` kaynak kanıtıdır.
- Sahip: bu iş; aktif seans, hareket menüsü/modeli, taslak servisi,
  `asReplace*` çeviri anahtarları ve ilgili testler. Ana kaynaklar, ortak
  aktif işler defteri ve diğer çalışma kopyaları yalnız okundu.

## Doğrulama planı

Tamamlanan/boş/girilmiş setler; farklı ölçüm tipi; aynı hareketin iki bloğu;
iptal/aynı seçim; yeniden açılış ve geçmiş/rutin değişmezliği; yazım hatası ve
yeniden deneme; seçim/yazım sırasında hesap temizliği; bayat native komut.
Odaklı testler, analiz ve tam Flutter takımı. Native build/cihaz kurulumu yok;
gerçek cihaz görsel doğrulaması bu dilimin teslim sınırı olarak raporlanacak.

## Son doğrulama — 29 Ekim 2026

- Tam Flutter takımı: **1404/1404**, 2 dakika 49 saniye, çıkış 0.
- Yeni kapsam: 8 saf dönüşüm + 16 taslak sıralama/okuma + 22 ekran testi.
- Analiz: **0 sorun**. Doküman bağlantıları: **117 dosya, 0 sorun**.
- Ekran testlerinde gerçek seçim rotasının sözleşmesini kullanan sentetik
  seçici var; native arayüz veya gerçek cihaz doğrulaması değildir.
- Hesap geçişinden hemen sonra, frame/temizlik beklemeden eski komut reddi;
  A→B→A; seçim/başarısız kayıt sonrası boşluk; bekleyen kayıt sırasında hesap
  değişimi; dispose sonrası hesap değişimi; farklı blokta biten sayaç; ikinci
  yazma hatası sonrası dispose ile yeniden kayıt test edildi.
- Mevcut rutin/geçmiş kayıtlar, tamamlanan ve girilmiş setler korunur;
  aynı hareketin başka bloğu değişmez. İptal ve aynı seçim no-op.

Documents/FileProvider bazı dosya okumalarını durdurdu; oradaki tam test henüz
başlamadan durduruldu. Kaynağın hash ile eşleşen yerel doğrulama kopyası
`/tmp/fitpack-workout-replacement-verify-final` üzerinde tüm takım tamamlandı.
`verification-manifest.json` dosya kanıtıdır. Yalnız analiz gereği eklenen if
süslü parantezleri davranış değiştirmeyen son biçim düzeltmesidir. Eksik dokuz
ignore edilmiş tarihsel Faz1 logu kaynak entegrasyondan birebir kopyalanınca
belge bağlantıları da geçti; bu loglar yeni test sonucu olarak sunulmaz.

Kaynak snapshot'ın Git indeksi bekleyen dosya okuması nedeniyle kilitliydi;
yeni commit oluşturulmadı. Teslim yaması başlangıç dosyalarına `git apply
--check` ve gerçek uygulama sonrası SHA256 karşılaştırmasıyla doğrulanır.
Üretim/Dev, push/merge, native build/kurulum, kimlik bilgisi, izin veya şema
işlemi yapılmadı. Süre/mesafe kaynak hareketlerini değiştirme ve gerçek cihaz
arayüz turu kapsam dışında kaldı. Kalıcı depolama bozukken veya süreç aniden
sonlandırılırken yeni bir dayanıklılık garantisi verilmez.
