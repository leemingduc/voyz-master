# Voyz giai đoạn 3: Roadmap hoàn thiện cuối khoá theo hướng AI-first và đơn giản hoá

> Ngày: 06/09/2026. Baseline: `master` sau merge PR #12 (commit `0e5bb51`).
> Tài liệu này THAY THẾ ba tài liệu cũ đã xoá khỏi repo: `project_review_supabase_integration.md` (23/08), `SUPABASE_INTEGRATION_ROADMAP.md` (roadmap học sinh), `week1_parallel_assignments.md` (30/08). Cần xem lại thì tra git history trước commit ngày 06/09/2026.
> Tài liệu nền vẫn còn hiệu lực, chỉ trỏ tới chứ không lặp lại: `project_phase2_core_architecture_alignment.md` (kiến trúc, mục 4.5 về giá thật), `lessons/2026-08-31-image-stability-walkthrough.md` (quy tắc ảnh), `superpowers/specs/2026-09-01-prompt-first-step1-design.md` (bước 1 planner đã làm).

## 0. Nguyên tắc của giai đoạn này

Đây là project cuối khoá. Mục tiêu là một app **mạch lạc, chạy được, thể hiện rõ ý tưởng**, không phải một hệ thống xử lý triệt để mọi edge case.

1. Khi phân vân giữa hai cách, chọn cách **ít code hơn** và **ít khái niệm mới hơn**.
2. Mỗi hướng dưới đây có mục "Đủ là dừng". Làm tới đó thì dừng, không tự mở rộng.
3. Xoá code không dùng được tính là tiến độ. Xoá một tầng cache, một form, một service chết đều là việc tốt.
4. Dữ liệu test cũ trong Hive và Supabase được phép reset sạch, không cần migrate.

## 1. Hiện trạng sau PR #10, #11, #12

