-- Complete the two Explore categories that previously had only one card.
-- Each image is a direct Wikimedia upload URL and is seed data, not Dart code.

insert into public.destinations
  (slug, name, country, location, category, tags, image_url, price, ai_insight, match_percent, detail_data, gallery)
values
  (
    'ban-gioc-vietnam', 'Ban Gioc Waterfall, Vietnam', 'Vietnam', 'Cao Bang, Vietnam', 'hidden_gems',
    array['Waterfall', 'Nature', 'Borderlands', 'Photography'],
    'https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/Ban_Gioc_Waterfall_-_Trung_Kanh_District_-_Cao_Bang_Province_-_Vietnam_-_11_%2848119809353%29.jpg/1280px-Ban_Gioc_Waterfall_-_Trung_Kanh_District_-_Cao_Bang_Province_-_Vietnam_-_11_%2848119809353%29.jpg',
    '~3.6M VND',
    'A dramatic multi-tier waterfall surrounded by limestone valleys and quiet mountain roads.',
    91,
    '{"weather":"Mild, 18-30C","dateRange":"Flexible","totalBudget":"~3.6M VND"}'::jsonb,
    '[{"title":"Ban Gioc Waterfall","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/Ban_Gioc_Waterfall_-_Trung_Kanh_District_-_Cao_Bang_Province_-_Vietnam_-_11_%2848119809353%29.jpg/1280px-Ban_Gioc_Waterfall_-_Trung_Kanh_District_-_Cao_Bang_Province_-_Vietnam_-_11_%2848119809353%29.jpg"}]'::jsonb
  ),
  (
    'ta-xua-vietnam', 'Ta Xua, Vietnam', 'Vietnam', 'Son La, Vietnam', 'hidden_gems',
    array['Cloud Hunting', 'Mountains', 'Trekking', 'Sunrise'],
    'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/Man_alone_in_T%E1%BA%A3_X%C3%B9a_03-03-2017.jpg/1280px-Man_alone_in_T%E1%BA%A3_X%C3%B9a_03-03-2017.jpg',
    '~3.4M VND',
    'A highland route for cloud hunting, sunrise viewpoints, and a slower mountain escape.',
    89,
    '{"weather":"Cool, 12-24C","dateRange":"Flexible","totalBudget":"~3.4M VND"}'::jsonb,
    '[{"title":"Ta Xua Highlands","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/Man_alone_in_T%E1%BA%A3_X%C3%B9a_03-03-2017.jpg/1280px-Man_alone_in_T%E1%BA%A3_X%C3%B9a_03-03-2017.jpg"}]'::jsonb
  ),
  (
    'ly-son-vietnam', 'Ly Son, Vietnam', 'Vietnam', 'Quang Ngai, Vietnam', 'hidden_gems',
    array['Island', 'Volcanic Coast', 'Seafood', 'Scenery'],
    'https://upload.wikimedia.org/wikipedia/commons/e/ef/Ly_Son3.jpg',
    '~4.1M VND',
    'A compact volcanic island with coastal scenery, seafood, and a distinct off-the-mainland feel.',
    88,
    '{"weather":"Sunny, 24-32C","dateRange":"Flexible","totalBudget":"~4.1M VND"}'::jsonb,
    '[{"title":"Ly Son Island","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/e/ef/Ly_Son3.jpg"}]'::jsonb
  ),
  (
    'ba-be-lake-vietnam', 'Ba Be Lake, Vietnam', 'Vietnam', 'Bac Kan, Vietnam', 'wellness',
    array['Lake', 'Forest', 'Boating', 'Nature'],
    'https://upload.wikimedia.org/wikipedia/commons/4/47/Ba_Be_Lake_6464.jpg',
    '~3.3M VND',
    'Lake boat rides, forest air, and small homestays make Ba Be a quiet reset from city pace.',
    90,
    '{"weather":"Mild, 17-30C","dateRange":"Flexible","totalBudget":"~3.3M VND"}'::jsonb,
    '[{"title":"Ba Be Lake","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/4/47/Ba_Be_Lake_6464.jpg"}]'::jsonb
  ),
  (
    'pu-luong-vietnam', 'Pu Luong, Vietnam', 'Vietnam', 'Thanh Hoa, Vietnam', 'wellness',
    array['Rice Terraces', 'Nature', 'Retreat', 'Hiking'],
    'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Sunset_in_Pu_Luong-_Nov_2025.jpg/1280px-Sunset_in_Pu_Luong-_Nov_2025.jpg',
    '~3.5M VND',
    'Terraced valleys and low-key eco stays suit travellers looking for a quieter nature retreat.',
    91,
    '{"weather":"Mild, 18-30C","dateRange":"Flexible","totalBudget":"~3.5M VND"}'::jsonb,
    '[{"title":"Pu Luong Sunset","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Sunset_in_Pu_Luong-_Nov_2025.jpg/1280px-Sunset_in_Pu_Luong-_Nov_2025.jpg"}]'::jsonb
  ),
  (
    'mai-chau-vietnam', 'Mai Chau, Vietnam', 'Vietnam', 'Hoa Binh, Vietnam', 'wellness',
    array['Valley', 'Culture', 'Cycling', 'Homestay'],
    'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Laundry-Lady-in-Mai-Chau%2C-Vietnam.jpg/1280px-Laundry-Lady-in-Mai-Chau%2C-Vietnam.jpg',
    '~3.2M VND',
    'A green valley for easy cycling, village stays, and a restful break close to nature.',
    89,
    '{"weather":"Mild, 18-31C","dateRange":"Flexible","totalBudget":"~3.2M VND"}'::jsonb,
    '[{"title":"Mai Chau Valley","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Laundry-Lady-in-Mai-Chau%2C-Vietnam.jpg/1280px-Laundry-Lady-in-Mai-Chau%2C-Vietnam.jpg"}]'::jsonb
  )
on conflict (slug) do update set
  name = excluded.name,
  country = excluded.country,
  location = excluded.location,
  category = excluded.category,
  tags = excluded.tags,
  image_url = excluded.image_url,
  price = excluded.price,
  ai_insight = excluded.ai_insight,
  match_percent = excluded.match_percent,
  detail_data = excluded.detail_data,
  gallery = excluded.gallery,
  updated_at = now();

insert into public.featured_destinations (destination_id, category_key, rank)
select id, 'random', 20 + row_number() over (order by match_percent desc)
from public.destinations
where slug in (
  'ban-gioc-vietnam', 'ta-xua-vietnam', 'ly-son-vietnam',
  'ba-be-lake-vietnam', 'pu-luong-vietnam', 'mai-chau-vietnam'
)
on conflict (destination_id, category_key) do update set rank = excluded.rank, is_active = true;

insert into public.featured_destinations (destination_id, category_key, rank)
select id, category, 20 + row_number() over (partition by category order by match_percent desc)
from public.destinations
where slug in (
  'ban-gioc-vietnam', 'ta-xua-vietnam', 'ly-son-vietnam',
  'ba-be-lake-vietnam', 'pu-luong-vietnam', 'mai-chau-vietnam'
)
on conflict (destination_id, category_key) do update set rank = excluded.rank, is_active = true;
