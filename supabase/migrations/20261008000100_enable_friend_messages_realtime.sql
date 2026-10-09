-- Ensure recalls are delivered as a realtime DELETE event to every open
-- conversation. REPLICA IDENTITY FULL lets Postgres provide the old row data
-- needed by clients that subscribe with a friendship_id filter.
alter table public.friend_messages replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'friend_messages'
  ) then
    alter publication supabase_realtime add table public.friend_messages;
  end if;
end;
$$;
