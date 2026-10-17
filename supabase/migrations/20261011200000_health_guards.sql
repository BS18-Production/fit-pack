-- Fit Pack — Sağlık verisi korumaları (Codex incelemesi 2026-10-11, P1/P2)
--
-- KARAR ÖZETİ
-- Senkron "son yazan kazanır" (sync_guard) satırın tamamına uygulanıyor. İki
-- karar bundan ayrılmalı:
--   1. GİZLEME KALICI (docs/40 W-6): bir cihaz tartı ölçümünü gizledikten
--      sonra başka cihaz aynı örneği (aynı UUID v5) ilk kez içe alıp daha
--      yeni damgayla gönderirse `hidden` NULL'a dönüyordu. Artık bir kez true
--      olan `hidden` geri açılmaz.
--   2. RIZA ZAMANA GÖRE İLERLER (docs/41 §3): rıza verme / geri alma
--      `health_consent_at` damgasıyla yazılır (geri alma: zaman + sürüm NULL).
--      Daha eski damgalı bir profil kopyası (ör. başka cihazdaki eski profil
--      düzenlemesi) rıza kararını geri getiremez; daha YENİ karar eski bir
--      satırla gelse de kaybolmaz (yalnız karar alınır). Aynı anda farklı
--      karar: geri alma kazanır. Gizleme için aynı birleştirme.
--   3. delete_user(): asistan kota sayaçları (`assistant_private.counters`,
--      bucket = '<kullanıcı uuid>:<gün>') yabancı anahtarsız olduğu için
--      hesap silmede kalıyordu → açıkça silinir (GDPR md. 17).
--
-- Tetikleyici sırası: PostgreSQL aynı olaydaki BEFORE tetikleyicileri ada
-- göre çalıştırır; `health_*_trg` < `sync_guard_trg` → koruma önce uygulanır,
-- sync_guard sonra kabul/ret kararını verir.
--
-- GERİ DÖNÜŞ: iki tetikleyiciyi düşür; delete_user'ın önceki sürümü
-- 20261011190000_delete_user.sql.

create or replace function public.health_hidden_sticky()
returns trigger
language plpgsql
set search_path = ''
as $fn$
begin
  if coalesce(old.hidden, false) then
    -- Bir kez gizlenen geri açılmaz.
    new.hidden := true;
  elsif coalesce(new.hidden, false) and new.changed_at_ms <= old.changed_at_ms then
    -- Gizleme kararı, geri kalanı ESKİ bir satırla geldi (başka cihaz bu arada
    -- satırı güncellemiş): sync_guard bütün yazmayı reddederdi → gizleme
    -- kaybolurdu. Sunucudaki satır korunur, yalnız gizleme alınır.
    new := old;
    new.hidden := true;
    new.changed_at_ms := old.changed_at_ms + 1;
  end if;
  return new;
end $fn$;

create or replace trigger health_hidden_sticky_trg
  before update on public.body_measurements
  for each row execute function public.health_hidden_sticky();

create or replace function public.health_consent_monotonic()
returns trigger
language plpgsql
set search_path = ''
as $fn$
declare
  v_at timestamptz;
  v_ver integer;
begin
  if old.health_consent_at is not null
     and (new.health_consent_at is null
          or new.health_consent_at < old.health_consent_at
          -- Aynı an, farklı karar: geri alma (sürüm NULL) kazanır.
          or (new.health_consent_at = old.health_consent_at
              and old.health_consent_version is null)) then
    -- Daha eski rıza kararı: sunucudaki karar korunur.
    new.health_consent_at := old.health_consent_at;
    new.health_consent_version := old.health_consent_version;
  elsif new.health_consent_at is not null
        and (old.health_consent_at is null
             or new.health_consent_at > old.health_consent_at
             -- Aynı an: gelen geri alma da kazanmalı (Codex son kontrol).
             or (new.health_consent_at = old.health_consent_at
                 and new.health_consent_version is null
                 and old.health_consent_version is not null))
        and new.changed_at_ms <= old.changed_at_ms then
    -- Daha YENİ rıza kararı ESKİ bir satırla geldi: sync_guard bütün yazmayı
    -- reddederdi → karar kaybolurdu. Sunucudaki profil korunur, yalnız rıza
    -- alınır.
    v_at := new.health_consent_at;
    v_ver := new.health_consent_version;
    new := old;
    new.health_consent_at := v_at;
    new.health_consent_version := v_ver;
    new.changed_at_ms := old.changed_at_ms + 1;
  end if;
  return new;
end $fn$;

create or replace trigger health_consent_monotonic_trg
  before update on public.user_profile
  for each row execute function public.health_consent_monotonic();

create or replace function public.delete_user()
returns void
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;
  -- Yabancı anahtarsız kota sayaçları (assistant_quota.sql) — kimlik içerir.
  delete from assistant_private.counters
   where scope = 'user' and bucket like v_uid::text || ':%';
  -- Geri kalan her kullanıcı tablosu auth.users'a `on delete cascade`.
  delete from auth.users where id = v_uid;
end $fn$;

revoke execute on function public.delete_user() from anon, public;
grant execute on function public.delete_user() to authenticated;
