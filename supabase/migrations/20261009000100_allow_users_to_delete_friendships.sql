-- Either person in a friendship can remove it. Deleting the friendship also
-- removes its messages through the existing foreign-key cascade.
create policy "Users can delete their own friendships"
  on public.friendships
  for delete
  to authenticated
  using (auth.uid() in (requester_id, addressee_id));
