# 50 — Asistandan haftalık özet ve "bugün ne yapmalıyım"

> **Durum:** Öneri — Samet'in kararı bekleniyor. Kod yok.
> **İlgili:** docs/22 (haftalık değerlendirme), docs/29 (RPE — algılanan
> zorluk — ile ilerleme önerisi), docs/36 (kural tabanlı yorum), docs/38
> (Verime sor / Gemini), docs/41 (gizlilik), docs/43 (gerçek harcama),
> docs/49 (Sıradaki antrenman kartı).

## Karar özeti

**Sorun.** Uygulama veriyi topluyor ve büyük kısmını yorumluyor ama
yorumlar dağınık:

- Haftalık değerlendirme ayrı bir ekranda duruyor.
- İlerleme önerisi yalnızca canlı seansın içinde görünüyor.
- "Bugün ne kaldı" bilgisi Verime sor'da, ancak soru sorulunca çıkıyor.

Kullanıcı uygulamayı açtığında tek bir yerde "bugün ne yapmalıyım"ı
görmüyor. Haftalık özeti de ancak ekranı kendisi açarsa okuyor (bildirim
varsayılanda kapalı).

**Bugün zaten var olanlar (yeniden yapılmayacak):**

| Ne | Nerede | Nasıl çalışır |
|---|---|---|
| Haftalık özet: antrenman, ilerleyen 3 hareket, beslenme, kilo, kas dengesi, gelecek hafta için **tek odak cümlesi** | `/insights/week` (docs/22) | Kural tabanlı, cihazda, ücretsiz |
| Haftalık bildirim | Pazar 20:00, **varsayılan kapalı** | Metin sayı içermiyor |
| İlerleme önerisi: kilo artır / +1 tekrar / tekrar et / kilo düşür | Canlı seans (docs/29) | Kural tabanlı |
| "Bugün hedefime ne kaldı" | Verime sor hazır sorusu (docs/36) | Kural tabanlı |
| Gerçek harcama tahmini | Profil / ana sayfa (docs/43) | Kural tabanlı |
| Sıradaki antrenman | Ana sayfa (docs/49) | Rutin döngüsü |

Yani "haftalık özet" **zaten var**. Eksik olan özetin içeriği değil:
kullanıcıya **ulaşması** ve günlük karşılığının olmaması.

**Önerilen seçenek: yapay zekâsız "Bugün" özeti + haftalık özetin
kendiliğinden gelmesi.**

1. **Ana sayfada "Bugün" satırları (yeni, kural tabanlı, çevrimdışı).**
   docs/49'daki "Sıradaki antrenman" kartı genişler; altında en fazla 3 kısa
   satır çıkar. Her satır mevcut bir hesaptan gelir:
   - *Antrenman:* "Bench Press'te bu sefer 62,5 kg dene." Kaynak: docs/29
     ilerleme kuralı, sıradaki rutinin ilk uygun hareketi. Öneri yoksa satır
     çıkmaz.
   - *Beslenme:* "Bugün 85 g protein kaldı." Kaynak: `today_remaining`
     (docs/36). Öğün kaydı yoksa "İlk öğününü ekle".
   - *Dinlenme:* Son 2 günde aynı kas grubu ağır çalışıldıysa "Bacaklar dün
     çalıştı; bugün üst vücut daha uygun." Kaynak: kas grubu eşlemesi
     (docs/22 A2). Yalnızca rutinler güne bağlı değilse gösterilir.
   Satırlar öneridir; hiçbir şeyi kendiliğinden değiştirmez (Samet kuralı,
   2026-09-17).
