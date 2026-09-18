# Sunucu testleri

Bu klasördeki SQL dosyaları **yalnız `Fit Pack Dev`** projesinde çalıştırılır
(`qecbnrkbordkqeogmevi` — docs/20 §10.4). Üretim projesinde ÇALIŞTIRILMAZ:
test verisi yazarlar.

Yerel Docker yığını kurulmadığı için `supabase test db` / `pg_prove` koşucusu
yok; dosyalar doğrudan çalıştırılır.

| Dosya | Kapsam |
|---|---|
| `sync_v2_stage3.sql` | `sync_guard` çakışma kuralı, saat kırpma, silme kazanır, yetkiler (29 test) |

## Çalıştırma

1. Dosyanın tamamını çalıştır (fonksiyonu kurar).
2. `select * from public.run_sync_v2_stage3_tests();`

Çıktı TAP biçimindedir (`ok N - açıklama`). Tek cümle = tek transaction:
hata çıkarsa tamamı geri alınır, başarıyla biterse fonksiyon test
kullanıcısını siler ve `on delete cascade` kalan her şeyi götürür.

## PostgREST üzerinden uçtan uca doğrulama

pgTAP SQL katmanını ölçer. İstemcinin gerçekten dayandığı şey ise
**PostgREST'in `upsert(...).select()` çağrısının reddedilen satırı
düşürmesidir**. Bu, 2026-09-18'de gerçek HTTP çağrılarıyla doğrulandı
(Aşama 4): tek satırlık ret boş dizi döndü, karışık toplu gönderimde yalnız
kabul edilen satır döndü, sayfalı çekme 5+5+4 ile 14 satırı tekrarsız
indirdi, `deleted_records` üzerinde DELETE 403 verdi.

Tekrarlamak gerekirse: `auth.users`'a doğrudan bir test hesabı eklerken
GoTrue'nun `confirmation_token` gibi alanları **boş string** olmalı (NULL
"Database error querying schema" verir) ve `auth.identities` kaydı şarttır.

## Cihaz duman testi (Aşama 4, 2026-09-18)

Uygulamayı test projesine bağlayıp **temiz** bir simülatörde çalıştır —
Samet'in simülatöründe (iPhone 17) yerel veri var, farklı hesapla girmek onu
etkiler:

```bash
xcrun simctl boot <temiz-simulator-id>
flutter run -d <temiz-simulator-id> \
  --dart-define=SUPABASE_URL=https://qecbnrkbordkqeogmevi.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_aQZzc4k4q8DSZ5VQdCujTQ_nfOMZmw4
```

Yerel veritabanını doğrudan okumak, arayüzü sürmekten güvenilir:

```bash
DB=$(xcrun simctl get_app_container <id> com.sametorhan.fitPack data)/Documents/fit_pack.sqlite
sqlite3 "$DB" "SELECT kcal_goal, server_rev, sync_state FROM user_profile"
```

**Simülatöre metin girme:** cliclick/AppleScript tuş vuruşları alana ulaşmıyor.
Çalışan yöntem `xcrun simctl pbcopy <id>` ile panoya koyup alana iki kez
dokunmak ve çıkan **Paste**'e basmak. İlk odaklanmada iOS'un klavye tanıtım
sayfası çıkabilir; "Continue" ile kapatılır.

**Ölçülen sonuç (2026-09-18):** giriş → açılışta tam uzlaştırma → profil
`changed_at_ms` ile gönderildi, sunucu `server_rev` atadı ve istemci onu
yerele yazdı. Sonra sunucu tarafında satır değiştirildi (kalori 2200 → 2750,
`server_rev` 45 → 46); uygulama yeniden açılınca **değişiklik yerele indi**,
satır kuyruğa geri GİRMEDİ (tetikleyiciler doğru susturulmuş) ve imleç payla
(46 − 1000 → 0) yazıldı.
