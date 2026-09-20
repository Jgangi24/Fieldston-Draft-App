-- Fixes infinite recursion: the previous write policies checked commissioner
-- status by querying public.gms, which re-triggered the same policy on itself.
-- This helper function runs with elevated privileges (security definer),
-- bypassing RLS for just this internal check.
create or replace function public.is_commissioner()
returns boolean
language sql
security definer
set search_path = public, pg_temp
stable
as $$
  select coalesce((select is_commissioner from public.gms where id = auth.uid()), false);
$$;

drop policy "Only commissioner can modify GMs" on public.gms;
drop policy "Only commissioner can modify teams" on public.teams;

create policy "Only commissioner can modify GMs"
  on public.gms for all
  to authenticated
  using (public.is_commissioner())
  with check (public.is_commissioner());

create policy "Only commissioner can modify teams"
  on public.teams for all
  to authenticated
  using (public.is_commissioner())
  with check (public.is_commissioner());
