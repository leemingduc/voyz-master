-- Add DELETE policy for friend_messages so message senders can recall their own messages.
-- Without this policy, Supabase RLS blocks all DELETE operations on friend_messages,
-- causing the recall feature to silently fail.

create policy "Sender can recall their own messages"
  on public.friend_messages
  for delete
  to authenticated
  using (auth.uid() = sender_id);