2. **Haftalık özet kendiliğinden gelir.** İki küçük değişiklik:
   - Haftalık bildirim yeni hesaplarda **açık** başlar. Mevcut kullanıcının
     tercihi değişmez.
   - Hafta kapanınca (Pazar 20:00'den sonra), değerlendirme açılana kadar
     ana sayfanın üstünde **"Haftan hazır"** kartı durur: odak cümlesi ve
     "Aç" düğmesi.
3. **Gemini sonraki aşamada, isteğe bağlı.** Özet metnini doğal dille
   "anlatmak" için. Ayrı bir karar konusu (aşağıda Faz 3).

**Elenen seçenekler.**

- *Haftalık özeti baştan Gemini'ye yazdırmak:* Var olan kural tabanlı ekranı
  ikinci kez yapmış oluruz.
  - Sağlıkla ilgili cümleler doğrulanamaz (docs/36'daki gerekçe).
  - Kullanıcının haftalık verisi Google'a gider. Bugün Verime sor'da yalnızca
    soru metni gidiyor; veri gitmiyor.
  - Ücretsiz katman kotası (uygulama genelinde günde 400 istek, dakikada 10)
    paylaşılır.
  - docs/41 §4: AB kullanıcısına hizmet veren uygulamada ücretli katman şart
    olabilir.
- *"Bugün ne yapmalıyım"ı tam program önerisine çevirmek:* Bu, program
  yazmak demek. Asistanın sınırı bunu dışarıda bırakıyor (docs/38: "Gemini
  cevap, program veya kişisel reçete yazmaz").
- *Ayrı bir "Koç" sekmesi:* Ana sayfa zaten bu iş için var. Yeni sekme
  dağınıklığı artırır.

**Gerçek veriye, sunucuya, maliyete etkisi (Faz 1–2).**

- Şema, sunucu ya da senkron değişikliği yok. Her şey mevcut tablolardan
  okunur.
- Ağ yok, Gemini yok, maliyet yok.
- Tek kalıcı yazma: yeni hesapta haftalık bildirim tercihinin varsayılanı
  (cihazdaki tercih).
- "Haftan hazır" kartının görülüp görülmediği cihazda tek bir tarih olarak
  tutulur (yeni tablo yok).

**Premium ile ilişkisi (karar verilmiyor, yalnızca işaretleniyor).**

- Fiyatlandırma kararı ertelendi; konumlandırma premium, deneme yaklaşık 7
  gün. Bu yüzden her şey zaten deneme içinde görülecek.
- Ücretli aday olarak işaretlenebilecek parçalar:
  - "Bugün" satırlarındaki **antrenman önerisi**: docs/29 bunu zaten "akıllı
    (ücretli aday)" katmanında sayıyor.
  - Faz 3'teki Gemini anlatımı.
- Ücretsiz kalması önerilenler: "Haftan hazır" kartı ve beslenme satırı.
  Kullanıcıyı uygulamaya bağlayan şeyler bunlar.
- docs/27'de öngörülen tek özellik anahtarı (`featureEnabled`) kodda henüz
  yok. Para kazanma işi açılınca eklenir; bu iş onu beklemez.

**Samet'ten gereken kararlar.**

1. Faz 1 ("Bugün" satırları) ve Faz 2 ("Haftan hazır" kartı + bildirimin
   yeni hesapta açık başlaması) uygun mu?
2. "Bugün" satırları en fazla kaç tane olsun? Önerim 3: antrenman, beslenme,
   dinlenme. Dinlenme satırı ilk sürümde olsun mu?
3. Haftalık bildirim **mevcut kullanıcılarda** da açılsın mı? Önerim hayır;
   yalnızca yeni hesaplarda açık başlasın.
4. Faz 3 (Gemini ile anlatım) şimdi planlansın mı, yoksa para kazanma ve
   docs/41 §4'teki ücretli katman kontrolü bitene kadar beklesin mi? Önerim
   beklesin.

**Nasıl doğrulanacak.**

- Birim testleri:
  - Her "Bugün" satırı ayrı bir saf fonksiyon. Veri yokken, öneri yokken ve
    gün dönerken (`currentDayProvider`) test edilir.
  - "Haftan hazır" kartı yalnızca hafta kapandıktan sonra ve değerlendirme
    açılana kadar görünür.
- Arayüz testi: ana sayfada satırlar ve kart.
- Gerçek veriyle karşılaştırma: Samet'in verisinde "Bugün" antrenman satırı,
  canlı seansta çıkan ilerleme önerisiyle aynı kiloyu söylemeli (aynı motor).
- Cihazda: iPhone'da bir hafta kullanım; Pazar akşamı kart ve bildirim.

---

## 1. Fazlar

| Faz | Ne | Yapay zekâ | Süre tahmini |
|---|---|---|---|
| **1** | Ana sayfada "Bugün" satırları (antrenman, beslenme, dinlenme) | Yok | 1–1,5 gün |
| **2** | "Haftan hazır" kartı + yeni hesapta haftalık bildirim açık | Yok | 0,5 gün |
| **3** | (İsteğe bağlı) Haftalık özetin Gemini ile 3–4 cümlelik doğal anlatımı | Gemini | Ayrı tasarım |

**En küçük değerli ilk adım: Faz 1'in yalnızca antrenman ve beslenme
satırları.** İkisi de mevcut hesapları kullanır (docs/29, docs/36), yalnızca
ana sayfaya taşınır. Dinlenme satırı yeni bir kural olduğu için ikinci
adımdır.

## 2. "Bugün" satırlarının kuralları

| Satır | Ne zaman görünür | Metin örneği | Kaynak |
|---|---|---|---|
| Antrenman | Sıradaki rutinde ilerleme önerisi "kilo artır" ya da "+1 tekrar" olan bir hareket varsa | "Squat: bu sefer 82,5 kg dene." | `progression.dart` |
| Antrenman (öneri yok) | Görünmez | — | — |
| Beslenme | Bugün kalori ya da protein hedefi tutmadıysa | "Bugün 85 g protein, 640 kcal kaldı." | `today_remaining` |
| Beslenme (kayıt yok) | Bugün hiç öğün yoksa | "İlk öğününü ekle." | — |
| Dinlenme | Son 48 saatte aynı ana kas grubuna ≥ 6 set ve sıradaki rutin aynı grubu çalıştırıyorsa | "Bacaklar dün çalıştı; istersen önce üst vücudu yap." | docs/22 A2 kas eşlemesi |

- Satırlar tıklanınca ilgili yere gider: rutin önizlemesi, Beslenme ya da
  rutin listesi.
- Bugün antrenman yapıldıysa antrenman ve dinlenme satırları gizlenir.
  Kalıplaşmış "Harika iş!" metni yok.
- Yargı cümlesi yok ("az çalıştın", "hedefi tutturamadın" — docs/22 Samet
  kuralı).

## 3. Faz 3 için açık sorular (bu sürüme girmez)

- **Gemini'ye ne gider?** Ham kayıtlar değil, yalnızca haftalık
  değerlendirmenin sayıları: seans sayısı, ilerleyen hareketler, ortalama
  kalori, kilo farkı. Yine de bu sağlık verisi sayılır (docs/41); politika
  metni ve rıza ekranı gerekir.
- **Doğrulama:** Model sayı üretmez. Yalnızca uygulamanın verdiği sayıları
  cümleye döker. Çıktıda verilmeyen bir sayı varsa cevap atılır ve kural
  tabanlı metin gösterilir.
- **Kota:** Haftada kişi başı 1 istek. Bugünkü kota için ihmal edilebilir.
  Asıl engel ücretli katman şartı (docs/41 §4).
