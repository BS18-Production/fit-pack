# 51 — Geri çağırma bildirimleri

> **Durum:** Öneri — Samet'in kararı bekleniyor. Kod yok.
> **İlgili:** docs/49 (yeni kullanıcı deneyimi, ilk hafta rehberi), docs/26
> (öğün hatırlatıcısı), docs/25 (mola zamanlayıcısı), docs/22 §5 (haftalık
> değerlendirme bildirimi), docs/16 §5 (bildirim ayarları), docs/41 (gizlilik).

## Karar özeti

**Sorun.** Uygulamayı açmayan kullanıcıya hiçbir şey hatırlatılmıyor. docs/49
ilk antrenmanı hazır hale getirdi, ama kullanıcı ertesi gün uygulamayı
açmazsa "Sıradaki antrenman" kartını hiç görmüyor. Kazanılan ilk haftayı
korumak gerekiyor.

**Bugünkü durum.** Altyapı hazır, eksik olan *koşullu* antrenman hatırlatıcısı.

| Bildirim | Nasıl | Varsayılan |
|---|---|---|
| Mola bitti | Tek seferlik, dakik (Android'de yerel servis) | İlk molada izin sorulur |
| Antrenman hatırlatıcısı | **Her gün aynı saatte**, koşulsuz | Kapalı |
| Su | Her gün aynı saatte | Kapalı |
| Haftalık değerlendirme | Haftada bir, 20:00 | Kapalı |
| Öğün hatırlatıcısı | **Koşullu**: bugün + 2 gün tek seferlik kurulur, kayıt girilince iptal, tablo değişince yeniden kurulur (docs/26) | Kapalı, beslenme ekranında öneri kartı |

Antrenman hatırlatıcısı bugün antrenman yapılmış olsa da ya da dinlenme günü
olsa da çalıyor. Bu yüzden ya kapatılıyor ya da görmezden geliniyor. Öğün
hatırlatıcısı ise doğru deseni zaten kurmuş: veri varsa bildirim yok.

**Önerilen seçenek: yerel, koşullu antrenman hatırlatıcısı (öğün deseniyle).**

- **Yerel bildirim, sunucu yok.** Telefon kendi takvimine kuruyor; sunucu,
  anahtar ya da maliyet yok. Hiçbir bilgi telefondan çıkmıyor.
- **Tek tür, iki durum:**
  1. **Planlı gün kaçtı:** rutinler güne bağlıysa (`todayRoutineProvider`),
     planlı günün akşamı antrenman yoksa: "Bugün Bacak günüydü — yarın da
     olur." Kayıt girilince iptal olur.
  2. **Ara uzadı:** güne bağlı rutin yoksa son antrenmandan **2 gün** sonra,
     kullanıcının olağan antrenman saatinde: "Sıradaki: Tüm vücut B · ~45 dk".
     Saat son 10 seansın başlangıç saatinden çıkarılır; veri yoksa 18:00.
- **İlk hafta (docs/49 ile bağ):** hesabın ilk 14 gününde rehberin ilk adımı
  (ilk antrenman) bitmemişse **tek** hatırlatma, 2. gün akşamı.
  Diğer adımlar (öğün, kilo) zaten var olan hatırlatıcılara bırakılır.
- **İzin zamanı:** iOS izni bir kez sorar; "hayır" denirse uygulama tekrar
  soramaz. İzin kurulumda ya da ilk açılışta **istenmez**. İlk antrenman
  bittikten sonra özet ekranında tek satırlık öneri gösterilir: "Sıradaki
  antrenmanını hatırlatayım mı?" İzin yalnız "Evet" denince istenir. Mola
  bildirimi izni daha önce alındıysa soru sorulmaz, ayar açılır, kullanıcıya
  bilgi verilir.
- **Sınırlar:**
  - Bu türden **günde en fazla 1**, **haftada en fazla 3** bildirim.
  - **Sessiz saatler** 22:00–08:00: bu aralığa düşen bildirim 08:30'a kayar.
  - Art arda **3 bildirime tepki yoksa** (uygulama açılmadıysa) tür kendini
    **14 gün** susturur.
- **Ton:** suçlamayan ve seçenek bırakan bir dil. "Seriyi bozdun", "tembellik
  yapma" gibi ifadeler yok. Metin bir sonraki adımı söyler. 2–3 başlık
  dönüşümlü kullanılır, öğün hatırlatıcısındaki gibi.
- **Kapatma:** Ayarlar → Bildirimler'de tür başına anahtar. Mevcut "Antrenman
  hatırlatıcısı" (her gün sabit saat) bu yeni türe **dönüşür**. Mevcut kapalı
  ayar kapalı kalır, açık ayar yeni davranışla açık kalır.

**Elenen seçenekler.**

- *Sunucu bildirimi (FCM — Firebase Cloud Messaging / APNs — Apple Push
  Notification service):*
  - Firebase eklemek ve Apple anahtarı almak gerekir.
  - Gönderim için bir sunucu işi gerekir.
  - Kullanıcının "son antrenman" bilgisi sunucuda hesaplanır.

  Bu bilgi zaten senkronla sunucuda, ama gönderim ayrı bir işleme amacı
  sayılır ve gizlilik politikasına yazılması gerekir (docs/41). Faydası
  yalnız, uygulama haftalarca açılmadığında da çalışması. Yerel bildirim
  bunu, kurulan son takvime kadar yapar. Sunucu bildirimi ilk adım için
  fazla.
- *Her gün sabit saat (bugünkü):* koşulsuz olduğu için gürültü üretiyor;
  kullanıcı onu kapatmayı öğreniyor.
- *Seri / rozet baskısı:* ürünün tonuna uymuyor. Yeni başlayanı suçlu
  hissettirip uygulamayı sildirme riski var.

**Veriye ve sunucuya etkisi.**

- Şema, göç ve sunucu değişikliği yok.
- Yeni ayarlar mevcut `NotificationPrefs` içinde, `shared_preferences`'ta
  tutulur:
  - tür anahtarı,
  - susturma bitiş tarihi,
  - tepkisiz bildirim sayacı.
- Bunlar senkronlanmaz. Aynı hesabın iki telefonu ikisi de hatırlatabilir.
  Kabul edilebilir: ikisi de yerel veriye baktığı için antrenman bir
  telefonda girilince senkron sonrası öbüründe de iptal olur.

**Samet'ten gereken kararlar.**

1. Bu yön uygun mu (yerel, koşullu, tek tür)?
2. Ara eşiği: **2 gün** mü (önerim), 3 gün mü?
3. Mevcut "her gün sabit saat" antrenman hatırlatıcısı yeni türe dönüşsün mü
   (önerim), yoksa ikisi ayrı mı dursun?
4. İzin sorusu ilk antrenman bitince mi sorulsun (önerim), yoksa kurulumun
   sonunda mı?

**Nasıl doğrulanacak.**

- Birim testleri (saf zamanlama fonksiyonu, sahte saatle):
  - planlı gün kaçınca kurulur, antrenman girilince iptal olur;
  - ara 2 günü geçince kurulur;
  - sessiz saate düşen bildirim 08:30'a kayar;
  - günlük ve haftalık sınırlar aşılmaz;
  - 3 tepkisiz bildirimden sonra 14 gün susar;
  - yaz saati geçişinde doğru takvim gününe kurulur;
  - hesap değişince eski hesabın bildirimleri silinir.
- Cihazda: Samsung'da cihaz saatini ileri alarak bildirimin gelmesi ve
  antrenman girilince gelmemesi. iPhone'da izin akışı (bir kez sorulur).

---

## 1. Zamanlama nasıl kurulur

Öğün hatırlatıcısıyla aynı desen (docs/26 §1):

- **Zamanlama:** Bildirim tek seferliktir, önümüzdeki 3 gün için kurulur.
  Tekrar eden bildirim kullanılmaz, çünkü "antrenman varsa gönderme" koşulu
  tekrar eden bildirimde kurulamaz.
- **Yeniden kurma tetikleyicileri:**
  - `workout_sessions` ve `routines` tablosu değişince (`watchTables`),
  - uygulama öne gelince,
  - gün dönünce (`currentDayProvider`),
  - ayar değişince.

  Her seferinde hepsi silinip baştan kurulur. Kararı saf bir fonksiyon verir:
  `planRecall(sessions, routines, prefs, now) → List<(DateTime, metin)>`.
  Bu fonksiyon test edilebilir.
- **Kimlikler:** `idRecallBase + gün` (0–2). Öğün aralığıyla (20–) çakışmayan
  yeni bir taban, örneğin 40.
- **Saat dilimi ve yaz saati:** Hedef an, takvim günü + saat olarak `tz`
  yerel saatiyle kurulur (`zonedSchedule`). 24 saat eklenmez; `addDays`
  (CR-011) kullanılır. Saat dilimi değişirse bildirim uygulama öne gelince
  yeniden kurulur.
- **Android:** Dakiklik gerekmez, `inexactAllowWhileIdle` kullanılır.
  Bildirim birkaç dakika geç gelebilir. Böylece Android 12+ "dakik alarm"
  özel iznine gerek kalmaz; Play mağazası da bu izni yalnız takvim ve alarm
  uygulamalarına veriyor. Android 13+ bildirim izni zaten isteniyor.
- **Hesap değişimi:** Yerel veri silinince tablolar değişir ve
  yeniden kurma, yeni hesabın verisine göre (genelde boş) çalışır. Ek önlem
  olarak hesap temizliği geri çağırma kimliklerini açıkça iptal eder. Bugün
  hesap değişiminde hiçbir bildirim açıkça iptal edilmiyor; öğün ve antrenman
  hatırlatıcıları yalnız yeniden kurmaya güveniyor. Bu da aynı işte
  düzeltilir.

## 2. Etkisini analitik olmadan ölçmek

Uygulamada analitik yok, olmaması da gizlilik açısından bir artı (docs/41).
Ölçüm tamamen cihazda yapılır ve hiçbir yere gönderilmez:

- **Bildirime dokunuldu mu:** bildirimdeki `payload` ile açılış sayılır.
  Bu, tepkisiz bildirim sayacını sıfırlar.
- **Bildirimden sonraki 24 saatte antrenman girildi mi:** yerel sayaç.
- **Okuma:** Ayarlar → Bildirimler'in altında yalnız geliştirici modunda
  görünen bir satır, ya da Samet'in telefonunda veritabanı ve tercih
  incelemesi (reference-ios-simulator yöntemi).

Bir ayın sonunda Samet'in ve Berna'nın telefonlarındaki sayaçlara bakılır.
Karar gerçek kullanıma göre verilir (eşik, ton, sınır).

## 3. En küçük değerli ilk adım

1. `planRecall` saf fonksiyonu ve testleri: yalnız **"ara uzadı"** durumu.
2. Mevcut antrenman hatırlatıcısının bu fonksiyona bağlanması (karar 3).
3. İlk antrenmandan sonra tek satırlık izin önerisi (karar 4).

"Planlı gün kaçtı", ilk hafta hatırlatması ve 14 günlük susturma ikinci
turda eklenir. İlk adım bir akşamlık iş. Şema yok, yeni paket yok.

## 4. Kapsam dışı

- Sunucu bildirimi (FCM/APNs): yerel bildirimin yetmediği görülürse ayrı iş.
- Kilit ekranı canlı etkinliği (docs/32): ayrı konu.
- Asistanın haftalık özeti: docs/50.
