-- Drafts: one row per draft session (a new one each season). Team order is
-- NOT stored here since it varies per draft/season — that'll be its own
-- table (draft_order) that references this one, built as a later step.
create table public.drafts (
  id uuid primary key default gen_random_uuid(),
  label text,
  format text not null check (format in ('snake', 'auction')),
  status text not null default 'setup'
    check (status in ('setup', 'in_progress', 'paused', 'completed', 'cancelled')),
  rounds integer,
  starting_budget numeric,
  created_by uuid references public.gms(id),
  created_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  -- Keep format-specific fields from being set on the wrong format by mistake.
  check (format <> 'snake' or starting_budget is null),
  check (format <> 'auction' or rounds is null)
);

alter table public.drafts enable row level security;

create policy "Drafts are viewable by authenticated users"
  on public.drafts for select
  to authenticated
  using (true);

create policy "Only commissioner can modify drafts"
  on public.drafts for all
  to authenticated
  using (public.is_commissioner())
  with check (public.is_commissioner());

grant select, insert, update, delete on public.drafts to authenticated;
