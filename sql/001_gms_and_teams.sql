-- GMs: one row per person, linked directly to their Supabase Auth account.
create table public.gms (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  is_commissioner boolean not null default false,
  created_at timestamptz not null default now()
);

-- Teams: the 8 fantasy teams, each owned by one GM.
create table public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  gm_id uuid not null references public.gms(id),
  created_at timestamptz not null default now()
);

alter table public.gms enable row level security;
alter table public.teams enable row level security;

-- Any signed-in GM can view all GMs and teams.
create policy "GMs are viewable by authenticated users"
  on public.gms for select
  to authenticated
  using (true);

create policy "Teams are viewable by authenticated users"
  on public.teams for select
  to authenticated
  using (true);

-- Only the commissioner can add/edit/remove GMs or teams.
create policy "Only commissioner can modify GMs"
  on public.gms for all
  to authenticated
  using (exists (select 1 from public.gms g where g.id = auth.uid() and g.is_commissioner))
  with check (exists (select 1 from public.gms g where g.id = auth.uid() and g.is_commissioner));

create policy "Only commissioner can modify teams"
  on public.teams for all
  to authenticated
  using (exists (select 1 from public.gms g where g.id = auth.uid() and g.is_commissioner))
  with check (exists (select 1 from public.gms g where g.id = auth.uid() and g.is_commissioner));

-- Seed the 4 GMs, matched by email (not by guessing auth UIDs).
insert into public.gms (id, name, is_commissioner)
select id, 'Jess', true from auth.users where email = 'jessgangi@gmail.com'
union all
select id, 'Mike', false from auth.users where email = 'mweston08@gmail.com'
union all
select id, 'Paul', false from auth.users where email = 'paulbcharney@gmail.com'
union all
select id, 'Lew', false from auth.users where email = 'lkrauskopf@yahoo.com';

-- Seed the 8 teams, matched to their GM by name.
insert into public.teams (name, gm_id)
select 'Blankendorf Monstrosities', id from public.gms where name = 'Jess'
union all
select 'Flamington Tuxedos', id from public.gms where name = 'Jess'
union all
select 'Oakland Paint Patrol', id from public.gms where name = 'Paul'
union all
select 'San Francisco 3 Deep', id from public.gms where name = 'Paul'
union all
select 'Jackson Heights Lew Crew', id from public.gms where name = 'Lew'
union all
select 'Queens Lew Crew 2, Electric Boogaloo', id from public.gms where name = 'Lew'
union all
select 'Laurel Canyon Naughty Chauffeurs', id from public.gms where name = 'Mike'
union all
select 'Los Angeles Magic Wiltworthy Kobronabitches', id from public.gms where name = 'Mike';
