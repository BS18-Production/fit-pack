# 27 — Hevy İncelemesi (rakip analizi)

> **Amaç:** Hevy'nin antrenman deneyimini gezip Fit Pack'e neyi alacağımızı
> karara bağlamak. Başlangıç soruları: **ısınma**, **kardiyo** (2026-10-04),
> **hazır rutinler** ve **RPE** (Samet'in istekleri).
> **Ortam:** Android emülatörü (AVD `FitPack`), Hevy Play Store sürümü,
> Samet'in hesabı (samor77). İnceleme sırasında hiçbir antrenman/rutin
> kaydedilmedi (deneme seansı ve rutin "Discard" ile atıldı).
> **Durum:** Antrenman sekmesi tarandı (2026-10-04). Karar özeti taslak —
> Samet'in onayı bekleniyor.

## Karar özeti (taslak)

| # | Fikir | Öneri | Etki |
|---|---|---|---|
| F1 | Hazır program kataloğu (seviye × bölünme × ekipman) | **Al** → [docs/28](28-program-catalog-set-plan.md) | Büyük — içerik + şema |
| F2 | Rutin içinde set bazlı plan (W ısınma setleri, set başına hedef) | **Al** → [docs/28](28-program-catalog-set-plan.md) | Orta — şema |
| F3 | Isınma = rutinin ilk hareketi (süreli "Isınma" + açıklama) | ✅ **Yapıldı (2026-10-04)** | Küçük |
| F4 | RPE seçici: 6–10 yarım adım, her değerde etiket + "kaç tekrar kaldı" | ✅ **Yapıldı (2026-10-04)** | Küçük — yalnız arayüz |
| F5 | RPE'yi işe yarar kılmak: bir sonraki seans önerisi | **Uyarla** → [docs/29](29-rpe-progression.md) | Orta — şema yok |
| F6 | "Isınma setleri istatistiğe dahil" ayarı | **Alma** — bizde ısınma hep hariç, doğru varsayılan | — |
| F7 | Kardiyo: KM + SÜRE (mm:ss) sütunlu sıradan hareket | Zaten var; **sade tut** | — |
| F8 | Rutin klasörleri | **Al**, F1 ile birlikte (program = klasör) | Küçük |
| F9 | Önceki değer kaynağı: "herhangi bir antrenman" / "aynı rutin" | Değerlendir | Küçük |
| F10 | Süperset | Değerlendir (bizde yok) | Orta |

## Ücretli / ücretsiz ayrımı — prensip (Samet, 2026-10-04)

**Karar:** Özelliklerin hepsi şimdi ücretsiz geliştirilir; hangilerinin
ücretli olacağına **ilk satıştan önce** karar verilir. Ayırmayı kolay tutmak
için:

1. **Tek kontrol noktası:** ücretli olabilecek her özellik tek bir
   fonksiyondan geçer (`featureEnabled(Feature.x)`), bugün hep "açık" döner.
   İlk "akıllı" özellikle (ör. F5) birlikte eklenir.
2. **Veri katmana bağlı değil:** tablolar/senkron kullanıcının ücretli olup
   olmadığını bilmez; ücretli olmak yalnız yeni şey yapmayı açar (docs/23 §4
   "abonelik bitince salt okunur" ile uyumlu).
3. **Kullanıcının kendi verisi asla kilitlenmez:** görme + dışa aktarma hep
   ücretsiz. Ücretli aday = **akıllı katman** (öneriler, hesaplayıcılar,
   ileri analiz).
4. Her yeni tasarım dokümanının karar özetinde bir satır:
   **"Katman: temel / akıllı (ücretli aday)"**.

| Temel (hep ücretsiz) | Akıllı (ücretli aday) |
|---|---|
| Antrenman kaydı, rutinler, set tipleri, RPE girişi (F4) | RPE'ye dayalı sonraki seans önerisi (F5) |
| Hazır programların bir kısmı (ör. başlangıç) | Tam katalog / program sihirbazı (F1) |
| Isınma hareketi, dinlenme sayacı (F3) | Isınma seti hesaplayıcısı |
| Temel geçmiş ve grafikler | e1RM, yorgunluk/deload analizi, ileri istatistik |
| Kendi verisini görme ve dışa aktarma | Bulut senkronu (docs/23 ile bağlantılı) |

Tablo taslaktır; karar satıştan önce verilir.

## Not formatı

Her madde: **Hevy ne yapıyor → Fit Pack'te bugün ne var → Öneri.**

## 1. Antrenman ana ekranı

- **Hevy:** Üstte "Start Empty Workout"; altında **Routines** başlığı:
  "New Routine" + "Explore" düğmeleri, klasör ekleme ikonu. Rutinler
  **klasörlerde** gruplanıyor (ör. kaydedilen program kendi klasörü, kişisel
  rutinler "My Routines"). Her rutin kartında hareket listesi özeti + büyük
  "Start Routine" düğmesi. Basılı tutup sürükleyerek sıralama.
- **Fit Pack:** Rutinler düz liste, `orderIndex` + haftanın günü
  (`scheduledWeekday`). Klasör/program kavramı yok.
- **Öneri:** Klasörü ayrı bir kavram olarak değil, **program** olarak ekle
  (F1). Kullanıcının kendi rutinleri "Rutinlerim" altında kalır.

## 2. Hazır programlar (Explore) — F1

- **Hevy:** **26 program**, filtre: **Seviye / Hedef / Ekipman**. Matris:
  - Seviye: Beginner · Intermediate · Advanced
  - Bölünme: Full-Body · Upper/Lower · Push/Pull/Legs (+ 5x5, Madcow 5x5,
    4-Day / 6-Day PHUL)
  - Ekipman: Gym · Dumbbells · Equipment-Free
  - Rutin sayısı seviyeyle artıyor (başlangıç 2–3, ileri 5–6).
- **Program detayı:** başlık, "Created by Hevy", kısa açıklama (ör. ileri
  full-body: "Menno Henselmans, Eric Helms, Jeff Nippard'dan esinlenildi;
  haftada 5 gün, her kas 3–5 kez"), etiketler (Advanced · Gym · Gain Muscle ·
  5 Routines), rutinler ve her hareketin **set sayısı + tekrar aralığı**
  (ör. Bench 6 set · 5–20, Row 4 set · 8–10). **"Save Program"** ile
  programın rutinleri kullanıcının hesabına kopyalanıyor; sonra düzenlenebilir.
- **Ayrıca:** "Routines" bölümünde ortama göre tekil rutinler: At home,
  Travel, Dumbbells Only, Band, Cardio & HIIT, Gym, Bodyweight, Suspension
  Band.
- **Fit Pack:** Hazır rutin yok; seed yalnız hareket kütüphanesi.
- **Öneri (Samet'in isteğiyle aynı):**
  - Katalog uygulamayla gelen **salt okunur içerik** olsun (seed), kullanıcı
    "Programı ekle" deyince rutinler **kopyalanıp** kendi rutinleri olur.
    Böylece kullanıcı değiştirince katalog bozulmaz, katalog güncellenince
    kullanıcının rutini değişmez.
  - Başlangıç kapsamı küçük tut: 3 seviye × 3 bölünme × 1–2 ekipman
    (Salon + Dambıl) ≈ 9–12 program. Türkçe açıklama.
  - Kopyalanan rutin senkronlanır (normal rutin); katalog senkronlanmaz.
  - **Açık soru:** program içeriğini kim yazar? Yayımlanmış, bilinen
    programlardan (5x5, PHUL, PPL) uyarlamak hızlı; telif açısından program
    yapısı (set/tekrar şeması) serbest, metinleri kendimiz yazarız.

## 3. Rutin detayı ve rutin oluşturma — F2, F3, F8

- **Hevy rutin detayı:** her hareket için açıklama metni (form ipucu +
  alternatif), **hareket başına dinlenme süresi** (Squat 2 dk 30 sn, Incline
  DB 2 dk), set tablosu `SET · KG · REP RANGE`. Set satırları **tek tek**
  tanımlı: Squat → **W 10–15, W 5–10**, sonra 1–4: 6–10.
- **Rutin oluşturma:** başlık, hareket ekle, hareket notu, dinlenme sayacı,
  set satırları; REPS başlığından **"Reps" / "Rep Range"** seçimi.
- **Fit Pack:** Rutin hareketi `targetSets` + `targetRepsMin/Max` +
  `targetRestSec` + not. Yani dinlenme ve tekrar aralığı **var**; ama setler
  tek tek değil, ısınma seti planlanamıyor.
- **Öneri F2:** Rutin hareketine **set planı** ekle (set tipi + hedef tekrar
  aralığı + isteğe bağlı hedef kg). En azından "kaç ısınma seti" alanı.
  Şema değişikliği → tasarım dokümanı.
- **Öneri F3 (ısınma kararını değiştiriyor):** Hevy genel ısınmayı ayrı bir
  aşama yapmamış; **rutinin ilk hareketi "Warm Up"**: süreli, tek set
  **05:00**, açıklama "bacak sallama, kol çevirme, jumping jack, yüksek diz
  gibi dinamik hareketlerle tüm vücut ısınması". Bizde kütüphanede zaten
  "Dynamic Warm-Up" (süreli) var. Önceki "sayaçlı ısınma kartı" fikri yerine:
  - Hazır programların hepsi "Isınma · 5:00" ile başlasın.
  - Süreli harekette **geri sayım sayacı** olsun (bugün süre `dk:sn`
    olarak elle giriliyor — `_TimeCell`).
  - İsteğe bağlı: yeni rutin oluştururken "Başa ısınma ekle" kutusu.
  Bu yol şema istemiyor, kardiyo sayacıyla aynı bileşeni paylaşır.
- **F3 yapıldı (2026-10-04):**
  - Rutin oluşturucuda **"Isınma ekle"** kısayolu: hazır "Dynamic Warm-Up"
    hareketini 1 set, dinlenmesiz olarak başa koyar; rutinde ısınma varken
    görünmez.
  - Süreli/mesafeli harekette tekrar aralığı gizli ve kaydedilmiyor
    (`targetRepsMin/Max` boş); önizleme "1 set" yazıyor.
  - Canlı seansta süreli setlerde **sayaç** (`set_timer.dart`): hedef süre
    varsa (girilen ya da geçen seansın değeri) geri sayar, sıfırda titreşip
    süreyi yazar; yoksa ileri sayar, durdurunca geçen süreyi yazar. Seti
    tamamlamaz. Süre saat farkından hesaplanır (arka planda da doğru).
  - İlk seferde hedef olmadığı için ileri sayar; ikinci seferden itibaren
    geçen seansın süresinden (ör. 5:00) geri sayar.
  - **Rutinde hedef süre** (ör. "Isınma 5:00") şema ister → F2 dokümanına.

## 4. Canlı antrenman ekranı

- **Hevy üst çubuk:** açılır ok (küçültme), "Log Workout", dinlenme sayacı
  ikonu, **Finish**. Altında canlı **Duration · Volume · Sets** + kas
  haritası (çalışılan kaslar renkleniyor).
- **Hareket kartı:** görsel + ad, "Add notes here…", "Rest Timer: OFF"
  (hareket bazında), tablo `SET · PREVIOUS · KG · REPS · RPE · ✓`, "+ Add Set".
- **Kardiyo (Treadmill):** tablo `SET · PREVIOUS · KM · TIME(mm:ss) · ✓`.
  Hız/eğim/nabız **yok** — sade.
- **Hareket menüsü (⋮):** Reorder · Replace · **Add To Superset** · Remove.
- **Set tipi (set numarasına dokun):** W Warm Up · 1 Normal · F Failure ·
  D Drop · Remove; her birinde "?" açıklaması.
- **Alt:** Add Exercise · Settings · Discard Workout (onay diyaloğu).
- **Fit Pack:** Set tablosu, set tipleri (I/D/F), dinlenme sayacı, önceki
  değerler, makine notu zaten var — bu ekranda Hevy'ye denk.
- **Öneri:** Fark yaratan iki şey: canlı **hacim/set özeti** üstte (bizde
  var mı, kontrol) ve **kas haritası** (görsel; düşük öncelik). Süperset
  (F10) ayrı karar.

## 5. RPE — F4, F5

- **Hevy:** Ayarlardan "RPE Tracking" açılınca sütun çıkıyor. RPE hücresine
  dokununca alt panel: başlıkta "Set 1: 0kg x 0 reps", büyük sayı, **yalnız
  6–10 arası yarım adımlı düğme şeridi** (6 · 7 · 7.5 · 8 · 8.5 · 9 · 9.5 ·
  10) ve seçilen değere göre **etiket + açıklama**:
  - 6 → Moderate Effort — "4+ tekrar daha yapabilirdin"
  - 7 / 7.5 → Vigorous Effort
  - 8 → Very Hard Effort — "kesin 2 tekrar daha yapabilirdin"
  - 8.5 → Very Hard Effort · 9 / 9.5 → Extremely Hard Effort
  - 10 → Max Effort — "hiç tekrar kalmadı"
  Değer klavyeyle yazılmıyor; tek dokunuş + "Done".
- **Fit Pack:** RPE set başına sayı olarak **klavyeyle** giriliyor; başlığa
  dokununca açıklama paneli var (10/9/8/7/≤6). Veri yalnız **kalori
  tahmininde** (ortalama RPE → yoğunluk) kullanılıyor.
- **Öneri F4 (küçük, hemen yapılabilir):** Klavye yerine Hevy tarzı seçici:
  6–10 yarım adım, Türkçe etiket + "kaç tekrar kaldı" (RIR — Reps in Reserve,
  yedekte kalan tekrar) açıklaması. Şema değişmez (`rpe` zaten real).
- **F4 yapıldı (2026-10-04):** `rpe_scale.dart` (ölçek, efor bandı, kalan
  tekrar) + `rpe_picker_sheet.dart` (panel). Hücre klavye açmıyor; panelde
  Tamam / Temizle / dışarı dokununca vazgeç. Eski kayıttaki 6 altı değerler
  korunur ve "Hafif efor · 4+ tekrar" olarak gösterilir. 9 yeni test.
- **Öneri F5 (RPE'ye anlam vermek — Hevy'nin ücretsiz sürümünde yok):**
  **Not:** Fit Pack'te zaten çift ilerleme önerisi var (`progression.dart`:
  aralığın üstü → kilo artır, içi → +1 tekrar, altı → tekrar et). F5 sıfırdan
  değil, bu öneriye RPE'yi girdi olarak katmak.
  - **Sonraki seans önerisi:** son çalışma setleri tekrar aralığının üstünde
    ve RPE ≤ 7 ise "+2,5 kg dene"; RPE 10 / tekrar aralığın altındaysa
    "ağırlığı koru". Önceki-değer önerisine ("önceki" sütunu) bağlanır.
  - **e1RM (tahmini tek tekrar maksimumu):** RPE + tekrardan daha doğru
    güç tahmini; ilerleme grafiğine girdi.
  - **Yorgunluk sinyali:** haftalık ortalama RPE yükselirken performans
    düşüyorsa haftalık değerlendirmede "deload haftası" önerisi (bizde
    `isDeload` alanı zaten var).
  Hesap kuralı → tasarım dokümanı (CONVENTIONS §7b).

## 6. Antrenman ayarları

- Sounds · **Default Rest Timer** · **Previous Workout Values** (Any workout /
  Same Routine) · **Warm-up Calculator** (PRO) · **Warm-up Sets** ("ısınma
  setlerini toplam set, hacim ve rekorlara kat" anahtarı, geçmişe de etki
  eder) · Keep Awake · **Plate Calculator** (halter hareketlerinde plaka
  hesabı) · RPE Tracking · Smart Superset Scrolling.
- **Not:** Isınma seti hesaplayıcısı ücretli. Bizde ücretsiz olabilir —
  fark yaratır.
- **Fit Pack karşılığı:** ekran açık kalma var (`wakelock_plus`); plaka
  hesaplayıcı yok (aday — halter kullananlar için küçük ve faydalı);
  varsayılan dinlenme rutin hareketi bazında var.

## 7. Trainer (PRO)

- Tercihlere göre kişisel program: hedef, hedef kas, deneyim, bölünme,
  kardiyo tercihi, program çeşitliliği. Vaatler: **progressive overload**
  ("gelişince ağırlıklar artar"), trainer ipuçları, ilerleme raporu.
- **Öneri:** Şimdilik alma. F1 (sabit katalog) + F5 (RPE'ye dayalı öneri)
  bunun ücretsiz ve basit karşılığı; ileride katalogtan "seviye, gün sayısı,
  ekipman" sorularıyla program seçen bir sihirbaz eklenebilir.

## 8. Kardiyo

- Hevy kardiyoyu bilinçli olarak sade tutuyor (KM + SÜRE). Bizde de aynı
  yapı var; önceki konuşmadaki "sade kardiyo" kararıyla uyumlu.
- Haftalık kardiyo dakikası ve Apple Sağlık entegrasyonu ayrı başlıklar —
  Hevy'nin Home/Profile sekmeleri incelenince güncellenecek.

## Sonraki adım

- Samet karar özetindeki önerileri onaylar/düzeltir.
- İstenirse Home ve Profile sekmeleri (istatistik, ölçüler, takvim) de
  aynı formatta taranır.
