-- Fix fabricated/broken seed image URLs from 20260829000100.
-- All file names below verified end-to-end (HTTP 200, image/jpeg) via
-- tool/verify_image_urls.dart. Special:FilePath computes the correct
-- thumb path server-side, avoiding hand-guessed hash paths (400/404).

update public.destinations set
  image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Da_Nang_-_Dragon_Bridge.jpg?width=1280',
  gallery = '[
    {"title":"Dragon Bridge","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/Da_Nang_-_Dragon_Bridge.jpg?width=1280"},
    {"title":"Golden Bridge","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/Aerial_view_of_the_Golden_Bridge%2C_Ba_Na_Hills%2C_Da_Nang%2C_Vietnam.jpg?width=1280"}
  ]'::jsonb,
  updated_at = now()
where slug = 'da-nang-vietnam';

update public.destinations set
  image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/H%E1%BB%99i_An%2C_Ancient_Town%2C_2020-01_CN-06.jpg?width=1280',
  gallery = '[
    {"title":"Hoi An Ancient Town","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/H%E1%BB%99i_An%2C_Ancient_Town%2C_2020-01_CN-06.jpg?width=1280"}
  ]'::jsonb,
  updated_at = now()
where slug = 'hoi-an-vietnam';

update public.destinations set
  image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/M%C3%A3_P%C3%AD_L%C3%A8ng_Pass%2C_Vietnam.jpg?width=1280',
  gallery = '[
    {"title":"Ma Pi Leng Pass","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/M%C3%A3_P%C3%AD_L%C3%A8ng_Pass%2C_Vietnam.jpg?width=1280"}
  ]'::jsonb,
  updated_at = now()
where slug = 'ha-giang-vietnam';

update public.destinations set
  image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Phu_Quoc_Beach.jpg?width=1280',
  gallery = '[
    {"title":"Phu Quoc Beach","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/Phu_Quoc_Beach.jpg?width=1280"}
  ]'::jsonb,
  updated_at = now()
where slug = 'phu-quoc-vietnam';
