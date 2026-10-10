-- A recall remains in the conversation as a neutral event so both
-- participants see that a message was withdrawn, without seeing its content.
alter table public.friend_messages
  add column if not exists recalled_at timestamptz;

-- Keep writes to recalled messages inside this function. The caller must be
-- the original sender and still be a participant in the accepted friendship.
create or replace function public.recall_friend_message(p_message_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.friend_messages m
  set body = 'Tin nhắn đã được thu hồi',
      message_type = 'system',
      recalled_at = now(),
      reply_to_message_id = null,
      reply_to_body = null,
      reply_to_sender_id = null
  where m.id = p_message_id
    and m.sender_id = auth.uid()
    and m.message_type = 'text'
    and m.recalled_at is null
    and exists (
      select 1
      from public.friendships f
      where f.id = m.friendship_id
        and f.status = 'accepted'
        and auth.uid() in (f.requester_id, f.addressee_id)
    );

  if not found then
    raise exception 'Không thể thu hồi tin nhắn. Bạn chỉ có thể thu hồi tin nhắn của chính mình.';
  end if;
end;
$$;

revoke all on function public.recall_friend_message(uuid) from public;
grant execute on function public.recall_friend_message(uuid) to authenticated;
