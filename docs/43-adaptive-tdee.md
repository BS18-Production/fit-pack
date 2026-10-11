# 43 — Gerçek harcama tahmini (uyarlanabilir TDEE)

> **Durum:** Uygulanıyor (2026-10-11). Samet: "önerdiğin sırayla ilerle" (yeni
> özellikler 2. madde). · **Sahip:** Claude-2

## 0. Karar özeti

**Ne değişecek.** Profil'deki formül TDEE'nin (Toplam Günlük Enerji Harcaması —
Mifflin-St Jeor × aktiflik çarpanı) altında **"Gerçek harcama tahmini"** çıkar:
son 28 günde **tamamlandı işaretli** beslenme günlerinin ortalama kalorisi ile
aynı dönemdeki kilo eğiliminden hesaplanır. Yanında, mevcut kalori hedefiyle
tahmini haftalık kilo değişimi yazar.

**Neden.** Formül bir tahmindir (aktiflik çarpanı kabaca seçilir); kişinin
gerçek harcaması ±%10–20 sapabilir. Kilo ve yeme kaydı birlikte bakılınca
vücut ne harcadığını kendisi söyler (MacroFactor'ın temel yöntemi). Adım ve
saat kalorisi **kullanılmaz** — çift sayım yok (rapor §6).

**Hedef kendiliğinden değişmez** (Samet kuralı): yalnız bilgi ve sonuç
("bu hedefle haftada ~0,4 kg kayıp"); hedefi kullanıcı değiştirir.

**Gerçek veriye etkisi.** Yok — saf hesap, şema değişmez.

## 1. Kurallar

| # | Kural | Neden |
|---|---|---|
| A-1 | Pencere: bugünden önceki 28 gün `[bugün − 28, bugün)` | Bugün henüz bitmedi |
| A-2 | Alım: yalnız **tamamlandı** işaretli günler (#8, docs/37); ≥ 10 gün | Yarım kayıtlı gün alımı düşük gösterir → harcama düşük çıkar |
| A-3 | Kilo: günde tek değer (docs/40), pencerede ≥ 4 ölçüm ve ilk–son ≥ 14 gün; eğim en küçük kareler | Tek ölçüm sıçraması baskın olmasın (docs/36 ile aynı yöntem) |
| A-4 | Harcama = ortalama alım − eğim(kg/gün) × 7.700 kcal/kg, 50'ye yuvarlanır | 1 kg vücut dokusu ≈ 7.700 kcal — yaygın yaklaşım; kesin değil, kartta "tahmin" yazar |
| A-5 | Sonuç 1.200–5.000 kcal dışındaysa sayı gösterilmez, "kayıtlar tutarsız görünüyor" denir | Büyük olasılıkla eksik kayıt |
| A-6 | Hedefle sonuç: (kalori hedefi − harcama) × 7 / 7.700 kg/hafta | Bilgi; hedefi değiştirmez |
| A-7 | Eksik veride ne eksik olduğu yazar (kaç tamamlanmış gün / kaç tartı gerekli) | Kullanıcı ne yapacağını bilsin |

## 2. Doğrulama

Birim: sabit kilo + 2.300 kcal → harcama 2.300; haftada −0,5 kg + 2.000 kcal →
~2.550; yarım (tamamlanmamış) gün sayılmaz; A-2/A-3 eşikleri; A-5 sınırı;
A-6 işareti. iPhone: Profil'de kart, eksik veri metni.
