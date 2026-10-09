-- A clear operation is private to one participant, but must outlive a local
-- sign-out and be available when that account signs in on another device.
create table if not exists public.friend_conversation_clears (
  friendship_id uuid not null references public.friendships(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  cleared_at timestamptz not null default now(),
  primary key (friendship_id, user_id)
);

alter table public.friend_conversation_clears enable row level security;

create policy "Users can read their own friend conversation clears"
  on public.friend_conversation_clears
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert their own friend conversation clears"
  on public.friend_conversation_clears
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.friendships
      where id = friendship_id
        and auth.uid() in (requester_id, addressee_id)
    )
  );

create policy "Users can update their own friend conversation clears"
  on public.friend_conversation_clears
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.friendships
      where id = friendship_id
        and auth.uid() in (requester_id, addressee_id)
    )
  );
