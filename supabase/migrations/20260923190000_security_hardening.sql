-- Güvenlik denetçisi uyarılarını kapatır (2026-09-23). Davranış değişmez.
--
-- 1. sync_guard / sync_delete: search_path sabitlenir. İkisi de SECURITY
--    INVOKER ve gövdelerindeki her ad şema nitelikli (public.…, auth.uid());
--    yerleşikler (now, format, nextval…) pg_catalog'dan her zaman bulunur.
--    sync_mark_deleted'te zaten böyleydi.
alter function public.sync_guard() set search_path = '';
alter function public.sync_delete(text, uuid[]) set search_path = '';

-- 2. Tetikleyici fonksiyonları PostgREST üzerinden (/rest/v1/rpc/…) çağrılabilir
--    görünüyordu. Tetikleyici ateşlenirken EXECUTE yetkisi denetlenmez, yani
--    geri almak tetikleyicileri etkilemez; yalnız doğrudan çağrı kapısı kapanır.
revoke execute on function public.sync_mark_deleted() from public, anon, authenticated;

-- rls_auto_enable yalnız üretimde var (ilk şemadan kalma olay tetikleyicisi).
do $$
begin
  if exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname = 'public' and p.proname = 'rls_auto_enable') then
    execute 'revoke execute on function public.rls_auto_enable() from public, anon, authenticated';
  end if;
end $$;
