# Voyz giai đoạn 3: Roadmap hoàn thiện cuối khoá theo hướng AI-first và đơn giản hoá

> Ngày: 06/09/2026. Baseline: `master` sau merge PR #12 (commit `0e5bb51`).
> Tài liệu này THAY THẾ ba tài liệu cũ đã xoá khỏi repo: `project_review_supabase_integration.md` (23/08), `SUPABASE_INTEGRATION_ROADMAP.md` (roadmap học sinh), `week1_parallel_assignments.md` (30/08). Cần xem lại thì tra git history trước commit ngày 06/09/2026.
> Tài liệu nền vẫn còn hiệu lực, chỉ trỏ tới chứ không lặp lại: `project_phase2_core_architecture_alignment.md` (kiến trúc, mục 4.5 về giá thật), `lessons/2026-08-31-image-stability-walkthrough.md` (quy tắc ảnh), `superpowers/specs/2026-09-01-prompt-first-step1-design.md` (bước 1 planner đã làm).
> Cập nhật 27/09/2026: thêm hướng 2.6 (planner dạng chat, gợi ý theo phương án chuyến đi). Hướng này thay mục "Đủ là dừng" về hội thoại của 2.1.

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

## 2. Các hướng hoàn thiện

### 2.1. Smart Planner AI-first: một ô mô tả và hàng chip xác nhận

> Trạng thái 27/09/2026: đã xong trong PR #15, bản cuối bỏ bước chip (bấm "Gợi ý" là trích xuất rồi mở gợi ý ngay). Luồng planner tiếp theo xem 2.6; dòng "không hội thoại nhiều vòng, không AI hỏi lại" bên dưới không còn áp dụng.

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

### 2.6. Planner dạng chat và gợi ý theo phương án chuyến đi

**Mục tiêu:** planner trở thành trải nghiệm agent-first giống Gemini. Người dùng mô tả chuyến đi, AI hỏi thêm khi thiếu thông tin quan trọng, rồi đưa vài phương án chuyến đi ngay trong chat. Mỗi phương án là một lộ trình tổng quan nhiều điểm dừng, không phải một địa điểm lẻ.

Vì sao:
- Prompt gợi ý hiện tại bắt AI trả đúng 8 "điểm đến" cấp thành phố, và chỉ coi điểm đến người dùng nêu là "mong muốn". Với điểm đến nhỏ như Côn Đảo, AI lấp chỗ trống bằng Đà Nẵng, Phú Quốc.
- Người dùng thường đã biết đi đâu ("4 ngày 3 đêm Nha Trang", "1 tuần Côn Đảo"). Họ cần hình dung chuyến đi trông thế nào, không cần danh sách 8 nơi.

Phạm vi: chỉ thay màn planner và màn gợi ý bằng một màn chat. Chạm vào một phương án mở `DestinationDetailScreen` giống như chạm một gợi ý hôm nay. Mọi màn sau đó giữ nguyên.

```text
Ô prompt -> gửi -> màn chuyển thành chat
  -> AI hỏi thêm (tối đa 1 câu mỗi lượt, tối đa 2 lượt) hoặc trả phương án ngay
  -> 3 thẻ phương án trong chat
  -> người dùng nhắn tiếp để chỉnh ("rẻ hơn", "thêm lặn biển") hoặc chọn 1 thẻ
  -> DestinationDetailScreen (không đổi) -> itinerary (không đổi)
```

Làm gì:
- `lib/services/gemini_service.dart`: thêm `planTurn(List<PlannerMessage> messages, {bool forceOptions, String languageCode})` với `responseSchema`. Mọi lượt trả cùng một JSON:

```json
{
  "reply": "câu trả lời hoặc câu hỏi ngắn",
  "trip": { "destination": null, "departDate": null, "returnDate": null, "numDays": null,
            "budgetTier": null, "participants": null, "interests": [] },
  "options": []
}
```

  - `options` là mảng rỗng khi AI đang hỏi, là mảng 3 phần tử khi đưa phương án. Mỗi phần tử: `title` (chủ đề), `destination` (điểm đến gốc, dạng "Côn Đảo, Việt Nam"), `numDays`, `stops` (3-5 địa danh theo thứ tự đi), `imageStop` (một địa danh tiêu biểu nhất cho chủ đề), `price` (ước tính), `aiInsight` (một câu).
  - Lượt của AI đưa lại vào `history` dưới dạng JSON gốc, để lượt sau AI biết mình đã hỏi gì và đã đưa phương án nào.
  - Parser thuần, test được, dùng lại phần xử lý ngày của `parseExtractedTripData`. Không cache hàm này.
