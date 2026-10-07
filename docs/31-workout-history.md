# 31 — Antrenman Geçmişi: bulunur, özet + detay

> **Durum:** Kodlandı (2026-10-08) · **Kaynak:** Samet'in 2026-10-07 geri
> bildirimi (#5 geçmiş, #7 RPE nerede kullanılıyor).
> **İlgili:** `history_summary.dart`, `record_calc.dart`, docs/29 (RPE'li
> ilerleme).

## Karar özeti

**Ne değişiyor, neden.** Geçmiş yalnız Antrenman başlığındaki küçük saat
ikonundan açılıyordu; kart açılınca sadece "hareket / kg × tekrar" listesi
vardı. RPE (Algılanan Zorluk Derecesi) her sette kaydediliyor ama yalnız
kalori tahmininde ve dışa aktarmada kullanılıyordu, ekranda hiç görünmüyordu.

**Önerilen (Hevy/Strong ortak pratiği):**
1. **Bulunurluk:** Antrenman sekmesinde rutinlerin altında **"Son
   antrenmanlar"** bölümü — son 3 seans kartı + "Tümünü gör". Başlıktaki ikon
   da kalır.
2. **Özet kart (liste):** ad · tarih · süre; hacim · set · rekor sayısı;
   en fazla 3 hareket satırı "3 set · Bench Press — en iyi 80 kg × 8",
   fazlası "+2 hareket". Dokununca detay sayfası (açılır kart yerine).
3. **Detay sayfası:** istatistik şeridi (süre, hacim, set, ~kcal, ortalama
   RPE); kırılan rekorlar; çalışan kaslar (set sayısıyla); her hareket için
   setler — tip rozeti, kg × tekrar, **set RPE'si**, rekor setinde kupa — ve
   **geçen sefere göre** satırı ("+5 kg", "+2 tekrar", "aynı"); seans notu.
   Tarih değiştir / sil menüsü detay sayfasına taşınır.

*Elenen:* takvim görünümü (ilerleme sekmesinde aktivite takvimi zaten var);
kas haritası görseli (kas çipleri yeter, harita hareket detayında var).

**Gerçek veriye etkisi.** Yok — şema, senkron, hesap değişmedi; yalnız
okuma. Rekor tanımı Özet ekranıyla aynı (`newRecordFor`): seans tarihinden
önceki geçmişi aşan e1RM (Epley tahmini 1 tekrar maksimum) ya da en ağır kilo.

**RPE nerede kullanılıyor (cevap #7):**
- Kalori tahmini (ortalama RPE yoğunluğu belirler) — Ana sayfa, aktivite,
  geçmiş.
- Dışa aktarma (Markdown/JSON/CSV).
- **Yeni:** geçmiş detayında set başına ve seans ortalaması.
- **Sırada:** ilerleme önerisine katmak — docs/29 (Samet'in 4 kararı).

**Nasıl doğrulanır.** `history_summary_test` (en iyi set, rekor sayımı,
geçen sefer farkı, kas dağılımı, ortalama RPE). Emülatörde (Dev hesabı):
Antrenman sekmesinde bölüm görünür → kart → detay; RPE'li set rozetli.
