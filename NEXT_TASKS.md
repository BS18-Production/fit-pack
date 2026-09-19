# Fit Pack — Sıradaki İşler (NEXT_TASKS)

## 🧭 Güncel sıra — Samet onayı (2026-09-17 akşam)

ChatGPT değerlendirmesi sonrası sıra değişti: taslak kaybı haftalık
değerlendirmeden önce kapanıyor; senkron v2 fotoğraflardan ve öğün
kopyalamadan öne alındı (aynı hesap birden fazla cihazda açık — telefon +
iOS simülatörü; haftalık raporun güvenilirliği kayıtların güvenilirliğine
bağlı).

1. **Sağlamlık paketi** — ✅ kodlandı; yalnız Android girişi Samet'le birlikte bekliyor.
2. **#1 Haftalık değerlendirme + hedef yönü + haftalık bildirim** (docs/21).
   Samet'in kuralları:
   - Beslenme ortalaması = **kayıt girilmiş günlerin** ortalaması; kaç gün
     kayıt olduğu yazılır. **Eksik kayıttan hedef başarısı/başarısızlığı
     çıkarılmaz** (kayıtsız gün = bilinmiyor). #8 "gün tamamlandı" senkron
     v2'yi beklediği için ilk sürüm bu kuralla çıkar.
   - Hedef yönü **geçmişe uygulanmaz**: yalnız bu haftanın yorumu ve gelecek
     haftanın odağında kullanılır; değişiklik tarihi saklanır.
   - İlk sürümde puan yok, grafik az; somut cümleler ("3 antrenman; 4 günde
     beslenme kaydı; önceki hafta kilo ölçümü yok"). Tek ölçüm varsa
     sınırlılığı yazılır. Farklı hareketler tek "gelişim puanı"na toplanmaz.
   - Bildirim kısa, dokununca bu ekran açılır. Hedef kullanıcı onayı olmadan
     değişmez.
3. **Senkron v2** (docs/20, ~10 gün). Sunucu test ortamı kuruldu:
   `Fit Pack Dev` bulut projesi (docs/20 §10.4) — yerel Docker kurulmuyor.
   Mevcut yerel ve bulut kayıtlarının kimlikleri korunarak taşınması da
   sınanır (S-18 + katalog kimliği taşıması), yalnız yeni kurulum değil.
4. **#4 İlerleme fotoğrafları** (docs/19 dilim 1, yalnız cihazda) + **#2
   "geçmişten öğün kopyala"**.
5. Diğerleri (docs/21 sırası): #8 → #5 → #7 → #2 tam → #10, #9, #13, #12.

## 🔵 Senkron v2 — Aşama 0 ✅ ve yerel ortam (2026-09-18)

- [x] **Sunucu test ortamı — `Fit Pack Dev` ✅ (2026-09-18):** Samet'in
      kararıyla yerel Docker yığınından vazgeçildi (~9,7 GB disk; bu projede
      disk iki kez yolu tıkadı). Yerine **ikinci ücretsiz bulut projesi**:
      `Fit Pack Dev` / `qecbnrkbordkqeogmevi`, eu-central-1. İki migration
      kuruldu (12 tablo, RLS açık, yetkiler verildi), pgTAP 1.3.3 `extensions`
      şemasında açıldı ve örnek testle doğrulandı. Ayrıntı + sıfırlama ve
      istemciyi yöneltme komutları: **docs/20 §10.4**.
      - Ücretsiz plan organizasyon başına 2 aktif proje veriyor; **ikisi de
        doldu** — üçüncü proje açılamaz.
      - Ücretsiz proje 7 gün dokunulmazsa duraklar, panelden ~1 dk'da uyanır.
      - Supabase CLI 2.117.0 kurulu duruyor (`db reset --linked` için).
      - Eski yerel kurulum denemesinden iki tuzak kayda geçti: Docker
        Desktop'tan kalan `credsStore: desktop` imaj indirmeyi engelliyor;
        colima'nın varsayılan DNS'i imaj sunucularını çözemiyor.
- [x] **Aşama 0 — kırmızı testler** (`test/features/sync_v2_stage0_test.dart`):
      S-1 (uçuştaki düzenleme), S-2 (aynı saniyedeki iki düzenleme), S-4
      (çekme sırasında ekleme), S-6 (düşen tetikleyicinin onarımı). Dördü de
      bugünkü kodda kırmızı olduğu görülüp `skip` ile işaretlendi. S-3 (süreç
      ölümü) zaten yeşil (sync_push_test T-1).
- [x] **Sunucu SQL'leri `supabase/migrations/` altına alındı** — yerel yığın
      şemayı buradan kuruyor; `supabase db reset` / `supabase test db` (pgTAP)
      için gereken standart düzen.
- [x] **Aşama 1 — yerel sağlamlık ✅** (şema **v11**): milisaniyelik damga
      (`changed_at_ms`), cihaz sayacı (`local_seq`), `server_rev`;
      `sync_meta` (capture/next_seq) ve `sync_tombstones` tabloları; 36
      tetikleyici (insert/update/**delete**), hepsi `capture` bayraklı;
      temiz işaretleme artık sayaca bakıyor; çekme tetikleyicileri
      düşürmüyor, yalnız inen satırlar yazılırken susturuyor; açılışta
      onarım (eksik tetikleyici + kapalı kalmış bayrak).
      **Aşama 0'ın dört testi yeşile döndü**; v10→v11 göç testi (7 test).
      analyze 0 · test **368/368**.
- [x] ~~ENGEL — simülatör derlemesi~~ → **çözüldü (2026-09-18):** Samet'in
      kararıyla Claude sanal makinesi silindi (11 GB), iOS platformu geri
      indirildi, simülatör çalışıyor. **Ders:** "bu bileşen kullanılmıyor"
      demeden önce bir derleme denenmeli — iOS 26.5 Xcode'un tek iOS
      SDK'sıymış. Disk: temizlik +17,6 GB, Claude VM +11 GB, geri indirme
      −19 GB, Docker VM +9,7 GB (kaldırıldı) → şu an **17 GB boş**.
      Eski kayıt:
      disk temizliğinde silinen **iOS 26.5 platformu** meğer kullanılıyormuş:
      Xcode'un tek iOS SDK'sı o ve silinince `flutter run` hiçbir simülatör
      hedefi bulamıyor ("iOS 26.5 is not installed"). Yeniden indirme **8,5 GB**
      istiyor, diskte **~4 GB** boş var (Supabase imajları + Docker sanal
      makinesi ~9,7 GB yer aldı). Aşama 1 bu yüzden simülatörde
      doğrulanamadı — testler yeşil ama cihazda görülmedi.
      **Samet'in kararı gerekiyor:** (a) Docker sanal makinesini kaldır
      (~9,7 GB; yerel Supabase Aşama 3'te yeniden kurulur), (b) Android
      emülatörünü kaldır (~13 GB; "Android'e dokunma" kararına aykırı),
      (c) kişisel büyük dosyalardan yer aç (Claude sanal makinesi 12 GB,
      Chrome modeli 4 GB, duvar kağıtları 3,7 GB).
- [x] **Aşama 2 — açılış ve kapı ✅** (docs/20 §7.1, §7.3–§7.5):
      • `bootstrap` artık **yerel hesap kontrolünü** de çalıştırıyor.
      • Nötr açılış ekranı (`/splash`): kapı karar verene kadar Karşılama
        değil marka işareti görünüyor.
      • **Yarıda kalan hesap temizliği** açılışta tamamlanıyor
        (`switch_in_progress`) — yarım temizlik = önceki hesabın verisinin
        sızması.
      • `last_user_id` shared_preferences'tan senkron defterine taşındı
        (temizlikle aynı veritabanı işleminde güncelleniyor).
      • **Gönderilmemiş kayıt + farklı hesap:** veri SİLİNMİYOR; "N kayıt
        henüz yüklenmedi" ekranı çıkıyor, öne çıkan seçenek geri dönmek.
      • Hesap doğrulanamazsa içeri alınmıyor ("Hesap doğrulanamadı" ekranı,
        Tekrar dene / Çıkış yap).
      • Hesap temizliği artık mezar taşı üretmiyor (üretseydi yeni
        kullanıcının sunucudaki kayıtlarını silerdi).
      18 test · analyze 0 · test **383/383**.
- [x] **Simülatörde gerçek veriyle doğrulandı (2026-09-18):** v10 → v11 göçü
      sorunsuz; 3 seans / 10 set / 2 öğün / 2 ölçüm yerinde, 36 tetikleyici
      kurulu, damgalar dolu, mezar taşı yok, `last_user_id` deftere taşındı.
      **Göç bir kusur gösterdi:** eski tetikleyiciler doldurma sırasında
      çalışıp 28 satırı gereksiz yere yeniden kuyruğa aldı (veri kaybı yok,
      tekrar yükleme). Sıra düzeltildi (önce tetikleyicileri düşür) ve göç
      testine v10 tetikleyicileri eklendi — şema anlık görüntüsünde
      tetikleyici olmadığı için bu hata testten kaçmıştı.
- [x] **Aşama 3 — sunucu sürümü ✅ (2026-09-18)**
      (`supabase/migrations/20260918120000_sync_v2_stage3.sql`):
      12 tabloya `changed_at_ms` + `server_rev`, ortak `sync_rev_seq` dizisi,
      `sync_guard` tetikleyicisi (çakışma kuralı artık sunucuda), çekme imleci
      dizini `(user_id, server_rev)`, gönderimin çakışma hedefi
      `(user_id, uid)` tekil dizini, `deleted_records` tablosu.
      **`Fit Pack Dev`'de 29/29 pgTAP testi yeşil**
      (`supabase/tests/sync_v2_stage3.sql`); migration idempotent (iki kez
      çalıştırıldı). Geçmiş satırlar dolduruluyor
      (`changed_at_ms` = `updated_at` × 1000).
      - **Tasarımdan iki bilinçli sapma:** eşit damga REDDEDİLİR (§5.2'nin
        kuralı; taslak kod istemciyi kazandırıyordu) ve `updated_at` sunucu
        saatinden yazılır. docs/20 §4.2'ye işlendi.
      - **Yeni risk bulundu ve belgelendi — docs/20 §12.1:** `server_rev`
        transaction başında atanıp commit'te görünür olduğu için çekme imleci
        bir satırı kalıcı olarak atlayabilir. Aşama 4 iki katmanla kapatacak:
        imleç payı (1.000) + düzenli tam uzlaştırma.
      - ⚠️ **ÜRETİME UYGULANMADI.** Aşama 4 ile aynı sürümde çıkar: ölçüldü ki
        `changed_at_ms` göndermeyen eski istemcinin GÜNCELLEMESİ sessizce
        reddediliyor (eklemesi geçiyor).
- [x] **Aşama 4 — sayfalı, artımlı çekme + koşullu gönderim ✅ (2026-09-18)**
      - **Gönderim:** `changed_at_ms` artık gönderiliyor (sunucunun çakışma
        ölçüsü); `upsert().select()` dönen satırlar = kabul edilenler;
        `server_rev` yerele yazılıyor. **Ret işleme yeni:** dönmeyen satırın
        sunucudaki hâli `fetchByUids` ile alınıp uygulanıyor ve satır
        kuyruktan çıkıyor — yoksa sonsuza kadar boşuna gönderilirdi.
        Ret çözümü `local_seq`'e bakıyor: o sırada yapılan düzenleme yutulmuyor.
      - **Çekme:** iki aşamalı (ağ / uygulama), tablo başına `server_rev`
        imleci `sync_meta`'da ve **kullanıcıya özel**; sayfa boyu 500 +
        "sunucu fazla döndürürse dur" kontrolü; artımlı — ikinci turda
        değişen yoksa hiçbir satır inmiyor (eskiden her açılışta her şey).
      - **İmleç payı (1.000)** docs/20 §12.1'in birinci katmanı; ikinci
        katman `pullAll(full: true)` olarak hazır (çağıran henüz yok).
      - **Satır uygulama kuralı `SyncApply`'a çıkarıldı** — çekme ve gönderim
        reddi aynı kuralı kullanıyor; çakışma ölçüsü `changed_at_ms`
        (`updated_at` yalnız v2 öncesi satırlar için geri düşüş).
      - **Test altyapısı:** dört ayrı sahte sunucu tek `FakeSyncServer`'da
        birleşti ve artık gerçek `sync_guard` kuralını uyguluyor — "sunucu
        reddetti" durumu eskiden hiç test edilmiyordu.
      - **Eski kırmızı test T-5b yeşile döndü** (Aşama 1'in `local_seq`'i
        çözmüş); `skip` kaldırıldı.
      - **Gerçek PostgREST doğrulaması** (docs/20 §10.5): kısmi kabul, ret,
        sayfalama, `in.()` ve RLS gerçek HTTP çağrılarıyla ölçüldü.
      - **Haftalık tam uzlaştırma kendiliğinden çalışıyor** (§12.1 ikinci
        katman): `full_pull_at:<kullanıcı>` defterde, yalnız temiz biten tur
        damgalanıyor. Çağıranın bir şey yapması gerekmiyor.
      - **Cihaz duman testi ✅** (temiz iOS simülatörü, test projesine bağlı):
        giriş → tam uzlaştırma → profil gönderildi, `server_rev` yerele
        yazıldı. Sunucu tarafında değiştirilince (2200 → 2750) uygulama
        yeniden açılışta değişikliği indirdi, satır kuyruğa geri girmedi,
        imleç payla yazıldı. Yöntem: `supabase/tests/README.md`.
      - analyze 0 · test **396/396** (atlanan yok).
- [x] **Aşama 5 — silme protokolü ✅ (2026-09-18)** — hata #1'i kapatır
      ("sildiğim öğün geri geliyor").
      **Sunucu** (`supabase/migrations/20260918140000_sync_v2_stage5.sql`):
      `sync_mark_deleted` tetikleyicisi (12 tablo) silinen satırın yalnız
      kimliğini `deleted_records`'a yazıyor; `sync_delete` RPC'si tablo adını
      sabit listeye karşı doğruluyor ve gerçekten silinenleri döndürüyor
      (RLS geçerli). 18 pgTAP testi.
      **İstemci:** mezar taşı gönderimi (yazmalardan SONRA, çocuk tablo önce),
      çekmede silme uygulama (işaretler her şeyden önce iner), bekleyen silme
      varken satırın sunucudan geri eklenmemesi, rutin kaydetmede **fark**
      uygulaması (§5.4 — tek hedef değişikliği artık bütün rutini silip
      yeniden yaratmıyor). 14 test.
      - **İki hata yalnız GERÇEK ROLLE ölçünce çıktı** (docs/20 §10.6):
        (a) silme izi tetikleyicisi `auth.users`'a bakıyor ama istemci
        rolünün yetkisi yok → **her silme patlıyordu**; SECURITY DEFINER
        yapıldı. (b) `delete from auth.users` zincirinde işaret yazılınca
        yabancı anahtar ihlali → **hesap silme patlıyordu**; kullanıcı yoksa
        işaret yazılmıyor. **Ders: sunucu testleri istemci rolüyle de koşmalı.**
      - Gerçek HTTP doğrulaması: RPC, işaret okuma, bilinmeyen tablo (400),
        dirilme reddi.
      - analyze 0 · test **410/410**.
- [ ] **Sıradaki: 3 + 4 + 5'i üretime çıkar — TEK SÜRÜM** (docs/20 §11,
      2026-09-19 kararı: `main`'deki uygulama Aşama 5'i içerdiği için sunucu
      da 5'i istiyor).
      - [x] Üretim şeması test projesiyle birebir (139 kolon, parmak izi eşit).
      - [x] **Yedek alındı ve doğrulandı:**
            `~/dev/fit_pack_backups/2026-09-19_senkron_v2_oncesi/prod_data.json`
            (repo dışında). 10 tablonun satır sayısı + kimlik parmak izi
            sunucuyla birebir. Ücretsiz planda panel yedeği yok; bu tek yedek.
      - [x] **Prova** (dolu tablolarla) Aşama 3'te `updated_at`'i ezen bir
            hata buldu; düzeltildi ve yeniden prova edildi (docs/20 §11).
      - [ ] **Telefon bağlı olmalı** — migration uygulandığı anda telefondaki
            eski sürümün güncellemeleri sunucuda sessizce reddedilir.
            Sıra: telefon bağlanır → migration (3 ve 5) → hemen telefona
            kurulum → senkron günlüğü kontrolü → simülatöre kurulum.
      Eski plan:
      1. Üretim projesinin panel yedeğini al.
      2. `supabase/migrations/20260918120000_sync_v2_stage3.sql`'i üretime uygula.
      3. **Aynı gün** uygulama sürümünü cihaza kur.
      Arada eski istemci YAZAMAZ (ölçüldü: güncellemesi sessizce reddediliyor).
      Öncesinde cihazda duman testi: `--dart-define` ile `Fit Pack Dev`'e
      bağlanıp açılış + bir kayıt + senkron (docs/20 §10.3, §10.4).
      **Aşama 5 kendi sürümünde, 3+4'ten SONRA çıkar** (docs/20 §11).
- **Şema sürümü kararı (2026-09-18):** v11'i **senkron v2** aldı (uygulaması
      önce başladı). Haftalık değerlendirmenin hedef yönü alanı **v12** olacak
      — docs/22 §9 soru 4 buna göre güncellendi.

## 🧹 A Paketi — karar gerektirmeyen birikmiş işler (2026-09-18)

Samet: "A'daki tüm maddelerin hepsini yap." analyze 0 · test **357/357**
(+1 belgelenmiş kırmızı).

- [x] **Açılışta Karşılama ekranı kırpması düzeldi** — kök neden: uygulama
      yeniden açılırken diskten gelen oturum olayı "hesap değişimi" sanılıyor,
      `busy` açılıyor ve yönlendirme erteleniyordu. Karar saf fonksiyona
      taşındı (`authActionFor`) + 5 test.
- [x] **Duman testi gerçek oldu** (E-16): `widget_test.dart` artık uygulamanın
      kökünü ayağa kaldırıyor. **Gerçek hata buldu:** Supabase başlatılamazsa
      (ağ yok/yanlış config) kök widget çöküyordu — oysa main.dart "bulut
      opsiyonel" diyor. `syncRemoteProvider` artık istemciyi çağrı anında
      çözüyor.
- [x] **Senkron yarış testleri dürüstleştirildi** (E-15): T-1 artık gerçekten
      dosyayı kapatıp açıyor; T-5 düzenlemeyi **gönderim sırasında** yapıyor.
      Aynı saniyedeki düzenlemenin kaybolduğu durum **kırmızı test** olarak
      işaretlendi (docs/20 Aşama 1 `changed_at_ms` ile yeşile dönecek).
- [x] **Silme bildirimi sekme değişince kapanıyor** — "Geri al" başka sekmede
      anlamsızdı.
- [x] **Yemek grupları (C-5)** — kategori kolonu vardı ama **boştu**: 111 hazır
      yemek gruplandı (et/süt/tahıl/baklagil/sebze/meyve/yağ/hazır yemek/diğer),
      mevcut kurulumlar için geriye dönük doldurma (`seedVersion` 2→3),
      Yemekler ekranına çip filtresi. 9 test.
- [x] **Oturum belirteci güvenli kasada** — düz metin `shared_preferences`
      yerine iOS Keychain / Android Keystore. Göç: eski değer taşınır, geri
      okunarak doğrulanır, ancak o zaman silinir; kasa çalışmazsa eski
      davranışa düşülür (kullanıcı oturumundan olmaz). 9 test + **simülatörde
      gerçek hesapla doğrulandı** (oturum korundu, anahtar prefs'ten silindi).
- [x] **iOS izin metni artık cihaz dilinde** — `Runner/tr.lproj` +
      `en.lproj/InfoPlist.strings`, Xcode projesine variant group olarak
      eklendi; `flutter build ios` ile doğrulandı. Info.plist'teki değer
      diğer diller için yedek (İngilizce).
- [x] **CI'a gecelik iOS derlemesi** (03:30 TSİ, imzasız) — macOS koşucusu
      pahalı olduğu için her push'ta değil.
- [x] **"+1.25 kg" satır sonunda bölünmüyor** (bölünmez boşluk).
- [x] **Duplike hareket teşhisi (#1) — temiz:** gerçek cihazdaki 1015 harekette
      kelime sırası/noktalama çakışması **0**. Kaynak veriye kalıcı test
      eklendi (yeni varyant eklenirse yakalanır).
- [x] **Bayat çıktı:** ana sayfa istatistikleri (H-05) zaten reaktif —
      `FutureProvider` kalmamış; atıf ekranı (C-6) zaten var ve Ayarlar'a bağlı.
- [x] **Supabase CLI kuruldu** (2.117.0) + Docker istemcisi ve colima
      (yönetici şifresi gerektirmeyen yol) kuruldu.
- [x] ~~Docker ENGELLİ — disk~~ → **gereksiz kaldı (2026-09-18):** yerel
      Docker yığını yerine ikinci bulut projesi `Fit Pack Dev` kullanılıyor
      (docs/20 §10.4). Disk sorunu bu iş için ortadan kalktı.

## 🧰 Süreç — ChatGPT değerlendirmesi sonrası (2026-09-17)

- [x] **Tasarım dokümanı eşiği artık etkiye bağlı** (CONVENTIONS §7b): kalıcı
      veri / hesap-senkron-silme-yedekleme / geri dönüşü pahalı karar / birden
      çok özelliği bağlayan kural → doküman. Diğerlerinde problem + beklenen
      davranış + doğrulama yeter.
- [x] **Tasarım dokümanları "Karar özeti" ile başlıyor** (bir sayfa: ne, neden,
      hangi seçenek, gerçek veriye etkisi, gereken karar, doğrulama).
      docs/20'ye eklendi; docs/22 bununla başlayacak.
- [x] **Dosya görev ayrımı + arşiv** (docs/06 §10): NEXT_TASKS 1128 → ~600
      satır; kapanan paketler docs/archive/next-tasks-2026-05_07.md.
      "Doğruluk kaynağı" ifadesi iş sırası/durumuyla sınırlandı.
- [x] **CI** (.github/workflows/ci.yml): her push/PR'da analyze + test +
      doküman kontrolü. Yerel kapı (§6) kalktı değil; bu ikinci ağ.
- [x] **tools/check_docs.py**: bozuk göreli bağlantı + bayat durum ifadesi
      (`commit edilmedi`) yakalar. İlk çalıştırmada 11 kırık bağlantı buldu,
      düzeltildi.
- [x] **Senkron v2 aşamaları:** "commit edilebilir ≠ yayınlanabilir" ayrımı ve
      yayın grupları docs/20 §11'e yazıldı; şema değişikliği kontrol listesine
      "eski sürüme dönülürse ne olur" maddesi eklendi (CONVENTIONS §3.8).
- [x] **Riskli değişiklikte bağımsız inceleme** (docs/06 §6b): senkron, göç,
      hesap izolasyonu, yedek/geri yükleme, silme işlerinde dış model
      incelemesi; inceleyene Karar özeti + diff + testlerin kanıtı verilir.
- [ ] **Arşivden gelen 40 açık madde triage'ı** — Samet'le birlikte: hangisi
      hâlâ geçerli, hangisi düşecek (aşağıdaki son bölüm).

## 🛡️ Sağlamlık Paketi (2026-09-17)

- [x] **Set girişinin taslağa güvenilir yazımı** — set alanına yazılan değer
      yazım 0,5 sn durunca taslağa yazılır (`_scheduleDraftSave`); bekleyen
      yazım **arka plana geçişte** ve **ekran kapanışında** hemen tamamlanır.
      Tarih değişimi de artık taslağa yazılıyor.
      **Kalan kayıp penceresi:** yalnız ani kapanmada (çökme, pil bitmesi,
      sistemin arka plan olayı vermeden öldürmesi) son tuştan sonraki en fazla
      ~0,5 sn + diske yazma süresi. Ayrıntı: docs/12 §1.
- [x] **Silinmiş taslak geri gelmez** — kapanışta yazım eklenince çıkan yeni
      risk: hesap değişimi taslağı sildikten sonra ekranın geciken yazımı eski
      hesabın taslağını geri getirebilirdi. `WorkoutDraftService.clearCount`
      ile engellendi.
- [x] **Geri alma ↔ taslak tutarlılığı** — uygula → geri al → arka plan →
      kapanış → taslak **diskten yeniden okunarak** (`reload()`) ve **taslaktan
      devam edilerek** doğrulandı: geri alınmış hal kalıcı, öneriler 10 tekrar
      (11 değil). Tersi (uygulanmış hal devamda korunur) de test edildi.
      Önceki tek seferlik gözlemin kodda karşılığı bulunmadı; o sırada
      simülatörde hot reload hatası (`lastWeightsKg` null) yaşanmıştı —
      muhtemel neden bu, kesin değil.
- [x] **"Kiloyu artır" satırının görsel doğrulaması** — gerçek hesaba
      yazmadan, widget testinde gerçek yazı tipiyle çizilip ekran görüntüsü
      alındı: gerekçe "60 kg × 12, 12, 12 — her sette 12 tekrara ulaştın…",
      düğme "+1.25 kg"; uygulanınca "Uygulandı: her sete +1.25 kg, 8 tekrar",
      boş alan önerileri 61.25 × 8, ÖNCEKİ sütunu 60×12 kalıyor. Kalıcı test:
      metinler + öneri ipuçları.
- [x] `test/features/active_session_draft_test.dart` — 7 widget testi; her
      biri koddan ilgili satır çıkarılınca kırmızıya dönüyor (5 bozma denemesi).
      analyze 0 · test **331/331**.
- [ ] **Android Google girişi** — Samet telefon yanındayken **birlikte**
      doğrulanacak (bekliyor).
- [ ] **Gözlem (düşük öncelik):** "+1.25 kg" gerekçe cümlesinde satır
      sonunda "+1.25 / kg" diye bölünebiliyor (dar ekran). Değer ile birim
      arasına bölünmez boşluk konabilir.

## ✅ Paket "Hızlı antrenman girişi" — #11 Arama v2 + #3 Sonraki hedef (2026-09-17)

Samet "özellik tarafından başla" dedi (Docker/Supabase kurulumu sonraya).
docs/21 §2 #11 ve #3. Commit: `7ca8415` (arama v2), `71def18` (sonraki
hedef) — main'e gönderildi (2026-09-17).

- [x] **#11 Hareket arama v2** — `exercise_search.dart` (saf): kelime başı
      eşleşme, tire/boşluk/çoğul sadeleştirme, alaka sıralaması (ad > Türkçe
      ad > birincil kas > ekipman/kategori > ikincil kas), kas adı aramasında
      birincil kas öncelikli, temel hareket + son 90 gün kullanım öne çıkar.
      Türkçe adlar `assets/data/exercise_terms_tr.json` (152 kural, 24'ü zayıf
      niteleyici, 39 temel hareket). Kütüphanede arama varken düz sıralı liste,
      boşken en üstte "Son kullandıkların" (`getExerciseUsageSince`). Eski
      `searchHaystack/matchesQuery` kaldırıldı. Ölçüm: "şınav" 0 → 25 sonuç
      (Push-Up 1.), "lat" Lat Pulldown 161. → 1.; 34 aramalık altın liste yeşil.
- [x] **#3 Antrenmanda sonraki hedef** — `progression.dart` (çift ilerleme):
      hareket başlığının altında gerekçe satırı ("Geçen sefer: 15 kg × 10, 10, 10
      (aralık 8–12)…"); kilo artışı/+1 tekrar **yalnız düğmeyle** uygulanır
      (Samet kararı), geri alınabilir, taslakta saklanır (`inc`); piramitte
      setler ayrı yazılır. Ayarlar → **Kilo artışı** (varsayılan 1,25 kg;
      imperial 2,5 lb). Metrik kilo artık iki ondalıkla gösteriliyor
      (`Units.lift`) — 61,25 kg eskiden "61,3" görünürdü.
- [x] analyze 0 · test **324/324** · iOS simülatöründe doğrulandı (arama
      "şınav"/"lat", son kullanılanlar, Bench "tekrar dene", Cable "+1 tekrar" →
      öneriler 11 → geri al, açıklama paneli, Ayarlar satırı). Simülatör
      verisi değişmedi.
- [ ] **Samet — Türkçe ad listesini gözden geçir:**
      `assets/data/exercise_terms_tr.json` (salonda kullandığın adlar eksikse
      ekleyelim).
- [x] ~~Gözlem — geri alma taslağa yazılmadı~~ → Sağlamlık paketinde testle
      kapatıldı (yukarıda).
- [x] ~~Bilinen boşluk — set alanı taslağa hemen yazılmıyor~~ → Sağlamlık
      paketinde düzeltildi.
- [x] ~~Doğrulanamadı — kilo artırma satırının görünümü~~ → Sağlamlık
      paketinde test ortamında ekran görüntüsüyle doğrulandı.

## 🌙 Gece Görevi — 2026-09-17 (Samet inceledi ve onayladı; commit `ec4197f` docs, `215653b` Paket 3)

- [x] **docs/20 — Senkron v2 tasarımı yazıldı** →
      [docs/20-sync-v2.md](docs/20-sync-v2.md). Kod yok. §13'teki 7 soru
      karara bağlandı (aşağıda). Uygulama 8 aşamaya (0–7) bölündü (~10 gün +
      yarım gün yerel test ortamı kurulumu).
- [x] **Paket 3 kodlandı** (C-16 seans ilerlemesi "1/6 set" + ince çubuk,
      C-15 sütun başlığı / ÖNCEKİ / ✓ okunurluğu). `session_progress.dart` +
      4 test · analyze 0 · test **267/267** · iOS simülatöründe
      doğrulandı.
- [x] **Özellik önerileri değerlendirildi** →
      [docs/21-feature-roadmap.md](docs/21-feature-roadmap.md). Kod yok.
      Önerilen sıra: #3 sonraki hedef → #1 haftalık değerlendirme (+#6
      çekirdeği) → #4 ilerleme fotoğrafları → #2 "geçmişten öğün kopyala";
      senkron v2 Aşama 5'ten sonra #8 → #5 → #7 → #2 tam; sonra #10, #9.
      §6'da Samet'e 10 soru.
- **Samet'in kararları (2026-09-17, sabah):** Supabase ücretli plan şimdi
      değil · özellik sırası onaylandı · kilo artışı varsayılan **1,25 kg**,
      otomatik değil ([Artır] ile) · profile **hedef yönü** alanı gelecek ·
      haftalık değerlendirme **bildirimi** gelecek · **katalog kimliği şimdi**
      (docs/20 Aşama 6'ya alındı). Samet'in soruları üzerine docs/20
      güncellendi: **silme her zaman kazanır**, sunucuda silinen satır gerçekten
      silinir (`deleted_records` işareti kalır), sunucu testleri **yerel
      Docker** önerisi (Docker + Supabase CLI kurulu değil). Açık kalanlar:
      docs/20 §13 (2, 3, 4, 5, 7) ve docs/21 §6 (6 soru).
- **Samet onayı (2026-09-17, öğlen):** docs/20 §13 ve docs/21 §6'daki tüm
      öneriler onaylandı (silme kazanır, gönderilmemiş kayıtta seçim, işaretler
      süresiz, su olay kaydı, yerel Docker testleri, günlük durum alanları,
      beslenme günü tamamlandı kuralı, asistan mimarisi, önce Android widget,
      takviye kaydı + rozetler isteniyor).
- [x] **Hareket arama v2** (docs/21 §2 #11) — yukarıda, uygulandı. Samet: "hareket aramak çok zor".
      Ölçüm: "lat" 485 sonuç (Lat Pulldown 161. sırada), "kol" 457, "şınav"/
      "barfiks"/"mekik" 0 sonuç, "pullup" Pull-Up'ı bulmuyor. Öneri: alaka
      sıralaması + kelime başı eşleşme + Türkçe ad listesi (~150 hareket) +
      son kullanılanlar; #3 ile aynı paket, sıranın başı. Samet onayladı.
- [x] **Simülatördeki açık seans kapandı:** 2026-09-16 22:23'te başlayan
      "Push day"i Samet 2026-09-17 09:20:45'te bitirdi (657 dk, tek set:
      Barbell Bench Press 100×10). Bu haftanın 5.059 kcal'i bu kayıttan.
- [ ] **Ürün fikri (bu olaydan):** çok uzun açık kalmış seans bitirilirken
      (ör. > 4 saat) bitiş saatini sormak / son set saatini önermek — yoksa
      süre ve kalori şişiyor.

## ✅ Paket 1 — Kullanım geri bildirimi + doğrulanmış arayüz hataları (2026-09-16)

Samet'in üç isteği (G-1/G-2/G-3, aşağıda) + Codex arayüz incelemesinden **kodda
doğrulanan** küçük hatalar. Senkron koduna dokunmaz. Samet 2026-09-16'da
"başla" dedi; açık sorular aşağıdaki kararlarla kapatıldı.

**Kararlar (G-1/G-2/G-3):**
- **G-1 kök neden:** seans ekranı `WakelockPlus` ile açık kalıyor → uygulama
  ön planda → mola bitince yalnız `HapticFeedback`. Arka plan bildirimi de
  varsayılan KAPALI (`restEnabled = false`). Salonda hiç ses çıkmıyordu.
  **Çözüm:** ön planda ses — son 3 saniye kısa tık + bitişte çift bip +
  titreşim. Ortak `FeedbackService` (`core/feedback/`) — ses/titreşim tek
  yerden. Ses **medya sesini** kullanır, müziğin üstüne karışır, kulaklık
  takılıysa kulaklıktan çalar; telefonun sessiz anahtarını dinlemez (salonda
  telefon çoğunlukla sessizde, özellik tam orada lazım). Ayarlar →
  Bildirimler → "Mola sonu sesi" ile kapatılır (varsayılan açık). Ses
  dosyaları bu projede üretildi (lisans yok), toplam ~56 KB
  (`assets/sounds/`). Kilit ekranı durumu için "Dinlenme sayacı bildirimi"
  hâlâ ayrıca açılmalı (izin ister, varsayılan kapalı).
- **G-2:** alanlar otomatik DOLDURULMAZ — `_finish` işaretlenmemiş ama değer
  girilmiş seti de kaydediyor, otomatik doldurma onaylanmamış kayıt üretirdi.
  Bunun yerine: boş alanlarda soluk **öneri** görünür; ✓'e basınca boş
  alanlar öneriyle dolar ve set tamamlanır (tek dokunuş = kullanıcı onayı).
  Öneri kuralı (`set_prefill.dart`): üstteki dolu set geçen seansın aynı
  setiyle AYNIYSA (geçen seansı takip ediyorsun) geçen seansın bu numaralı
  seti önerilir — piramit (100→120→140) bozulmaz; bugün farklı değer
  girildiyse o değer sonraki setlere taşınır; geçmişi olmayan harekette
  üstteki set taşınır. Isınma seti çalışma setine taşınmaz. RPE (algılanan
  zorluk) taşınmaz — öznel. "ÖNCEKİ" sütunu artık set numarasına göre geçen
  seansı gösterir (önceden her satırda son seti gösteriyordu). Öneri alanda
  belirgin soluk (%40) — girilmiş değerle karışmasın.
- **G-3:** `defaultRestSec` kuvvet kategorilerinde 60 sn (esneme 30 sn).
  "Gerçek molayı öğren" fikri ERTELENDİ: `workout_sets.restSeconds` kolonu
  var ama hiç yazılmıyor (dünkü "veri zaten var" notu yanlıştı); rutinlerdeki
  eski 180'ler varsayılandan geldiği için "son kullanılanı hatırla" da eski
  değeri geri getirirdi. Mevcut rutinlerin mola değerleri değiştirilmez
  (kullanıcı verisi) — rutin düzenleyiciden elle değiştirilir.

**Codex bulguları (kodda doğrulandı):**
- **C-1** Beslenme/İlerleme alt panelleri buzlu çubuğun arkasında açılıyor —
  `showModalBottomSheet` sekme navigator'ına ekleniyor → `useRootNavigator`.
- **C-2** Beslenmede liste sonu FAB (yüzen düğme) payı yok.
- **C-5** Öğün seçici: "Breakfast"/"Kahvaltı" satır kırıyor, "Atıştır." kısaltması.
- **C-7** Ana Sayfa "This Week" ızgarası: `GridView` padding'i boş → Flutter
  güvenli alan boşluğunu (çentik + çubuk) ekliyor → büyük boşluklar.
- **C-18** Geçmiş antrenman: tarih seçici kendiliğinden açılsın, düğme "Kaydet".
- **C-19** Antrenman geçmişi: eski yıllarda yıl yok; kapalı kartta set/hacim özeti yok.
- **C-20** Hareket kütüphanesi: ad tek satırda kesiliyor.
- **C-31** İlerleme özeti: fark ilk ölçüme göre ama yazmıyor; artış otomatik
  kırmızı (Ana Sayfa'da nötr). Renk hedef kilo yönüne göre olmalı.
- **C-35** Hesap: "Çıkış yap" ve "Hesabı sil" aynı kırmızı.

- **Ek (doğrulama sırasında bulundu):** İlerleme takvim ızgarasında C-7 ile
  aynı padding hatası (takvimin altına alt çubuk boşluğu) · Beslenme +
  İlerleme FAB'ları aynı varsayılan hero etiketini paylaşıyordu ("multiple
  heroes share the same tag" — Codex turunda da vardı) → `heroTag: null`.
- [x] **Paket 1 bitti** (2026-09-16): analyze 0 · test **263/263** (36 yeni)
  · iOS simülatöründe (iPhone 17) görsel doğrulama: C-1 iki panel, C-2,
  C-5, C-7, C-18, C-19, C-20, C-31, C-35, G-2 (✓ → 100×10 doldu, 2. set
  120×9 önerisi korundu), G-1 ayarı + ses kuyruğunun çaldığı sistem
  günlüğünden görüldü (kulakla dinlenmedi). Seans kaydedilmeden kapatıldı,
  simülatör verisi değişmedi.
- [ ] **Samet — cihazda dene:** mola sesi (kulaklıklı/kulaklıksız, sessiz
  modda), ✓ ile doldurma. Android emülatöründe oturum düştü (sunucu:
  `refresh_token_not_found`) → emülatörde yeniden Google girişi gerekiyor.
- [ ] **Samet — profil çelişkisi:** hedef kilo 80 kg (kilo verme) ama kalori
  hedefi 3100, günlük harcama ~2891 (fazla). Hangisi doğru? (C-34 ile bağlı.)
- [ ] **Silme bildirimi sekme değişince de ekranda kalıyor** ("X silindi —
  Geri al"): eylemli SnackBar kendiliğinden kapanmıyor; başka sekmede
  yanlışlıkla "Geri al"a basılabilir.

## 🔎 Codex Arayüz İncelemesi — kalan bulgular (2026-09-16)

Codex (dış model) uygulamayı iOS simülatöründe İngilizce/açık temada gezdi, 37
öneri verdi. Kodla karşılaştırıldı; Paket 1'e girenler yukarıda.

- **Paket 2 — ana sayfa düzeni (Samet'le karar):** C-6 seri kartındaki sayılar
  son 30 gün ama etiketsiz (haftalıkla tekrar gibi görünüyor) · C-8 günlük
  işler (su/beslenme) haftalık istatistiğin altında · C-9 sıfır kartlar ·
  C-10 kilo kartında ölçüm tarihi yok. Önce C-7 düzeltmesiyle ekrana yeniden bak.
- ✅ **Paket 3 — seans** (2026-09-17, gece görevi): C-16 "1/6 set" ilerleme
  göstergesi + çubuk · C-15 sütun kontrastı.
- **Paket 4 — orta boy:** C-11 Antrenman üst ikonları etiketsiz · C-12 baskın
  aksiyon "boş antrenman" · C-13 rutin önizlemede toplam set/süre ·
  C-21 filtre keşfedilebilirliği · C-22 listede hareket görseli (911 harekette
  var) · C-28 hazır besini "kopyala → kendi besinim" · C-29 İlerleme takvimle
  başlıyor · C-32 ölçüm düzenleme yok · C-34 TDEE (toplam günlük enerji
  harcaması) kartı hedefle ilişki kurmuyor · C-36 son senkron zamanı.
- **Katılınmayan / zaten var:** C-30 gün detayı zaten var (takvimde güne
  dokun) · C-4 besin/birim Türkçe → bilinçli ertelenen Faz B · C-17 TR
  arayüzde "ÖNCEKİ" + RPE açıklaması var (yalnız 1RM açıklanmamış) · C-23
  814 hareketin talimatı zaten açık karar · C-37 lisans satırı bilinçli (B2).
- **Düşük öncelik:** C-14, C-24, C-25, C-26, C-27, C-33.

## 🗣️ Kullanım Geri Bildirimi — Samet, 2026-09-15

Samet uygulamayı **gerçekten kullanırken** çıkan üç istek. Hepsi aktif seans
akışında — yani en sık dokunulan ekranda. Kararlar yukarıda (Paket 1).
Aşağısı 2026-09-15'te kod üzerinde doğrulanan durum + o günkü açık sorular.

### G-1 · Mola bitince SESLİ uyarı

> "Sürekli telefonun ekranına bakamaz kimse. 40 saniye mola bitti mi bitmedi mi
> anlaşılması için bir uyarı sesi olmalı."

**Mevcut durum (doğrulandı):**
- `active_session_screen.dart:486` — mola bitince **yalnız titreşim**
  (`HapticFeedback.mediumImpact()`). Ses yok.
- `core/notifications/notification_service.dart:107` — `scheduleRestDone()`
  **zaten var**: Android `Importance.high`, iOS `InterruptionLevel.timeSensitive`.
- Yani altyapı duruyor ama Samet duymuyor. **Önce bunun nedeni bulunmalı:**
  bildirim ön plandayken bastırılıyor mu, kanal sesi kapalı mı, izin verilmemiş
  mi? Yeni ses eklemeden önce cevaplanmalı — belki hata, belki eksik özellik.

**Açık sorular:**
- Ses mi, sesli bildirim mi, yoksa ikisi de mi? Spor salonunda telefon cepteyken
  titreşim yetmiyor; kulaklık takılıysa ses müziğin üstüne binmeli (ducking).
- Sessiz moddayken ne olmalı? Salonda telefonu sessizde tutan çok.
- Son 3 saniye geri sayım sesi mi, tek bitiş sesi mi? (Setin başına hazırlanmak
  için geri sayım daha iyi olabilir.)
- Ayarlardan kapatılabilmeli (Ayarlar → Bildirimler ekranı zaten var).
- **Samet'in notu: "bu sadece mola için değil, başka alanlarda da olabilir."**
  → Seans bitişi, kişisel rekor (PR) kutlaması, su hatırlatması gibi yerler için
  ortak bir "geri bildirim (ses/titreşim) katmanı" düşünülmeli; her yere ayrı
  `HapticFeedback` serpiştirmek yerine tek servis.
- Paket seçimi: `audioplayers` / `just_audio` / `SystemSound` — hangisi? Ses
  dosyası APK'ya gömülecekse boyut etkisi var.

### G-2 · Önceki setin kilo/tekrar değerini sonrakine taşıma

> "Şu anda her setin bilgisini girerken sıfırdan giriyorum."

**Mevcut durum (doğrulandı):**
- `active_session_screen.dart:452` — hareket eklenirken `getLastSetForExercise`
  çağrılıyor ve `prevLabel(...)` ile **önceki performans GÖSTERİLİYOR**.
- Ama `_SetEntry()` **boş** oluşturuluyor → değer gösteriliyor, doldurulmuyor.
  Samet ekranda gördüğü sayıyı elle yazıyor. Şikayetin tam kaynağı bu.

**Açık sorular:**
- Otomatik doldurma mı, tek dokunuşla kopyalama mı? Otomatik doldurma yanlış
  kayda yol açabilir (kullanıcı onaylamadan "bitti" derse geçen haftanın kilosu
  bu haftanın kaydı olur) — **veri doğruluğu riski, hafife alınmamalı.**
- Kaynak ne olmalı: aynı seanstaki **bir önceki set** mi, geçmiş seanstaki
  **aynı set numarası** mı? İkisi farklı: ilki düşen set (drop set) akışına,
  ikincisi program takibine uyar.
- Dolu gelen değer görsel olarak "taslak" mı görünmeli (soluk), yoksa normal mi?
- Ölçüm tipi farkı: kilo×tekrar dışında süre/mesafe hareketleri de var
  (`measurementType`) — çözüm hepsini kapsamalı.

### G-3 · Varsayılan mola süresi 3 dk → 1 dk

> "Sıfırdan programa başlayıp tek tek egzersiz eklediğimde mola 3 dk geliyor."

**Mevcut durum (doğrulandı):** `workout_ui.dart:116` `defaultRestSec(category)`
kategoriye göre veriyor — `compound` **180 sn**, `isolation`/`calisthenics` 90,
`cardio` 60, `flexibility` 30. Samet 3 dk görüyor çünkü eklediği hareketler
bileşik (compound). Yani sabit 3 dk değil, kategori kuralı.

**İstenen:** başlangıç değeri **60 sn**.

**Açık sorular:**
- Bütün kategoriler mi 60'a inecek, yoksa yalnız `compound` mu? Kategori mantığı
  mantıklı bir fikirdi ama pratikte uzun geliyor.
- **Daha iyi UX fikri aranıyor** (Samet'in isteği): sabit varsayılan yerine
  kullanıcının o harekette *gerçekte* ne kadar dinlendiğini öğrenip önermek?
  Veri zaten var — `workout_sets.restSeconds` kaydediliyor.
- Rutin oluştururken ayarlanabiliyor (`restOptions` listesi 0-300 sn). Seans
  içinde de hızlı değiştirme var mı, yoksa yalnız ±ayar (`_bumpRest`) mı?

---

## 🔴 Senkron v2 (docs/20) — ONAYLANDI, sıra 3 (bkz. "Güncel sıra")

Samet'in kararı (2026-09-17 akşam): sağlamlık paketi → #1 haftalık
değerlendirme → Docker + Supabase CLI kurulumu ve bu iş → #4, #2.

Dış inceleme (2026-09-15) senkron protokolünde 7 P1 açığı buldu, hepsi kodda
doğrulandı. Ayrıntı ve numaralandırma: [CODE_REVIEW.md § Dış İnceleme](CODE_REVIEW.md).

- [x] **docs/20 yazıldı** (2026-09-17) → [docs/20-sync-v2.md](docs/20-sync-v2.md).
      Samet onayladı (§13'teki 7 soru karara bağlandı). Uygulama aşamaları
      (§11): 0 kırmızı testler · 1 yerel sağlamlık (şema v11, `capture`
      bayrağı, `local_seq`) · 2 açılış ve kapı · 3 sunucu sürümü · 4
      sayfalı/artımlı çekme + koşullu gönderim · 5 silme protokolü · 6
      sahiplik + belirlenimci katalog kimliği + su olay kaydı · 7
      durum/operasyon. Toplam ~10 gün.
- [x] Tasarımın kapsaması gerekenler (hepsi docs/20'de karşılandı):
      - **Silme protokolü** (#1): tombstone / `deleted_at` + `SyncRemote.delete`.
        Rutin düzenlemesi sil+yeniden-ekle yerine satır kimliğini koruyan fark
        uygulamalı, yoksa sunucuda rutin şişmeye devam eder.
      - **Satır sürümü** (#3, #4): saniyelik `updated_at` sürüm yerine geçemez;
        her yerel değişiklikte artan revizyon. Sunucu tarafında **koşullu**
        upsert (RPC ya da `where updated_at <`), yoksa eski yazma yeniyi ezer.
      - **Sayfalama** (#5): kararlı sıralamayla tüm sayfalar; PostgREST
        varsayılanı 1.000 satır ve sessizce kesiyor.
      - **Pull penceresi** (#2): ağ beklemesi tetikleyiciler kapalıyken
        olmamalı. Açılışta tetikleyici bütünlüğü onarılmalı (`beforeOpen` şu an
        yalnız `PRAGMA foreign_keys` yapıyor).
      - **Hesap izolasyonu** (#6, #7): `bootstrap()` sahiplik kontrolü yapmalı;
        `gateRedirect` hata durumunu girdi olarak almalı; ortak katalog
        kimlikleri kullanıcıya bağlanmamalı.
      - **Reaktif yayılım** (#9): pull ham SQL yazdığı için Drift `tableUpdates`
        tetiklenmiyor; elle liste 8 provider, kodda 23 `watchTables` var.
      - **Su tekilliği** (#8 kalan yarısı): gün başına tekillik kısıtı — şema
        değişikliği, migration + test aynı commit'te (ADR-007).
- [x] ~~Açılışta oturum açıkken birkaç saniye Karşılama ekranı görünüyor~~ →
      A paketinde düzeltildi (2026-09-18). Eski kayıt:
      **Açılışta oturum açıkken birkaç saniye Karşılama ekranı görünüyordu**
      (2026-09-16, emülatörde gözlendi — Supabase projesi duraklatılmışken).
      Router `initialLocation: welcome`; `bootstrap()` `_appliedUserId`'yi
      `await _readOnboarded()` SONRASI atıyor → arada gelen oturum olayı
      `_applyAccount`'u tetikliyor → `busy=true` iken `gateRedirect` karar
      vermiyor → pull ağda bekledikçe kullanıcı "Hesap oluştur" ekranını
      görüyor. Kural 1'e (açılış ağa bağlı değil) aykırı; sinyalsiz salonda
      daha uzun sürer. Pull penceresi (#2) ile birlikte ele alınmalı.
      Ayrıca ağ hatası yakalanmamış istisna (`Unhandled Exception:
      AuthRetryableFetchException`) olarak günlüğe düşüyor.
- [x] ~~Senkron testleri gerçekten yarışı sınamalı~~ → A paketinde yapıldı. (E-15): `sync_push_test`
      T-5 düzenlemeyi `pushAll` bittikten SONRA yapıyor; T-1 dosyayı kapatıp
      açmıyor. İsimleri vaat ettiklerini ölçmüyorlar.
- [x] ~~Açılış dumanı testi + CI~~ → ikisi de yapıldı (CI 2026-09-17, duman testi 2026-09-18). (E-16): `widget_test.dart` yalnız `1+1==2`;
      repoda takip edilen iş akışı yok.

- [x] **Bağımsız bulgular düzeltildi** (2026-09-15): #11 kilo sorgusu
      (`getLatestWeight`), #10 aktivite takvimi reaktif oldu, #12 "dünü kopyala"
      transaction + çift dokunuş koruması, #8 su kaydı yerel yarısı, #13 admin
      panel yarış durumu. analyze 0 · test 227/227 (12 yeni).

---

## 🔐 Zorunlu Hesap + Senkron (docs/18) — kodlandı, protokol eksik

Tasarım: **[docs/18-auth-and-sync.md](docs/18-auth-and-sync.md)**. Aşama sırası:
A → B → C → E → G → F → D.

- [x] **Aşama A — Şema v9** (2026-07-22): `SyncColumns` mixin 12 tabloda,
      migration + 4 test, gerçek cihazda v8→v9 doğrulandı.
- [x] **Aşama C — Zorunlu giriş kapısı** (2026-07-23): ① Karşılama → ② Giriş/Kayıt
      → ③ Onboarding (4→3 sayfa) → ④ Uygulama. `features/auth/` altında `AuthGate`
      (+saf `gateRedirect`), `AccountSwitchGuard`, karşılama ve tam ekran giriş
      ekranları; router `redirect` + `refreshListenable`; `main.dart` `runApp`
      öncesi `bootstrap()`. **11 yeni test**, emülatörde uçtan uca doğrulandı
      (docs/18 §5.4).
- [x] **Aşama B — Supabase mirror tabloları + RLS** (2026-07-22): `supabase/01_schema.sql`
      + `02_grants.sql`. ⚠️ RLS tek başına yetmiyor, GRANT de şart (42501 dersi).
- [x] **Aşama E — Outbox senkron katmanı** (2026-07-22): **canlıda çalışıyor**,
      telefondan 15 satır gitti. Dört arıza aşıldı, veri kaybı sıfır (docs/18 §6.7).
- [x] **Aşama F — Pull + çakışma** (2026-07-23): `features/sync/sync_pull.dart`.
      Girişte sunucu verisi iner, `onboarded` profil varsa onboarding atlanır.
      Tetikleyiciler pull boyunca kapalı (yankı yok), profil tekil (junk iyileşir),
      katalog isimle benimsenir, LWW çakışma. 6 test + emülatörde gerçek Supabase'e
      karşı uçtan uca doğrulandı (docs/18 §6.8). Samet'in "verim geri gelmedi" hatası
      çözüldü.
- [x] **Aşama G — Senkron durumu UI** (2026-07-23): `features/sync/sync_status.dart`
      + hesap ekranı göstergesi (4 durum, "kaydedildi" güvenceli) + bekleyen kayıtla
      çıkış uyarısı (İptal/Önce senkron et/Yine de çık). docs/18 §9.1.
- [x] **Aşama D — Google yerel akış** (2026-07-23 kod, 2026-07-25 iOS kurulumu):
      `auth_service.dart` iki yollu. Web client ID yazıldı; seçim artık **platform
      bazlı** (`_nativeGoogleReady`), çünkü Google her platform için ayrı OAuth
      istemcisi ister. **iOS: yerel akış kuruldu** (istemci kimliği + Info.plist).
      **Android: tarayıcı akışında** — Android istemcisi (paket adı + SHA-1) henüz
      yok, `googleNativeOnAndroid = false`. Detay: docs/18 §15.3.

## 📱 iOS platformu (docs/18 §15) — 2026-07-25 ayağa kalktı

Android ile eş zamanlı ilerlemesi için kuruldu. Derleme, simülatör, Google girişi,
deep link, senkron, veritabanı ve seed doğrulandı (docs/18 §15.6).

- [x] **iOS yerel Google girişi ÇALIŞIYOR** (2026-07-25): Supabase → Google →
      "Client IDs"e iOS kimliği eklendi + **"Skip nonce checks" açıldı** (google_sign_in
      6.x nonce parametresi almıyor). Doğrulandı: `grant_type: id_token`,
      `login_method: oidc` → 200. Bedeli replay korumasının zayıflaması; kalıcı
      çözüm `google_sign_in` 7.x yükseltmesi (Android'i de etkiler, ayrı iş).
      docs/18 §15.4 + §15.4.1.
- [ ] **Android yerel Google akışı**: Google Cloud'da Android istemcisi (paket adı
      `com.sametorhan.fit_pack` + SHA-1 imza parmak izi) → kimliği aynı Authorized
      Client IDs listesine ekle → `googleNativeOnAndroid = true`. Bugün çalışan
      tarayıcı akışı bozulmadan yapılmalı.
- [x] ~~Info.plist izin metinleri tek dilli~~ → A paketinde çözüldü (tr/en.lproj).
      Eski kayıt: **Info.plist izin metinleri tek dilliydi**: `NSCameraUsageDescription`
      cihaz dilinden bağımsız hep aynı görünüyor. Lokalizasyon `tr.lproj/en.lproj +
      InfoPlist.strings` ister ve Xcode proje dosyasına dokunur → yayın hazırlığına
      bırakıldı.
- [x] ~~Oturum belirteçleri düz metin~~ → A paketinde güvenli kasaya taşındı.
      Eski kayıt: **Oturum belirteçleri `shared_preferences`'ta düz metindi** (iOS ve Android,
      supabase_flutter varsayılanı). Keychain/Keystore'a taşımak yayın öncesi
      güvenlik maddesi.
- **Not — Berna'nın telefonundaki kopyanın süresi 2026-08-01'de doldu**
      (ücretsiz Apple ID imzası 7 gün). Yeniden kullanılacaksa telefonu
      bağlayıp kur: `xcrun devicectl device install
      app --device <UDID> build/ios/Release-iphoneos/Runner.app`. **Debug derlemesi
      ana ekrandan açılmaz**, release şart. Flutter `--release` derlemeyi yapıp
      "expected app not found" der — uygulama `Release-iphoneos/` altındadır,
      `iphoneos/` altında değil.
- [ ] **Kablosuz dağıtım (TestFlight) ERTELENDİ** — Samet 2026-07-25: "şimdilik
      kablolu test yeterli, sonra bakarız". Ücretsiz yolu yok, $99/yıl Apple
      Developer Program şart. İç test (100 kişi, Apple incelemesi yok) ile dış test
      (10.000 kişi, Beta App Review + gizlilik politikası URL'si) ayrımı var.
- [ ] **iOS turu ritmi**: her oturumda çift test değil — epik sonunda ve UI
      ağırlıklı işlerde (glass, animasyon, klavye, güvenli alan) iOS turu. Ucuz
      sigorta olarak CI'da `flutter build ios --no-codesign` (macOS koşucusu
      dakikayı 10× sayar → gecelik/PR'da, her push'ta değil).

- [x] **Şifre kurtarma akışı** (2026-07-25): zorunlu hesap mimarisindeki son
      açık delik kapandı — şifresini unutan kullanıcının antrenman geçmişi artık
      erişilemez hale gelmiyor. `sendPasswordReset` yazılmıştı ama UI'ya
      bağlanmamıştı. Eklenenler: giriş ekranında "Şifreni mi unuttun?" +
      `_ForgotPasswordDialog`, `AuthGate.recovering` bayrağı (kurtarma oturumu
      yönlendirme tablosunun ÜSTÜNDE — yoksa kullanıcı Ana Sayfa'ya düşer ve
      şifresi hiç değişmezdi), `/reset-password` rotası +
      `ResetPasswordScreen` (şifre iki kez sorulur), `updatePassword`.
      **5 yeni test** · test 203/203 · emülatörde gerçek Supabase'e karşı
      `200 + mail.send` doğrulandı (docs/18 §14).

- [x] **Kayıt doğrulama maili deep link'e döner** (2026-07-25): `signUpWithEmail`
      `emailRedirectTo` vermiyordu → doğrulama bağlantısı Site URL'e
      (`http://localhost:3000`) gidiyor, kullanıcı `ERR_CONNECTION_REFUSED`
      görüyordu. Hesap onaylanıyordu ama kullanıcı sonucu göremiyordu. Artık
      kayıt/sıfırlama/Google üçü de `fitpack://login-callback` üzerinden döner.

**Hâlâ açık:**

- [ ] **Supabase ücretsiz planı projeyi DURAKLATIYOR** (2026-09-16'da
      `INACTIVE` bulundu, MCP ile yeniden başlatıldı). Duraklatılmışken
      alt alan adı hiç çözülmüyor (NXDOMAIN). Evdeki ZTE modem var olmayan
      adresleri kendine yönlendirdiği için uygulamada
      `CERTIFICATE_VERIFY_FAILED` olarak görünüyor — yanıltıcı. Uygulama yerelde
      çalışmaya devam ediyor ama senkron sessizce duruyor ve kullanıcı bunu
      fark etmiyor. Gerçek kullanıcı almadan önce: ücretli plan ya da düzenli
      etkinlik; senkron durumu göstergesi bu hatayı "bağlantı yok" diye
      göstermeli.

- [x] **Supabase Site URL düzeltildi** (Samet, 2026-08-02 bildirdi). Artık
      varsayılan `http://localhost:3000` değil.
- [ ] **Samet — Redirect URLs listesi doğrulanmalı.** Authentication → URL
      Configuration → **Redirect URLs** içinde `fitpack://login-callback`
      bulunmalı. Site URL'den daha kritik: Supabase koddan gelen
      `emailRedirectTo`'yu bu allow-list'e karşı doğruluyor, eşleşme yoksa
      **sessizce Site URL'e düşüyor** — yani deep link listede değilse
      `emailRedirectTo` düzeltmesi hiç devreye girmez (docs/18 §14).
- [ ] **Custom SMTP artık kozmetik değil.** Dahili mail servisinin saatlik
      kotası `/signup` + `/recover` toplamı üzerinden sayılıyor; mevcut
      kurulumda aynı saat içinde birkaç kişi kayıt olamıyor
      (`429 over_email_send_rate_limit`, 2026-07-25'te yaşandı). Gerçek
      kullanıcı almadan önce çözülmeli.
- **E-posta doğrulama AÇIK KALIYOR** (karar 2026-07-25): kapatmanın tek kazancı
  sürtünme, kaybı ise geri dönüşü olmayan veri kaybı (hesap = tek kurtarma yolu;
  yanlış mail = veri kayıp). Sürtünmeyi bunun yerine **Google girişini birincil
  buton yaparak** çözeceğiz → çoğunluk tek dokunuşla, zaten doğrulanmış girer;
  e-posta/şifre yolu doğrulamalı kalır. **Yapılacak (küçük UI):** `auth_screen`de
  Google butonunu görsel olarak öne çıkar (tarayıcı fallback'le bugün de çalışır,
  native için Samet'in Client ID işi bekliyor).
- **Markalı Türkçe doğrulama maili — ERTELENDİ** (2026-07-25): şablon hazır
  (`supabase/emails/confirm_signup_tr.html`). **Engel:** Supabase artık custom SMTP
  KURULMADAN template konusu/gövdesini düzenletmiyor ("Set up custom SMTP to edit
  templates"). Custom SMTP anlamlı olması için kendi domain gerekir; Samet'te domain
  YOK. Karar: pilotta İngilizce varsayılan mailde kal, markalı maili domain + Resend
  (ücretsiz 3000/ay) ile **yayın hazırlığında** kur. Şablon SMTP açılınca aynen
  yapıştırılır. *(Yan fayda: SMTP kurulunca spam düşme + rate limit de çözülür.)*

- [x] **`updated_at` NULL eski satır onarımı** (2026-07-25): gönderim ön geçişine
      `_repairMissingTimestamps()` eklendi (`sync_push.dart`) + `backfillUpdatedAtSql`
      (`sync_columns.dart`). v9-öncesi zaman damgasız satırlar artık push öncesi
      şimdiye ayarlanıyor → sunucunun NOT NULL kolonundaki `23502` reddi bitti.
      Yalnız NULL olanlara dokunur (idempotent). **1 yeni test** (v9 durumunu
      tetikleyici kaldırıp taklit ediyor) · test 198/198 · analyze 0.

- [x] **H-05 — Reaktif veri katmanı** (2026-07-23): 20 okuma provider'ı `FutureProvider`
      → `StreamProvider` (`data/reactive.dart` `watchTables`); tablo değişince ekran
      kendiliğinden tazelenir. Elle invalidate **74 → 38** (kalanlar meşru: onRetry,
      gün-dönümü, pull, activeDraft, pull-to-refresh). Momentum hero (`last30WorkoutStats`)
      artık seans bitince otomatik güncelleniyor — H-05 bug'ı çözüldü. Emülatörde su
      widget'ıyla (invalidate'i kaldırılmış) canlı doğrulandı. test 197/197 · analyze 0.

**Samet'in manuel işleri:** Google Cloud → **Branding** doldur (izin ekranında ham
`...supabase.co` görünüyor, B-1) · mirror tablo SQL'i · `delete_user()` fonksiyonu.


> **Son güncelleme:** 2026-07-12
> **Bağlı doküman:** [PROJECT_STATE.md](PROJECT_STATE.md), [CODE_REVIEW.md](CODE_REVIEW.md), [docs/04-roadmap.md](docs/04-roadmap.md), [docs/17-improvement-analysis.md](docs/17-improvement-analysis.md)

---

## 🗃️ Arşivden gelen açık maddeler (geçerliliği teyit edilecek)

2026-07-12 ve öncesi paketler [docs/archive/next-tasks-2026-05_07.md](docs/archive/next-tasks-2026-05_07.md) dosyasına taşındı. Oradaki açık
maddeler kaybolmasın diye aynen buraya alındı; bir kısmı bugün geçersiz
olabilir — Samet'le gözden geçirilecek.

### ✅ Haftalık Seri + Kişisel Rekor (PR) Kutlaması (2026-07-11)
- [x] ~~Yan bulgu (H-05)~~ → reaktif katman geldiğinde çözülmüş; 2026-09-18'de
      doğrulandı (ilgili ekranlarda `FutureProvider` kalmamış). Eski kayıt: seans bitişi `_finish` yalnız 3 provider
      invalidate ediyor — `last30WorkoutStatsProvider` / `weekDashboardProvider`
      tazelenmiyor (Ana Sayfa momentum istatistikleri seans sonrası eski
      kalıyor; uygulama yeniden açılınca düzeliyor). Tek tek invalidate
      eklemek yerine **reaktif veri katmanı** (docs/17 adım 2, drift
      `watch()`) bunu kökten çözecek — o işte ele al.

### ✅ Uygulama Geneli Liquid Glass Tutarlılığı (2026-07-07)
- [ ] **Gerçek cihaz performansı:** SM A075F'te blur (navbar + GlassCard)
      akıcılığı test edilmeli; takılırsa `GlassCard.blur=false` +
      navbar blur sigma düşürülebilir. APK kurulunca Samet baksın.

### ✅ Profil + Ayarlar IA Yeniden Yapılanması (2026-07-05) — docs/16
- [ ] **Yayın öncesi kalanlar (docs/16):** Gizlilik Politikası + Kullanım
      Şartları URL'leri (metin yok — yazılınca About'a link eklenecek),
      "Uygulamayı Puanla" (mağaza linki yayında belli olur), destek e-postası
      kararı (şimdilik iş e-postası).

### 🔍 Kod İncelemesi & Tutarlılık Refactor'u (2026-07-04) — `fix/code-review`
- [ ] **Samet kararı bekleyen:** H-04 yayın imzası (keystore + targetSdk; telefondaki kurulumu etkiler), M-08 Google girişi (tamamla ya da düğmeyi gizle)

### 🔧 Cihaz Geri Bildirimi Düzeltmeleri (2026-06-30) — `fix/active-session-persistence`
- [x] ~~#1 Duplike hareketler~~ → teşhis yapıldı (2026-09-18): gerçek katalogda çakışma 0; kaynak veriye kalıcı test eklendi.

### ✅ Geçmişe Dönük Veri Girişi TAMAM (2026-06-29) — `feat/historical-entry`
- [x] ~~C-5 Yemekler grup filtresi~~ → A paketinde yapıldı (kolon boştu: 111 yemek gruplandı + filtre).
- [x] ~~C-6 atıf ekranı~~ → zaten yapılmış (`attribution_screen.dart`, Ayarlar → Açık veri kaynakları). Eski kayıt: **C-6** (OFF=ODbL, free-exercise-db=public domain, muscle_selector=MIT)
- [ ] **Açık karar:** barkod kamera tarayıcısını çıkar → ~5MB küçülür (OFF metin araması yedeklediği için). Samet'e soruldu, beklemede.

### 🎨 Sprint D — Tasarım Reskin (DEVAM EDİYOR)
- [ ] **D-04** Antrenman V2 — Hevy/Strong genişleme. **PRD:** [docs/09-workout-v2.md](docs/09-workout-v2.md). Karar: tam geçiş (sadece rutinler), genel kitle, İngilizce hareketler.
- [ ] **D-05** Beslenme ekranı reskin
- [ ] **D-06** İlerleme ekranı reskin
- [ ] **D-07** Ayarlar + Onboarding reskin (Onboarding fonksiyon olarak var, görsel reskin gerek)

### ✅ Sprint P — Premium Cila TAMAM (2026-06-11)
- [ ] **P-10** Onboarding akışı (ilk açılışta hedef kişiselleştirme — V2 release öncesi ŞART; profil tablosuna `onboarded` kolonu = şema v3)
- [ ] **P-11** Dinlenme zamanlayıcısı bildirimi (ekran kapalıyken lokal bildirim — `flutter_local_notifications` + izinler)
- [ ] **P-12** Faz/Hafta otomatik ilerleme (yanlış otomasyon > manuel; tasarım gerekiyor)
- [ ] **P-13** Hareket detay sayfası (hedef kas + form ipuçları — içerik üretimi gerekiyor)
- [ ] **P-14** Achievements kararı: V2'de UI yap YA DA tabloyu kaldır (şema v3 ile birleştirilebilir)
- [ ] **P-15** Uygulama ikonu + splash hâlâ varsayılan Flutter logosu — release öncesi marka ikonu (flutter_launcher_icons)
- [ ] **P-16** Isınma seti işaretleme UI (alan `isWarmup` DB'de var, arayüzü yok)

### 🎯 BUGÜN / YARIN
- [ ] `docs/01-product-spec.md` (PRD v1.1) — final onay
- [ ] `docs/02-architecture.md` (Mimari v1.0) — onay
- [ ] `docs/03-ux-flows.md` (UX v1.0) — onay
- [ ] `docs/04-roadmap.md` (Roadmap v1.0) — onay
- [ ] `docs/05-testing.md` (Test v1.0) — onay
- [ ] `docs/06-workflow.md` (Workflow v1.0) — onay

### 🚀 SONRAKİ MILESTONE: Aşama 0 — Sağlamlaştırma
- [ ] T-002: Mevcut DB'yi yedek alma helper'ı (export to JSON)
- [ ] T-003: `drift_sqlcipher` paketini ekle, LazyDatabase connection güncelle
- [ ] T-004: SecureKeyManager — Android Keystore'dan key oku/üret
- [ ] T-005: `flutter_secure_storage` paketini ekle (Gemini API key için)
- [ ] T-006: V1 DB → şifreli DB migration script'i
- [ ] T-007: Emülatörde V1 → V2 göç testi
- [ ] T-008: Drift migration integration test örneği
- [ ] T-010: `core/errors/app_exception.dart` sealed class hiyerarşisi
- [ ] T-011: Global error handler
- [ ] T-012: `shared/widgets/error_card.dart` + `empty_state.dart`
- [ ] T-013: Snackbar tabanlı UI hata gösterimi
- [ ] T-014: Input validation (kg/rep/RIR/stres)
- [ ] T-015: Workout history screen — TODO bitir
- [ ] T-016: ✅ README gerçek doc (bu session yapıldı)
- [ ] T-017: Emülatörde V1 akışları regression test
