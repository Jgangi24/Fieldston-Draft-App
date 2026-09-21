-- Tracks when a nomination's current bid was last placed, so the bidding
-- countdown can reset every time someone bids (separate from the
-- nomination timer itself, which doesn't reset).
alter table public.nominations add column last_bid_at timestamptz not null default now();
