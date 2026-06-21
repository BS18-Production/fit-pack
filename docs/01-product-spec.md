# Fit Pack — Ürün Gereksinim Dokümanı (Product Requirements Document — PRD)

> **Doküman versiyonu:** 1.1
> **Tarih:** 2026-05-13
> **Sahibi:** Samet Orhan
> **Durum:** Final onay bekliyor (tüm açık sorular cevaplandı)
> **Kaynak:** Samet ile yapılan keşif sohbetinden derlenmiştir.

Bu doküman **Fit Pack uygulamasının ne olduğunu, kim için olduğunu, ne yapması ve ne yapmaması gerektiğini** tanımlar. Kod yazılmadan önce bu spec onaylanır, ardından mimari ve UX dokümanlarına geçilir.

---

## 1. Vizyon

> **"Sportif gelişimimi yaptığım her şeyle birlikte tek yerde gören sadık asistanım olmalı."**

Fit Pack, kullanıcının fiziksel verisini (antrenman, beslenme, ölçü, sakatlık, takviye, uyku, stres, foto) tek noktada toplayan ve **AI (Artificial Intelligence — Yapay Zeka)** ile yorumlayan kişisel sportif asistandır. Hedef, uzaktan eğitim veren fitness eğitmeninin yerini doldurabilecek seviyede kişiselleştirilmiş içgörü sunmaktır.

---

## 2. Persona (Hedef Kullanıcı)

### V1 (mevcut faz): Pilot Kullanıcı — Samet
- **Yaş:** 28
- **Yaşam tarzı:** Tam zamanlı ofis çalışanı (Customer Success Specialist, Inveon.ai startup)
- **Stres seviyesi:** Yüksek (8/10)
- **Fitness deneyimi:** Yeni dönüş, haftada 2-4 gün antrenman, bilinçli ama orta seviye
- **Teknoloji:** AI araçlarına açık, hızlı adapte olur, otomasyon sever
- **Dil:** Türkçe ana, İngilizce ikincil
- **Cihaz:** Android (öncelik), iOS (ileri faz)

### V3+ (gelecek faz): Genel Hedef Kitle
> **"Spor yapan, gelişimini düzenli takip etmek isteyen, AI destekli kişisel asistan deneyimine açık birey."**
>
> Pilot başarılı olursa public release planlanır. Bu fazda persona detaylandırılacak.

---

## 3. Problem Tanımı (Problem Statement)

### Mevcut Sıkıntı
AI'nın hayatımıza girdiği çağda, **fitness takibinde kullanılan mevcut araçlar iki uçta hatalı:**

1. **Sadece veri toplayan ama yorumlamayan araçlar** (Strong, Hevy, vs.)
   → Kullanıcı kendi pattern'ini bulmak zorunda, çoğu zaman bulamıyor.

2. **Yüksek ücretli uzaktan eğitim veren fitness eğitmenleri**
   → Pahalı, ölçeklenemez, eğitmenin kalitesine bağlı, geri bildirim yavaş.

### Çözüm
Fit Pack, kullanıcı verisini sürekli toplayıp **AI ile yorumlayarak** "kişisel coach" deneyimi sunan bir orta yol oluşturur. Kullanıcı bir insandan çok daha hızlı, sürekli, tarafsız analiz alır.

---

## 4. Hedefler ve Başarı Kriterleri

### Ürün Hedefi
**3 ay içinde** Samet'in (pilot) sportif gelişimini somut, kanıtlanabilir şekilde göstermek; günlük rutine yerleşmiş bir araç haline gelmek.

### Başarı Kriterleri (3 ay sonra ölçülecek)

| # | Kriter | Tipi | Ölçüm |
|---|--------|------|-------|
| 1 | **3 aylık fiziksel değişim bariz görülmeli** (kilo, yağ, foto, ölçü trendi) | Sonuç | Grafiklerde net trend; foto karşılaştırması |
| 2 | **Günde en az 1 kez uygulamayı açıyor olmalıyım** | Tutma (Retention) | App-açılış log; 90 günün ≥%80'i |
| 3 | **Yemek log etme alışkanlığım haftada en az 5 gün düzenli olmalı** | Davranış | Haftalık ortalama yemek log gün sayısı |