| Phần | Đã có trên master | Còn thiếu hoặc cần sửa |
|---|---|---|
| Smart Planner | Prompt là trường bắt buộc duy nhất; AI suy ra điểm đến, ngày, số người từ mô tả (PR #12) | Vẫn còn 7 form control (điểm đến, 2 ngày, ngân sách, số người, độ tuổi, sở thích, ghi chú). Chưa có hàm trích xuất prompt thành `TripData` |
| AI service | `GeminiService` một cửa duy nhất, model `gemini-3.1-flash-lite`, 3 prompt builder test được | Cache key của detail thiếu budget/currency/ngày; key itinerary thiếu ngày; key suggestions thiếu participants/ageRange |
| Cache | `AiCacheService` 3 tầng Memory / Hive / Supabase, allowlist host ảnh | Không TTL. Tầng Supabase `ai_generated_cache` cho `anon` ghi (cache poisoning). `CacheService` là code chết, chỉ còn `init()` trong `main.dart` |
| Trip data | `saved_trips` và `saved_itineraries` đã lên cloud, có realtime | `SavedItem` chưa có `id`, còn `cloudId`. Upsert theo `(user_id, name)`, itinerary theo `destination_name`. `_currentTrip` chỉ ở Hive. Sync merge theo tên, xoá bị hồi sinh |
| Supabase schema | 14 bảng, `profiles` có `preferred_currency`, `travel_styles` | `search_history` không có DELETE policy nên xoá lịch sử là no-op trên cloud |
| Ảnh | Chuỗi Wikipedia REST vi -> en -> Commons -> rỗng, allowlist `upload.wikimedia.org`, `tool/verify_image_urls.dart` | 7 chỗ tự viết `CachedNetworkImage` mỗi nơi một kiểu, 2 chỗ dùng `NetworkImage` thô. Nhánh vi luôn 404 với tên không dấu. Landmark AI đặt tên không có ảnh |
| Giá | Budget tier 4 mức trong prompt, `ExchangeRateService` quy đổi tiền | Không có khái niệm giá khách sạn. Mọi số tiền là chuỗi đã format. Hardcode `matchPercent: 98, rating: 4.5, reviewCount: 120` khi lưu |
| Test / CI | 10 file test unit, CI build và deploy GitHub Pages | Không test sync, screens. CI không chạy analyze/test |

Về việc tuần 1 cũ: **chưa có deliverable nào vào master**. Phần còn dùng lại: trip identity theo UUID (mục 2.3). Phần bỏ hẳn: harden RLS cho `ai_generated_cache`, Hive box theo user cho cache Supabase (vì bỏ luôn tầng đó, mục 2.2). Tách interface `AITravelGateway` chuyển thành tuỳ chọn, không bắt buộc.

## 2. Năm hướng hoàn thiện

### 2.1. Smart Planner AI-first: một ô mô tả và hàng chip xác nhận

**Mục tiêu:** người dùng chỉ mô tả chuyến đi bằng lời, AI trích ra thông tin có cấu trúc, người dùng liếc qua chip và sửa nếu cần.

Làm gì:
- `lib/screens/smart_planner_screen.dart`: xoá 7 form control. Còn lại prompt box, hàng chip, nút "Gợi ý". Prefill currency và sở thích từ `profiles` giữ nguyên nhưng không hiển thị dưới dạng form.
- `lib/services/gemini_service.dart`: thêm `extractTripData(String prompt, {String languageCode})` trả về `TripData`. Prompt yêu cầu JSON với các key: `destination`, `departDate`, `returnDate`, `budgetTier`, `participants`, `interests`. Key không suy ra được thì để rỗng hoặc null. Không cache hàm này.
- `lib/widgets/shared/trip_chips.dart` (mới): hàng chip đọc từ `TripData`. Chip rỗng hiện dạng mờ ("Điểm đến: AI sẽ gợi ý"). Tap chip mở bottom sheet nhỏ để sửa đúng một giá trị (text, date picker, hoặc chọn tier).
- Luồng: bấm "Gợi ý" -> `extractTripData` -> hiển thị chip -> người dùng sửa hoặc bấm tiếp -> `updateTrip()` + `recordTripSearch()` -> `SuggestionsScreen` như hiện tại.
- `TripData` giữ nguyên hình dạng. Không cần khái niệm `TripContext` mới, `TripData` đã đóng vai trò đó khi được truyền xuyên suốt.
- Xoá các key l10n không còn dùng (`requiredInfo`, `fillAllRequired` và các nhãn form) sau khi xoá form.

Đủ là dừng:
- Không streaming, không hội thoại nhiều vòng trên planner, không "AI hỏi lại".
- Không đổi 3 màn hình downstream (suggestions, detail, plan).

Nghiệm thu:
- [ ] Nhập "Đi Đà Lạt 3 ngày với gia đình 4 người, tiết kiệm" -> chip hiện đúng điểm đến, số ngày, số người, tier economy.
- [ ] Sửa chip ngân sách sang premium rồi bấm tiếp: gợi ý phản ánh tier mới.
- [ ] Prompt mơ hồ "muốn đi biển" vẫn ra gợi ý, chip điểm đến ở trạng thái mờ.
- [ ] Có test parse JSON của `extractTripData` (bao gồm trường hợp thiếu key).

### 2.2. Cache đơn giản: hai tầng, có TTL, chỉ cache thứ cần cache

> Spec chi tiết: `docs/superpowers/specs/2026-09-06-simple-cache-and-trip-identity-design.md` phần 1. Spec cắt gọn thêm so với mục này (một tầng Hive, một TTL, không ảnh trong cache); khi khác nhau thì spec thắng.

**Mục tiêu:** cache chỉ để mở lại nhanh trên cùng máy, không phải dữ liệu nghiệp vụ, không dùng chung giữa người dùng.

Làm gì:
- Xoá `lib/services/cache_service.dart` và dòng `CacheService.instance.init()` trong `lib/main.dart`.
- `lib/services/ai_cache_service.dart`: bỏ toàn bộ đọc/ghi bảng `ai_generated_cache` và RPC `increment_ai_cache_hit`. Còn Memory + Hive. Tên box theo user: `ai_cache_<userId>` (đăng xuất thì đóng box).
- Entry lưu thêm `createdAt` và `ttl`. TTL cố định theo feature: explore 24 giờ; suggestions, detail, itinerary 7 ngày; best_time, cultural_tips, comparison 30 ngày. Quá hạn coi là miss ở cả hai tầng.
- Cache key = md5 của **mọi** input có mặt trong prompt + hằng `promptVersion` (tăng khi sửa prompt). Sửa key detail (thêm budget, currency, ngày), key itinerary (thêm ngày), key suggestions (thêm participants, ageRange).
- Bỏ `nonce` trong `getExploreTrending`: force refresh bỏ qua bước đọc, kết quả ghi đè vào key chuẩn.
- Giữ `sanitizeImageUrls` vì Hive vẫn có thể chứa URL cũ.
- Migration mới `supabase/migrations/20260907000200_drop_ai_generated_cache.sql`: `drop table if exists public.ai_generated_cache;`.

Đủ là dừng:
- Không LRU, không giới hạn dung lượng, không thống kê hit.
- Không cache chat, không cache `extractTripData`.

Nghiệm thu:
- [ ] `grep -r "ai_generated_cache" lib/` trả về 0 kết quả; `lib/services/cache_service.dart` không còn tồn tại.
- [ ] Test: entry quá TTL trả về miss; hai input khác `participants` sinh hai key khác nhau.
- [ ] Hai tài khoản đăng nhập lần lượt trên một máy không thấy cache của nhau.
- [ ] Đổi budget tier rồi mở lại detail cùng điểm đến: nội dung ngân sách khác nhau.

### 2.3. Mô hình dữ liệu chuẩn và đưa dữ liệu local lên Supabase

> Spec chi tiết: `docs/superpowers/specs/2026-09-06-simple-cache-and-trip-identity-design.md` phần 2. Spec cắt gọn thêm so với mục này (không version itinerary, không draft lên cloud, ghi cloud có chờ thay cho cờ pendingSync); khi khác nhau thì spec thắng.

**Mục tiêu:** một chuyến đi có danh tính thật (UUID), Supabase là nguồn chính, Hive chỉ là cache đọc. Đăng nhập máy khác thấy đúng dữ liệu.

Mô hình sau khi sửa (bảng đã có, chỉ nắn cột):

```text
profiles (user_id PK)  1 --- n  search_history (id, user_id, destination, dates, budget, ai_prompt...)
                       1 --- n  saved_trips (id UUID PK do client sinh, user_id, name, status, trip_data jsonb,
                       |                    checklist, notes, booking_refs, updated_at)
                       |             1 --- n  saved_itineraries (id, trip_id FK, version, is_current, plan_data jsonb)
                       1 --- n  chat_threads (id, user_id, destination_name) 1 --- n chat_messages
destinations (curated seed, chỉ đọc)  1 --- n  featured_destinations
Đóng băng, không đụng: social_profiles, friendships, friend_messages, trip_collaborators, community_reviews
```

Làm gì:
- Migration `supabase/migrations/20260907000100_trip_identity.sql`:
  - `saved_trips`: bỏ unique `(user_id, name)`; thêm `status text not null default 'saved'` (giá trị `draft` cho bản nháp planner).
  - `saved_itineraries`: thêm `trip_id uuid references saved_trips(id) on delete cascade`, `version integer default 1`, `is_current boolean default true`; bỏ unique `(user_id, destination_name)`; unique `(trip_id, version)`.
  - `search_history`: thêm policy DELETE cho `auth.uid() = user_id`.
- `lib/data/trip_data.dart`: `SavedItem` thêm `final String id` (package `uuid`, sinh khi tạo), bỏ `cloudId`. `fromMap` thiếu `id` thì sinh mới. `copyWith` giữ `id`.
- `lib/models/itinerary_plan.dart`: thêm `tripId`.
- `lib/data/saved_trips_provider.dart`: upsert `saved_trips` với `onConflict: 'id'`; Hive key = `item.id`; `itineraryFor(tripId)`, `saveItinerary(plan)` tăng `version`; xoá theo `id`. `_currentTrip` lưu lên `saved_trips` với `status = 'draft'` (một bản nháp mỗi user).
- Sync tối giản trong `_syncFromSupabase`: load cloud trước, cloud là nguồn chính; item local có cờ `pendingSync` thì đẩy lên rồi xoá cờ; item local không có cờ mà cloud không còn thì xoá local. Chỉ xử lý trip có `user_id` là mình.
- `lib/screens/saved_screen.dart` và `destination_detail_screen.dart`: mở trip đã lưu phải truyền `SavedItem` và restore `item.tripData`, không dùng `currentTrip` toàn cục.
- Số ngày itinerary: tính cả ngày đi và ngày về (`inDays + 1`), tối đa 7.

Đủ là dừng:
- Không tombstone, không hàng đợi offline, không so `updated_at` từng field. Mất mạng thì báo lỗi và thử lại.
- Không thêm collaborator, không thêm realtime mới. Subscription hiện có giữ nguyên.

Nghiệm thu:
- [ ] Tạo 2 chuyến "Đà Nẵng" ngày khác nhau: cả hai cùng hiện, mỗi chuyến có itinerary riêng và mở lại đúng ngày, số người, ngân sách.
- [ ] Xoá trip trên trình duyệt A, reload trình duyệt B: trip mất và không sống lại.
- [ ] Nhập planner trên máy A, đăng nhập máy B: prompt và chip đã nhập hiện lại.
- [ ] Xoá một dòng lịch sử tìm kiếm rồi reload: dòng đó mất thật trên cloud.
- [ ] Test: `fromMap` thiếu `id` sinh id hợp lệ; hai item cùng `name` cùng tồn tại.

### 2.4. Ảnh: polish trải nghiệm trên nền đã ổn định

**Mục tiêu:** không đổi kiến trúc nguồn ảnh (đã sửa xong ở PR #10). Chỉ làm ảnh lỗi trông nhất quán và giảm request thừa.

Làm gì:
- `lib/widgets/shared/destination_image.dart` (mới): bọc `CachedNetworkImage`, nhận `imageUrl`, `destinationName`, `fit`, `borderRadius`. Ba trạng thái: URL rỗng hiện fallback ngay; đang tải hiện gradient placeholder; lỗi hiện gradient + icon núi + tên mờ. Thay 7 call site trong `lib/screens/` và 2 chỗ `NetworkImage` avatar (`friends_screen.dart`, `account_menu_button.dart`).
- `lib/services/image_service.dart`:
  - Tên không có ký tự tiếng Việt có dấu thì hỏi `en.wikipedia` trước rồi `vi`; có dấu thì giữ `vi` trước.
  - Kết quả rỗng chỉ cache 10 phút, không cache suốt phiên.
  - `getImageUrls` chạy theo lô 3 request, không fan-out toàn bộ.
- `lib/screens/destination_detail_screen.dart`: landmark không có ảnh thì fallback về ảnh chính của điểm đến (làm tối đi).
- `lib/screens/explore_screen.dart`: `_loadExplore` fallback sang Gemini cả khi `DestinationRepository` ném exception, không chỉ khi rỗng.
- Ảnh điểm đến seed nào resolve được URL tốt thì ghi vào `destinations.image_url` bằng migration và chạy `dart run tool/verify_image_urls.dart`. URL là dữ liệu, không nằm trong code Dart.

Đủ là dừng:
- Không CDN, không upload ảnh, không thêm nguồn ảnh mới, không sửa `tool/verify_image_urls.dart`.

Nghiệm thu:
- [ ] Mọi trạng thái không có ảnh trong app trông giống nhau (một design).
- [ ] Mở Explore với điểm đến tên tiếng Anh: console không còn chuỗi 404 `vi.wikipedia.org`.
- [ ] Gallery landmark không còn ô trống.
- [ ] `dart run tool/verify_image_urls.dart` pass; test MockClient cho cả hai nhánh heuristic ngôn ngữ.

### 2.5. Khung ước tính giá khách sạn

**Mục tiêu:** tách rõ "ước tính AI" và "báo giá đối tác" bằng một interface, để sau này cắm API thật không phải sửa UI. Giai đoạn này chỉ dựng khung và mock.

Làm gì:
- `lib/services/pricing/pricing_provider.dart` (mới), rút gọn từ `project_phase2_core_architecture_alignment.md` mục 4.5:

```dart
abstract class PricingProvider {
  Future<List<HotelOffer>> searchHotels(HotelQuery query);
}

class HotelQuery { destination, checkIn, checkOut, guests, budgetTier }
class HotelOffer { hotelName, provider, fetchedAt, PriceQuote? quote, AiEstimate? estimate, String? deepLink }
class PriceQuote { num amount, String currency, DateTime expiresAt }
class AiEstimate { num amountMin, num amountMax, String currency }

PricingProvider pricingProvider = AiEstimateAdapter();
```

- Tiền trong khung này là `amount` số + `currency` mã, không phải chuỗi đã format. Hiển thị qua `CurrencyAmountText` hiện có.
- `AiEstimateAdapter`: một prompt nhỏ trong `GeminiService` trả 3-5 khách sạn gợi ý với khoảng giá mỗi đêm theo budget tier. Không cache.
- `MockProviderAdapter`: trả dữ liệu giả có cấu trúc thật (`provider: 'mock_partner'`, `deepLink`, `fetchedAt`, `quote`).
- `lib/widgets/shared/ai_estimate_badge.dart` (mới): nhãn "Ước tính AI" kèm thời điểm tạo. Dùng ở section chỗ ở, suggestions, và budget breakdown trong detail.
- `lib/screens/destination_detail_screen.dart`: thêm section "Chỗ ở" đọc qua `pricingProvider`; mỗi dòng có nhãn "Ước tính AI" hoặc "Báo giá đối tác (mock)". Bỏ hardcode `matchPercent: 98, rating: 4.5, reviewCount: 120` khi lưu, giữ giá trị gốc từ suggestion.

Đủ là dừng:
- Không gọi Amadeus, Booking, Agoda thật. Không Edge Function. Không lưu offer vào DB.

Nghiệm thu:
- [ ] Detail hiện hai loại giá phân biệt rõ bằng nhãn.
- [ ] Đổi `pricingProvider = MockProviderAdapter()` ở một dòng, UI không cần sửa và hiện cột "Báo giá đối tác".
- [ ] Test `HotelOffer.fromJson` và test `AiEstimateAdapter` parse JSON.

## 3. Thứ tự làm và phụ thuộc

| Bước | Hướng | Phụ thuộc | Lý do |
|---|---|---|---|
| 1 | 2.2 Cache | Không | Xoá code trước, giảm mặt tiếp xúc cho mọi việc sau |
| 1 | 2.3 Dữ liệu | Không | Nền cho mọi tính năng lưu trữ |
| 2 | 2.1 Planner | Không phụ thuộc 2.3 vì chạm file khác | Làm song song với 2.3 được |
| 3 | 2.4 Ảnh | Sau 2.1 (để không sửa widget trên form sắp xoá) | |
| 3 | 2.5 Giá | Sau 2.3 (cần `TripData` restore đúng để tính `HotelQuery`) | |

Mỗi hướng một nhánh (tên mô tả việc đang làm là đủ) và một PR. Không gộp hai hướng vào một PR.

## 4. Quy tắc bất biến

1. Không commit/push thẳng lên `master`. Nhánh + PR theo `AGENTS.md`.
2. `flutter analyze` không lỗi mới và `flutter test` pass trước khi mở PR.
3. Không hardcode URL ảnh trong code Dart. URL seed phải pass `dart run tool/verify_image_urls.dart`.
4. Supabase là nguồn dữ liệu chính. Hive chỉ là cache đọc.
5. Mọi số liệu do AI sinh (giá, rating, thời tiết) phải có nhãn ước tính, không lưu như dữ liệu thật.
6. Mọi lời gọi AI đi qua `GeminiService`. Screens không import `google_generative_ai`. Tách interface `AITravelGateway` là tuỳ chọn khi rảnh.
7. Prompt gửi Gemini viết tiếng Việt theo convention hiện có; chỉ dòng chỉ thị ngôn ngữ đầu ra thay đổi theo locale.

## 5. Không làm trong giai đoạn này

Bạn bè, chat xã hội, community reviews, presence. CDN ảnh và upload ảnh. Edge Function. Provider giá thật. Offline queue và tombstone. Collaborator và realtime mới. Cải tiến `chat_history_service`. Khái niệm `TripContext` riêng. Streaming AI.

## 6. Definition of done cho demo cuối khoá

- [ ] Một mạch demo liền: mô tả chuyến đi bằng lời -> chip -> gợi ý -> chi tiết có hai loại giá -> itinerary -> lưu -> đăng nhập máy khác thấy đúng.
- [ ] Hai chuyến cùng điểm đến khác ngày cùng tồn tại với itinerary riêng.
- [ ] Xoá trip ở máy A, máy B không thấy sống lại.
- [ ] Cache chỉ còn Memory + Hive theo user, có TTL; bảng `ai_generated_cache` và `CacheService` đã xoá.
- [ ] Mọi ảnh lỗi hiện cùng một fallback; verifier pass.
- [ ] `flutter analyze` không lỗi mới, `flutter test` pass với test mới của từng hướng.
- [ ] `README.md` có mục setup `.env` và cách chạy migration.

## 7. Gợi ý chia việc cho hai người

| | Bạn A | Bạn B |
|---|---|---|
| Thứ tự | 2.3 Dữ liệu -> 2.4 Ảnh | 2.2 Cache -> 2.1 Planner -> 2.5 Giá |
| File chính | `trip_data.dart`, `saved_trips_provider.dart`, `itinerary_plan.dart`, `saved_screen.dart`, migration `trip_identity`, `image_service.dart`, `destination_image.dart` | `ai_cache_service.dart`, `gemini_service.dart`, `smart_planner_screen.dart`, `trip_chips.dart`, `pricing/`, migration `drop_ai_generated_cache` |

Điểm giao duy nhất: `TripData` (A không đổi hình dạng, B chỉ thêm hàm trả về `TripData`) và `destination_detail_screen.dart` (A sửa phần restore dữ liệu, B thêm section chỗ ở). Ai xong trước nhận việc viết `README.md` setup.
