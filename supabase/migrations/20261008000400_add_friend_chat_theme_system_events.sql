-- Theme changes are shared conversation events, not device-local settings.
alter table public.friend_messages
  add column if not exists message_type text not null default 'text'
    check (message_type in ('text', 'system'));

-- Update the conversation theme and append the visible system message in one
-- transaction. The sender is the participant who changed the theme, while the
-- message itself is rendered as a neutral event by the client.
create or replace function public.change_friend_chat_theme(
  p_friendship_id uuid,
  p_theme_id text,
  p_system_message text
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.friendships
  set chat_theme_id = p_theme_id,
      chat_theme_changed_by = auth.uid(),
      chat_theme_changed_at = now(),
      updated_at = now()
  where id = p_friendship_id
    and status = 'accepted'
    and auth.uid() in (requester_id, addressee_id);

  if not found then
    raise exception 'Friendship not found or unavailable';
  end if;

  insert into public.friend_messages (
    friendship_id,
    sender_id,
    body,
    message_type
  )
  values (p_friendship_id, auth.uid(), p_system_message, 'system');
end;
$$;

revoke all on function public.change_friend_chat_theme(uuid, text, text) from public;
grant execute on function public.change_friend_chat_theme(uuid, text, text) to authenticated;
