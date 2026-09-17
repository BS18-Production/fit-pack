# 21 — Özellik Önerileri Değerlendirmesi ve Yol Haritası

> **Durum:** Sıra **onaylandı** (Samet, 2026-09-17). Kararlar §6'da. **Kod yazılmadı.**
> **Tarih:** 2026-09-17 · **Yazan:** Claude (gece görevi)
> **Temel:** `main` @ `6009362` + çalışma ağacı (Paket 3) · şema **v10**
> **Girdi:** Samet'in 10 önerisi + 2 sonraki aşama önerisi (2026-09-16),
> Codex'in öncelik önerisi, [docs/01 PRD](01-product-spec.md),
> [docs/17](17-improvement-analysis.md), [docs/19](19-progress-photos.md),
> [docs/20 Senkron v2](20-sync-v2.md), güncel kod.

**Ürün vizyonu (Samet):** antrenman, beslenme ve vücut gelişimini tek yerde
takip eden; zamanla bu verileri yorumlayan kişisel sportif asistan.
**Öncelikler:** hızlı veri girişi · günlük kullanımda değer · anlaşılır
gelişim takibi. **Yok:** reklam, sosyal rekabet.

---

## 0. Kısa özet

**Önerilen sıra** (gerekçe §4):

| Sıra | Özellik | Neden şimdi | Senkron v2'yi bekler mi? |
|---|---|---|---|
| 1a | **#11 Hareket arama v2** ✅ | Samet'in doğrudan şikâyeti; "şınav" 0 sonuç, "lat" 485 sonuç; yalnız cihazda | Hayır |
| 1 | **#3 Antrenmanda bir sonraki hedef** ✅ | En sık kullanılan ekran; Paket 1'deki öneri (G-2) altyapısının doğal devamı; yeni tablo yok | Hayır |
| 2 | **#1 Haftalık değerlendirme** (kural tabanlı) + **#6'nın çekirdeği** (kas grubu set sayımı) | Vizyonun "yorumlayan asistan" kısmının ilk adımı; tamamen mevcut veriden hesaplanır | Hayır |
| 3 | **#4 İlerleme fotoğrafları** (docs/19 dilim 1, yalnız cihazda) | PRD'nin P0'ı, uzun süredir tasarımı hazır; uzak senkrondan muaf | Kısmen (yalnız muafiyet kuralı) |
| 4 | **#2 Öğün şablonları — küçük sürüm:** "geçmişten öğün kopyala" | Yeni tablo olmadan değerin çoğu; tam şablon senkron v2 sonrası | Küçük sürüm: hayır |
| 5 | **#8 Beslenme günü tamamlandı** | Haftalık değerlendirmenin beslenme kısmını güvenilir yapar | **Evet** (yeni senkron verisi) |
| 6 | **#5 Esnek antrenman planı** | Değeri yüksek ama "bugünün antrenmanı", seri ve ana sayfa mantığına dokunuyor | **Evet** |
| 7 | **#7 Günlük durum kaydı** | #1 ve #10 ile birleşince değer kazanır | **Evet** |
| 8 | **#10 Kişisel veri asistanı** (önce hazır sorular, yapay zekâ sonra) | #1 ve #6'nın hesap motorunu yeniden kullanır | Hayır (yapay zekâ aşaması ayrı karar) |
| 9 | **#9 Ana ekran widget'ı** | Yerel (native) iki platform işi; hesap izolasyonu ve veri paylaşımı gerektirir | Kısmen |
| 10 | **#13 Rozetler** | Hesaplanan veri; #1'in motorunu kullanır | Hayır |
| 11 | **#12 Takviye kaydı** | Yeni, silinebilir senkron verisi | **Evet** |

**Codex'in sırasından farkı:** Codex "haftalık değerlendirme → öğün
şablonları → ilerleme fotoğrafları" dedi. Haftalık değerlendirmeye ve
fotoğraflara katılıyorum. İki fark var:
(1) **Bir sonraki hedef öne çıktı.** Samet'in son geri bildirimlerinin hepsi
seans ekranındaydı (mola sesi, önceki değeri taşıma, varsayılan mola); bu
özellik aynı koda (`set_prefill.dart`) yaslanıyor ve her antrenmanda değer
üretiyor.
(2) **Öğün şablonları geriye kaydı ve küçüldü.** Tam şablon, iki yeni
senkron tablosu ve silinebilir veri demek; silme protokolü (docs/20 Aşama 5)
olmadan eklenirse silinen şablonlar geri gelir. Değerin çoğunu yeni tablo
gerektirmeyen "geçmişten öğün kopyala" verir.

**Bağımlılık kuralı (docs/20):** *Kullanıcının silebileceği yeni bir senkron
verisi üreten özellik, senkron v2 Aşama 5 (silme protokolü) bitmeden
yayınlanmaz.* Aksi halde "sildiğim şey geri geldi" hatası o özelliğe de
bulaşır. Hesaplanan (türetilmiş) ve yalnız cihazda kalan özellikler bu
kuraldan muaf.

---

## 1. Yöntem ve dokümanlarla kod arasındaki farklar

Her öneri güncel koda karşı kontrol edildi (dosya:satır kanıtları ilgili
bölümlerde). Eski dokümanların bir kısmı artık gerçeği yansıtmıyor:

