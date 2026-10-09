-- A chat theme belongs to the shared friendship conversation, not a device.
alter table public.friendships
  add column if not exists chat_theme_id text not null default 'aivivu',
  add column if not exists chat_theme_changed_by uuid references auth.users(id) on delete set null,
  add column if not exists chat_theme_changed_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'friendships'
  ) then
    alter publication supabase_realtime add table public.friendships;
  end if;
end;
$$;
