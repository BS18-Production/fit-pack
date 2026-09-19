# 19 — İlerleme Fotoğrafları (Progress Photos)

> **Durum:** ✅ **Dilim 1 kodlandı (2026-09-19)** — cihazda görsel kontrol bekliyor (§8)
> Tasarım: 2026-08-02
> **Şema:** değişiklik YOK — `ProgressPhotos` tablosu Nisan'dan beri şemada duruyor
> **İlgili:** [18 — Hesap & Senkron](18-auth-and-sync.md) · [17 §2 #7](17-improvement-analysis.md)

## 1. Neden

`ProgressPhotos` tablosu, DAO'su ve Supabase mirror'ı **var**; hiçbir ekran
kullanmıyor. Tabloya dokunan tek şey senkron hattı — yani bugün özellik olarak
sıfır, bakım yükü olarak eksi.

Ürün gerekçesi: cut (yağ yakma) döneminde tartı yanıltıcıdır — su tutma, glikojen
ve bağırsak içeriği günlük ±1,5 kg oynatır. Aynada görülen değişim tartıdan
haftalar önce belli olur. docs/17 §2 bunu "cut kitlesinin 1 numaralı
motivasyonu" diye işaretlemiş. Kilo grafiği zaten var; fotoğraf onun eksik yarısı.

## 2. Kapsam

**Dilim 1 (bu iş) — cihazda kalan fotoğraflar**

- Fotoğraf çek (kamera) veya galeriden seç
- Her fotoğrafa tarih + açı (`front` / `side` / `back`) etiketi
- Galeri: tarihe göre gruplu ızgara, açıya göre süzme
- **Karşılaştırma:** iki fotoğrafı yan yana koy (özelliğin asıl değeri)
- Sil (satır + disk dosyası birlikte)
- Fotoğraflar **cihazdan çıkmaz**

**Dilim 2 (sonra) — Supabase Storage**

Yükleme, özel bucket + RLS, `image_path` → storage anahtarı, telefon değişiminde
geri gelme. **Otomatik değil, açık kullanıcı onayıyla** (§6).

Kapsam dışı: yüz bulanıklaştırma, otomatik poz hizalama, zaman-atlamalı video,
vücut yağ tahmini. Hepsi dilim 3+.

## 3. Üç karar

### K-1 — `image_path` **göreli dosya adı** tutar, mutlak yol DEĞİL

Tabloda `imagePath text not null` var ama içine ne yazılacağı tanımlanmamıştı.
Mutlak yol (`/var/mobile/Containers/Data/Application/<UUID>/…`) yazmak **iOS'ta
gizli bir arıza**: konteyner UUID'si her kurulumda/güncellemede değişir, yani
kullanıcı uygulamayı güncelledikten sonra bütün fotoğrafları kırılır. Android'de
de yeniden kurulumda aynı sonuç.

Bu yüzden kolon yalnız **dosya adını** tutar (`2026-08-02T19-30-12_front.jpg`).
Tam yol okuma anında çözülür:

```
<getApplicationDocumentsDirectory()>/progress_photos/<image_path>
```

Yan fayda: dilim 2'de aynı değer doğrudan storage anahtarı olur
(`<user_id>/<image_path>`) — göç gerekmez.

### K-2 — `progress_photos` uzak senkrondan MUAF, ama yerel silme listesinde KALIR

Tablo bugün `syncPushOrder` içinde (`sync_columns.dart:82`) ve sunucuda
`image_path text not null` mirror'ı var. İlk fotoğraf yazıldığı anda hat o satırı
sunucuya gönderir — **içinde yalnız bu cihazda anlamı olan bir dosya adıyla**.
İkinci cihaz onu çeker, dosya yoktur, kırık kayıt oluşur. Veri yokluğundan kötü:
kullanıcı "fotoğrafım yüklendi" sanır.

Akla ilk gelen çözüm — tabloyu `syncPushOrder`'dan çıkarmak — **yanlış**, çünkü o
liste üç işi birden yapıyor:

| Kullanım | Yer |
|---|---|
| Gönderim sırası | `sync_push.dart:88` |
| Çekme sırası | `sync_pull.dart:63` |
| Kuyruk sayımı (durum göstergesi) | `sync_controller.dart:132,145` |
| **Hesap değişiminde yerel veriyi silme** (ters sıra) | `account_switch.dart:64` |

Listeden çıkarsa dördüncü madde de kaybolur: A kullanıcısı çıkıp B girdiğinde
A'nın **vücut fotoğrafları cihazda kalır ve B'ye görünür**. Uygulamadaki en
hassas veri için bu kabul edilemez bir sızıntı.

**Karar:** liste korunur; yeni bir küme eklenir.

```dart
/// Yerel yaşayan ama sunucuya GİTMEYEN tablolar. Silme/kuyruk mantığı bunları
/// yine kapsar — yalnız uzak gönderim/çekme atlar (docs/19 §3 K-2).
const syncRemoteExcluded = <String>{'progress_photos'};
```

Push, pull ve kuyruk sayımı bu kümeyi atlar; `wipeLocalUserData` atlamaz.
Dilim 2'de küme boşalır, tek satırlık geri alma.

### K-3 — Silme diski de temizler

Satır silmek dosyayı bırakırsa konteyner sonsuza dek şişer ve silinmiş fotoğraf
diskte yaşamaya devam eder (gizlilik açısından da yanlış). Hem tekil silme hem
`wipeLocalUserData` dosyaları kaldırır. Yetim dosyalara karşı açılışta ucuz bir
süpürme: `progress_photos/` altında DB'de karşılığı olmayan dosyaları sil.

## 4. Mimari

```
lib/
  data/services/photo_storage.dart     # dosya yaz/çöz/sil — UI bilmez, test edilir
  features/progress_photos/
    progress_photos_screen.dart        # galeri (ızgara + açı süzgeci)
    progress_photos_providers.dart     # StreamProvider (watchTables kalıbı)
    photo_compare_screen.dart          # iki fotoğraf yan yana
    photo_capture_sheet.dart           # kaynak seç + açı + tarih
```

`PhotoStorage` sorumluluğu: dosya adı üret, seçilen görseli hedefe kopyala, tam
yolu çöz, sil, yetimleri süpür. Dart tarafı saf — `path_provider`'dan gelen kök
dizin **parametre**, böylece test geçici dizinle koşar.

Okuma kalıbı kanonik (CONVENTIONS §2, H-05 sonrası):

```dart
final progressPhotosProvider = StreamProvider<List<ProgressPhoto>>((ref) {
  final db = ref.watch(databaseProvider);
  return watchTables(db, [db.progressPhotos],
      () => ref.read(bodyDaoProvider).getAllPhotos());
});
```

## 5. Görsel boyut

Telefon kamerası 3–12 MB JPEG üretir. Ham saklamak konteyneri haftada yüzlerce
MB şişirir ve dilim 2'nin depolama maliyetini anlamsız kılar. Kayıtta küçültme:
`maxWidth: 1440`, `imageQuality: 85` → fotoğraf başına ~250–400 KB. Haftada 3
fotoğraf = yılda ~55 MB, kabul edilebilir. Vücut kompozisyonu değerlendirmesi
için 1440 px fazlasıyla yeterli.

## 6. Gizlilik

Bunlar uygulamanın topladığı **en hassas veri** — çoğu iç çamaşırıyla çekilir.
Kurallar:

1. Dilim 1'de fotoğraflar cihazdan **çıkmaz**. Ağ çağrısı yok.
2. Dilim 2'nin yüklemesi **varsayılan açık olmayacak** — kullanıcı açıkça
   onaylayacak, ne yüklendiği anlatılarak. Senkronun geri kalanı sessizce çalışır;
   burada sessizlik yanlış olur.
3. Dosyalar uygulama konteynerinde durur, cihaz galerisine yazılmaz — galeriye
   yazmak fotoğrafları Google Photos/iCloud yedeğine ve diğer uygulamalara açardı.
4. Hesap değişimi hepsini siler (K-2).

## 7. Bitti tanımı

- [x] `flutter analyze` 0
- [x] `PhotoStorage` birim testleri (ad üretimi, yol çözümü, silme, yetim süpürme) — 9 test
- [x] Senkron muafiyeti testi: fotoğraf satırı gönderilmez, çekilmez, göstergede "bekliyor" sayılmaz
- [x] Hesap değişimi testi: satırlar **ve** dosyalar gider
- [ ] Emülatörde: çek → galeride gör → karşılaştır → sil — **bekliyor** (Mac ekranına erişilemedi)
- [ ] iOS turu (UI ağırlıklı iş — hafıza kuralı gereği) — **bekliyor**
- [x] `PROJECT_STATE.md` / `NEXT_TASKS.md` güncel

## 8. Uygulama notları (2026-09-19)

- **Senkron muafiyeti** senkron v2 üzerine kuruldu (`syncRemoteExcluded`,
  `syncRemoteTables`): gönderim, çekme, mezar taşı gönderimi ve senkron
  göstergesi fotoğrafları atlar; hesap temizliği atlamaz.
- **Bilinçli sapma — hesap değişimi uyarısı fotoğrafları SAYAR.** K-2 "kuyruk
  sayımı bu kümeyi atlar" diyordu; senkron göstergesi için doğru, ama hesap
  değişimindeki "N kayıt henüz yüklenmedi" sayımı için yanlış olurdu:
  fotoğraflar sunucuya hiç gitmediği için temizlik onları geri dönüşsüz
  siler. Sayılmasalardı kullanıcı en hassas verisini sessizce kaybederdi.
- **Silme sırası:** önce satır, sonra dosya. Arada uygulama kapanırsa dosya
  yetim kalır ve galeri açılışındaki süpürme onu siler; ters sırada galeride
  kırık bir kare kalırdı. **Ekleme:** önce dosya, sonra satır; satır
  yazılamazsa kopya geri silinir.
- **Yetim süpürme** "açılışta" yerine **galeri açılışında** çalışıyor: yerel
  ve ucuz, uygulama başlangıcını yavaşlatmıyor; hesap temizliği klasörü
  zaten tamamen siliyor.
- **Güvenlik:** dosya adı `../` ya da `/` içeriyorsa yol çözülmez — bozuk bir
  satır klasör dışındaki bir dosyaya dokunamaz.
- **iOS izin metinleri:** kamera metni fotoğrafı da kapsayacak şekilde
  genişletildi, galeri izni (`NSPhotoLibraryUsageDescription`) eklendi; ikisi
  de tr/en ve "fotoğraflar bu cihazda kalır" diyor.
- Giriş: İlerleme sekmesinde aktivite takviminin altında kart.
