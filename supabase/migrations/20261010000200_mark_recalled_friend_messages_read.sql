-- A recalled message must not leave an unread badge or notification behind.
update public.friend_messages
set delivered_at = coalesce(delivered_at, recalled_at),
    read_at = coalesce(read_at, recalled_at)
where recalled_at is not null;

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
      delivered_at = coalesce(m.delivered_at, now()),
      read_at = coalesce(m.read_at, now()),
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
