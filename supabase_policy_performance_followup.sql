-- TAINT Supabase policy/performance follow-up.

begin;

revoke execute on function public.handle_new_auth_user() from public, anon, authenticated;

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
    execute 'revoke execute on function public.rls_auto_enable() from public, anon, authenticated';
  end if;
end $$;

drop policy if exists "business locations write editors" on public.business_locations;

drop policy if exists "business locations insert editors" on public.business_locations;
create policy "business locations insert editors"
on public.business_locations for insert
to authenticated
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

drop policy if exists "business locations update editors" on public.business_locations;
create policy "business locations update editors"
on public.business_locations for update
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

drop policy if exists "business locations delete editors" on public.business_locations;
create policy "business locations delete editors"
on public.business_locations for delete
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
);

create index if not exists idx_app_files_device on public.app_files(device_id);
create index if not exists idx_app_files_process on public.app_files(process_run_id);
create index if not exists idx_route_logs_entity on public.route_logs(business_entity_id, created_at desc);
create index if not exists idx_feedback_messages_entity on public.feedback_messages(business_entity_id, created_at desc);
create index if not exists idx_carbon_profiles_entity on public.carbon_profiles(business_entity_id, created_at desc);
create index if not exists idx_commitments_entity on public.commitments(business_entity_id, created_at desc);
create index if not exists idx_product_clicks_entity on public.product_clicks(business_entity_id, created_at desc);

commit;
