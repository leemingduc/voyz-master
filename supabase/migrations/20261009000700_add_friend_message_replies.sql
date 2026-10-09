-- Store a small snapshot of the replied-to message so the quoted context is
-- still meaningful even when the original message is later removed.
alter table public.friend_messages
  add column if not exists reply_to_message_id uuid
    references public.friend_messages(id) on delete set null,
  add column if not exists reply_to_body text,
  add column if not exists reply_to_sender_id uuid;

create index if not exists friend_messages_reply_to_idx
  on public.friend_messages (reply_to_message_id)
  where reply_to_message_id is not null;
