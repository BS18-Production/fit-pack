# 23 — Senkronun ticari ürüne hazırlanması

> **Durum:** ✅ **§2 ve §3 kodlandı (2026-09-22).** Saat düzeltmesi (şema v13)
> ve asgari sürüm kapısı (`app_min_version`, Dev + üretimde, atıl) hazır;
> cihazda görsel kontrol bekliyor. §4 (abonelik) karar olarak alındı,
> kodlaması satın alma katmanı geldiğinde.
> **Tarih:** 2026-09-22 · **Yazan:** Claude
> **Temel:** `main` · şema v12 · senkron v2 Aşama 0–5 ve 7 üretimde
> **İlgili:** [docs/20 — Senkron v2](20-sync-v2.md) ·
> [docs/18 — Hesap ve senkron](18-auth-and-sync.md) ·
> [CONVENTIONS §7b](../CONVENTIONS.md)

---

## 0. Karar özeti

**Ne değişecek, neden.** Senkron v2, **tek kullanıcı (Samet) + otomatik saatli
telefon** varsayımıyla tasarlandı; bu varsayım docs/20'de açıkça yazılı
(§5.2: *"Tek kullanıcı, otomatik saat açık telefonlar için yeterli"*).
Uygulama abonelikle satılmaya başlandığında bu varsayım düşer. Üç şey
varsayımın üstünde duruyor ve **ilk ödeme yapan kullanıcıdan önce** kapanmalı:
cihaz saatine güvenen çakışma kuralı, sunucu ile istemcinin aynı anda
güncellendiğini varsayan yayın kuralı, ve aboneliğin bulut verisiyle ilişkisi.

**Önerilen seçenek.** (1) Cihaz saati yerine **sunucu saatiyle düzeltilmiş
damga**; (2) sunucuda **asgari istemci sürümü** + istemcide zorunlu güncelleme
ekranı; (3) abonelik bitince bulut verisinin **salt okunur** olması.
*Elenenler:* hibrit mantıksal saat (HLC) — doğru çözüm ama bu veri boyutunda
fazla, `server_rev` zaten toplam sıra veriyor; sunucunun damgayı tamamen kendi
atması — çevrimdışı düzenlemenin sırası bozulur, üç gün sonra senkronlanan
telefon taze düzenlemeyi ezer; abonelik bitince veri silme — geri dönüşü yok,
iade/yeniden abonelik akışını imkânsız kılar.

**Gerçek veriye etkisi.** (1) yalnız **damgalama anını** değiştirir, mevcut
satırlara dokunmaz; geri dönüş = düzeltmeyi kapatmak. (2) yeni bir sunucu
tablosu (`app_min_version`) ve yeni bir ekran; kullanıcı verisine dokunmaz.
(3) karar verilene kadar **kod yazılmaz** — ama şema sabitlenmeden
cevaplanmalı, çünkü "salt okunur" bir abonelik durumu alanı gerektirir.

**Kararlar (Samet, 2026-09-22).** Dördü de önerilen şekilde onaylandı: saat
farkı düzeltmesi, zorunlu güncelleme kapısı, abonelik bitince salt okunur veri.
Çoklu cihaz ilk sürümde **vaat edilmiyor** → Aşama 6 launch sonrasına kalıyor
(varsayım olarak kaydedildi; vaat değişirse sıra da değişir).

**Nasıl doğrulanacak.** Saat düzeltmesi: saati elle 2 saat geri alınmış bir
cihazda yapılan düzenleme sunucuda **kabul** edilmeli (bugün sessizce
reddediliyor) — `Fit Pack Dev`'de pgTAP + istemcide birim testi. Sürüm kapısı:
sunucudaki asgari sürüm yükseltilince eski istemci güncelleme ekranına
düşmeli. Üçü de cihazda duman testiyle kapanır.

---

## 1. Bağlam: varsayım neden düşüyor