| Doküman ne diyor | Kod ne diyor | Sonuç |
|---|---|---|
| PRD F-06: fotoğraf DB'de sıkıştırılmış + **orijinali telefon galerisine** | docs/19 (daha yeni): dosya uygulama klasöründe, **galeriye yazılmaz** (gizlilik) | docs/19 geçerli |
| PRD F-02: RIR (yedek tekrar) girişi | Seans ekranı **RPE** (algılanan zorluk) kullanıyor (`active_session_screen.dart`) | RPE geçerli; RIR ≈ 10 − RPE |
| PRD F-20: değiştirilebilir yapay zekâ sağlayıcısı (Gemini) | Kodda **hiçbir** yapay zekâ çağrısı/paketi yok | Planlı, başlanmamış |
| `recipe_items` tablosu ve `foods.is_recipe` | Hiç kullanılmıyor; `is_recipe` her yerde `false` (`nutrition_screen.dart:791,828`, `foods_screen.dart:78`) | Ölü altyapı (şemada duruyor, ADR-007) |
| `workout_sessions.energy`, `.notes`, `.knee_status` | Tabloda var (`workout_tables.dart:41-44`), **arayüzde yok** | Günlük durum (#7) için kısmi temel |
| `workout_sets.rest_seconds` | Var ama **hiç yazılmıyor** (Paket 1'de tespit) | Gerçek mola analizi için veri yok |
| `progress_photos` | Tablo + DAO var (`body_dao.dart:42-49`), **ekran yok** | docs/19 dilim 1 bekliyor |
| Rutin günü | Rutin başına **tek** hafta günü (`workout_tables.dart:78`) | Esnek plan (#5) için model yetersiz |

---

## 2. Özellikler

Efor ölçeği: **S** ≤ 1 gün · **M** 2–3 gün · **L** 4–6 gün · **XL** > 6 gün
(1 gün = test + cihaz doğrulaması dahil bir odaklı oturum).

### #1 — Haftalık değerlendirme ve gelecek haftanın odağı

**Mevcut durum: kısmen var (parçalar dağınık).**
- Ana Sayfa "Bu Hafta" ızgarası: hacim + önceki haftaya göre değişim,
  yakılan kalori, planlı/yapılan antrenman, protein hedefi uyumu
  (`dashboard_providers.dart:45-104`, `dashboard_stats.dart`).
- "En çok gelişen hareket" içgörüsü — son ~6 haftada e1RM (tahmini tek tekrar
  maksimumu) artışı (`dashboard_stats.dart:43-74`, `topProgressProvider`).
- Haftalık seri (`streak_calc.dart`), kilo trendi (`weightTrendProvider`).
- **Yok:** bunları tek bir haftalık özette birleştiren ekran, "sonraki odak"
  önerisi, haftalık bildirim (bildirim servisi yalnız günlük tekrar
  destekliyor — `notification_service.dart:160`).
- **Dikkat:** protein uyumu yalnız **kayıt girilen günlerden** hesaplanıyor
  (`dashboard_stats.dart:76-78`) → eksik kayıt ile düşük tüketim ayırt
  edilemiyor (#8'in konusu).

**Çözdüğü ihtiyaç:** "Bu hafta nasıl gitti, önümüzdeki hafta neye
odaklanmalıyım?" sorusuna 30 saniyede cevap. PRD US-10 / F-21 / F-25 (kural
tabanlı içgörü).

**En küçük yararlı sürüm (kural tabanlı, yapay zekâ yok):**
- Ana Sayfa'da hafta bitince (kullanıcının hafta başlangıç gününe göre)
  "Geçen haftanın özeti" kartı → ayrıntı ekranı.
- Dört bölüm, her biri tek cümle + sayı + "nereden hesaplandı":
  1. **Devamlılık:** planlı X / yapılan Y antrenman; seri durumu.
  2. **Performans:** e1RM'i artan / düşen / aynı kalan hareketler (en az 2
     seans verisi olanlar).
  3. **Beslenme:** kayıtlı gün sayısı (X/7), kayıtlı günlerde kalori ve
     protein hedef uyumu. Kayıt 4 günden azsa yorum yapılmaz, yalnız
     "yetersiz kayıt" denir.
  4. **Kilo:** hafta ortalaması ve önceki haftaya göre fark (tek ölçüme değil,
     ortalamaya bakılır); yön, hedef kiloya göre yorumlanır
     (`weight_goal.dart`).
- **Sonraki odak:** öncelik sırasıyla tek bir kural tetiklenir (ör. "Planlı 4
  günün 2'si yapıldı → önümüzdeki hafta hedef 3"; "Protein 5 günün 4'ünde
  hedefin altında → her öğüne bir protein kaynağı"). Kurallar sabit bir
  tabloda, metni açıklanabilir.
- Kas grubu set dağılımı (#6 çekirdeği) bu ekranda bir bölüm olarak yer alır.
- **Haftalık bildirim (Samet kararı: evet):** hafta bitiminde (varsayılan
  Pazar 20:00; hafta Pazar başlıyorsa Cumartesi 20:00), Ayarlar →
  Bildirimler'den saat/kapatma. Bildirim metni yalnız "Haftalık özetin hazır"
  der; sayılar kilit ekranında görünmez.

**Efor:** M (hesap motoru + ekran + kurallar) + S (haftalık bildirim).

**Bağımlılıklar:** A1 hesap motoru, A2 kas eşlemesi (§3). Senkron v2
gerekmez (türetilmiş, kaydedilmez). #8 gelince beslenme bölümü güvenilir olur.

**Risk:** Kötü kurgulanmış öneri güveni zedeler → her önerinin gerekçesi ve
kullanılan veri görünmeli; veri yetersizse öneri verilmez.

---

### #2 — Öğün şablonları

**Mevcut durum: kısmen var.**
- "Dünü kopyala": yalnız **dünün tüm günü**, hedef gün boşken
  (`nutrition_dao.dart:216`, transaction'lı).
- "Son kullanılanlar" şeridi (`getRecentFoods`, `nutrition_dao.dart:188`).
- Tarif altyapısı (`recipe_items`, `foods.is_recipe`) **ölü** — hiç yazılmıyor.
- **Tarif ≠ şablon:** tarif, birden çok besinin **tek bir besin** olarak
  kaydıdır (makrolar birleşir, sonradan tek tek düzenlenemez). Şablon ise
  **ayrı kayıtlar** olarak eklenir ve eklemeden önce her miktar
  değiştirilebilir. Tarif tablosunu şablon için kullanmak, iki farklı
  kavramı tek tabloya sıkıştırır; önerilmez.

**Çözdüğü ihtiyaç:** Her gün aynı kahvaltıyı 4–5 dokunuşla tek tek girmek.
Vizyonun "hızlı veri girişi" önceliği.

**En küçük yararlı sürüm (yeni tablo YOK):** **"Geçmişten öğün kopyala"**
- Öğün kartında "⋯ → Başka günden kopyala": son 14 günün aynı öğünü (ör.
  kahvaltı) tarihleriyle listelenir.
- Seçince öğündeki besinler **düzenlenebilir bir listede** açılır (miktar
  değiştir, çıkar) → "Ekle" tek transaction'la ekler.
- "Dünü kopyala"nın öğün düzeyindeki hali; mevcut `copyDayLogs` kalıbı
  genişletilir.

**Tam sürüm (senkron v2 sonrası):** adlandırılmış şablon ("Her zamanki
kahvaltım") — `meal_templates` + `meal_template_items` tabloları; öğünden
"Şablon olarak kaydet"; Yemek Ekle panelinde şablon şeridi.

**Efor:** küçük sürüm S–M · tam sürüm M.

**Bağımlılıklar:** tam sürüm → docs/20 Aşama 5 (şablon silme/düzenleme
senkronu). Küçük sürüm bağımsız.

---

### #3 — Antrenmanda bir sonraki hedef — ✅ uygulandı (2026-09-17)

**Mevcut durum: kısmen var.**
- Paket 1 (G-2): geçen seansın aynı seti "ÖNCEKİ" sütununda; ✓'e basınca boş
  alanlar öneriyle dolar (`set_prefill.dart`). Öneri = **geçen sefer ne
  yaptıysan**; ilerleme yok.
- Rutinde hedef set ve **tekrar aralığı** var (`targetRepsMin/Max`,
  varsayılan 8–12 — `routine_builder_screen.dart:75-76`); seansta
  kullanılmıyor.
- Rekor/e1RM hesapları hazır (`record_calc.dart`).
- PRD F-10 "otomatik ilerleme önerisi" ⚠️ yarım olarak işaretli.

**Çözdüğü ihtiyaç:** "Bugün bu harekette ne yapmalıyım?" kararını salonda,
ekrana bakmadan hızlı vermek. Aşamalı yüklenme (progressive overload) —
gelişimin ana mekanizması.

**En küçük yararlı sürüm:**
- **Tek ilerleme kuralı: çift ilerleme** (double progression) — önce tekrar
  aralığının üstüne çık, sonra kiloyu artır, tekrarı aralığın altına indir.
  - Geçen sefer tüm çalışma setleri aralığın **üst sınırına** ulaştıysa →
    **kilo artırma önerisi** (varsayılan **+1,25 kg** — Samet kararı), tekrar =
    alt sınır.
  - Ulaşmadıysa → aynı kilo, tekrar **+1** (üst sınırı aşmadan).
  - Geçen sefer tekrar **alt sınırın altında** kaldıysa → aynı kilo, aynı
    hedef ("tekrar dene").
- **Kilo artışı kullanıcının inisiyatifinde (Samet kararı):** öneri
  kendiliğinden uygulanmaz. Setlerin soluk önerisi **geçen seferki kiloda**
  kalır (G-2 davranışı); hareket başlığının altında gerekçe + düğme görünür:
  *"Geçen sefer 3×12 @ 60 kg — aralığın üstü. Hazırsan +1,25 kg dene."*
  **[Artır]** → yalnız bu seansın önerileri 61,25 kg × 8 olur; tekrar
  dokununca geri alınır. Tekrar artışı (+1) da aynı şekilde öneri olarak
  kalır.
- **Artış miktarı ayarlanabilir:** Ayarlar'da genel değer (varsayılan
  1,25 kg; imperial'de 2,5 lb). Hareket başına ayar sonraki sürümde.
- **Kurallar:** hedef rutini **değiştirmez**; set yapılmış **sayılmaz**
  (✓ yine kullanıcının dokunuşu).
- Rutinsiz (boş) antrenmanda ve süre/mesafe hareketlerinde öneri yok (G-2
  davranışı sürer).

**Sonraki sürüm:** kullanıcının seçebileceği kurallar (sabit tekrar + kilo
artışı, RPE tabanlı, yüzde tabanlı), hareket başına artış miktarı, deload
(boşaltma haftası) önerisi (PRD F-35).

**Efor:** M.

**Bağımlılıklar:** yok (yeni tablo yok; kural ayarı başta sabit). Ayar
eklenirse `shared_preferences` yeterli; hareket başına ayar → yeni senkron
verisi → senkron v2 sonrası.

**Risk:** Yanlış öneri sakatlık riskine dönüşebilir (Samet'in diz/dirsek
geçmişi — PRD US-04). Artış küçük ve öneri her zaman görünür gerekçeli olmalı.

---

### #4 — İlerleme fotoğrafları ve karşılaştırma

**Mevcut durum: yalnız veri katmanı var, tasarım hazır.**
- `progress_photos` tablosu (tarih, açı, `image_path`) + DAO
  (`body_dao.dart:42-49`); **ekran yok**; görüntü seçme paketi yok.
- docs/19 dilim 1 tasarımı (2026-08-02): cihazda kalan fotoğraflar, göreli
  dosya adı (K-1), **uzak senkrondan muafiyet ama hesap değişiminde silme**
  (K-2), silmede diski temizleme (K-3), 1440 px / %85 sıkıştırma, galeriye
  yazmama (gizlilik).

**Çözdüğü ihtiyaç:** Tartı yanıltırken görsel değişimi görmek. PRD P0
(F-06, F-12), başarı kriteri 1.

**En küçük yararlı sürüm:** docs/19 dilim 1 aynen + **ölçü bağlantısı:**
karşılaştırma ekranında her fotoğrafın altında o tarihe en yakın (±3 gün)
kilo ve bel ölçüsü; yoksa "ölçüm yok".

**Efor:** M–L (paket + dosya servisi + 3 ekran + testler + iOS turu).

**Bağımlılıklar:**
- `syncRemoteExcluded` kümesi (docs/19 K-2) — fotoğraf satırı ilk kez
  yazılmadan önce gelmeli.
- docs/20 ile çakışma: v2'de silme tetikleyicileri `progress_photos` için
  mezar taşı üretmemeli (uzaktan muaf tablo) — docs/20 uygulanırken not.
- Dilim 2 (bulut yedeği) → senkron v2 + Supabase Storage + açık kullanıcı
  onayı.

**Risk:** En hassas veri. docs/19 §6 gizlilik kuralları pazarlıksız.

---

### #5 — Esnek antrenman planı

**Mevcut durum: yok (yalnız gün bazlı).**
- Rutin başına tek `scheduledWeekday` (`workout_tables.dart:78`).
- "Bugünün rutini" o günün hafta gününe bakıyor (`routine_providers.dart:35-60`);
  kaçırılan gün kaybolur, sıra kavramı yok.
- Haftalık seri hedefi planlı gün sayısından geliyor (`streak_calc.dart`).

**Çözdüğü ihtiyaç:** Haftanın gününe bağlı olmayan programlar (Push → Pull →
Legs); kaçırılan günün planı bozmaması.

**En küçük yararlı sürüm:**
- Plan türü seçimi: **Gün bazlı** (bugünkü) ya da **Sıralı**.
- Sıralı planda rutinlerin sırası + haftalık hedef antrenman sayısı.
- "Bugün" = sıradaki rutin (son yapılan rutinin bir sonrakisi); kaçırılan gün
  sırayı kaydırmaz, yalnız bekletir.
- Ana Sayfa kartında "Bugün yap" ve "Atla (sıradakine geç)".
- Seri hedefi sıralı planda haftalık hedef sayısından gelir.

**Sonraki sürüm:** "başka güne taşı", haftayı yeniden planlama, takvim
görünümü.

**Efor:** L (plan modeli + Ana Sayfa + Antrenman sekmesi + seri + testler).

**Bağımlılıklar:** yeni senkron verisi (plan tanımı, sıra durumu) → **docs/20
Aşama 5**. Sıra durumu türetilebilir (son seansın rutininden) → saklanması
gereken yalnız plan tanımı.

**Risk:** Ana Sayfa'nın "dinlenme günü zekası" ve seri mantığıyla çakışma;
iki modun testle korunması gerekir.

---

### #6 — Kas grubu bazında antrenman özeti

**Mevcut durum: veri var, özet yok.**
- Her harekette `primary_muscle` ve `muscle_groups` (JSON dizi)
  (`workout_tables.dart:9,18`); kas haritası widget'ı var (`muscle_map.dart`).
- Haftalık/kas bazlı sayım yok; Ana Sayfa yalnız toplam hacim gösteriyor.

**Çözdüğü ihtiyaç:** "Hangi kas grubunu az/çok çalışıyorum?" Toplam kilo
yanıltıcıdır (bacak hareketleri hacmi şişirir).

**En küçük yararlı sürüm:**
- Haftalık **çalışma seti** sayısı (ısınma hariç, tamamlanmış setler), kas
  grubu başına; son 4 haftanın ortalamasıyla karşılaştırma.
- **Sayım kuralı (açıklanır):** birincil kas = 1 set, ikincil kas = 0,5 set.
- Ekranda "nasıl sayıldı" bilgisi; hacim kilosu **gösterilmez** ya da ikincil
  bilgi olarak kalır.
- İlk yer: haftalık değerlendirmenin bir bölümü (#1). Sonra İlerleme'de ayrı
  kart.

**Efor:** S–M (hesap + kart). **Veri durumu (ölçüldü, 2026-09-17):** 1015
hareketin hepsinde `primary_muscle` ve `muscle_groups` dolu; 661'inde ikincil
kas da var. Birincil kaslar zaten sade gruplarda (legs 270, shoulders 150,
back 138, core 106, chest 101, triceps 81, biceps 59, calves 32, glutes 31,
forearms 25, full_body 22) — eşleme işi küçük.

**Bağımlılıklar:** A2 kas eşlemesi (kas adlarının sade gruplara indirgenmesi:
göğüs, sırt, omuz, kol, bacak, karın). Senkron gerekmez.

---

### #7 — Kısa günlük durum kaydı

**Mevcut durum: çok az.**
- Seans tablosunda `energy`, `rpe`, `notes`, `knee_status` kolonları var,
  arayüz kullanmıyor (`workout_tables.dart:41-44`). Seans RPE'si geçmişte
  gösteriliyor ama girilmiyor.
- Günlük (seanstan bağımsız) kayıt yok. PRD US-09 / F-09 (stres, uyku, ağrı,
  ruh hali) açık.

**Çözdüğü ihtiyaç:** Performans düşüşünü uyku/stres/yorgunlukla birlikte
görmek; Samet'in diz/dirsek takibi (US-04).

**En küçük yararlı sürüm:**
- **Seans sonu tek soru** (özet ekranında): "Nasıl hissettin?" 1–5 → mevcut
  `workout_sessions.energy` kolonuna. Yeni tablo yok → senkron v2'yi
  beklemez.
- **Günlük kart** (isteğe bağlı, Ana Sayfa'da sabahtan öğlene kadar,
  kapatılabilir), 10 saniyede. Önerilen alanlar — spor biliminde yaygın kısa
  sabah anketlerinin (ör. Hooper indeksi: uyku, yorgunluk, stres, kas ağrısı)
  sadeleştirilmiş hali:
  - **Uyku süresi** (saat, yarım saat adımlı)
  - **Uyku kalitesi** (1–5)
  - **Enerji** (1–5)
  - **Stres** (1–5)
  - **Kas ağrısı / yorgunluk** (1–5)
  - *(Ayarla açılır)* **Eklem ağrısı** — diz / dirsek (0–10), PRD US-04
  - *(İsteğe bağlı)* kısa not
- **Seans sonu:** "Antrenman nasıldı?" — seans RPE'si (1–10); mevcut
  `workout_sessions.rpe` kolonu.
- Gösterim: haftalık değerlendirmede "iyi uyuduğun günlerde ortalama e1RM …"
  gibi **birlikte görülen** bilgiler; "neden" ya da tıbbi yorum yok, küçük
  veri uyarısı her zaman.

**Efor:** seans sonu sorusu S · günlük kart M.

**Bağımlılıklar:** günlük kart yeni tablo (`daily_checkins`) → docs/20
Aşama 5. Gün başına tek satır olacağı için sunucuda `(user_id, date)`
tekilliği gerekir → docs/20'deki su tartışmasıyla aynı sorun; olay kaydı
yerine "günün son değeri kazanır" kuralı yeterli (tek kullanıcı, alanlar
bağımsız değil).

**Risk:** Sağlık verisi; gizlilik politikası metni bunu kapsamalı.

---

### #8 — Beslenme kaydının tamamlandığını belirtme

**Mevcut durum: yok.**
- Beslenme yalnız kayıtları topluyor; "gün tamam" kavramı yok.
- Haftalık protein uyumu kayıt girilen tüm günleri eşit sayıyor
  (`dashboard_stats.dart:76-78`) → yarım girilmiş gün uyumu düşük gösterir.

**Çözdüğü ihtiyaç:** Eksik kayıt ile gerçekten düşük tüketimi ayırmak;
haftalık değerlendirme ve ileride hedef gözden geçirme buna dayanır.

**En küçük yararlı sürüm:**
- Beslenme ekranının altında **"Bugünkü kaydım tamamlandı"** düğmesi;
  tamamlanan günde küçük ✓ rozeti (takvimde de).
- **Düzenleme kuralı:** tamamlanmış güne kayıt eklenir/silinirse durum
  **korunur** (kullanıcı unuttuğunu ekliyor), yalnız "tamamlandı, sonra
  değişti" diye işaretlenir; kullanıcı istediğinde kaldırır.
- **Geçmiş günler:** geçmiş bir günü sonradan tamamlandı işaretlemek
  serbest; hiç işaretlenmemiş eski günler **bilinmiyor** sayılır, "eksik"
  değil.
- **Hesaplarda:** haftalık değerlendirme önce tamamlanmış günleri kullanır;
  tamamlanmış gün yoksa bugünkü davranışa döner ve bunu yazar.

**Efor:** S–M.

**Bağımlılıklar:** yeni senkron verisi (gün başına durum) → docs/20
Aşama 5 + gün tekilliği kuralı (#7 ile aynı).

---

### #9 — Ana ekran widget'ı

**Mevcut durum: yok.** Widget paketi ya da yerel (native) kod yok.

**Çözdüğü ihtiyaç:** Uygulamayı açmadan su ekleme ve günün durumunu görme
(docs/17 §2 #6: en ucuz günlük dönüş tetikleyicisi).

**Kapsam değerlendirmesi:**

| Konu | Android | iOS |
|---|---|---|
| Teknoloji | App Widget (Glance ya da RemoteViews) | WidgetKit (SwiftUI) + App Group |
| Uygulamayı açmadan eylem (su ekle) | Yayın alıcısı / arka plan Dart çağrısı | iOS 17+ App Intents; Dart'ı arka planda çalıştırmak kısıtlı → paylaşılan küçük kuyruk, uygulama açılınca veritabanına işlenir |
| Veri güncelliği | Uygulama yazınca widget'ı tazele; sistem en sık ~30 dk | Zaman çizelgesi; sistem bütçesi sınırlı |

**En küçük yararlı sürüm:** **salt okunur** widget (önce Android): bugünün
antrenmanı, kalan kalori, su durumu; dokununca ilgili ekran açılır. Su ekleme
ikinci adım.

**Efor:** Android salt okunur M · su ekleme +M · iOS L.

**Bağımlılıklar:**
- **Hesap izolasyonu:** widget verisi paylaşılan depoda (SharedPreferences /
  App Group) durur → çıkış ve hesap değişiminde **temizlenmeli**
  (`wipeLocalUserData`'ya eklenir). Kilit ekranında görünen kalori/kilo
  gizlilik tercihine bağlanmalı.
- Su ekleme widget'tan yapılırsa docs/20'deki su olay kaydı modeli (her ekleme
  ayrı satır) işi kolaylaştırır.

---

### #10 — Kişisel veriye dayalı asistan

**Mevcut durum: yok.** Yapay zekâ altyapısı yok (PRD F-20 planlı). Soruların
cevaplanabileceği hesaplar kısmen var (e1RM geçmişi, haftalık istatistik,
seri, kilo trendi).

**Çözdüğü ihtiyaç:** "Son bir ayda hangi hareketlerde ilerledim?", "Bu hafta
planıma ne kadar uydum?" — ekranlar arasında gezmeden cevap.

**En küçük yararlı sürüm (yapay zekâsız):** **Hazır sorular** ekranı.
- 6–8 soru kartı (ör. "Son 4 haftada en çok gelişen hareketler", "Bu hafta
  plana uyum", "Protein hedefini tuttuğum günler", "Kas grubu dengesi").
- Her cevap: sonuç cümlesi + **kullanılan tarih aralığı ve kayıt sayısı** +
  ilgili ekrana bağlantı. Veri yetersizse "yeterli kayıt yok (en az N
  gerekli)".
- Cevaplar #1 ve #6'nın hesap motorundan (A1) gelir — aynı sayı iki yerde
  farklı çıkmaz.

**Sonraki sürüm (yapay zekâ):** serbest soru → yapay zekâ **yalnız soruyu
hazır sorgulardan birine eşler** ve cevabı hesaplanan veriden yazar
(uydurma riski düşük). Tam sohbet ayrı karar.

**Samet'in fikri — uygun maliyetli bir yapay zekâ API'sini gömmek — için
mimari öneri:**
- **API anahtarı uygulamanın içine konmaz.** Uygulama dosyasından anahtar
  çıkarılabilir; biri ele geçirirse fatura Samet'e gelir. Doğru kalıp:
  uygulama → **Supabase Edge Function** (Supabase'in sunucu tarafı küçük
  fonksiyonu; anahtar orada gizli durur, kullanıcının oturumunu doğrular,
  kullanıcı başına günlük/aylık kota uygular) → yapay zekâ sağlayıcısı.
- **Veri azaltma:** ham kayıtlar değil, A1 motorunun hesapladığı özet
  sayılar gönderilir; isim/e-posta gitmez.
- **Maliyet kontrolü:** haftalık özet kullanıcı başına haftada bir kez
  üretilir ve saklanır (her açılışta değil); acil olmayan haftalık özetler
  toplu (batch) istekle gönderilir (Anthropic'te toplu istek %50 ucuz);
  sabit sistem metni önbelleğe alınır; aylık üst sınır aşılırsa kural tabanlı
  metne dönülür.
- **Sağlayıcı değiştirilebilir katman** (PRD F-20): model/sağlayıcı bir
  ayardır; seçim gerçek haftalık özetlerle karşılaştırmalı denenerek yapılır.
- **Kaba maliyet (Anthropic API liste fiyatlarıyla, 2026-09):** bir haftalık
  özet ≈ 3.000 girdi + 500 çıktı token (token ≈ kelime parçası). Claude
  Haiku 4.5 ($1 / $5, milyon token başına) ile ≈ **0,006 $/özet**; Claude
  Sonnet 5 ($2 / $10) ile ≈ 0,011 $; Claude Opus 5 ($5 / $25) ile ≈ 0,028 $.
  Kullanıcı başına ayda 4 özet + 10 soru ≈ Haiku ile 0,1 $ altı. Diğer
  sağlayıcıların fiyatları karar anında güncel sayfalarından karşılaştırılmalı.

**Efor:** hazır sorular M · yapay zekâ eşleme L (+ sağlayıcı katmanı,
maliyet, gizlilik metni).

**Bağımlılıklar:** A1, A2, A3. Yapay zekâ aşamasında kişisel verinin dış
servise gitmesi → açık kullanıcı onayı + gizlilik politikası.

---

### #11 — Hareket arama v2 (Samet'in bildirimi, 2026-09-17) — ✅ uygulandı (2026-09-17)

> "Egzersiz oluştururken hareket aramak çok zor, istediğimi bulamıyorum."

**Mevcut durum (ölçüldü — uygulamanın arama kuralı gerçek katalogda
yeniden çalıştırıldı):**
- Arama, adın **ve** kas/ekipman/kategori terimlerinin (Türkçe karşılıkları
  dahil) birleştirildiği metinde **kelime parçası** arıyor
  (`workout_ui.dart:216-254`); sıralama **yok** — sonuçlar kategoriye göre
  gruplanıp alfabetik diziliyor (`exercise_library_screen.dart:340-360`).
- **Parça eşleşmesi gürültü üretiyor:** "lat" → **485 sonuç** ("plate",
  "lateral", "alternating" içinde de geçiyor); "Wide-Grip Lat Pulldown"
  **161. sırada**.
- **Kas terimleri listeyi boğuyor:** "kol" → **457**, "omuz" → **346** sonuç
  (ikincil kas olarak omuz çalıştıran her hareket dahil).
- **Türkçe hareket adı yok:** "şınav", "barfiks", "mekik", "yan açış",
  "ölü kaldırma" → **0 sonuç**. Hareket adları yalnız İngilizce; Türkçe
  karşılık yalnız kas/ekipman için var.
- **Yazım farkları:** "pullup" → "Pull Ups"/"Pull-Up" varyantlarını
  bulmuyor; "pushup" → "Push-Up"u bulmuyor (tire/boşluk/çoğul).
- **Temel hareket gömülü:** "squat" → "Barbell Squat" 5., "curl" → "Barbell
  Curl" 6. sırada; 12+ bench press ve 8 lat pulldown varyantı yan yana.
- **Kişisel geçmiş kullanılmıyor:** en sık yaptığın hareketler öne çıkmıyor.

**Katalog kimliği düzeltmesi (docs/20 Aşama 6) bunu çözmez** — kimlik
kullanıcıya görünmez, eşitleme içindir. Arama ayrı bir iş; ama aynı veriye
dokunduğu için ortak bir parça var: Türkçe ad/eş anlamlı listesi hareket
**ismine** bağlanır, katalog kimliği de isimden hesaplanacağı için ikisi
aynı anahtarı kullanır.

**Çözdüğü ihtiyaç:** rutin kurarken ve seansa hareket eklerken aradığını
ilk ekranda bulmak — "hızlı veri girişi" önceliğinin tam merkezi.

**En küçük yararlı sürüm:**
1. **Alaka sıralaması** (saf fonksiyon + testler): adın kelime başında tam
   eşleşme > Türkçe ad/eş anlamlı eşleşmesi > birincil kas > ikincil kas /
   ekipman. Kısa ve temel ad (ör. "Barbell Squat") uzun varyanttan önce.
   Arama varken kategori gruplaması kalkar, düz sıralı liste gelir.
2. **Kelime başı eşleşme:** "lat" yalnız "lat" ile başlayan kelimelere
   uyar ("Lat Pulldown" evet, "plate" hayır).
3. **Yazım sadeleştirme:** tire/boşluk/çoğul eki farkı yok sayılır
   ("pull-up" = "pullup" = "pull ups").
4. **Türkçe ad ve eş anlamlılar:** en yaygın ~150 hareket için
   `assets/data/exercise_aliases_tr.json` (şınav, barfiks, mekik, göğüs
   pres, yan açış, ölü kaldırma, çömelme, hamle, kürek çekme, lat çekiş,
   pazı bükme, triceps itiş…). Listeyi Claude taslak olarak hazırlar, Samet
   gözden geçirir. (814 hareketin Türkçe *talimatı* ayrı ve hâlâ açık karar.)
5. **Kişisel öncelik:** arama boşken seçim ekranının üstünde "Son
   kullandıkların"; aramada son 90 günde yapılan hareketler öne çıkar.
6. **Test altın listesi:** 30 gerçek arama → beklenen ilk 3 sonuç; her
   değişiklikte çalışır ("lat" → Lat Pulldown ilk 3'te; "şınav" → Pushups
   ilk 3'te; …).

**Sonraki sürüm:** küçük yazım hatası toleransı ("benc", "dedlift"),
varyantları tek başlık altında toplama ("Bench Press ▸ 12 varyant"),
"yalnız temel hareketler" süzgeci.

**Efor:** M (sıralama + eşleşme S–M, eş anlamlı listesi S–M, arayüz S).

**Bağımlılıklar:** yok — yalnız cihazda, yeni senkron verisi yok. Senkron
v2'yi beklemez.

**Önerilen yer:** sıranın **başı**, #3 ile aynı paket ("hızlı antrenman
girişi") — ikisi de rutin/seans akışında ve Samet'in doğrudan şikâyeti.

---

### #12 — Takviye kaydı (PRD F-08) — Samet: isteniyor

**Mevcut durum:** yok. Whey gibi besin sayılanlar bugün Yemek olarak
girilebiliyor.
**İhtiyaç:** "Bugün kreatinimi aldım mı?" — düzenli takviyeleri unutmamak.
**En küçük yararlı sürüm:** Profil'de takviye listesi (ad, miktar, saat);
Ana Sayfa'da günlük işaret listesi; isteğe bağlı günlük hatırlatma (mevcut
bildirim altyapısı). Makrosu olan takviye (whey) Beslenme'ye yönlendirilir.
**Efor:** M. **Bağımlılık:** iki yeni senkron tablosu → docs/20 Aşama 5.

### #13 — Rozetler (PRD F-14) — Samet: isteniyor

**Mevcut durum:** `achievements` tablosu şemada, **hiç kullanılmıyor**;
docs/17 "canlandır ya da bırak" kararını bekliyordu.
**İhtiyaç:** uzun vadeli motivasyon — sosyal yarış olmadan, kendi
kilometre taşların.
**En küçük yararlı sürüm:** 15–20 rozet, **mevcut veriden hesaplanır**
(ilk antrenman, 10/50/100 antrenman, 4/12 hafta seri, harekette yeni rekor,
30 gün beslenme kaydı…); kazanma anında küçük kutlama (PR kupası gibi);
Profil'de rozet vitrini. Rozetler hesaplandığı için saklanmaları gerekmez →
senkron v2'yi beklemez (yalnız "görüldü" bilgisi cihazda).
**Efor:** M. **Bağımlılık:** A1 hesap motoru.

---

### Sonraki aşamalar

**Hedefleri gözden geçirme (uyarlanabilir hedef).**
Düzenli kilo + tamamlanmış beslenme günlerinden gerçek bakım kalorisini
tahmin edip hedefi önermek (MacroFactor benzeri).
- **Ön koşul:** #8 (tamamlanmış günler) — yoksa eksik kayıt "az yiyor"
  sanılır ve öneri yanlış çıkar; hafta ortalamalı kilo trendi (#1); en az 2–3
  hafta veri.
- Bugün profilde hedef kilo **80 kg** ama kalori hedefi **3100 > günlük
  harcama ~2891** (kilo alma yönü) — çelişkili. Açık bir "hedef yönü" alanı
  (ver / koru / al) bu özelliğin temeli olmalı (§6 Soru 3).
- Öneri her zaman **öneri**: hedef kullanıcı onayıyla değişir.

**Fotoğraftan veya doğal dille öğün ekleme.**
- Doğal dil ("2 yumurta, 1 dilim peynir"): mevcut besin veritabanı + yapay
  zekâ ayrıştırma → **düzenlenebilir onay listesi** (#2'nin küçük sürümündeki
  liste aynen kullanılabilir) → onaysız kayıt yok.
- Fotoğraf: yemek fotoğrafı dış yapay zekâ servisine gider → ayrı gizlilik
  onayı; ilerleme fotoğraflarıyla aynı depolama/izin altyapısı kullanılmaz
  (yemek fotoğrafı saklanmaz).
- **Ön koşul:** yapay zekâ sağlayıcı katmanı (PRD F-20), maliyet sınırı, #2
  onay listesi.

---

## 3. Ortak altyapı

| Kod | Altyapı | Kullanan özellikler | Not |
|---|---|---|---|
| **A1** | **Hesap motoru** — hafta/ay pencereleri (`[start, end)` kuralı), plana uyum, e1RM eğilimi, kas grubu set sayımı, kilo hafta ortalaması | #1, #6, #10, hedef gözden geçirme | Saf Dart, DB'siz testler; mevcut `dashboard_stats.dart` buraya taşınır/genişler. Aynı sayının her ekranda aynı çıkmasını garanti eder. |
| **A2** | **Kas eşlemesi** — ham kas adlarını 6–8 sade gruba indirger; birincil/ikincil ağırlık | #1, #6, #10 | `muscle_groups` doluluk ölçümü ilk adım. |
| **A3** | **"Nereden hesaplandı" bileşeni** — tarih aralığı, kayıt sayısı, kural adı | #1, #3, #10 | Güven için şart. |
| **A4** | **Senkron v2** (docs/20) | #2 tam, #5, #7, #8, #4 dilim 2 | Özellikle Aşama 5 (silme protokolü). |
| **A5** | **Haftalık zamanlama** — bildirim servisine haftalık tekrar | #1, #5 | `matchDateTimeComponents.dayOfWeekAndTime`; küçük iş. |
| **A6** | **Paylaşılan depo + yerel widget kodu** | #9 | Hesap değişiminde temizlik. |
| **A7** | **Yapay zekâ sağlayıcı katmanı** (PRD F-20) | #10 sonrası, doğal dil/fotoğraf öğün | Maliyet, gizlilik onayı, çevrimdışı geri dönüş. |
| **A8** | **Fotoğraf depolama servisi** (docs/19 `PhotoStorage`) | #4 | Yemek fotoğrafı için kullanılmaz. |
| **A9** | **Düzenlenebilir onay listesi** — eklenecek besinlerin miktarını değiştirme | #2, doğal dil öğün | Bir kez yazılır. |

---

## 4. Önerilen geliştirme sırası ve gerekçesi

Senkron v2 (docs/20) ile özellik işleri **paralel iki şeritte** yürüyebilir;
şerit B'deki özellikler şerit A'nın ilgili aşamasını bekler.

```
Şerit A (veri bütünlüğü)   docs/20 Aşama 0-2 ──► Aşama 3-4 ──► Aşama 5 ──► 6-7
Şerit B (özellik)          #3 hedef ──► #1 haftalık(+#6) ──► #4 foto ──► #2 kopyala
                                                                  │
                           (Aşama 5 bittikten sonra) ──► #8 ──► #5 ──► #7 ──► #2 tam
                           (bağımsız, sonra)          ──► #10 hazır sorular ──► #9 widget
```

**Gerekçeler:**

1. **#3 önce** — her antrenmanda kullanılan ekran, Samet'in son geri
   bildirimlerinin odağı; G-2 kodunu yeniden kullanır; yeni tablo yok, senkron
   riski yok; "hızlı veri girişi" ve "anlaşılır gelişim" önceliklerinin
   ikisine birden hizmet eder.
2. **#1 (+#6 çekirdeği) ikinci** — vizyonun "yorumlayan asistan" tarafının
   ilk görünür adımı; A1/A2 motorunu kurar, #10'un temelini atar.
   Türetilmiş veri → senkron v2'yi beklemez.
3. **#4 üçüncü** — PRD P0 ve başarı kriteri; tasarım hazır; yalnız cihazda
   olduğu için senkron riskini taşımaz (muafiyet kuralı önce gelir).
4. **#2 küçük sürüm dördüncü** — beslenme girişini hızlandırır, yeni tablo yok.
5. **Aşama 5 sonrası: #8 → #5 → #7 → #2 tam** — hepsi yeni, silinebilir
   senkron verisi üretir. #8 önce, çünkü #1'in beslenme bölümünü ve ileride
   hedef gözden geçirmeyi güvenilir yapar.
6. **#10 hazır sorular** — #1/#6 motoru olgunlaşınca ucuzlar.
7. **#9 widget en son** — iki platformda yerel kod, en yüksek bakım yükü; ilk
   sürüm Android salt okunur.

**Toplam kaba efor:** şerit B'nin ilk dört adımı ≈ 8–11 gün; Aşama 5 sonrası
dört özellik ≈ 9–13 gün; #10 + #9 ≈ 6–9 gün. (docs/20 ≈ 9 gün ayrıca.)

---

## 5. İlk üç özellik — kullanıcı akışı ve kabul kriterleri

### 5.1 #3 — Antrenmanda bir sonraki hedef

**Akış:**
1. Samet "Push day"i başlatır.
2. Bench Press kartının başlığının altında tek satır + düğme:
   *"Geçen sefer 3 sette 12'ye ulaştın (60 kg). Hazırsan +1,25 kg dene."*
   **[Artır]**
3. Set satırlarındaki soluk öneri hâlâ geçen seferki değer (60 / 12);
   "ÖNCEKİ" sütunu da 60×12.
4. Samet **[Artır]**'a basar → bu seansın önerileri 61,25 / 8 olur; düğme
   "Geri al" olur.
5. İlk seti yapar, ✓'e basar → set 61,25×8 ile dolar ve tamamlanır.
6. 8 yerine 6 yaptıysa tekrar alanına 6 yazıp ✓'e basar; sonraki setin önerisi
   bugünkü değeri (61,25×6) taşır (G-2 kuralı).
7. Gerekçe satırına dokununca kısa açıklama: çift ilerleme kuralı, tekrar
   aralığı 8–12, artış 1,25 kg (Ayarlar'dan değişir).

**Kabul kriterleri:**
- [ ] Geçen seferki tüm çalışma setleri üst sınıra ulaştıysa öneri = kilo +
      artış, tekrar = alt sınır; ulaşmadıysa aynı kilo, tekrar +1 (üst sınırı
      aşmadan); alt sınırın altındaysa aynı hedef. (Saf fonksiyon, birim
      testleri; ısınma setleri hesaba katılmaz.)
- [ ] Kilo artışı **yalnız [Artır]'a basınca** uygulanır; basılmazsa öneriler
      geçen seferki değerde kalır. [Artır] tekrar basınca geri alınır.
- [ ] Varsayılan artış 1,25 kg; Ayarlar'dan değiştirilir ve kalıcıdır.
- [ ] Öneri rutindeki hedefleri **değiştirmez** (DB'de rutin satırı aynı).
- [ ] Öneri set **tamamlanmış sayılmaz**; ✓ olmadan kayda "yapıldı" diye
      geçmez (G-2 kuralı korunur).
- [ ] Her önerinin görünür gerekçesi var; gerekçede geçen seansın tarihi ve
      değerleri yazıyor.
- [ ] Rutinsiz antrenmanda, geçmişi olmayan harekette, süre/mesafe
      hareketinde hedef satırı gösterilmez.
- [ ] Imperial birimde varsayılan artış 2,5 lb; gösterim lb'ye yuvarlanır.
- [ ] `flutter analyze` 0, testler yeşil, cihazda bir seans turu (kayıt
      yapılmadan).

### 5.2 #1 — Haftalık değerlendirme (+ #6 çekirdeği)

**Akış:**
1. Hafta bitince (Samet'in hafta başlangıcı Pazartesi) Ana Sayfa'nın
   üstünde "Geçen haftanın özeti" kartı: tek cümle + "Aç".
2. Özet ekranı dört bölüm: Devamlılık · Performans · Beslenme · Kilo; her
   birinde sayı + tek cümle + "nereden?" bağlantısı.
3. "Kas grupları" bölümü: sade gruplar, bu haftaki çalışma seti ve son 4
   hafta ortalaması; "nasıl sayıldı" açıklaması.
4. En altta **"Önümüzdeki haftanın odağı"**: tek öneri + gerekçesi.
5. Kart kapatılabilir; ekran İlerleme sekmesinden geçmiş haftalar için de
   açılabilir.

**Kabul kriterleri:**
- [ ] Tüm sayılar A1 motorundan gelir ve Ana Sayfa "Bu Hafta" ızgarasıyla
      aynı haftada **aynı** değeri verir (test).
- [ ] Hafta sınırları kullanıcının hafta başlangıç tercihine ve `[start, end)`
      kuralına uyar (gece yarısı kaydı iki haftaya sayılmaz).
- [ ] Performans bölümü yalnız en az 2 seans verisi olan hareketleri
      değerlendirir; yetersizse "yeterli veri yok" der.
- [ ] Beslenme bölümü kayıtlı gün sayısını (X/7) her zaman gösterir; 4 günden
      az kayıtta uyum yorumu yapılmaz.
- [ ] Kilo yorumu tek ölçüme değil hafta ortalamasına dayanır; yön hedef
      kiloya göre yorumlanır; hedef yoksa nötr.
- [ ] Kas grubu sayımı: ısınma hariç, tamamlanmış setler; birincil 1, ikincil
      0,5; açıklama metni ekranda.
- [ ] "Sonraki odak" tek bir kuraldan gelir, gerekçesi ve kullandığı sayılar
      görünür; hiçbir kural tetiklenmezse "Böyle devam" der.
- [ ] Hiç veri olmayan haftada kart gösterilmez.
- [ ] EN/TR metinler, `flutter analyze` 0, testler, cihazda görsel tur.

### 5.3 #4 — İlerleme fotoğrafları (docs/19 dilim 1 + ölçü bağlantısı)

**Akış:**
1. İlerleme sekmesinde "Fotoğraflar" kartı → galeri (tarihe göre gruplu,
   açı süzgeci: ön / yan / arka).
2. "Fotoğraf ekle" → kamera ya da galeri → açı seç → tarih (varsayılan bugün)
   → kaydet. Fotoğraf küçültülüp uygulama klasörüne yazılır.
3. Galeride iki fotoğraf seçip "Karşılaştır" → yan yana; altlarında tarih ve
   o tarihe en yakın (±3 gün) kilo/bel ölçüsü.
4. Fotoğrafa uzun basınca "Sil" → onay → satır ve dosya birlikte silinir.

**Kabul kriterleri:**
- [ ] docs/19 §7 "bitti" listesinin tamamı.
- [ ] Fotoğraf satırı sunucuya **gitmez** (muafiyet testi); hesap değişiminde
      satırlar **ve dosyalar** silinir (test).
- [ ] `image_path` yalnız dosya adı; uygulama güncellemesinden sonra
      fotoğraflar açılır (iOS turu).
- [ ] Fotoğraf cihaz galerisine yazılmaz; ağ çağrısı yoktur.
- [ ] Kayıtlı fotoğraf ≤ 1440 px ve ~400 KB altında.
- [ ] Karşılaştırmada ölçü yoksa "ölçüm yok" yazar, uydurma değer göstermez.
- [ ] Silmeden sonra diskte dosya kalmaz; açılışta yetim dosyalar süpürülür.
- [ ] Kamera/galeri izni reddedilirse anlaşılır mesaj, uygulama çökmez.

---

## 6. Kararlar ve açık sorular

**Kararlar (Samet, 2026-09-17):**

| # | Konu | Karar |
|---|---|---|
| 1 | Geliştirme sırası (§0) | ✅ Onaylandı |
| 2 | İlerleme kuralı (#3) | ✅ Çift ilerleme; varsayılan artış **1,25 kg**; artış **otomatik değil**, kullanıcı [Artır] ile uygular |
| 3 | Hedef yönü | ✅ Profile "hedef: kilo ver / koru / al" alanı eklenecek (haftalık değerlendirmenin kilo yorumu ve hedef gözden geçirme buna dayanacak; şema değişikliği → docs/20 kurallarıyla) |
| 4 | Haftalık değerlendirme bildirimi (#1) | ✅ Evet (varsayılan Pazar 20:00, ayarlanabilir) |
| 5 | Supabase ücretli plan | ✅ Şimdi değil (docs/20 §13) |
| 6 | Katalog kimliği | ✅ Şimdi (docs/20 Aşama 6) |

| 7 | Günlük durum alanları (#7) | ✅ Uyku süresi + kalitesi, enerji, stres, kas ağrısı; ayarla diz/dirsek ağrısı; isteğe bağlı not; seans sonu RPE |
| 8 | Beslenme günü tamamlandı (#8) | ✅ İşaret sonradan kayıt eklenince korunur; akşam isteğe bağlı hatırlatma; işaretsiz günler "bilinmiyor" |
| 9 | İlerleme fotoğrafları (#4) | ✅ İlk sürüm yalnız cihazda |
| 10 | Asistan (#10) | ✅ Önce hazır sorular; yapay zekâ aşamasında Edge Function + özet veri; özet verinin dış servise gitmesine izin var |
| 11 | Widget (#9) | ✅ Önce Android, salt okunur. Varsayılan: kilit ekranında sayı gösterilmez (gizlilik) |
| 12 | Takviye kaydı ve rozetler | ✅ İsteniyor → §2 #12, #13 |
| 13 | Hareket arama v2'nin yeri | ✅ Sıranın başı, #3 ile aynı paket (uygulandı 2026-09-17) |
