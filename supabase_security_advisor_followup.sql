-- TAINT Supabase advisor follow-up.
-- Tightens helper functions and adds a narrow visitor device read policy.

begin;

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

revoke execute on function public.handle_new_auth_user() from anon, authenticated;

do $$
begin
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'rls_auto_enable'
      and p.pronargs = 0
  ) then
    execute 'revoke execute on function public.rls_auto_enable() from anon, authenticated';
  end if;
end $$;

drop policy if exists "read own visitor device" on public.visitor_devices;
create policy "read own visitor device"
on public.visitor_devices for select
to authenticated
using (auth_user_id = (select auth.uid()));

commit;