### Anti-Hedef (yapmaması gereken)
- Sıkıcı/karmaşık olup silinmemeli
- Reklamla bunaltmamalı
- Veri girişi yorucu olmamalı

---

## 5. Kullanıcı Senaryoları (User Stories)

Format: *Bir [kullanıcı tipi] olarak, [eylem] yapmak istiyorum, çünkü [sebep].*

### Antrenman
- **US-01:** Bir kullanıcı olarak, antrenman gününde her hareketin set/tekrar/ağırlığını ve **RIR (Reps in Reserve — Yedek Tekrar)** değerini hızlıca girmek istiyorum, çünkü bilimsel ilerleme için bu veriler şart.
- **US-02:** Bir kullanıcı olarak, geçen hafta yaptığım hareketin ağırlığını uygulamada görmek istiyorum, çünkü bu hafta ne kadar yüklenmem gerektiğine karar vermem gerek.
- **US-03:** Bir kullanıcı olarak, antrenman içi set arası **dinlenme zamanlayıcısı** istiyorum, çünkü 90/120 saniye disiplinine ihtiyacım var.
- **US-04:** Bir kullanıcı olarak, sakatlık (sağ diz, sağ dirsek) durumumu antrenman bazlı kaydetmek istiyorum, çünkü ağrının hangi hareketle arttığını/azaldığını görmem lazım.

### Beslenme
- **US-05:** Bir kullanıcı olarak, yediğim yemeği gram bazında hızlıca log edebilmek istiyorum, çünkü günlük protein/kalori hedefimi takip etmem gerekiyor.
- **US-06:** Bir kullanıcı olarak, su tüketimimi ve takviyelerimi günlük olarak kaydetmek istiyorum, çünkü bu da antrenman performansımı etkiliyor.

### Ölçüm & İlerleme
- **US-07:** Bir kullanıcı olarak, kilom/bel/göğüs/kol ölçülerimi haftalık girmek ve **grafikte trendini görmek** istiyorum, çünkü ilerlemenin somut kanıtı bu.
- **US-08:** Bir kullanıcı olarak, ön/yan/arka **ilerleme fotoğrafı** çekip karşılaştırmak istiyorum, çünkü tartı her zaman değişimi yansıtmıyor.

### Genel Sağlık
- **US-09:** Bir kullanıcı olarak, günlük stres (1-10), uyku saati ve günlük not (mood) girmek istiyorum, çünkü stres/uyku antrenman sonuçlarını çok etkiliyor.

### AI Asistan
- **US-10:** Bir kullanıcı olarak, AI'dan **haftalık özet rapor** almak istiyorum, çünkü 7 günde ne ilerlediğimi tek bakışta görmek istiyorum.
- **US-11:** Bir kullanıcı olarak, sorularımı (örn: "bu hafta neyi yanlış yaptım?", "yarın leg day için ne yiyeyim?") AI asistana sormak istiyorum, çünkü kişisel coach deneyimi bekliyorum.
- **US-12:** Bir kullanıcı olarak, AI'ın verimi düşük gördüğü antrenman/öğün için **uyarı veya öneri** sunmasını istiyorum, çünkü pattern'leri kendim göremiyorum.

### Motivasyon
- **US-13:** Bir kullanıcı olarak, üst üste antrenman/log gün sayım (streak) görmek istiyorum, çünkü bu beni motive ediyor.
- **US-14:** Bir kullanıcı olarak, başardığım kilometre taşları için **rozet/achievement** kazanmak istiyorum.
- **US-15:** Bir kullanıcı olarak, **akıllı bildirim** almak istiyorum (örn: "bugün antrenman günü", "takviye saati"), çünkü unutuyorum.

---

## 6. Feature Listesi (Önceliklendirilmiş)

> Öncelik: **P0** = Olmadan ürün anlamsız | **P1** = V1 release için zorunlu | **P2** = Olursa çok iyi | **P3** = İleri faz

### V1 — Çekirdek (P0 + P1)

