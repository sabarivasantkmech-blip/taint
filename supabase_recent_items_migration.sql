-- TAINT saved calculation items.
-- Apply after taint_supabase_schema.sql and supabase_user_owned_logs_rls_followup.sql.
-- This moves the latest-5 calculation list away from browser storage for signed-in users.

begin;

create table if not exists public.user_calculation_items (
  id uuid primary key default gen_random_uuid(),
  device_id text references public.visitor_devices(device_id) on delete set null,
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  mode text not null check (mode in ('commute', 'workplace', 'home', 'taint', 'buy')),
  city_name text,
  title text not null,
  detail text,
  value numeric(14,6) not null default 0,
  unit text not null default 't/yr',
  grade text,
  source_table text,
  source_row_id uuid,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_user_calculation_items_owner
on public.user_calculation_items(auth_user_id, mode, created_at desc);

create index if not exists idx_user_calculation_items_device
on public.user_calculation_items(device_id);

create index if not exists idx_user_calculation_items_source
on public.user_calculation_items(auth_user_id, source_table, source_row_id);

drop trigger if exists trg_user_calculation_items_touch_updated_at on public.user_calculation_items;
create trigger trg_user_calculation_items_touch_updated_at
before update on public.user_calculation_items
for each row execute function public.touch_updated_at();

alter table public.user_calculation_items enable row level security;

drop policy if exists "insert own saved calculation items" on public.user_calculation_items;
create policy "insert own saved calculation items"
on public.user_calculation_items for insert
to authenticated
with check (auth_user_id = (select auth.uid()));

drop policy if exists "read own saved calculation items" on public.user_calculation_items;
create policy "read own saved calculation items"
on public.user_calculation_items for select
to authenticated
using (auth_user_id = (select auth.uid()));

drop policy if exists "update own saved calculation items" on public.user_calculation_items;
create policy "update own saved calculation items"
on public.user_calculation_items for update
to authenticated
using (auth_user_id = (select auth.uid()))
with check (auth_user_id = (select auth.uid()));

drop policy if exists "delete own saved calculation items" on public.user_calculation_items;
create policy "delete own saved calculation items"
on public.user_calculation_items for delete
to authenticated
using (auth_user_id = (select auth.uid()));

revoke all on public.user_calculation_items from anon, authenticated;
grant select, insert, update, delete on public.user_calculation_items to authenticated;

commit;
