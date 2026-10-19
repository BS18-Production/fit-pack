# 11 — Araştırma kaynakları

18 Ekim 2026 · Bütün bağlantılara bu tarihte erişildi. Arşiv kopyası alınmadı;
içerik sonradan değişebilir.

## Kanıt sınıfları

| Sınıf | Anlamı | Ne için yeterli | Ne için yetersiz |
|---|---|---|---|
| **K — Kod** | FitPack kaynağında dosya:satır ile doğrulanan davranış (kaynak anı `07104d1`) | "Uygulama bunu yapıyor / yapmıyor" | Kullanıcının bunu nasıl yaşadığı |
| **R — Render** | `visuals/current/` altındaki 76 görüntü: mevcut widget testleriyle bellek içi örnek veriden üretildi | Yerleşim, sıra, ilk görünüm, dar ekran ve büyük yazı | Gerçek hesap verisi, akıcılık, dokunma başarısı |
| **Q1 — Resmî yardım** | Üreticinin yardım merkezinde anlattığı işleyiş | "Rakip bunu belgeliyor" | Hız, memnuniyet, tüm platformlarda aynılık |
| **Q2 — Resmî tanıtım** | Ürün sayfası, blog, sürüm notu | Konumlandırma ve özellik varlığı | Sonuç iddiaları (taraflı olabilir) |
| **S — Standart / rehber** | W3C, Apple, Google, Flutter | Ölçülebilir kabul eşikleri | Ürün tercihi |
| **H — Hipotez** | Uzman çıkarımı | Test edilecek tasarım fikri | Doğrulanmış sonuç |

Rakip uygulamalarına hesapla girilmedi, cihazda görev testi yapılmadı (G = doğrudan
gözlem sınıfı rakipler için boştur). Kullanıcı görüşmesi, anket veya analitik yok.

## Rakip kaynakları (Q1/Q2)

Tam tablo, sayfada görülen tarih ve her kaynağın sınırı:
[workstreams/competitive-sources.md](workstreams/competitive-sources.md) (S01–S30).
Özet:

| Ürün | Kaynaklar | En güçlü kanıt |
|---|---|---|
| Strong | S01–S03 | Mola ve şablon davranışı (Q1) |
| Hevy | S04–S06 | 2026 özellik kılavuzu; Trainer programları (Q1) |
| Fitbod | S07–S10 | Plan girdileri ve düzenlenebilir öneri (Q1) |
| MyFitnessPal | S11–S14 | 2026 "Today" geçişi, 28 Nis ve 20 Ağu 2026 güncellemeleri (Q1) |
| MacroFactor | S15–S18 | Hedef / tahmini harcama ayrımı (Q1) |
| Nike Training Club | S19–S20 | Yalnız tanıtım (Q2) |
| Strava | S21–S22 | Üyelik kapsamı (Q1) |
| Gentler Streak | S23–S27 | Activity Path ve dinlenmeyi tanıyan seri (Q1) |
| Todoist (kategori dışı) | S28–S30 | Quick Add, 1 Eyl 2026 güncellemesi (Q1) |

## Standartlar ve platform rehberleri (S)

- Dokunma hedefi: [Apple düğme rehberi](https://developer.apple.com/design/human-interface-guidelines/buttons) (44×44 pt),
  [Android erişilebilirlik rehberi](https://support.google.com/accessibility/android/answer/7101858?hl=en) (48×48 dp),
  [WCAG 2.2 — 2.5.8 hedef boyutu](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) (24×24 CSS px, web ölçütü).
  Üç birim birbirine eşitlenmedi; FitPack için 48×48 mantıksal birim seçildi.
- Kontrast: [WCAG 2.2 — 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html),
  [1.4.11 metin dışı kontrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).
- Android görünüm erişilebilirliği: [developer.android.com](https://developer.android.com/guide/topics/ui/accessibility/views/apps-views).
- Canlı etkinlik: [Apple Live Activities HIG](https://developer.apple.com/design/human-interface-guidelines/live-activities),
  [ActivityKit](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities).
- Flutter: [erişilebilirlik testleri](https://docs.flutter.dev/ui/accessibility/accessibility-testing),
  [azaltılmış hareket — disableAnimationsOf](https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html),
  [Android durum geri yükleme](https://docs.flutter.dev/platform-integration/android/restore-state-android),
  [giriş ve odak](https://docs.flutter.dev/ui/adaptive-responsive/input).

## Davranış bilimi

- [Lally ve ark., 2010 — gerçek hayatta alışkanlık oluşumu](https://onlinelibrary.wiley.com/doi/abs/10.1002/ejsp.674)
- [Teixeira ve ark., 2012 — egzersiz ve öz belirleme kuramı](https://selfdeterminationtheory.org/SDT/documents/2012_TeixeiraEtAl_IJBNPA.pdf)
- [NICE PH49 — davranış değişimi rehberi](https://www.nice.org.uk/guidance/ph49/chapter/recommendations)

Bu kaynaklar ilke düzeyinde kullanıldı (özerklik, yeterlik, bağlam ipucu). FitPack
kullanıcılarında etki büyüklüğü iddiası yapılmadı.

## FitPack iç kaynakları (K)

Kod: `lib/` (dosya:satır bağlantıları 02, 04, 07, 08'de). Önceki tasarım kararları:
docs/15 (kurulum V2), docs/26 (öğün hatırlatıcısı), docs/45 (Ekim geri bildirim
turu), docs/49 (yeni kullanıcı), docs/50 (Bugün satırları), docs/51 (geri çağırma).

## Bilinen kanıt boşlukları

1. **Kullanıcı yok:** Bugünkü görev süresi, hata oranı, tutma oranı ölçülmedi.
   Hiçbir sayı "mevcut performans" olarak sunulmadı.
2. **Rakipler denenmedi:** Davranışlar belgeden okundu.
3. **Gerçek cihazda dokunma testi yok:** Hedef boyutları koddan ölçüldü;
   yanlış dokunma oranı bilinmiyor.
4. **Ekran okuyucu uçtan uca denenmedi:** Adsız kontrol riski kodda var;
   gerçek arıza gözlenmedi.
5. **Görsel kavramlar kurgu veridir:** `visuals/concept-*.png` ve `concepts.html`
   üretim ekranı değil, karşılaştırma için çizilmiş öneridir.
