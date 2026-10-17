-- Fit Pack — Hesabı sil: delete_user() RPC (docs/16 §4, docs/41 §2)
--
-- KARAR ÖZETİ
-- Uygulamadaki "Hesabı Sil" `rpc('delete_user')` çağırıyor; fonksiyon docs/16
-- §4'te yazılmış ama üretimde hiç kurulmamıştı (2026-10-11 tespit) → silme
-- "Hesap silinemedi" hatasıyla düşüyordu. GDPR md. 17 / KVKK md. 7 silinme
-- hakkı için şart.
--
-- Kullanıcı yalnız KENDİ hesabını silebilir (`auth.uid()`). Tüm kullanıcı
-- tabloları auth.users'a `on delete cascade` ile bağlı (14 tablo, 2026-10-11
-- doğrulandı) → satırlar da silinir. Fotoğraf ve adım zaten sunucuda yok.
--
-- GERİ DÖNÜŞ: `drop function public.delete_user();` (silinmiş hesap geri gelmez).

create or replace function public.delete_user()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from auth.users where id = auth.uid();
$$;

revoke execute on function public.delete_user() from anon, public;
grant execute on function public.delete_user() to authenticated;
