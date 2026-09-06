-- supabase/migrations/20260907000100_trip_identity.sql
-- Spec: docs/superpowers/specs/2026-09-06-simple-cache-and-trip-identity-design.md phan 2.4

-- Du lieu test cu khong co trip_id, reset sach (da thong nhat voi giao vien).
delete from public.saved_itineraries;
-- Xoa saved_trips cung keo theo xoa het trip_collaborators tuong ung, vi
-- trip_collaborators.trip_id references saved_trips(id) on delete cascade.
delete from public.saved_trips;

-- saved_trips: id do client sinh, cho phep hai chuyen cung ten.
alter table public.saved_trips drop constraint if exists saved_trips_user_name_unique;

-- saved_itineraries: gan theo trip, mot trip mot itinerary.
alter table public.saved_itineraries
  add column if not exists trip_id uuid references public.saved_trips(id) on delete cascade;
alter table public.saved_itineraries drop constraint if exists saved_itineraries_user_dest_unique;
alter table public.saved_itineraries alter column trip_id set not null;
create unique index if not exists saved_itineraries_trip_idx
  on public.saved_itineraries (trip_id);

-- search_history: cho phep xoa lich su cua minh.
drop policy if exists "Users can delete their own search history" on public.search_history;
create policy "Users can delete their own search history"
  on public.search_history for delete to authenticated
  using (auth.uid() = user_id);
