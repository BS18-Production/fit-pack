# 25 — Dinlenme sayacı: arka planda ses + tek parça geri sayım

> **Durum:** ✅ Kodlandı (2026-09-30) · emülatörde doğrulandı · **telefonda
> doğrulama bekliyor** (SM A075F — asıl sorun Samsung'a özgü olabilir).
> **Yazan:** Claude · **Kaynak:** Samet'in salon notu (NEXT_TASKS A3)
> **İlgili:** [docs/16 §5 — bildirimler](16-settings-profile-ia.md) ·
> `tools/make_rest_sounds.py`

---

## 0. Karar özeti

**Ne değişti, neden.** Samet'in iki şikâyeti vardı:
1. "2. ve 3. bip kayıyor gibi."
2. "Uygulama alttayken (başka uygulama açıkken) son 3 saniyenin sesi gelmiyor."

(1)'in sebebi: her saniye oynatıcı durdurulup yeniden başlatılıyordu
(`stop` + `resume`); zayıf telefonda bu 50–300 ms **değişken** gecikme
veriyor. (2)'nin en olası sebebi: Samsung'un arka plan dondurucusu
(Freecess) alttaki uygulamanın sürecini saniyeler içinde donduruyor; Dart
zamanlayıcısı hiç tetiklenmiyor. Sade Android emülatöründe (Android 14)
eski kod arka planda çaldı — yani sorun cihaza özgü.

**Seçilen çözüm.**
- **Tek parça ses:** `rest_countdown.wav` = 3 tık (0, 1, 2. sn) + bitiş
  (3. sn). Bitişten tam 3 sn önce **bir kez** başlatılır → aralıklar
  örnek hassasiyetinde sabit. Ses de değişti: "yarış" (3 kısa + 1 uzun
  yüksek bip). Eski adaylar betikte duruyor.
- **Android: ön plan servisi** (`RestTimerService`, Kotlin). Dinlenme
  başlayınca açılır, bitince kendini kapatır. Bildirimde canlı geri sayım
  (sistem çizer) gösterir, kısmi uyanıklık kilidi tutar, sesi ve bitiş
  titreşimini **kendisi** çalar. Uygulama ekrandaysa "bitti" bildirimi
  atmaz. Strong/Hevy gibi uygulamaların Android'deki yöntemi budur.
- **iOS / servis başlatılamazsa:** eski yol — uygulama içi zamanlayıcı aynı
  tek parça dosyayı çalar; arka planda bildirim (docs/16 §5).

*Elenenler:* (a) Zamanlanmış bildirimin sesini geri sayım dosyası yapmak —
Android 14'te dakik alarm izni varsayılan kapalı, dakik olmayan alarm
dakikalarca gecikebilir. (b) Sessiz ses döngüsüyle süreci canlı tutmak —
dinlenme boyunca kullanıcının müziğini kısardı.

**Gerçek veriye etkisi.** Yok — şema, senkron, kayıt değişmedi.

**Geri dönüşü pahalı olan taraf.** Yeni izinler: `FOREGROUND_SERVICE`,
`FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK`, `VIBRATE`. Servis türü
`mediaPlayback` (Android 14 tür zorunluluğu; servisin işi ses çalmak).
**Play Store'a çıkışta** Play Console'da ön plan servisi beyanı + kısa video
gerekir. Tür reddedilirse alternatif `specialUse` (yine beyan) ya da
`shortService` (3 dk sınırı — 5 dk molada yetmez).

**Samet'ten gereken kararlar.**
1. ☐ Yeni ses ("yarış") beğenildi mi? Adaylar:
   `python3 tools/make_rest_sounds.py --demo KLASÖR` → 4 tam geri sayım
   dosyası. Değiştirmek tek satır (`SECILI_TIK` / `SECILI_BITIS`).
2. ☐ Telefonda doğrulama (§3).

## 1. Akış

```
✓ set → _startRest → deadline
  ├─ Android: RestAlarm.start → RestTimerService (ön plan)
  │    ├─ bildirim: "Dinlenme  00:59" (geri sayan kronometre)
  │    ├─ deadline − 3 sn: MediaPlayer.start (önceden prepare edilmiş)
  │    └─ deadline: titreşim + (uygulama alttaysa ve mola bildirimi açıksa)
  │                 "Dinlenme bitti" bildirimi → 1,5 sn sonra servis kapanır
  └─ diğer: Timer(deadline − 3 sn) → FeedbackService.playCountdown
±15 sn → aynı çağrı yeni deadline ile (servis yeniden kurar;
          3 sn'den az kaldıysa dosyanın içinden başlar — countdownPlan)
Atla / seanstan çık → RestAlarm.stop
```

Ekrandaki sayı Dart'ta güncellenmeye devam eder (`restTickDelayMs`); ses
ondan bağımsızdır. Android'de ses/titreşim **yalnız** servisten gelir — iki
kaynak olursa bipler üst üste biner.

## 2. Dosyalar

- `android/.../RestTimerService.kt` — servis.
- `android/.../MainActivity.kt` — `fit_pack/rest_timer` kanalı.
- `lib/core/feedback/rest_alarm.dart` — Dart köprüsü (Android dışında no-op).
- `lib/core/feedback/feedback_service.dart` — tek parça çalma,
  `countdownPlan` (test: `test/core/rest_cue_test.dart`).
- `assets/sounds/rest_countdown.wav` + `android/app/src/main/res/raw/` kopyası
  — ikisi de betikten üretilir.

## 3. Doğrulama

**Emülatör (2026-09-30, Android 14):** servis `isForeground=true`,
`types=mediaPlayback`; bildirimde "Rest · 00:51" geri sayımı; uygulama
alttayken ses odağı isteği deadline'dan tam 3,00 sn önce
(`22:05:39.229`), ses çaldı. Emülatörün ses saati milisaniye ölçümü için
güvenilir değil ("device stall time corrected").

**Telefonda yapılacak (Samet):**
1. Seansta set işaretle → uygulamayı alta al → Instagram/YouTube aç.
   Son 3 sn: tık-tık-tık-bitiş duyulmalı, müzik varsa kısılmalı.
2. Aynısını ekran kilitliyken (telefon cepte).
3. Uygulama açıkken: bipler ekrandaki 3-2-1 ile aynı anda mı?
4. Bildirim alanında "Dinlenme" geri sayımı görünüyor mu?