- Quy tắc trong prompt:
  - Chỉ cần hai thứ để đưa phương án: điểm đến (hoặc kiểu chuyến như "đi biển") và độ dài chuyến. Thiếu thì hỏi. Đủ thì trả phương án ngay, không hỏi thêm.
  - Tối đa 1 câu hỏi mỗi lượt, tối đa 2 lượt hỏi. Sau đó bắt buộc đưa phương án và nói rõ đã giả định gì ("Mình giả định 3N2Đ, 2 người").
  - Người dùng đã nêu điểm đến thì cả 3 phương án phải nằm trong điểm đến đó, khác nhau ở chủ đề hoặc nhịp đi. Chưa nêu thì mỗi phương án có thể là một điểm đến khác.
  - `stops` và `imageStop` phải là địa danh có tên riêng, không dùng tên chung như "bãi biển", "chợ đêm". `imageStop` của 3 phương án phải khác nhau.
- Độ dài chuyến lấy từ bất cứ gì người dùng nói: ngày đi và ngày về, hoặc thời lượng ("4 ngày 3 đêm", "1 tuần", "cuối tuần").
  - `lib/data/trip_data.dart`: `TripData` thêm `int? numDays`, có trong `toMap`, `fromMap`, `copyWith`. `trip_data` trên Supabase là jsonb nên không cần migration.
  - `dayCount()`: có ngày đi và ngày về thì tính theo ngày; không có thì dùng `numDays`; không có nữa mới dùng fallback. Giữ giới hạn tối đa 7 ngày.
  - `parseExtractedTripData` đang bỏ `numDays` khi không có ngày đi: sửa để luôn giữ lại.
- `lib/models/plan_turn.dart` (mới): `TripOption`, `PlanTurn`, `PlannerMessage`. `DestinationSuggestion` giữ nguyên cho Explore. Spec chi tiết: `docs/superpowers/specs/2026-09-27-planner-chat-design.md`.
- `lib/screens/smart_planner_screen.dart`:
  - Trạng thái ban đầu giữ ô prompt và quick prompt hiện có. Sau lượt gửi đầu, màn chuyển thành danh sách tin nhắn, ô nhập ở đáy và nút "Gợi ý luôn" (buộc AI đưa phương án ở lượt kế tiếp).
  - Tin nhắn AI có `options` thì hiện thẻ phương án ngay dưới câu trả lời.
  - Hội thoại chỉ nằm trong state của màn, không lưu.
- Thẻ phương án: tiêu đề kèm thời lượng ("Côn Đảo 4N3Đ · Biển & lặn"), một dòng lộ trình nối `stops` bằng "→", giá có nhãn "Ước tính AI", một dòng insight, một ảnh. Không rating, không `reviewCount`, không `matchPercent`.
- Chọn thẻ:
  - `updateTrip()` với `TripData` của lượt cuối.
  - `aiPrompt` = các tin nhắn của người dùng nối lại, cộng "Phương án đã chọn: {title}, lộ trình: {stops}". Code tự ghép, không gọi AI thêm.
  - `recordTripSearch()`, rồi mở `DestinationDetailScreen(destinationName: option.destination)`. Màn chi tiết và itinerary đã đọc `currentTrip.aiPrompt` nên không phải sửa, và itinerary sẽ bám theo lộ trình đã chọn.
- Ảnh cho thẻ:
  - Tra `"{imageStop}, {destination}"` qua `ImageService.getImageUrl`, giống cách `getLandmarkPhotos` đang làm.
  - Không có ảnh, hoặc URL trùng với thẻ khác, thì thử lần lượt các `stops` còn lại. Hết mới dùng ảnh của `destination`.
- Xoá sau khi luồng mới chạy: `lib/screens/suggestions_screen.dart`, `getSuggestions`, `buildSuggestionsPrompt`, `extractTripData` (nếu `planTurn` đã thay hết), cùng test và key l10n chỉ phục vụ chúng. Giữ `enrichSuggestionsWithImages` vì Explore còn dùng. Compare vẫn mở được từ AI tools.

