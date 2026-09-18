# 22 — Haftalık Değerlendirme (docs/21 #1 + #6 çekirdeği)

> **Durum:** Tasarım — Samet'in kararlarını bekliyor (§9). **Kod yazılmadı.**
> **Tarih:** 2026-09-18 · **Yazan:** Claude
> **Temel:** `main` · şema **v10** · docs/21 §2 #1 ve #6
> **İlgili:** [docs/21 — Özellik yol haritası](21-feature-roadmap.md) ·
> [docs/20 — Senkron v2](20-sync-v2.md) · [CONVENTIONS §7b](../CONVENTIONS.md)

---

## 0. Karar özeti

**Ne değişecek, neden.** Uygulama bugün veriyi topluyor ama **yorumlamıyor**:
ana sayfada "bu hafta 3 antrenman, 1.000 kg hacim" var; "geçen haftaya göre ne
oldu, bu hafta neye odaklanayım" yok. Haftalık değerlendirme, biriken kaydı
haftada bir kez okunabilir bir özete çevirir. Vizyondaki "yorumlayan asistan"ın
yapay zekâsız ilk adımı budur; hesap motoru (A1) sonradan asistanın da temeli
olur.

**Önerilen seçenek.** **Kural tabanlı**, tamamen mevcut veriden hesaplanan,
**saklanmayan** bir özet ekranı + haftada bir bildirim. *Elenenler:* (a) yapay
zekâ ile yorum — maliyet ve gizlilik kararı gerektiriyor, docs/21'de zaten
sonraya bırakıldı; (b) haftalık özetin veritabanına yazılması — yeni senkron
verisi demek, silme protokolü (docs/20 Aşama 5) bitmeden yeni silinebilir
tablo eklenmez.

**Gerçek veriye etkisi.** Ekran **yalnız okur**; hiçbir kaydı değiştirmez.
Tek yazma: profildeki yeni **hedef yönü** alanı (kilo ver / koru / al) —
kullanıcı seçtiğinde. Şema v11 → **v12** (iki nullable kolon), göç kayıpsız.
**Geri dönüş:** kolonlar nullable, eski uygulama sürümü şemayla sorunsuz
çalışır (CONVENTIONS §3.8); sunucuya da aynı iki kolon eklenir, eski istemci
onları göndermez.

**Samet'ten gereken kararlar.** §9'da 4 madde: (1) haftanın kapanış günü ve
bildirim saati, (2) hedef yönünün mevcut çelişkiyi nasıl çözeceği, (3) "bu
hafta neye odaklan" cümlesinin tonu, (4) şema sürüm çakışmasının çözümü
(bu iş v11'i alırsa senkron v2 v12'ye kayar).

**Nasıl doğrulanacak.** Hesap motoru saf Dart → veritabanısız birim testleri
(hafta sınırı, eksik kayıt, tek ölçüm, hedef yönü geçmişe uygulanmaz).
Ekran widget testiyle; bildirim zamanlaması birim testiyle. Simülatörde
Samet'in gerçek verisiyle **okuma** doğrulaması: rakamlar ana sayfadaki
"bu hafta" kutusuyla birebir aynı çıkmalı (aynı motor).

---

## 1. Bugün ne var, ne yok

| Var | Nerede |
|---|---|
| Bu hafta antrenman sayısı, hacim, yakılan kalori | `weekDashboardProvider` |
| Son 30 gün momentum | `last30WorkoutStatsProvider` |
| Haftalık seri (streak) | `weeklyStreakProvider` |
| En çok gelişen hareket (6 hafta) | `topProgressProvider` |
| Protein hedefi uyumu (kayıtlı günler) | `weeklyProteinAdherencePct` |

