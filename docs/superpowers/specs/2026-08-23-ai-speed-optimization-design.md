# Design Spec: Multi-Tier Cache Optimization for AI Travel Features (Voyz)

## 1. Goal & Context
Optimize response time and resource consumption for **Get AI Suggestions**, **Generate AI Itinerary**, and **Free Explore** from 4–8 seconds down to <100ms for cached data and ~1.5–2.5s for fresh Gemini generations.

## 2. Architecture: Multi-Tier Caching System
```
[User Request]
       │
       ▼
[Tier 1: In-Memory Cache (0ms)]  ──► Hit ──► Return instant result
       │ Miss
       ▼
[Tier 2: Hive Local Storage (5ms)]  ──► Hit ──► Return result + sync memory
       │ Miss
       ▼
[Tier 3: Supabase Cloud DB (50-100ms)] ──► Hit ──► Save to Hive & RAM ──► Return result
       │ Miss
       ▼
[Tier 4: Gemini 3.1 Flash Lite API (1.5-2.5s)]
       │
       ▼
[Write back to Supabase DB, Hive, RAM + Pre-cache images]
```

## 3. Supabase Schema (`ai_generated_cache`)
Table definition in `supabase/migrations/20260823000100_create_ai_generated_cache.sql`:
- `id`: `uuid primary key default gen_random_uuid()`
- `cache_key`: `text not null unique` (deterministic key built from feature type, sanitized inputs, locale)
- `feature_type`: `text not null` (`explore_trending`, `suggestions`, `itinerary`, `detail`, `cultural_tips`, `best_time`, `comparison`)
- `destination`: `text` (optional indexed destination name)
- `language_code`: `text not null default 'vi'`
- `payload`: `jsonb not null` (the raw parsed JSON or string payload)
- `image_urls`: `jsonb` (map of destination -> imageUrl)
- `hit_count`: `int default 1`
- `created_at`: `timestamptz default now()`
- `updated_at`: `timestamptz default now()`

Policies:
- Read: Public (Anon & Authenticated can SELECT)
- Insert/Update: Authenticated + Anon (or service role / open insert with sanitization)

## 4. Components & Flow

### 4.1. CacheService & SupabaseCacheService
- `CacheService` handles Tier 1 (Memory) and Tier 2 (Hive).
- `SupabaseCacheService` handles Tier 3 (Supabase Postgres table query & upsert).
- Unified caching helper: `CacheManager` / `GeminiCacheCoordinator` provides:
  ```dart
  Future<String?> get(String key);
  Future<void> put(String key, String payload, {required String featureType, String? destination, String languageCode = 'vi', Map<String, String>? imageUrls});
  ```

### 4.2. Image Caching in Database & Memory
- When suggestions/destinations are generated, their image URLs from `ImageService` are stored directly in `ai_generated_cache.image_urls` alongside the JSON payload.
- On cache hit, image URLs are immediately available with 0 additional network calls to Wikipedia or Wikimedia.

### 4.3. Prompt & Token Optimization in `GeminiService`
- For suggestions & explore: tuned prompt with concise fields, reduce redundant formatting.
- Graceful fallbacks: If Supabase connection fails or device is offline, app degrades smoothly to Hive -> Gemini without breaking.

## 5. Verification & Testing
- Unit tests for cache tier escalation (Memory -> Hive -> Supabase -> Gemini).
- Deterministic key generation test.
- Flutter widget/integration testing.
