-- Asistan kotası fitness senkronundan ayrıdır; soru/cevap saklanmaz.
create schema if not exists assistant_private;
revoke all on schema assistant_private from public, anon, authenticated;
grant usage on schema assistant_private to service_role;

create table assistant_private.counters (
  scope text not null,
  bucket text not null,
  requests integer not null default 0 check (requests >= 0),
  input_tokens integer not null default 0 check (input_tokens >= 0),
  created_at timestamptz not null default now(),
  primary key (scope, bucket)
);
create table assistant_private.requests (
  owner_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (owner_id, request_id)
);
alter table assistant_private.counters enable row level security;
alter table assistant_private.requests enable row level security;
revoke all on assistant_private.counters, assistant_private.requests from public, anon, authenticated;
grant select, insert, update, delete on assistant_private.counters, assistant_private.requests to service_role;

create or replace function public.assistant_reserve(p_owner uuid, p_request uuid)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare
  v_now timestamptz := clock_timestamp();
  v_day text := (v_now at time zone 'America/Los_Angeles')::date::text;
  v_min text := date_trunc('minute', v_now)::text;
  v_user text := p_owner::text || ':' || v_day;
  v_reset timestamptz := (((v_now at time zone 'America/Los_Angeles')::date + 1)::timestamp at time zone 'America/Los_Angeles');
  v_user_n integer; v_day_n integer; v_min_n integer; v_tokens integer;
  -- UTF-8 istem + şema + en çok 500 karakter için temkinli üst rezervasyon.
  v_budget constant integer := 15000;
begin
  if p_owner is null or p_request is null then raise exception 'invalid_request'; end if;
  perform pg_advisory_xact_lock(61011108);
  if exists(select 1 from assistant_private.requests where owner_id=p_owner and request_id=p_request) then
    return jsonb_build_object('allowed',false,'error','duplicate_request');
  end if;
  select coalesce((select requests from assistant_private.counters where scope='user' and bucket=v_user),0) into v_user_n;
  select coalesce((select requests from assistant_private.counters where scope='day' and bucket=v_day),0) into v_day_n;
  select coalesce((select requests from assistant_private.counters where scope='minute' and bucket=v_min),0),
    coalesce((select input_tokens from assistant_private.counters where scope='minute' and bucket=v_min),0) into v_min_n,v_tokens;
  if v_user_n >= 20 or v_day_n >= 400 then
    return jsonb_build_object('allowed',false,'error','daily_quota','reset_at',v_reset);
  end if;
  if v_min_n >= 10 or v_tokens + v_budget > 200000 then
    return jsonb_build_object('allowed',false,'error','minute_quota','reset_at',date_trunc('minute',v_now)+interval '1 minute');
  end if;
  insert into assistant_private.requests(owner_id,request_id) values(p_owner,p_request);
  insert into assistant_private.counters(scope,bucket,requests,input_tokens) values
    ('user',v_user,1,0),('day',v_day,1,0),('minute',v_min,1,v_budget)
    on conflict(scope,bucket) do update set requests=assistant_private.counters.requests+excluded.requests,
      input_tokens=assistant_private.counters.input_tokens+excluded.input_tokens;
  delete from assistant_private.counters where created_at < v_now-interval '8 days';
  return jsonb_build_object('allowed',true,'reset_at',v_reset,'user_remaining',19-v_user_n);
end;
$$;
revoke all on function public.assistant_reserve(uuid,uuid) from public, anon, authenticated;
grant execute on function public.assistant_reserve(uuid,uuid) to service_role;
comment on function public.assistant_reserve(uuid,uuid) is 'Service-only atomic free Gemini quota reservation. No question text; repeat request IDs never call the model again.';
