-- Persist full AI conversation lists, not just the device-local Hive cache.
-- This keeps histories when a browser profile is recreated or a user changes
-- devices while preserving the existing chat_threads/chat_messages tables.
create table if not exists public.ai_chat_conversation_histories (
  user_id uuid not null references auth.users(id) on delete cascade,
  destination_name text not null default '',
  history jsonb not null default '{"activeId": null, "conversations": []}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, destination_name)
);

create table if not exists public.planner_conversation_histories (
  user_id uuid primary key references auth.users(id) on delete cascade,
  history jsonb not null default '{"activeId": null, "conversations": []}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.ai_chat_conversation_histories enable row level security;
alter table public.planner_conversation_histories enable row level security;

drop policy if exists "Users manage their own AI chat histories"
  on public.ai_chat_conversation_histories;
create policy "Users manage their own AI chat histories"
  on public.ai_chat_conversation_histories for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users manage their own planner histories"
  on public.planner_conversation_histories;
create policy "Users manage their own planner histories"
  on public.planner_conversation_histories for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
