-- Fit Pack — Senkron v2, Aşama 3: sunucu sürümü (docs/20 §4.2)
--
-- KARAR ÖZETİ
-- Sunucu artık her kabul edilen yazmaya artan bir sürüm numarası (`server_rev`)
-- veriyor ve çakışmayı kendisi çözüyor: gelen satırın değişim zamanı
-- (`changed_at_ms`) sunucudakinden yeni değilse yazma ATLANIR. İstemci hangi
-- satırın kabul edildiğini `RETURNING` sonucundan anlar.
--
-- NE ÇÖZÜYOR (docs/20 §1)
-- • #4 — sunucuda çakışma çözümü yoktu; son yazan körlemesine eziyordu.
-- • #5 hazırlığı — `server_rev` çekme imlecinin anahtarı (sayfalama).
-- • K-3 hazırlığı — silinen kimlik hiçbir yazmayla geri gelemez.
--
-- ⚠️ YAYIN KURALI: Bu SQL ve istemcinin Aşama 4'ü **aynı sürümde** çıkar.
--    Eski istemci `changed_at_ms` göndermez → değeri 0 kalır → `sync_guard`
--    onu "yeni değil" sayıp yazmayı reddeder. Sunucu tek başına güncellenirse
--    telefondaki eski sürüm sessizce yazamaz hale gelir.
--
-- ⚠️ GERİ DÖNÜŞ (CONVENTIONS §3 madde 8): kolonların varsayılanı var, tablo
--    silinmiyor, tip daralmıyor. Eski istemci OKUYABİLİR; YAZAMAZ (yukarıdaki
--    kural). Geri dönüş gerekirse `sync_guard` tetikleyicilerini düşürmek
--    yeterli — veri kaybı olmaz, kolonlar kalır:
--      drop trigger sync_guard_trg on public.<tablo>;  -- 12 tablo
--
-- ⚠️ ÜRETİME UYGULAMADAN ÖNCE: panel yedeği al (docs/20 §11).
--    Bu dosya önce `Fit Pack Dev` projesinde yeşile döner (docs/20 §10.4).

-- ─────────────────────── 1. Sürüm dizisi ───────────────────────
-- Tek dizi, BÜTÜN tablolar için ortak. Çekme imleci tek bir sayı ile
-- "şu ana kadar gördüklerim" diyebilsin diye tablo başına ayrı dizi YOK.

create sequence if not exists public.sync_rev_seq as bigint start with 1;

-- İstemci rolü `nextval` çağırabilmeli: `sync_guard` SECURITY INVOKER'dır,
-- yani tetikleyici yazmayı yapan kullanıcının yetkisiyle çalışır. Bu grant
-- unutulursa HER yazma "permission denied for sequence" ile düşer.
grant usage on sequence public.sync_rev_seq to authenticated;

-- ─────────────────────── 2. Silme işaretleri ───────────────────────
-- Satırın İÇERİĞİ burada YOK — yalnız "şu kimlik silindi" bilgisi (KVKK).
-- Tabloyu Aşama 3 kuruyor çünkü `sync_guard` ona bakıyor (silme kazanır).
-- İşareti YAZAN silme tetikleyicileri ve `sync_delete` RPC'si Aşama 5'te
-- gelir; bu aşamada tablo boş kalır ve kontrol her zaman "hayır" döner.

create table if not exists public.deleted_records (
  user_id       uuid   not null references auth.users(id) on delete cascade,
  table_name    text   not null,
  uid           uuid   not null,
  deleted_at_ms bigint not null,
  server_rev    bigint not null default nextval('public.sync_rev_seq'),
  primary key (user_id, table_name, uid)
);

-- Çekme imleci: "bu kullanıcının benden sonraki silmeleri".
create index if not exists deleted_records_user_rev_idx
  on public.deleted_records(user_id, server_rev);

