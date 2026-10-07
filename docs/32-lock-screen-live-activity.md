# 32 — Kilit ekranında antrenman (Canlı Etkinlik)

> **Durum:** Faz 1 kodlandı (2026-10-08, iOS) · **Kaynak:** Samet'in
> 2026-10-07 geri bildirimi #3 ("Hevy örneği incelenmeli").
> **İlgili:** docs/25 (Android dinlenme servisi), docs/27 (Hevy incelemesi).

## Karar özeti

**Ne değişiyor, neden.** Antrenman sırasında telefon kilitliyken ne
yapılacağını görmek için uygulamayı açmak gerekiyordu. Hevy, iOS'ta Canlı
Etkinlik (Live Activity) ile kilit ekranında ve Dynamic Island'da şu anki
hareketi, seti ve dinlenme sayacını gösteriyor.

**Faz 1 (bu sürüm, iOS 16.2+):** salt görüntü.
- Kilit ekranı: seans adı + geçen süre, şu anki hareket, "Set 2/4 · 80 kg
  × 8" (sıradaki setin önerisi), dinlenme geri sayımı (büyük, neon), set
  ilerleme çubuğu.
- Dynamic Island: küçükte dambıl + dinlenme ya da süre; açıkta hareket ve
  hedef.
- Sayaçlar sistem tarafından çizilir (`Text(timerInterval:)`) — uygulama
  uykudayken de akar. Bu, "alttayken dinlenme bitişi görünmüyor"
  sorununu da görsel olarak çözer; bitiş sesi yine bildirimden gelir.
- Dokununca uygulama açılır. Seans bitince/atılınca etkinlik kapanır.

**Faz 2 (sonraki):** kilit ekranından **etkileşim** — "Seti tamamla",
"+15 sn / Atla" düğmeleri (iOS 17 `LiveActivityIntent`). Düğme arka planda
uygulamayı uyandırır; Flutter tarafının uykudan güvenle yazması ayrı tasarım
ister (taslak + seans durumu tek doğruluk kaynağı). Android karşılığı:
dinlenme servisini seans boyu süren bildirime genişletmek + eylem düğmeleri.

*Elenen:* üçüncü taraf `live_activities` paketi — App Group ister; ücretsiz
Apple hesabıyla App Group'u riske atmamak için durum doğrudan ActivityKit'e
taşınıyor (paylaşılan dosya yok).

**Gerçek veriye etkisi.** Yok — şema/senkron değişmedi; yalnız görüntü.

**İmza.** Ücretsiz (Personal Team) hesapla widget eklentisi imzalandı
(2026-10-08): `com.sametorhan.fitPack.WorkoutLiveActivity`, profil 7 gün —
uygulamayla aynı yenileme. Developer Program gerekmiyor.

**Nasıl doğrulanır.** `live_activity_test` (şu anki set, köprü: başlat →
güncelle → bitir, aynı durum gönderilmez, Android'de çağrı yok). iPhone'da:
rutini başlat → kilitle → kilit ekranında hareket/set; seti tamamla →
dinlenme geri sayımı kilit ekranında akar; bitir → etkinlik kalkar.

## Teknik

- `ios/Runner/WorkoutActivityAttributes.swift` — iki hedefin ORTAK derlediği
  öznitelik (alan değişirse ikisi birlikte).
- `ios/Runner/WorkoutLiveActivityController.swift` — başlat/güncelle/bitir.
- `ios/WorkoutLiveActivity/` — widget eklentisi (iOS 16.2+, Runner'a gömülü).
- `AppDelegate.swift` — `fit_pack/live_activity` kanalı.
- Dart: `core/live_activity/workout_live_activity.dart` (köprü, aynı durumu
  tekrar göndermez), `features/workout/live_position.dart` (şu anki set);
  seans ekranı `_syncLive()` — taslak yazımı, dinlenme başla/bitti/±15 sn,
  atla; bitir/at/kapan → `end`.
- `Info.plist`: `NSSupportsLiveActivities` (+ sık güncelleme).
- Eklenti hedefi `xcodeproj` gem'iyle eklendi; Xcode'da elle dokunmaya
  gerek yok.
