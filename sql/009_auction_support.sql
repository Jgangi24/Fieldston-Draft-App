-- Auction drafts need a target roster size too (to know when the draft is
-- done), same as snake's "rounds" — loosen the constraint that forced it
-- to be empty for auction. Looked up by definition rather than a guessed
-- name, since it was created unnamed and Postgres auto-names those.
do $$
declare
  found_constraint text;
begin
  select conname into found_constraint
  from pg_constraint
  where conrelid = 'public.drafts'::regclass
    and pg_get_constraintdef(oid) ilike '%rounds IS NULL%';

  if found_constraint is not null then
    execute format('alter table public.drafts drop constraint %I', found_constraint);
  end if;
end $$;

-- Track what a pick cost, for auction drafts (null for snake).
alter table public.picks add column amount_paid numeric;

-- Nominations: the live state of "what's up for bid right now" in an
-- auction draft. One row per player nominated; current_bid/current_bid_team_id
-- update as bidding happens, then it gets finalized (closed) into a picks
-- row once sold.
create table public.nominations (
  id uuid primary key default gen_random_uuid(),
  draft_id uuid not null references public.drafts(id) on delete cascade,
  nomination_number integer not null check (nomination_number > 0),
  player_id uuid not null references public.players(id),
  nominated_by_team_id uuid not null references public.teams(id),
  current_bid numeric not null default 1,
  current_bid_team_id uuid references public.teams(id),
  status text not null default 'open' check (status in ('open', 'sold')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  unique (draft_id, nomination_number),
  unique (draft_id, player_id)
);

alter table public.nominations enable row level security;

create policy "Nominations are viewable by authenticated users"
  on public.nominations for select
  to authenticated
  using (true);

-- A GM can nominate on behalf of a team they own, while the draft is live.
create policy "Team owner or commissioner can nominate"
  on public.nominations for insert
  to authenticated
  with check (
    exists (select 1 from public.drafts d where d.id = draft_id and d.status = 'in_progress')
    and (
      public.is_commissioner()
      or exists (select 1 from public.teams t where t.id = nominated_by_team_id and t.gm_id = auth.uid())
    )
  );

-- Any signed-in GM can update an open nomination (to place a bid); the
-- commissioner also updates it to close/sell. Bid validity (higher than
-- current, within budget) is checked in the app, not here.
create policy "Authenticated users can bid on open nominations"
  on public.nominations for update
  to authenticated
  using (true)
  with check (true);

grant select, insert, update on public.nominations to authenticated;

alter publication supabase_realtime add table public.nominations;
