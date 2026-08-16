create table if not exists public.social_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null default '',
  avatar_url text,
  updated_at timestamptz not null default now()
);

alter table public.social_profiles enable row level security;
insert into public.social_profiles (user_id, email, display_name, avatar_url, updated_at)
select
  id,
  coalesce(email, ''),
  coalesce(raw_user_meta_data->>'display_name', raw_user_meta_data->>'username', email, 'Traveler'),
  nullif(raw_user_meta_data->>'avatar_url', ''),
  now()
from auth.users
on conflict (user_id) do update set
  email = excluded.email,
  display_name = excluded.display_name,
  avatar_url = excluded.avatar_url,
  updated_at = now();

create or replace function public.sync_social_profile_from_auth()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.social_profiles (user_id, email, display_name, avatar_url, updated_at)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'username', new.email, 'Traveler'),
    nullif(new.raw_user_meta_data->>'avatar_url', ''),
    now()
  )
  on conflict (user_id) do update set
    email = excluded.email,
    display_name = excluded.display_name,
    avatar_url = excluded.avatar_url,
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists sync_social_profile_from_auth_trigger on auth.users;
create trigger sync_social_profile_from_auth_trigger
after insert or update of email, raw_user_meta_data on auth.users
for each row execute function public.sync_social_profile_from_auth();

create policy "Authenticated users can search social profiles"
  on public.social_profiles
  for select
  to authenticated
  using (true);

create policy "Users can insert their own social profile"
  on public.social_profiles
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their own social profile"
  on public.social_profiles
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  addressee_id uuid not null references auth.users(id) on delete cascade,
  user_low uuid not null references auth.users(id) on delete cascade,
  user_high uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint friendships_no_self check (requester_id <> addressee_id),
  constraint friendships_unique_pair unique (user_low, user_high)
);

alter table public.friendships enable row level security;

create policy "Users can read their own friendships"
  on public.friendships
  for select
  to authenticated
  using (auth.uid() in (requester_id, addressee_id));

create policy "Users can send friend requests"
  on public.friendships
  for insert
  to authenticated
  with check (auth.uid() = requester_id and requester_id <> addressee_id);

create policy "Users can update their own friendships"
  on public.friendships
  for update
  to authenticated
  using (auth.uid() in (requester_id, addressee_id))
  with check (auth.uid() in (requester_id, addressee_id));

create table if not exists public.friend_messages (
  id uuid primary key default gen_random_uuid(),
  friendship_id uuid not null references public.friendships(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

alter table public.friend_messages enable row level security;

create policy "Friends can read messages"
  on public.friend_messages
  for select
  to authenticated
  using (
    exists (
      select 1 from public.friendships f
      where f.id = friendship_id
        and f.status = 'accepted'
        and auth.uid() in (f.requester_id, f.addressee_id)
    )
  );

create policy "Friends can send messages"
  on public.friend_messages
  for insert
  to authenticated
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.friendships f
      where f.id = friendship_id
        and f.status = 'accepted'
        and auth.uid() in (f.requester_id, f.addressee_id)
    )
  );

create index if not exists social_profiles_email_idx on public.social_profiles (lower(email));
create index if not exists friendships_user_pair_idx on public.friendships (user_low, user_high);
create index if not exists friend_messages_friendship_created_idx on public.friend_messages (friendship_id, created_at desc);