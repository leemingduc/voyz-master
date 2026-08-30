-- Special:FilePath redirects from commons.wikimedia.org, which does NOT send
-- Access-Control-Allow-Origin; browsers fail the redirect hop even though the
-- final upload.wikimedia.org hop is CORS-enabled (curl cannot see this).
-- Seed image URLs must therefore be DIRECT upload.wikimedia.org URLs.
-- All URLs below verified: HTTP 200, image/jpeg, ACAO=*, no redirect
-- (tool/verify_image_urls.dart now enforces exactly this).

update public.destinations set
  image_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Da_Nang_-_Dragon_Bridge.jpg/1280px-Da_Nang_-_Dragon_Bridge.jpg',
  gallery = '[
    {"title":"Dragon Bridge","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Da_Nang_-_Dragon_Bridge.jpg/1280px-Da_Nang_-_Dragon_Bridge.jpg"},
    {"title":"Golden Bridge","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/9/98/Aerial_view_of_the_Golden_Bridge%2C_Ba_Na_Hills%2C_Da_Nang%2C_Vietnam.jpg/1280px-Aerial_view_of_the_Golden_Bridge%2C_Ba_Na_Hills%2C_Da_Nang%2C_Vietnam.jpg"}
  ]'::jsonb,
  updated_at = now()
where slug = 'da-nang-vietnam';

update public.destinations set
  image_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/H%E1%BB%99i_An%2C_Ancient_Town%2C_2020-01_CN-06.jpg/1280px-H%E1%BB%99i_An%2C_Ancient_Town%2C_2020-01_CN-06.jpg',
  gallery = '[
    {"title":"Hoi An Ancient Town","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/H%E1%BB%99i_An%2C_Ancient_Town%2C_2020-01_CN-06.jpg/1280px-H%E1%BB%99i_An%2C_Ancient_Town%2C_2020-01_CN-06.jpg"}
  ]'::jsonb,
  updated_at = now()
where slug = 'hoi-an-vietnam';

update public.destinations set
  image_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/M%C3%A3_P%C3%AD_L%C3%A8ng_Pass%2C_Vietnam.jpg/1280px-M%C3%A3_P%C3%AD_L%C3%A8ng_Pass%2C_Vietnam.jpg',
  gallery = '[
    {"title":"Ma Pi Leng Pass","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/M%C3%A3_P%C3%AD_L%C3%A8ng_Pass%2C_Vietnam.jpg/1280px-M%C3%A3_P%C3%AD_L%C3%A8ng_Pass%2C_Vietnam.jpg"}
  ]'::jsonb,
  updated_at = now()
where slug = 'ha-giang-vietnam';

update public.destinations set
  image_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Phu_Quoc_Beach.jpg/1280px-Phu_Quoc_Beach.jpg',
  gallery = '[
    {"title":"Phu Quoc Beach","imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Phu_Quoc_Beach.jpg/1280px-Phu_Quoc_Beach.jpg"}
  ]'::jsonb,
  updated_at = now()
where slug = 'phu-quoc-vietnam';
