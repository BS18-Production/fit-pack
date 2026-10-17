# 44 — Antrenmanı Apple Sağlık / Health Connect'e yazma (Faz 2)

> **Durum:** Uygulanıyor (2026-10-11). Samet: "önerdiğin sırayla ilerle"
> (yeni özellikler 3. madde). · **Sahip:** Claude-2

## 0. Karar özeti

**Ne değişecek.** Ayarlar → Sağlık → "Antrenmanları Sağlık'a yaz" açıksa,
Fit Pack'te **canlı** kaydedilen her seans bitince Apple Sağlık'a (Android'de
Health Connect'e) "kuvvet antrenmanı" olarak yazılır: başlangıç, bitiş, seans
adı. Apple Fitness / Sağlık'ın antrenman listesinde görünür.

**Bilerek yazılmayanlar.**
- **Kalori:** Fit Pack'in tahmini kaba (MET × süre, dinlenme payı dahil) ve
  Apple Watch kendi ölçtüğü aktif enerjiyi zaten yazıyor → çift sayım ve "yanlış
  veri yazma" yasağı (App Store 5.1.3-ii).
- **Elle girilen seans:** bitiş saati yok; saat uydurulmaz (aynı kural).

**Tek kayıt garantisi.** Sağlık'tan okuma izni istenmez (en az veri). Bunun
yerine cihazda küçük bir giden kutusu: seans "yazılıyor" diye işaretlenir,
yazılınca kutudan çıkar. Uygulama tam yazma sırasında kapanırsa o seans
**yeniden denenmez** — eksik kayıt, çift kayıttan iyidir.

**İkinci cihaz.** Yalnız seansı **bitiren** cihaz yazar; buluttan inen seans
yazılmaz.

**Not (Apple Watch).** Watch'ta ayrıca antrenman başlatırsan Sağlık'ta iki
antrenman görünür; bu özellik açıkken Watch'ta başlatmaya gerek yoktur. Watch
nabız ve hareket verisini yine kendisi kaydeder. Halkalara katkı Apple'ın
kuralına bağlıdır (hareket halkası Watch'un ölçtüğü enerjiden dolar).

**Gerçek veriye etkisi.** Fit Pack verisi değişmez; şema yok. Tercih ve giden
kutusu `SharedPreferences`'ta, hesap değişiminde silinir.

## 1. Kurallar

| # | Kural |
|---|---|
| H-1 | Yalnız tercih açıkken ve seansın başlangıç + bitişi varken yazılır |
| H-2 | Tür: kardiyo seans → iOS karışık kardiyo / Android diğer; geri kalan → kuvvet antrenmanı |
| H-3 | Giden kutusu: `pending` → (yazma öncesi) `writing` → başarılıysa silinir; açılışta `writing` kalan atlanır |
| H-4 | Yazma izni ayrıca istenir (iOS `NSHealthUpdateUsageDescription`, Android `WRITE_EXERCISE`); okuma izni istenmez |
| H-5 | Hata seansı bozmaz; öne gelişte yeniden denenir |
