-- TAINT user-owned log RLS follow-up.
-- Applied to dev project pywjwsrjzgkvgplkxdry and prod project oavkdvuvlupawxhjtowh on 2026-06-03.
-- Guest calculations remain local in the browser. Supabase calculation, route,
-- profile, product, and process rows require the authenticated owner.

begin;

create index if not exists idx_route_logs_user
on public.route_logs(auth_user_id, created_at desc);

create index if not exists idx_process_runs_user
on public.process_runs(auth_user_id, started_at desc);

revoke all on public.calculation_logs, public.route_logs, public.carbon_profiles,
  public.commitments, public.product_clicks, public.product_purchases,
  public.process_runs from anon;

drop policy if exists "insert calculation logs" on public.calculation_logs;
create policy "insert calculation logs"
on public.calculation_logs for insert
to authenticated
with check (auth_user_id = (select auth.uid()));

drop policy if exists "read own calculation logs" on public.calculation_logs;
create policy "read own calculation logs"
on public.calculation_logs for select
to authenticated
using (auth_user_id = (select auth.uid()));

drop policy if exists "insert route logs" on public.route_logs;
create policy "insert route logs"
on public.route_logs for insert
to authenticated
with check (auth_user_id = (select auth.uid()));

drop policy if exists "read own route logs" on public.route_logs;
create policy "read own route logs"
on public.route_logs for select
to authenticated
using (auth_user_id = (select auth.uid()));

drop policy if exists "insert carbon profiles" on public.carbon_profiles;
create policy "insert carbon profiles"
on public.carbon_profiles for insert
to authenticated
with check (auth_user_id = (select auth.uid()));

drop policy if exists "read own carbon profiles" on public.carbon_profiles;
create policy "read own carbon profiles"
on public.carbon_profiles for select
to authenticated
using (auth_user_id = (select auth.uid()));

drop policy if exists "insert commitments" on public.commitments;
create policy "insert commitments"
on public.commitments for insert
to authenticated
with check (auth_user_id = (select auth.uid()));

drop policy if exists "read own commitments" on public.commitments;
create policy "read own commitments"
on public.commitments for select
to authenticated
using (auth_user_id = (select auth.uid()));

drop policy if exists "insert product clicks" on public.product_clicks;
create policy "insert product clicks"
on public.product_clicks for insert
to authenticated
with check (auth_user_id = (select auth.uid()));

drop policy if exists "read own product clicks" on public.product_clicks;
create policy "read own product clicks"
on public.product_clicks for select
to authenticated
using (auth_user_id = (select auth.uid()));

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

drop policy if exists "insert process runs" on public.process_runs;
create policy "insert process runs"
on public.process_runs for insert
to authenticated
with check (auth_user_id = (select auth.uid()));

drop policy if exists "read own process runs" on public.process_runs;
create policy "read own process runs"
on public.process_runs for select
to authenticated
using (auth_user_id = (select auth.uid()));

grant insert on public.calculation_logs, public.route_logs, public.carbon_profiles,
  public.commitments, public.product_clicks, public.product_purchases,
  public.process_runs to authenticated;

grant select on public.calculation_logs, public.route_logs, public.carbon_profiles,
  public.commitments, public.product_clicks, public.product_purchases,
  public.process_runs to authenticated;

commit;
