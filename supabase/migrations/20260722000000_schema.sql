-- Fit Pack — Supabase mirror tabloları + RLS (docs/18 §7, Aşama B)
-- Üretildi: drift_schema_v9.json'dan (elle düzenleme yerine yeniden üret)
--
-- TASARIM NOTLARI
-- • Birincil anahtar `uid` (istemcide üretilen UUID v4). Yerel integer `id`
--   sunucuya GELMEZ — o yalnız cihaz içi kimliktir (docs/18 §4).
-- • `sync_state` de gelmez — giden kutusu bayrağı, cihaza ait.
-- • Tablolar arası referanslar `*_uid` üzerinden.
-- • ⚠️ TABLO SIRASI BAĞIMLILIĞA GÖRE: referans verilen tablo önce oluşur
--   (foods → food_logs/recipe_items, routines → routine_exercises,
--   workout_sessions → workout_sets). Betik tek işlem olarak çalışır; sıra
--   yanlışsa TAMAMI geri alınır.
-- • Hareket/besin referanslarında YABANCI ANAHTAR KISITI YOK: katalog satırları
--   ancak kullanıcı onları kullanınca yükleniyor (tembel senkron — docs/18 §3.2
--   seçenek A). Sıralamayı senkron katmanı garanti eder.
-- • auth.users silinince her şey cascade ile gider → hesap silme (docs/16 §4).
--
-- ÇALIŞTIRMA: Supabase Dashboard → SQL Editor → yapıştır → Run.
-- Tekrar çalıştırmak güvenlidir (if not exists / drop policy if exists).

create table if not exists public.user_profile (
  uid          uuid        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  updated_at   timestamptz not null default now(),
  current_phase integer not null,
  current_week integer not null,
  start_date   timestamptz not null,
  kcal_goal    integer not null,
  protein_goal integer not null,
  last_deload  timestamptz,
  height_cm    double precision,
  goal_weight_kg double precision,
  onboarded    boolean not null,
  water_goal_ml integer not null,
  birth_date   timestamptz,
  gender       text,
  activity_level text
);

create table if not exists public.exercises (
  uid          uuid        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  updated_at   timestamptz not null default now(),
  name         text not null,
  category     text not null,
  muscle_groups text not null,
  alternatives text,
  notes        text,
  is_posture   boolean not null,
  is_arm       boolean not null,
  primary_muscle text,
  equipment    text,
  measurement_type text not null,
  is_custom    boolean not null,
  is_archived  boolean not null,
  image_path   text,
  instructions text,
  level        text,
  force        text
);

create table if not exists public.foods (
  uid          uuid        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  updated_at   timestamptz not null default now(),
  name         text not null,
  barcode      text,
  kcal_per100g double precision not null,
  protein_per100g double precision not null,
  carb_per100g double precision not null,
  fat_per100g  double precision not null,
  source       text not null,
  is_custom    boolean not null,
  is_recipe    boolean not null,
  default_portion_grams double precision,
  unit_label   text,
  category     text
);

create table if not exists public.routines (
  uid          uuid        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  updated_at   timestamptz not null default now(),
  name         text not null,
  note         text,
  order_index  integer not null,
  scheduled_weekday integer,
  created_at   timestamptz not null,
  is_archived  boolean not null
);

create table if not exists public.routine_exercises (
  uid          uuid        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  updated_at   timestamptz not null default now(),
  routine_uid  uuid references public.routines(uid) on delete cascade,
  exercise_uid uuid,
  order_index  integer not null,
  target_sets  integer,
  target_reps_min integer,
  target_reps_max integer,
  target_rest_sec integer,
  note         text
);

create table if not exists public.workout_sessions (
  uid          uuid        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  updated_at   timestamptz not null default now(),
  date         timestamptz not null,
  phase        integer not null,
  workout_type text not null,
  duration_min integer,
  knee_status  text not null,
  energy       integer,
  rpe          integer,
  notes        text,
  is_deload    boolean not null,
  routine_uid  uuid,
  started_at   timestamptz,
  ended_at     timestamptz
);

create table if not exists public.workout_sets (
  uid          uuid        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  updated_at   timestamptz not null default now(),
  session_uid  uuid references public.workout_sessions(uid) on delete cascade,
  exercise_uid uuid,
  set_number   integer not null,
  weight_kg    double precision,
  reps         integer,
  is_warmup    boolean not null,
  rest_seconds integer,
  rpe          double precision,
  set_type     text not null,
  is_complete  boolean not null,
  distance_m   double precision,
  duration_sec integer
);

