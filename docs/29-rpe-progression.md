# 29 — RPE'yi İlerleme Önerisine Katmak (docs/27 F5)

> **Durum:** ✅ Kodlandı (2026-10-08) — Samet'in kararlarıyla: yalnız tükeniş
> tarafı ("çok rahat → kilo artır" YOK), kilo düşürme önerisi VAR.
> **Katman:** akıllı (ücretli aday) — bu özellikle birlikte docs/27'deki
> tek kontrol noktası (`featureEnabled`) eklenir; bugün hep açık.
> **Bağlı:** `lib/features/workout/progression.dart` (çift ilerleme, docs/21
> §2 #3), RPE seçicisi (F4).

## Karar özeti

**Ne değişecek, neden.** Canlı seansta bugün bir ilerleme önerisi var ve
yalnız **tekrar sayısına** bakıyor: geçen sefer bütün çalışma setleri aralığın
üstüne ulaştıysa "kilo artır", aralık içindeyse "+1 tekrar", altındaysa
"aynısını tekrar et". Girilen RPE (Algılanan Zorluk) hiçbir şeyi etkilemiyor.
Oysa aynı "3 × 12" bir gün rahat (RPE 7), bir gün tükenişte (RPE 10) gelir —
ikisi için doğru adım farklı. RPE'yi öneriye **ikinci girdi** olarak
katıyoruz; RPE girilmemişse bugünkü kural **aynen** çalışır.

**Önerilen kural (geçen seansın çalışma setleri, ısınma hariç):**

| Tekrar durumu | RPE (çalışma setlerinin en yükseği) | Öneri |
|---|---|---|
| Hepsi aralığın üstünde | ≤ 8 | **Kilo artır** (bugünkü gibi) |
| Hepsi aralığın üstünde | ≥ 9,5 | **Kilo artır, ama tekrar aralığın altından başla** — bugünkü gibi; gerekçe metni "zorlandın, ilk sette tekrar düşebilir" uyarısı ekler |
| Aralık içinde | ≤ 7 (hepsi rahat) | **Kilo artır** — tekrar aralığın üstüne ulaşmadan; "çok rahat geldi" gerekçesi (yeni) |
| Aralık içinde | 8 – 9,5 | **+1 tekrar** (bugünkü gibi) |
| Aralık içinde | 10 (en az bir set tükeniş) | **Aynı hedefi tekrar et** — +1 tekrar zorlanmaz (yeni) |
| En az bir set aralığın altında | herhangi | **Tekrar et** (bugünkü gibi) |
| Üst üste **2 seans** aralığın altında ve RPE 10 | — | **Kiloyu bir adım düşür** önerisi (yeni, düğmeyle; kendiliğinden değil) |

- "En yüksek RPE" seçildi çünkü tek bir tükeniş seti, ortalaması düşük
  olsa da yorgunluğu gösterir. *Elenen:* ortalama RPE — 7, 7, 10'u "8" diye
  yumuşatır.
- RPE yalnız **bir kısım** sette girildiyse: girilen setlere bakılır; hiç
  yoksa bugünkü kural.
- Öneri **hiçbir zaman kendiliğinden uygulanmaz** (Samet'in 2026-09-17
  kuralı): kart gerekçesiyle görünür, düğmeye basılırsa yalnız o seansın
  önerileri değişir, rutin hedefi değişmez.

**Elenen seçenekler.**
- Tam RPE tabanlı programlama (hedef "3 × 5 @ RPE 8", kiloyu RPE tablosundan
  hesaplamak): güçlü ama kullanıcıdan disiplinli RPE girişi ister; tek
  kullanıcı pilotunda erken. İleride e1RM ile birlikte (§3).
- Yorgunluk/deload algılama: ayrı iş (§3); veri biriktikçe.

**Gerçek veriye etkisi.** **Yok.** Şema değişmez, yalnız hesap kuralı.
Mevcut kayıtlar okunur, hiçbir şey yazılmaz. Geri dönüş: kural kodu eski
haline dönerse öneriler bugünkü gibi olur.

**Kararlar (Samet):**
1. [x] Eşikler: "tükeniş" = RPE 10; "zorlandın" uyarısı ≥ 9,5. "Rahat"
   eşiği kullanılmıyor (karar 2).
2. [x] **Hayır** (2026-10-08): "aralık içinde ama çok rahat → kilo artır"
   kuralı eklenmedi; rahat RPE'de öneri bugünkü gibi +1 tekrar.
3. [x] **Evet**: 2 seans üst üste aralığın altında + son seansta RPE 10 →
   "−adım" önerisi, düğmeyle.
4. [ ] Katman kararı satıştan önce (docs/27); `featureEnabled` kontrol
   noktası o zaman eklenir — bugün herkes için açık.

**Nasıl doğrulanacak.**
- Birim test: tablodaki her satır için `progressionFor` beklenen öneriyi
  verir; RPE'siz girdi bugünkü sonuçla birebir aynı (mevcut testler
  değişmeden geçer — regresyon bekçisi).
