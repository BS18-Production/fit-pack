-- docs/58: A1–A8 + B1 + C1. Local migration authored; NOT APPLIED.
-- Rollout flags and empty admin allowlist keep activation separate.
-- No existing table/function grants are changed.
create schema if not exists product_private;
revoke all on schema product_private from public, anon, authenticated;
grant usage on schema product_private to service_role;

create table product_private.preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  enabled boolean not null default false,
  generation bigint not null default 0 check (generation >= 0),
  policy_version text check (policy_version is null or policy_version = 'phase1-v1'),
  updated_at timestamptz not null default now()
);
create table product_private.consent_history (
  user_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  enabled boolean not null,
  generation bigint not null,
  policy_version text not null check (policy_version = 'phase1-v1'),
  at timestamptz not null default now(),
  primary key (user_id, request_id)
);
create index consent_history_at_idx on product_private.consent_history(at);

create table product_private.events (
  user_id uuid not null references auth.users(id) on delete cascade,
  event_id uuid not null,
  generation bigint not null,
  occurred_at timestamptz not null,
  received_at timestamptz not null default now(),
  session_id uuid not null,
  name text not null,
  properties jsonb not null,
  context jsonb not null,
  primary key (user_id, event_id)
);
create index product_events_received_idx on product_private.events(received_at);
create index product_events_user_received_idx on product_private.events(user_id, received_at);

-- Deliberately empty: migration never appoints an administrator.
create table product_private.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  overview boolean not null default false,
  support boolean not null default false,
  enabled boolean not null default false
);
create table product_private.access_audit (
  request_id uuid primary key,
  actor_id uuid not null,
  action text not null check (action in ('overview', 'support')),
  target_id uuid,
  reason text check (reason is null or reason in ('account_setup', 'sync_issue', 'missing_records')),
  case_id uuid,
  outcome text not null check (outcome in ('allowed', 'denied', 'not_found')),
  row_count integer not null default 0,
  at timestamptz not null default now()
);
create index product_access_audit_at_idx on product_private.access_audit(at);

alter table product_private.preferences enable row level security;
alter table product_private.consent_history enable row level security;
alter table product_private.events enable row level security;
alter table product_private.admins enable row level security;
alter table product_private.access_audit enable row level security;
revoke all on all tables in schema product_private from public, anon, authenticated;
grant select, insert, update, delete on product_private.preferences, product_private.consent_history,
  product_private.events to service_role;
grant select on product_private.admins to service_role;
grant select, insert, delete on product_private.access_audit to service_role;

