-- Yalnız Dev/test: bütün yazmalar ROLLBACK (CR-024, 20261017120000 göçü).
begin;
insert into auth.users(id,aud,role,email) values
  ('eeeeeeee-2222-4222-8222-222222222222','authenticated','authenticated','assistant-retention-test@example.invalid');
set local role service_role;
do $$
declare
  owner constant uuid := 'eeeeeeee-2222-4222-8222-222222222222';
  old_req constant uuid := 'bbbbbbbb-2222-4222-8222-000000000001';
  fresh_req constant uuid := 'bbbbbbbb-2222-4222-8222-000000000002';
  result jsonb;
begin
  delete from assistant_private.counters;
  insert into assistant_private.requests(owner_id,request_id,created_at) values
    (owner,old_req,clock_timestamp()-interval '9 days'),
    (owner,fresh_req,clock_timestamp()-interval '7 days');
  result := public.assistant_reserve(owner,gen_random_uuid());
  if result->>'allowed' <> 'true' then raise exception 'reservation denied'; end if;
  if exists(select 1 from assistant_private.requests where request_id=old_req) then
    raise exception '9 günlük kimlik silinmedi'; end if;
  if not exists(select 1 from assistant_private.requests where request_id=fresh_req) then
    raise exception '7 günlük kimlik erken silindi'; end if;
  -- 7 günlük kimlik hâlâ tekrar sayılır; 9 günlük kimlik yeni istektir.
  result := public.assistant_reserve(owner,fresh_req);
  if result->>'error' <> 'duplicate_request' then raise exception 'taze tekrar kabul edildi'; end if;
  result := public.assistant_reserve(owner,old_req);
  if result->>'allowed' <> 'true' then raise exception 'eski kimlik yeni istek sayılmadı'; end if;
end;
$$;
reset role;
select 'assistant requests retention: 8-day prune, fresh duplicate kept, expired id re-admitted passed' as result;
rollback;
