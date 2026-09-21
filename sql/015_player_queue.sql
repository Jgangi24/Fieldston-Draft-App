-- Per-GM private queue (watchlist): star a player to keep an eye on them
-- during a draft, see the list in the Draft Room's Queue tab. This is the
-- first genuinely private table in the app — every policy scopes to
-- gm_id = auth.uid() with no commissioner override, since it's personal
-- draft prep, not administrative data the commissioner needs to see or fix.
create table public.player_queue (
  id uuid primary key default gen_random_uuid(),
  gm_id uuid not null references public.gms(id) on delete cascade,
  player_id uuid not null references public.players(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (gm_id, player_id)
);

alter table public.player_queue enable row level security;

create policy "A GM can view only their own queue"
  on public.player_queue for select
  to authenticated
  using (gm_id = auth.uid());

create policy "A GM can add only to their own queue"
  on public.player_queue for insert
  to authenticated
  with check (gm_id = auth.uid());

create policy "A GM can remove only from their own queue"
  on public.player_queue for delete
  to authenticated
  using (gm_id = auth.uid());

grant select, insert, delete on public.player_queue to authenticated;
