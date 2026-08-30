-- Sprint 2/3 cloud data model: AI chat, collaborative trip workspaces,
-- curated destinations/media, community reviews, and extended profiles.

create extension if not exists pgcrypto;

-- Extended user profile/preferences.
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null default '',
  display_name text not null default '',
  avatar_url text,
  phone_number text not null default '',
  travel_styles text[] not null default '{}',
  preferred_currency text not null default 'VND',
  home_airport text not null default '',
  dietary_preferences text[] not null default '{}',
  accessibility_needs text[] not null default '{}',
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users can read their own profile" on public.profiles;
create policy "Users can read their own profile"
  on public.profiles for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Users can insert their own profile"
  on public.profiles for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

insert into public.profiles (user_id, email, display_name, avatar_url, phone_number, updated_at)
select
  id,
  coalesce(email, ''),
  coalesce(raw_user_meta_data->>'display_name', raw_user_meta_data->>'username', email, 'Traveler'),
  nullif(raw_user_meta_data->>'avatar_url', ''),
  coalesce(raw_user_meta_data->>'phone_number', ''),
  now()
from auth.users
on conflict (user_id) do update set
  email = excluded.email,
  display_name = excluded.display_name,
  avatar_url = coalesce(public.profiles.avatar_url, excluded.avatar_url),
  phone_number = coalesce(nullif(public.profiles.phone_number, ''), excluded.phone_number),
  updated_at = now();

create or replace function public.sync_profile_from_auth()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, email, display_name, avatar_url, phone_number, updated_at)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'username', new.email, 'Traveler'),
    nullif(new.raw_user_meta_data->>'avatar_url', ''),
    coalesce(new.raw_user_meta_data->>'phone_number', ''),
    now()
  )
  on conflict (user_id) do update set
    email = excluded.email,
    display_name = excluded.display_name,
    avatar_url = excluded.avatar_url,
    phone_number = coalesce(nullif(public.profiles.phone_number, ''), excluded.phone_number),
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists sync_profile_from_auth_trigger on auth.users;
create trigger sync_profile_from_auth_trigger
after insert or update of email, raw_user_meta_data on auth.users
for each row execute function public.sync_profile_from_auth();

-- AI chat threads/messages for multi-device sync.
create table if not exists public.chat_threads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'Travel chat',
  destination_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chat_threads_user_destination_unique unique (user_id, destination_name)
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.chat_threads(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  message_index integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.chat_threads enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "Users can manage their own chat threads" on public.chat_threads;
create policy "Users can manage their own chat threads"
  on public.chat_threads for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can manage their own chat messages" on public.chat_messages;
create policy "Users can manage their own chat messages"
  on public.chat_messages for all to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.chat_threads t
      where t.id = thread_id and t.user_id = auth.uid()
    )
  );

create index if not exists chat_messages_thread_order_idx
  on public.chat_messages (thread_id, message_index, created_at);

-- Collaborative trip workspace members.
create table if not exists public.trip_collaborators (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.saved_trips(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  collaborator_id uuid references auth.users(id) on delete cascade,
  collaborator_email text not null default '',
  role text not null default 'editor' check (role in ('viewer', 'editor')),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trip_collaborators_unique_user unique (trip_id, collaborator_id),
  constraint trip_collaborators_unique_email unique (trip_id, collaborator_email)
);

alter table public.trip_collaborators enable row level security;

drop policy if exists "Trip members can view collaborators" on public.trip_collaborators;
create policy "Trip members can view collaborators"
  on public.trip_collaborators for select to authenticated
  using (
    auth.uid() = owner_id
    or auth.uid() = collaborator_id
    or lower(collaborator_email) = lower(coalesce(auth.jwt()->>'email', ''))
  );

drop policy if exists "Trip owners can add collaborators" on public.trip_collaborators;
create policy "Trip owners can add collaborators"
  on public.trip_collaborators for insert to authenticated
  with check (
    auth.uid() = owner_id
    and exists (
      select 1 from public.saved_trips s
      where s.id = trip_id and s.user_id = auth.uid()
    )
  );

drop policy if exists "Trip owners and invited users can update collaborators" on public.trip_collaborators;
create policy "Trip owners and invited users can update collaborators"
  on public.trip_collaborators for update to authenticated
  using (
    auth.uid() = owner_id
    or auth.uid() = collaborator_id
    or lower(collaborator_email) = lower(coalesce(auth.jwt()->>'email', ''))
  )
  with check (
    auth.uid() = owner_id
    or auth.uid() = collaborator_id
    or lower(collaborator_email) = lower(coalesce(auth.jwt()->>'email', ''))
  );

drop policy if exists "Trip owners can remove collaborators" on public.trip_collaborators;
create policy "Trip owners can remove collaborators"
  on public.trip_collaborators for delete to authenticated
  using (auth.uid() = owner_id);

-- Expand saved trip access to accepted collaborators.
drop policy if exists "Users can view their own saved trips" on public.saved_trips;
drop policy if exists "Users can view own or collaborative saved trips" on public.saved_trips;
create policy "Users can view own or collaborative saved trips"
  on public.saved_trips for select to authenticated
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.trip_collaborators c
      where c.trip_id = saved_trips.id
        and c.status <> 'removed'
        and (
          c.collaborator_id = auth.uid()
          or lower(c.collaborator_email) = lower(coalesce(auth.jwt()->>'email', ''))
        )
    )
  );
