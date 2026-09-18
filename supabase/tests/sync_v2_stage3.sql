-- Fit Pack — Senkron v2 Aşama 3 sunucu testleri (docs/20 §10.2)
--
-- NEREDE ÇALIŞIR: `Fit Pack Dev` bulut projesi (docs/20 §10.4).
--   Yerel Docker yığını kurulmadığı için `supabase test db` / pg_prove
--   koşucusu yok. Bunun yerine testler tek bir fonksiyonda toplanır ve
--   tek cümleyle çalıştırılır:
--
--     1) bu dosyanın tamamını çalıştır (fonksiyonu kurar)
--     2) select * from public.run_sync_v2_stage3_tests();
--
--   Çıktı TAP biçimindedir: `ok N - açıklama` / `not ok N - açıklama`,
--   sonunda özet. Tek cümle = tek transaction: bir hata çıkarsa TAMAMI geri
--   alınır; başarıyla biterse fonksiyon test kullanıcısını siler ve
--   `on delete cascade` bütün test satırlarını götürür. Her iki durumda da
--   veritabanında iz kalmaz, test tekrar tekrar çalıştırılabilir.
--
-- NE DOĞRULAR: `sync_guard` tetikleyicisinin çakışma kuralı — hangi yazma
--   kabul edilir, hangisi sessizce atlanır. İstemcinin gönderim protokolü
--   (docs/20 §5.1) "dönen satır = kabul, dönmeyen = ret" varsayımına
--   dayanır; testlerin yarısı tam bu varsayımı ölçer.
--
-- ⚠️ ÜRETİMDE ÇALIŞTIRMA. Test verisi yazar; yalnız `Fit Pack Dev` içindir.

create or replace function public.run_sync_v2_stage3_tests()
returns setof text
language plpgsql
as $tests$
declare
  u    uuid := '11111111-1111-1111-1111-111111111111';
  s1   uuid := 'a0000001-0000-0000-0000-000000000001';
  s2   uuid := 'a0000002-0000-0000-0000-000000000002';
  s3   uuid := 'a0000003-0000-0000-0000-000000000003';
  s4   uuid := 'a0000004-0000-0000-0000-000000000004';
  s5   uuid := 'a0000005-0000-0000-0000-000000000005';
  set1 uuid := 'b0000001-0000-0000-0000-000000000001';

  senkron_tablolari text[] := array[
    'user_profile','exercises','foods','routines','routine_exercises',
    'workout_sessions','workout_sets','food_logs','recipe_items',
    'water_intake','body_measurements','progress_photos'];

  v_sayi  int;
  v_rev   bigint;
  v_rev2  bigint;
  v_not   text;
  v_ms    bigint;
  simdi   bigint;
