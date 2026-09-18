-- Fit Pack — tablo yetkileri (docs/18 §7)
--
-- ⚠️ NEDEN GEREKLİ: Postgres'te RLS ile GRANT AYRI katmanlardır.
--   GRANT → role tabloya dokunabilir mi?
--   RLS   → dokunabildiği SATIRLAR hangileri?
-- RLS tek başına yetmez. Supabase panelinden oluşturulan tablolara bu
-- yetkiler otomatik verilir; SQL Editor'den ham SQL ile oluşturulanlara
-- VERİLMEZ → "permission denied for table X (42501)".
--
-- Güvenlik kaybı yok: yetki tabloyu açar, RLS satırları kullanıcının kendi
-- satırlarıyla sınırlar. İkisi birlikte çalışır.

grant usage on schema public to authenticated;

grant select, insert, update, delete on public.user_profile to authenticated;
grant select, insert, update, delete on public.exercises to authenticated;
grant select, insert, update, delete on public.foods to authenticated;
grant select, insert, update, delete on public.routines to authenticated;
grant select, insert, update, delete on public.routine_exercises to authenticated;
grant select, insert, update, delete on public.workout_sessions to authenticated;
grant select, insert, update, delete on public.workout_sets to authenticated;
grant select, insert, update, delete on public.food_logs to authenticated;
grant select, insert, update, delete on public.recipe_items to authenticated;
grant select, insert, update, delete on public.water_intake to authenticated;
grant select, insert, update, delete on public.body_measurements to authenticated;
grant select, insert, update, delete on public.progress_photos to authenticated;

-- Bundan sonra bu şemada oluşturulacak tablolar için de varsayılan yetki —
-- aynı tuzağa bir daha düşmeyelim.
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;
