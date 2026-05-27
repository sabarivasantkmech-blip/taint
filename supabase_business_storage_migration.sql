-- TAINT business entities, artifact metadata, and private storage buckets.
-- Apply after taint_supabase_schema.sql.

begin;

create table if not exists public.business_entities (
  id uuid primary key default gen_random_uuid(),
  owner_auth_user_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null default 'organization'
    check (entity_type in ('person', 'organization', 'workplace', 'project', 'site', 'vendor')),
  legal_name text,
  display_name text not null,
  sector text,
  industry text,
  registration_no text,
  tax_id text,
  city_key text,
  city_name text,
  contact_email text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.business_entity_members (
  id uuid primary key default gen_random_uuid(),
  business_entity_id uuid not null references public.business_entities(id) on delete cascade,
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  member_role text not null default 'viewer'
    check (member_role in ('owner', 'admin', 'editor', 'viewer')),
  created_at timestamptz not null default now(),
  unique (business_entity_id, auth_user_id)
);

create table if not exists public.business_locations (
  id uuid primary key default gen_random_uuid(),
  business_entity_id uuid not null references public.business_entities(id) on delete cascade,
  location_name text,
  address_text text,
  city_key text,
  city_name text,
  latitude numeric(10,7),
  longitude numeric(10,7),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.app_files (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  device_id text references public.visitor_devices(device_id) on delete set null,
  business_entity_id uuid references public.business_entities(id) on delete set null,
  process_run_id uuid references public.process_runs(id) on delete set null,
  bucket_id text not null,
  object_path text not null,
  file_category text not null default 'json'
    check (file_category in ('json', 'image', 'document', 'export', 'attachment', 'other')),
  mime_type text not null,
  extension text,
  size_bytes bigint check (size_bytes is null or size_bytes >= 0),
  checksum_sha256 text,
  title text,
  description text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (bucket_id, object_path)
);

alter table public.calculation_logs add column if not exists business_entity_id uuid;
alter table public.route_logs add column if not exists business_entity_id uuid;
alter table public.feedback_messages add column if not exists business_entity_id uuid;
alter table public.carbon_profiles add column if not exists business_entity_id uuid;
alter table public.commitments add column if not exists business_entity_id uuid;
alter table public.product_clicks add column if not exists business_entity_id uuid;
alter table public.process_runs add column if not exists business_entity_id uuid;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'calculation_logs_business_entity_id_fkey') then
    alter table public.calculation_logs
      add constraint calculation_logs_business_entity_id_fkey
      foreign key (business_entity_id) references public.business_entities(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'route_logs_business_entity_id_fkey') then
    alter table public.route_logs
      add constraint route_logs_business_entity_id_fkey
      foreign key (business_entity_id) references public.business_entities(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'feedback_messages_business_entity_id_fkey') then
    alter table public.feedback_messages
      add constraint feedback_messages_business_entity_id_fkey
      foreign key (business_entity_id) references public.business_entities(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'carbon_profiles_business_entity_id_fkey') then
    alter table public.carbon_profiles
      add constraint carbon_profiles_business_entity_id_fkey
      foreign key (business_entity_id) references public.business_entities(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'commitments_business_entity_id_fkey') then
    alter table public.commitments
      add constraint commitments_business_entity_id_fkey
      foreign key (business_entity_id) references public.business_entities(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'product_clicks_business_entity_id_fkey') then
    alter table public.product_clicks
      add constraint product_clicks_business_entity_id_fkey
      foreign key (business_entity_id) references public.business_entities(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'process_runs_business_entity_id_fkey') then
    alter table public.process_runs
      add constraint process_runs_business_entity_id_fkey
      foreign key (business_entity_id) references public.business_entities(id) on delete set null;
  end if;
end $$;

create index if not exists idx_business_entities_owner on public.business_entities(owner_auth_user_id, created_at desc);
create index if not exists idx_business_entity_members_user on public.business_entity_members(auth_user_id);
create index if not exists idx_business_locations_entity on public.business_locations(business_entity_id);
create index if not exists idx_app_files_user on public.app_files(auth_user_id, created_at desc);
create index if not exists idx_app_files_entity on public.app_files(business_entity_id, created_at desc);
create index if not exists idx_app_files_bucket_path on public.app_files(bucket_id, object_path);
create index if not exists idx_calculation_logs_entity on public.calculation_logs(business_entity_id, created_at desc);
create index if not exists idx_process_runs_entity on public.process_runs(business_entity_id, started_at desc);

drop trigger if exists trg_business_entities_touch_updated_at on public.business_entities;
create trigger trg_business_entities_touch_updated_at
before update on public.business_entities
for each row execute function public.touch_updated_at();

drop trigger if exists trg_business_locations_touch_updated_at on public.business_locations;
create trigger trg_business_locations_touch_updated_at
before update on public.business_locations
for each row execute function public.touch_updated_at();

alter table public.business_entities enable row level security;
alter table public.business_entity_members enable row level security;
alter table public.business_locations enable row level security;
alter table public.app_files enable row level security;

drop policy if exists "business entities insert own" on public.business_entities;
create policy "business entities insert own"
on public.business_entities for insert
to authenticated
with check (owner_auth_user_id = (select auth.uid()));

drop policy if exists "business entities read members" on public.business_entities;
create policy "business entities read members"
on public.business_entities for select
to authenticated
using (
  owner_auth_user_id = (select auth.uid())
  or exists (
    select 1 from public.business_entity_members m
    where m.business_entity_id = business_entities.id
      and m.auth_user_id = (select auth.uid())
  )
);

drop policy if exists "business entities update admins" on public.business_entities;
create policy "business entities update admins"
on public.business_entities for update
to authenticated
using (
  owner_auth_user_id = (select auth.uid())
  or exists (
    select 1 from public.business_entity_members m
    where m.business_entity_id = business_entities.id
      and m.auth_user_id = (select auth.uid())
      and m.member_role in ('owner', 'admin')
  )
)
with check (
  owner_auth_user_id = (select auth.uid())
  or exists (
    select 1 from public.business_entity_members m
    where m.business_entity_id = business_entities.id
      and m.auth_user_id = (select auth.uid())
      and m.member_role in ('owner', 'admin')
  )
);

drop policy if exists "business members read related" on public.business_entity_members;
create policy "business members read related"
on public.business_entity_members for select
to authenticated
using (auth_user_id = (select auth.uid()));

drop policy if exists "business members insert owner" on public.business_entity_members;
create policy "business members insert owner"
on public.business_entity_members for insert
to authenticated
with check (
  exists (
    select 1 from public.business_entities e
    where e.id = business_entity_members.business_entity_id
      and e.owner_auth_user_id = (select auth.uid())
  )
);

drop policy if exists "business locations read members" on public.business_locations;
create policy "business locations read members"
on public.business_locations for select
to authenticated
using (
  exists (
    select 1 from public.business_entities e
    where e.id = business_locations.business_entity_id
      and (
        e.owner_auth_user_id = (select auth.uid())
        or exists (
          select 1 from public.business_entity_members m
          where m.business_entity_id = e.id
            and m.auth_user_id = (select auth.uid())
        )
      )
  )
);

drop policy if exists "business locations write editors" on public.business_locations;
create policy "business locations write editors"
on public.business_locations for all
to authenticated
using (
  exists (
    select 1 from public.business_entities e
    where e.id = business_locations.business_entity_id
      and (
        e.owner_auth_user_id = (select auth.uid())
        or exists (
          select 1 from public.business_entity_members m
          where m.business_entity_id = e.id
            and m.auth_user_id = (select auth.uid())
            and m.member_role in ('owner', 'admin', 'editor')
        )
      )
  )
)
with check (
  exists (
    select 1 from public.business_entities e
    where e.id = business_locations.business_entity_id
      and (
        e.owner_auth_user_id = (select auth.uid())
        or exists (
          select 1 from public.business_entity_members m
          where m.business_entity_id = e.id
            and m.auth_user_id = (select auth.uid())
            and m.member_role in ('owner', 'admin', 'editor')
        )
      )
  )
);

drop policy if exists "app files insert own" on public.app_files;
create policy "app files insert own"
on public.app_files for insert
to authenticated
with check (
  auth_user_id = (select auth.uid())
  and (
    business_entity_id is null
    or exists (
      select 1 from public.business_entities e
      where e.id = app_files.business_entity_id
        and (
          e.owner_auth_user_id = (select auth.uid())
          or exists (
            select 1 from public.business_entity_members m
            where m.business_entity_id = e.id
              and m.auth_user_id = (select auth.uid())
              and m.member_role in ('owner', 'admin', 'editor')
          )
        )
    )
  )
);

drop policy if exists "app files read own or entity" on public.app_files;
create policy "app files read own or entity"
on public.app_files for select
to authenticated
using (
  auth_user_id = (select auth.uid())
  or exists (
    select 1 from public.business_entities e
    where e.id = app_files.business_entity_id
      and (
        e.owner_auth_user_id = (select auth.uid())
        or exists (
          select 1 from public.business_entity_members m
          where m.business_entity_id = e.id
            and m.auth_user_id = (select auth.uid())
        )
      )
  )
);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'taint-json-artifacts',
    'taint-json-artifacts',
    false,
    10485760,
    array['application/json', 'text/json']::text[]
  ),
  (
    'taint-media',
    'taint-media',
    false,
    52428800,
    array[
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif',
      'application/pdf',
      'text/plain'
    ]::text[]
  )
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "taint storage read own folder" on storage.objects;
create policy "taint storage read own folder"
on storage.objects for select
to authenticated
using (
  bucket_id in ('taint-json-artifacts', 'taint-media')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "taint storage insert own folder" on storage.objects;
create policy "taint storage insert own folder"
on storage.objects for insert
to authenticated
with check (
  bucket_id in ('taint-json-artifacts', 'taint-media')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "taint storage update own folder" on storage.objects;
create policy "taint storage update own folder"
on storage.objects for update
to authenticated
using (
  bucket_id in ('taint-json-artifacts', 'taint-media')
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id in ('taint-json-artifacts', 'taint-media')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "taint storage delete own folder" on storage.objects;
create policy "taint storage delete own folder"
on storage.objects for delete
to authenticated
using (
  bucket_id in ('taint-json-artifacts', 'taint-media')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

grant select, insert, update on public.business_entities to authenticated;
grant select, insert, update, delete on public.business_entity_members to authenticated;
grant select, insert, update, delete on public.business_locations to authenticated;
grant select, insert on public.app_files to authenticated;

commit;
