-- DEV ONLY: transactional synthetic receipt/history clock boundaries.
begin;
do $$ begin
  if exists(select 1 from auth.users where id='58000000-0000-4000-8000-000000000011') then
    raise exception 'fixture collision';
  end if;
end $$;
insert into auth.users(id,aud,role,email,created_at,email_confirmed_at)
 values('58000000-0000-4000-8000-000000000011','authenticated','authenticated','phase1-clock@example.invalid',now(),now());
insert into product_private.preferences(user_id) values('58000000-0000-4000-8000-000000000011');
insert into product_private.events(user_id,event_id,generation,occurred_at,received_at,session_id,name,properties,context)
 select '58000000-0000-4000-8000-000000000011',gen_random_uuid(),0,now(),now()-interval '30 days'+n*interval '1 second',gen_random_uuid(),
 'session_started','{"reason":"cold_start"}'::jsonb,'{"version":"1.0.0","build":"10003","platform":"ios","os_major":26,"environment":"test"}'::jsonb
 from generate_series(-1,1) n;
insert into product_private.consent_history(user_id,request_id,enabled,generation,policy_version,at)
 select '58000000-0000-4000-8000-000000000011',gen_random_uuid(),false,0,'phase1-v1',now()-interval '180 days'+n*interval '1 second'
 from generate_series(-1,1) n;
insert into product_private.access_audit(request_id,actor_id,action,outcome,at)
 select gen_random_uuid(),'58000000-0000-4000-8000-000000000011','overview','allowed',now()-interval '180 days'+n*interval '1 second'
 from generate_series(-1,1) n;
set local role service_role;
select public.phase1_retain();
reset role;
do $$ begin
  if (select count(*) from product_private.events where user_id='58000000-0000-4000-8000-000000000011') is distinct from 2 then raise exception '30-day boundary'; end if;
  if (select count(*) from product_private.consent_history where user_id='58000000-0000-4000-8000-000000000011') is distinct from 2 then raise exception '180-day consent boundary'; end if;
  if (select count(*) from product_private.access_audit where actor_id='58000000-0000-4000-8000-000000000011') is distinct from 2 then raise exception '180-day audit boundary'; end if;
end $$;
select 'phase1 exact retention boundaries passed: 30/180 days +/-1s and exact cutoff; transaction rolled back' as result;
rollback;