**Yok:** hafta kapanışı kavramı, önceki haftayla karşılaştırma, kilo trendinin
hafta ortalaması, kas grubu bazında set sayımı (#6 çekirdeği), tek yerden
okunabilir özet, hatırlatma.

**Dağınıklık:** yukarıdaki hesaplar üç dosyaya yayılmış. Aynı sayının iki
ekranda farklı çıkması bugün mümkün. Bu iş onları **tek motora** (A1) taşır.

---

## 2. Kapsam

**İlk sürümde var:** hafta özeti (2–3 cümle), antrenman bölümü, hareket
ilerlemesi, beslenme, kilo, gelecek hafta için tek odak; haftalık bildirim;
profilde hedef yönü alanı; "nereden hesaplandı" açıklaması.

**İlk sürümde yok (bilinçli):** puanlama/"gelişim skoru", çok sayıda grafik,
geçmiş haftalar arşivi, paylaşılabilir görsel, yapay zekâ yorumu, hedefi
otomatik güncelleme.

**Neden puan yok:** farklı hareketlerin ilerlemesini tek sayıya toplamak
yanıltıcı (bench'te +2,5 kg ile biceps'te +1 tekrar aynı şey değil).
Somut cümle daha anlaşılır: *"Bu hafta 3 antrenman tamamladın; beslenmede 4
gün kayıt var; kilo karşılaştırması için önceki hafta ölçümü yok."*

---

## 3. Hesap motoru (A1)

`lib/features/insights/weekly_review.dart` — **saf Dart**, veritabanı
bilmez; girdiyi DAO'lardan sağlayıcı verir, çıktıyı ekran ve (ileride)
asistan kullanır. `dashboard_stats.dart` buraya taşınır, ana sayfa da bu
motoru kullanır → aynı sayı her yerde aynı.

### 3.1 Hafta penceresi
`[start, end)` (CONVENTIONS §3). Başlangıç günü kullanıcı tercihinden
(`weekStartProvider`, varsayılan Pazartesi). **İçinde bulunulan hafta
tamamlanmamış olabilir** → özet "3 günlük veriyle" ibaresini taşır.

### 3.2 Bölümler ve kurallar

| Bölüm | Hesap | Kritik kural |
|---|---|---|
| **Hafta özeti** | Tarih aralığı + 2–3 gözlem cümlesi | Hafta bitmediyse açıkça yazılır |
| **Antrenman** | Tamamlanan seans, tamamlanan set, toplam süre, hacim | Rutinde planlı gün varsa "gerçekleşen/planlanan" (`scheduledWeekday`), yoksa yalnız gerçekleşen |
| **Hareket ilerlemesi** | Aynı hareketin bu hafta ve önceki kaydı: en iyi set (kilo × tekrar) ve tahmini 1TM (Epley) farkı | **Tek gelişim puanına toplanmaz**; en çok ilerleyen 3 hareket listelenir, yeterli veri yoksa bölüm gizlenir |
| **Beslenme** | **Kayıt girilmiş gün sayısı** + o günlerin ortalama kalori/proteini | Kayıtsız gün sıfır sayılmaz, "hedefi tutturamadın" denmez (Samet kuralı). #8 "gün tamamlandı" gelince ölçüt ona döner |
| **Kilo** | Ölçüm sayısı, hafta ortalaması, önceki hafta ortalamasıyla fark | Tek ölçüm varsa "tek ölçüm — trend sayılmaz" yazılır |
| **Kas grubu dengesi (#6 çekirdeği)** | Hafta içi set sayısının kas grubuna dağılımı (A2 eşlemesi) | Yalnız sayım; "az çalıştın" yargısı yok |
| **Gelecek hafta** | Veriye dayanan **tek** odak cümlesi | Hedefi/rutini değiştirmez, öneri olarak kalır |

### 3.3 Odak cümlesi (kural sırası)
İlk eşleşen kural kazanır — belirlenimci ve test edilebilir:
1. Planlı gün varsa ve gerçekleşen < planlanan → "planı tamamlamak".
2. Bir hareket 3 haftadır aynı kiloda ve aralık üstünde → "o harekette kiloyu
   artırmayı denemek" (docs/21 #3 ile aynı dil).
3. Beslenme kaydı olan gün sayısı < 4 → "kayıt alışkanlığı".
4. Kilo trendi hedef yönünün tersine 2 hafta üst üste gittiyse → "kalori
   hedefini gözden geçirmek" (öneri; değiştirmez).
5. Hiçbiri → "aynı ritmi sürdürmek".

### 3.4 Hedef yönü
Profilde yeni alan: **kilo ver / koru / al**. Kullanımı:
- Kilo bölümünün yorumunu belirler (aynı 0,4 kg artış, "al" hedefinde olumlu,
  "ver" hedefinde dikkat).
- **Geçmişe uygulanmaz** (Samet kuralı): yön yalnız **bu haftanın** yorumunda
  ve gelecek hafta odağında kullanılır. Değişiklik tarihi (`goalDirectionSince`)
  saklanır; daha eski haftalar yorumlanırken yön **bilinmiyor** sayılır.
- Bugünkü çelişki (hedef kilo 80 kg ama kalori hedefi harcamanın üstünde)
  ilk açılışta tek seferlik bir soruyla çözülür (§9 soru 2).

---

## 4. Ekran

`/insights/week` — Ana Sayfa'daki "Bu Hafta" kutusundan ve bildirimden açılır.

- Üstte tarih aralığı + hafta bitmediyse uyarı satırı.
- Bölümler kart olarak, yukarıdaki sırayla. Verisi olmayan bölüm **gizlenmez**,
  "bu hafta kayıt yok" der — eksikliğin kendisi bilgi.
- Her kartta **"nereden hesaplandı"** (A3): tarih aralığı, kaç kayıt, hangi
  kural. Güven için şart; sayıya itiraz eden kullanıcı kaynağı görebilmeli.
- Grafik: yalnız kilo bölümünde küçük bir çizgi (zaten `fl_chart` var).

---

## 5. Bildirim (A5)

- Haftada bir, hafta kapanış günü akşamı; dokununca bu ekran açılır.
- Metin kısa ve yargısız: *"Haftan hazır: 3 antrenman, 4 gün beslenme kaydı."*
- `NotificationService.scheduleDaily` bugün `DateTimeComponents.time` ile
  günlük tekrar kuruyor; haftalık için `dayOfWeekAndTime` eklenecek.
- Ayarlar → Bildirimler altında açma/kapama (mevcut bildirim tercihleriyle
  aynı yerde).

---

## 6. Şema ve senkron

Yeni iki kolon (`user_profile`): `goal_direction` (text, nullable),
`goal_direction_since` (datetime, nullable). CONVENTIONS §3 kontrol listesi
aynı commit'te uygulanır: şema **v12**, göç adımı, `drift_dev schema dump`,
kayıpsız göç testi, tripwire güncellemesi.

**Sunucu:** `user_profile` senkron edilen tablo → aynı iki kolon Supabase'de
de açılır (küçük `ALTER TABLE`, ücretli plan gerektirmez). Sıra: yedek → dalda
dene → uygula → aynı gün uygulama sürümü (docs/20 §11 kuralı).

**Sürüm çakışması — karar verildi (2026-09-18):** senkron v2 Aşama 1 önce
uygulandı ve **v11'i o aldı**. Hedef yönü alanı bu yüzden **v12** olacak.

---

## 7. Test planı

| # | Test | Neyi kilitler |
|---|---|---|
| W-1 | Hafta penceresi `[start, end)`; pazar/pazartesi tercihleri | Sınır kaymaları |
| W-2 | Tamamlanmamış hafta → "N günlük veri" ibaresi | Yanlış kıyas |
| W-3 | Beslenme: 3 gün kayıt → ortalama 3 güne bölünür, 7'ye değil | Samet kuralı |
| W-4 | Kayıtsız hafta → "kayıt yok", hedef yargısı YOK | Samet kuralı |
| W-5 | Tek kilo ölçümü → trend iddiası yok | Yanıltıcı yorum |
| W-6 | Hedef yönü değişmeden önceki haftalar "bilinmiyor" sayılır | Geçmişe uygulama yasağı |
| W-7 | Odak cümlesi kural sırası (5 senaryo) | Belirlenimcilik |
| W-8 | Hareket ilerlemesi: farklı hareketler toplanmaz | Tek puan yasağı |
| W-9 | Motor ile ana sayfa aynı sayıyı verir | Çift hesap tutarsızlığı |
| W-10 | Göç v10 → v11 kayıpsız + yeni kolonlar null | Veri kaybı |
| W-11 | Haftalık bildirim doğru gün/saate kurulur, kapalıyken kurulmaz | Bildirim kirliliği |

---

## 8. Aşamalar

| Aşama | İçerik | Tahmin |
|---|---|---|
| 1 | Hesap motoru + testler (`dashboard_stats` taşınır) | 1 gün |
| 2 | Şema v11 + hedef yönü alanı (profil ekranı) + sunucu kolonları | 0,5 gün |
| 3 | Ekran + "nereden hesaplandı" | 1 gün |
| 4 | Haftalık bildirim + ayar | 0,5 gün |
| 5 | Ana sayfanın motora bağlanması (tek kaynak) | 0,5 gün |

Toplam ≈ **3,5 gün**. Her aşama tek başına commit edilebilir; 2. aşama sunucu
değişikliği içerdiği için uygulama sürümüyle **birlikte** yayınlanır.

---

## 9. Kararlar ve açık sorular

| # | Konu | Öneri |
|---|---|---|
| 1 | **Hafta kapanışı ve bildirim saati** | Hafta başlangıcı Pazartesi (mevcut tercih) → kapanış **Pazar 20:00**. Hafta bitmeden bakmak isteyen ekranı her zaman açabilir. |
| 2 | **Profildeki çelişki** | Hedef yönü alanı ilk kez doldurulurken tek soru: "Hedefin ne?" Cevap "kilo al" ise hedef kilo 80 kg değeri düzeltilir; "ver" ise kalori hedefi harcamanın altına çekilir. Otomatik değiştirme yok, onayla. |
| 3 | **Odak cümlesinin tonu** | Yargısız ve tek cümle ("Bu hafta planındaki 4 antrenmandan 3'ünü tamamladın — hedef aynı ritmi sürdürmek"). Suçlayıcı dil ("kaçırdın") yok. |
| 4 | **Şema sürümü** | ✅ Çözüldü: senkron v2 v11'i aldı (2026-09-18), bu iş **v12** olacak. Karar gerekmiyor. |
