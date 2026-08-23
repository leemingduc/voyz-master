-- Create ai_generated_cache table for multi-tier shared AI cache
create table if not exists public.ai_generated_cache (
    id uuid primary key default gen_random_uuid(),
    cache_key text not null unique,
    feature_type text not null,
    destination text,
    language_code text not null default 'vi',
    payload jsonb not null,
    image_urls jsonb,
    hit_count integer not null default 1,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Indexes for ultra-fast lookup
create index if not exists idx_ai_generated_cache_key on public.ai_generated_cache (cache_key);
create index if not exists idx_ai_generated_cache_feature_dest on public.ai_generated_cache (feature_type, destination);
create index if not exists idx_ai_generated_cache_updated_at on public.ai_generated_cache (updated_at desc);

-- Enable Row Level Security
alter table public.ai_generated_cache enable row level security;

-- Policy: Allow anyone (anon + authenticated) to read cache
drop policy if exists "Allow public read ai_generated_cache" on public.ai_generated_cache;
create policy "Allow public read ai_generated_cache"
    on public.ai_generated_cache
    for select
    to anon, authenticated
    using (true);

-- Policy: Allow anyone (anon + authenticated) to insert cache entries
drop policy if exists "Allow public insert ai_generated_cache" on public.ai_generated_cache;
create policy "Allow public insert ai_generated_cache"
    on public.ai_generated_cache
    for insert
    to anon, authenticated
    with check (true);

-- Policy: Allow anyone (anon + authenticated) to update cache entries (for hit count and payload refreshes)
drop policy if exists "Allow public update ai_generated_cache" on public.ai_generated_cache;
create policy "Allow public update ai_generated_cache"
    on public.ai_generated_cache
    for update
    to anon, authenticated
    using (true)
    with check (true);