begin
  return next extensions.plan(29);

  -- Hazırlık. Önceki yarım kalmış bir koşu varsa temizle.
  delete from auth.users where id = u;
  insert into auth.users (id) values (u);

  -- ═══════════════ 1. Yapı ═══════════════
  -- Tek bir tablonun atlanması sessiz bir senkron hatası olurdu: o tablonun
  -- satırları hiç çekilmez ya da körlemesine ezilir. Bu yüzden 12'nin hepsi
  -- sayarak doğrulanır.

  return next extensions.has_table('public'::name, 'deleted_records'::name,
    'deleted_records tablosu kuruldu');

  select count(*)::int into v_sayi from information_schema.columns
    where table_schema = 'public' and column_name = 'changed_at_ms'
      and table_name = any (senkron_tablolari);
  return next extensions.is(v_sayi, 12,
    '12 senkron tablosunun hepsinde changed_at_ms var');

  select count(*)::int into v_sayi from information_schema.columns
    where table_schema = 'public' and column_name = 'server_rev'
      and table_name = any (senkron_tablolari);
  return next extensions.is(v_sayi, 12,
    '12 senkron tablosunun hepsinde server_rev var');

  select count(*)::int into v_sayi from pg_trigger
    where tgname = 'sync_guard_trg' and not tgisinternal;
  return next extensions.is(v_sayi, 12,
    '12 tabloda sync_guard tetikleyicisi var');

  select count(*)::int into v_sayi from pg_indexes
    where schemaname = 'public'
      and indexname = any (select t || '_user_rev_idx' from unnest(senkron_tablolari) t);
  return next extensions.is(v_sayi, 12,
    '12 tabloda (user_id, server_rev) dizini var — çekme imleci');

  select count(*)::int into v_sayi from pg_indexes
    where schemaname = 'public'
      and indexname = any (select t || '_user_uid_key' from unnest(senkron_tablolari) t);
  return next extensions.is(v_sayi, 12,
    '12 tabloda (user_id, uid) tekil dizini var — gönderimin çakışma hedefi');

  select count(*)::int into v_sayi from pg_sequences
    where schemaname = 'public' and sequencename = 'sync_rev_seq';
  return next extensions.is(v_sayi, 1, 'ortak sürüm dizisi sync_rev_seq var');

  -- ═══════════════ 2. Ekleme ═══════════════

  with y as (
    insert into public.workout_sessions
      (uid, user_id, updated_at, date, phase, workout_type, knee_status,
       is_deload, notes, changed_at_ms)
    values (s1, u, timestamptz '2000-01-01 00:00:00+00', now(), 1,
            'push', 'iyi', false, 'ilk', 1000000000000)
    returning uid
  ) select count(*)::int into v_sayi from y;
  return next extensions.is(v_sayi, 1,
    'ekleme kabul edildi — satır RETURNING ile döndü');

  select server_rev into v_rev from public.workout_sessions where uid = s1;
  return next extensions.ok(v_rev > 0,
    'eklemede server_rev diziden atandı (0 kalmadı)');

  return next extensions.ok(
    (select updated_at from public.workout_sessions where uid = s1)
      > timestamptz '2020-01-01 00:00:00+00',
    'updated_at sunucu saatinden yazıldı — istemcinin 2000 tarihi kullanılmadı');

  -- ═══════════════ 3. Daha yeni damga → kabul ═══════════════
  -- İstemci gönderimi PostgREST üzerinden `on conflict (user_id, uid)` ile
  -- gelir; testler tam o yolu kullanır, düz UPDATE değil.

  with y as (
    insert into public.workout_sessions
      (uid, user_id, updated_at, date, phase, workout_type, knee_status,
       is_deload, notes, changed_at_ms)
    values (s1, u, now(), now(), 1, 'push', 'iyi', false, 'yeni', 1000000001000)
    on conflict (user_id, uid) do update
      set notes = excluded.notes, changed_at_ms = excluded.changed_at_ms
    returning uid
  ) select count(*)::int into v_sayi from y;
  return next extensions.is(v_sayi, 1,
    'daha yeni changed_at_ms kabul edildi — satır döndü');

  select notes, server_rev into v_not, v_rev2
    from public.workout_sessions where uid = s1;
  return next extensions.is(v_not, 'yeni', 'kabul edilen yazmada veri değişti');
  return next extensions.ok(v_rev2 > v_rev,
    'kabul edilen yazmada server_rev arttı');

  -- ═══════════════ 4. Daha eski damga → ret ═══════════════
  -- Çevrimdışı kalmış eski telefonun gönderimi sunucudakini EZMEMELİ (#4).

  v_rev := v_rev2;
  with y as (
    insert into public.workout_sessions
      (uid, user_id, updated_at, date, phase, workout_type, knee_status,
       is_deload, notes, changed_at_ms)
    values (s1, u, now(), now(), 1, 'push', 'iyi', false,
            'ESKI TELEFON', 999999999000)
    on conflict (user_id, uid) do update
      set notes = excluded.notes, changed_at_ms = excluded.changed_at_ms
    returning uid
  ) select count(*)::int into v_sayi from y;
  return next extensions.is(v_sayi, 0,
    'daha eski changed_at_ms reddedildi — RETURNING boş (istemci reddi buradan anlar)');

  select notes, server_rev into v_not, v_rev2
    from public.workout_sessions where uid = s1;
  return next extensions.is(v_not, 'yeni', 'reddedilen yazma veriyi değiştirmedi');
  return next extensions.is(v_rev2, v_rev,
    'reddedilen yazma server_rev''i artırmadı — öteki cihaz boşuna indirmez');

  -- ═══════════════ 5. Eşit damga → ret (sunucu kazanır) ═══════════════
  -- docs/20 §5.2: eşitlikte sunucu kazanır. Zaman aşımından sonra aynı
  -- satırın yeniden gönderimi sunucuda değişiklik yaratmaz.

  with y as (
    insert into public.workout_sessions
      (uid, user_id, updated_at, date, phase, workout_type, knee_status,
       is_deload, notes, changed_at_ms)
    values (s1, u, now(), now(), 1, 'push', 'iyi', false, 'AYNI MS', 1000000001000)
    on conflict (user_id, uid) do update
      set notes = excluded.notes, changed_at_ms = excluded.changed_at_ms
    returning uid
  ) select count(*)::int into v_sayi from y;
  return next extensions.is(v_sayi, 0,
    'eşit changed_at_ms reddedildi — sunucu kazanır');

  select notes into v_not from public.workout_sessions where uid = s1;
  return next extensions.is(v_not, 'yeni', 'eşit damgalı yazma veriyi değiştirmedi');

  -- ═══════════════ 6. Saat sapması ═══════════════

  simdi := (extract(epoch from now()) * 1000)::bigint;
  insert into public.workout_sessions
    (uid, user_id, date, phase, workout_type, knee_status, is_deload, changed_at_ms)
  values (s2, u, now(), 1, 'pull', 'iyi', false, simdi + 3600000);

  select changed_at_ms into v_ms from public.workout_sessions where uid = s2;
  return next extensions.ok(v_ms <= simdi + 5000,
    'bir saat ileri damga şimdiye kırpıldı — ileri saatli cihaz satırı kilitleyemez');

  insert into public.workout_sessions
    (uid, user_id, date, phase, workout_type, knee_status, is_deload, changed_at_ms)
  values (s3, u, now(), 1, 'pull', 'iyi', false, simdi + 60000);

  select changed_at_ms into v_ms from public.workout_sessions where uid = s3;
  return next extensions.ok(v_ms >= simdi + 60000,
    '1 dakika ileri damga kırpılmadı — 5 dk tolerans içinde');

  -- ═══════════════ 7. Silme kazanır (K-3) ═══════════════
  -- Aşama 5'te işaretleri tetikleyici yazacak; kural şimdiden yerinde
  -- olmalı, yoksa çevrimdışı bir cihaz silinen kaydı diriltir.

  insert into public.deleted_records (user_id, table_name, uid, deleted_at_ms)
  values (u, 'workout_sessions', s4, 1000000002000);

  with y as (
    insert into public.workout_sessions
      (uid, user_id, date, phase, workout_type, knee_status, is_deload, changed_at_ms)
    values (s4, u, now(), 1, 'push', 'iyi', false, 1000000009000)
    returning uid
  ) select count(*)::int into v_sayi from y;
  return next extensions.is(v_sayi, 0,
    'silinmiş kimliğe ekleme reddedildi — silme her zaman kazanır');

  select count(*)::int into v_sayi from public.workout_sessions where uid = s4;
  return next extensions.is(v_sayi, 0, 'silinmiş kimlik gerçekten geri gelmedi');

  insert into public.workout_sessions
    (uid, user_id, date, phase, workout_type, knee_status, is_deload, changed_at_ms)
  values (s5, u, now(), 1, 'push', 'iyi', false, 1000000000000);

  insert into public.deleted_records (user_id, table_name, uid, deleted_at_ms)
  values (u, 'workout_sessions', s5, 1000000003000);

  with y as (
    update public.workout_sessions
       set notes = 'DIRILT', changed_at_ms = 1000000009000
     where uid = s5
    returning uid
  ) select count(*)::int into v_sayi from y;
  return next extensions.is(v_sayi, 0, 'silinmiş kimliğe güncelleme reddedildi');

  select notes into v_not from public.workout_sessions where uid = s5;
  return next extensions.is(v_not, null::text,
    'silinmiş kimliğin güncellemesi veriye işlemedi');

  -- ═══════════════ 8. Dizi tablolar arası ortak ═══════════════
  -- Çekme imleci tek sayı; iki tablo aynı numarayı alırsa satır atlanır.

  insert into public.workout_sets
    (uid, user_id, session_uid, set_number, is_warmup, set_type, is_complete,
     changed_at_ms)
  values (set1, u, s1, 1, false, 'normal', true, 1000000005000);

  select server_rev into v_rev from public.workout_sets where uid = set1;
  select server_rev into v_rev2 from public.workout_sessions where uid = s1;
  return next extensions.ok(v_rev > v_rev2,
    'server_rev tablolar arasında ortak diziden — sonraki yazma daha büyük');

  -- ═══════════════ 9. İşaret tablosu yetkileri ═══════════════
  -- İşaretin silinmesi silinmiş satırı diriltirdi; istemci rolü yapamamalı.

  return next extensions.is(
    has_table_privilege('authenticated', 'public.deleted_records', 'UPDATE'),
    false, 'istemci rolü silme işaretini GÜNCELLEYEMEZ');

  return next extensions.is(
    has_table_privilege('authenticated', 'public.deleted_records', 'DELETE'),
    false, 'istemci rolü silme işaretini SİLEMEZ');

  return next extensions.is(
    has_table_privilege('authenticated', 'public.deleted_records', 'SELECT'),
    true, 'istemci rolü silme işaretlerini okuyabilir — çekme buna dayanır');

  return next extensions.is(
    has_sequence_privilege('authenticated', 'public.sync_rev_seq', 'USAGE'),
    true, 'istemci rolü diziyi kullanabilir — yoksa her yazma yetki hatasıyla düşer');

  -- Temizlik: cascade 12 tabloyu ve silme işaretlerini götürür.
  delete from auth.users where id = u;

  return query select * from extensions.finish();
end $tests$;
