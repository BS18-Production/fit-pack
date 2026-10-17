# 49 — Yeni kullanıcı deneyimi: ilk açılıştan ilk haftaya

> **Durum:** Öneri — Samet'in kararı bekleniyor. Kod yok.
> **İlgili:** docs/15 (Onboarding V2, Temmuz), docs/28 (hazır program
> kataloğu), docs/18 (zorunlu hesap), docs/38 (asistan).

## Karar özeti

**Sorun.** Uygulamaya giren yeni kullanıcı kurulumu bitirince ne yapacağını
bilmiyor. Canlı veride iki örnek:

- Ekim'de Google ile giren bir hesap kurulumu **bitirmemiş** (tek giriş,
  profil varsayılan değerlerde).
- Temmuz'da giren bir hesap kurulumu bitirmiş ama 3 ayda **0 rutin, 0
  antrenman** kaydı var.

İkisi de aynı yeri gösteriyor: kurulum bize veri veriyor ama kullanıcıya
**ilk antrenmanını** vermiyor.

**Bugünkü akış.**

1. Karşılama → hesap oluştur / Google ile gir (e-postayla kayıtta onay
   postası için uygulamadan çıkılıyor).
2. Kurulum, 4 sayfa: karşılama → kilo/boy/cinsiyet/yaş + hedef (ver / koru
   / al) → kalori + protein planı → "İçeride ne var" (4 sekme listesi).
3. Ana sayfa: günlük özet (enerji, öğünler, son 7 gün). Antrenman için
   "Antrenmana başla — Rutin oluştur ya da boş antrenman başlat".
4. Antrenman sekmesine ilk girişte tek ipucu: "Hazır bir programla başla ya
   da kendi rutinini kur."

Uygulamanın kalbi antrenman olduğu hâlde kurulum **antrenmanla ilgili tek
soru sormuyor**. 9 hazır program var (başlangıç / orta / ileri × tüm vücut /
alt-üst / itiş-çekiş-bacak, haftada 3–6 gün), ama kullanıcı onları ancak
Antrenman sekmesindeki "Keşfet" bölümünü kendisi bulursa görüyor.

**Önerilen seçenek: "ilk antrenmanın hazır" kurulumu.**

- **A. Kurulumda iki antrenman sorusu** (beslenme sorularından önce):
  - Deneyim: "Yeni başlıyorum / Bir süredir yapıyorum / Uzun süredir
    yapıyorum".
  - Haftada kaç gün: 2–3 / 4 / 5–6.
