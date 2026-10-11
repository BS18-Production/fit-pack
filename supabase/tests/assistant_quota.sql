-- Yalnız Dev/test: bütün yazmalar ROLLBACK; fitness tablolarına dokunulmaz.
begin;
insert into auth.users(id,aud,role,email) values
  ('eeeeeeee-1111-4111-8111-111111111111','authenticated','authenticated','assistant-quota-test@example.invalid');
set local role service_role;
do $$
declare
  owner constant uuid := 'eeeeeeee-1111-4111-8111-111111111111';
  request constant uuid := 'aaaaaaaa-1111-4111-8111-111111111111';
  day text := (clock_timestamp() at time zone 'America/Los_Angeles')::date::text;
  minute text := date_trunc('minute',clock_timestamp())::text;
  result jsonb; n integer;
begin
  if has_function_privilege('anon','public.assistant_reserve(uuid,uuid)','execute')
    or has_function_privilege('authenticated','public.assistant_reserve(uuid,uuid)','execute') then raise exception 'public RPC access'; end if;
  if has_schema_privilege('anon','assistant_private','usage') or has_schema_privilege('authenticated','assistant_private','usage') then raise exception 'private schema exposed'; end if;
  -- İzole kota fikstürü; gerçek Dev sayaçları transaction sonunda aynen döner.
  delete from assistant_private.counters;
  result := public.assistant_reserve(owner,request);
  if result->>'allowed' <> 'true' then raise exception 'first reservation denied'; end if;
  if (result->>'reset_at')::timestamptz at time zone 'America/Los_Angeles' <> (day::date+1)::timestamp then raise exception 'Pacific reset'; end if;
  result := public.assistant_reserve(owner,request);
  if result->>'error' <> 'duplicate_request' then raise exception 'duplicate allowed'; end if;
  select requests into n from assistant_private.counters where scope='day' and bucket=day;
  if n <> 1 then raise exception 'duplicate consumed quota'; end if;
  update assistant_private.counters set requests=20 where scope='user';
  result := public.assistant_reserve(owner,gen_random_uuid());
  if result->>'error' <> 'daily_quota' then raise exception 'user quota'; end if;
  update assistant_private.counters set requests=0 where scope='user';
  update assistant_private.counters set requests=400 where scope='day';
  result := public.assistant_reserve(owner,gen_random_uuid());
  if result->>'error' <> 'daily_quota' then raise exception 'project quota'; end if;
  update assistant_private.counters set requests=1 where scope='day';
  update assistant_private.counters set requests=10 where scope='minute';
  result := public.assistant_reserve(owner,gen_random_uuid());
  if result->>'error' <> 'minute_quota' then raise exception 'minute quota'; end if;
  update assistant_private.counters set requests=1,input_tokens=190000 where scope='minute';
  result := public.assistant_reserve(owner,gen_random_uuid());
  if result->>'error' <> 'minute_quota' then raise exception 'token budget'; end if;
  update assistant_private.counters set requests=9,input_tokens=135000 where scope='minute';
  result := public.assistant_reserve(owner,gen_random_uuid());
  if result->>'allowed' <> 'true' then raise exception 'tenth reservation denied'; end if;
  select requests into n from assistant_private.counters where scope='minute' and bucket=minute;
  if n <> 10 then raise exception 'minute count'; end if;
  result := public.assistant_reserve(owner,gen_random_uuid());
  if result->>'error' <> 'minute_quota' then raise exception 'eleventh request allowed'; end if;
end;
$$;
reset role;
select 'assistant quota: permissions, Pacific reset, deduplication, user/day/minute/token boundaries passed' as result;
rollback;
