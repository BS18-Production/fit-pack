# 58 — Ürün verisi ve kontrollü destek, Faz 1

## Karar özeti

Samet'in 29 Ekim 2026 tarihli açık uygulama onayı: **A1–A8 + B1 + C1**.
Amaç, kullanım ölçümünü ve belirli bir hesap için kayıt kapsamı desteğini
aynı mevcut Supabase altyapısında, farklı erişim sınırlarıyla sunmak.
Ham ürün olayları **30 gün**, tercih geçmişi ve yönetici erişim günlüğü
**180 gün** saklama hedefiyle temizleme kodu hazırlanır; fiziksel silme bakım işi etkinleştirilmeden garanti edilmez. Hesapla ilişkilendirilen kimlikler anonim değildir.
Analitik izni, pazarlama veya kişiselleştirilmiş gönderim izni değildir.
Bu faz gönderim, sağlık profillemesi veya otomatik öneri yapmaz.

**Temel:** `main@daf0b92`. Bildirim dalı `feat/notification-planner`
(`d1a236a`, build 4) bağımsız ve korunur; bu iş onun birleşmesini gerektirmez.
Ana dalın kaynak sürümü build 2'dir; pubspec build numarası değiştirilmedi.
Yalnız temiz Dev simülatörü testinde komut seviyesinde build10003/10004 kullanıldı.
Senkron şeması ve vücut verileri değiştirilmez. Flutter'ın yerel analitik
kuyruğu, mevcut tercih saklama kalıbında, ayrı sürümlü bir anahtarda tutulur.

**Gerçek veriye etki:** kaynak geliştirme yalıtılmış dalda yapıldı. Sonraki
açık Dev test onayıyla yalnız Fit Pack Dev'e şema/function uygulandı ve
sentetik Auth/MFA hesaplarıyla sınandı. Test sonunda collection/admin
bayrakları ve iki sentetik admin rolü kapatıldı. Üretim göçü/yetkisi,
yayın, birleştirme ve push yapılmadı. Migration başlangıçta boş yönetici
listesi oluşturur; mobil tercih varsayılan kapalıdır. Gerçek kişilerin sağlık
kayıtları okunmadı. Yürütme kanıtları özel yerel teslim paketindedir; çalışma zamanı raporları ve ekran görüntüleri açık depoya dahil edilmez.

### Kapsam

- A1: iç hesap kimliği, maskeli e-posta, kayıt/doğrulama/kurulum durumu.
- A2: build/sürüm, platform, yalnız ana işletim sistemi sürümü, ortam.
- A3: ziyaret başlangıcı ve kaba süre aralığı; kalıcı cihaz kimliği yok.
- A4: sabit kurulum adım kodları, cevaplar yok.
- A5: yalnız izinli hata/ekran kodları; ham günlük, URL ve istisna metni yok.
- A6: yön/sonuç/hata kodu, kuyruk ve süre aralıkları; kayıt içeriği yok.
- A7: sürümlü açık analitik tercihi ve nesil numarası; geri alma kuyruğu siler.
- A8: kim, hedef hesap, destek nedeni, istek, zaman, sonuç/satır sayısı.
- B1: antrenman başladı/kaydedildi, rutin/serbest, canlı/geçmiş; isim/değer yok.
- C1: hesap başına kategori sayıları ve son sunucu kayıt zamanları; kayıt
  satırları, kilo/tekrar/öğün/ölçüm değerleri ve serbest metin dönmez.

B2/B3/B6, C2–C7 ve D grupları dahil değildir. Fotoğraf/adım taşınmaz.

### Kabul sözleşmesi

1. Tercih kapalıyken ürün olayı tutulmaz/gönderilmez. Açma sunucu onayı ister.
2. Yerel kuyruk en fazla 500 olay ve 7 gündür; olaylar hesap/izin nesli taşır.
3. Geri alma yerelde derhal siler; çevrimdışı geri alma yeniden bağlanınca
   diğer gönderimlerden önce sunucuya gider. Sunucu güncel olmayan nesli
   reddeder. İnternetsiz cihaz, sunucudaki tercihi anında değiştiremez.
4. Tekrar gönderim aynı event_id'yi çoğaltmaz; hesap değişimi kuyruk kimliğini
   yeniden damgalamaz. Analitik hatası kullanıcı kaydını engellemez.
5. Sunucu şeması ek/ham alanları reddeder; sorgular sınırlı ve parametrelidir.
6. Özet rolü bireysel desteği açamaz; normal kullanıcı yönetimi açamaz.
   Destek isteği sunucu yetkisi ve gerekçe ister; denetim yazılamazsa veri yok.
7. Panel geçmiş ölçümü varmış gibi doldurmaz; veri kapsamını, paydaları,
   ölçüm başlangıcını ve güncel olmayan bilgiyi gösterir.
8. Hesap silme analitik veriyi de kaldırır; saklama işi eski olayları ve
   tercih/denetim geçmişini sürelerine göre temizler. Destek görüntüsü ayrı
   sağlık kopyası yaratmaz, önbelleğe alınmaz.

## Yerel uygulama ve doğrulama

### Dosyalar ve veri akışı

- `lib/features/analytics/`: kesin olay sözleşmesi → hesap/izin nesline bağlı,
  500 olay/7 gün sınırlı SharedPreferences kuyruğu → mevcut Supabase Auth ile
  `product-data` Edge işlevi. Yerel iş verisi/Drift şeması değiştirilmedi.
