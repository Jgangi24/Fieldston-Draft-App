-- Per-draft pick timer length, in seconds. Set at draft creation, editable
-- by the commissioner mid-draft. The timer is purely a visual "you're
-- overdue" indicator (per the user's choice) — nothing is auto-skipped or
-- auto-picked when it runs out.
alter table public.drafts add column pick_time_seconds integer not null default 90;
