-- Cache AI giờ chỉ nằm ở Hive trên máy người dùng (spec 2026-09-06 phần 1).
-- Bảng dùng chung này từng cho anon ghi (cache poisoning) và không có TTL.
drop function if exists public.increment_ai_cache_hit(text);
drop table if exists public.ai_generated_cache;
