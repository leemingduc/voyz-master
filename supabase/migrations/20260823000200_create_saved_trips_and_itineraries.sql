-- Migration: Create saved_trips and saved_itineraries tables for cloud synchronization.

-- 1. Table for Saved Trips & Wishlist Items
create table if not exists public.saved_trips (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  image_url text not null default '',
  price text not null default '',
  match_percent integer not null default 0,
  rating numeric(3, 2) not null default 0.0,
  review_count integer not null default 0,
  ai_insight text not null default '',
  is_wishlist boolean not null default false,
  trip_data jsonb,
  checklist jsonb not null default '[]'::jsonb,
  workspace_notes text not null default '',
  booking_refs text[] not null default '{}',
  shared_with text[] not null default '{}',
  saved_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint saved_trips_user_name_unique unique (user_id, name)
);

-- Enable RLS on saved_trips
alter table public.saved_trips enable row level security;

drop policy if exists "Users can view their own saved trips" on public.saved_trips;
create policy "Users can view their own saved trips"
  on public.saved_trips
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own saved trips" on public.saved_trips;
create policy "Users can insert their own saved trips"
  on public.saved_trips
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own saved trips" on public.saved_trips;
create policy "Users can update their own saved trips"
  on public.saved_trips
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own saved trips" on public.saved_trips;
create policy "Users can delete their own saved trips"
  on public.saved_trips
  for delete
  to authenticated
  using (auth.uid() = user_id);

create index if not exists saved_trips_user_saved_at_idx
  on public.saved_trips (user_id, saved_at desc);

-- 2. Table for Saved Itineraries (Day-by-day plan)
create table if not exists public.saved_itineraries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  destination_name text not null,
  plan_data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint saved_itineraries_user_dest_unique unique (user_id, destination_name)
);

-- Enable RLS on saved_itineraries
alter table public.saved_itineraries enable row level security;

drop policy if exists "Users can view their own saved itineraries" on public.saved_itineraries;
create policy "Users can view their own saved itineraries"
  on public.saved_itineraries
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own saved itineraries" on public.saved_itineraries;
create policy "Users can insert their own saved itineraries"
  on public.saved_itineraries
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own saved itineraries" on public.saved_itineraries;
create policy "Users can update their own saved itineraries"
  on public.saved_itineraries
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own saved itineraries" on public.saved_itineraries;
create policy "Users can delete their own saved itineraries"
  on public.saved_itineraries
  for delete
  to authenticated
  using (auth.uid() = user_id);

create index if not exists saved_itineraries_user_dest_idx
  on public.saved_itineraries (user_id, destination_name);

-- 3. Enable Realtime replication safely
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.saved_trips;
    exception when others then null;
    end;
    begin
      if exists (select 1 from pg_tables where schemaname = 'public' and tablename = 'friend_messages') then
        alter publication supabase_realtime add table public.friend_messages;
      end if;
    exception when others then null;
    end;
  end if;
end $$;