create table if not exists public.food_logs (
  uid          uuid        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  updated_at   timestamptz not null default now(),
  date         timestamptz not null,
  meal_type    text not null,
  food_uid     uuid,
  grams        double precision not null,
  computed_kcal double precision not null,
  computed_protein double precision not null,
  computed_carb double precision not null,
  computed_fat double precision not null
);

create table if not exists public.recipe_items (
  uid          uuid        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  updated_at   timestamptz not null default now(),
  recipe_uid   uuid references public.foods(uid) on delete cascade,
  food_uid     uuid,
  grams        double precision not null
);

create table if not exists public.water_intake (
  uid          uuid        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  updated_at   timestamptz not null default now(),
  date         timestamptz not null,
  amount_ml    integer not null
);

create table if not exists public.body_measurements (
  uid          uuid        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  updated_at   timestamptz not null default now(),
  date         timestamptz not null,
  weight_kg    double precision,
  waist_cm     double precision,
  chest_cm     double precision,
  arm_cm       double precision,
  hip_cm       double precision,
  neck_cm      double precision,
  body_fat_pct double precision
);

create table if not exists public.progress_photos (
  uid          uuid        primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  updated_at   timestamptz not null default now(),
  date         timestamptz not null,
  angle        text not null,
  image_path   text not null
);

-- ─────────────────────── RLS (satır bazlı güvenlik) ───────────────────────
-- Her kullanıcı YALNIZ kendi satırlarını görür/yazar. İstisnasız her tabloda.

alter table public.user_profile enable row level security;
drop policy if exists "own rows" on public.user_profile;
create policy "own rows" on public.user_profile
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.exercises enable row level security;
drop policy if exists "own rows" on public.exercises;
create policy "own rows" on public.exercises
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.foods enable row level security;
drop policy if exists "own rows" on public.foods;
create policy "own rows" on public.foods
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.routines enable row level security;
drop policy if exists "own rows" on public.routines;
create policy "own rows" on public.routines
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.routine_exercises enable row level security;
drop policy if exists "own rows" on public.routine_exercises;
create policy "own rows" on public.routine_exercises
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.workout_sessions enable row level security;
drop policy if exists "own rows" on public.workout_sessions;
create policy "own rows" on public.workout_sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.workout_sets enable row level security;
drop policy if exists "own rows" on public.workout_sets;
create policy "own rows" on public.workout_sets
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.food_logs enable row level security;
drop policy if exists "own rows" on public.food_logs;
create policy "own rows" on public.food_logs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.recipe_items enable row level security;
drop policy if exists "own rows" on public.recipe_items;
create policy "own rows" on public.recipe_items
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.water_intake enable row level security;
drop policy if exists "own rows" on public.water_intake;
create policy "own rows" on public.water_intake
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.body_measurements enable row level security;
drop policy if exists "own rows" on public.body_measurements;
create policy "own rows" on public.body_measurements
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.progress_photos enable row level security;
drop policy if exists "own rows" on public.progress_photos;
create policy "own rows" on public.progress_photos
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─────────────────────── Kısıtlar ───────────────────────
-- Kullanıcı başına TEK profil. Senkron hatası çift profil yaratmasın.
create unique index if not exists user_profile_one_per_user
  on public.user_profile(user_id);

-- ─────────────────────── Indeksler ───────────────────────
-- Senkron çekme sorgusu: kullanıcı + son değişiklik zamanı.
create index if not exists user_profile_user_updated_idx on public.user_profile(user_id, updated_at desc);
create index if not exists exercises_user_updated_idx on public.exercises(user_id, updated_at desc);
create index if not exists foods_user_updated_idx on public.foods(user_id, updated_at desc);
create index if not exists routines_user_updated_idx on public.routines(user_id, updated_at desc);
create index if not exists routine_exercises_user_updated_idx on public.routine_exercises(user_id, updated_at desc);
create index if not exists workout_sessions_user_updated_idx on public.workout_sessions(user_id, updated_at desc);
create index if not exists workout_sets_user_updated_idx on public.workout_sets(user_id, updated_at desc);
create index if not exists food_logs_user_updated_idx on public.food_logs(user_id, updated_at desc);
create index if not exists recipe_items_user_updated_idx on public.recipe_items(user_id, updated_at desc);
create index if not exists water_intake_user_updated_idx on public.water_intake(user_id, updated_at desc);
create index if not exists body_measurements_user_updated_idx on public.body_measurements(user_id, updated_at desc);
create index if not exists progress_photos_user_updated_idx on public.progress_photos(user_id, updated_at desc);
