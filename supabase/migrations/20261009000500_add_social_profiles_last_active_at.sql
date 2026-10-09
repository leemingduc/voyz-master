-- Add last_active_at to social_profiles for user presence and activity status
alter table public.social_profiles
  add column if not exists last_active_at timestamptz not null default now();

-- Update sync_social_profile_from_auth trigger to initialize last_active_at
create or replace function public.sync_social_profile_from_auth()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.social_profiles (user_id, email, display_name, avatar_url, updated_at, last_active_at)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'display_name', new.raw_user_meta_data->>'username', new.email, 'Traveler'),
    nullif(new.raw_user_meta_data->>'avatar_url', ''),
    now(),
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