- Ayarlar ve kurulumun ilk sayfasında isteğe bağlı, kapalı başlayan tercih.
  Açma onay diyaloğu ve sunucu onayı ister; hesap değişmişse eski diyalog
  yeni hesaba izin veremez. Derleme kapalıyken oturumlu kullanıcıya açık
  sunucu tercihi geri çekme düğmesi sunulur.
- App yaşam döngüsü; kurulum adım kodları; başarılı antrenman kaydından sonra
  B1; eşitleme sonucu gözlemleri. Analitik işlemler iş kaydının sonucunu
  değiştirmez. İlk kurulumda tercih verilmediyse önceki adımlar geri doldurulmaz.
- `supabase/migrations/20261029083943_product_data_phase1.sql`: özel tablolar,
  izin/ingest için aynı hesap kilidi, nesil kontrolü, event_id tekilleştirme,
  sunucuda rol/MFA ve denetim kaydı, sınırlı temizleme işlevi.
- `tools/admin/phase1/`: özet ve kontrollü hesap desteği; mevcut Supabase
  Auth/TOTP ile giriş, tarayıcı belleğinde oturum. Canlı yapılandırma boş;
  sentetik demo hiçbir kullanıcı sorgusu veya erişim kaydı oluşturmaz.

### Etkin davranış ve sınırlamalar

Ham olaylar sunucunun **alma zamanından 30 gün** sonra; tercih/erişim geçmişi
180 gün sonra temizlenmeye uygundur. `phase1_retain()` her kategori için en
çok 5000 satır siler. Fiziksel silme için ayrıca onaylı zamanlama ve kuyruk
izleme gerekir; henüz cron oluşturulmadı. Özet, 30 günden eski alınmış ham
olayları temizleme çalışmasa da dışlar. Bağımsız kalıcı özet kopyası yoktur.
Geri çekme ham olayları siler. Hesap silme analitik tercihi/geçmişi/olayları ve
admin atamasını zincirler; minimal erişim denetimi ayrı 180 gün politikasına
bağlıdır. Mevcut tercih, geçmişin süresi dolunca eski istemciyi açmamak için
hesap var oldukça korunur.

Çevrimdışı geri çekme derhal yerel toplamayı kapatır ve sıradaki gönderimden
önce sunucuya iletilir. Disk ve ağ aynı anda arızalıysa kalıcı geri çekme
garantisi yoktur; UI hata gösterir, bellekten toplama kapanır. Ön planda
60 saniyelik sınırlı yeniden deneme vardır; arka planda çalışmaz. Android OS
sürümü güvenilir biçimde ayrıştırılamazsa 0=bilinmiyor. Ziyaretler kişi sayısı
veya tüm kullanıcı kitlesi değildir; küçük pilot örnekleri ve izin seçimi
özetleri etkiler. Panel bu kapsamı/paydayı ve geçmiş eksikliğini gösterir.

### Bağımsız inceleme

Claude Code kurulu Pro oturumuyla, ayrı tek seferlik araçsız ve kalıcı oturum
oluşturmayan **sözleşme incelemesi** yaptı; kaynak kodu incelemesi değildir.
Yeni plan/API anahtarı/extra usage açılmadı. İzin-kilit yarışı, replay,
kapalı başlangıç, saklama, audit ve kapsam yanlılığı önerileri mevcut
sözleşme/testlerle karşılaştırıldı. Eski request_id tekrarına tarihsel açma
onayı yerine **güncel tercih** dönmesi bilinçli güvenlik kararıdır.

Ayrı Codex incelemesinde bulunan sürüm sözleşmesi uyumsuzluğu, toplama
kapatılırken geri çekmenin engellenmesi, açık izin diyaloğunda hesap değişimi
ve kapalı derlemede geri çekme erişimi düzeltildi. SQL çalışma zamanı
incelemesinin yerini bu kontroller tutmaz.

### Yayına geçiş ve geri dönüş

Kod yereldir; bulutta bu göç/işlev/rol/zamanlama etkinleştirilmedi. Üretim
yayını sayılmaz. Önce izole test Supabase ortamında SQL paketi, roller,
MFA, audit hata davranışı, kilit yarışları ve silme zinciri yürütülmeli.
Deno giriş bağımlılık/tip kontrolü ve gerçek geliştirme MFA akışı denenmeli.
Sonra eylem anında göç, rol ataması, origin/etkinleştirme ve yayın onaylanmalı.
Mevcut geniş tablo grant'leri bu pakette değiştirilmedi; ayrı inceleme konusu.

Geri dönüş: sunucu toplama/yönetim bayraklarını ve mobil rollout'u kapat;
tercih sorgulama/geri çekme açık kalır. Eklemeli tabloları yerinde bırak;
yıkıcı DROP veya iş verisi geri dönüşü gerekmez. Admin ataması geri alma ve
mevcut veriyi silme ayrı onaylı işlemlerdir. Kişiselleştirilmiş/işlevsel bildirim
ve pazarlama tercihleri ayrı amaçlardır; bu paket bunlara izin veya gönderim
oluşturmaz. Sağlık bağlamının pazarlamada kullanımı rızayla otomatik serbest
olmaz: [Apple kuralları](https://developer.apple.com/app-store/review/guidelines/#health-and-health-research).

### Doğrulama kaydı

Nihai komut sonuçları özel yerel doğrulama paketinde kaydedilir.
Masaüstü/mobil panel görüntüleri aynı dizindedir; tamamı sentetiktir.
