# docs/13 — Bulut Yedek + Hesap (Supabase)

> ## ⛔ YÜRÜRLÜKTEN KALKTI — 2026-07-21
> Bu dokümanın **Faz 1 (Storage blob yedek)** yaklaşımı terk edildi. Yerine
> **[docs/18-auth-and-sync.md](18-auth-and-sync.md)** geçti: zorunlu hesap +
> mirror tablolar + otomatik senkron.
>
> **Kaldırılanlar:** elle "Buluta Yedekle" / "Buluttan Geri Yükle" düğmeleri,
> `cloud_backup_service.dart`, `backups` Storage bucket'ı. Samet kararı: hesap
> açan kullanıcının verisi zaten otomatik saklanacağı için elle yedekleme hem
> gereksiz hem kafa karıştırıcı.
>
> **Hâlâ geçerli olan:** §3.1 Auth kurulumu (e-posta + Google) — docs/18
> bunun üstüne inşa ediliyor. Storage/RLS bölümleri yalnız `ProgressPhotos`
> görselleri için referans niteliğinde.

> **Durum:** Tasarım v1.0 — 2026-06-30 (SÜPERSEDE EDİLDİ)
> **Karar:** Samet — Supabase free tier · kapsam = **bulut yedek (tek yön)** ·
> giriş = **e-posta/şifre + Google** · local-first KORUNUR
> **Bağlı:** [docs/12](12-session-resilience.md) (yerel yedek), [docs/02-architecture.md](02-architecture.md)

---

## 1. Amaç & kapsam

**Faz 1 (bu doküman): Hesap tabanlı bulut yedek.**
- Kullanıcı giriş yapar (e-posta/şifre veya Google).
- "Buluta Yedekle" → cihazdaki `fit_pack.sqlite` Supabase'e yüklenir.
- "Buluttan Geri Yükle" → yeni cihaz/yeniden kurulumda hesapla giriş → veri iner.
- **Tek yön + manuel** (otomatik canlı senkron DEĞİL). Çakışma (conflict) yok.
- **Local-first değişmez:** doğruluk kaynağı hâlâ cihazdaki drift. Bulut = kopya.

**Kapsam dışı (ileride Faz 2 — ayrı doc):** çoklu cihaz canlı senkron, çakışma
çözümü, satır bazlı delta. O iş "mirror tablolar" gerektirir (aşağıda not).

## 2. Mimari karar: Storage blob mı, mirror tablo mu?

| | **A. Storage blob (.sqlite yükle)** ✅ Faz 1 | **B. Mirror tablolar** |
|---|---|---|
| Ne | `fit_pack.sqlite` dosyasını Supabase Storage'a yükle | Her tabloyu Postgres'te yeniden kur, satır satır upsert |
| Karmaşıklık | Düşük — mevcut `backup_service`'i kullanır | Yüksek |
| Sorgulanır mı | Hayır (opak dosya) | Evet |
| Sync temeli | Hayır | Evet |
| Faz 1 için | **Doğru seçim** | Gereksiz |

**Karar: A (Storage blob).** Zaten `backup_service.dart` bir `.sqlite` yedeği
üretiyor (docs/12); onu Drive yerine (ya da ek olarak) Supabase Storage'a
yükleriz. Hızlı, sağlam, solo kullanıma yeter. Faz 2 sync gelince mirror tablolar
o zaman kurulur (zaten büyük iş, baştan yapmak israf).

## 3. Supabase tarafı

### 3.1 Auth
- **Sağlayıcılar:** Email/Password + Google.
- Email: Supabase Auth varsayılan; e-posta doğrulama açık (ücretsiz).
- Google: Supabase → Authentication → Providers → Google; Google Cloud Console'da
  OAuth client (Web + Android) gerekir (Samet kurar, §5).

### 3.2 Storage
- **Bucket:** `backups` (private).
- **Yol deseni:** `{user_id}/fit_pack.sqlite` — kullanıcı başına tek güncel yedek
  (üzerine yazılır; istenirse tarihli sürümler Faz 1.1).
