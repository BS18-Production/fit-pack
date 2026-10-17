# 47 — Senkronun hesap sahipliği sınırı (CR-001)

> Kaynak: Codex inceleme raporu (16 Eki 2026) CR-001. Önceki işler: docs/46
> (CR-002…005). İlgili tasarım: docs/20 §7 (hesap izolasyonu), docs/18 §5.1.

## Karar özeti

**Ne değişecek, neden.** Hesap kapısı (`AuthGate`) yalnız ekranı kilitliyor;
arka plandaki senkron yalnız "oturum var mı" diye bakıyor. Telefonda A
hesabının yüklenmemiş kayıtları varken B giriş yapınca:

- Çakışma ekranı açıkken bile gönderim, A'nın kayıtlarını **B'nin hesabına**
  yükleyebilir (`user_id` B ile damgalanır, sunucu bunu reddedemez).
- Uygulama B oturumuyla çakışma hâlinde yeniden açılırsa açılış, B'nin
  verisini A'nın veritabanına indirebilir.
- A için başlamış bir çekme, hesap değiştikten sonra gelen cevabı aynı
  veritabanına yazabilir.

Pratikte yalnız aynı telefonda hesap değiştirilince olur (Samet ve Berna
ayrı telefonda). Yine de uygulama başkalarına açılmadan kapanması gereken
bir veri sızıntısı.

**Önerilen seçenek: tek "sahiplik" kuralı.** Senkron işi bir kullanıcı için
yalnız şu üçü birlikte doğruysa çalışır:

1. Açık oturum bu kullanıcının.
2. Cihazdaki verinin kayıtlı sahibi (`sync_meta.last_user_id`) bu kullanıcı.
3. Yarım kalmış hesap temizliği yok (`switch_in_progress` boş).

Kural `SyncOwnership` adlı tek bir sınıfta. Gönderim ve çekme onu üç yerde
sorar: **işe başlarken**, **her ağ çağrısından önce** ve **her yerel yazma
transaction'ının içinde, yazmadan önce**. Kural bozulursa iş yarıda bırakılır,
hiçbir şey yazılmaz. Satırlar kuyrukta kalır; sahiplik düzelince (kullanıcı
çakışma ekranında karar verince) sıradaki tur onları gönderir.

Ek olarak:
- **Gönderimde satır sahipliği:** `user_id`'si dolu ve gönderen kullanıcıdan
  farklı olan satır gönderilmez, kuyrukta bekler.
- **Açılış:** hesap kontrolü çakışma ya da hata verdiyse açılış çekmesi
  başlatılmaz.

**Elenen seçenekler.**
- *Hesap geçişinde controller'ı durdurup yeniden başlatmak:* ekran
  olaylarına bağlı kalır, yarıda kalan ağ işini durduramaz.
- *Bellekte "hesap nesli" sayacı:* uygulama yeniden açılınca sıfırlanır.
  Doğruluk kaynağı zaten diskte (`last_user_id`); ikinci bir kaynak gerekmez.
- *İptal edilebilir ağ istekleri:* Supabase istemcisi istek iptalini
  desteklemiyor. Cevabı yazmadan önce sahipliği sormak aynı güvenceyi verir.

**Gerçek veriye etkisi.** Şema, göç ve sunucu değişikliği yok. Mevcut veri
etkilenmez. Tek görünür fark: çakışma ekranı açıkken senkron bekler. Bugün
de kullanıcı karar verene kadar içeri giremiyor; artık arka plan da bekliyor.

**Samet'ten gereken kararlar.**
1. [x] Uygula — "onaylıyorum başla hepsini bitir" (2026-10-17).

**Nasıl doğrulanacak.**
- Testler (önce kırmızı, sonra yeşil):
  - A'nın bekleyen kaydı varken B oturumu → controller hiçbir şey göndermez.
  - Aynı hesap, çevrimdışı açılış, ilk giriş (sahipsiz veri) → eskisi gibi
    gönderir.
  - A çekmesi sürerken oturum B'ye geçer → hiçbir satır yazılmaz, imleç
    ilerlemez.
  - Gönderim sürerken hesap temizliği başlar → temiz işaretleme yapılmaz,
    sonraki tablolar gönderilmez.
  - Başka hesaba ait (`user_id` farklı) satır gönderilmez.
  - Açılış kararı: çakışma / hata → çekme yok; normal → çekme var.
