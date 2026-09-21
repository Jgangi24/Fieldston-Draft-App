-- Reworks the salary-cap (auction) format: instead of 8 team budgets and an
-- 8-team nomination rotation, each of the 4 GMs bids from one shared pot,
-- nominating/bidding in a 4-person rotation. Team assignment happens AFTER
-- a GM wins a player, as a separate step. Snake drafts are unaffected —
-- team_id stays how it's always worked there.
--
-- Pattern used in draft_order, nominations, and picks: the existing
-- team_id-based columns become nullable, and a parallel gm_id-based column
-- is added. For a snake draft, team_id is used (gm_id null). For a salary
-- cap draft, gm_id is used (team_id null until a pick gets assigned).

alter table public.draft_order add column gm_id uuid references public.gms(id);
alter table public.draft_order alter column team_id drop not null;
alter table public.draft_order add constraint draft_order_team_xor_gm check (
  (team_id is not null and gm_id is null) or (team_id is null and gm_id is not null)
);
alter table public.draft_order add constraint draft_order_gm_unique unique (draft_id, gm_id);

alter table public.nominations add column nominated_by_gm_id uuid references public.gms(id);
alter table public.nominations alter column nominated_by_team_id drop not null;
alter table public.nominations add column current_bid_gm_id uuid references public.gms(id);

alter table public.picks alter column team_id drop not null;
alter table public.picks add column gm_id uuid references public.gms(id);

-- Nominations INSERT: allow a GM-based nomination (salary cap) alongside
-- the existing team-based one (snake).
drop policy "Team owner or commissioner can nominate" on public.nominations;
create policy "Team owner, GM, or commissioner can nominate"
  on public.nominations for insert
  to authenticated
  with check (
    exists (select 1 from public.drafts d where d.id = draft_id and d.status = 'in_progress')
    and (
      public.is_commissioner()
      or (nominated_by_team_id is not null and exists (select 1 from public.teams t where t.id = nominated_by_team_id and t.gm_id = auth.uid()))
      or (nominated_by_gm_id is not null and nominated_by_gm_id = auth.uid())
    )
  );

-- Picks INSERT: allow recording a win by gm_id with no team yet (salary cap)
-- alongside the existing team-based insert (snake).
drop policy "Team owner or commissioner can record picks" on public.picks;
create policy "Team owner, GM, or commissioner can record picks"
  on public.picks for insert
  to authenticated
  with check (
    exists (select 1 from public.drafts d where d.id = draft_id and d.status = 'in_progress')
    and (
      public.is_commissioner()
      or (team_id is not null and exists (select 1 from public.teams t where t.id = team_id and t.gm_id = auth.uid()))
      or (team_id is null and gm_id is not null and gm_id = auth.uid())
    )
  );

-- Picks UPDATE: a GM can assign their own pending (team-less) win to one of
-- their own teams — a one-time self-service update, separate from the
-- commissioner's general edit/correct authority.
create policy "GM can assign their own pending pick to a team"
  on public.picks for update
  to authenticated
  using (gm_id = auth.uid() and team_id is null)
  with check (
    gm_id = auth.uid()
    and team_id is not null
    and exists (select 1 from public.teams t where t.id = team_id and t.gm_id = auth.uid())
  );