docs/20 bilinçli olarak dar bir dünya varsaydı ve bunu yazdı. Tek kullanıcıda
doğru bir seçimdi: her varsayımı kapatmaya çalışmak epiği bitirmezdi. Ticari
ürüne geçerken düşen varsayımlar:

| Varsayım | Nerede yazılı | Ticari üründe ne olur |
|---|---|---|
| Kullanıcının telefonunda otomatik saat açık | docs/20 §5.2, §12 risk tablosu | Saati geride olan cihazın düzenlemesi **sessizce reddedilir** ve yerel kopya sunucununkiyle değiştirilir |
| Sunucu ve istemci aynı anda güncellenir | docs/20 §11 yayın kuralı | Mağaza güncellemesi kademeli yayılır; eski sürümdeki kullanıcı **yazamaz hale gelir** |
| Kullanıcı = hesap sahibi = geliştirici | docs/18 | Hatayı kullanıcı görmez, bildiremez; yalnız cihaz logunda kalır |

**Zaten tasarlanmış, yalnız kodlanmamış olanlar bu dokümanın kapsamı dışında**
(§6): su olay kaydı ve belirlenimci katalog kimliği docs/20'de onaylandı,
Aşama 6'da duruyor. Çekme tetikleyicileri (docs/20 §6.5) 2026-09-22'de
kodlandı.

---

## 2. Saat sapması — cihaz saatine güvenen çakışma kuralı

### 2.1 Bugün ne oluyor

`changed_at_ms` cihaz saatinden damgalanır. Sunucudaki `sync_guard`:

- **İleri sapma** kırpılır: `changed_at_ms > now + 5dk` ise `now`'a çekilir.
- **Geri sapma kırpılmaz.** Saati 2 saat geride olan telefon gerçek bir
  düzenleme yaptığında damga sunucudakinden küçük çıkar → `sync_guard` yazmayı
  atlar → istemci ret çözümünde **kendi satırını sunucudakiyle değiştirir**
  (docs/20 §5.1 adım 5).

Kullanıcı açısından sonuç: *"düzenlemem geri alındı"*. Logda görünür
(`N satır reddedildi`), **ekranda görünmez**.

Bu, ileri sapmadan daha sinsi: ileri sapma yanlış sürümün kazanmasına yol
açar (veri yanlış ama kullanıcının yazdığı bir şey), geri sapma kullanıcının
yazdığı şeyin kaybolmasına yol açar.

### 2.2 Önerilen: sunucu saatiyle düzeltilmiş damga

İstemci sunucu saatiyle arasındaki farkı öğrenir, `sync_meta`'da tutar ve
damgalarken uygular:

```
damga = cihaz_saati + sunucu_farki
```

**Fark nereden öğrenilir — ek tur atmadan.** Sunucu kabul ettiği her satıra
zaten `updated_at = now()` yazıyor (`sync_guard`, docs/20 §4.2). Gönderim
cevabındaki `RETURNING` projeksiyonuna `updated_at` eklenirse istemci fark
hesabını **bedavaya** yapar: `sunucu_farki = donen_updated_at - gonderim_ani`.
Bugün `AcceptedRow` yalnız `uid` + `server_rev` taşıyor; üçüncü alan eklenir.

*Elenen:* ayrı bir `select now()` RPC'si — her turda fazladan bir gidiş-dönüş.
*Elenen:* PostgREST cevabının `Date` başlığı — `supabase_flutter` katmanında
başlığa erişim dolaylı, kırılgan.

**Fark ne zaman uygulanır.** Yalnız |fark| bir eşiği (öneri: 30 sn) aşarsa;
küçük farklar zaten önemsiz ve her turda damgaları oynatmak `changed_at_ms`'i
gereksiz gürültülü yapar.

**Fark hiç öğrenilmemişse** (ilk kurulum, henüz gönderim olmamış) damga bugünkü
gibi cihaz saatinden atılır — ilk gönderim farkı öğretir.