-- Validates exactly the permitted fields at the database boundary as well.
create function product_private.valid_event(e jsonb) returns boolean
language plpgsql immutable security invoker set search_path = '' as $$
declare p jsonb; c jsonb; n text; k text; allowed text[];
begin
  if jsonb_typeof(e) is distinct from 'object' or not (e ?& array['event_id','occurred_at','session_id','name','properties','context'])
     or exists(select 1 from jsonb_object_keys(e) x where x <> all(array['event_id','occurred_at','session_id','name','properties','context'])) then return false; end if;
  if jsonb_typeof(e->'event_id') is distinct from 'string' or jsonb_typeof(e->'session_id') is distinct from 'string'
     or jsonb_typeof(e->'occurred_at') is distinct from 'string' or jsonb_typeof(e->'name') is distinct from 'string'
     or (e->>'event_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     or (e->>'session_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then return false; end if;
  p := e->'properties'; c := e->'context'; n := e->>'name';
  if jsonb_typeof(p) is distinct from 'object' or jsonb_typeof(c) is distinct from 'object'
     or not (c ?& array['version','build','platform','os_major','environment'])
     or exists(select 1 from jsonb_object_keys(c) x where x <> all(array['version','build','platform','os_major','environment'])) then return false; end if;
  if jsonb_typeof(c->'version') is distinct from 'string' or (c->>'version') !~ '^\d{1,3}\.\d{1,3}\.\d{1,3}$'
     or jsonb_typeof(c->'build') is distinct from 'string' or (c->>'build') !~ '^\d{1,10}$'
     or jsonb_typeof(c->'platform') is distinct from 'string' or jsonb_typeof(c->'environment') is distinct from 'string'
     or c->>'platform' not in ('ios','android','other') or c->>'environment' not in ('production','development','test')
     or jsonb_typeof(c->'os_major') is distinct from 'number' or (c->>'os_major') !~ '^\d{1,2}$' then return false; end if;
  case n
    when 'session_started' then allowed := array['reason']; if p->>'reason' not in ('cold_start','foreground') then return false; end if;
    when 'session_ended' then allowed := array['duration_bucket']; if p->>'duration_bucket' not in ('under_1m','1_5m','5_15m','15_60m','over_60m') then return false; end if;
    when 'onboarding_step_completed' then allowed := array['step']; if p->>'step' not in ('training','nutrition','complete') then return false; end if;
    when 'workout_started' then allowed := array['mode']; if p->>'mode' not in ('routine','free') then return false; end if;
    when 'workout_saved' then allowed := array['mode','source']; if p->>'mode' not in ('routine','free') or p->>'source' not in ('live','historical') then return false; end if;
    when 'app_error' then allowed := array['code','screen']; if p->>'code' not in ('startup','ui','storage','network','unknown') or p->>'screen' not in ('app','onboarding','workout','settings','sync') then return false; end if;
    when 'sync_cycle_result' then allowed := array['direction','outcome','pending_bucket','duration_bucket'];
      if p->>'direction' not in ('push','pull') or p->>'outcome' not in ('success','unreachable','no_session','permanent','repairable','unknown')
         or p->>'pending_bucket' not in ('zero','1_10','11_100','over_100') or p->>'duration_bucket' not in ('under_1s','1_5s','5_30s','over_30s') then return false; end if;
    else return false;
  end case;
  if not (p ?& allowed) or exists(select 1 from jsonb_object_keys(p) x where x <> all(allowed)) then return false; end if;
  for k in select unnest(allowed) loop if jsonb_typeof(p->k) <> 'string' then return false; end if; end loop;
  perform (e->>'occurred_at')::timestamptz;
  return true;
exception when others then return false;
end $$;
revoke all on function product_private.valid_event(jsonb) from public, anon, authenticated;
grant execute on function product_private.valid_event(jsonb) to service_role;
alter table product_private.events add constraint product_event_shape check
  (product_private.valid_event(jsonb_build_object('event_id',event_id,'session_id',session_id,
  'occurred_at',occurred_at,'name',name,'properties',properties,'context',context)));

create function public.phase1_consent_status(p_actor uuid) returns jsonb
language sql stable security invoker set search_path = '' as $$
  select coalesce((select jsonb_build_object('enabled',enabled,'generation',generation,'policy_version',policy_version)
    from product_private.preferences where user_id=p_actor),
    jsonb_build_object('enabled',false,'generation',0,'policy_version',null));
$$;

create function public.phase1_set_consent(p_actor uuid, p_enabled boolean, p_expected_generation bigint,
  p_request_id uuid, p_policy_version text) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare pref product_private.preferences; prev product_private.consent_history;
begin
  if p_actor is null or p_enabled is null or p_expected_generation is null or p_expected_generation < 0
     or p_request_id is null or p_policy_version is distinct from 'phase1-v1' then raise exception 'invalid_request' using errcode='22023'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_actor::text, 58));
  insert into product_private.preferences(user_id) values(p_actor) on conflict do nothing;
  select * into pref from product_private.preferences where user_id=p_actor for update;
  select * into prev from product_private.consent_history where user_id=p_actor and request_id=p_request_id;
  if found then
    if prev.enabled <> p_enabled or prev.policy_version <> p_policy_version then raise exception 'request_conflict' using errcode='22023'; end if;
    -- Replaying an old enable never undoes a later revoke.
    return public.phase1_consent_status(p_actor);
  end if;
  if p_enabled and pref.generation <> p_expected_generation then raise exception 'stale_consent' using errcode='P0001'; end if;
  update product_private.preferences set enabled=p_enabled,generation=generation+1,
    policy_version=p_policy_version,updated_at=now() where user_id=p_actor returning * into pref;
  insert into product_private.consent_history(user_id,request_id,enabled,generation,policy_version)
    values(p_actor,p_request_id,p_enabled,pref.generation,p_policy_version);
  if not p_enabled then delete from product_private.events where user_id=p_actor; end if;
  return public.phase1_consent_status(p_actor);
