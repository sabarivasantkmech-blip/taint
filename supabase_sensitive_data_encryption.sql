-- TAINT sensitive user data encryption.
-- Uses Supabase Vault so sensitive JSON is encrypted at rest and only exposed
-- through authenticated RPC functions that enforce auth.uid() ownership.
-- Apply after taint_supabase_schema.sql and supabase_business_storage_migration.sql.

begin;

create extension if not exists supabase_vault with schema vault;

create table if not exists public.sensitive_user_records (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  record_type text not null,
  vault_secret_id uuid not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (auth_user_id, record_type),
  check (record_type ~ '^[a-z0-9_:-]{1,64}$')
);

create index if not exists idx_sensitive_user_records_user
on public.sensitive_user_records(auth_user_id, updated_at desc);

drop trigger if exists trg_sensitive_user_records_touch_updated_at on public.sensitive_user_records;
create trigger trg_sensitive_user_records_touch_updated_at
before update on public.sensitive_user_records
for each row execute function public.touch_updated_at();

alter table public.sensitive_user_records enable row level security;

drop policy if exists "sensitive records metadata read own" on public.sensitive_user_records;
create policy "sensitive records metadata read own"
on public.sensitive_user_records for select
to authenticated
using (auth_user_id = (select auth.uid()));

drop policy if exists "sensitive records metadata insert own" on public.sensitive_user_records;
create policy "sensitive records metadata insert own"
on public.sensitive_user_records for insert
to authenticated
with check (auth_user_id = (select auth.uid()));

drop policy if exists "sensitive records metadata update own" on public.sensitive_user_records;
create policy "sensitive records metadata update own"
on public.sensitive_user_records for update
to authenticated
using (auth_user_id = (select auth.uid()))
with check (auth_user_id = (select auth.uid()));

create or replace function public.store_sensitive_user_data(
  p_record_type text,
  p_payload jsonb,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, vault, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_existing uuid;
  v_secret_id uuid;
  v_record_id uuid;
  v_name text;
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;
  if p_record_type is null or p_record_type !~ '^[a-z0-9_:-]{1,64}$' then
    raise exception 'Invalid record type';
  end if;
  if p_payload is null then
    raise exception 'Payload is required';
  end if;

  select id, vault_secret_id
    into v_record_id, v_existing
  from public.sensitive_user_records
  where auth_user_id = v_uid
    and record_type = p_record_type
  for update;

  if v_existing is not null then
    perform vault.update_secret(
      v_existing,
      p_payload::text,
      null,
      'TAINT encrypted sensitive user data',
      null
    );
    update public.sensitive_user_records
       set metadata = coalesce(p_metadata, '{}'::jsonb),
           updated_at = now()
     where id = v_record_id;
    return v_record_id;
  end if;

  v_record_id := gen_random_uuid();
  v_name := 'taint_sensitive_' || replace(v_record_id::text, '-', '_');
  v_secret_id := vault.create_secret(
    p_payload::text,
    v_name,
    'TAINT encrypted sensitive user data',
    null
  );

  insert into public.sensitive_user_records
    (id, auth_user_id, record_type, vault_secret_id, metadata)
  values
    (v_record_id, v_uid, p_record_type, v_secret_id, coalesce(p_metadata, '{}'::jsonb));

  return v_record_id;
end;
$$;

create or replace function public.get_sensitive_user_data(p_record_type text)
returns jsonb
language plpgsql
security definer
set search_path = public, vault, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_payload text;
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;
  if p_record_type is null or p_record_type !~ '^[a-z0-9_:-]{1,64}$' then
    raise exception 'Invalid record type';
  end if;

  select ds.decrypted_secret
    into v_payload
  from public.sensitive_user_records r
  join vault.decrypted_secrets ds on ds.id = r.vault_secret_id
  where r.auth_user_id = v_uid
    and r.record_type = p_record_type
  limit 1;

  return coalesce(v_payload::jsonb, null);
end;
$$;

revoke all on public.sensitive_user_records from anon;
revoke execute on function public.store_sensitive_user_data(text, jsonb, jsonb) from public, anon;
revoke execute on function public.get_sensitive_user_data(text) from public, anon;

grant select on public.sensitive_user_records to authenticated;
grant execute on function public.store_sensitive_user_data(text, jsonb, jsonb) to authenticated;
grant execute on function public.get_sensitive_user_data(text) to authenticated;

commit;