- Mevcut 1006 test yeşil; `flutter analyze` temiz.
- Cihazda (Samet onayıyla): normal kullanımda "Son yedekleme" ilerliyor;
  tek hesapta davranış değişmedi.

---

## 1. Sahiplik kontrolü

```dart
class SyncOwnership {
  SyncOwnership(this.db, {this.sessionUserId});
  Future<bool> owns(String userId);   // üç şart
  Future<void> ensure(String userId); // değilse SyncOwnershipLost fırlatır
}
```

- `sessionUserId`: üretimde Supabase'in kalıcı oturumu (ağ sormaz; docs/18
  Kural 1). Verilmezse oturum şartı atlanır, yalnız testlerde.
- `SyncPush` ve `SyncPull` isteğe bağlı `ownership` alır. Sağlayıcılar
  (`sync_providers.dart`) her zaman verir. Verilmezse kontrol yapılmaz;
  sahiplikle ilgisi olmayan eski testler aynen çalışır.
- Okumalar `sync_meta`'dan yapılır. Transaction içinde çağrılınca drift aynı
  transaction'ı kullanır, yani kontrol ile yazma atomiktir. Hesap
  temizliğinin `switch_in_progress` yazması, süren bir transaction bitene
  kadar bekler.

## 2. Gönderim (`SyncPush`)

| Nokta | Davranış |
|---|---|
| `pushAll` başı | Sahip değilse tur atlanır (hata değil, sağlık kaydına yazılmaz). |
| `upsert` / `deleteRows` / `fetchByUids` öncesi | `ensure`; bozulursa tur biter. |
| `_markClean`, `_resolveRejected`, `_upsertIsolating` işaretlemesi | Transaction içinde `ensure`; bozulursa geri alınır. |
| `_rowToJson` | Satırın `user_id`'si dolu ve farklıysa satır atlanır (kuyrukta kalır). |

Tur yarıda kalırsa sonuç hata taşır, ama sağlık kaydına "sunucuya
ulaşılamadı" olarak yazılmaz: bu bir ağ hatası değil.

`SyncController.syncNow` aynı kontrolü bekleyen sayısından önce yapar ve
sahip değilse "atlandı: yerel veri bu hesaba ait değil" diye loglar. Hesap
kararı verilince `sync_meta` yazması tablo güncellemesi ürettiği için
controller kendiliğinden yeniden tetiklenir; ayrıca bağlamak gerekmez.

## 3. Çekme (`SyncPull`)

| Nokta | Davranış |
|---|---|
| `pullAll` başı | Sahip değilse boş sonuç döner. |
| Her `fetch*` öncesi | `ensure`. |
| Üç uygulama transaction'ı (satırlar, silme işaretleri, ikinci deneme) | Önce `ensure`; bozulursa satırlar da imleç de yazılmaz. |
| Tablo başına `catch` | `SyncOwnershipLost` yutulmaz, yeniden fırlatılır. Çekme tümüyle durur, başarı kaydı yazılmaz. |

## 4. Açılış (`AuthGate.bootstrap`)

Açılış çekmesi yalnız şu durumda başlar: oturum var, bu oturum bu açılışta
henüz uygulanmamış, hesap kontrolü hata vermedi ve sonuç çakışma değil.
Karar saf bir fonksiyona (`shouldPullOnBootstrap`) alınır ki test edilebilsin.
Çekme kendi içinde de sahipliği sorduğu için bu ikinci bir güvencedir.

## 5. Korunanlar

- **İlk giriş:** sahipsiz yerel veri yeni hesaba bağlanır (`adopted` →
  `last_user_id` yazılır), sonra gönderilir.
- **Çevrimdışı aynı hesap:** oturum ve sahip aynı, ağ sorulmaz.
- **"Silip devam et":** temizlik bitince `last_user_id` = yeni hesap;
  sıradaki tur ve çekme normal çalışır.
- **"Önceki hesaba dön":** A ile tekrar girilince sahip = A, kuyruk gider.

## 6. Kapsam dışı

- Sunucu tarafında yabancı anahtar sahipliği (raporun "Needs Verification"
  başlığı) — ayrı inceleme.
- Sağlık modülünün kendi dönem sayacı (`healthEpoch`, feat/health-next) —
  o dalın işi, bu değişiklikle çakışmaz.
