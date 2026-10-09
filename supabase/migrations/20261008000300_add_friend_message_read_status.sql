-- Keep friend-message unread state across sessions and devices.
alter table public.friend_messages
  add column if not exists delivered_at timestamptz,
  add column if not exists read_at timestamptz;

create index if not exists friend_messages_unread_idx
  on public.friend_messages (friendship_id, sender_id, created_at desc)
  where read_at is null;

-- The recipient can mark messages as delivered or read without gaining
-- permission to alter their contents.
create or replace function public.mark_friend_messages_delivered(p_friendship_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.friendships f
    where f.id = p_friendship_id
      and f.status = 'accepted'
      and auth.uid() in (f.requester_id, f.addressee_id)
  ) then
    raise exception 'Friendship not found or unavailable';
  end if;

  update public.friend_messages
  set delivered_at = now()
  where friendship_id = p_friendship_id
    and sender_id <> auth.uid()
    and delivered_at is null;
end;
$$;

create or replace function public.mark_friend_messages_read(p_friendship_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.friendships f
    where f.id = p_friendship_id
      and f.status = 'accepted'
      and auth.uid() in (f.requester_id, f.addressee_id)
  ) then
    raise exception 'Friendship not found or unavailable';
  end if;

  update public.friend_messages
  set delivered_at = coalesce(delivered_at, now()),
      read_at = now()
  where friendship_id = p_friendship_id
    and sender_id <> auth.uid()
    and read_at is null;
end;
$$;

revoke all on function public.mark_friend_messages_delivered(uuid) from public;
revoke all on function public.mark_friend_messages_read(uuid) from public;
grant execute on function public.mark_friend_messages_delivered(uuid) to authenticated;
grant execute on function public.mark_friend_messages_read(uuid) to authenticated;
