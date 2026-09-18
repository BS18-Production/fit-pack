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
