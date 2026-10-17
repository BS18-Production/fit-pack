# 46 — Senkron: yakalama bayrağı ve yoldaki silme (CR-003, CR-004)

> Kaynak: Codex inceleme raporu (16 Eki 2026) CR-003 ve CR-004. Önceki iş:
> CR-002 + CR-005 (`b182248`, dal `fix/sync-review-p1`). İlgili tasarım:
> docs/20 §4.1 (tetikleyiciler, `capture`), §5.3 (silme protokolü).

## Karar özeti

**Ne değişecek, neden.** İki küçük boşluk kullanıcının kaydını sessizce
yedeksiz bırakıyor ya da sildiği kaydı geri getiriyor:

1. **CR-003 — yakalama bayrağı işlemin dışında.** Senkron, sunucudan inen
   satırları yazarken tetikleyicileri `capture = 0` ile susturuyor. Bayrak
   veritabanı işleminden (transaction) *önce* kapanıp *sonra* açılıyor. Tam o
   aralıkta kullanıcının yaptığı bir kayıt (ör. öğün ekleme) kimliksiz ve
   kuyruksuz kalır, yani sunucuya hiç gitmez ve kullanıcı bunu fark etmez.
2. **CR-004 — yoldayken silinen kayıt geri gelir.** Silme tetikleyicisi
   yalnız "sunucuda olduğu bilinen" satır için iz (mezar taşı) bırakıyor. Yeni
   kayıt sunucuya gönderilirken, cevap gelmeden silinirse iz bırakılmaz;
   sunucu kaydı kabul eder, bir sonraki çekmede kayıt geri gelir. En olası
   yer: yemek ekleyip hemen "Geri al".

**Önerilen seçenekler.**

- CR-003: Bayrağın kapatılması, sunucu yazmaları ve tekrar açılması **aynı
  transaction içinde**. Drift başka yazmaları transaction bitene kadar
  beklettiği için kullanıcı yazması bayrak kapalıyken araya giremez. Elenen:
  sayaçlı (ref-count) bayrak; asıl sorun olan zamanlamayı çözmüyor.
- CR-004: Silme tetikleyicisinin kuralı **"sunucuda olabilir"e** genişler:
  satır kuyruktaysa ya da kalıcı hatadaysa (`sync_state` 1 ya da 2) da iz
  bırakır. Sunucu, tanımadığı kimliğin silmesini zaten sessizce yok sayıyor
  (docs/20 §5.3); fazladan iz zarar vermez, turun sonunda temizlenir.
  - Elenen 1: yalnız gönderim kodunda "kabul edildi ama satır yok" kontrolü.
    "Sunucu yazdı ama cevap kayboldu" durumunu kapsamıyor.
  - Elenen 2: kalıcı "yolda" durumu (yeni kolon). Şema değişikliği gerektiriyor,
    kazancı yok.
