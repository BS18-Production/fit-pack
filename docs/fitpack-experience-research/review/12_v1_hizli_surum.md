# 12 — Son öneri ve eleştirel tasarım incelemesi

18 Ekim 2026 · kaynak `07104d1` · üretim kodu değişmedi.
Yazım: 02–10 Codex araştırma oturumunda hazırlandı; oturum kotası bittiği için
01, 11, 12 ve bu inceleme Claude tarafından tamamlandı. İnceleme raporları
olduğu gibi onaylamaz: önce iddiaları kodda yeniden doğrular, sonra yedi bakış
açısıyla sınar ve gerekirse öneriyi değiştirir.

## Karar özeti

**Öneri: B — Rafine Performans, dar bir ilk dilimle.** Mevcut lime/karbon
kimliği ve dört sekme kalır. Yeniden tasarımın ağırlığı görsel yenilemeye değil,
en sık yapılan iki işe (set kaydı, günün eylemini bulma) verilir.

**İlk dilim — "Temel etkileşim güveni"** (09'daki sınır, iki değişiklikle):

1. Set kontrollerinin gerçek dokunma alanı en az 48×48.
2. Önceki/önerilen değer okunur (en az 4,5:1 kontrast) ve etiketli.
3. Set kontrolleri ekran okuyucuda hareket, set, birim ve durumla adlandırılır.
4. Ana sayfada antrenman eylemi enerji kartından önce; ilk görünümde.
5. Beslenme → Hedefler, Profil'deki gerçek kalori/protein düzenleyicisine gider.
6. **(değişiklik)** Beslenme özeti yüklenemezse sessizce kaybolmaz; "Tekrar dene"
   gösterir (U07). Ucuz ve veri güveniyle ilgili; ilk dilime alındı.
7. **(değişiklik)** Ana sayfadaki rutin kartında doğrudan "Başlat" (U08) ilk
   dilime **alınmadı**: tek kullanıcıda yanlışlıkla başlatma riski ölçülmeden
   değiştirilmez; önce Samet'in iki haftalık kullanımında önizleme ekranının
   gerçekten atlanıp atlanmadığına bakılır.

Şema, senkron, hesap kapısı, bildirim ve yerel (native) canlı etkinlik köprüleri
değişmez. Seans küçültme (P07) ayrı teknik tasarım notu ister ve ilk dilimde yok.

**Samet'ten gereken kararlar** en altta.

## 1. Yeniden doğrulama: raporlardaki iddialar kodda doğru mu?

| İddia | Kontrol | Sonuç |
|---|---|---|
| U03: Beslenme "Hedefler" Ayarlar'a gidiyor | `nutrition_screen.dart:236` `onGoals: () => context.push(AppRoutes.settings)` | **Doğru.** Kökeni: docs/34'te "Hedefler mevcut Ayarlar rotasına açılır" yazıyor; hedef düzenleme sonradan Profil'e taşınınca bağlantı eskimiş. |
| U07: özet hatasında sessiz kaybolma | `nutrition_screen.dart:242` `error: (_, _) => const SizedBox.shrink()` | **Doğru.** |
| U04: ✓ 38×34, ± 36×30 | `active_session_widgets.dart:1239–1240`, `:655–656`; özel `InkWell`, Material'in 48'e genişletmesi yok | **Doğru.** |
| U01: uygulama içi çıkış taslağı siliyor | `active_session_screen.dart:985` `_clearDraft()` onaydan sonra | **Doğru.** Onaylı bir eylem; kaza sonucu kayıp değil ama "koruyarak çık" seçeneği yok. |
| U02: aktif seans/eylem beslenmeden sonra | `home_screen.dart:76–102` sırası: başlık → hafta → Haftan hazır → beslenme → eylem kartı | **Doğru.** `dark-tr-home.png`'de (393×852) eylem kartının yalnız başlığı görünüyor. |
| P02: öneri metni %40 opak | `active_session_widgets.dart:1338` `onSurfaceVariant.withValues(alpha: 0.4)` | **Doğru.** Kontrast hesabı Q02'de; yeniden hesaplanmadı. |

Altı iddianın altısı kodla örtüşüyor. Rapor paketinin kanıt disiplini (kod
satırı, "bilinmiyor" demeyi seçmek, uydurma sayı olmaması) güçlü.

## 2. Raporlar arası çelişkiler

| Konu | 05 (Tasarım yönleri) | 07 (Tasarım sistemi) | Karar |
|---|---|---|---|
| Beslenmenin sıcak teması | "Kahverengi ayrı ürün hissi ortak temaya yaklaşır" | "Sıcak yüzeyler bilinçli bir alt ton olarak kalabilir" | **07 kazanır.** Sıcak Günlük, Samet'in 9 Ekim onayıyla geldi (docs/34). Onaylı bir kararı uzman tutarlılık görüşüyle geri almak için kullanıcı şikâyeti yok. Ortak kalan: aynı eylem (ekle, sil, geri al) iki temada aynı biçim ve anlamda. **Samet kararı (K3).** |
| Odak görünümü (tek set büyük) | B'nin aktif antrenman ekranı odak görünümü + "Tümü" | 07 §7: sabit etiketli eylemin kapsamı onay ister | **Ertele.** Bkz. bakış açısı 2. |
| Ana sayfa adı ve kartlar | 05 B: "Bugün" başlığı, iki satır beslenme | 06: Home "Bugün" görev yüzeyi | Uyumlu. |

## 3. Eleştirel inceleme — yedi bakış açısı

### 3.1 İlk kez kullanan kişi

- **Güçlü:** docs/49 ile kurulum artık bir program öneriyor; ilk hafta listesi ve
  "Bugün" kartı var. Araştırma bunları yeniden önermiyor; doğru.
- **Zayıf:** İlk görünümde dev enerji halkası, yeni kullanıcıda **130 / 2400** gibi
  neredeyse boş bir gösterge. İlk gün değer üretmeyen en büyük alan bu. Eylemin
  öne alınması (madde 4) yeni kullanıcıya da en çok yarayan değişiklik.
- **Değişiklik yok.**

### 3.2 Deneyimli salon kullanıcısı (Samet)

- **Risk:** B'nin aktif seans kavramı "tek set büyük, liste gizli". Bugünkü
  tablo düzeni sette hızlı göz gezdirmeyi sağlıyor (önceki seans, tüm setler).
  Odak görünümü deneyimli kullanıcıyı yavaşlatabilir; "Tümü" bağlantısı ek dokunuş.
- **Revizyon:** Odak görünümü Faz 3'ten **çıkarıldı, deney olarak** bekletildi.
  Önce tablo düzeninde 48×48 hedefler ve okunur öneri (Faz 1). Faz 1 sonrası
  Samet iki hafta kullanır; tabloda hâlâ yanlış dokunma veya küçük metin sorunu
  varsa odak görünümü prototiplenir.

### 3.3 Her gün beslenme kaydeden kişi

- **Güçlü:** Panel kapanmadan art arda ekleme, son porsiyon, geri alma,
  öğün kopyalama zaten var. 04 bunları kaybetmeme uyarısını doğru yapıyor.
- **Eksik:** Ana sayfadaki öğün kartından hızlı + ile 2 seçimde kayıt mümkün,
  ama kart ana sayfanın altında. Madde 4 eylemi öne aldığında öğün kartı daha da
  aşağı iner. **Revizyon:** Faz 3'te ana sayfa beslenme bölümüne doğrudan
  "Ekle" (05 B kavramındaki "+ Ekle") konur; Faz 1'de sıra değişikliğinin öğün
  kaydını yavaşlatmadığı Samet'in kullanımıyla kontrol edilir.

### 3.4 Karmaşık uygulamayı sevmeyen kişi

- Ana sayfa listesinde 15 bölüm var, bazıları koşullu (`home_screen.dart:76–102`, U11). Bu kişi için en büyük sorun yoğunluk.
- Araştırmanın önerisi (bir birincil görev + en çok iki bağlamsal satır)
  doğru ama Faz 3'e bırakılmış. **Değişiklik yok**, çünkü kart kaldırmak bilgi
  kaybıdır ve gerçek kullanıcı verisi olmadan yapılmamalı.

### 3.5 Premium ürün müşterisi

- **Araştırmanın atladığı:** FitPack'in konumlandırması premium ve deneme süresi
  dışında ücretsiz kullanım yok (para kazanma kararı, ertelendi). Bu, **ilk 7
  günün** satın alma kararını verdiği anlamına gelir. Raporlarda "premium kalite =
  ücretli değil" ayrımı doğru, ama deneme süresinin deneyimi hiç incelenmemiş.
- **Revizyon:** Doğrulama ölçütlerine "deneme haftası görevleri" eklenir: ilk
  antrenmanı bitirme, ilk öğünü ekleme, ilk haftalık değerlendirmeyi görme.
  Bunlar docs/49'un ilk hafta listesiyle aynı; ölçüm altyapısı gerekmez.
- Görsel kalite: mevcut kimlik (koyu karbon, lime, özgün ikonlar) zaten ayırt
  edici. Rakiplerin çoğu açık/beyaz zeminli; FitPack'in koyu performans dili
  bir farklılaşma. Değiştirmemek doğru karar.

### 3.6 Mobil mühendislik lideri

- **Tahmin birimi yanlış:** 09'daki "iş günü" tahminleri tek insan geliştiriciye
  göre. Bu projede kodu yapay zekâ yazıyor; gerçek darboğaz **Samet'in cihazda
  deneme süresi** ve onay döngüsü. Faz 1 kodu birkaç saatte yazılır; asıl süre
  iki cihazda tek el, klavye ve ekran okuyucu denemesidir.
  **Revizyon:** Her dilimde "kod" ve "cihaz denemesi" ayrı tahmin edilir.
- **48×48 ve dar ekran:** 320 genişlikte set satırı (set no · kg · ± · tekrar ·
  ✓) 48'lik hedeflerle sığmayabilir. 09 "iki satıra geçer" diyor; bu her seti
  iki kat uzatır, kaydırma artar. **Alternatif:** ± düğmelerini satırdan çıkarıp
  sayı alanına dokununca açılan büyük adım panelinde toplamak; ✓ 48×48 kalır.
  İki seçenek de Faz 1'de dar ekran render'ıyla karşılaştırılır, sonra seçilir.
- **P07 (seans küçültme)** risk değerlendirmesi doğru: sayaç, mola alarmı ve
  kilit ekranı canlı etkinliği bugün ekranın ömrüne bağlı (`dispose`). Ayrı
  tasarım notu olmadan başlanmamalı.

### 3.7 Erişilebilirlik uzmanı

- Hedef boyutu, kontrast ve semantik etiketin ilk dilimde olması doğru öncelik.
- **Eksik:** Mola sayacının ekran okuyucuda her saniye anons edilmemesi P11'de
  var ama kabul ölçütlerinde yok. **Revizyon:** Faz 1 kabulüne eklendi:
  "Mola sayacı yalnız başlangıçta, son 10 saniyede ve bitişte anons edilir."
- **Eksik:** Renk körlüğü. Makro çubukları (protein lime, karbonhidrat mercan,
  yağ krem) yalnız renkle ayrışıyor mu? Etiketler var (dark-tr-home.png'de
  "Protein / Karbonhidrat / Yağ" yazıyor), sorun yok; ama 3 renkli halka
  varyantlarında etiket zorunluluğu tasarım sistemine yazılmalı (07 §9'a not).

## 4. Revize edilmiş yol haritası

| Faz | Kapsam | Kod | Cihaz denemesi | Çıkış kapısı |
|---|---|---|---|---|
| **1 — Temel güven** | Karar özetindeki 1–6 | ~1 oturum | iPhone + Samsung, 1–2 akşam | Kabul ölçütleri (aşağıda) + Samet'in 2 haftalık kullanımı |
| **2 — Görsel sistem** | Ortak bileşen durumları (07 §6), kontrast denetimi, açık tema eşdeğerleri | 1–2 oturum | 1 akşam | Bileşen galerisi açık/koyu, TR/EN |
| **3A — Bugün** | Tam "Bugün" hiyerarşisi, ana sayfada beslenme "+ Ekle", kart sadeleştirme | 1–2 oturum | Berna + Samet | Yeni kullanıcıda ve Samet'te "sonraki eylemi 5 saniyede bul" |
| **3B — Seans küçültme (P07)** | Önce teknik tasarım notu, sonra kod | not + 2–3 oturum | Kesinti matrisi (10 §5) | Tek seans kimliği, sayaç ve canlı etkinlik bozulmaz |
| **3C — İlerleme** | Antrenman / Vücut / Haftalık girişleri | 1–2 oturum | 1 akşam | "Bench gelişimimi bul" görevi |
| **4 — İnce işçilik** | Hareket, boş/hata durumları, haftalık dil | 1 oturum | 1 akşam | Azaltılmış hareket, bildirim sayısı artmaz |
| **Deney (koşullu)** | Aktif seans odak görünümü | — | — | Yalnız Faz 1 sonrası tabloda sorun sürerse |

## 5. Faz 1 kabul ölçütleri (09'a eklemelerle)

- Tüm özel set hedefleri ≥ 48×48 mantıksal birim; 320 genişlikte taşma yok.
- Öneri metni normal yüzeyde ≥ 4,5:1; "Önceki" etiketi görünür.
- VoiceOver ve TalkBack ile: değer gir → seti tamamla → geri al, engelsiz.
- **Mola sayacı yalnız başlangıç, son 10 saniye ve bitişte anons edilir.** (yeni)
- 360×800 ve 393×852'de normal yazıda antrenman eylemi ilk görünümde.
- Beslenme → Hedefler → kalori değiştir → geri dön: seçili gün korunur.
- **Beslenme özeti hatasında "Tekrar dene" görünür; yanlış 0 gösterilmez.** (yeni)
- Seans kaydı, taslak, set kopyalama, RPE, süre/mesafe ve geri alma davranışı
  değişmez; mevcut testler yeşil, `flutter analyze` 0.
- `flutter install` kullanılmaz; yerinde güncelleme.

## 6. Başarı nasıl görülecek (analitik olmadan)

Uygulamada analitik yok ve olmaması gizlilik açısından değerli (docs/41). Ölçüm
elle ve küçük ölçekte:

| Ölçü | Nasıl | Kim |
|---|---|---|
| Ana sayfadan ilk sete süre | Kronometre, önce/sonra aynı rutin | Samet |
| Yanlış dokunma | Bir seans boyunca geri alma sayısı (taslakta görülür) | Samet |
| "Sonraki eylem" anlaşılırlığı | Ekranı 5 sn göster, sor | Berna + 2–3 gönüllü |
| Deneme haftası görevleri | İlk antrenman, ilk öğün, ilk haftalık değerlendirme | Yeni hesaplar (Supabase'de sayılabilir) |

Hedef sayılar hipotezdir; bugünkü değerler ölçülmedi.

## 7. Samet'ten gereken kararlar

- **K1 — Yön:** B (Rafine Performans) onaylanıyor mu? Kimlik ve dört sekme kalır.
- **K2 — İlk dilim:** Karar özetindeki 6 madde (seans küçültme ve tam görsel
  yenileme hariç) onaylanıyor mu?
- **K3 — Beslenme teması:** Sıcak Günlük kalsın mı (önerim: kalsın), yoksa
  ortak lime/karbon temaya mı yaklaşsın?
- **K4 — Set satırı, dar ekran:** ± düğmeleri satırda kalıp satır iki kata mı
  çıksın, yoksa sayı alanından açılan adım paneline mi taşınsın? Önerim: ikisini
  dar ekran görüntüsüyle karşılaştırıp sonra seçmek.
- **K5 — Test katılımcısı:** Berna dışında 2–3 gönüllü bulunabilir mi?
