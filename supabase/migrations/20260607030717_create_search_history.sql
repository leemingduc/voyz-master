create table if not exists public.search_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  destination text not null,
  depart_date date,
  return_date date,
  budget text,
  currency text not null default 'VND',
  participants text,
  age_range text,
  selected_interests text[] not null default '{}',
  ai_prompt text,
  additional_notes text,
  created_at timestamptz not null default now()
);

alter table public.search_history enable row level security;

create policy "Users can read their own search history"
  on public.search_history
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert their own search history"
  on public.search_history
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create index if not exists search_history_user_created_at_idx
  on public.search_history (user_id, created_at desc);
