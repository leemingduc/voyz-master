# Multi-Tier AI Cache Speed Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Accelerate "Get AI Suggestions", "Generate AI Itinerary", and "Free Explore" features using a unified 3-tier caching system (Memory -> Hive -> Supabase Cloud DB) and pre-cached images.

**Architecture:** Implement `AiCacheService` to coordinate Tier 1 (RAM), Tier 2 (Hive), Tier 3 (Supabase Database Table `ai_generated_cache`), with fallback to Gemini 3.1 Flash Lite API. Automatically persist AI generation results and resolved image URLs into Supabase and Hive.

**Tech Stack:** Flutter, Dart, Supabase Flutter, Hive Flutter, Crypto (MD5 keying), Google Generative AI.

---

### Task 1: Supabase Database Migration for `ai_generated_cache`

**Files:**
- Create: `supabase/migrations/20260823000100_create_ai_generated_cache.sql`

- [ ] **Step 1: Write migration SQL**
Create table `public.ai_generated_cache` with columns `id`, `cache_key`, `feature_type`, `destination`, `language_code`, `payload`, `image_urls`, `hit_count`, `created_at`, `updated_at` with RLS policies allowing public reads and authenticated/anon upserts.

- [ ] **Step 2: Commit**
`git add supabase/migrations/20260823000100_create_ai_generated_cache.sql`

---

### Task 2: Implement Unified `AiCacheService` (Multi-Tier Caching)

**Files:**
- Create: `lib/services/ai_cache_service.dart`
- Test: `test/services/ai_cache_service_test.dart`
- Modify: `lib/services/cache_service.dart`

**Interfaces:**
- `Future<String?> get(String key)` (checks Memory -> Hive -> Supabase DB)
- `Future<Map<String, String>?> getImageUrls(String key)`
- `Future<void> put(String key, String payload, {required String featureType, String? destination, String languageCode, Map<String, String>? imageUrls})`

- [ ] **Step 1: Write unit tests for `AiCacheService`**
- [ ] **Step 2: Implement `AiCacheService` with in-memory map, Hive box, and Supabase client fallback**
- [ ] **Step 3: Run tests to verify pass**

---

### Task 3: Refactor `GeminiService` to use `AiCacheService` & Image Pre-caching

**Files:**
- Modify: `lib/services/gemini_service.dart`
- Test: `test/gemini_service_test.dart`

- [ ] **Step 1: Update `getExploreTrending`, `getSuggestions`, and `getItineraryPlan` in `GeminiService` to check `AiCacheService`**
- [ ] **Step 2: Pre-save image URLs directly into cache payload so subsequent loads get images instantly**
- [ ] **Step 3: Run existing and new test suites (`flutter test`)**

---

### Task 4: Enhance UI Screens (`ExploreScreen`, `SmartPlannerScreen`, `DestinationPlanScreen`)

**Files:**
- Modify: `lib/screens/explore_screen.dart`
- Modify: `lib/screens/suggestions_screen.dart`
- Modify: `lib/screens/destination_plan_screen.dart`

- [ ] **Step 1: Wire cached images directly from suggestions/destinations without secondary network wait**
- [ ] **Step 2: Verify instantaneous rendering on cache hit (<100ms) and smooth UI state updates**
- [ ] **Step 3: Run `flutter analyze` & `flutter test`**