- **RLS (Row Level Security) — kritik:** kullanıcı SADECE kendi klasörüne
  yazabilir/okuyabilir. Politika (Storage objects):
  ```sql
  -- okuma
  create policy "own backups read" on storage.objects for select
    using ( bucket_id = 'backups' and (storage.foldername(name))[1] = auth.uid()::text );
  -- yazma/güncelleme
  create policy "own backups write" on storage.objects for insert
    with check ( bucket_id = 'backups' and (storage.foldername(name))[1] = auth.uid()::text );
  create policy "own backups update" on storage.objects for update
    using ( bucket_id = 'backups' and (storage.foldername(name))[1] = auth.uid()::text );
  ```

## 4. Uygulama tarafı (kod — anahtarlar gelince)

- **Paket:** `supabase_flutter`.
- **Init:** `main.dart`'ta `Supabase.initialize(url, anonKey)`.
- **Anahtarlar:** URL + **anon key** uygulamaya gömülür (anon key publishable,
  RLS koruyor → güvenli). **service_role key ASLA uygulamada olmaz.**
  - Saklama: `--dart-define` ile build'e geçir (repoya commit etme) ya da
    `lib/core/config/supabase_config.dart` (gitignore'lu). Karar: dart-define.
- **AuthService:** signUp/signIn (email), signInWithGoogle, signOut, authState
  stream. Riverpod provider.
- **CloudBackupService:**
  - `backupToCloud()`: `backup_service.exportToTemp()` → Storage'a
    `{uid}/fit_pack.sqlite` upsert.
  - `restoreFromCloud()`: indir → `backup_service.restoreFromFile()` (mevcut akış:
    db.close + üstüne yaz + restart).
  - `lastBackupAt()`: Storage obje metadata'sından son yedek zamanı.
- **UI:** Ayarlar → Verilerim → "Bulut Hesabı" bölümü:
  - Çıkışta: Giriş/Kayıt ekranı (e-posta + Google butonu).
  - Girişte: e-posta göster · "Buluta Yedekle" · "Buluttan Geri Yükle" ·
    "Son bulut yedeği: …" · Çıkış.
- **Soyutlama:** `SyncBackend` arayüzü (backupToCloud/restoreFromCloud) — Faz 2'de
  mirror-tablo sync ya da başka sağlayıcı gelirse takılabilir kalsın.

## 5. SAMET'İN YAPACAKLARI (kod öncesi gerekli)

1. **Supabase projesi aç:** supabase.com → New project (free). Bölge: Avrupa
   (eu-central / Frankfurt — Türkiye'ye yakın gecikme).
2. **Anahtarları ver:** Project Settings → API → **Project URL** + **anon public
   key**. (⚠️ `service_role` key'i verme/koyma.)
3. **Storage bucket:** `backups` adında **private** bucket oluştur.
4. **RLS politikaları:** SQL Editor → §3.2'deki politikaları çalıştır.
5. **Google girişi (opsiyonel ama istendi):** Google Cloud Console → OAuth consent
   + Credentials → OAuth client (Android için SHA-1 + package
   `com.sametorhan.fit_pack`; Web client de gerekir) → client ID/secret'ı
   Supabase → Auth → Providers → Google'a gir. (Adım adım birlikte yaparız.)
6. Bunları verince kod + emülatör testi bende.

## 6. Doğrulama planı
- Emülatör: kayıt ol → giriş → Buluta Yedekle (Storage'da `{uid}/fit_pack.sqlite`
  görünür) → uygulamayı sil/yeniden kur → giriş → Buluttan Geri Yükle → veri yerinde.
- RLS testi: ikinci hesapla giriş → birincinin yedeğine erişemez.
- Çıkış → bulut butonları gizli, sadece local yedek (docs/12) açık kalır.

## 7. Maliyet / ölçek (free tier)
- Solo kullanım: 500 MB DB + 1 GB Storage + 50K MAU → fazlasıyla yeter.
- Yedek dosyası birkaç MB, kullanıcı başına tek dosya → Storage derdi yok.
- Yayın + kullanıcı + gelir gelince → **Pro $25** (free→Pro = kod değişmez, kart ekle).
- Not: free proje 7 gün hareketsizlikte durabilir; solo aktif kullanımda sorun değil.
