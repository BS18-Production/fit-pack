-- Fit Pack — Senkron v2 Aşama 5 sunucu testleri (docs/20 §10.2)
--
-- ÇALIŞTIRMA (yalnız `Fit Pack Dev` — docs/20 §10.4):
--   1) bu dosyanın tamamını çalıştır
--   2) select * from public.run_sync_v2_stage5_tests();
--
-- NE DOĞRULAR: silme protokolü — işaretin yazılması, satırın gerçekten
--   silinmesi, zincirleme silmelerin de iz bırakması, `sync_delete`'in tablo
--   adı doğrulaması ve RLS'i, hesap silmenin bozulmaması.
--
-- ⚠️ **GERÇEK İSTEMCİ ROLÜYLE** ölçen testler kritik (13–16). Superuser
--    olarak koşan bir test yetki hatalarını gizler: bu suite'in ilk hâli
--    yeşildi, ama `authenticated` rolüyle her silme "permission denied for
--    table users" ile patlıyordu (tetikleyici SECURITY DEFINER yapıldı).
--
-- ⚠️ ÜRETİMDE ÇALIŞTIRMA. Test verisi yazar.

create or replace function public.run_sync_v2_stage5_tests()
returns setof text
language plpgsql
as $tests$
declare
  u    uuid := '44444444-4444-4444-4444-444444444444';
  u2   uuid := '55555555-5555-5555-5555-555555555555';
  s1   uuid := 'd0000001-0000-0000-0000-000000000001';
  s2   uuid := 'd0000002-0000-0000-0000-000000000002';
  set1 uuid := 'e0000001-0000-0000-0000-000000000001';
  set2 uuid := 'e0000002-0000-0000-0000-000000000002';
  r1   uuid := 'f0000001-0000-0000-0000-000000000001';
  r2   uuid := 'f0000002-0000-0000-0000-000000000002';
  yok  uuid := 'aaaaaaaa-0000-0000-0000-00000000dead';
  v_sayi int;
  v_rev  bigint;
