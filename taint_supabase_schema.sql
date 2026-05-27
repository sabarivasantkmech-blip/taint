-- TAINT application database for Supabase/Postgres.
-- Run this in Supabase SQL Editor, then run supabase_business_storage_migration.sql
-- for business entities, JSON artifact storage, and media storage.
-- Paste the Project URL and anon key into supabase-config.js.

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Public aggregate counters used by the existing UI.
-- ---------------------------------------------------------------------------
create table if not exists public.stats (
  key text primary key,
  value bigint not null default 0 check (value >= 0),
  updated_at timestamptz not null default now()
);

insert into public.stats (key, value)
values ('uniqueUsers', 0), ('totalCalcs', 0)
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Auth-linked user profile. Supabase Auth remains the source of truth for
-- credentials; this table stores app-facing profile metadata only.
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  auth_user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  email text,
  city_key text,
  city_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Anonymous or signed-in browser/device sessions.
create table if not exists public.visitor_devices (
  device_id text primary key,
  auth_user_id uuid references auth.users(id) on delete set null,
  city_key text,
  city_name text,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  visit_count bigint not null default 1 check (visit_count >= 1)
);

-- Generic event/process log from the UI.
create table if not exists public.app_events (
  id uuid primary key default gen_random_uuid(),
  device_id text references public.visitor_devices(device_id) on delete set null,
  auth_user_id uuid references auth.users(id) on delete set null,
  event_name text not null,
  event_category text not null default 'ui',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Commute calculator records.
create table if not exists public.calculation_logs (
  id uuid primary key default gen_random_uuid(),
  device_id text references public.visitor_devices(device_id) on delete set null,
  auth_user_id uuid references auth.users(id) on delete set null,
  calculation_type text not null default 'commute',
  city_key text,
  city_name text,
  category text,
  fuel text,
  vehicle text,
  distance_km numeric(10,3) check (distance_km is null or distance_km >= 0),
  passengers integer check (passengers is null or passengers > 0),
  per_trip_kg numeric(12,6) check (per_trip_kg is null or per_trip_kg >= 0),
  per_passenger_kg numeric(12,6) check (per_passenger_kg is null or per_passenger_kg >= 0),
  from_label text,
  to_label text,
  raw_input jsonb not null default '{}'::jsonb,
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Route search and live journey records.
create table if not exists public.route_logs (
  id uuid primary key default gen_random_uuid(),
  device_id text references public.visitor_devices(device_id) on delete set null,
  auth_user_id uuid references auth.users(id) on delete set null,
  city_key text,
  city_name text,
  from_label text,
  to_label text,
  distance_km numeric(10,3) check (distance_km is null or distance_km >= 0),
  mode text,
  source text not null default 'ui',
  route_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Feedback from Contact and My Taint surfaces.
create table if not exists public.feedback_messages (
  id uuid primary key default gen_random_uuid(),
  device_id text references public.visitor_devices(device_id) on delete set null,
  auth_user_id uuid references auth.users(id) on delete set null,
  source text not null default 'contact',
  name text,
  email text,
  feedback_type text,
  rating integer check (rating is null or rating between 1 and 5),
  message text,
  city_key text,
  city_name text,
  email_sent boolean,
  email_error text,
  created_at timestamptz not null default now()
);

-- My Taint, workplace, and household carbon profile snapshots.
create table if not exists public.carbon_profiles (
  id uuid primary key default gen_random_uuid(),
  device_id text references public.visitor_devices(device_id) on delete set null,
  auth_user_id uuid references auth.users(id) on delete set null,
  profile_type text not null check (profile_type in ('my_taint', 'workplace', 'household')),
  city_key text,
  city_name text,
  total_tco2e numeric(14,6) check (total_tco2e is null or total_tco2e >= 0),
  per_capita_tco2e numeric(14,6) check (per_capita_tco2e is null or per_capita_tco2e >= 0),
  grade text,
  inputs jsonb not null default '{}'::jsonb,
  results jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Personal emissions commitments.
create table if not exists public.commitments (
  id uuid primary key default gen_random_uuid(),
  device_id text references public.visitor_devices(device_id) on delete set null,
  auth_user_id uuid references auth.users(id) on delete set null,
  city_key text,
  city_name text,
  target_year integer not null check (target_year between 2026 and 2100),
  reduction_percent numeric(5,2) not null check (reduction_percent between 0 and 100),
  baseline_tco2e numeric(14,6) check (baseline_tco2e is null or baseline_tco2e >= 0),
  target_tco2e numeric(14,6) check (target_tco2e is null or target_tco2e >= 0),
  created_at timestamptz not null default now()
);

-- Taint Buy outbound click log.
create table if not exists public.product_clicks (
  id uuid primary key default gen_random_uuid(),
  device_id text references public.visitor_devices(device_id) on delete set null,
  auth_user_id uuid references auth.users(id) on delete set null,
  platform text not null,
  product_id text not null,
  city_key text,
  city_name text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Process/API/AI job log for UI workflows such as route lookup, AI tips, exports.
create table if not exists public.process_runs (
  id uuid primary key default gen_random_uuid(),
  device_id text references public.visitor_devices(device_id) on delete set null,
  auth_user_id uuid references auth.users(id) on delete set null,
  process_type text not null,
  status text not null default 'started' check (status in ('started', 'succeeded', 'failed')),
  request_payload jsonb not null default '{}'::jsonb,
  response_payload jsonb,
  error_message text,
  started_at timestamptz not null default now(),
  finished_at timestamptz
);

create index if not exists idx_app_events_created_at on public.app_events(created_at desc);
create index if not exists idx_app_events_device_id on public.app_events(device_id);
create index if not exists idx_calculation_logs_created_at on public.calculation_logs(created_at desc);
create index if not exists idx_calculation_logs_user on public.calculation_logs(auth_user_id, created_at desc);
create index if not exists idx_route_logs_created_at on public.route_logs(created_at desc);
create index if not exists idx_feedback_messages_created_at on public.feedback_messages(created_at desc);
create index if not exists idx_carbon_profiles_user on public.carbon_profiles(auth_user_id, created_at desc);
create index if not exists idx_product_clicks_created_at on public.product_clicks(created_at desc);
create index if not exists idx_process_runs_created_at on public.process_runs(started_at desc);

-- ---------------------------------------------------------------------------
-- Utility trigger/functions.
-- ---------------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_touch_updated_at on public.profiles;
create trigger trg_profiles_touch_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (auth_user_id, display_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)),
    new.email
  )
  on conflict (auth_user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_taint_profile on auth.users;
create trigger on_auth_user_created_taint_profile
after insert on auth.users
for each row execute function public.handle_new_auth_user();

create or replace function public.increment_stat(stat_key text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.stats(key, value, updated_at)
  values(stat_key, 1, now())
  on conflict(key) do update
    set value = public.stats.value + 1,
        updated_at = now();
end;
$$;

create or replace function public.register_device(
  p_device_id text,
  p_city_key text default null,
  p_city_name text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.visitor_devices (device_id, auth_user_id, city_key, city_name)
  values (p_device_id, auth.uid(), p_city_key, p_city_name)
  on conflict (device_id) do nothing;

  if found then
    perform public.increment_stat('uniqueUsers');
  else
    update public.visitor_devices
       set auth_user_id = coalesce(public.visitor_devices.auth_user_id, auth.uid()),
           city_key = coalesce(p_city_key, public.visitor_devices.city_key),
           city_name = coalesce(p_city_name, public.visitor_devices.city_name),
           last_seen_at = now(),
           visit_count = public.visitor_devices.visit_count + 1
     where device_id = p_device_id;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Row-level security.
-- ---------------------------------------------------------------------------
alter table public.stats enable row level security;
alter table public.profiles enable row level security;
alter table public.visitor_devices enable row level security;
alter table public.app_events enable row level security;
alter table public.calculation_logs enable row level security;
alter table public.route_logs enable row level security;
alter table public.feedback_messages enable row level security;
alter table public.carbon_profiles enable row level security;
alter table public.commitments enable row level security;
alter table public.product_clicks enable row level security;
alter table public.process_runs enable row level security;

drop policy if exists "public read stats" on public.stats;
create policy "public read stats"
on public.stats for select
to anon, authenticated
using (true);

drop policy if exists "users read own profile" on public.profiles;
create policy "users read own profile"
on public.profiles for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile"
on public.profiles for update
to authenticated
using (auth_user_id = auth.uid())
with check (auth_user_id = auth.uid());

drop policy if exists "users insert own profile" on public.profiles;
create policy "users insert own profile"
on public.profiles for insert
to authenticated
with check (auth_user_id = auth.uid());

drop policy if exists "read own visitor device" on public.visitor_devices;
create policy "read own visitor device"
on public.visitor_devices for select
to authenticated
using (auth_user_id = auth.uid());

-- Logs are write-only for guests. Signed-in users can read their own rows.
drop policy if exists "insert app events" on public.app_events;
create policy "insert app events"
on public.app_events for insert
to anon, authenticated
with check (auth_user_id is null or auth_user_id = auth.uid());

drop policy if exists "read own app events" on public.app_events;
create policy "read own app events"
on public.app_events for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists "insert calculation logs" on public.calculation_logs;
create policy "insert calculation logs"
on public.calculation_logs for insert
to anon, authenticated
with check (auth_user_id is null or auth_user_id = auth.uid());

drop policy if exists "read own calculation logs" on public.calculation_logs;
create policy "read own calculation logs"
on public.calculation_logs for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists "insert route logs" on public.route_logs;
create policy "insert route logs"
on public.route_logs for insert
to anon, authenticated
with check (auth_user_id is null or auth_user_id = auth.uid());

drop policy if exists "read own route logs" on public.route_logs;
create policy "read own route logs"
on public.route_logs for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists "insert feedback" on public.feedback_messages;
create policy "insert feedback"
on public.feedback_messages for insert
to anon, authenticated
with check (auth_user_id is null or auth_user_id = auth.uid());

drop policy if exists "read own feedback" on public.feedback_messages;
create policy "read own feedback"
on public.feedback_messages for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists "insert carbon profiles" on public.carbon_profiles;
create policy "insert carbon profiles"
on public.carbon_profiles for insert
to anon, authenticated
with check (auth_user_id is null or auth_user_id = auth.uid());

drop policy if exists "read own carbon profiles" on public.carbon_profiles;
create policy "read own carbon profiles"
on public.carbon_profiles for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists "insert commitments" on public.commitments;
create policy "insert commitments"
on public.commitments for insert
to anon, authenticated
with check (auth_user_id is null or auth_user_id = auth.uid());

drop policy if exists "read own commitments" on public.commitments;
create policy "read own commitments"
on public.commitments for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists "insert product clicks" on public.product_clicks;
create policy "insert product clicks"
on public.product_clicks for insert
to anon, authenticated
with check (auth_user_id is null or auth_user_id = auth.uid());

drop policy if exists "read own product clicks" on public.product_clicks;
create policy "read own product clicks"
on public.product_clicks for select
to authenticated
using (auth_user_id = auth.uid());

drop policy if exists "insert process runs" on public.process_runs;
create policy "insert process runs"
on public.process_runs for insert
to anon, authenticated
with check (auth_user_id is null or auth_user_id = auth.uid());

drop policy if exists "read own process runs" on public.process_runs;
create policy "read own process runs"
on public.process_runs for select
to authenticated
using (auth_user_id = auth.uid());

grant usage on schema public to anon, authenticated;
grant select on public.stats to anon, authenticated;
grant select, insert, update on public.profiles to authenticated;
grant insert on public.app_events, public.calculation_logs, public.route_logs,
  public.feedback_messages, public.carbon_profiles, public.commitments,
  public.product_clicks, public.process_runs to anon, authenticated;
grant select on public.app_events, public.calculation_logs, public.route_logs,
  public.feedback_messages, public.carbon_profiles, public.commitments,
  public.product_clicks, public.process_runs to authenticated;
grant execute on function public.increment_stat(text) to anon, authenticated;
grant execute on function public.register_device(text, text, text) to anon, authenticated;
revoke execute on function public.handle_new_auth_user() from anon, authenticated;

commit;
