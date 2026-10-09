-- `rank` remains required by the existing schema but is no longer used by
-- Explore to order or visually promote destinations.

update public.featured_destinations
set rank = 0
where category_key in (
  'random', 'beach', 'mountain', 'heritage', 'city', 'wellness', 'hidden_gems'
);