drop policy if exists "Users can update their own saved trips" on public.saved_trips;
drop policy if exists "Owners and editors can update saved trips" on public.saved_trips;
create policy "Owners and editors can update saved trips"
  on public.saved_trips for update to authenticated
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.trip_collaborators c
      where c.trip_id = saved_trips.id
        and c.status <> 'removed'
        and c.role = 'editor'
        and (
          c.collaborator_id = auth.uid()
          or lower(c.collaborator_email) = lower(coalesce(auth.jwt()->>'email', ''))
        )
    )
  )
  with check (
    auth.uid() = user_id
    or exists (
      select 1 from public.trip_collaborators c
      where c.trip_id = saved_trips.id
        and c.status <> 'removed'
        and c.role = 'editor'
        and (
          c.collaborator_id = auth.uid()
          or lower(c.collaborator_email) = lower(coalesce(auth.jwt()->>'email', ''))
        )
    )
  );
create index if not exists trip_collaborators_trip_idx
  on public.trip_collaborators (trip_id, status);
create index if not exists trip_collaborators_user_idx
  on public.trip_collaborators (collaborator_id, status);
create index if not exists trip_collaborators_email_idx
  on public.trip_collaborators (lower(collaborator_email), status);

-- Curated destinations and featured slots for Explore.
create table if not exists public.destinations (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  country text not null default '',
  location text not null default '',
  category text not null default 'random',
  tags text[] not null default '{}',
  image_url text not null default '',
  price text not null default '',
  ai_insight text not null default '',
  match_percent integer not null default 80,
  rating numeric(3, 2) not null default 0,
  review_count integer not null default 0,
  detail_data jsonb not null default '{}'::jsonb,
  gallery jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.featured_destinations (
  id uuid primary key default gen_random_uuid(),
  destination_id uuid not null references public.destinations(id) on delete cascade,
  category_key text not null default 'random',
  rank integer not null default 0,
  is_active boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  constraint featured_destinations_unique_slot unique (destination_id, category_key)
);

alter table public.destinations enable row level security;
alter table public.featured_destinations enable row level security;

drop policy if exists "Anyone can read active destinations" on public.destinations;
create policy "Anyone can read active destinations"
  on public.destinations for select
  using (is_active);

drop policy if exists "Anyone can read active featured destinations" on public.featured_destinations;
create policy "Anyone can read active featured destinations"
  on public.featured_destinations for select
  using (
    is_active
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at >= now())
  );

create index if not exists destinations_active_category_idx
  on public.destinations (is_active, category, match_percent desc);
create index if not exists featured_destinations_category_rank_idx
  on public.featured_destinations (category_key, rank);

-- Destination community reviews with aggregate rating trigger.
create table if not exists public.community_reviews (
  id uuid primary key default gen_random_uuid(),
  destination_id uuid not null references public.destinations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint community_reviews_unique_user_destination unique (destination_id, user_id)
);

alter table public.community_reviews enable row level security;

drop policy if exists "Anyone can read community reviews" on public.community_reviews;
create policy "Anyone can read community reviews"
  on public.community_reviews for select
  using (true);

