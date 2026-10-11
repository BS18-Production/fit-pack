# 45 — Geri bildirim turu (2026-10-11): kilit ekranı, mola sesi, takvim, beslenme

> **Durum:** Kodlandı (dal `feat/feedback-oct11`) · Android emülatörde uçtan
> uca doğrulandı · iPhone 17'ye kuruldu, **kilit ekranı ve ses kontrolü
> Samet'te** · **Kaynak:** Samet'in 11 Ekim listesi (8 madde).
> **İlgili:** docs/25 (Android dinlenme servisi), docs/32 (Canlı Etkinlik
> faz 1), docs/37 (beslenme günü tamamlandı).

## Karar özeti

**Ne değişti, neden.**
1. **Çift kilit ekranı kartı — kök neden bulundu.** Seans açılışında aynı
   karede iki kez `_syncLive` çağrılıyor (`_load` → `_syncLive` +
   `_saveDraft` → `_syncLive`). Dart köprüsü "etkin" bayrağını kanal cevabı
   gelince kurduğu için ikinci çağrı da `start` gönderiyordu; Swift tarafı
   her çağrıda ayrı `Task` açtığından ikisi de "etkinlik yok" görüp **iki
   Canlı Etkinlik** istiyordu. Testle kanıtlandı (`['start','start']`).
   Çözüm iki katlı: Dart çağrıları kuyrukta sıralı + niyet eşzamanlı
   kaydedilir; Swift işlemleri seri ve **tekil** (aynı seansın kartı varsa
   günceller, yoksa diğerlerini kapatıp tek kart açar — uygulama öldürülüp
   seans taslaktan sürdürülünce de eski kart sahiplenilir).
2. **Etkileşimli kilit ekranı.** iOS 17+: "Seti tamamla", dinlenmede
   "+15 sn" / "Atla" (`LiveActivityIntent`, kilit açılmaz; uygulama arka
   planda uyanır, eylem açık seans ekranına iletilir — durumun tek sahibi
   orası). Dinlenme bitişi kartın "bayatlama" anı: uygulama uyurken de kart
   kendiliğinden **"Dinlenme bitti"** durumuna geçer. Toplam süre üst satırda
   "Süre" etiketiyle, dinlenme ayrı ve büyük; tahmini bitiş uydurulmaz.
   Android: seans boyu **tek** bildirim (dinlenme servisinin ön plan
   bildirimiyle aynı kimlik), aynı düğmeler bildirim eylemi olarak.
3. **Mola sesi arka planda (iOS) — kök neden.** Telefondaki tercihler
   okundu: mola bildirimi açık. Arka planda ses yalnız **sistem bildirimiyle**
   gelebilir (iOS uygulamayı askıya alır, uygulama içi geri sayım çalamaz);
   sistem bildirim sesi **sessiz anahtara ve Odaklanma'ya uyar** — salonda
   telefon sessizdeyken bildirim sessiz gelir. Bu iOS kuralı; uygulamada
   düzeltilebilecek iki gerçek kusur vardı ve düzeltildi: (a) bildirim yalnız
   `paused` anında kuruluyordu — kilit ekranından başlayan dinlenmenin
   bildirimi hiç kurulmazdı; artık dinlenme başlarken/değişirken de kurulur;
   (b) bildirim varsayılan sistem sesiyle çalıyordu; artık seçili mola sesi.
   Ayarlar'da iPhone bildirim sesi kapalıysa uyarı, sessiz mod notu.
4. **Mola sesi seçimi:** Dijital bip (varsayılan, eski ses), Klasik zil,
   Boks zili (ding-ding-ding), Yumuşak çan, Güçlü alarm. Sentetik
   (`tools/make_rest_sounds.py`, telifsiz). Geri sayım AAC (`.m4a`), iOS
   bildirim bitişi IMA4 (`.caf`). Toplam ~158 KB (eski tek ses 2 kopya
   ×313 KB). Android servisi Flutter varlığından çalar (kopya dosya yok);
   ses servisten geldiği için Android'de ses başına bildirim kanalı gerekmez.
5. **Antrenman takvimi — kök neden:** Antrenman sekmesindeki takvim ikonu
   aslında "Geçmiş antrenman ekle" düğmesiydi: seçilen gün için **boş kayıt
   formu** açıyor, kayıtları hiç okumuyordu. Veri/saat dilimi hatası yok
   (kayıtlar yerel saatle yazılıyor, testle doğrulandı). Yeni ekran: ay
   ızgarasında antrenman günleri, güne dokununca o günün seansları (detaya
   gider), boş günde "Bu güne antrenman ekle" (gün hazır açılır).
6. **Beslenme:** "Makroları göster / Sade görünüm" kaldırıldı — makrolar
   gram satırında hep görünür (satır yüksekliği değişmez). "Kaydın tamam"
   **kaldırılmadı**, sadeleştirildi (aşağıda gerekçe).
7. **Ana Sayfa Öğün günlüğü:** sabit stok fotoğraf ("Somonlu salata",
   kullanıcı verisiyle ilgisiz) yerine bugünün 4 öğünü: girilen öğün
   kalorisiyle, boş öğün "+ Ekle", saate göre sıradaki boş öğün vurgulu;
   dokununca o öğün için ekleme paneli.

