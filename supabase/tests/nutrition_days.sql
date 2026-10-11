-- Fit Pack — nutrition_days sunucu testleri (docs/37 Aşama 3)
--
-- ÇALIŞTIRMA (yalnız `Fit Pack Dev` — docs/20 §10.4):
--   1) bu dosyanın tamamını çalıştır
--   2) select * from public.run_nutrition_days_tests();
--
-- NE DOĞRULAR: iki kullanıcının aynı günü aynı uid ile yazabilmesi (PK
-- user_id+uid), çakışma kuralı (LWW), RLS, gün biçimi, sync_delete izin
-- listesi — kritik olanlar GERÇEK istemci rolüyle.
-- ⚠️ ÜRETİMDE ÇALIŞTIRMA. Test verisi yazar.

create or replace function public.run_nutrition_days_tests()
returns setof text
language plpgsql
as $tests$
declare
  u    uuid := '66666666-6666-6666-6666-666666666666';
  u2   uuid := '77777777-7777-7777-7777-777777777777';
  gun  uuid := '0b3f2a10-9c1e-5d4b-8a7f-112233445566'; -- aynı gün, iki kullanıcı
  v_sayi int;
  v_status text;
begin
  return next extensions.plan(9);

  delete from auth.users where id in (u, u2);
  insert into auth.users (id) values (u), (u2);

  -- ═══ Yapı ═══
  return next extensions.has_table('public'::name, 'nutrition_days'::name,
    'nutrition_days tablosu var');
  select count(*)::int into v_sayi from pg_trigger
    where tgrelid = 'public.nutrition_days'::regclass
      and tgname in ('sync_guard_trg', 'sync_mark_deleted_trg');
  return next extensions.is(v_sayi, 2, 'sync_guard + silme izi tetikleyicileri bağlı');

  -- ═══ Aynı uid, iki kullanıcı (PK user_id+uid) ═══
  insert into public.nutrition_days (uid, user_id, day, status, completed_at_ms, changed_at_ms)
    values (gun, u, '2026-10-10', 'complete', 1000, 1000),
           (gun, u2, '2026-10-10', 'complete', 1000, 1000);
  select count(*)::int into v_sayi from public.nutrition_days where uid = gun;
  return next extensions.is(v_sayi, 2, 'iki kullanıcı aynı günü aynı uid ile yazabilir');

  -- ═══ Çakışma: eski yazma reddedilir, yeni kazanır ═══
  update public.nutrition_days set status = 'open', changed_at_ms = 500
    where uid = gun and user_id = u;
  select status into v_status from public.nutrition_days where uid = gun and user_id = u;
  return next extensions.is(v_status, 'complete', 'eski changed_at_ms ile yazma atlandı (LWW)');

  update public.nutrition_days set status = 'open', completed_at_ms = null, changed_at_ms = 2000
    where uid = gun and user_id = u;
  select status into v_status from public.nutrition_days where uid = gun and user_id = u;
  return next extensions.is(v_status, 'open', 'yeni changed_at_ms ile geri al kabul edildi');

  -- ═══ Gün biçimi ═══
  return next extensions.throws_ok(
    format('insert into public.nutrition_days (uid, user_id, day, status) values (%L, %L, %L, %L)',
      gen_random_uuid(), u, '10.10.2026', 'complete'),
    '23514', null, 'gün metni YYYY-MM-DD olmalı');

  -- ═══ RLS: istemci rolü yalnız kendi satırını görür ═══
  perform set_config('request.jwt.claims',
    json_build_object('sub', u::text, 'role', 'authenticated')::text, true);
  set local role authenticated;
  select count(*)::int into v_sayi from public.nutrition_days;
  reset role;
  return next extensions.is(v_sayi, 1, 'istemci rolü yalnız kendi gününü görür');

  -- ═══ sync_delete yeni tabloyu tanır (istemci rolüyle) ═══
  perform set_config('request.jwt.claims',
    json_build_object('sub', u::text, 'role', 'authenticated')::text, true);
  set local role authenticated;
  select count(*)::int into v_sayi from public.sync_delete('nutrition_days', array[gun]);
  reset role;
  return next extensions.is(v_sayi, 1, 'sync_delete nutrition_days kabul eder, yalnız kendi satırını siler');

  select count(*)::int into v_sayi from public.nutrition_days where uid = gun and user_id = u2;
  return next extensions.is(v_sayi, 1, 'başka kullanıcının aynı-uid satırı yerinde');

  delete from auth.users where id in (u, u2);
  return next extensions.finish();
end $tests$;