alter table public.deleted_records enable row level security;
drop policy if exists "own rows" on public.deleted_records;
create policy "own rows" on public.deleted_records
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- İstemci işaretleri OKUR ve (Aşama 5'te tetikleyici aracılığıyla) YAZAR.
-- UPDATE/DELETE verilmez: işaretin silinmesi silinmiş satırı diriltirdi.
-- (`alter default privileges` dörtünü birden verdiği için açıkça geri alınır.)
grant select, insert on public.deleted_records to authenticated;
revoke update, delete on public.deleted_records from authenticated;

-- ─────────────────────── 3. Çakışma tetikleyicisi ───────────────────────

create or replace function public.sync_guard()
returns trigger
language plpgsql
as $fn$
declare
  now_ms bigint := (extract(epoch from now()) * 1000)::bigint;
begin
  -- Saat sapması: gelecekten gelen damga şimdiye kırpılır. 5 dk tolerans,
  -- çünkü küçük sapmalar normaldir; kırpma olmadan ileri saatli bir cihaz
  -- kendi satırını sonsuza kadar "en yeni" yapar ve başka cihaz yazamaz.
  if new.changed_at_ms > now_ms + 300000 then
    new.changed_at_ms := now_ms;
  end if;

  -- K-3: SİLME HER ZAMAN KAZANIR. Silinmiş kimlik hiçbir yazmayla geri
  -- gelmez — çevrimdışı kalmış bir cihazın eski kopyası satırı diriltemesin.
  if exists (
    select 1 from public.deleted_records d
     where d.user_id    = new.user_id
       and d.table_name = tg_table_name
       and d.uid        = new.uid
  ) then
    return null;
  end if;

  if tg_op = 'UPDATE' then
    -- K-2: gelen sürüm sunucudakinden YENİ DEĞİLSE yazma atlanır.
    -- Eşitlikte sunucu kazanır (docs/20 §5.2): aynı satırın tekrar
    -- gönderimi (zaman aşımı sonrası yeniden deneme) sunucuda değişiklik
    -- yaratmaz, `server_rev` boşuna artmaz, öteki cihaz onu tekrar indirmez.
    if new.changed_at_ms <= old.changed_at_ms then
      return null;
    end if;
  end if;

  -- Buraya gelen yazma KABUL edildi.
  new.server_rev := nextval('public.sync_rev_seq');
  -- `updated_at` sunucu saatinden — istemcinin saati sapsa bile v1 çekmesi
  -- (updated_at imleci) doğru çalışsın.
  new.updated_at := now();
  return new;
end $fn$;

comment on function public.sync_guard() is
  'Senkron v2 çakışma kuralı (docs/20 §4.2). BEFORE INSERT OR UPDATE; NULL '
  'dönerse yazma atlanır ve satır RETURNING sonucunda görünmez — istemci '
  'reddi buradan anlar.';

-- ─────────────────────── 4. Tablolara uygulama ───────────────────────
-- 12 senkron tablosunun hepsine aynı beş adım. Elle 60 satır yazmak yerine
-- döngü: bir tabloyu atlamak sessiz bir senkron hatası olurdu.

do $mig$
declare
  t text;
  tables text[] := array[
    'user_profile', 'exercises', 'foods', 'routines', 'routine_exercises',
    'workout_sessions', 'workout_sets', 'food_logs', 'recipe_items',
    'water_intake', 'body_measurements', 'progress_photos'
  ];
begin
  foreach t in array tables loop
    -- 4.1 Kolonlar. Varsayılanları var → mevcut satırlar bozulmaz.
    execute format(
      'alter table public.%I add column if not exists changed_at_ms bigint not null default 0', t);
    execute format(
      'alter table public.%I add column if not exists server_rev bigint not null default 0', t);

    -- 4.2 Geçmiş satırların doldurulması (idempotent: yalnız 0 olanlar).
    -- `changed_at_ms` = updated_at'in milisaniyesi; yoksa bütün eski satırlar
    -- "en eski" görünür ve ilk gerçek yazma hepsini ezerdi.
    execute format(
      'update public.%I set changed_at_ms = (extract(epoch from updated_at) * 1000)::bigint
         where changed_at_ms = 0', t);
    -- `server_rev` = diziden. Sıra önemli değil: her satır ayrı bir numara
    -- alır ve yeni istemci imleç 0'dan başlayıp hepsini indirir.
    execute format(
      'update public.%I set server_rev = nextval(''public.sync_rev_seq'')
         where server_rev = 0', t);

    -- 4.3 Çekme imlecinin dizini.
    execute format(
      'create index if not exists %I on public.%I(user_id, server_rev)',
      t || '_user_rev_idx', t);

    -- 4.4 Gönderimin çakışma hedefi. Bugün birincil anahtar yalnız `uid`,
    -- yani bu dizin gereksiz görünüyor — ama PostgREST'in
    -- `on_conflict=user_id,uid` çağrısı TAM bu kolonlarda bir tekil dizin
    -- arar (Aşama 4 böyle gönderiyor). Aşama 6'da birincil anahtar
    -- `(user_id, uid)` olunca yerini o alır.
    execute format(
      'create unique index if not exists %I on public.%I(user_id, uid)',
      t || '_user_uid_key', t);

    -- 4.5 Tetikleyici.
    execute format('drop trigger if exists sync_guard_trg on public.%I', t);
    execute format(
      'create trigger sync_guard_trg before insert or update on public.%I
         for each row execute function public.sync_guard()', t);
  end loop;
end $mig$;