end $$;

create function public.phase1_ingest(p_actor uuid,p_generation bigint,p_events jsonb) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare pref product_private.preferences; e jsonb; t timestamptz; inserted integer; total integer := 0;
begin
  if p_actor is null or p_generation is null or jsonb_typeof(p_events) is distinct from 'array'
    or jsonb_array_length(p_events) not between 1 and 50 or octet_length(p_events::text)>32768 then raise exception 'invalid_request' using errcode='22023'; end if;
  -- Same lock as revoke: no in-flight batch can commit after a completed revoke.
  perform pg_advisory_xact_lock(hashtextextended(p_actor::text,58));
  select * into pref from product_private.preferences where user_id=p_actor for update;
  if not found or not pref.enabled or pref.generation<>p_generation or pref.policy_version<>'phase1-v1' then raise exception 'stale_consent' using errcode='P0001'; end if;
  if (select count(*) from product_private.events where user_id=p_actor and received_at>=date_trunc('day',now())) + jsonb_array_length(p_events) > 5000 then raise exception 'rate_limited' using errcode='P0001'; end if;
  for e in select value from jsonb_array_elements(p_events) loop
    if not coalesce(product_private.valid_event(e),false) then raise exception 'invalid_request' using errcode='22023'; end if;
    t := (e->>'occurred_at')::timestamptz;
    if t<now()-interval '7 days' or t>now()+interval '5 minutes' then raise exception 'invalid_request' using errcode='22023'; end if;
    insert into product_private.events(user_id,event_id,generation,occurred_at,session_id,name,properties,context)
      values(p_actor,(e->>'event_id')::uuid,p_generation,t,(e->>'session_id')::uuid,e->>'name',e->'properties',e->'context') on conflict do nothing;
    get diagnostics inserted=row_count; total:=total+inserted;
  end loop;
  return jsonb_build_object('accepted',total);
end $$;

create function product_private.admin_allowed(p_actor uuid,p_scope text,p_aal text) returns boolean
language sql stable security invoker set search_path = '' as $$
 select p_aal='aal2' and exists(select 1 from product_private.admins
 where user_id=p_actor and enabled and case p_scope when 'overview' then overview or support when 'support' then support else false end);
$$;
revoke all on function product_private.admin_allowed(uuid,text,text) from public, anon, authenticated;
grant execute on function product_private.admin_allowed(uuid,text,text) to service_role;