### 2.3 Ayrıca: ret sessiz kalmamalı

Düzeltme sapmayı azaltır ama sıfırlamaz (kullanıcı saati senkron sırasında
değiştirebilir). Bu yüzden **ret görünür olmalı**: hesap ekranındaki durum
kartında "N kaydın sunucudaki daha yeni sürümü alındı" satırı. Kullanıcı
ne olduğunu anlayabilsin; destek bunu sorabilsin.

### 2.4 Kapsam dışı: hibrit mantıksal saat (HLC)

Local-first sistemlerin "doğru" cevabı HLC: her yazma (fiziksel saat, sayaç,
düğüm kimliği) üçlüsüyle damgalanır, saat sapması sıralamayı bozamaz. Burada
**gerekmiyor**: `server_rev` zaten sunucuda toplam bir sıra üretiyor ve çekme
onu kullanıyor; cihaz saati yalnız **çakışma kararında** devrede. Sunucu
farkı düzeltmesi o kararı yeterince sağlamlaştırıyor. Kullanıcı başına cihaz
sayısı artar ve çakışma sıklaşırsa yeniden değerlendirilir.

---

## 3. Sürüm uyumluluğu — asgari istemci sürümü

### 3.1 Bugünkü kural neden ticari üründe çalışmaz

docs/20 §11: *"Sunucu değişikliği olan aşamalarda sunucu ile telefon birlikte
güncellenmelidir."* Aşama 3 tam bunu yaşattı: sunucu tek başına güncellenseydi
eski istemcinin `changed_at_ms = 0` gönderen yazmaları sessizce reddedilirdi.