- Tetikleyici metni değiştiği için mevcut kurulumlarda eski tetikleyicinin
  yenisiyle değiştirilmesi gerekir. **Şema sürümü artırılmaz** (şema kilidi
  Claude-2'de, v17). Bunun yerine `sync_meta` tablosuna `trigger_rev` yazılır.
  Açılıştaki onarım (`_repairSyncTriggers`) bu sayı eskiyse tetikleyicileri
  düşürüp yeniden kurar. Tetikleyiciler Drift şema dökümünde yer almadığı
  için göç testleri etkilenmez.

**Gerçek veriye etkisi.** Mevcut satırlara dokunulmaz, göç yok. Değişen tek
şey tetikleyici tanımları ve bir `sync_meta` anahtarı. Geri dönüş: eski
sürüm kurulursa `trigger_rev` yüksek kalır ama eski kod onu okumaz; eski
tetikleyiciler yalnız yeni kurulumda oluşur. Pratikte geri dönüş gerekmez.

**Kullanıcıya görünen küçük fark.** Hiç gönderilmeden silinen kayıt, bir
sonraki tura kadar "1 kayıt bekliyor" olarak görünür (önceden görünmüyordu).
Hesap değiştirirken bu iz de "yüklenmemiş kayıt" sayılır. Tur çalışınca iz
kalkar; bu davranış doğru kabul edildi.

**Samet'ten gereken kararlar.**

1. [x] Önerilen yol uygulansın — Samet "tasarım notunu yaz, sonra kodla"
   dedi (2026-10-17). İtiraz gelirse geri alınır.

**Nasıl doğrulanacak.**

- Yeni testler (önce kırmızı, sonra yeşil):
  - Bayrak kapalıyken araya giren kullanıcı yazması kimlik ve kuyruk alır.
  - Gönderim beklerken silinen yeni kayıt sunucuda kalmaz, çekmede geri gelmez.
  - "Sunucu yazdı, cevap kayboldu" sonrası silinen kayıt sunucudan da kalkar.
  - Eski tetikleyiciyle açılan veritabanı yeni kurala geçer, ikinci açılış
    tekrar kurmaz.
  - Seed katalog satırının silmesi hâlâ iz bırakmaz.
- Mevcut 1000 test yeşil kalır; `flutter analyze` temiz.
- Cihazda (Samet onayıyla): öğün ekle → hemen "Geri al" → hesap ekranında
  "Şimdi eşitle" → ikinci cihazda/simülatörde öğün yok.

---

## 1. CR-003 ayrıntı

**Bugün:** `SyncApply.withCaptureOff(body)` →
`capture=0` → `body()` (içinde `db.transaction`) → `capture=1`. Üç ayrı
`await`. Drift aynı bağlantıda transaction dışı sorguları kuyruğa alır; bayrak
kapandıktan sonra kuyruğa giren kullanıcı yazması transaction'dan sonra,
**bayrak açılmadan önce** çalışabilir.

**Yeni:** `withCaptureOff(body)` kendi transaction'ını açar:

```dart
Future<void> withCaptureOff(Future<void> Function() body) =>
    db.transaction(() async {
      await db.customStatement(setCaptureSql(false));
      try {
        await body();
      } finally {
        await db.customStatement(setCaptureSql(true));
      }
    });
```

- Çağıranlar içteki `db.transaction(...)`ı bırakır (5 yer: pull ×3,
  push ×2). İç içe kalsa da Drift kayıt noktasıyla çalışırdı, ama tek
  sorumluluk daha okunur.
- Hata olursa işlem geri alınır; bayrak da işlem öncesi değerine (1) döner.
  Uygulama işlemin ortasında ölürse SQLite işlemi geri alır, bayrak 1 kalır.
  Açılış onarımı yine de güvence olarak `capture=1` yazmaya devam eder.
- Ağ çağrısı işlemin içine **girmez**: çağıranlar zaten ağ cevabını işlemden
  önce alıyor (docs/20 §6, S-4).
- **Hesap temizliği** (`AccountSwitchGuard.wipeLocalUserData`) aynı kalıba
  geçer: bayrak `_wipeTables`'ın transaction'ı içinde kapanıp açılır.
- Göç adımlarındaki (`app_database.dart` onUpgrade) bayrak kullanımı
  değişmez: göç sırasında kullanıcı yazması olamaz, ayrıca şema kilidine
  dokunmamak gerekiyor.

## 2. CR-004 ayrıntı

**Bugünkü kural:**
`OLD.uid IS NOT NULL AND (OLD.server_rev IS NOT NULL OR OLD.user_id IS NOT NULL)`

**Yeni kural:**
`OLD.uid IS NOT NULL AND (OLD.server_rev IS NOT NULL OR OLD.user_id IS NOT NULL OR OLD.sync_state <> 0)`

| Satırın durumu | Sunucuda olabilir mi | Bugün iz | Yeni iz |
|---|---|---|---|
| Sunucudan inmiş / onaylanmış (`server_rev` ya da `user_id` dolu) | evet | var | var |
| Kuyrukta, hiç gönderilmemiş (`sync_state=1`) | belki (yolda / cevap kayboldu) | **yok** | var |
| Kalıcı hatada (`sync_state=2`) | belki (toplu gönderim yarım kaldıysa) | **yok** | var |
| Seed katalog, hiç kuyruğa girmemiş (`sync_state=0`, sahipsiz) | hayır | yok | yok |

- Aynı turda sıra korunur: yazmalar önce, mezar taşları sonra (docs/20
  §5.3). Yolda silinen kayıt → sunucu ekler → aynı turun sonunda silme gider.
- Mezar taşı varken çekme o kimliği yerele uygulamaz (`_hasTombstone`,
  mevcut). Silme turu ağ yüzünden düşerse kayıt yine geri gelmez.
- Büyüme: yalnız "gönderilmeden silinen" satır başına bir iz; ilk turda kalkar.

## 3. Tetikleyici sürümü

- `sync_columns.dart`: `const syncTriggerRev = 2;` (1 = bugünkü kural,
  anahtar yoksa 1 sayılır).
- `_repairSyncTriggers`: `trigger_rev` eksik ya da küçükse her senkron
  tablosu için üç tetikleyiciyi düşürür, yeniden kurar ve `trigger_rev`'i
  yazar; hepsi tek transaction'da. Sonra mevcut "eksik tetikleyici" kontrolü
  aynen çalışır.
- `onCreate`'te de `trigger_rev` yazılır, yeni kurulum gereksiz yeniden
  kurulum yapmaz.
- `onUpgrade`'deki eski göç adımları **değişmez**. Onlar o sürümün
  tetikleyicisini kurar, açılış onarımı en güncele taşır.

## 4. Kapsam dışı

- CR-001 (hesap nesli ve iptal) ayrı iş. Bu değişiklik ona engel değil.
- Su sayacı ve saat düzeltmesi (raporun "Needs Verification" başlıkları).
