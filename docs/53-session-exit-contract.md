# 53 — Seanstan çıkış sözleşmesi (K8)

18 Ekim 2026 · Samet onayı: K8 "önce kaydet ve çık" (deneyim araştırması 12 v2 §6).

## Karar özeti

- Canlı seanstan çıkış penceresinde üç yol olur:
  - **Devam et** (ana düğme).
  - **Kaydet ve çık**.
  - **Sil ve çık** (kırmızı, ikincil).
- **Kaydet ve çık**, girilen değerleri taslakta tutar ve ekranı kapatır. Ana
  sayfadaki "Devam et" kartı seansı aynı haliyle geri açar.
- Çıkınca **sayaç, mola sesi/alarmı ve kilit ekranı kartı durur**. Bu bilinçli bir
  karardır: seans "duraklatılmış" sayılır, arka planda yaşamaz. Arka planda süren
  "küçült" davranışı ayrı iştir (P07b).
- Taslak yazılamazsa ekran kapanmaz. Hata mesajı gösterilir ve kullanıcı seansta
  kalır.
- Bekleyen mola taslağa yazılmaz. Döndüğünde mola yoktur, sıradaki set seni
  bekler. Çıkışta mola sesi durduğu için, dönüşte yarım kalmış bir molanın
  kendiliğinden yeniden çalması beklenmez.
- **Süre:** seans süresi son tamamlanan setten sonraki boşta kalma süresini
  saymaz (bkz. "Süre kuralı"). Bu, kaydet-çık-dön akışında araya giren saatlerin
  süreye eklenmesini de önler.

## Neden "küçült" değil

Bugün seansın tek sahibi ekran:
- `dispose` sayaçları iptal eder.
- `dispose` mola sesini durdurur.
- `dispose` kilit ekranı kartını kapatır.

(`active_session_screen.dart:483–498`.) Ekran kapanınca da çalışmayı
sürdürmek, uygulama ömrü boyunca yaşayan bir seans denetleyicisi gerektirir.
Bunun için önce teknik not ve 14 senaryoluk kesinti testi gerekir (P07b,
review/A6 §2.2). "Kaydet ve çık" bu altyapı olmadan güvenle yapılabiliyor.

## Davranış

| Durum | Sonuç |
|---|---|
| Veri yok | Pencere açılmaz, ekran kapanır, boş taslak silinir (bugünkü gibi). |
| Kaydet ve çık | 1. `await _saveDraft()` (mola alanları boş).<br>2. Başarılıysa `activeDraftProvider` tazelenir ve ekran kapanır.<br>3. Başarısızsa SnackBar gösterilir, ekran açık kalır. |
| Sil ve çık | Bugünkü davranış: taslak silinir, kart kapanır. |
| Dönüş (Devam et kartı) | Mevcut resume yolu: değerler, set durumları, rutin bağı. Mola yok. |
| Uygulama arka plana gider | Değişmez: taslak yazılır, mola bildirimi kurulur (P-11). |

## Süre kuralı

- **Bitiş anı:** son tamamlanan setten sonra 10 dakikadan uzun bir boşluk varsa
  bitiş = son set + 1 dakika. Yoksa bitiş = şimdi.
- **Hiç set tamamlanmadıysa:** şimdi.
- Kalori tahmini süreden türediği için aynı kuraldan geçer.
- Son set anı taslağa `lastDoneAtMs` olarak yazılır. Bu yeni ve isteğe bağlı bir
  JSON alanı; eski taslaklar okunur. Şema değişmez.

## Doğrulama

- Birim testi: süre kuralı (boşluk var / yok / hiç set yok) ve taslakta
  `lastDoneAtMs` gidiş-dönüşü.
- Widget testi:
  - Kaydet ve çık → taslak duruyor, ekran kapandı.
  - Sil ve çık → taslak yok.
  - Taslak yazımı hata verir → ekran açık.
- Emülatörde: mola sürerken kaydet ve çık → başka sekmeye geç → Devam et.
  Beklenen: değerler aynı, mola yok, alarm çalmıyor.
