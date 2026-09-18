-- Fit Pack — Senkron v2, Aşama 5: silme protokolü (docs/20 §4.2, §5.3)
--
-- KARAR ÖZETİ
-- Silme artık öteki cihaza taşınıyor. Satır sunucuda **gerçekten siliniyor**,
-- yerine yalnız "şu kimlik silindi" işareti kalıyor (`deleted_records`).
-- İşareti AFTER DELETE tetikleyicisi yazıyor, silmeyi istemci `sync_delete`
-- fonksiyonuyla istiyor.
--
-- NE ÇÖZÜYOR
-- • #1 — "sildiğim öğün/ölçüm/antrenman bir sonraki açılışta geri geliyor".
--   Bugün silme sunucuya HİÇ gitmiyor; çekme satırı geri ekliyor.
--
-- NEDEN İÇERİK SAKLANMIYOR
-- İşaret yalnız kimlik taşır. Silinen kaydın kendisi sunucuda kalsaydı
-- "sildim" demek bir şey ifade etmezdi (KVKK / kişisel veri). Aşama 3'teki
-- `sync_guard` de bu işarete bakıp silinmiş kimliğin dirilmesini engelliyor.
--
-- ⚠️ YAYIN: Aşama 5 kendi sürümünde çıkar (docs/20 §11). Eski istemci
--    `sync_delete`'i çağırmaz ve `deleted_records`'u çekmez — yani silmeyi
--    yaymaz, ama bozulmaz da. Geri dönüş: tetikleyicileri düşürmek yeterli,
--    veri kaybı olmaz:
--      drop trigger sync_mark_deleted_trg on public.<tablo>;  -- 12 tablo
--
-- ⚠️ ÜRETİME UYGULAMADAN ÖNCE: panel yedeği al. Önce `Fit Pack Dev`.

-- ─────────────────── 1. Silme işaretini yazan tetikleyici ───────────────────

-- ⚠️ SECURITY DEFINER — nedeni ve neden güvenli olduğu:
--
-- Fonksiyon `auth.users`'a bakmak ZORUNDA (aşağıdaki hesap silme istisnası).
-- İstemci rolü `authenticated`'ın o tabloya SELECT yetkisi YOKTUR ve
-- olmamalıdır (herkesin e-postası ve parola özeti orada). SECURITY INVOKER
-- bırakılsaydı **gerçek bir kullanıcının her silmesi** "permission denied for
-- table users" ile patlardı — superuser olarak koşan testlerde görünmeyen,
-- ancak gerçek rolle ölçünce çıkan bir hata (tam olarak böyle yakalandı).
--
-- Neden yetki yükseltmesi değil: fonksiyon dışarıdan hiçbir girdi almaz.
-- Yazdığı tek satır `OLD`'dan türer ve `OLD`, çağıranın RLS gereği zaten
-- silebildiği bir satırdır. Başkasının adına işaret yazmanın yolu, önce
-- başkasının `user_id`'siyle satır eklemekten geçer; bunu tablo politikasının
-- `with check (auth.uid() = user_id)` kuralı engeller.
-- `search_path` boşaltıldı: sahte bir şema `auth.users`'ı gölgeleyemesin.

create or replace function public.sync_mark_deleted()
returns trigger
language plpgsql
security definer
set search_path = ''
as $fn$
begin
  -- `uid` kontrolü YOK: sunucuda her senkron tablosunun birincil anahtarı
  -- `uid`, yani NULL olamaz. Savunma amaçlı bir `if old.uid is null` dalı
  -- yazıldı ve testle ölü kod olduğu görülüp kaldırıldı — kapsanamayan
  -- savunma kodu, olmayan koddan daha kötüdür (okuyanı yanıltır).
  --
  -- HESAP SİLME İSTİSNASI. `delete from auth.users` önce kullanıcıyı siler,
  -- sonra zincirleme bu tabloları siler. O sırada işaret yazmaya kalkarsak
  -- `deleted_records.user_id` artık olmayan bir kullanıcıya bakar ve yabancı
  -- anahtar ihlaliyle **hesap silme işlemi patlar** (ölçüldü: 23503).
  -- Kullanıcı gittiyse işaretin de bir anlamı yok.
  if not exists (select 1 from auth.users u where u.id = old.user_id) then
    return old;
  end if;

  insert into public.deleted_records
    (user_id, table_name, uid, deleted_at_ms, server_rev)
  values (
    old.user_id,
    tg_table_name,
    old.uid,
    (extract(epoch from now()) * 1000)::bigint,
    nextval('public.sync_rev_seq')
  )
  on conflict (user_id, table_name, uid) do nothing;

  return old;
end $fn$;

comment on function public.sync_mark_deleted() is
  'Senkron v2 silme izi (docs/20 §5.3). AFTER DELETE; silinen satirin yalnız '
  'kimligini deleted_records tablosuna yazar, icerigini degil.';

-- ─────────────────── 2. Silme isteği (RPC) ───────────────────
-- RPC = uzaktan çağrılan sunucu fonksiyonu. İstemci tabloya doğrudan DELETE
-- atabilirdi; fonksiyon iki şey ekliyor: tablo adının sabit listeye karşı
-- doğrulanması (SQL enjeksiyonuna kapı yok) ve hangi kimliklerin gerçekten
-- silindiğinin dönmesi.
--
-- SECURITY INVOKER (varsayılan): RLS geçerli, kullanıcı yalnız kendi
-- satırlarını silebilir. SECURITY DEFINER olsaydı fonksiyon RLS'i atlar ve
-- tablo adı doğrulaması tek savunma hattı kalırdı.

create or replace function public.sync_delete(p_table text, p_uids uuid[])
returns table (uid uuid)
language plpgsql
as $fn$
declare
  izinli text[] := array[
    'user_profile', 'exercises', 'foods', 'routines', 'routine_exercises',
    'workout_sessions', 'workout_sets', 'food_logs', 'recipe_items',
    'water_intake', 'body_measurements', 'progress_photos'
  ];
begin
  if p_table is null or not (p_table = any (izinli)) then
    raise exception 'sync_delete: bilinmeyen tablo %', p_table
      using errcode = '22023';
  end if;
  if p_uids is null or cardinality(p_uids) = 0 then
    return;
  end if;

  -- `user_id = auth.uid()` RLS'in üstüne ikinci kilit: politika bir gün
  -- gevşetilirse burası yine de başkasının satırına dokundurmaz.
  return query execute format(
    'delete from public.%I where user_id = auth.uid() and uid = any($1) '
    'returning uid', p_table)
    using p_uids;
end $fn$;

comment on function public.sync_delete(text, uuid[]) is
  'Senkron v2 silme cagrisi (docs/20 §5.3). Tablo adi sabit listeye karsi '
  'dogrulanir; RLS gecerlidir; gercekten silinen kimlikler doner.';

grant execute on function public.sync_delete(text, uuid[]) to authenticated;

-- ─────────────────── 3. Tetikleyicileri tablolara bağla ───────────────────
-- Zincirleme silmeler de bu tetikleyiciyi çalıştırır: seans silinince
-- setlerinin işaretleri de kendiliğinden oluşur (workout_sets.session_uid
-- ... on delete cascade).

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
    execute format('drop trigger if exists sync_mark_deleted_trg on public.%I', t);
    execute format(
      'create trigger sync_mark_deleted_trg after delete on public.%I
         for each row execute function public.sync_mark_deleted()', t);
  end loop;
end $mig$;