Tek kullanıcıda bu bir zamanlama meselesi (2026-09-22'de böyle yapıldı).
Mağazada **imkânsız**: güncelleme kademeli yayılır, kullanıcıların bir kısmı
haftalarca eski sürümde kalır, bir kısmı otomatik güncellemeyi kapatmıştır.

### 3.2 Önerilen: iki katmanlı kural

**Katman 1 — sunucu değişiklikleri yalnız eklemeli.** Zaten CONVENTIONS §3.8
kuralı; sunucu tarafı için açıkça yazılır: kolon eklenir (varsayılanla), kolon
silinmez, tip daraltılmaz, zorunlu hale getirilmez. Eski istemci yeni şemada
çalışmaya devam eder.

**Katman 2 — asgari sürüm kapısı.** Eklemeli yapılamayan bir değişiklik
gerektiğinde (ör. Aşama 6'nın birincil anahtar değişimi), sunucu desteklediği
en eski istemci sürümünü söyler; altındaki istemci kullanıcıyı **zorunlu
güncelleme** ekranına alır.

```sql
-- Herkese okunabilir, yalnız panelden yazılır.
create table public.app_min_version (
  platform    text primary key,   -- 'android' | 'ios'
  min_build   int  not null,
  message     text                -- kullanıcıya gösterilecek kısa açıklama
);
```

İstemci bunu açılışta okur (çevrimdışıysa **kapı kapanmaz** — docs/18 Kural 1:
ağ yokluğu kullanıcıyı kendi verisinden etmez; kapı yalnız sunucu "çok
eskisin" dediğinde devreye girer).

**Neden şimdi.** Kapının kendisi yarım günlük iş, ama **ilk sürümde bulunmak
zorunda**: sonradan eklenirse, kapıdan önceki sürümdeki kullanıcılar zaten
güncelleme zorlanamayacak kullanıcılardır.

---

## 4. Abonelik ve bulut verisinin yaşam döngüsü

Kodda satın alma / hak sahipliği (entitlement) katmanı **hiç yok**. Bu bir
ürün kararı, ama veri modelini etkilediği için burada duruyor.

Cevaplanması gereken soru: **abonelik biterse bulut verisine ne olur?**

| Seçenek | Kullanıcı deneyimi | Maliyet / risk |
|---|---|---|
| **Salt okunur** (öneri) | Veri durur, yeni kayıt buluta gitmez; yerelde çalışmaya devam eder; yeniden abone olunca kaldığı yerden | Depolama maliyeti sürer; sunucuda "yazma kapalı" durumu gerekir |
| Dondur + N ay sonra sil | Depolama sınırlı | "Verim silindi" şikâyeti; KVKK/GDPR bildirim yükümlülüğü; geri dönüşü yok |
| Hemen sil | Maliyet yok | Kabul edilemez — iade, ödeme sorunu, kart yenileme gecikmesi hep veri kaybına dönüşür |

**Öneri: salt okunur.** Fitness verisi biriktikçe değerlenir; "geri dönersem
geçmişim duruyor" aboneliği yenilemenin en güçlü sebebi. Yerel öncelikli
mimari bunu zaten destekliyor: abonelik bitince senkron durur, uygulama
yerelde tam çalışır.

Karar verilirse gereken: profilde abonelik durumu alanı, sunucuda yazmayı
kapatan bir RLS koşulu, ve istemcide "aboneliğin bitti, verilerin duruyor"
mesajı. **Bu dokümanda kodlanmıyor** — karar çıkınca ayrı bir doküman.

---

## 5. Kararlar ve açık sorular

| # | Konu | Durum | Karar |
|---|---|---|---|
| 1 | Saat düzeltmesi yaklaşımı | ✅ **Karar (Samet, 2026-09-22)** | §2.2 — gönderim cevabından sunucu farkı, 30 sn eşik. *Elenenler:* hiçbir şey yapmama, HLC (şimdilik fazla) |
| 2 | Asgari sürüm kapısının sertliği | ✅ **Karar (Samet, 2026-09-22)** | §3.2 — zorunlu güncelleme. *Elenen:* kapatılabilir uyarı şeridi — nazik ama bozuk istemciyi sahada bırakır |
| 3 | Abonelik bitince bulut verisi | ✅ **Karar (Samet, 2026-09-22)** | §4 — salt okunur. Kodlaması ayrı iş; satın alma katmanı geldiğinde |
| 4 | İlk sürümde çoklu cihaz vaadi | ✅ **Varsayım (2026-09-22)** | Vaat **edilmiyor** → Aşama 6 (katalog kimliği + su olay kaydı) launch sonrasına kalıyor. Vaat değişirse sıra da değişir |

---

## 6. Kapsam dışı — zaten karara bağlanmış işler

Bu doküman **yeni** karar gerektiren şeyleri kapsar. Aşağıdakiler docs/20'de
onaylandı, yalnız kodlanmayı bekliyor; buraya kopyalanmaz:

- **Su olay kaydı** — docs/20 §8, Karar 5 ✅. İki cihazın aynı gün su eklemesi
  bugün birbirini eziyor. Aşama 6.
- **Belirlenimci katalog kimliği** — docs/20 §7.2, Karar 6 ✅. İkinci cihaz
  tohum katalogunu çiftliyor. Aşama 6.
- **Çekme tetikleyicileri** — docs/20 §6.5. **2026-09-22'de kodlandı**
  (öne gelme + "Şimdi eşitle"), 10 test.

Bu dokümanda **bilinçli olarak ele alınmayanlar** (launch öncesi son haftaya):

- **Arka plan senkronu** (WorkManager / BGTaskScheduler). Uygulama açıkken
  gönderim canlı, öne gelmede de tetikleniyor → pencere dar. Kapatılması
  gereken durum: çevrimdışı kayıt girip uygulamayı bir daha hiç açmamak.
- **Ağ geri geldiğinde tetikleme** (`connectivity_plus`). Yeni paket
  bağımlılığı; öne gelme tetikleyicisi vakaların çoğunu zaten yakalıyor.
- **Sunucu tarafı senkron telemetrisi.** İlk 50 kullanıcıda cihazdaki
  "Son yedekleme" göstergesi yeterli.
