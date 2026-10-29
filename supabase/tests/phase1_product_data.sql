-- Only an isolated local/test Supabase database, after the new migration.
-- Entire fixture rolls back. Do NOT run against production or real user data.
begin;
insert into auth.users(id,aud,role,email,created_at,email_confirmed_at) values
 ('58000000-0000-4000-8000-000000000001','authenticated','authenticated','phase1-owner@example.invalid',now(),now()),
 ('58000000-0000-4000-8000-000000000002','authenticated','authenticated','phase1-viewer@example.invalid',now(),now()),
 ('58000000-0000-4000-8000-000000000003','authenticated','authenticated','phase1-support@example.invalid',now(),now());
insert into product_private.admins(user_id,overview,support,enabled) values
 ('58000000-0000-4000-8000-000000000002',true,false,true),
 ('58000000-0000-4000-8000-000000000003',true,true,true);

-- Private schema & service-only RPC privileges, tested as database roles.
do $$
declare role_name text; signature text;
begin
  foreach role_name in array array['anon','authenticated'] loop
    if has_schema_privilege(role_name,'product_private','usage') is distinct from false then raise exception 'private schema exposed to %',role_name; end if;
    if has_function_privilege(role_name,'product_private.support_summary(uuid,text,text,text,uuid,uuid)','execute') is distinct from false then raise exception 'private privileged support helper exposed to %',role_name; end if;
    foreach signature in array array['public.phase1_consent_status(uuid)',
      'public.phase1_set_consent(uuid,boolean,bigint,uuid,text)',
      'public.phase1_ingest(uuid,bigint,jsonb)','public.phase1_admin_overview(uuid,text,integer,uuid)',
      'public.phase1_admin_support(uuid,text,text,text,uuid,uuid)','public.phase1_retain()'] loop
      if has_function_privilege(role_name,signature,'execute') is distinct from false then raise exception 'RPC exposed to %: %',role_name,signature; end if;
    end loop;
  end loop;
end $$;
set local role authenticated;
do $$ begin
  begin
    perform public.phase1_consent_status('58000000-0000-4000-8000-000000000001');
    raise exception 'ordinary authenticated user invoked service RPC';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

set local role service_role;
do $$
declare
  owner constant uuid := '58000000-0000-4000-8000-000000000001';
  viewer constant uuid := '58000000-0000-4000-8000-000000000002';
  supporter constant uuid := '58000000-0000-4000-8000-000000000003';
  enable_request uuid:=gen_random_uuid(); revoke_request uuid:=gen_random_uuid();
  ev jsonb; result jsonb; n integer; req uuid;
begin
  result:=public.phase1_consent_status(owner);
  if result->>'enabled' is distinct from 'false' or (result->>'generation')::int is distinct from 0 then raise exception 'consent not off by default'; end if;
  ev:=jsonb_build_object('event_id',gen_random_uuid(),'session_id',gen_random_uuid(),'occurred_at',now(),
    'name','workout_saved','properties',jsonb_build_object('mode','routine','source','live'),
    'context',jsonb_build_object('version','1.0.0','build','2','platform','ios','os_major',26,'environment','production'));
  begin
    perform public.phase1_ingest(owner,0,jsonb_build_array(ev));
    raise exception 'ingest before consent';
  exception when raise_exception then if sqlerrm<>'stale_consent' then raise; end if; end;
  result:=public.phase1_set_consent(owner,true,0,enable_request,'phase1-v1');
  if (result->>'generation')::int is distinct from 1 then raise exception 'enable generation'; end if;
  result:=public.phase1_set_consent(owner,true,0,enable_request,'phase1-v1');
  if (result->>'generation')::int is distinct from 1 then raise exception 'enable retry duplicated'; end if;
  result:=public.phase1_ingest(owner,1,jsonb_build_array(ev));
  if (result->>'accepted')::int is distinct from 1 then raise exception 'first event not inserted'; end if;
  result:=public.phase1_ingest(owner,1,jsonb_build_array(ev));
  if (result->>'accepted')::int is distinct from 0 then raise exception 'retry duplicated event'; end if;
  if product_private.valid_event(ev||jsonb_build_object('properties',jsonb_build_object('mode','routine','source','live','weight_kg',100))) is distinct from false then raise exception 'health field accepted'; end if;
  if product_private.valid_event(ev||jsonb_build_object('owner_id',viewer)) is distinct from false then raise exception 'owner override accepted'; end if;
  if product_private.valid_event(ev||jsonb_build_object('name','nutrition_entry_saved')) is distinct from false then raise exception 'out of scope event accepted'; end if;
  result:=public.phase1_set_consent(owner,false,0,revoke_request,'phase1-v1');
  if result->>'enabled' is distinct from 'false' or (result->>'generation')::int is distinct from 2 then raise exception 'stale-generation revoke not accepted'; end if;
  select count(*) into n from product_private.events where user_id=owner;
  if n is distinct from 0 then raise exception 'revoke retained events'; end if;
  result:=public.phase1_set_consent(owner,true,0,enable_request,'phase1-v1');
  if result->>'enabled' is distinct from 'false' or (result->>'generation')::int is distinct from 2 then raise exception 'old enable replay revived consent'; end if;
  begin
    perform public.phase1_ingest(owner,1,jsonb_build_array(ev));
    raise exception 'old generation ingest accepted';
  exception when raise_exception then if sqlerrm<>'stale_consent' then raise; end if; end;
  begin
    perform public.phase1_set_consent(owner,true,0,gen_random_uuid(),'phase1-v1');
    raise exception 'stale enable accepted';
  exception when raise_exception then if sqlerrm<>'stale_consent' then raise; end if; end;
  perform public.phase1_set_consent(owner,true,2,gen_random_uuid(),'phase1-v1');
  perform public.phase1_ingest(owner,3,jsonb_build_array(ev));

  -- No role, aggregate-only role, and MFA boundary must fail with an audit.
  result:=public.phase1_admin_support(owner,'aal2',owner::text,'sync_issue',gen_random_uuid(),gen_random_uuid());
  if result->>'error' is distinct from 'forbidden' then raise exception 'ordinary user gained support'; end if;
  result:=public.phase1_admin_support(viewer,'aal2',owner::text,'sync_issue',gen_random_uuid(),gen_random_uuid());
  if result->>'error' is distinct from 'forbidden' then raise exception 'aggregate-only user gained support'; end if;
  result:=public.phase1_admin_support(supporter,'aal1',owner::text,'sync_issue',gen_random_uuid(),gen_random_uuid());
  if result->>'error' is distinct from 'forbidden' then raise exception 'aal1 gained support'; end if;
  req:=gen_random_uuid();
  result:=public.phase1_admin_support(supporter,'aal2','phase1-owner@example.invalid','missing_records',gen_random_uuid(),req);
  if result->'account'->>'id' is distinct from owner::text or result->'account'->>'email_masked' is distinct from 'p***@example.invalid' then raise exception 'support lookup/masking failed'; end if;
  if (result::text ~ 'weight_kg|computed_kcal|birth_date|encrypted_password|raw_user_meta_data') is distinct from false then raise exception 'sensitive support payload'; end if;
  select count(*) into n from product_private.access_audit where request_id=req and outcome='allowed';
  if n is distinct from 1 then raise exception 'support audit missing'; end if;
  -- Existing request id forces audit insertion failure: no support result may escape.
  begin
    perform public.phase1_admin_support(supporter,'aal2',owner::text,'sync_issue',gen_random_uuid(),req);
    raise exception 'audit failure did not close support';
  exception when unique_violation then null; end;
  result:=public.phase1_admin_overview(viewer,'aal2',7,gen_random_uuid());
  if coalesce(result ? 'error',true) or (result->'coverage'->>'missing_history')::boolean is distinct from true then raise exception 'overview coverage'; end if;
  if (result::text like '%phase1-owner@example.invalid%') is distinct from false then raise exception 'overview leaked email'; end if;
