-- Players: a minimal, manually-entered pool for now (name + optional
-- position). This will be extended with BBGM fields (ovr, pot, contract)
-- once real league exports are imported, matched by name to whatever's
-- already been drafted rather than trusting any BBGM id.
create table public.players (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  position text,
  created_at timestamptz not null default now()
);

alter table public.players enable row level security;

create policy "Players are viewable by authenticated users"
  on public.players for select
  to authenticated
  using (true);

create policy "Only commissioner can modify players"
  on public.players for all
  to authenticated
  using (public.is_commissioner())
  with check (public.is_commissioner());

grant select, insert, update, delete on public.players to authenticated;
