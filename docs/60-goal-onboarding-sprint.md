# 60 — Kesin antrenman kurulumu ve yerel hedef yolculuğu

## Karar özeti

Samet’in 29 Ekim 2026 geliştirme talebiyle, ilk program seçimi ve sonraki
hedef yolculuğu aynı gerçek tercihlere bağlandı. Deneyim yalnız katalog
isteyene sorulur ve saklanır; haftalık gün seçimi kesin 2–6’dır. Katalog
sıklığı/süresi bütçeye uymuyorsa açık kabul veya başka rota seçimi gerekir.
Kullanıcının programı, setleri veya kalorileri kendiliğinden değiştirilmez.

Yeni Hedef Yolculuğu mevcut Ana Sayfa ve Hafta’dan açılır: amaç, kayıtların
kapsamı belirtilmiş başlangıç, mevcut rutin, sıradaki gerçek eylem ve
haftalık kontrol. Hareket odağında kullanıcı kendi kayıtlarından bir
hareket seçer; iki farklı gündeki gerçek tamamlanmış çalışma setleri
karşılaştırılır. Kilo/kas sonucu veya ilerleme süresi garanti edilmez.

**Veri etkisi:** Uygulama şeması ve sunucu değişmez. Yeni yerel tercihler
hesap anahtarlıdır: `training_setup_v1_`, `goal_journey_v1_`,
`weekly_target_history_v1_`. Başka cihaza taşınmazlar. İş kayıtları mevcut
DAO’larda kalır. Hesap silme, bu anahtarları ve eski `weekly_goal_v1_`
tercihini yalnız silinen hesap için temizler; hata, sunucu silme başarısıyla
karıştırılmaz. Analitik olay/soru cevabı eklenmez; Faz 1 tercih/olay sınırları
korunur. Gerçek veride otomatik bir düzeltme veya geriye dönük doldurma yok.

**Yerel çalışma sınırı:** Özgün Faz 1 ve bildirim çalışma ağaçları
değiştirilmedi. `/tmp/fitpack-goal-onboarding-20261029`,
`codex/goal-onboarding-sprint`; başlangıç `66cc74a` doğrulanmış Faz 1 mobil
kaynaklarının yalıtılmış snapshot’ıdır. Üretim, uzak şema, rollout bayrağı,
admin erişimi, push, main birleşmesi ve yayın yapılmadı.

## Davranış sözleşmesi

- Haftalık taahhüt **ayrı antrenman günü** sayar. Aynı gün iki seans tek
  gündür; haftalık özet gerçek seans sayısını ayrıca söyler.
- Yeni değişiklik varsayılan olarak sonraki tam haftaya uygulanır. Onay
  önizlemesi, önceki haftanın değişmeyeceğini söyler; vazgeçmek yazmaz.
- Eski hedef tarihçesi bilinmiyorsa geçmiş hafta “3” ile doldurulmaz.
  Asistan ve seri görünümü bu belirsizlikten başarı/başarısızlık çıkarmaz.
- Hafta başlangıcı tercihi değişince revizyonların yürürlük tarihleri
  taşınmaz. Dönemin yalnız bir kısmını kapsayan hedef tam haftaya kıyas
  edilmez; yürürlük tarihi görünür.
- Kurulumda yerel tercih hatası profil/tartı yazımına ilerlemez. Profil
  transaction’ı başarısızsa tamamlanmamış kurulumun mevcut hafta tercihi
  düzeltilip yeniden denenebilir; kapalı haftalar yeniden yazılmaz.
- Açık hedef düzenleyici hesap kimliği ve oturum geçişiyle bağlıdır.
  A→B veya A→B→A geçişinden kalan ekran/dialog yeni hedef yazamaz. Aynı
  hesapta okuma hatasından yeniden deneme hesap değişimi sayılmaz.
- Hareket seçimi diske yazılamazsa ekranda onaylanmış gibi görünmez.
- Haftalık “kayıtlar doğru” ve zaman engeli cevabı yalnız görüntülenen
  kapanmış dönem için geçerlidir. Eksik kayıt gerçek yapılmayan set üretmez.
- Amaç/egzersiz seçimi ve gözlem, kişisel tıbbi/diyet önerisi değildir.
  Mevcut hatırlatmalar Ayarlar’dan yönetilir; ara verme bildirimleri otomatik
  durdurmuş gibi sunulmaz.

## Kesin kapsam ve kalan sınırlar

Beslenme kurulumunu erteleme bu dilimde yoktur: mevcut profil modelindeki
2200/180/faz varsayılanları “kullanıcı onayladı” sayılmamalıdır. Bu nedenle
kilo ve sayısal beslenme adımı korunur; kilo verme ön seçimi kaldırılmıştır.
Gerçek hedefsiz kayıt ve senkronlu yolculuk ayrıca tasarlanmalıdır.

Profilin tamamlanması ile katalog rutinlerinin kurulması hâlâ ayrı
işlemlerdir. Kesinti profil sonrasında olursa yeni hedef ekranı saklanmış
katalog seçimiyle eksik rutinleri fark eder ve mevcut program ayrıntısına
“kurulumu tamamla” bağlantısı verir. Otomatik işlem günlüğü/atomik çoklu
kurulum tasarımı bu sprintte eklenmedi. Mevcut rutin kopyası tekrar eklenmez.

Bildirim dalındaki ileri tarih planlaması bu tarihli hedef resolver’ına
ayrıca bağlanmalıdır; `fit_pack-notif` bu görevde değiştirilmedi. Yeni hedef
bildirimi veya sağlık kaynağı okuması eklenmedi. Tam dört haftalık dönem
arşivi, otomatik hedef duraklatma ve akıllı program üretimi kapsam dışıdır.

## Doğrulama ve inceleme

Odaklı regresyonlar: kesin seçim/deneyim, katalog süre farkı, disk hatası,
hesap değişimi, yarım kurulumdan değişmiş cevapla tekrar deneme, hedef
tarihçesi, Pazar/Pazartesi sınırı, sağlayıcıdan kısmi dönem aktarımı,
asistanın bilinmeyen hedefi, hedef ekranı retry/başarısız seçim ve tek seçim
erişilebilirlik semantiği.

Tam komut/sonuçlar çalışma ağacındaki `sprint-validation/` dosyalarında
teslim edilir. İlk tam koşu hataları sonraki düzeltmelerin kanıtı olarak
saklanır; son geçiş ayrı kaydedilir. Native build/gerçek cihaz testi bu
çalışma ağacında yapılmadı; widget testleri cihaz doğrulaması diye sunulmaz.

Önceki onboarding araştırmasında tamamlanan araçsız Claude Code eleştirisi
kullanıldı. Bu sprintte ek araçsız, abonelik oturumlu ve 150 saniyeyle sınırlı
tek çağrı maksimum eforda zaman aşımına uğradı; tamamlanmış kaynak incelemesi
iddiası yoktur. Kaynak değişiklikleri ayrıca bağımsız salt okuma
incelemelerinin hesap/hafta/yeniden deneme bulgularıyla düzeltildi.