| ID | Feature | Öncelik | V1'de var mı? |
|----|---------|---------|----------------|
| F-01 | Antrenman log (set / tekrar / kg) | P0 | ✅ |
| F-02 | RIR (Yedek Tekrar) değer girişi | P0 | ❌ Yeni |
| F-03 | Set arası dinlenme zamanlayıcısı | P0 | ✅ |
| F-04 | Yemek log + makro (kalori/protein/karb/yağ) | P0 | ✅ |
| F-05 | Vücut ölçümü (kilo + bel/göğüs/kol/kalça/boyun + yağ %) | P0 | ✅ |
| F-06 | İlerleme fotoğrafı çekme + galeri (**hibrit saklama:** DB'de sıkıştırılmış 1600px/JPEG %85/~500KB + telefon galerisine orijinal) | P0 | ❌ Yeni |
| F-07 | Su tüketimi günlük takibi | P1 | ❌ Yeni |
| F-08 | Takviye logu (ne, ne kadar, ne zaman) | P1 | ❌ Yeni |
| F-09 | Günlük log (stres, uyku, ağrı diz, ağrı dirsek, mood) | P1 | ❌ Yeni |
| F-10 | Auto-progression önerisi (geçen hafta vs bu hafta) | P0 | ⚠️ Yarı |
| F-11 | Kilo / hacim / protein / ağrı trend grafikleri (fl_chart) | P0 | ❌ Yeni |
| F-12 | Foto önce/sonra karşılaştırma | P0 | ❌ Yeni |
| F-13 | Streak (üst üste antrenman/log gün sayısı) | P0 | ✅ |
| F-14 | Achievement / rozet sistemi | P1 | ⚠️ Tablo var, UI yok |
| F-15 | Akıllı bildirim (antrenman, takviye, vs.) | P1 | ❌ Yeni |
| F-16 | Veri export (Markdown / JSON / CSV) | P1 | ✅ |
| F-17 | Antrenman geçmişi (history) ekranı | P1 | ⚠️ TODO |

### V1 — AI Asistan (P0 + P1)

| ID | Feature | Öncelik |
|----|---------|---------|
| F-20 | **Switchable LLM Provider** mimarisi (Gemini başlangıç, sonra değiştirilebilir) | P0 |
| F-21 | Haftalık AI özet rapor (Pazar gece veya açılışta) | P0 |
| F-22 | AI sohbet (kullanıcının soru sorabildiği) | P1 |
| F-23 | AI pattern uyarıları (örn: "3 haftadır protein hedefini tutturamıyorsun") | P1 |
| F-24 | Pre-WO (Pre-Workout — Antrenman Öncesi) checklist | P1 |
| F-25 | Kural tabanlı offline insight'lar (AI olmadığında fallback) | P1 |

### V2 — Genişleme (P2)

| ID | Feature | Öncelik |
|----|---------|---------|
| F-30 | Plate calculator (barbell + plaka hesaplayıcı) | P2 |
| F-31 | Sakatlık tag → alternatif hareket önerisi | P2 |
| F-32 | Adım sayacı entegrasyonu (Google Fit / Apple Health) | P2 |
| F-33 | Recipe builder (yemek tarifi → makro hesaplama) | P2 |
| F-34 | Barkod okuma (yemek arama hızlandırma) | P2 |
| F-35 | Deload (boşaltma haftası) takibi ve hatırlatması | P2 |

### V3+ — İleri Faz (P3)

| ID | Feature | Öncelik |
|----|---------|---------|
| F-50 | Çoklu kullanıcı (auth + cloud sync) | P3 |
| F-51 | Bulut yedekleme + cihaz senkronu | P3 |
| F-52 | Kullanıcının kendi LLM API key'ini girmesi (premium AI) | P3 |
| F-53 | Eğitmen-öğrenci ilişki modu | P3 |
| F-54 | Public release (Play Store + App Store) | P3 |

---

## 7. Out-of-Scope (V1'de Bilinçli Olarak YAPILMAYACAKLAR)

| Konu | Neden? |
|------|--------|
| Çoklu kullanıcı / hesap sistemi | Pilot tek kullanıcı (Samet). V3'e ertelendi. |
| Bulut sync / yedekleme | V1 lokal odaklı, basitlik için. Yedek için export yeterli. |
| Sosyal özellikler (feed, paylaşım) | Vizyon değil, dikkat dağıtır. |
| Reklam | Anti-hedef. Asla. |
| Premium / freemium model | V1 kişisel kullanım. Public release zamanı düşünülecek. |
| Eğitmen modu | İlk kullanıcı tek başına gelişmeli. |
| Apple Watch / Wear OS uygulaması | Mobil uygulama V1 odaklı. |

---

## 8. Açık Sorular ve Riskler

### Cevaplanan Sorular (v1.1'de kapatıldı)
- [x] **Q-01:** Gemini API anahtarı → ✅ Samet'in API key'i mevcut, Google AI Studio'da kurulu.
- [x] **Q-02:** Foto saklama → ✅ **Hibrit yaklaşım benimsendi.** DB'de sıkıştırılmış kopya (1600px, JPEG %85, ~500KB) + telefon galerisine orijinal kalitede kayıt. Gerekçe: DB şişmesini önlemek ama orijinal yedek kalsın.
- [x] **Q-03:** AI rate limit handling → ✅ Limit dolduğunda hata göster + sonraki güne ertele (kural tabanlı insight fallback'i V2 sonrasına bırakıldı).
- [x] **Q-04:** Bildirim izni reddi → ✅ Sessizce devam edilir, in-app reminder (uygulama içi hatırlatıcı) ile feature degraded çalışır.
- [x] **Q-05:** SQLite şifreleme → ✅ **AÇIK.** Drift SQLCipher + Android Keystore (Android'in güvenli anahtar deposu) kombinasyonu. Kullanıcı parola girmez, OS otomatik halleder (transparent encryption — şeffaf şifreleme). Gerekçe: Fitness verisi hassas (kilo, foto, sakatlık geçmişi), telefon çalınırsa veri okunamasın; V3 public release için zaten gerekli olacak, baştan koyalım; performans kaybı yok.

### Riskler
| Risk | Olasılık | Etki | Azaltma |
|------|----------|------|---------|
| Kullanıcının her gün veri girmeyi unutması | Yüksek | Yüksek | Akıllı bildirim + hızlı giriş UX |
| Gemini API'sının geri sınırlanması/kapanması | Düşük | Yüksek | Switchable provider mimarisi |
| Sakatlık/ağrı kötüleşmesi sırasında uygulama tarafında uyarısız geçilmesi | Orta | Orta | Pattern detection + uyarı |
| Veri kaybı (telefon bozulması vs.) | Orta | Çok Yüksek (10/10) | Zorunlu haftalık export hatırlatması, V1.5'te bulut yedek |

---

## 9. Bağımlılıklar

### Teknik
- Flutter (mevcut)
- Drift (SQLite) (mevcut)
- Riverpod (mevcut)
- fl_chart (mevcut, V1'de ilk kez kullanılacak)
- `health` paketi (V2 için adım sayısı)
- Gemini API (`google_generative_ai` paketi veya HTTP client)
- `image_picker` veya `camera` paketi (foto için)
- `flutter_image_compress` (foto sıkıştırma — Q-02 hibrit yaklaşım)
- `gal` veya `image_gallery_saver` (orijinal fotoğrafı telefon galerisine kaydetme — Q-02)
- `flutter_local_notifications` (akıllı bildirim)
- `flutter_secure_storage` (API anahtarı için)
- `drift_sqlcipher` + Android Keystore entegrasyonu (Q-05 — şeffaf DB şifreleme)

### Kullanıcı Tarafı
- Samet'in günlük disiplini (veri girişi)
- Mezura (sipariş edildi 2026-05-10, ölçümler için)
- Akıllı tartı (opsiyonel, V1'de manuel giriş)

---

## 10. Onay & Versiyon Geçmişi

| Versiyon | Tarih | Değişiklik | Onay |
|----------|-------|------------|------|
| 1.0 (taslak) | 2026-05-10 | İlk taslak — keşif sohbetinden | ✅ Geçti |
| **1.1** | **2026-05-13** | **Q-01..Q-05 tüm açık sorular cevaplandı. Foto için hibrit saklama, DB için SQLCipher şifreleme onaylandı. Bağımlılıklar listesi güncellendi.** | **⏳ Final onay bekliyor** |

**Onay süreci:**
1. ✅ Samet keşif sohbetinde temel kararları onayladı (v1.0)
2. ✅ Q-01..Q-05 cevapları alındı (v1.1)
3. ⏳ Samet v1.1'i okur, final onay verir
4. Onaylanır → final v1.1 (kilit)

**Onay sonrası:** `docs/02-architecture.md` (Mimari Doküman) yazımına geçilir.