begin
  return next extensions.plan(18);

  delete from auth.users where id in (u, u2);
  insert into auth.users (id) values (u), (u2);

  -- ═══ Yapı ═══
  select count(*)::int into v_sayi from pg_trigger
    where tgname = 'sync_mark_deleted_trg' and not tgisinternal;
  return next extensions.is(v_sayi, 12, '12 tabloda silme izi tetikleyicisi var');

  return next extensions.has_function('public'::name, 'sync_delete'::name,
    'sync_delete fonksiyonu var');

  return next extensions.is(
    has_function_privilege('authenticated', 'public.sync_delete(text, uuid[])', 'EXECUTE'),
    true, 'istemci rolu sync_delete cagirabilir');

  -- ═══ Silme izi ═══
  insert into public.workout_sessions
    (uid, user_id, date, phase, workout_type, knee_status, is_deload, changed_at_ms)
  values (s1, u, now(), 1, 'push', 'iyi', false, 1000000000000);
  delete from public.workout_sessions where uid = s1;

  select count(*)::int into v_sayi from public.deleted_records
    where user_id = u and table_name = 'workout_sessions' and uid = s1;
  return next extensions.is(v_sayi, 1, 'silinen satir icin isaret yazildi');

  select count(*)::int into v_sayi from public.workout_sessions where uid = s1;
  return next extensions.is(v_sayi, 0, 'satirin kendisi GERCEKTEN silindi');

  select server_rev into v_rev from public.deleted_records
    where user_id = u and table_name = 'workout_sessions' and uid = s1;
  return next extensions.ok(v_rev > 0,
    'isaret ortak diziden server_rev aldi — cekme imleci onu gorebilsin');

  insert into public.workout_sessions
    (uid, user_id, date, phase, workout_type, knee_status, is_deload, changed_at_ms)
  values (s1, u, now(), 1, 'push', 'iyi', false, 9000000000000);
  select count(*)::int into v_sayi from public.workout_sessions where uid = s1;
  return next extensions.is(v_sayi, 0,
    'silinmis kimlik yeni damgayla bile geri gelmiyor');

  -- ═══ Zincirleme silme ═══
  insert into public.workout_sessions
    (uid, user_id, date, phase, workout_type, knee_status, is_deload, changed_at_ms)
  values (s2, u, now(), 1, 'pull', 'iyi', false, 1000000000000);
  insert into public.workout_sets
    (uid, user_id, session_uid, set_number, is_warmup, set_type, is_complete, changed_at_ms)
  values (set1, u, s2, 1, false, 'normal', true, 1000000000000),
         (set2, u, s2, 2, false, 'normal', true, 1000000000000);
  delete from public.workout_sessions where uid = s2;

  select count(*)::int into v_sayi from public.workout_sets where session_uid = s2;
  return next extensions.is(v_sayi, 0, 'zincirleme silme setleri de goturdu');

  select count(*)::int into v_sayi from public.deleted_records
    where user_id = u and table_name = 'workout_sets' and uid in (set1, set2);
  return next extensions.is(v_sayi, 2,
    'zincirleme silinen setlerin de isareti var — yoksa oteki cihazda kalirlar');

  -- ═══ sync_delete: tablo adi dogrulama ═══
  return next extensions.throws_ok(
    $$select public.sync_delete('pg_shadow', array['00000000-0000-0000-0000-000000000000']::uuid[])$$,
    '22023', null, 'bilinmeyen tablo adi reddedilir (SQL enjeksiyonuna kapi yok)');

  return next extensions.throws_ok(
    $$select public.sync_delete('workout_sessions; drop table foods', array['00000000-0000-0000-0000-000000000000']::uuid[])$$,
    '22023', null, 'tablo adina eklenen SQL reddedilir');

  return next extensions.lives_ok(
    $$select public.sync_delete('routines', array[]::uuid[])$$,
    'bos kimlik listesi hata vermez');

  -- ═══ GERCEK ISTEMCI ROLU (kritik) ═══
  insert into public.routines
    (uid, user_id, name, order_index, created_at, is_archived, changed_at_ms)
  values (r1, u, 'Silinecek', 0, now(), false, 1000000000000);
  insert into public.routines
    (uid, user_id, name, order_index, created_at, is_archived, changed_at_ms)
  values (r2, u2, 'Baskasinin', 0, now(), false, 1000000000000);

  perform set_config('request.jwt.claims',
    json_build_object('sub', u::text, 'role', 'authenticated')::text, true);
  set local role authenticated;
  select count(*)::int into v_sayi
    from public.sync_delete('routines', array[r1, yok, r2]);
  reset role;

  return next extensions.is(v_sayi, 1,
    'sync_delete yalniz GERCEKTEN silinen kendi kimligini dondurur');

  select count(*)::int into v_sayi from public.deleted_records
    where user_id = u and table_name = 'routines' and uid = yok;
  return next extensions.is(v_sayi, 0,
    'sunucuda olmayan kimlik icin isaret yazilmaz — bilgi tasimaz');

  select count(*)::int into v_sayi from public.routines where uid = r2;
  return next extensions.is(v_sayi, 1,
    'BASKA kullanicinin satiri silinmedi (RLS + user_id kilidi)');

  select count(*)::int into v_sayi from public.deleted_records
    where table_name = 'routines' and uid = r1;
  return next extensions.is(v_sayi, 1,
    'gercek istemci rolu ile silme isareti YAZILABILDI (SECURITY DEFINER)');

  -- ═══ Hesap silme zinciri ═══
  return next extensions.lives_ok(
    format('delete from auth.users where id = %L', u2),
    'hesap silme calisir — isaret tetikleyicisi zinciri patlatmiyor');

  select count(*)::int into v_sayi from public.deleted_records where user_id = u2;
  return next extensions.is(v_sayi, 0, 'silinen hesap icin isaret birikmiyor');

  delete from auth.users where id in (u, u2);
  return query select * from extensions.finish();
end $tests$;
