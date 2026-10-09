-- Broaden the curated Explore feed. Image URLs are direct Wikimedia uploads
-- and must remain valid under `dart run tool/verify_image_urls.dart`.

insert into public.destinations
  (slug, name, country, location, category, tags, image_url, price, ai_insight, match_percent, detail_data, gallery)
values
  (
    'ha-long-bay-vietnam', 'Ha Long Bay, Vietnam', 'Vietnam', 'Quang Ninh, Vietnam', 'beach',
    array['Bay', 'Cruise', 'Limestone', 'Seafood'],
    'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Halong_Bay_in_Vietnam.jpg/1280px-Halong_Bay_in_Vietnam.jpg',
    '~4.5M VND',
    'Limestone islands, a slow bay cruise, and seafood villages make this an easy coastal reset.',
    92,
    '{"weather":"Humid, 22-31C","dateRange":"Flexible","totalBudget":"~4.5M VND"}'::jsonb,
    '[{"title":"Ha Long Bay","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Halong_Bay_in_Vietnam.jpg/1280px-Halong_Bay_in_Vietnam.jpg"}]'::jsonb
  ),
  (
    'nha-trang-vietnam', 'Nha Trang, Vietnam', 'Vietnam', 'Khanh Hoa, Vietnam', 'beach',
    array['Beach', 'Island', 'Seafood', 'Diving'],
    'https://upload.wikimedia.org/wikipedia/commons/4/4d/Soccer_by_the_beach%2C_Nha_Trang%2C_Vietnam.jpg',
    '~4M VND',
    'A sunny beach city for relaxed mornings, island day trips, and fresh seafood by the shore.',
    91,
    '{"weather":"Sunny, 25-32C","dateRange":"Flexible","totalBudget":"~4M VND"}'::jsonb,
    '[{"title":"Nha Trang Beach","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/4/4d/Soccer_by_the_beach%2C_Nha_Trang%2C_Vietnam.jpg"}]'::jsonb
  ),
  (
    'con-dao-vietnam', 'Con Dao, Vietnam', 'Vietnam', 'Ba Ria - Vung Tau, Vietnam', 'beach',
    array['Island', 'Nature', 'Beach', 'History'],
    'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3d/C%C3%B4n_%C4%90%E1%BA%A3o_National_Park.jpg/1280px-C%C3%B4n_%C4%90%E1%BA%A3o_National_Park.jpg',
    '~5.5M VND',
    'A quieter island escape where forested hills, clear water, and local history meet.',
    90,
    '{"weather":"Tropical, 25-31C","dateRange":"Flexible","totalBudget":"~5.5M VND"}'::jsonb,
    '[{"title":"Con Dao National Park","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/3/3d/C%C3%B4n_%C4%90%E1%BA%A3o_National_Park.jpg/1280px-C%C3%B4n_%C4%90%E1%BA%A3o_National_Park.jpg"}]'::jsonb
  ),
  (
    'sa-pa-vietnam', 'Sa Pa, Vietnam', 'Vietnam', 'Lao Cai, Vietnam', 'mountain',
    array['Mountains', 'Rice Terraces', 'Trekking', 'Culture'],
    'https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Road_and_paddy_fields_in_Sa_Pa%2C_Vietnam%2C_20240126_1202_3586.jpg/1280px-Road_and_paddy_fields_in_Sa_Pa%2C_Vietnam%2C_20240126_1202_3586.jpg',
    '~3.8M VND',
    'Terraced valleys, cool mountain air, and village walks suit a scenic weekend away.',
    93,
    '{"weather":"Cool, 12-25C","dateRange":"Flexible","totalBudget":"~3.8M VND"}'::jsonb,
    '[{"title":"Sa Pa Rice Terraces","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Road_and_paddy_fields_in_Sa_Pa%2C_Vietnam%2C_20240126_1202_3586.jpg/1280px-Road_and_paddy_fields_in_Sa_Pa%2C_Vietnam%2C_20240126_1202_3586.jpg"}]'::jsonb
  ),
  (
    'da-lat-vietnam', 'Da Lat, Vietnam', 'Vietnam', 'Lam Dong, Vietnam', 'wellness',
    array['Pine Forest', 'Coffee', 'Cool Weather', 'Relaxation'],
    'https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Da_Lat_train_station_02.JPG/1280px-Da_Lat_train_station_02.JPG',
    '~3.5M VND',
    'Cool weather, pine-covered hills, and unhurried coffee stops make Da Lat a gentle recharge.',
    94,
    '{"weather":"Cool, 15-24C","dateRange":"Flexible","totalBudget":"~3.5M VND"}'::jsonb,
    '[{"title":"Da Lat Railway Station","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Da_Lat_train_station_02.JPG/1280px-Da_Lat_train_station_02.JPG"}]'::jsonb
  ),
  (
    'hue-vietnam', 'Hue, Vietnam', 'Vietnam', 'Thua Thien Hue, Vietnam', 'heritage',
    array['Imperial City', 'Heritage', 'Cuisine', 'River'],
    'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Hu%C3%A9%2C_1932_%E2%80%93_La_Ville_Imp%C3%A9riale_%E2%80%93_Vue_a%C3%A9rienne.jpg/1280px-Hu%C3%A9%2C_1932_%E2%80%93_La_Ville_Imp%C3%A9riale_%E2%80%93_Vue_a%C3%A9rienne.jpg',
    '~3.6M VND',
    'Imperial architecture, riverside cycling, and central Vietnamese cuisine reward a slower pace.',
    89,
    '{"weather":"Warm, 22-32C","dateRange":"Flexible","totalBudget":"~3.6M VND"}'::jsonb,
    '[{"title":"Hue Imperial City","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Hu%C3%A9%2C_1932_%E2%80%93_La_Ville_Imp%C3%A9riale_%E2%80%93_Vue_a%C3%A9rienne.jpg/1280px-Hu%C3%A9%2C_1932_%E2%80%93_La_Ville_Imp%C3%A9riale_%E2%80%93_Vue_a%C3%A9rienne.jpg"}]'::jsonb
  ),
  (
    'ninh-binh-vietnam', 'Ninh Binh, Vietnam', 'Vietnam', 'Ninh Binh, Vietnam', 'heritage',
    array['Limestone', 'Rivers', 'Temples', 'Cycling'],
    'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/Vietnam%2C_Ninh_Binh%2C_Limestone_Karts.jpg/1280px-Vietnam%2C_Ninh_Binh%2C_Limestone_Karts.jpg',
    '~3.2M VND',
    'River caves, limestone peaks, and cycling lanes give Ninh Binh a calm, cinematic rhythm.',
    92,
    '{"weather":"Mild, 20-31C","dateRange":"Flexible","totalBudget":"~3.2M VND"}'::jsonb,
    '[{"title":"Ninh Binh Limestone Landscape","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/Vietnam%2C_Ninh_Binh%2C_Limestone_Karts.jpg/1280px-Vietnam%2C_Ninh_Binh%2C_Limestone_Karts.jpg"}]'::jsonb
  ),
  (
    'hanoi-vietnam', 'Hanoi, Vietnam', 'Vietnam', 'Hanoi, Vietnam', 'city',
    array['Old Quarter', 'Food', 'Culture', 'Lakes'],
    'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Sunset_over_Hanoi_After_the_Rain.jpg/1280px-Sunset_over_Hanoi_After_the_Rain.jpg',
    '~3.7M VND',
    'Street food, walkable old streets, and lakeside evenings make Hanoi ideal for culture-led city breaks.',
    93,
    '{"weather":"Seasonal, 15-34C","dateRange":"Flexible","totalBudget":"~3.7M VND"}'::jsonb,
    '[{"title":"Hanoi Sunset","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Sunset_over_Hanoi_After_the_Rain.jpg/1280px-Sunset_over_Hanoi_After_the_Rain.jpg"}]'::jsonb
  ),
  (
    'phong-nha-vietnam', 'Phong Nha, Vietnam', 'Vietnam', 'Quang Binh, Vietnam', 'hidden_gems',
    array['Caves', 'Nature', 'Adventure', 'Rivers'],
    'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/Phong_Nha-Ke_Bang_cave3.jpg/1280px-Phong_Nha-Ke_Bang_cave3.jpg',
    '~4.2M VND',
    'Caves, jungle roads, and river scenery offer an adventurous alternative to the usual beach break.',
    90,
    '{"weather":"Warm, 22-33C","dateRange":"Flexible","totalBudget":"~4.2M VND"}'::jsonb,
    '[{"title":"Phong Nha Cave","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/Phong_Nha-Ke_Bang_cave3.jpg/1280px-Phong_Nha-Ke_Bang_cave3.jpg"}]'::jsonb
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
select id, 'random', 10 + row_number() over (order by match_percent desc)
from public.destinations
where slug in (
  'ha-long-bay-vietnam', 'nha-trang-vietnam', 'con-dao-vietnam',
  'sa-pa-vietnam', 'da-lat-vietnam', 'hue-vietnam', 'ninh-binh-vietnam',
  'hanoi-vietnam', 'phong-nha-vietnam'
)
on conflict (destination_id, category_key) do update set rank = excluded.rank, is_active = true;

insert into public.featured_destinations (destination_id, category_key, rank)
select id, category, 10 + row_number() over (partition by category order by match_percent desc)
from public.destinations
where slug in (
  'ha-long-bay-vietnam', 'nha-trang-vietnam', 'con-dao-vietnam',
  'sa-pa-vietnam', 'da-lat-vietnam', 'hue-vietnam', 'ninh-binh-vietnam',
  'hanoi-vietnam', 'phong-nha-vietnam'
)
on conflict (destination_id, category_key) do update set rank = excluded.rank, is_active = true;