create function public.phase1_admin_overview(p_actor uuid,p_aal text,p_days integer,p_request_id uuid) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare result jsonb; start_at timestamptz; end_at timestamptz:=now();
begin
  if p_actor is null or p_days is null or p_days not in (7,14,30) or p_request_id is null then raise exception 'invalid_request' using errcode='22023'; end if;
  if not coalesce(product_private.admin_allowed(p_actor,'overview',p_aal),false) then
    insert into product_private.access_audit(request_id,actor_id,action,outcome) values(p_request_id,p_actor,'overview','denied');
    return jsonb_build_object('error','forbidden');
  end if;
  start_at:=date_trunc('day',end_at)-(p_days-1)*interval '1 day';
  with e as (select * from product_private.events where occurred_at>=start_at and occurred_at<end_at and received_at>=end_at-interval '30 days' and context->>'environment'='production')
  select jsonb_build_object(
    'generated_at',end_at,'window_days',p_days,
    'coverage',jsonb_build_object('started_at',(select min(received_at) from product_private.events where context->>'environment'='production'),
      'consenting_accounts',(select count(*) from product_private.preferences where enabled),
      'observed_accounts',(select count(distinct user_id) from e),'observed_sessions',(select count(distinct (user_id,session_id)) from e),'missing_history',true),
    'metrics',jsonb_build_object('session_starts',(select count(*) from e where name='session_started'),
      'workout_starts',(select count(*) from e where name='workout_started'),'workout_saves',(select count(*) from e where name='workout_saved'),
      'workout_saved_accounts',(select count(distinct user_id) from e where name='workout_saved')),
    'daily',coalesce((select jsonb_agg(d order by d.day) from (select to_char(occurred_at at time zone 'UTC','YYYY-MM-DD') as day,
      count(*) filter(where name='session_started') sessions,count(*) filter(where name='workout_saved') workout_saves from e group by 1) d),'[]'::jsonb),
    'onboarding',coalesce((select jsonb_agg(d order by d.step) from (select properties->>'step' step,count(*) count,
      count(distinct user_id) accounts from e where name='onboarding_step_completed' group by 1) d),'[]'::jsonb),
    'versions',coalesce((select jsonb_agg(d) from (select context->>'version' version,context->>'build' build,
      context->>'platform' platform,(context->>'os_major')::integer os_major,
      count(distinct (user_id,session_id)) sessions,count(distinct user_id) accounts from e
      group by 1,2,3,4 order by count(distinct (user_id,session_id)) desc,1,2 limit 30) d),'[]'::jsonb),
    'errors',coalesce((select jsonb_agg(d) from (select properties->>'code' code,properties->>'screen' screen,count(*) count from e where name='app_error' group by 1,2 order by count(*) desc limit 30) d),'[]'::jsonb),
    'sync',coalesce((select jsonb_agg(d) from (select properties->>'outcome' outcome,count(*) count from e where name='sync_cycle_result' group by 1 order by count(*) desc) d),'[]'::jsonb),
    'notice','Yalnız analitiği açan hesapların bildirilen üretim olayları. Geçmiş tamamlanmaz; eksik ölçüm sıfır kullanım değildir. Kayıt tarihleri son kullanım değildir.') into result;
  insert into product_private.access_audit(request_id,actor_id,action,outcome,row_count) values(p_request_id,p_actor,'overview','allowed',1);
  return result;
end $$;

