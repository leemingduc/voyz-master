-- Keep exactly eight image-backed cards in every Explore category.
-- A destination may be relevant to more than one travel style, so the same
-- curated destination can appear in multiple category feeds.

update public.featured_destinations
set is_active = false
where category_key in (
  'random', 'beach', 'mountain', 'heritage', 'city', 'wellness', 'hidden_gems'
);

with slots(category_key, rank, slug) as (
  values
    -- Ngẫu nhiên
    ('random', 1, 'da-nang-vietnam'),
    ('random', 2, 'hoi-an-vietnam'),
    ('random', 3, 'ha-giang-vietnam'),
    ('random', 4, 'phu-quoc-vietnam'),
    ('random', 5, 'da-lat-vietnam'),
    ('random', 6, 'hanoi-vietnam'),
    ('random', 7, 'nha-trang-vietnam'),
    ('random', 8, 'phong-nha-vietnam'),

    -- Biển đảo
    ('beach', 1, 'phu-quoc-vietnam'),
    ('beach', 2, 'ha-long-bay-vietnam'),
    ('beach', 3, 'nha-trang-vietnam'),
    ('beach', 4, 'con-dao-vietnam'),
    ('beach', 5, 'ly-son-vietnam'),
    ('beach', 6, 'da-nang-vietnam'),
    ('beach', 7, 'hoi-an-vietnam'),
    ('beach', 8, 'ba-be-lake-vietnam'),

    -- Vùng núi & đèo
    ('mountain', 1, 'ha-giang-vietnam'),
    ('mountain', 2, 'sa-pa-vietnam'),
    ('mountain', 3, 'ta-xua-vietnam'),
    ('mountain', 4, 'ban-gioc-vietnam'),
    ('mountain', 5, 'da-lat-vietnam'),
    ('mountain', 6, 'pu-luong-vietnam'),
    ('mountain', 7, 'mai-chau-vietnam'),
    ('mountain', 8, 'ninh-binh-vietnam'),

    -- Cổ kính & di sản
    ('heritage', 1, 'hoi-an-vietnam'),
    ('heritage', 2, 'hue-vietnam'),
    ('heritage', 3, 'ninh-binh-vietnam'),
    ('heritage', 4, 'hanoi-vietnam'),
    ('heritage', 5, 'da-nang-vietnam'),
    ('heritage', 6, 'ha-long-bay-vietnam'),
    ('heritage', 7, 'phong-nha-vietnam'),
    ('heritage', 8, 'ly-son-vietnam'),

    -- Đô thị sôi động
    ('city', 1, 'da-nang-vietnam'),
    ('city', 2, 'hanoi-vietnam'),
    ('city', 3, 'hue-vietnam'),
    ('city', 4, 'hoi-an-vietnam'),
    ('city', 5, 'nha-trang-vietnam'),
    ('city', 6, 'da-lat-vietnam'),
    ('city', 7, 'ha-long-bay-vietnam'),
    ('city', 8, 'ninh-binh-vietnam'),

    -- Nghỉ dưỡng thiên nhiên
    ('wellness', 1, 'da-lat-vietnam'),
    ('wellness', 2, 'ba-be-lake-vietnam'),
    ('wellness', 3, 'pu-luong-vietnam'),
    ('wellness', 4, 'mai-chau-vietnam'),
    ('wellness', 5, 'sa-pa-vietnam'),
    ('wellness', 6, 'ninh-binh-vietnam'),
    ('wellness', 7, 'ha-long-bay-vietnam'),
    ('wellness', 8, 'con-dao-vietnam'),

    -- Độc lạ
    ('hidden_gems', 1, 'phong-nha-vietnam'),
    ('hidden_gems', 2, 'ban-gioc-vietnam'),
    ('hidden_gems', 3, 'ta-xua-vietnam'),
    ('hidden_gems', 4, 'ly-son-vietnam'),
    ('hidden_gems', 5, 'ba-be-lake-vietnam'),
    ('hidden_gems', 6, 'pu-luong-vietnam'),
    ('hidden_gems', 7, 'con-dao-vietnam'),
    ('hidden_gems', 8, 'ha-giang-vietnam')
)
insert into public.featured_destinations (destination_id, category_key, rank, is_active)
select d.id, slots.category_key, slots.rank, true
from slots
join public.destinations d on d.slug = slots.slug
where d.is_active = true
  and d.image_url <> ''
on conflict (destination_id, category_key) do update set
  rank = excluded.rank,
  is_active = true;