drop policy if exists "Users can insert their own reviews" on public.community_reviews;
create policy "Users can insert their own reviews"
  on public.community_reviews for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own reviews" on public.community_reviews;
create policy "Users can update their own reviews"
  on public.community_reviews for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own reviews" on public.community_reviews;
create policy "Users can delete their own reviews"
  on public.community_reviews for delete to authenticated
  using (auth.uid() = user_id);

create or replace function public.refresh_destination_review_stats(target_destination_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.destinations d
  set
    rating = coalesce((
      select round(avg(r.rating)::numeric, 2)
      from public.community_reviews r
      where r.destination_id = target_destination_id
    ), 0),
    review_count = (
      select count(*)::integer
      from public.community_reviews r
      where r.destination_id = target_destination_id
    ),
    updated_at = now()
  where d.id = target_destination_id;
end;
$$;

create or replace function public.refresh_destination_review_stats_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.refresh_destination_review_stats(coalesce(new.destination_id, old.destination_id));
  return coalesce(new, old);
end;
$$;

drop trigger if exists community_reviews_refresh_stats_trigger on public.community_reviews;
create trigger community_reviews_refresh_stats_trigger
after insert or update or delete on public.community_reviews
for each row execute function public.refresh_destination_review_stats_trigger();

create index if not exists community_reviews_destination_created_idx
  on public.community_reviews (destination_id, created_at desc);

-- Destination media CDN bucket.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'destination-media',
  'destination-media',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can read destination media" on storage.objects;
create policy "Public can read destination media"
  on storage.objects for select
  using (bucket_id = 'destination-media');

drop policy if exists "Authenticated users can upload destination media" on storage.objects;
create policy "Authenticated users can upload destination media"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'destination-media');

-- Seed a starter curated Explore set so DB mode works immediately.
insert into public.destinations
  (slug, name, country, location, category, tags, image_url, price, ai_insight, match_percent, rating, review_count, detail_data, gallery)
