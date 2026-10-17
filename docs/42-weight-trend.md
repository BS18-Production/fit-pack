# 42 — Trend kilo (yumuşatılmış kilo)

> **Durum:** Uygulanıyor (2026-10-11). Samet: "önerdiğin sırayla ilerle" (yeni
> özellikler 1. madde). · **Sahip:** Claude-2

## 0. Karar özeti

**Ne değişecek.** Günlük tartı su/tuz yüzünden ±1 kg oynar. Fit Pack ham
ölçümlerin yanında **trend kilo** hesaplar: üstel hareketli ortalama (her yeni
günlük ölçüm farkın %10'u kadar trendi çeker — "Hacker's Diet" yöntemi,
yaklaşık 10 günlük pencere). Vücut ölçümü grafiğinde ham ölçümler soluk nokta,
trend kalın çizgi. Ana Sayfa'daki kilo farkı **"son iki satırın farkı"
yerine "7 günlük trend değişimi"** olur.

**Neden.** Önceki fark iki ham ölçümün farkıydı: sabah 0,8 kg fazla tartılınca
"kilo aldın" görünüyordu. Trend gerçek yönü gösterir.

**Seçilen yol:** üstel ortalama, boşluklu günlerde katsayı gün sayısına göre
ölçeklenir (`1 − 0,9^gün`) — 5 gün tartılmayıp gelen ölçüm 5 günlük ağırlık
alır. *Elenen:* 7 günlük basit hareketli ortalama — eksik günlerde zıplar ve
geride kalır; doğrusal regresyon — docs/36 kilo yorumunda zaten var, grafik
için kırılımları düzleştirir.

**Gerçek veriye etkisi.** Yok — saf hesap, şema değişmez. Girdi docs/40'ın
günde tek değer serisi.

## 1. Kurallar

| # | Kural |
|---|---|
| T-1 | Girdi: günde tek kilo (docs/40 W-4), eskiden yeniye |
| T-2 | İlk trend = ilk ölçüm; sonra `trend += (1 − 0,9^gün) × (ölçüm − trend)`, gün = önceki ölçümden bu yana takvim günü |
| T-3 | Trend **hazır**: ≥ 3 ölçüm ve ilk–son arası ≥ 7 gün. Hazır değilse grafik yalnız ham, Ana Sayfa eski farkı gösterir |
| T-4 | 7 günlük değişim = son trend − 7 gün önceki trend (o güne en yakın önceki nokta); yoksa `null` |
| T-5 | Trend yalnız gösterim: hedefleri, kalori hedefini, yorum kurallarını değiştirmez (docs/36 kendi ≥14 gün regresyonunu kullanır) |

## 2. Doğrulama

Birim: sabit kilo → trend sabit; tek sıçrama → trend %10 hareket eder;
5 günlük boşluk → `1 − 0,9^5` ağırlık; T-3 eşikleri; T-4 değişimi.
iPhone: grafikte noktalar + çizgi; Ana Sayfa "7 günlük trend".
