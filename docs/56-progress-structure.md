# 56 — İlerleme sekmesi: Antrenman / Vücut / Hafta (Faz 3C)

18 Ekim 2026 · Kaynak: deneyim araştırması 02 U05, 06 "İlerleme" satırı,
review/A2 hata #6. Durum: **öneri, Samet onayı bekliyor.**

## Karar özeti

**Samet kararı (18 Ekim 2026):** İ-1 evet, İ-2 Antrenman — önerildiği gibi; kodlama başladı.

- **Sorun (U05):** "İlerleme" sekmesi bugün yalnız şunları gösteriyor:
  - Aktivite takvimi.
  - Fotoğraflar.
  - Vücut ölçümü.

  Kuvvet gelişimi hareket ayrıntısında (`/exercise/:id`), haftalık
  değerlendirme ayrı bir sayfada. "Bench'im nasıl gidiyor?" sorusunun
  cevabı İlerleme'de yok.
- **Öneri:** Sekmenin üstüne üç parçalı seçici gelir: **Antrenman · Vücut ·
  Hafta**.
  - **Vücut:** bugünkü sayfanın aynısı (takvim, fotoğraf, ölçüm). Hiçbir şey
    kaybolmaz.
  - **Antrenman:**
    - Ana hareketlerin günlük en iyi tahmini 1RM (tek tekrar maksimum)
      eğilimi. Codex'in Faz 2 günlük en iyi hesabı kullanılır.
    - Son 30 günün kişisel rekorları.
    - Haftalık hacim.
  - **Hafta:** Mevcut haftalık değerlendirme sayfası buraya gömülür; ayrı rota
    da kalır (bildirim ve "Haftan hazır" oraya gider).
- **Varsayılan parça:** Son seçilen. İlk açılışta **Antrenman** (antrenman
  verisi yoksa Vücut).
- Yeni veri yok. Şema, senkron ve rota değişmez; mevcut DAO sorguları yeterli.
  Kod 1–2 oturum, cihaz turu 1 akşam.

## 1. Antrenman parçası

| Bölüm | İçerik | Kaynak |
|---|---|---|
| Ana hareketler | En sık yapılan 3–5 hareket (son 8 hafta). Her biri için günlük en iyi e1RM (tahmini 1RM) eğrisi, son değer ve 4 haftalık fark. Dokununca `/exercise/:id`. | `exercise_daily_best.dart` (Faz 2), `record_calc.dart` |
| Rekorlar | Son 30 günün yeni kişisel rekorları: tarih, hareket, değer | `record_calc` / seans setleri |
| Hacim | Son 8 haftanın haftalık toplam hacmi; sütun grafik, kayıtsız hafta boşluk | `dashboard_providers` toplamları |
| Boş durum | "Karşılaştırma için 2 antrenman daha" ve antrenman başlat | — |

Kurallar:
- Tek seans bir "gelişim" sayılmaz. Eğri en az iki farklı gün ister (A2 hata #6
  dersi).
- Isınma setleri hesaba girmez.
- Birim tercihi (kg/lb) uygulanır.

## 2. Hafta parçası

`weekly_review_screen` gövdesi bir widget'a ayrılır. Hem `/insights/week`
rotası hem bu parça aynı widget'ı kullanır. Geçmiş haftalar arasında
oklarla gezilir (bugünkü davranış).

## 3. Test ve kabul

- **Birim:**
  - Ana hareket seçimi (sıklık, eşitlikte son tarih).
  - 4 haftalık fark.
  - Tek gün → eğri yok.
- **Widget:**
  - Üç parça.
  - Varsayılanın hatırlanması.
  - Boş durumlar.
  - 320 ve 1,6× yazıda taşma yok.
  - Erişilebilirlik kılavuz testi geçer.
- **Görev testi:**
  - "Bench gelişimimi bul": İlerleme → Antrenman, 2 dokunuşta.
  - "Son ölçümüm": İlerleme → Vücut.

## 4. Samet'ten karar

- **İ-1:** Üç parça (Antrenman · Vücut · Hafta) uygun mu? Önerim: evet.
- **İ-2:** İlk açılışta varsayılan parça Antrenman mı olsun, Vücut mu? Önerim:
  Antrenman. Kilo verme hedefin varsa Vücut daha mantıklı olabilir; bu karar
  senin.
