-- Grants baseline table access to signed-in users. RLS policies (from
-- 001/002) still control what they can actually see or change — this just
-- opens the outer gate that Postgres checks before RLS is even consulted.
grant select, insert, update, delete on public.gms to authenticated;
grant select, insert, update, delete on public.teams to authenticated;