**Elenenler.** Arka planda sessiz ses döngüsüyle uygulamayı uyanık tutmak
(App Store kuralı 2.5.4 ihlali, pil); Critical Alert (Apple özel izni
ister); Time Sensitive bildirim (**ücretsiz Apple hesabı desteklemiyor** —
Xcode imzası reddetti, 2026-10-11). Öğün kartında illüstrasyon (A) ve büyük
dinamik görsel (B tek başına) — ikisi de dekoratif kalıyordu; seçilen:
ikonografik + veriye bağlı (B+C).

**Gerçek veriye etkisi.** Şema/senkron/sunucu değişmedi. Taslağa
(`shared_preferences`) iki isteğe bağlı alan: dinlenme başlangıç/bitişi —
eski taslak alanları yoksa null. Yeni tercih: `notif_rest_sound_id`
(yoksa eski ses). Geri dönüş: eski sürüm yeni alanları yok sayar.

**Samet'ten gereken.** iPhone'da §Doğrulama listesi; sesleri Ayarlar →
Bildirimler → Mola sesi'nden dinleyip beğenmediğini söylemek.

## 1. "Kaydın tamam" incelemesi

1. **Amaç:** "hiç yenmedi" ile "girilmedi"yi ayırmak. İşaretli gün "bilinen
   gün" (docs/37).
2. **Ne zaman görünür:** Beslenme ekranında her gün, günlüğün altında.
3. **Neye bağlı:** `nutrition_days` tablosu (senkronlu), kullanıcı dokunuşu.
4. **Fayda:** haftalık değerlendirme ("N tamamlanmış gün", protein hedefi
   K/N gün), asistanın protein sorusu ("Tamamlanan gün yok; protein hedefi
   başarısı hesaplanmaz"), takvimde ✓.
5. **Tekrar mı:** hayır — başka yerde aynı bilgi yok.
6. **Kaldırılırsa:** asistanın protein cevabı ve haftalık değerlendirmenin
   gün sayımı çalışmaz hale gelir.

**Karar:** kaldırılmadı; sunumu kendini anlatır hale getirildi — tek onay
satırı "Bugünün tüm öğünlerini girdim" + altında etkisi; işaretlenince
"Tüm öğünler girildi · Bu gün haftalık değerlendirmede tam sayılıyor" +
"Geri al". İki durumda aynı yükseklik.

## 2. Teknik

- Dart köprüsü: `core/live_activity/workout_live_activity.dart` (kuyruk,
  etiketler, eylem dinleyici, `endAll`).
- iOS: `WorkoutLiveActivityController.swift` (seri + tekil),
  `WorkoutActivityAttributes.swift` (yeni alanlar), 
  `WorkoutLiveActivityIntents.swift` (iki hedefte; AppIntents zayıf bağlı —
  Runner iOS 15'i destekliyor), `AppDelegate.swift` (eylem → Dart, 8 sn zaman
  aşımı, kart güncellemesi bitene kadar bekler), widget görünümü.
- Android: `WorkoutNotification.kt` (kanal `workout_session`, önem
  VARSAYILAN + sessiz — DÜŞÜK önemli bildirim kilit ekranında varsayılan
  olarak gizleniyordu), `LiveActionReceiver`, `RestTimerService.kt` (ortak
  kimlik, bitişte kartı bırakır, seçili sesi varlıktan çalar).
- Seans ekranı: `_onLiveAction`, `_syncRestNotification`, taslakta dinlenme.
- Sahipsiz kart: taslak banner'dan ya da hesap değişiminde silinince
  `WorkoutLiveActivity.endAll()`.
- Bilinen sınır: uygulama süreci iOS tarafından tamamen kapatılmışsa kilit
  ekranı düğmesi bir şey yapmaz (seans ekranı yok); kart dokununca uygulama
  açılır, seans taslaktan sürer. Android'de bu durumda bayat kart kaldırılır.

## 3. Doğrulama

**Otomatik:** `live_activity_test` (art arda gösterim tek başlatma — kök neden
testi; Android köprüsü; hata sonrası yeniden başlatma; eylem yönlendirme),
`workout_calendar_test` (gerçek DB: iki seanslı gün, boş gün, tarih değişimi,
gece yarısına 10 dk kala seans), `feedback_oct11_test` (ses kimliği/dosyalar,
tercih kalıcılığı, taslakta dinlenme, sıradaki öğün), güncellenen beslenme
testleri. Tümü: **987 test, analiz temiz.**

**Android emülatör (Android 14, Dev hesabı, 2026-10-11):** rutin başlat →
tek bildirim · uygulama alttayken "Seti tamamla" → dinlenme 1:30, düğmeler
+15 sn/Atla · +15 sn bitişi tam 15 000 ms ileri · Atla → set durumu · kurulum
sonrası taslaktan devam (Set 2/3) · **kilit ekranında** kart görünür, kilit
açılmadan "Seti tamamla" · ekran kapalı/kilitli dinlenme bitişi: seçili ses
çaldı (ses odağı kaydı), kart "Dinlenme bitti · …" · seans atılınca kart kalkar.

**iPhone (Samet):**
1. Rutin başlat → kilitle: kilit ekranında **tek** kart.
2. Karttan "Seti tamamla" → dinlenme geri sayımı + çubuk; "+15 sn", "Atla".
3. Dinlenme bitince kart "Dinlenme bitti"ye geçiyor mu; telefon sessizde
   DEĞİLKEN bildirim seçili sesle çalıyor mu (sessizdeyken sessiz gelmesi
   iOS kuralı).
4. Uygulamayı alta al, aç: kart çoğalmıyor.
5. Ayarlar → Bildirimler → Mola sesi: 5 sesi dinle, birini seç.
6. Antrenman → takvim ikonu → antrenman yaptığın bir gün.
