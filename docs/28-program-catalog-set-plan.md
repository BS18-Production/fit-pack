# 28 — Hazır Program Kataloğu + Rutinde Set Planı (docs/27 F1 + F2)

> **Durum:** Taslak — Samet'in kararları bekleniyor (aşağıda §Kararlar).
> **Katman:** Set planı = temel (hep ücretsiz). Katalog = başlangıç
> programları temel; tam katalog "akıllı" (ücretli aday) — docs/27 prensibi.
> **Kaynak:** Hevy incelemesi (docs/27 §2–§3).

## Karar özeti

**Ne değişecek, neden.** Bugün her kullanıcı rutinini sıfırdan kuruyor ve
rutinde her hareket için yalnız "3 set × 8–12" yazılabiliyor: ısınma setleri,
set başına farklı hedef ya da süreli hareket için hedef süre (ör. "Isınma
5:00") planlanamıyor. İki şey ekliyoruz:

1. **Set planı (F2):** rutin hareketine isteğe bağlı, set set plan:
   her satırda set tipi (ısınma/normal/drop/failure), hedef tekrar aralığı,
   isteğe bağlı hedef kilo ve hedef süre. Plan yoksa bugünkü "N set × a–b"
   davranışı aynen sürer.
2. **Hazır program kataloğu (F1):** uygulamayla gelen, salt okunur programlar
   (seviye × bölünme × ekipman). Kullanıcı "Programı ekle" deyince programın
   rutinleri **kendi rutinlerine kopyalanır**; sonra istediği gibi düzenler.

**Önerilen seçenek.**
- Set planı, `routine_exercises` tablosuna **tek bir nullable metin kolonu**
  (`set_plan`, JSON) olarak eklenir.
  *Elenen:* ayrı `routine_sets` tablosu — senkron için yeni tablo, yabancı
  anahtar eşlemesi, sunucu RLS (satır düzeyinde güvenlik) ve tetikleyici
  ister; rutin zaten bütün olarak kaydedildiği için (sil + yeniden yaz)
  satır düzeyinde senkronun getirisi yok.
- Katalog **koddaki sabit veri** (Dart), veritabanında değil.
  *Elenen:* katalogu sunucudan indirmek — çevrimdışı ilk açılışta boş kalır,
  yeni sunucu tablosu ve sürümleme ister. İlk sürümde gereksiz.
- Kopyalanan rutinler **normal rutin**: senkronlanır, düzenlenir, silinir.
  Hangi programdan geldiği `routines.program_key` (nullable metin) ile
  tutulur → Rutinlerim ekranında programa göre gruplama (Hevy'deki klasör).
  *Elenen:* ayrı klasör tablosu — şimdilik tek gruplama ölçütü program.

**Gerçek veriye etkisi.** Yalnız **eklemeli**: iki nullable kolon
(`routine_exercises.set_plan`, `routines.program_key`). Mevcut rutinler hiç
değişmez (plan boş → bugünkü davranış). Şema v13 → v14.
**Sunucu:** senkron her kolonu gönderdiği için iki kolon **istemci
yayımlanmadan önce** sunucuya da eklenmeli (Dev'de dene → üretim). Eklemeli
olduğu için eski uygulama sürümü çalışmaya devam eder (bilmediği kolonu
göndermez; sunucu boş bırakır).
**Geri dönüş:** eski sürüme dönülürse plan ve program bilgisi yok sayılır ama
silinmez; eski sürüm rutini kaydederse (sil + yeniden yaz) **o rutinin planı
kaybolur.** Tek kullanıcı döneminde kabul edilebilir; mağaza öncesi asgari
sürüm kapısıyla (docs/23 §3) kapatılır.

**Kararlar (Samet):**
1. [ ] Set planı JSON kolonu (önerilen) mı, ayrı tablo mu?
2. [ ] İlk katalog kapsamı: önerilen **9 program** = 3 seviye
   (başlangıç/orta/ileri) × 3 bölünme (tüm vücut, üst/alt, itme/çekme/bacak),
   yalnız **salon** ekipmanı. Dambıl/ekipmansız sonraki tur.
3. [ ] Program içeriği: yaygın, kamuya açık yapılardan (5x5, PPL, üst/alt)
   **uyarlanır, metinler bizim** (set/tekrar şeması telifli değil; başkasının
   metni/markası kopyalanmaz). İçeriği ben taslaklarım, Samet salonda
   deneyip düzeltir.
4. [ ] Ücretsiz/ücretli: başlangıç programları temel, orta/ileri "akıllı"
   aday — ama **satıştan önce** karar (docs/27). Şimdi hepsi açık.
5. [ ] Programdan eklenen rutinler Rutinlerim'de program adıyla gruplansın
   mı (önerilen), düz liste mi kalsın?

**Nasıl doğrulanacak.**
- Göç testi: v13 veritabanı v14'e kayıpsız geçer; mevcut rutinlerin planı boş.
- Birim test: plan JSON'u okuma/yazma, bozuk JSON → plan yok sayılır
  (çökme yok), plan ↔ "N set × a–b" geri uyum.
- Seans testi: planlı rutin başlatılınca setler planın tipleri ve hedefleriyle
  açılır (ısınma setleri "I" rozetli, istatistiğe girmez).
- Katalog testi: her programdaki her hareket adı seed'de var (bekçi test);
  ekleme iki kez yapılırsa çift rutin oluşmaz ya da açıkça "tekrar ekle" sorar.
- Senkron testi (sahte sunucu): yeni kolonlar gidip geliyor; Dev Supabase'de
  gerçek gidiş-dönüş.
- Cihaz: Dev hesabında program ekle → rutin aç → başlat → plan görünür.

---

## 1. Set planı (F2)

### 1.1 Veri biçimi

`routine_exercises.set_plan` (TEXT, nullable). İçerik bir JSON dizisi; her
eleman bir set:

```json
[
  {"type": "warmup", "repsMin": 10, "repsMax": 15},
  {"type": "warmup", "repsMin": 5,  "repsMax": 8},
  {"type": "normal", "repsMin": 6,  "repsMax": 10},
  {"type": "normal", "repsMin": 6,  "repsMax": 10, "kg": 60},
  {"type": "normal", "sec": 300}
]
```

- `type`: `normal | warmup | drop | failure` (WorkoutSets.setType ile aynı).
- `repsMin/repsMax`, `kg`, `sec` hepsi isteğe bağlı.
- Bilinmeyen alanlar okunurken yok sayılır (ileri uyum), bozuk JSON → plan
  yok sayılır ve hareket bugünkü gibi davranır.

**Geri uyum kuralı (tek yerde, saf fonksiyon):**
- Plan varsa: `targetSets` = plandaki **normal (çalışma)** set sayısı,
  `targetRepsMin/Max` = çalışma setlerinin ilk aralığı. Böylece planı
  bilmeyen kod (eski sürüm, ilerleme önerisi, önizleme) doğru özet görür.
- Plan yoksa: bugünkü alanlar tek doğruluk kaynağı.

### 1.2 Arayüz

- **Rutin oluşturucu:** hareket kartında "Setleri ayrıntılı planla" bağlantısı
  → kart set satırlarına açılır (Hevy rutin düzenleyicisi gibi): her satırda
  tip rozeti (dokununca I/N/D/F), tekrar aralığı, isteğe bağlı kg, süreli
  harekette süre. "Isınma seti ekle" kısayolu iki ısınma satırı ekler
  (≈%50 × 10, ≈%70 × 5 — kilo, çalışma kilosu biliniyorsa önerilir).
- **Önizleme:** "2 ısınma + 4 × 6–10".
- **Canlı seans:** planlı hareket açıldığında setler plan sırasıyla oluşur;
  ısınma setleri "I" rozetiyle gelir; hedef kilo/tekrar, bugünkü öneri
  ipucu (soluk) olarak görünür — **kendiliğinden yazılmaz** (Samet'in
  2026-09-17 kuralı: öneri set yapılmış sayılmaz).

### 1.3 Göç

- v14: `routine_exercises.set_plan` (TEXT NULL), `routines.program_key`
  (TEXT NULL). `onUpgrade` iki `addColumn`. Backfill yok.
- Sunucu (önce Dev, sonra üretim):
  `alter table routine_exercises add column set_plan text;`
  `alter table routines add column program_key text;`
  RLS değişmez (satır sahipliği aynı), tetikleyiciler kolon bağımsız.

## 2. Hazır program kataloğu (F1)

### 2.1 Veri

`lib/data/seed/program_catalog.dart` — sabit liste:

```dart
ProgramDef(
  key: 'beginner_full_body_gym',      // kalıcı kimlik, asla değişmez
  level: Level.beginner, split: Split.fullBody, equipment: Equip.gym,
  daysPerWeek: 3, goal: Goal.muscle,
  routines: [
    RoutineDef(nameKey: 'fullBodyA', exercises: [
      ExDef('Dynamic Warm-Up', plan: [Set.timed(300)]),
      ExDef('Barbell Back Squat', rest: 150, plan: [
        Set.warmup(10, 15), Set.warmup(5, 8),
        Set.work(6, 10), Set.work(6, 10), Set.work(6, 10)]),
      ...
    ]),
  ],
)
```

- Hareketler seed **adıyla** bağlanır (seed id'leri cihazlar arası farklı
  olabilir). Bekçi test: her ad seed'de var.
- Ad ve açıklama metinleri l10n anahtarı (Türkçe + İngilizce).
- Her program hazır programlarda olduğu gibi **ısınma ile başlar** (F3).

### 2.2 Arayüz

- Antrenman sekmesi → "Rutinlerim" üstünde **"Hazır programlar"** kartı →
  Keşfet ekranı: filtre çipleri (Seviye · Bölünme · Gün sayısı), program
  kartları.
- Program detayı: açıklama, etiketler (Başlangıç · 3 gün · Tüm vücut),
  rutinler ve hareketlerin set şeması (salt okunur), **"Programı ekle"**.
- Ekleme: tek transaction'da her rutin + hareketleri + set planı yazılır,
  `program_key` damgalanır. Aynı program daha önce eklenmişse "Zaten
  rutinlerinde — yine de ikinci kopya eklensin mi?" sorulur.
- Rutinlerim: `program_key` dolu rutinler program adıyla gruplanır
  (karar 5), program grubu daraltılabilir.

### 2.3 İlk 9 programın iskeleti (karar 2–3 onaylanırsa)

| Seviye | Tüm vücut | Üst/Alt | İtme/Çekme/Bacak |
|---|---|---|---|
| Başlangıç | 3 gün, A/B dönüşümlü | 4 gün | 3 gün |
| Orta | 3 gün, A/B/C | 4 gün | 3 veya 6 gün |
| İleri | 4–5 gün | 4 gün, güç + hacim (PHUL benzeri) | 6 gün |

İçerik ayrı bir taslak dosyada Samet'in onayına sunulur; kod onu okur.

## 3. Uygulama sırası

1. Set planı veri katmanı + göç v14 + sunucu Dev göçü + testler.
2. Seansın planı kullanması (setlerin tip/hedefle açılması).
3. Rutin oluşturucuda plan düzenleme.
4. Katalog verisi (9 program) + bekçi test.
5. Keşfet + program detayı + ekleme + Rutinlerim gruplaması.
6. Üretim sunucusu göçü → iPhone'a sürüm.

Her adım ayrı commit; 1 bitmeden 2'ye geçilmez.