- **B. Program önerisi sayfası:** iki cevaba göre 9 programdan biri
  önerilir. Tek dokunuşla "Bu programla başla" der (rutinler kullanıcının
  hesabına kopyalanır; bugün Keşfet'teki "Programı ekle" ile aynı işlem) ya
  da "Kendim kuracağım" diye geçer.
- **C. Ana sayfada "bugünkü antrenman" kartı:** program seçildiyse ilk
  açılışta ilk gün hazır gelir: "Bugün: Tüm vücut A · 6 hareket · ~45 dk →
  Başlat". Seçilmediyse kart iki yolu gösterir: hazır program / kendi rutinin.
- **D. İlk hafta rehberi (hafif):** ana sayfada 3 adımlı bir kontrol listesi.
  Kullanıcı tamamladıkça adım işaretlenir, üçü bitince kart kaybolur:
  1. İlk antrenmanını bitir.
  2. İlk öğününü ekle.
  3. İlk kilonu gir.
  Bildirim ya da rozet yok; sadece ne yapacağını gösterir.
- **E. Küçük düzeltmeler:**
  - Yeni telefonda eski hesapla giren kullanıcıya ilk kullanım ipuçları
    tekrar gösteriliyor. Gösterim kararı hesabın kurulum durumuna göre
    verilmeli.
  - "İçeride ne var" sayfası A ve B gelince gereksizleşir. Kurulum 4 sayfada
    kalsın diye bu sayfa çıkarılır.

**Elenen seçenekler.**

- *Uzun tanıtım slaytları:* docs/15'teki araştırma bunun işe yaramadığını
  gösteriyor; kullanıcı görmediği ekranı hatırlamıyor.
- *Programı zorunlu seçtirmek:* kendi rutinini kurmak isteyeni engeller.
  "Kendim kuracağım" her zaman açık kalır.
- *Kurulumu tamamen atlatmak:* kalori hedefi kilo olmadan hesaplanamıyor.
  Ama beslenme soruları kısaltılabilir (aşağıda karar 3).

**Gerçek veriye etkisi.** Şema, göç ya da sunucu değişikliği yok. Program
kopyalama mevcut işlemi kullanır. Mevcut kullanıcılar kurulumu bir daha
görmez; yeni kart yalnızca rutini olmayan kullanıcıda çıkar.

**Samet'ten gereken kararlar.**

1. Bu yön (A–D) uygun mu?
2. Program önerisi bir kez mi yapılsın, yoksa kullanıcı Keşfet'e girmeden
   önce "Programını değiştir" seçeneği de olsun mu? Önerim: bir kez yapılsın;
   değiştirmek isteyen Keşfet'i kullanır.
3. Kurulumdaki beslenme soruları kısalsın mı? Örneğin boy, cinsiyet ve yaş
   "sonra tamamla" diye ertelenebilir; kilo ve hedef kalır. Önerim: kısalsın.
   Kalori tahmini eksik bilgiyle de çalışıyor, eksikler Profil'den
   tamamlanabiliyor.
4. Ekip notu: Berna'ya ilk hafta deneyimini birlikte denetelim mi? Gerçek
   bir yeni kullanıcının gözü bu iş için en değerli test.

**Nasıl doğrulanacak.**

- Birim testleri:
  - Öneri tablosu: 3 deneyim × 3 gün aralığı = 9 kombinasyonun her biri
    tek bir programa gider.
  - Kurulum, program seçilmeden de bitebiliyor.
  - Kontrol listesi doğru adımları işaretliyor.
- Arayüz testi: sıfır kurulum → kurulum → program seç → ana sayfada
  "Bugün" kartı → Başlat → aktif seans ekranı.
- Cihazda: test hesabıyla sıfırdan kurulum (iPhone ve Samsung).

---

## 1. Program önerisi tablosu

| Deneyim \ Gün | 2–3 | 4 | 5–6 |
|---|---|---|---|
| Yeni başlıyorum | Tüm vücut · başlangıç | Alt-üst · başlangıç | Alt-üst · başlangıç |
| Bir süredir | Tüm vücut · orta | Alt-üst · orta | İtiş-çekiş-bacak · orta |
| Uzun süredir | Tüm vücut · ileri | Alt-üst · ileri | İtiş-çekiş-bacak · ileri |

Yeni başlayan biri haftada 5–6 gün istese bile 4 günlük program önerilir.
Öneri kartı bunun nedenini tek cümleyle söyler: "Başlangıçta dinlenme günü
gelişimi hızlandırır." 3 günlük itiş-çekiş-bacak başlangıç programı tabloda
yer almıyor, Keşfet'te seçilebilir.

## 2. Kurulumun yeni sırası

1. Karşılama (aynı).
2. **Antrenman:** deneyim + haftada kaç gün (yeni, tek sayfa).
3. **Programın:** öneri kartı. "Bu programla başla" ya da "Kendim kuracağım".
4. Seni tanıyalım: kilo + hedef. Boy, cinsiyet ve yaş karar 3'e göre
   kurulumda kalır ya da "sonra" diye ertelenir.
5. Planın hazır: kalori + protein (aynı).

"İçeride ne var" çıkar. Toplam sayfa 4'ten 5'e çıkar. Karar 3 "kısalsın"
olursa 4. sayfa tek alana iner.

## 3. Ana sayfa: "Bugün" kartı ve ilk hafta rehberi

- **"Bugün" kartı:**
  - Programı varsa sıradaki gün gösterilir. Bu, bugün de kullanılan "günün
    rutini" mantığıdır (`todayRoutineProvider`).
  - Rutini yoksa iki düğme: "Hazır program seç" (Keşfet'e gider) ve "Kendi
    rutinini kur".
- **İlk hafta rehberi:**
  - Yalnızca hesabın ilk 14 gününde ve üç adım bitmediyse görünür.
  - Adımlar mevcut veriden okunur: antrenman sayısı > 0, öğün sayısı > 0,
    kilo ölçümü > 0.
  - Ayrı bir tablo ya da bayrak tutulmaz; senkronla öbür cihazda da aynı
    görünür.

## 4. Kapsam dışı

- Bildirimle geri çağırma ("2 gündür antrenman yok"): ayrı iş, izin akışı
  gerektirir.
- E-postayla kayıtta onay postası sorunu (uygulamadan çıkma, saatlik kota):
  özel e-posta sunucusu (SMTP) işiyle birlikte ele alınacak
  (reference-supabase-email-smtp).
- Premium deneme ekranı: para kazanma işi.