end $$;
reset role;

-- Revocation is checked on the next request even with the same actor/AAL.
update product_private.admins set support=false where user_id='58000000-0000-4000-8000-000000000003';
set local role service_role;
do $$
declare result jsonb;
begin
  result:=public.phase1_admin_support('58000000-0000-4000-8000-000000000003','aal2',
    '58000000-0000-4000-8000-000000000001','sync_issue',gen_random_uuid(),gen_random_uuid());
  if result->>'error' is distinct from 'forbidden' then raise exception 'revoked support role remained effective'; end if;
end $$;
reset role;

-- Separate retention clocks: only synthetic fixtures are aged.
update product_private.events set received_at=now()-interval '31 days'
 where user_id='58000000-0000-4000-8000-000000000001';
update product_private.consent_history set at=now()-interval '181 days'
 where user_id='58000000-0000-4000-8000-000000000001';
update product_private.access_audit set at=now()-interval '181 days'
 where actor_id in ('58000000-0000-4000-8000-000000000001','58000000-0000-4000-8000-000000000002','58000000-0000-4000-8000-000000000003');
-- A fresh minimal audit must survive cleanup and later account deletion.
insert into product_private.access_audit(request_id,actor_id,action,outcome,row_count,at)
 values('58000000-0000-4000-8000-000000000009','58000000-0000-4000-8000-000000000001','overview','allowed',1,now());
set local role service_role;
select public.phase1_retain();
reset role;
do $$ begin
  if exists(select 1 from product_private.events where user_id='58000000-0000-4000-8000-000000000001') then raise exception '30-day event retention failed'; end if;
  if exists(select 1 from product_private.consent_history where user_id='58000000-0000-4000-8000-000000000001') then raise exception '180-day consent retention failed'; end if;
  if exists(select 1 from product_private.access_audit
    where actor_id in ('58000000-0000-4000-8000-000000000001','58000000-0000-4000-8000-000000000002','58000000-0000-4000-8000-000000000003')
      and at<now()-interval '180 days') then raise exception '180-day expired audit retention failed'; end if;
  if not exists(select 1 from product_private.access_audit
    where request_id='58000000-0000-4000-8000-000000000009' and at>=now()-interval '180 days') then raise exception 'retention erased fresh audit'; end if;
  if not exists(select 1 from product_private.preferences where user_id='58000000-0000-4000-8000-000000000001') then raise exception 'retention erased current consent'; end if;
end $$;
delete from auth.users where id='58000000-0000-4000-8000-000000000001';
do $$ begin
  if exists(select 1 from product_private.preferences where user_id='58000000-0000-4000-8000-000000000001') then raise exception 'account deletion did not cascade'; end if;
  if not exists(select 1 from product_private.access_audit where request_id='58000000-0000-4000-8000-000000000009') then raise exception 'account deletion erased independent access audit'; end if;
end $$;
select 'phase1 synthetic SQL integration passed: permissions, consent, dedupe, roles/MFA, audit, retention, deletion' result;
rollback;