Đủ là dừng:
- Không streaming. Không lưu hội thoại planner, không đụng `chat_history_service`.
- Không đổi `DestinationDetailScreen` và `DestinationPlanScreen`. Giá trên thẻ và giá ở màn chi tiết có thể lệch nhau (cả hai đều là ước tính), để sửa sau.
- Không thêm nguồn ảnh mới, không dải ảnh nhiều điểm dừng trên thẻ.
- Không gộp với `ChatScreen` hiện có.
- Mỗi lần đưa 3 phương án, không "xem thêm", không phân trang.

Nghiệm thu:
- [ ] "Du lịch Côn Đảo" -> AI hỏi độ dài chuyến (hoặc giả định và nói rõ). Cả 3 phương án đều ở Côn Đảo, không có Đà Nẵng hay nơi khác.
- [ ] "4 ngày 3 đêm Nha Trang" -> có phương án ngay ở lượt đầu, không hỏi lại. Mỗi thẻ ghi 4N3Đ và có lộ trình nhiều điểm dừng.
- [ ] "Muốn đi biển 1 tuần" -> 3 phương án ở 3 điểm đến khác nhau.
- [ ] Có phương án rồi nhắn "rẻ hơn" -> ra bộ phương án mới trong cùng chat.
- [ ] Bấm "Gợi ý luôn" khi AI đang hỏi -> có phương án ở lượt kế tiếp.
- [ ] 3 thẻ hiện 3 ảnh khác nhau.
- [ ] "1 tuần Côn Đảo" không nêu ngày -> itinerary 7 ngày. "Từ 10/10 đến 13/10" -> itinerary 4 ngày.
- [ ] Chọn một thẻ -> mở màn chi tiết như hôm nay; itinerary bám theo lộ trình của thẻ đã chọn.
- [ ] Test: parser của `planTurn` (lượt hỏi, lượt có phương án, thiếu key); `dayCount` với ngày đi/về, với `numDays`, với không có gì.

## 3. Thứ tự làm và phụ thuộc

| Bước | Hướng | Phụ thuộc | Lý do |
|---|---|---|---|
| 1 | 2.2 Cache | Không | Xoá code trước, giảm mặt tiếp xúc cho mọi việc sau |
| 1 | 2.3 Dữ liệu | Không | Nền cho mọi tính năng lưu trữ |
| 2 | 2.1 Planner | Không phụ thuộc 2.3 vì chạm file khác | Làm song song với 2.3 được |
| 3 | 2.4 Ảnh | Sau 2.1 (để không sửa widget trên form sắp xoá) | |
| 3 | 2.5 Giá | Sau 2.3 (cần `TripData` restore đúng để tính `HotelQuery`) | |
| 4 | 2.6 Planner chat | Sau 2.1 | Thay màn planner và màn gợi ý; không chạm màn chi tiết nên làm song song với 2.5 được |

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

- [ ] Một mạch demo liền: mô tả chuyến đi bằng lời -> chat (AI hỏi thêm nếu cần) -> chọn phương án -> chi tiết có hai loại giá -> itinerary -> lưu -> đăng nhập máy khác thấy đúng.
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

## 8. Ghi chú xem lại sau khi xong 2.4 (thêm ngày 19/09/2026)

Nghiên cứu `docs/research/2026-09-19-gemini-image-sources.md` kết luận: Gemini không thay được Wikipedia làm nguồn ảnh (free tier không có grounding cho model 3.x, ảnh sinh ra là ảnh giả có watermark, URL do model nhớ ra là bịa). Kiến trúc ảnh giữ nguyên như mục 2.4.

Hai việc ghi lại để quyết định sau, KHÔNG làm trong nhánh ảnh:

1. **Package `google_generative_ai` đã ngừng phát triển** (đóng băng ở 0.4.7, chỉ có function calling và code execution). Đường chuyển đổi chính thức là `firebase_ai` (có `Tool.googleSearch()`, `Tool.googleMaps()`, `Tool.urlContext()`, nhưng cần Firebase project). Chỉ cân nhắc khi app thật sự cần một tool của Gemini; hiện tại chưa cần. Đây là quyết định riêng, không liên quan tới ảnh.
2. **Wikimedia đã chuyển host thumbnail** của REST summary sang `thumb.wikimedia.org`. Regex trong `tool/verify_image_urls.dart` chỉ nhận `upload.wikimedia.org` và `commons.wikimedia.org`, nên sẽ bỏ qua URL seed mới trên host này. Chưa ảnh hưởng render vì `lib/` không còn allowlist host. Sửa verifier khi có đợt cập nhật seed kế tiếp.