- Kısmi RPE, ısınma setinde RPE (yok sayılır), 6 altı eski değerler.
- Seans testi: gerekçe metni RPE'yi anıyor ("en zor set RPE 10").
- Cihaz: Dev hesabında RPE'li geçmiş seans → yeni seansta kart doğru öneriyi
  gösterir.

---

## 1. Teknik tasarım

### 1.1 Girdi

`progressionFor` bugün `List<SetValues>` alıyor (kg + tekrar). `SetValues`
`rpe` taşımıyor. İki seçenek:

- **Önerilen:** `progressionFor`'a ayrı `List<double?> lastRpe` (çalışma
  setleriyle aynı sıra) parametresi; `SetValues` değişmez (taslak/öneri
  karşılaştırmasında RPE eşitliğe girmemeli — `SetValues ==` kullanılıyor).
- Üst üste iki seans kuralı için bir önceki seansın da çalışma setleri
  gerekir: `_adviceFor` iki seans okur (DAO'da var olan "son N seans"
  sorgusu kullanılır; yoksa eklenir — okuma, şema değil).

### 1.2 Çıktı

`ProgressionKind`'a iki değer eklenir:
- `increaseWeightEasy` — aralık içinde ama rahat (gerekçe metni farklı,
  uygulaması `increaseWeight` ile aynı).
- `decreaseWeight` — iki seans başarısız; uygulaması kiloyu bir artış adımı
  düşürür, tekrar `repsMin`.

`ProgressionAdvice`'a `double? topRpe` (gerekçe metni için).

### 1.3 Kontrol noktası

`lib/core/features/feature_gate.dart`:

```dart
enum Feature { rpeProgression }
bool featureEnabled(Feature f) => true; // karar satıştan önce (docs/27)
```

`_adviceFor` RPE'li kuralı yalnız `featureEnabled(Feature.rpeProgression)`
ise uygular; değilse bugünkü kural. Böylece ileride ücretsiz kullanıcı yine
temel öneriyi görür, yalnız RPE'li akıllı kısım kapanır.

## 2. Uygulama sırası

1. `feature_gate.dart` + `progressionFor` RPE parametresi + tablo testleri
   (mevcut testler değişmeden geçmeli).
2. `_adviceFor` iki seans okuması + seans testi.
3. Gerekçe metinleri (l10n) + cihaz doğrulaması.

## 3. Sonraki adımlar (bu dokümanın kapsamı dışı)

- **e1RM (tahmini tek tekrar maksimumu):** kilo + tekrar + RPE'den (RTS
  tablosu benzeri); ilerleme grafiğinde güç eğrisi. Ayrı doküman.
- **Yorgunluk sinyali:** haftalık en yüksek RPE artarken hacim/performans
  düşüyorsa haftalık değerlendirmede "hafif hafta (deload)" önerisi;
  `WorkoutSessions.isDeload` zaten var.