values
  (
    'da-nang-vietnam',
    'Da Nang, Vietnam',
    'Vietnam',
    'Central Coast, Vietnam',
    'city',
    array['Beach', 'City', 'Food', 'Bridges'],
    'https://commons.wikimedia.org/wiki/Special:FilePath/Da_Nang_-_Dragon_Bridge.jpg?width=1280',
    '~5M VND',
    'A compact coastal city with beaches, night markets, and quick access to Hoi An and Ba Na Hills.',
    98,
    4.8,
    1280,
    '{"weather":"Sunny, 26-32C","dateRange":"Flexible","totalBudget":"~5M VND","budgetBreakdown":[{"label":"Transport","amount":"1.5M VND","fraction":0.3,"icon":"flight"},{"label":"Stay","amount":"1.6M VND","fraction":0.32,"icon":"hotel"},{"label":"Food","amount":"1.1M VND","fraction":0.22,"icon":"restaurant"},{"label":"Activities","amount":"0.8M VND","fraction":0.16,"icon":"kayaking"}]}'::jsonb,
    '[{"title":"Dragon Bridge","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/Da_Nang_-_Dragon_Bridge.jpg?width=1280"},{"title":"Golden Bridge","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/Aerial_view_of_the_Golden_Bridge%2C_Ba_Na_Hills%2C_Da_Nang%2C_Vietnam.jpg?width=1280"}]'::jsonb
  ),
  (
    'hoi-an-vietnam',
    'Hoi An, Vietnam',
    'Vietnam',
    'Quang Nam, Vietnam',
    'heritage',
    array['Heritage', 'Lanterns', 'Food', 'Old Town'],
    'https://commons.wikimedia.org/wiki/Special:FilePath/H%E1%BB%99i_An%2C_Ancient_Town%2C_2020-01_CN-06.jpg?width=1280',
    '~4M VND',
    'Lantern-lit streets, riverside cafes, tailor shops, and slow evenings make this a high-value cultural escape.',
    96,
    4.7,
    2140,
    '{"weather":"Warm, 25-31C","dateRange":"Flexible","totalBudget":"~4M VND","budgetBreakdown":[{"label":"Transport","amount":"1.1M VND","fraction":0.28,"icon":"flight"},{"label":"Stay","amount":"1.3M VND","fraction":0.32,"icon":"hotel"},{"label":"Food","amount":"1M VND","fraction":0.25,"icon":"restaurant"},{"label":"Activities","amount":"0.6M VND","fraction":0.15,"icon":"kayaking"}]}'::jsonb,
    '[{"title":"Hoi An Ancient Town","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/H%E1%BB%99i_An%2C_Ancient_Town%2C_2020-01_CN-06.jpg?width=1280"}]'::jsonb
  ),
  (
    'ha-giang-vietnam',
    'Ha Giang, Vietnam',
    'Vietnam',
    'Northern Highlands, Vietnam',
    'mountain',
    array['Mountains', 'Road Trip', 'Views', 'Culture'],
    'https://commons.wikimedia.org/wiki/Special:FilePath/M%C3%A3_P%C3%AD_L%C3%A8ng_Pass%2C_Vietnam.jpg?width=1280',
    '~4.5M VND',
    'One of Vietnam''s most dramatic road trips, with limestone passes and small villages spread across high valleys.',
    95,
    4.9,
    860,
    '{"weather":"Cool, 16-26C","dateRange":"Flexible","totalBudget":"~4.5M VND","budgetBreakdown":[{"label":"Transport","amount":"1.7M VND","fraction":0.38,"icon":"flight"},{"label":"Stay","amount":"1M VND","fraction":0.22,"icon":"hotel"},{"label":"Food","amount":"0.9M VND","fraction":0.2,"icon":"restaurant"},{"label":"Activities","amount":"0.9M VND","fraction":0.2,"icon":"kayaking"}]}'::jsonb,
    '[{"title":"Ma Pi Leng Pass","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/M%C3%A3_P%C3%AD_L%C3%A8ng_Pass%2C_Vietnam.jpg?width=1280"}]'::jsonb
  ),
  (
    'phu-quoc-vietnam',
    'Phu Quoc, Vietnam',
    'Vietnam',
    'Kien Giang, Vietnam',
    'beach',
    array['Beach', 'Island', 'Seafood', 'Resort'],
    'https://commons.wikimedia.org/wiki/Special:FilePath/Phu_Quoc_Beach.jpg?width=1280',
    '~6M VND',
    'A flexible island trip with easy flights, resort choices, sunset beaches, and seafood-heavy nights.',
    94,
    4.6,
    1750,
    '{"weather":"Tropical, 27-32C","dateRange":"Flexible","totalBudget":"~6M VND","budgetBreakdown":[{"label":"Transport","amount":"1.8M VND","fraction":0.3,"icon":"flight"},{"label":"Stay","amount":"2.2M VND","fraction":0.37,"icon":"hotel"},{"label":"Food","amount":"1.2M VND","fraction":0.2,"icon":"restaurant"},{"label":"Activities","amount":"0.8M VND","fraction":0.13,"icon":"kayaking"}]}'::jsonb,
    '[{"title":"Phu Quoc Beach","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/Phu_Quoc_Beach.jpg?width=1280"}]'::jsonb
  )
on conflict (slug) do update set
  name = excluded.name,
  country = excluded.country,
  location = excluded.location,
  category = excluded.category,
  tags = excluded.tags,
  image_url = excluded.image_url,
  price = excluded.price,
  ai_insight = excluded.ai_insight,
  match_percent = excluded.match_percent,
  detail_data = excluded.detail_data,
  gallery = excluded.gallery,
  updated_at = now();

insert into public.featured_destinations (destination_id, category_key, rank)
select id, 'random', row_number() over (order by match_percent desc)
from public.destinations
where slug in ('da-nang-vietnam', 'hoi-an-vietnam', 'ha-giang-vietnam', 'phu-quoc-vietnam')
on conflict (destination_id, category_key) do update set rank = excluded.rank, is_active = true;

insert into public.featured_destinations (destination_id, category_key, rank)
select id, category, 1
from public.destinations
where slug in ('da-nang-vietnam', 'hoi-an-vietnam', 'ha-giang-vietnam', 'phu-quoc-vietnam')
on conflict (destination_id, category_key) do update set rank = excluded.rank, is_active = true;

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin alter publication supabase_realtime add table public.chat_messages; exception when others then null; end;
    begin alter publication supabase_realtime add table public.saved_trips; exception when others then null; end;
    begin alter publication supabase_realtime add table public.trip_collaborators; exception when others then null; end;
    begin alter publication supabase_realtime add table public.community_reviews; exception when others then null; end;
  end if;
end $$;
