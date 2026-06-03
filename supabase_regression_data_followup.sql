-- TAINT regression data follow-up.
-- Apply after the main schema and business storage migrations.

begin;

alter table public.profiles
  add column if not exists username text;

create index if not exists idx_profiles_email_lower
on public.profiles (lower(email));

create index if not exists idx_profiles_username_lower
on public.profiles (lower(username));

create table if not exists public.product_purchases (
  id uuid primary key default gen_random_uuid(),
  device_id text references public.visitor_devices(device_id) on delete set null,
  auth_user_id uuid references auth.users(id) on delete set null,
  product_id text not null,
  product_name text not null,
  platform text,
  status text not null default 'checked_out'
    check (status in ('checked_out', 'bought')),
  price_num numeric(14,2) check (price_num is null or price_num >= 0),
  quantity integer not null default 1 check (quantity > 0),
  city_key text,
  city_name text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_product_purchases_user
on public.product_purchases(auth_user_id, created_at desc);

create index if not exists idx_product_purchases_device
on public.product_purchases(device_id, created_at desc);

alter table public.product_purchases enable row level security;

drop policy if exists "insert product purchases" on public.product_purchases;
create policy "insert product purchases"
on public.product_purchases for insert
to authenticated
with check (auth_user_id = (select auth.uid()));

drop policy if exists "read own product purchases" on public.product_purchases;
create policy "read own product purchases"
on public.product_purchases for select
to authenticated
using (auth_user_id = (select auth.uid()));

create or replace function public.taint_account_email_exists(p_email text)
returns boolean
language sql
security definer
set search_path = auth, public
stable
as $$
  with normalized as (
    select lower(trim(coalesce(p_email, ''))) as email
  )
  select case
    when (select email from normalized) = ''
      or (select email from normalized) !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
      then false
    else exists (
      select 1
        from auth.users u, normalized n
       where lower(u.email) = n.email
         and u.deleted_at is null
    )
    or exists (
      select 1
        from public.profiles p, normalized n
       where lower(p.email) = n.email
    )
  end;
$$;

revoke all on public.product_purchases from anon;
grant select, insert on public.product_purchases to authenticated;
revoke all on function public.taint_account_email_exists(text) from public;
grant execute on function public.taint_account_email_exists(text) to anon, authenticated;

commit;
