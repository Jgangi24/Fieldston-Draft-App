-- Picks: one row per player drafted in a given draft. Whose turn it is for
-- a given pick_number is NOT stored — it's computed from draft_order plus
-- snake round-reversal math at query time, same reasoning as draft_order.
create table public.picks (
  id uuid primary key default gen_random_uuid(),
  draft_id uuid not null references public.drafts(id) on delete cascade,
  pick_number integer not null check (pick_number > 0),
  round integer not null check (round > 0),
  team_id uuid not null references public.teams(id),
  player_id uuid not null references public.players(id),
  picked_at timestamptz not null default now(),
  unique (draft_id, pick_number),
  unique (draft_id, player_id)
);

alter table public.picks enable row level security;

create policy "Picks are viewable by authenticated users"
  on public.picks for select
  to authenticated
  using (true);

-- A GM can only record a pick for a team they own, and only while the draft
-- is actually in progress. The commissioner can record picks for any team
-- (e.g. covering for an absent GM during a live draft).
create policy "Team owner or commissioner can record picks"
  on public.picks for insert
  to authenticated
  with check (
    exists (select 1 from public.drafts d where d.id = draft_id and d.status = 'in_progress')
    and (
      public.is_commissioner()
      or exists (select 1 from public.teams t where t.id = team_id and t.gm_id = auth.uid())
    )
  );

create policy "Only commissioner can edit picks"
  on public.picks for update
  to authenticated
  using (public.is_commissioner())
  with check (public.is_commissioner());

create policy "Only commissioner can delete picks"
  on public.picks for delete
  to authenticated
  using (public.is_commissioner());

grant select, insert, update, delete on public.picks to authenticated;

-- Enable realtime so all 4 GMs see picks appear live, without refreshing.
alter publication supabase_realtime add table public.picks;
