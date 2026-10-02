-- Update review calculation trigger to incorporate 100 virtual base votes with 5.0 stars
create or replace function public.refresh_destination_review_stats(target_destination_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.destinations d
  set
    rating = (
      select round((500.0 + coalesce(sum(r.rating), 0)) / (100.0 + count(*)), 2)
      from public.community_reviews r
      where r.destination_id = target_destination_id
    ),
    review_count = (
      select 100 + count(*)::integer
      from public.community_reviews r
      where r.destination_id = target_destination_id
    ),
    updated_at = now()
  where d.id = target_destination_id;
end;
$$;

-- Refresh all existing destinations
update public.destinations d
set
  rating = coalesce((
    select round((500.0 + coalesce(sum(r.rating), 0)) / (100.0 + count(*)), 2)
    from public.community_reviews r
    where r.destination_id = d.id
  ), 5.0),
  review_count = coalesce((
    select 100 + count(*)::integer
    from public.community_reviews r
    where r.destination_id = d.id
  ), 100),
  updated_at = now();
