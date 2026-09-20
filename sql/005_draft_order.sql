-- Draft order: the pick order for one specific draft. Custom per draft/season
-- (not a fixed league-wide order). For snake drafts, round reversal (round 2
-- goes 8->1, etc.) is computed from pick_position at query time, not stored.
-- For auction drafts, this same order doubles as the nomination rotation.
create table public.draft_order (
  id uuid primary key default gen_random_uuid(),
  draft_id uuid not null references public.drafts(id) on delete cascade,
  team_id uuid not null references public.teams(id),
  pick_position integer not null check (pick_position > 0),
  unique (draft_id, team_id),
  unique (draft_id, pick_position)
);

alter table public.draft_order enable row level security;

create policy "Draft order is viewable by authenticated users"
  on public.draft_order for select
  to authenticated
  using (true);

create policy "Only commissioner can modify draft order"
  on public.draft_order for all
  to authenticated
  using (public.is_commissioner())
  with check (public.is_commissioner());

grant select, insert, update, delete on public.draft_order to authenticated;
