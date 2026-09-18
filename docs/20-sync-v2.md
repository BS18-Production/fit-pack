# 20 — Senkron v2: Veri Bütünlüğü Tasarımı

> **Durum:** Tasarım taslağı — Samet'in onayını bekliyor. **Kod yazılmadı.**
> **Revizyon 2026-09-17 (Samet'in soruları sonrası):** silme her zaman kazanır;
> sunucuda silinen satır gerçekten silinir, yerine `deleted_records` işareti
> kalır; katalog kimliği (eski Aşama 8) ana akışa alındı; sunucu testleri yerel
> Docker ile. Kararlar §13'te.
> **Tarih:** 2026-09-17 · **Yazan:** Claude (gece görevi)
> **Temel:** `6009362` (main) · şema **v10** · Supabase `jkviihbyogktwboreydn`
> **Önceki doküman:** [docs/18 — Zorunlu hesap + senkron](18-auth-and-sync.md)
> **Kaynak bulgular:** [CODE_REVIEW.md § Dış İnceleme](../CODE_REVIEW.md) (#1–#9, E-15),
> NEXT_TASKS "Senkron v2" + "Açılışta Karşılama ekranı" + "Supabase duraklatma"

Bu doküman **neyin, neden, hangi sırayla** değişeceğini anlatır. Kısaltmalar ilk
geçtikleri yerde açıldı; sonda küçük bir sözlük var (§14).

---

## 0. Karar özeti (bir sayfa — teknik ayrıntı §1'den itibaren)

**Ne değişecek, neden.** Telefon ile bulut arasındaki eşitleme bugün dört
konuda hatalı: silme diğer cihaza gitmiyor, sürüm damgası saniyelik olduğu
için aynı saniyedeki iki değişiklikte yanlış kayıt kazanıyor, sunucuda
çakışma çözümü yok ve çekme sayfalanmıyor. Sonuç: **sildiğin kayıt geri
gelebiliyor, düzenlemen sessizce kaybolabiliyor.** Aynı hesabı iki cihazda
(telefon + iOS) kullandığın için bu teorik değil.

**Önerilen seçenek.** Üç ayrı sayaç (çakışma için milisaniyelik damga,
gönderim onayı için yerel sıra numarası, çekme için sunucu sürümü); çakışma
kararı **sunucuda** verilir; silme kalıcı bir işaret bırakır ve **her zaman
kazanır**. *Elenenler:* yalnız istemci tarafında çakışma çözümü (iki cihaz
aynı anda yazınca yine kayıp), tam yeniden indirme (veri büyüdükçe pahalı).

**Gerçek veriye etkisi.** Mevcut kayıtlar yerinde kalır; göç yalnız kolon
ekler ve mevcut zaman damgalarını milisaniyeye çevirir (S-18 kayıpsız göç
testi). Sunucuda önce yedek alınır. **Geri dönüş:** yeni kolonların
varsayılanı olduğu için eski uygulama sürümü şemayla çalışır; ancak
Aşama 3'ten sonra eski istemcinin yazmaları sunucuda **reddedilir** — bu
yüzden 3 ve 4 aynı sürümde yayınlanır (§11).

**Samet'ten gereken kararlar.** §13'teki 7 sorunun tamamı 2026-09-17'de
cevaplandı (ücretli plan: hayır · silme kazanır · gönderilmemiş kayıtta
seçim sunulur · işaretler süresiz · su olay kaydına döner · katalog kimliği
bu işe dahil · sunucu testleri yerel Docker). Yeni karar gerekmiyor.

**Nasıl doğrulanacak.** 18 yerel + sunucu testi (§10): silme yayılımı,
çakışmada son yazan kazanır, sayfalama, reddedilen yazma, hesap izolasyonu,
v10 → v11 kayıpsız göç. Cihazda duman testi: her aşama sonunda açılış + bir
kayıt + senkron. Ölçüt: iki cihazda silinen kayıt geri gelmiyor, bekleyen
kayıt sayısı sıfıra iniyor.

---

## 1. Problem — bugün ne bozuk?

Senkron (cihaz ↔ Supabase eşitleme) canlıda çalışıyor, ama **veri
bütünlüğünü** (verinin doğru, eksiksiz ve tutarlı kalmasını) garanti etmiyor.
Dış inceleme 7 kritik açık buldu; hepsi kodda doğrulandı. Kullanıcı gözünden:

| Kullanıcının göreceği | Bulgu | Kod kanıtı |
|---|---|---|
| **Sildiğim öğün/ölçüm/antrenman bir sonraki açılışta geri geliyor.** Tek cihazda bile. | #1 | `SyncRemote`'ta silme yok (`sync_push.dart:27`); yerel `delete` çağrıları (`nutrition_dao.dart:242`, `body_dao.dart:39`, `workout_dao.dart:224-229`) sunucuya hiç gitmiyor; `bootstrap()`'taki arka plan çekmesi sunucudaki satırı geri ekliyor. |
| Rutini her düzenlediğimde sunucuda rutin hareketleri **çoğalıyor**. | #1 | `saveRoutineWithExercises` önce siliyor sonra yeniden ekliyor (`workout_dao.dart:77-91`) → her kayıt yeni `uid`'li satırlar. |
| Aynı saniye içinde iki kez düzenlediğim kayıt **sessizce yüklenmiyor**. | #3 | Sürüm damgası saniye çözünürlüğünde (`sync_columns.dart:175,191`); `_markClean` `updated_at IS ?` ile karşılaştırıyor (`sync_push.dart:221`). |
| Çevrimdışı telefondaki **eski** düzenleme, diğer cihazdaki **yeni** düzenlemenin üstüne yazıyor. | #4 | `upsert(onConflict: 'uid')` koşulsuz (`supabase_sync_remote.dart:22`); çakışma kuralı yalnız çekmede var. |
| Geçmişi büyük kullanıcıda veri **eksik iniyor**, hata da çıkmıyor. | #5 | `select()` sayfalamasız (`supabase_sync_remote.dart:26`); PostgREST (Supabase'in REST katmanı) varsayılan olarak 1.000 satırda kesiyor. `workout_sets` ~50 seansta bu sınıra gelir. |
| Veri çekilirken girdiğim kayıt **hiç yüklenmiyor**; uygulama o anda kapanırsa senkron **kalıcı olarak** bozuluyor. | #2 | Çekme, ağ beklemesi boyunca 24 tetikleyiciyi (trigger) siliyor (`sync_pull.dart:82-95`); `beforeOpen` tetikleyicileri onarmıyor (`app_database.dart:305`). |
| Aynı telefonda ikinci hesapla girince **öncekinin verisini görebilme** ihtimali; hesap değişince **gönderim kuyruğu kilitleniyor**. | #6, #7 | `bootstrap()` hesap kontrolünü atlıyor (`auth_gate.dart:100-109`); `_applyAccount` hatasında kapı yine de içeri alıyor (`gateRedirect` hata durumunu bilmiyor); katalog satırı eski kullanıcının `uid`/`user_id`'siyle kalıyor (`account_switch.dart:62-70`) → yeni kullanıcının gönderimi RLS'e (satır düzeyi güvenlik) takılıp kuyruğu durduruyor. |
| Çekmeden sonra bazı ekranlar **bayat** kalıyor. | #9 | Çekme ham `customStatement` kullanıyor → Drift değişikliği bilmiyor; elle tazelenen 8 provider var, kodda 23 `watchTables` var (`auth_gate.dart:202-214`). |
| İki cihazdan aynı gün su eklenince **çift satır**. | #8 | `water_intake`'te gün başına tekillik yok (yerel yarısı 2026-09-15'te toplayarak okuma ile yumuşatıldı). |

**Ek gözlemler (2026-09-16):**

- **Açılışta birkaç saniye Karşılama ekranı** — oturum açıkken bile. Router
  `initialLocation: welcome`; `bootstrap()` `_appliedUserId`'yi bir `await`'ten
  SONRA atıyor → arada gelen oturum olayı `_applyAccount`'u tetikliyor →
  `busy=true` iken `gateRedirect` karar vermiyor → çekme ağda bekledikçe
  "Hesap oluştur" görünüyor. Kural 1'e (açılış ağa bağlı değil) aykırı.
- **Supabase ücretsiz planı projeyi duraklattı.** Duraklatılmış projenin alt
  alan adı çözülmüyor; ev modemi var olmayan adresleri kendine yönlendirdiği
  için uygulamada `CERTIFICATE_VERIFY_FAILED` göründü. Senkron sessizce durdu,
  arayüz "verilerin güncel" demeye devam etti.
- **Android'de oturum düştü:** Temmuz'dan kalan yenileme anahtarı sunucuda
  bulunamadı (`refresh_token_not_found`). Kütüphane oturumu kapattı; yerel veri
  kaldı. Bu sırada **gönderilmemiş kayıt** olsaydı ve başka hesapla girilseydi,
  hesap değişimi temizliği onları **silerdi** (bkz. §7.4).
- **Testler yanlış şeyi ölçüyor (E-15):** `sync_push_test` T-5 düzenlemeyi
  `pushAll` bittikten SONRA yapıyor (uçuştaki yarış sınanmıyor); T-1 dosyayı
  kapatıp açmıyor (süreç ölümü sınanmıyor).

### 1.1 Kök nedenler

Yedi bulgu dört eksikten doğuyor. Tek tek yamamak aynı varsayımı dört yerde
yeniden kurmak olurdu; bu doküman dördünü birlikte çözer.

| Kök eksik | Bulgular | Çözüm bölümü |
|---|---|---|
| **Satır sürümü yok** — saniyelik `updated_at` sürüm yerine kullanılıyor | #3, #4 | §4.1, §5.1 |
| **Silme protokolü yok** | #1 | §4.2, §5.3 |
| **Çekme, ağ beklemesini yazma penceresinden ayırmıyor** | #2, #5, #9 | §6 |
| **Sahiplik modeli belirsiz** — ortak katalog kullanıcıya bağlanıyor | #6, #7 | §7 |

---

## 2. Hedefler ve hedef dışı

### Hedefler (kabul edilebilir "bitti")

1. **Silinen kayıt silinmiş kalır** — tüm cihazlarda, çevrimdışı dönüşlerde de.
2. **Hiçbir yerel düzenleme sessizce kaybolmaz** — aynı milisaniyede olsa bile.
3. **Eski yazma yeniyi ezmez** — çakışmada hangi sürümün kazanacağı tek ve
   açıklanabilir bir kurala bağlı (§5.2).
4. **Çekme her zaman tam** — satır sayısından bağımsız; kesilirse hata verir,
   sessiz kalmaz.
5. **Senkron kendini onarır** — uygulama herhangi bir anda öldürülse bile bir
   sonraki açılışta tetikleyiciler ve bayraklar doğru durumdadır.
6. **Hesaplar birbirinin verisini görmez**; hesap değişimi kuyruğu kilitlemez;
   gönderilmemiş veri sessizce silinmez.
7. **Kullanıcı senkronun gerçekten çalışıp çalışmadığını görür** — "son
   yedekleme" zamanı; sunucuya günlerce ulaşılamıyorsa uyarı.
8. **Açılış ağa bağlı değil** — oturum açıkken Karşılama ekranı hiç görünmez.

### Hedef dışı (bu sürümde yok)

- **Alan bazında birleştirme** (aynı satırın farklı alanlarını iki cihazdan
  birleştirmek). Çakışmada satır bütün olarak kazanır (§5.2). Uygulama büyük
  ölçüde ekleme ağırlıklı; tek kullanıcı, az cihaz.
- **Gerçek zamanlı (anlık) senkron** — Supabase Realtime. Açılışta + yazmadan
  sonra + periyodik çekme yeterli.
- **İlerleme fotoğrafı dosyaları** — docs/19'un konusu (Storage). Bu doküman
  yalnız `progress_photos` **satırının** senkronunu kapsar.
- **Çok kullanıcılı paylaşım** (antrenör/öğrenci). Veri modeli buna kapıyı
  kapatmıyor (§7.2) ama tasarlanmadı.
- **Yerel birincil anahtarların UUID'ye göçü** — docs/18 §4 kararı (integer
  `id` yerelde kalır, `uid` sunucu kimliği) korunuyor.

---

## 3. Temel kararlar (özet)

| # | Karar | Neden |
|---|---|---|
| K-1 | **Üç ayrı sayaç:** `changed_at_ms` (istemci, milisaniye — çakışma), `local_seq` (cihaz içi artan sayı — gönderim onayı), `server_rev` (sunucunun verdiği artan sayı — çekme imleci) | Her biri tek bir soruyu cevaplar; birini ötekinin yerine kullanmak bugünkü hataların kaynağı. |
| K-2 | **Çakışma kuralı sunucuda**, Postgres tetikleyicisiyle: gelen satır sunucudakinden eskiyse güncelleme **yapılmaz** | Uygulama güncellense de güncellenmese de kural sunucuda geçerli; PostgREST `upsert` aynen kullanılabilir. |
| K-3 | **Silme = yerel gerçek silme + mezar taşı (tombstone) kaydı**; sunucuda da **satır gerçekten silinir**, yerine küçük bir işaret (`deleted_records`) kalır. **Silme her zaman kazanır.** | Yerelde 20+ sorguya "silinmemiş olanlar" filtresi eklemek gerekmez (unutulan filtre = hayalet veri). İşaret öteki cihazlara silmeyi taşır; silinen **içerik** sunucuda kalmaz (KVKK / kişisel veri). |
| K-4 | **Tetikleyiciler çalışma anında hiç silinmez.** Yakalamayı bir bayrak (`sync_meta.capture`) açıp kapatır; bayrak yazma işlemiyle aynı transaction'da değişir | Uygulama ölürse transaction geri alınır, bayrak açık kalır. #2'nin kalıcı bozulma riski kökten kalkar. |
| K-5 | **Çekme iki aşamalı:** önce ağdan sayfa sayfa indir (veritabanına dokunmadan), sonra kısa transaction'larla uygula | Ağ beklemesi yazma penceresinden ayrılır (#2); sayfalama (#5) doğal olarak gelir. |
| K-6 | **Sunucuda birincil anahtar `(user_id, uid)`** | Aynı `uid` iki kullanıcıda bulunabilir; hesap değişimi RLS'e takılmaz (#7). |
| K-7 | **Su = olay kaydı** (her "+250 ml" ayrı satır, günlük toplam = toplam) | Tekillik kısıtı iki cihazda aynı gün eklemeyi kilitlerdi; olay kaydında çakışma hiç olmaz (#8). |
| K-8 | **Çekme sonrası Drift'e değişiklik bildirilir** (`notifyUpdates`) | Elle tazeleme listesi kalkar; 23 akışın hepsi kendiliğinden tazelenir (#9). |

---

## 4. Veri modeli

### 4.1 Yerel şema v11 (Drift / SQLite)

**Yıkıcı değil (ADR-007):** yalnız kolon ve tablo **eklenir**. Tetikleyiciler
yeniden kurulur (tetikleyici veri değildir).

**Senkron edilen 12 tablonun her birine:**

| Kolon | Tip | Anlamı |
|---|---|---|
| `changed_at_ms` | `INTEGER NULL` | Son yerel değişikliğin zamanı, **milisaniye**. Çakışma kuralı buna bakar. Göçte `updated_at * 1000` ile doldurulur. |
| `local_seq` | `INTEGER NULL` | Cihazdaki her yazmada artan sayı. "Gönderdiğim sürüm hâlâ aynı mı?" sorusunun cevabı (#3). |
| `server_rev` | `INTEGER NULL` | Bu satırın en son görülen sunucu sürümü. `NULL` = hiç gönderilmedi. |

`updated_at` (saniye) **kalır** — ekranlarda ve eski kodda kullanılıyor;
yalnız artık sürüm olarak kullanılmaz.

**Yeni tablo `sync_meta`** (anahtar–değer):

| Anahtar | Değer | Anlamı |
|---|---|---|
| `capture` | 0/1 | Tetikleyiciler yazmaları kuyruğa alsın mı (K-4). Varsayılan 1. |
| `next_seq` | tamsayı | Bir sonraki `local_seq`. |
| `cursor:<user>:<table>` | tamsayı | O kullanıcı için o tablonun son çekilen `server_rev`'i. |
| `last_push_ok_at`, `last_pull_ok_at` | ms | Son başarılı gönderim/çekme — "Son yedekleme" satırı (C-36). |
| `last_server_error_at`, `server_unreachable_since` | ms | Ulaşılamama süresi (§9). |
| `switch_in_progress` | kullanıcı kimliği | Hesap değişimi temizliği yarıda kaldıysa (§7.3). |

**Yeni tablo `sync_tombstones`** (mezar taşları):

| Kolon | Anlamı |
|---|---|
| `id` | yerel artan anahtar |
| `table_name` | silinen satırın tablosu |
| `uid` | silinen satırın sunucu kimliği |
| `changed_at_ms` | silme zamanı |
| `local_seq` | gönderim onayı için |

**Tetikleyiciler (v11):**

- `*_sync_ins` / `*_sync_upd`: bugünküyle aynı iş + `local_seq = next_seq`
  (ve `next_seq`'i artır) + `changed_at_ms = şimdi (ms)`. Koşula
  `capture = 1` eklenir.
- **Yeni** `*_sync_del` (AFTER DELETE): `OLD.uid` varsa ve satır sunucuya
  gitmiş olabilecekse (`OLD.server_rev IS NOT NULL OR OLD.user_id IS NOT NULL`
  ya da katalog dışı tablo) `sync_tombstones`'a bir satır yazar. Koşul:
  `capture = 1`. **Hiç kullanılmamış seed katalog satırı** mezar taşı üretmez.
- SQLite'ta yabancı anahtar zinciriyle silinen satırlar da AFTER DELETE
  tetikleyicisini çalıştırır → seans silinince setlerin mezar taşları da oluşur.
- Milisaniye: `CAST((julianday('now') - 2440587.5) * 86400000 AS INTEGER)`.

**Göç adımı `from < 11`:**
1. `sync_meta`, `sync_tombstones` tablolarını oluştur; `capture=1`,
   `next_seq = 1`.
2. 12 tabloya üç kolonu `_addColumnIfMissing` ile ekle.
3. `changed_at_ms = updated_at * 1000` (yalnız NULL olanlar).
4. `server_rev`: bugün temiz olan (`sync_state = 0` ve `user_id` dolu) satırlar
   için **0** (= "sunucuda var ama sürümü bilinmiyor"); diğerleri NULL.
5. Eski tetikleyicileri düşür, v11 tetikleyicilerini kur.
6. Göç testi aynı commit'te: v10 → v11 kayıpsız + 36 tetikleyicinin varlığı.

### 4.2 Sunucu şeması (Supabase / Postgres) — `supabase/03_sync_v2.sql`

**Her senkron tablosuna:**

| Kolon | Tip | Anlamı |
|---|---|---|
| `changed_at_ms` | `bigint not null default 0` | İstemcinin gönderdiği değişim zamanı. |
| `server_rev` | `bigint not null` | Ortak bir diziden (`sync_rev_seq`) her kabul edilen yazmada yeni değer. |

**Yeni tablo `deleted_records`** (silme işaretleri — satırın içeriği YOK):

| Kolon | Anlamı |
|---|---|
| `user_id` | sahibi (RLS) |
| `table_name` | silinen satırın tablosu |
| `uid` | silinen satırın kimliği |
| `deleted_at_ms` | silme zamanı |
| `server_rev` | aynı diziden — çekme imleci bunu da okur |

Anahtar: `(user_id, table_name, uid)`. Her senkron tablosunda **AFTER DELETE**
tetikleyicisi bu tabloya işaret yazar — sunucudaki zincirleme silmeler
(`workout_sets.session_uid ... on delete cascade`) de otomatik işaret üretir.

**Birincil anahtar:** `uid` → `(user_id, uid)` (K-6). Tablolar arası iki
yabancı anahtar (`workout_sets.session_uid`, `recipe_items.recipe_uid`) de
`(user_id, *_uid)` → `(user_id, uid)` biçimine geçer. Bugün sunucuda yalnız
Samet'in verisi var → anahtar değişimi veri kaybetmeden yapılır (önce yedek).

**Dizin:** `(user_id, server_rev)` — çekme imleci bununla sayfalar.

**Tetikleyici `sync_guard` (BEFORE INSERT OR UPDATE, her tablo):**

> **Uygulandı (2026-09-18).** Kesin SQL:
> `supabase/migrations/20260918120000_sync_v2_stage3.sql`. Aşağıdaki taslaktan
> **iki sapma** var, ikisi de bilinçli:
> 1. **Eşit damga reddedilir** (`<=`, taslakta `<`). §5.2'nin kuralı budur:
>    eşitlikte sunucu kazanır. Taslak koddaki `<` istemciyi kazandırıyordu.
>    Ayrıca zaman aşımı sonrası aynı satırın yeniden gönderimi `server_rev`'i
>    boşuna artırmaz, öteki cihaz onu gereksiz yere indirmez.
> 2. **`updated_at` sunucu saatinden yazılır.** İstemcinin saati saparsa v1
>    çekmesinin (`updated_at` imleci) satırı kaçırmasını önler.
>
> `deleted_records` tablosu da bu aşamada kuruluyor (Aşama 5 yerine): tetikleyici
> zaten ona bakıyor, ayrıca kurmak fonksiyonu iki kez yazmak olurdu. İşareti
> **yazan** silme tetikleyicileri ve `sync_delete` RPC'si Aşama 5'te gelir.

```sql
-- Taslak (yukarıdaki iki sapmayla birlikte uygulandı).
create or replace function public.sync_guard() returns trigger
language plpgsql as $$
begin
  -- Saat sapmasına karşı: gelecekten gelen damga şimdiye kırpılır.
  if new.changed_at_ms > (extract(epoch from now()) * 1000)::bigint + 300000 then
    new.changed_at_ms := (extract(epoch from now()) * 1000)::bigint;
  end if;
  -- K-3: silinmiş kimlik HİÇBİR yazmayla geri gelmez (silme kazanır).
  if exists (select 1 from public.deleted_records d
              where d.user_id = new.user_id
                and d.table_name = tg_table_name
                and d.uid = new.uid) then
    return null;
  end if;
  if tg_op = 'UPDATE' then
    -- K-2: gelen sürüm sunucudakinden eskiyse güncellemeyi ATLA.
    if new.changed_at_ms < old.changed_at_ms then
      return null;
    end if;
  end if;
  new.server_rev := nextval('public.sync_rev_seq');
  return new;
end $$;
```

Postgres'te BEFORE tetikleyicisi `NULL` dönerse o satırın yazması atlanır ve
`RETURNING` sonucunda o satır **görünmez** — istemci hangi satırların kabul
edildiğini buradan anlar (§5.1).

**Silme RPC'si** (RPC = sunucuda çalışan fonksiyon çağrısı) `sync_delete(p_table text, p_items jsonb)`:
`SECURITY INVOKER` (RLS geçerli); öğelerdeki `uid`'leri **gerçekten siler**;
işaretleri AFTER DELETE tetikleyicisi yazar. Satır sunucuda yoksa işaret
yazılmaz (hiç gönderilmemiş satırın silinmesi bilgi taşımaz). Tablo adı sabit
bir listeye karşı doğrulanır (SQL enjeksiyonuna kapı yok).

**RLS:** değişmez (`auth.uid() = user_id`). GRANT'lar değişmez;
`sync_delete` için `grant execute ... to authenticated`.

**Operatör panelleri** (`tools/admin/*.html`) doğrudan SQL okuyor; silinen
satır gerçekten silindiği için **ek filtre gerekmez**.

---

## 5. Gönderim (push) protokolü v2

### 5.1 Yazmalar

```
1. Kuyruktan oku:  sync_state = 1, ORDER BY local_seq LIMIT 200
2. JSON'a çevir:   bugünkü _rowToJson + changed_at_ms (server_rev GİTMEZ)
3. Gönder:         upsert(rows, onConflict: 'user_id,uid')
                     .select('uid, server_rev, changed_at_ms')
4. Kabul edilenler (dönen satırlar):
     UPDATE ... SET sync_state = 0, server_rev = ?, user_id = ?
      WHERE uid = ? AND local_seq = <gönderdiğim local_seq>
   → gönderim sırasında satır düzenlendiyse local_seq değişmiştir,
     satır kuyrukta KALIR (#3 çözülür; saniye/milisaniye önemsiz).
5. Reddedilenler (dönmeyen satırlar = sunucu daha yeni):
     sunucudaki sürümü uid ile çek → yerele uygula (çekme kuralıyla, §6.2)
     → satır temiz olur. Reddedilen satır sonsuza kadar tekrar gönderilmez.
```

### 5.2 Çakışma kuralı

**"Değişim zamanı daha yeni olan kazanır" (LWW — last writer wins),
satır bütün olarak.** Karşılaştırma `changed_at_ms` üzerinden, **sunucuda**.

| Durum | Sonuç |
|---|---|
| Yerel düzenleme, sunucudan yeni | Yerel kazanır (gönderimde kabul) |
| Yerel düzenleme, sunucudan eski (çevrimdışı eski telefon) | Sunucu kazanır (gönderimde ret → yerel sunucununkiyle değişir) — **#4 çözülür** |
| Silme ile düzenleme (hangisi yeni olursa olsun) | **Silme kazanır** — düzenleme atılır (§13 Karar 2) |
| Eşit zaman | Sunucu kazanır (tekrar gönderim zararsız kalsın) |

**Saat sapması:** damgalar cihaz saatinden gelir. Tek kullanıcı, otomatik saat
açık telefonlar için yeterli; gelecekten gelen damga sunucuda kırpılır (§4.2).

### 5.3 Silmeler (mezar taşları)

```
1. sync_tombstones'u tablo sırasının TERSİNE göre oku (çocuk önce)
2. sync_delete(table, [{uid, changed_at_ms}]) çağır
3. Onay gelince mezar taşı satırını yerelde sil (local_seq kontrolüyle)
```

- Mezar taşları **yazmalardan SONRA** gönderilir: aynı turda "ekle + sil"
  olan satır sunucuda önce oluşup sonra silinmiş olur (tutarlı).
- **"Geri al" yeni kimlikle ekler** — bugünkü davranış
  (`nutrition_screen.dart:69-84`) doğru ve korunur. Silme her zaman kazandığı
  için eski `uid` bir daha kullanılamaz; "Geri al" silinen kaydın **kopyasını**
  yeni `uid` ile oluşturur. Gönderim 2 sn sonra gittiği için bu, silme
  sunucuya ulaşmış olsa da doğru çalışır.

### 5.4 Rutin kaydetme — fark uygulaması

`saveRoutineWithExercises` "hepsini sil, yeniden ekle" yerine **farkı**
uygular: eşleşen satır (aynı hareket + sıra) güncellenir, eksilen silinir
(mezar taşı), yeni olan eklenir. Mezar taşlarıyla eski yöntem de *doğru*
çalışırdı; fark uygulaması gereksiz silme/ekleme trafiğini ve sunucudaki
mezar taşı birikimini önler.

---

## 6. Çekme (pull) protokolü v2

### 6.1 İki aşama

```
AĞ AŞAMASI (veritabanına dokunmaz, tetikleyiciler AÇIK)
  önce deleted_records (imleç: cursor:<user>:deleted), sonra
  her tablo için, bağımlılık sırasıyla:
    imleç = sync_meta[cursor:<user>:<table>]  (yoksa 0)
    döngü:
      select * where user_id = ? and server_rev > imleç
               order by server_rev limit 500
      sayfa boşsa dur; imleç = son satırın server_rev'i
      sayfa < 500 ise son sayfa → dur

UYGULAMA AŞAMASI (sayfa başına kısa transaction)
  BEGIN
    sync_meta.capture = 0
    her satır için §6.2
    sync_meta[cursor] = sayfanın son server_rev'i
    sync_meta.capture = 1
  COMMIT
  → Drift'e bildir: notifyUpdates(tablo)
```

- **Ağ beklemesi sırasında kullanıcı yazarsa** tetikleyiciler açık → yazma
  kuyruğa girer (#2 çözülür).
- **Uygulama transaction ortasında ölürse** transaction geri alınır: bayrak 1,
  imleç eski değerde → bir sonraki çekme o sayfayı tekrar indirir (idempotent).
- **Sayfalama `server_rev` üzerinden** (anahtar tabanlı): sayfalar arasında
  yeni satır eklense de satır atlanmaz ya da iki kez gelmez (#5 çözülür).
  Sayfa boyu 500 < PostgREST sınırı 1.000 → sunucu sessizce kesemez; yine de
  "istenen 500, gelen 1.000'den fazla olamaz" türünden bir tutarlılık
  kontrolü eklenir.
- **Artımlı:** ilk girişte imleç 0 → tam çekme; sonrakilerde yalnız
  değişenler. Bugünkü "her açılışta her şeyi indir" maliyeti kalkar.
- **Ebeveyn–çocuk:** ebeveyn tablo tamamen uygulanmadan çocuk tablo
  uygulanmaz. Referansı çözülemeyen satır (ebeveyni hiç inmemiş) atlanır ama
  **imleç yine ilerler**; atlanan satırın `uid`'si `sync_meta`'daki "bekleyen
  referans" listesine yazılır ve sonraki turda yalnız o satırlar yeniden
  istenir. İmleç durdurulsaydı tek bozuk satır bütün tabloyu kilitlerdi.

### 6.2 Satır uygulama kuralı

| Sunucu satırı | Yerelde | Yapılan |
|---|---|---|
| silme işareti | yok | hiçbir şey |
| silme işareti | var (temiz ya da kirli) | **yerelde sil** (capture=0 → mezar taşı üretmez); bekleyen düzenleme atılır |
| canlı | yok ve yerelde mezar taşı var | **ekleme** (yerel silme gönderilecek, silme kazanır) |
| canlı | yok | ekle |
| canlı | var, yerel temiz | sunucununkini yaz |
| canlı | var, yerel kirli | `changed_at_ms` karşılaştır (§5.2) |

Profil (tek satır) ve katalog "isimle benimseme" kuralları bugünkü gibi kalır
(§7.2'deki opsiyonel aşamaya kadar).

### 6.3 Reaktif yayılım (#9)

Uygulama aşamasından sonra `db.notifyUpdates({TableUpdate.onTableName(t)})`.
`authGateProvider`'daki elle `invalidate` listesi kaldırılır. Test: çekmeden
sonra `watchTables` kullanan bir akışın yeni değeri vermesi.

### 6.4 Tetikleyici bütünlüğü (açılışta onarım)

`beforeOpen`: `sqlite_master`'da 36 tetikleyicinin varlığı kontrol edilir;
eksik varsa tek kaynaktan yeniden kurulur ve günlüğe yazılır; `capture`
değeri 1'e çekilir. Böylece hiçbir hata yolu senkronu kalıcı olarak bozamaz.

### 6.5 Ne zaman çekilir?

- Girişte (tam ya da artımlı)
- Uygulama öne geldiğinde, son çekmeden 5 dakikadan fazla geçtiyse
- Gönderimde ret alındığında (yalnız o satırlar)
- Kullanıcı hesap ekranında "Şimdi eşitle"ye bastığında

---

## 7. Hesap izolasyonu

### 7.1 Açılış (#6 + Karşılama ekranı)

1. `bootstrap()` ilk iş olarak `currentUserId`'yi okur ve `_appliedUserId`'yi
   **ilk `await`'ten önce** atar → başlangıç oturum olayı gereksiz hesap
   kontrolü tetiklemez.
2. `bootstrap()` **yerel** hesap kontrolünü yine de çalıştırır
   (`AccountSwitchGuard.apply` — ağ gerektirmez, "aynı kullanıcı" durumunda
   anında döner). Bugün bu adım atlanıyor.
3. Router'ın başlangıç konumu sabit `welcome` değil,
   `gateRedirect`'in bootstrap sonucu verdiği konum.
4. Kapı "meşgul" iken Karşılama değil **nötr açılış ekranı** (logo) gösterilir.
5. Çekme hiçbir koşulda kapı kararını bekletmez (Kural 1).

### 7.2 Katalog sahipliği (#7)

- Sunucu anahtarı `(user_id, uid)` olduğu için aynı seed hareketi iki
  kullanıcıda aynı `uid` ile bulunabilir → yeni kullanıcının gönderimi eski
  kullanıcının satırına çarpmaz.
- Hesap değişiminde katalog satırları silinmez ama **kişiselleştirmesi
  sıfırlanır**: `user_id = NULL`, `server_rev = NULL`, `sync_state = 0`.
- **Belirlenimci katalog kimliği (Aşama 6'da — Samet: "şimdi"):** seed
  katalog satırlarının `uid`'si cihazda rastgele üretilmez, **isimden
  hesaplanır** (UUIDv5 — aynı girdiden hep aynı UUID'yi üreten sürüm).
  Başlangıç verisinde sabit bir kaynak kimliği yok, tek sabit anahtar isim;
  ölçüldü: 1015 hareketin ve 111 besinin isimleri tekil (büyük/küçük harf ve
  boşluk farkı dahil). Girdi: `"fitpack:exercise:" + küçük harfe çevrilmiş,
  kırpılmış isim` (besinde `"fitpack:food:"`).
  1. **Yerel göç:** `is_custom = 0` satırların `uid`'si yeni değere çevrilir;
     eski→yeni eşleşmesi yerel `uid_remap` tablosuna yazılır. Yerel ilişkiler
     tamsayı `id` ile kurulu olduğu için başka hiçbir şey değişmez.
  2. **Sunucu eşlemesi:** bir sonraki gönderimden önce `sync_remap_uids(p_table,
     p_pairs)` RPC'si çağrılır → tek transaction'da katalog satırının `uid`'si
     ve ona bakan `workout_sets.exercise_uid`, `routine_exercises.exercise_uid`,
     `food_logs.food_uid`, `recipe_items.food_uid` güncellenir. İkinci cihaz
     aynı eşlemeyi gönderirse işlem boşa geçer (eski `uid` artık yok).
  3. **İsim değişikliği kuralı:** seed ismi ileride değişirse kimlik
     değişmesin diye `assets/data/catalog_aliases.json`'a eski isim → kimlik
     girdisi eklenir (seed güncelleme kontrol listesine yazılır).
  4. "İsimle benimseme" kuralı (`sync_pull.dart:200-209`) kaldırılır.
  5. Kullanıcının kendi eklediği hareket/besin (`is_custom = 1`) rastgele
     kimlikle kalır.

### 7.3 Hesap değişimi temizliği

- Temizlikten **önce** `sync_meta.switch_in_progress = <yeni kullanıcı>`
  yazılır, bitince silinir. Açılışta bu anahtar doluysa temizlik baştan
  yapılır (yarım temizlik = veri sızıntısı).
- Temizlik `capture = 0` ile çalışır → mezar taşı üretmez (yerel temizlik
  kullanıcı silmesi değildir).
- `last_user_id` shared_preferences'tan `sync_meta`'ya taşınır → temizlik ile
  aynı transaction'da güncellenir.

### 7.4 Gönderilmemiş veri + farklı hesap

Kuyrukta bekleyen kayıt varken **farklı** bir hesapla giriş yapılırsa temizlik
**yapılmaz**; kullanıcıya açık bir seçim sunulur (§13 Soru 3):

> "Bu cihazda önceki hesaba (s…@gmail.com) ait **N kayıt henüz yüklenmedi**.
> Devam edersen bu kayıtlar silinecek."
> `[Önceki hesaba geri dön]` `[Kayıtları silip devam et]`

### 7.5 Kapı hata durumu

`gateRedirect`'e `accountError` girdisi eklenir. Hesap kontrolü başarısızsa
kullanıcı içeri alınmaz; "Hesap doğrulanamadı — Tekrar dene / Çıkış yap"
ekranı gösterilir. Bugün `_applyAccount` hatasında kapı içeri alıyor
(yorumdaki sözle çelişki).

---

## 8. Su kaydı (#8)

**Olay kaydına geçiş (K-7):** "+250 ml" yeni satır ekler (bugün günün
satırını güncelliyor). "Sıfırla" o günün satırlarını siler (mezar taşları).
Günlük toplam zaten satırları toplayarak okunuyor (2026-09-15 düzeltmesi).
İki cihazda aynı gün ekleme artık çakışma değil, iki olay. Mevcut veri
dönüşüm gerektirmez. Arayüz değişmez; istenirse ileride "son eklemeyi geri
al" doğal olarak gelir.

---

## 9. Hata ve çevrimdışı durumları

| Durum | Sınıflandırma | Davranış |
|---|---|---|
| `SocketException`, `HandshakeException`, DNS hatası, 5xx, 521/522 | **Sunucuya ulaşılamıyor** | Artan bekleme (bugünkü 1 sn → 5 dk). `server_unreachable_since` ilk seferde yazılır. |
| 401 / oturum düştü | **Oturum yok** | Tur atlanır, kuyruk bekler. Kapı zaten Karşılama'ya yönlendirir. |
| 403 / 42501 (yetki), RLS ihlali | **Kalıcı hata** | Satır `sync_state = 2` (hata) olur, **kuyruğun geri kalanı durmaz**; hesap ekranında "N kayıt yüklenemedi — Destek" satırı. |
| 409 / 23505 (tekillik) | **Kalıcı hata** (bu tasarımdan sonra beklenmez) | Aynı. |
| 23502 (NOT NULL) | **Onarılabilir** | Bugünkü onarım geçişleri (uid, updated_at) + changed_at_ms onarımı. |

**Senkron durumu göstergesi** (docs/18 §9'un güncellemesi + C-36):

- Her zaman: **"Son yedekleme: bugün 14:32"** (`last_push_ok_at`).
- Sunucuya **3 günden uzun** ulaşılamıyorsa: sarı uyarı — "3 gündür
  yedeklenemedi. Veriler bu telefonda güvende." Ayrıntıda hata sınıfı.
- Kalıcı hatalı satır varsa: kırmızı değil, turuncu bilgi + sayı.
- Mesaj yine **"kaydedildi"** güvencesiyle başlar.

**Supabase ücretsiz planı:** proje hareketsizlikte duraklatılıyor. Gerçek
kullanıcıdan önce ücretli plana geçiş önerilir (§13 Soru 1). Geçene kadar
yukarıdaki "3 gündür yedeklenemedi" uyarısı sorunu görünür kılar.

---

## 10. Test planı

Mevcut 263 test korunur. Senkron v2 şu testler yeşil olmadan "bitti" sayılmaz.
**Kural:** test adı neyi vaat ediyorsa onu ölçer (E-15 dersi).

### 10.1 Gerçek yarış ve süreç ölümü (yerel)

| # | Test | Nasıl |
|---|---|---|
| S-1 | **Uçuştaki düzenleme** kaybolmaz | Sahte `SyncRemote.upsert` bir `Completer`'da bekler; o sırada satır güncellenir; `Completer` tamamlanır → satır **hâlâ kirli**, `local_seq` yeni. |
| S-2 | **Aynı milisaniyede iki düzenleme** kaybolmaz | Saat sabitlenir (enjekte edilen saat); iki güncelleme → iki farklı `local_seq`. |
| S-3 | **Süreç ölümü** | Geçici **dosya** veritabanı: yaz → `close()` → aynı dosyayı yeniden aç → kuyrukta. |
| S-4 | **Çekme sırasında yazma** | Sahte `fetch` bekler; o sırada kullanıcı satır ekler → ekleme kuyrukta, `uid`'li, `changed_at_ms` dolu. |
| S-5 | **Uygulama transaction'ında ölüm** | Uygulama aşamasında bilerek hata fırlat → `capture = 1`, imleç eski değerde. |
| S-6 | **Tetikleyici onarımı** | Bir tetikleyiciyi el ile düşür → veritabanını kapat/aç → tetikleyici geri gelmiş. |
| S-7 | **Silme yayılır** | Sil → mezar taşı → gönder → sahte sunucuda satır yok + silme işareti var → ikinci cihaz (ikinci test veritabanı) çekince satır silinir. |
| S-8 | **Seans silme zinciri** | Seans sil → setlerin de mezar taşı var. |
| S-9 | **Hesap temizliği mezar taşı üretmez** | A verisi → B girişi → `sync_tombstones` boş. |
| S-10 | **Sayfalama** | Sahte sunucuda 1.234 satır, sayfa 500 → üç sayfa, hepsi yerelde; imleç 1.234. |
| S-11 | **Kesilen sayfa algılanır** | Sahte sunucu 500 isteğe 1.000'den fazla dönerse → hata, imleç ilerlemez. |
| S-12 | **Reddedilen yazma** | Sahte sunucu satırı döndürmez (sunucu yeni) → yerel sunucununkiyle değişir, temizlenir, tekrar gönderilmez. |
| S-13 | **Silme kazanır** | Silmeden sonra (başka cihazda) yapılan düzenleme de satırı geri getirmez; "Geri al" yeni kimlikli kopya oluşturur. |
| S-14 | **Yarım hesap temizliği** | `switch_in_progress` dolu açılış → temizlik tamamlanır. |
| S-15 | **Gönderilmemiş veri + farklı hesap** | Temizlik yapılmaz, kapı seçim ekranına gider. |
| S-16 | **Reaktif yayılım** | Çekmeden sonra `watchTables` akışı yeni değeri verir (elle `invalidate` yok). |
| S-17 | **Açılışta Karşılama yok** | Oturumlu `bootstrap` → ilk konum `home`; yavaş çekme sırasında konum değişmez. |
| S-18 | **Göç v10 → v11** | Kayıpsız + 36 tetikleyici + `changed_at_ms` dolu. |

### 10.2 Sunucu (Postgres) testleri

`supabase/tests/sync_v2.sql` (pgTAP — Postgres için test çerçevesi) —
**ikinci bulut projesinde** (`Fit Pack Dev`) çalıştırılır; bkz. §10.4
(2026-09-18 kararı, §13 Karar 7'nin yerini aldı):

**Aşama 3 — 29 test, hepsi yeşil (2026-09-18):** yapı (12 tabloda kolon,
tetikleyici, iki dizin), ekleme, daha yeni damga → kabul, daha eski damga →
ret, eşit damga → ret, saat kırpma (1 saat ileri kırpılır, 1 dakika ileri
kırpılmaz), silme kazanır (ekleme ve güncelleme ayrı ayrı), ortak dizi,
işaret tablosu yetkileri.

**Ayrıca elle doğrulandı:** `changed_at_ms` göndermeyen bir "eski istemci"nin
EKLEMESİ geçiyor, GÜNCELLEMESİ sessizce reddediliyor — §11'deki "3 ve 4 aynı
sürümde çıkar" kuralının gerekçesi ölçülerek teyit edildi.

**Sonraki aşamalara kalanlar:**

- `sync_delete` başka kullanıcının satırına dokunamaz (RLS) → Aşama 5.
- `(user_id, uid)`: iki kullanıcı aynı `uid` → ikisi de yazılır → Aşama 6
  (bugün birincil anahtar hâlâ yalnız `uid`; tekil dizin kuruldu ama anahtar
  değişmedi).

### 10.4 Sunucu test ortamı — `Fit Pack Dev` (2026-09-18 kararı)

**Karar özeti:** sunucu değişiklikleri **ikinci bir ücretsiz bulut projesinde**
denenir; yerel Docker yığını kurulmaz.

| | Proje | Referans (`ref`) |
|---|---|---|
| Üretim | Fit Pack | `jkviihbyogktwboreydn` |
| **Test** | **Fit Pack Dev** | **`qecbnrkbordkqeogmevi`** |

İkisi de `eu-central-1`, ücretsiz plan (organizasyon başına 2 aktif proje
sınırının ikisi de kullanıldı — üçüncü bir proje açılamaz).

**Neden yerel Docker değil.** Yerel yığın ~9,7 GB disk istiyor; bu projede
disk iki kez yolu tıkadı (iOS platformunun silinmesi, Docker sanal makinesinin
kaldırılması). Test ortamının işi "gerçek veriye dokunmadan denemek" — bunu
ikinci bulut projesi diskten hiç yemeden yapıyor.

**Ne kaybediliyor.** `supabase test db` hazır koşucusu yerelde çalışır,
uzakta çalışmaz. Karşılığı: pgTAP eklentisi `extensions` şemasında açıldı
(sürüm 1.3.3, 2026-09-18'de doğrulandı) ve test SQL'i doğrudan
çalıştırılıyor; TAP çıktısı aynı şekilde okunuyor. Çağrılar
`extensions.plan(...)` / `extensions.has_table(...)` gibi şema önekiyle
yazılır.

**Sıfırlama.** `supabase link --project-ref qecbnrkbordkqeogmevi` +
`supabase db reset --linked` (yalnız test projesinde; üretimde **asla**).

**Uyku.** Ücretsiz proje 7 gün dokunulmazsa duraklar; panelden ~1 dk'da
uyanır.

**İstemciyi test projesine yöneltme (Aşama 4).**
`lib/core/config/supabase_config.dart` bugün sabit değer tutuyor; Aşama 4'te
`String.fromEnvironment` ile `--dart-define` geçişi eklenecek:

```
flutter run --dart-define=SUPABASE_URL=https://qecbnrkbordkqeogmevi.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=sb_publishable_aQZzc4k4q8DSZ5VQdCujTQ_nfOMZmw4
```

(publishable anahtar istemciye gömülmek için tasarlıdır — RLS korur.)

### 10.5 PostgREST doğrulaması — Aşama 4 (2026-09-18)

pgTAP SQL katmanını ölçer; istemcinin asıl dayandığı varsayım
**PostgREST'in `upsert(...).select()` çağrısının reddedilen satırı
düşürmesidir**. Gerçek HTTP çağrılarıyla `Fit Pack Dev` üzerinde ölçüldü:

| Ne denendi | Sonuç |
|---|---|
| Yeni satır gönderimi | kabul, `server_rev` döndü |
| Eski damgayla tekrar gönderim | **boş dizi** — ret doğru bildiriliyor |
| Yeni damgayla gönderim | kabul, `server_rev` arttı |
| **Karışık toplu gönderim** (biri eski, biri yeni) | yalnız yeni döndü — kısmi kabul çalışıyor |
| Sayfalı çekme, sayfa boyu 5, 14 satır | 5 + 5 + 4 + 0, tekrarsız, `server_rev` benzersiz |
| `uid=in.(...)` ile ret çözümü | iki satır da döndü |
| Oturumsuz erişim | boş (RLS) |
| `deleted_records` üzerinde DELETE | **403** — işaret silinemiyor |

Test hesabı ve verisi sonrasında silindi. Yöntem ve tuzaklar:
`supabase/tests/README.md`.

### 10.3 Uçtan uca (elle, cihazda)

Telefon + simülatör aynı hesapla: (1) telefonda öğün sil → simülatör
açılınca öğün yok; (2) simülatör çevrimdışı düzenle, telefon çevrimiçi daha
yeni düzenle → simülatör bağlanınca telefonunki kalır; (3) 1.200 satırlık
sahte geçmiş (test hesabı) → tam iner.

**Gerçek hesapta deneme yapılmaz** — test hesabı açılır (Supabase panelinden
"Auto Confirm", `.test` içermeyen adres; docs/18 §14).

---

## 11. Uygulama aşamaları

Her aşama **tek başına commit edilebilir**, testleri yeşil ve uygulama
çalışır durumda bırakır. Sıra bağımlılığa göre.

> **Commit edilebilir ≠ yayınlanabilir.** Sunucu değişikliği olan aşamalarda
> (3, 5, 6) sunucu ile telefon **birlikte** güncellenmelidir: sunucu yeni
> kuralı uygulamaya başladığı anda eski istemcinin yazmaları reddedilir.
> Yayın grupları: **3 + 4 aynı sürüm**, **5** kendi sürümü, **6** kendi
> sürümü. 0, 1, 2 ve 7 yalnız istemci — tek başlarına yayınlanabilir.
> Her yayın öncesi: sunucu yedeği + "eski sürüme dönülürse ne olur"
> sorusunun yazılı cevabı (CONVENTIONS §3 madde 8).

| Aşama | İçerik | Çözdüğü | Sunucu değişikliği | Tahmini |
|---|---|---|---|---|
| **0 — Kırmızı testler** ✅ | S-1, S-2, S-4, S-6 bugünkü koda karşı yazıldı, kırmızı oldukları görüldü, `skip` ile commit edildi (`test/features/sync_v2_stage0_test.dart`, 2026-09-18). S-3 (süreç ölümü) zaten yeşil: `sync_push_test` T-1. | E-15 | yok | ✅ |
| **1 — Yerel sağlamlık** ✅ | Şema v11: `changed_at_ms` / `local_seq` / `server_rev` + `sync_meta` + `sync_tombstones`; 36 tetikleyici (`capture` bayraklı, silme izi dahil); `_markClean` → `local_seq`; çekmede DROP TRIGGER yerine `capture`; açılışta onarım. **2026-09-18** — S-1, S-2, S-4, S-6 yeşile döndü; v10→v11 göç testi (7 test). | #2, #3, #9 | yok | ✅ |
| **2 — Açılış ve kapı** ✅ | `bootstrap` yerel hesap kontrolünü de yapıyor; nötr açılış ekranı (`/splash`) ve başlangıç konumu kapıdan; `accountError` → "Hesap doğrulanamadı" ekranı; `switch_in_progress` ile yarıda kalan temizlik açılışta tamamlanıyor; `last_user_id` deftere taşındı; gönderilmemiş kayıt + farklı hesap → seçim ekranı (veri silinmiyor). **2026-09-18**, 18 test. | #6, Karşılama, §7.4 | yok | ✅ |
| **3 — Sunucu v2 (sürüm)** ✅ | `supabase/migrations/20260918120000_sync_v2_stage3.sql`: 12 tabloya `changed_at_ms` + `server_rev`, ortak `sync_rev_seq` dizisi, `sync_guard` tetikleyicisi, `(user_id, server_rev)` dizini, `(user_id, uid)` tekil dizini, `deleted_records` tablosu. **2026-09-18**, `Fit Pack Dev`'de **29/29 pgTAP testi yeşil** (`supabase/tests/sync_v2_stage3.sql`). **Üretime UYGULANMADI** — Aşama 4 ile birlikte çıkacak. | #4 hazırlığı | **var** | ✅ |
| **4 — Sayfalı, artımlı çekme + koşullu gönderim** ✅ | İki aşamalı çekme + tablo başına `server_rev` imleci (`sync_meta`'da, kullanıcıya özel) ve **imleç payı** (§12.1); sayfa boyu 500 + tutarlılık kontrolü; `upsert().select()` ile kabul/ret; ret çözümü (`fetchByUids` → uygula → temizle, `local_seq` korumasıyla); `changed_at_ms` gönderimi; `server_rev` yerele yazılıyor; satır uygulama kuralı `SyncApply`'da tek yerde; `--dart-define` ile test projesine yönlendirme. **2026-09-18**, 11 yeni test (toplam 394) + gerçek PostgREST doğrulaması. | #4, #5 | — | ✅ |
| **5 — Silme protokolü** | Silme tetikleyicileri; `sync_delete` RPC; mezar taşı gönderimi; çekmede silme uygulama; rutin fark kaydı; `deleted_records` tablosu + sunucu silme tetikleyicileri | #1 | **var** | 2 gün |
| **6 — Sahiplik + katalog kimliği + su** | Sunucu anahtarı `(user_id, uid)`; belirlenimci katalog kimliği + `sync_remap_uids`; hesap değişiminde katalog sıfırlama; su olay kaydı | #7, #8, isimle benimseme | **var** | 2 gün |
| **7 — Durum ve operasyon** | Hata sınıflandırma; "Son yedekleme"; 3 gün uyarısı; kalıcı hata satırı (`sync_state = 2`) | C-36, duraklatma | yok | 1 gün |
**Toplam:** yaklaşık 10 iş günü. Sunucu test ortamı **kuruldu**
(`Fit Pack Dev`, §10.4 — yerel Docker yerine ikinci bulut projesi). Her aşama sonunda cihazda
duman testi (açılış + bir kayıt + senkron) ve PROJECT_STATE güncellemesi.

**Sunucu değişikliklerinde sıra:** yedek al (`pg_dump` ya da panel yedeği) →
`Fit Pack Dev`'de dene (§10.4) → ana projeye uygula → **aynı gün** uygulama sürümünü çıkar.
Eski uygulama sürümü yeni şemayla çalışmaya devam etmeli: yeni kolonların
varsayılanı var (`changed_at_ms default 0`); eski istemci `server_rev`
göndermez (sunucu atar). Eski istemcinin koşulsuz yazması `changed_at_ms = 0`
ile gelir → tetikleyici onu **eski** sayıp reddeder; bu yüzden 3. ve 4.
aşama **aynı sürümde** yayınlanmalı (tek kullanıcı, tek cihaz güncellemesi —
pratikte sorun değil, ama kural olarak yazıldı).

---

## 12. Riskler

| Risk | Etki | Önlem |
|---|---|---|
| Göçte tetikleyici yeniden kurulurken hata | Senkron durur | Göç tek transaction; `beforeOpen` onarımı; S-18 |
| Sunucu anahtar değişikliği (`(user_id, uid)`) | Yanlış uygulanırsa veri görünmez olur | Önce yedek; dalda deneme; satır sayısı öncesi/sonrası karşılaştırma |
| Saat sapması | Yanlış sürüm kazanır | Sunucuda gelecek damgası kırpma; otomatik saat varsayımı belgelendi |
| Mezar taşı birikimi | Sunucu tablosu büyür | Satır başına birkaç bayt; saklama süresi kararı §13 Soru 4 |
| İlk tam çekme büyük | Yavaş ilk giriş | Sayfa başına transaction; ilerleme göstergesi ("Verilerin indiriliyor…") |
| Eski uygulama sürümü | Yazmaları reddedilir | §11 son paragraf |
| **`server_rev` boşluğu — imleç bir satırı atlayabilir** (2026-09-18'de Aşama 3 yazılırken görüldü) | Satır öteki cihaza **hiç** ulaşmaz | §12.1 — Aşama 4'te imleç gecikmesi + düzenli tam uzlaştırma |

### 12.1 `server_rev` boşluğu (Aşama 4'ün çözmesi gereken)

**Sorun.** `server_rev` tetikleyicide `nextval` ile atanır — yani
**transaction'ın başında**, ama satır ancak **commit'te** görünür olur. İki
gönderim üst üste binerse numaralar sıraya girmez:

```
A gönderimi  → rev 10 aldı, henüz commit etmedi
B gönderimi  → rev 11 aldı, commit etti
çekme        → rev 11'i gördü, imleci 11 yaptı
A            → şimdi commit etti; rev 10 artık görünür
sonraki çekme → "rev > 11" diyor; rev 10'u BİR DAHA görmez
```

Sonuç: A'nın satırı öteki cihaza hiç inmez. Satır yerelde temiz olduğu için
tekrar gönderilmez de — yeniden düzenlenene kadar kalıcı kayıp. Bu, epiğin
kapatmaya çalıştığı "sessiz kayıp" sınıfının ta kendisi.

**Ne kadar olası.** Tek kullanıcı, iki cihaz (telefon + simülatör) ve gönderim
tek cümlelik bir `upsert` (milisaniyeler). Çakışma penceresi dar ama sıfır
değil: iki cihaz aynı anda gönderirse olur.

**Önlem (Aşama 4'te uygulanacak, iki katman):**

1. **İmleç gecikmesi.** Çekme imleci son görülen `server_rev`'i değil,
   **son görülen − pay** değerini saklar (öneri: 1.000). Aynı satırın tekrar
   inmesi zararsızdır — uygulama kuralı (§6.2) `changed_at_ms` karşılaştırıp
   eskiyi atar, yani işlem **idempotent**. Maliyet yalnız birkaç yüz satırlık
   fazladan indirme; bu veri boyutunda ölçülemez.
2. **Düzenli tam uzlaştırma.** Haftada bir (ya da elle "Şimdi eşitle") imleç
   0'dan başlatılır ve her şey yeniden okunur. Pay ne kadar geniş olursa
   olsun kapatamadığı uzun süreli açık transaction durumunu bu yakalar.

**Neden sunucuda çözülmedi.** Sıraya sokmanın kesin yolu yazmaları tek tek
kilitlemek (kullanıcı başına advisory lock) ya da imleci commit sırasına
(`xmin` anlık görüntüsü) bağlamak. İkisi de bu ölçekteki bir uygulama için
gereğinden karmaşık; idempotent tekrar indirme aynı garantiyi çok daha ucuza
veriyor. Karar gerekirse §13 Soru 8'e taşınır.

---

## 13. Kararlar ve açık sorular

| # | Konu | Durum | Karar / öneri |
|---|---|---|---|
| 1 | Supabase ücretli plan | ✅ **Karar (Samet, 2026-09-17):** şimdi değil; ürün oturunca değerlendirilecek | Arada §9'daki "N gündür yedeklenemedi" uyarısı sorunu görünür kılar. Günlük kullanım projeyi zaten uyanık tutar. |
| 2 | Silme ile düzenleme çakışması | ✅ **Karar (Samet onayladı, 2026-09-17)** | **Silme her zaman kazanır.** Silme bilinçli bir eylem; "sildiğim geri geldi" tam da düzeltmeye çalıştığımız hata. Kaybedilen şey, başka cihazda silinmiş bir kayda yapılan düzenleme — nadir ve kullanıcının zaten istemediği bir kayıt. |
| 3 | Gönderilmemiş kayıt + farklı hesap | ✅ **Karar (Samet onayladı, 2026-09-17)** | §7.4: temizlik **yapılmaz**, seçim sunulur; varsayılan (öne çıkan) seçenek "önceki hesaba geri dön", silme seçeneği kırmızı ve ikinci onaylı. Kaybı kaynağında önleyen çıkış uyarısı (Aşama G) zaten var. |
| 4 | Silme işaretlerinin saklanması | ✅ **Karar (Samet onayladı, 2026-09-17)** | İşaretler **süresiz** tutulur (satır başına ~100 bayt). İleride temizlik gerekirse: 1 yıldan eski işaretler silinir **ve** son eşitlemesi o sınırdan eski olan cihaz tam yeniden eşitleme yapar (eski kopyasını sunucununkiyle değiştirir). Silinen içeriğin kendisi sunucuda zaten tutulmaz (K-3). |
| 5 | Su kaydının olay kaydına dönmesi | ✅ **Karar (Samet onayladı, 2026-09-17)** | Evet (§8). |
| 6 | Belirlenimci katalog kimliği | ✅ **Karar (Samet):** şimdi | Aşama 6'ya alındı; yöntem §7.2. |
| 7 | Sunucu testleri | 🔄 **Karar değişti (Samet, 2026-09-18)** | ~~Yerel Docker~~ → **ikinci ücretsiz bulut projesi** `Fit Pack Dev` + pgTAP (§10.4). Gerekçe: yerel yığın ~9,7 GB disk istiyor, disk bu projede iki kez yolu tıkadı; bulut kopyası aynı işi diskten yemeden yapıyor. Kaybedilen: `supabase test db` hazır koşucusu (test SQL'i doğrudan çalıştırılıyor). |

## 14. Sözlük

| Terim | Anlamı |
|---|---|
| **Senkron** | Cihaz ile sunucu arasında verinin eşitlenmesi |
| **Kuyruk / giden kutusu (outbox)** | Sunucuya gönderilmeyi bekleyen değişiklikler |
| **Push / gönderim** | Cihazdan sunucuya |
| **Pull / çekme** | Sunucudan cihaza |
| **LWW (last writer wins)** | Çakışmada son yazan kazanır |
| **Tombstone / mezar taşı** | "Bu kayıt silindi" bilgisini taşıyan kayıt |
| **Silme işareti** | Silinen satırın yerine kalan, içerik taşımayan "bu kimlik silindi" kaydı |
| **RLS (Row Level Security)** | Postgres'in her kullanıcıya yalnız kendi satırlarını gösteren kuralı |
| **RPC (Remote Procedure Call)** | Sunucudaki bir fonksiyonu çağırmak |
| **PostgREST** | Supabase'in veritabanını REST API olarak açan katmanı |
| **Tetikleyici (trigger)** | Veritabanında bir yazma olunca kendiliğinden çalışan kod |
| **Transaction** | Ya hep ya hiç çalışan yazma grubu |
| **İmleç (cursor)** | Çekmede "en son nereye kadar aldım" işareti |
| **Anahtar tabanlı sayfalama** | "Şu değerden sonrakileri getir" diye sayfalamak (sayfa numarasıyla değil) |
| **UUIDv5** | Aynı girdiden hep aynı kimliği üreten UUID türü |
| **ADR-007** | Projenin "yıkıcı göç yasak" kararı |
| **Supabase dalı (branch)** | Ana projenin denemeler için kopyası |
