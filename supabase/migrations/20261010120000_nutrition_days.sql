-- Fit Pack — beslenme günü tamamlandı (docs/37, #8): 13. senkron tablosu.
--
-- İstemci şema v15'ten ÖNCE uygulanır (docs/37 §4 Aşama 6). Yalnız EKLEME:
-- mevcut hiçbir tablo/satır değişmez; sync_delete'in izin listesi büyür.
--
-- ⚠️ Birincil anahtar (user_id, uid): satır kimliği gün metninden türetilir
-- (UUIDv5, kullanıcıdan bağımsız) → iki kullanıcının aynı günü AYNI uid'i
-- üretir. Diğer tablolarda PK hâlâ yalnız `uid` (docs/20 Aşama 6 bekliyor);
-- bu tablo yeni olduğu için baştan doğru anahtarla kurulur. İstemcinin
-- `on_conflict=user_id,uid` gönderimi bu birincil anahtara oturur.

-- ───────────────────────────── 1. Tablo ─────────────────────────────
create table if not exists public.nutrition_days (
  uid             uuid        not null,
  user_id         uuid        not null references auth.users(id) on delete cascade,
  updated_at      timestamptz not null default now(),
  day             text        not null check (day ~ '^\d{4}-\d{2}-\d{2}$'),
  status          text        not null check (status in ('complete', 'open')),
  completed_at_ms bigint,
  changed_at_ms   bigint      not null default 0,
  server_rev      bigint      not null default 0,
  primary key (user_id, uid),
  unique (user_id, day)
);

comment on table public.nutrition_days is
  'Beslenme günü "kaydım tamamlandı" durumu (docs/37). Gün başına tek satır; '
  'işaret kaldırma silme değil status=open.';

-- ──────────────────────── 2. Yetki + RLS ────────────────────────
alter table public.nutrition_days enable row level security;
drop policy if exists "own rows" on public.nutrition_days;
create policy "own rows" on public.nutrition_days
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
grant select, insert, update, delete on public.nutrition_days to authenticated;

-- ───────────── 3. Senkron v2: imleç dizini + çakışma + silme izi ─────────────
create index if not exists nutrition_days_user_rev_idx
  on public.nutrition_days(user_id, server_rev);

drop trigger if exists sync_guard_trg on public.nutrition_days;
create trigger sync_guard_trg before insert or update on public.nutrition_days
  for each row execute function public.sync_guard();

drop trigger if exists sync_mark_deleted_trg on public.nutrition_days;
create trigger sync_mark_deleted_trg after delete on public.nutrition_days
  for each row execute function public.sync_mark_deleted();

-- ─────────────── 4. sync_delete izin listesine ekleme ───────────────
-- Gövde Aşama 5'tekiyle aynı; yalnız liste büyüdü. search_path sabitlemesi
-- (2026-09-23 güvenlik sertleştirmesi) `create or replace` ile düşmesin diye
-- fonksiyon tanımına yazıldı.
create or replace function public.sync_delete(p_table text, p_uids uuid[])
returns table (uid uuid)
language plpgsql
set search_path = ''
as $fn$
declare
  izinli text[] := array[
    'user_profile', 'exercises', 'foods', 'routines', 'routine_exercises',
    'workout_sessions', 'workout_sets', 'food_logs', 'recipe_items',
    'water_intake', 'body_measurements', 'progress_photos', 'nutrition_days'
  ];
begin
  if p_table is null or not (p_table = any (izinli)) then
    raise exception 'sync_delete: bilinmeyen tablo %', p_table
      using errcode = '22023';
  end if;
  if p_uids is null or cardinality(p_uids) = 0 then
    return;
  end if;

  return query execute format(
    'delete from public.%I where user_id = auth.uid() and uid = any($1) '
    'returning uid', p_table)
    using p_uids;
end $fn$;

grant execute on function public.sync_delete(text, uuid[]) to authenticated;