-- Narrow privileged boundary: the migration owner must be a trusted server
-- owner with access to auth.users and the fixed C1 queries. No browser role is
-- granted any auth/users/health-table read. No arbitrary SQL or field selector.
create function product_private.support_summary(p_actor uuid,p_aal text,p_query text,p_reason text,p_case_id uuid,p_request_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare target record; result jsonb; is_uuid boolean;
begin
  if p_actor is null or p_reason is null or p_reason not in ('account_setup','sync_issue','missing_records') or p_case_id is null or p_request_id is null
     or p_query is null or length(p_query)>254 then raise exception 'invalid_request' using errcode='22023'; end if;
  if not coalesce(product_private.admin_allowed(p_actor,'support',p_aal),false) then
    insert into product_private.access_audit(request_id,actor_id,action,reason,case_id,outcome) values(p_request_id,p_actor,'support',p_reason,p_case_id,'denied');
    return jsonb_build_object('error','forbidden');
  end if;
  is_uuid:=p_query ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
  if not is_uuid and p_query !~ '^[^\s@]+@[^\s@]+\.[^\s@]+$' then raise exception 'invalid_request' using errcode='22023'; end if;
  -- Exact lookup only. Never return auth metadata, email, tokens, or health rows.
  select id,email,created_at,email_confirmed_at into target from auth.users where (is_uuid and id::text=lower(p_query)) or (not is_uuid and lower(email)=lower(p_query)) limit 1;
  if not found then
    insert into product_private.access_audit(request_id,actor_id,action,reason,case_id,outcome) values(p_request_id,p_actor,'support',p_reason,p_case_id,'not_found');
    return jsonb_build_object('error','not_found');
  end if;
  select jsonb_build_object('account',jsonb_build_object('id',target.id,
      'email_masked',case when target.email is null then null else left(split_part(target.email,'@',1),1)||'***@'||split_part(target.email,'@',2) end,
      'created_at',target.created_at,'email_confirmed',target.email_confirmed_at is not null,
      'onboarded',(select bool_or(onboarded) from public.user_profile where user_id=target.id)),
    'categories',jsonb_build_array(
      (select jsonb_build_object('category','workouts','count',count(*),'latest_record_at',max(date),'latest_server_change_at',max(updated_at)) from public.workout_sessions where user_id=target.id),
      (select jsonb_build_object('category','nutrition','count',count(*),'latest_record_at',max(date),'latest_server_change_at',max(updated_at)) from public.food_logs where user_id=target.id),
      (select jsonb_build_object('category','body','count',count(*),'latest_record_at',max(date),'latest_server_change_at',max(updated_at)) from public.body_measurements where user_id=target.id and not coalesce(hidden,false))),
    'request_id',p_request_id) into result;
  -- Same transaction: audit failure rolls back and no data result is released.
  insert into product_private.access_audit(request_id,actor_id,action,target_id,reason,case_id,outcome,row_count)
    values(p_request_id,p_actor,'support',target.id,p_reason,p_case_id,'allowed',3);
  return result;
end $$;
revoke all on function product_private.support_summary(uuid,text,text,text,uuid,uuid) from public,anon,authenticated;
grant execute on function product_private.support_summary(uuid,text,text,text,uuid,uuid) to service_role;

create function public.phase1_admin_support(p_actor uuid,p_aal text,p_query text,p_reason text,p_case_id uuid,p_request_id uuid) returns jsonb
language sql security invoker set search_path = '' as $$
  select product_private.support_summary(p_actor,p_aal,p_query,p_reason,p_case_id,p_request_id);
$$;

-- A bounded maintenance call; activation/scheduling requires separate review.
create function public.phase1_retain() returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare e integer; c integer; a integer;
begin
  delete from product_private.events where (user_id,event_id) in (select user_id,event_id from product_private.events where received_at<now()-interval '30 days' order by received_at limit 5000);
  get diagnostics e=row_count;
  delete from product_private.consent_history where (user_id,request_id) in (select user_id,request_id from product_private.consent_history where at<now()-interval '180 days' order by at limit 5000);
  get diagnostics c=row_count;
  delete from product_private.access_audit where request_id in (select request_id from product_private.access_audit where at<now()-interval '180 days' order by at limit 5000);
  get diagnostics a=row_count;
  return jsonb_build_object('events_deleted',e,'consents_deleted',c,'audits_deleted',a);
end $$;

revoke all on function public.phase1_consent_status(uuid),public.phase1_set_consent(uuid,boolean,bigint,uuid,text),
 public.phase1_ingest(uuid,bigint,jsonb),public.phase1_admin_overview(uuid,text,integer,uuid),
 public.phase1_admin_support(uuid,text,text,text,uuid,uuid),public.phase1_retain() from public,anon,authenticated;
grant execute on function public.phase1_consent_status(uuid),public.phase1_set_consent(uuid,boolean,bigint,uuid,text),
 public.phase1_ingest(uuid,bigint,jsonb),public.phase1_admin_overview(uuid,text,integer,uuid),
 public.phase1_admin_support(uuid,text,text,text,uuid,uuid),public.phase1_retain() to service_role;
