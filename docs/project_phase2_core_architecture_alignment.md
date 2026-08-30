# Voyz Phase 2: Hệ thống lại khung kiến trúc trước khi hoàn thiện demo cuối khóa

> Ngày: 30/08/2026
> Phạm vi review: các commit từ `539ae23` đến `27532d6` (10 commit, đều đẩy chủ nhật 23/08/2026)
> Tài liệu liên quan: `project_review_supabase_integration.md` (review 23/08), `SUPABASE_INTEGRATION_ROADMAP.md` (roadmap học sinh tự viết)
> Mục đích: đây KHÔNG phải tài liệu làm thay. Đây là bộ khung kiến trúc và các điểm mấu chốt để học sinh tự hệ thống lại và hoàn thiện trong 2-3 tuần tới.

---

## 1. Đánh giá phần học sinh cập nhật chủ nhật 23/08

### 1.1. Những gì đã làm được (đáng ghi nhận)

Học sinh đã chuyển từ cách làm ngẫu hứng sang có kế hoạch: tự viết roadmap, chia task theo sprint, có commit message rõ ràng và thêm 3 file test mới. Về kỹ thuật:

| Hạng mục | Việc đã làm | Nhận xét |
|---|---|---|
| Search history | `SearchHistoryService` ghi song song Hive + Supabase, đọc ưu tiên Supabase, có delete và clear | Đúng hướng "Supabase là nguồn chính". Khép lại tích hợp dở dang từ review trước |
| Saved trips sync | Migration `saved_trips` + `saved_itineraries` với RLS chuẩn `auth.uid() = user_id`, index hợp lý; `SavedTripsProvider` load cloud, merge với local, đẩy item local chưa có lên cloud | Bước tiến lớn nhất tuần này. Dữ liệu chuyến đi lần đầu tiên lên backend |
| Friend chat realtime | Bỏ polling 4 giây, dùng `supabase.stream()` trong `FriendChatScreen`, hủy subscription khi dispose | Giải quyết đúng phát hiện P1.5 của review trước |
| AI cache 3 tầng | `AiCacheService` mới: Memory, Hive, Supabase `ai_generated_cache`; key MD5 deterministic; tương thích ngược box cũ | Ý tưởng tốt cho tốc độ demo. Nhưng có vấn đề bảo mật và tính đúng, xem 1.2 |
| Budget tiers | Thay ô nhập số tiền bằng 4 phân khúc (economy, moderate, premium, luxury) kèm mô tả chi phí thực tế trong prompt | Đơn giản hóa UX đúng hướng, prompt được "ground" tốt hơn |
| Image service | Bộ URL Wikimedia được kiểm tra tay theo điểm đến, pre-cache ảnh vào cache AI, fallback chain | Cải thiện demo rõ rệt; về lâu dài đây là dữ liệu nên nằm ở DB, không nằm trong code |
| CI/CD | Workflow build Flutter web và deploy GitHub Pages | Có tư duy DevOps, nhưng tạo ra rủi ro lộ key, xem 1.2 |
| Tests | `saved_trips_sync_test`, `ai_cache_service_test`, `search_history_service_test` | Bắt đầu có thói quen test cho tầng dữ liệu |

### 1.2. Những lỗ hổng còn lại sau cập nhật (điểm cần hệ thống lại)

Đây là những điểm quan trọng nhất, vì chúng nằm ở tầng kiến trúc chứ không phải tầng tính năng.

**(A) Identity của chuyến đi vẫn là chuỗi tên, chưa phải UUID.**
DB mới có cột `id uuid` nhưng client không dùng. Ràng buộc unique là `(user_id, name)`, itinerary vẫn key theo `destination_name`, và `SavedItem` trong Dart vẫn không có `id`. Hệ quả: bài toán "đi Đà Nẵng tháng 6 với gia đình, đi Đà Nẵng tháng 12 với bạn" vẫn bị coi là một chuyến. Đây là nợ domain lớn nhất, mọi tính năng sau này (nhiều itinerary version, share, báo giá theo chuyến) đều tựa lên identity này.

**(B) Sync mới chỉ là "merge cộng dồn", chưa có ngữ nghĩa xóa và xung đột.**
Trong `_syncFromSupabase`: item local chưa có trên cloud sẽ được đẩy lên lại. Nghĩa là item đã xóa trên thiết bị B sẽ "sống lại" khi thiết bị A sync. Ghi lên cloud là fire-and-forget, không so `updated_at`, không có hàng đợi khi offline, ai ghi sau thắng. Với demo một thiết bị thì chạy được, nhưng chính tính năng "đồng bộ đa thiết bị" đang quảng bá lại chưa đúng.

**(C) Bảng `ai_generated_cache` đang mở cho cả thế giới ghi.**
Policy hiện tại cho `anon` và `authenticated` select, insert, update với `check (true)`. Bất kỳ ai có publishable key (nằm sẵn trong web build công khai) đều có thể ghi đè payload cache mà mọi user khác sẽ đọc. Đây là cache poisoning: kết quả AI hiển thị cho cả lớp có thể bị bên ngoài sửa. Thêm vào đó:
- Cache key của suggestions vẫn thiếu ngày đi, số người, độ tuổi, notes và aiPrompt, trong khi prompt có dùng chúng. Trước đây lỗi này chỉ rò rỉ giữa các user trên cùng máy; giờ cache lên cloud dùng chung, kết quả cá nhân hóa của user này có thể phục vụ user khác trên toàn hệ thống.
- Không có TTL. Explore dùng `nonce` theo thời gian khi force refresh, mỗi lần bấm refresh tạo một dòng cache mới không bao giờ được đọc lại, bảng sẽ phình rác vĩnh viễn.

**(D) Deploy GitHub Pages đóng gói `GEMINI_API_KEY` vào asset công khai.**
Workflow tạo `.env` từ secrets rồi build web và publish lên Pages. Secrets của GitHub chỉ bảo vệ lúc build; sản phẩm build ra là trang tĩnh công khai, ai cũng tải được file asset chứa key. Chưa cần Edge Function ngay (xem mục 2), nhưng tối thiểu phải: dùng key demo riêng có quota cap thấp, bật giới hạn trong Google AI Studio/Cloud console, và chấp nhận rõ ràng rằng key đó coi như công khai. Không dùng key "xịn" cho pipeline này.

**(E) Số liệu AI bịa vẫn được lưu như dữ liệu thật.**
Prompt mới còn yêu cầu AI sinh "reviewCount thực tế 300-4500" và "rating 4.2-4.9", tức là ép AI bịa cho giống thật hơn. Các con số này sau đó được lưu vào `saved_trips` như master data. Hướng đúng là dán nhãn "ước tính AI" và tách kênh dữ liệu giá thật (mục 5).

**(F) Roadmap của học sinh đang lệch trọng tâm.**
Sprint 2 trong `SUPABASE_INTEGRATION_ROADMAP.md` dồn vào chat threads, collaborative workspace, community reviews, presence online/offline. Đây đều là tính năng mạng xã hội, không phải giá trị lõi của một app tư vấn du lịch AI. Cần điều chỉnh lại như mục 3.

---

## 2. Các quyết định định hướng đã chốt (từ giáo viên)

Học sinh dùng các quyết định này làm luật khi phân vân:

1. **Gemini chưa cần tách về Supabase Edge Function.** Giữ Gemini dưới dạng một class service duy nhất là đủ cho giai đoạn này, miễn là toàn bộ AI call đi qua một cửa (không screen nào gọi model trực tiếp, không client nào tự chọn model/temperature). Viết đúng dạng interface + adapter thì sau này migrate sang Edge Function chỉ là thay một adapter. Điều kiện đi kèm: xử lý mục 1.2(D) về key trên web build công khai.
2. **Supabase là nguồn dữ liệu chính, nhất quán theo luồng nghiệp vụ tư vấn du lịch.** Auth, profile, yêu cầu du lịch (search history), chuyến đi đã lưu, itinerary, hội thoại AI gắn chuyến đi: tất cả lấy Supabase làm source of truth. Hive chỉ còn hai vai trò: cache đọc để mở app nhanh, và hàng đợi ghi khi offline.
3. **Tập trung tính năng lõi tư vấn du lịch AI. Đóng băng mảng bạn bè, chat xã hội, community reviews.** Những gì đã chạy (friends, friend chat realtime) giữ nguyên, không mở rộng, không làm presence, không làm reviews cộng đồng trong phase này.
4. **Xây một trải nghiệm AI liền lạc xuyên suốt.** AI phải "nhớ" người dùng đang lo cho chuyến đi nào ở mọi màn hình, thay vì mỗi màn hình là một lần hỏi AI rời rạc.
5. **Kiến trúc phải mở đường cho dữ liệu giá thật.** Giá khách sạn, báo giá cụ thể phải đến từ provider đáng tin cậy (Agoda, Booking hoặc aggregator), AI chỉ tư vấn và giải thích. Chưa cần tích hợp thật trong 2-3 tuần này, nhưng khung code phải sẵn chỗ cắm.

---

## 3. Luồng nghiệp vụ lõi cần hệ thống lại

Mọi thứ trong app phải xếp được vào một bước của luồng này. Tính năng nào không nằm trên luồng thì hoãn.

```text
[1] Đăng nhập (Supabase Auth)
        |
[2] Hồ sơ + sở thích du lịch (profiles)          <- nguồn: Supabase
        |
[3] Nhập yêu cầu du lịch (Smart Planner)
        |  lưu thành TravelRequest / search_history <- nguồn: Supabase
        v
[4] AI gợi ý điểm đến (AITravelGateway -> Gemini)
        |  kết quả là ƯỚC TÍNH, có nhãn, có generated_at
        v
[5] Xem chi tiết điểm đến + hỏi đáp AI trong ngữ cảnh chuyến đi
        |
[6] Chốt thành Trip (id UUID, owner, ngày, phân khúc ngân sách)  <- nguồn: Supabase
        |
[7] AI tạo/refine Itinerary (nhiều version, gắn trip_id)          <- nguồn: Supabase
        |
[8] Workspace: checklist, ghi chú, mã booking                     <- nguồn: Supabase
        |
[9] (Tương lai) Báo giá khách sạn thật qua PricingProvider port
```

Bước 1, 2, 3 phần lớn đã có. Bước 4-8 đã có UI và một phần sync nhưng chưa có identity và ngữ nghĩa dữ liệu đúng. Bước 9 chỉ cần dựng khung interface trong phase này.

---

## 4. Khung kiến trúc mục tiêu

### 4.1. Module và ranh giới

```text
Flutter Screens (UI, không chứa business logic, không gọi Supabase/Gemini trực tiếp)
    |
    +--> TripRepository (interface)
    |       +--> SupabaseTripAdapter   : source of truth
    |       +--> HiveTripCacheAdapter  : cache đọc + hàng đợi ghi offline
    |
    +--> AITravelGateway (interface)   : suggestions, itinerary, chat, detail
    |       +--> GeminiAdapter         : hiện tại (class service, key ở client)
    |       +--> (sau này) EdgeFunctionAdapter : migrate không đổi UI
    |       +--> FakeAdapter           : cho test
    |
    +--> PricingProvider (interface)   : tìm khách sạn, lấy báo giá
    |       +--> AiEstimateAdapter     : hiện tại, kết quả dán nhãn "ước tính AI"
    |       +--> (sau này) Agoda/Booking/aggregator adapter
    |
    +--> ProfileRepository             : profiles trên Supabase
    |
    +--> Social (đóng băng)            : giữ nguyên friends_service hiện có
```

Nguyên tắc bắt buộc:

- Screen chỉ biết interface, không biết Supabase hay Gemini tồn tại. Kiểm tra nhanh: xóa import `supabase_flutter` và `google_generative_ai` khỏi thư mục `screens/` mà vẫn compile được là đạt.
- Không tạo lớp pass-through vô nghĩa. Một interface chỉ đáng tồn tại khi nó che được serialization, cache, retry hoặc business rule cho nhiều màn hình.

### 4.2. Quy tắc nguồn dữ liệu (source of truth)

| Dữ liệu | Nguồn chính | Vai trò của Hive/local |
|---|---|---|
| Tài khoản, session | Supabase Auth | Không |
| Profile, sở thích du lịch, tiền tệ mặc định | Bảng `profiles` | Cache đọc |
| Yêu cầu du lịch / search history | `search_history` | Cache đọc + queue offline, box phải scope theo user |
| Trip, wishlist, checklist, notes, booking refs | `trips` (nâng cấp từ `saved_trips`) | Cache đọc + queue offline |
| Itinerary | `itinerary_versions` gắn `trip_id` | Cache đọc |
| Hội thoại AI gắn chuyến đi | Supabase (khi làm bước 6 tuần 3) | Cache đọc |
| AI cache (suggestions, explore, detail) | Cache là cache, KHÔNG phải dữ liệu nghiệp vụ | Memory + Hive có TTL; tầng Supabase chỉ giữ nếu sửa xong RLS |
| UI state, tab, draft đang gõ, ảnh cache, nhạc nền | Client | Toàn quyền local |

### 4.3. Sửa domain model tối thiểu (không viết lại từ đầu)

Tận dụng bảng `saved_trips` đã có, chỉ cần nắn lại:

1. `SavedItem` (nên đổi tên dần thành `Trip`) thêm trường `id` (UUID, do client generate hoặc lấy từ DB khi insert). Mọi upsert, delete, navigation đều theo `id`, không theo `name`.
2. Bỏ unique `(user_id, name)`, thay bằng khóa chính `id`. Cho phép hai chuyến cùng tên.
3. `saved_itineraries` đổi khóa từ `(user_id, destination_name)` sang `trip_id`, mỗi lần AI generate/refine là một version mới (`version integer`, `is_current boolean`), lưu kèm `generated_at` và `prompt_version`.
4. Khi mở một trip đã lưu, màn hình detail phải restore đúng `trip.tripData` của trip đó, không dùng `currentTrip` toàn cục (lỗi này đã nêu ở review 23/08, hiện vẫn còn).
5. Ngữ nghĩa sync: cloud thắng. Load là cloud-first; local chỉ đẩy lên những bản ghi có `updated_at` mới hơn bản cloud; xóa là xóa trên cloud trước, local theo sau (hoặc thêm cột `deleted_at` làm tombstone nếu muốn hỗ trợ xóa offline).

### 4.4. Trải nghiệm AI liền lạc (gợi ý thiết kế)

Vấn đề hiện tại: mỗi màn hình gọi Gemini với một prompt độc lập, người dùng cảm giác app "hỏi AI nhiều lần" chứ không phải "một trợ lý theo suốt chuyến đi".

Khung đề xuất, gọn đủ cho 1 tuần làm:

- Tạo khái niệm `TripContext`: destination, ngày, phân khúc ngân sách, số người, sở thích, và tóm tắt các quyết định đã chốt (đã chọn điểm đến X, đã có itinerary version N).
- `AITravelGateway` nhận `TripContext` trong MỌI lời gọi: suggestions, detail, itinerary, chat. Một hàm private duy nhất dựng phần ngữ cảnh của prompt, các feature chỉ thêm phần câu hỏi riêng.
- Màn hình chat AI mặc định mở trong ngữ cảnh trip đang xem ("Hỏi thêm về chuyến Đà Nẵng của bạn"), thay vì chat trống. Nút gợi ý câu hỏi tiếp theo sinh từ trạng thái trip (chưa có itinerary thì gợi ý tạo, có rồi thì gợi ý refine).
- Mọi output AI hiển thị kèm nhãn "Ước tính bởi AI" + thời điểm tạo. Một widget nhãn dùng chung, làm một lần.
- Lịch sử hội thoại gắn `trip_id` khi đưa lên Supabase, để mở máy khác vẫn tiếp mạch tư vấn.

### 4.5. Kiến trúc cho báo giá thật (Agoda, Booking)

Trả lời câu hỏi "app nên theo hướng nào để dùng được API tìm khách sạn, lấy giá thật thay vì giá từ AI":

**Thực tế về nguồn dữ liệu.** Agoda và Booking.com không có API công khai tự do; họ cấp qua chương trình affiliate/partner (Booking.com Affiliate Partner Programme, Agoda Affiliate API) và duyệt theo đối tác. Con đường khả thi cho dự án học tập và cả sản phẩm nhỏ: aggregator như Amadeus Self-Service API (có tier miễn phí, có Hotel Search/Offers), Travelpayouts, hoặc các hotel API trên RapidAPI. Tất cả đều trả về cùng một dạng dữ liệu: danh sách khách sạn + offer có giá, tiền tệ, ngày, điều kiện, và deep link đặt phòng.

**Hệ quả kiến trúc.** Vì mọi provider đều quy về cùng một hình dạng dữ liệu, điều duy nhất cần làm NGAY trong phase này là tách hai khái niệm và dựng một port:

- `AiEstimate`: con số AI sinh ra. Chỉ để tham khảo, luôn có nhãn, không bao giờ lưu như dữ liệu thật.
- `PriceQuote`: báo giá thật. Bắt buộc có `provider`, `fetched_at`, `currency`, `deep_link`. Có thể hết hạn.

```dart
abstract class PricingProvider {
  Future<List<HotelOffer>> searchHotels(HotelQuery query);
}

class HotelQuery {
  final String destination;      // sau này là geo id/lat-lng của provider
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final String budgetTier;       // economy | moderate | premium | luxury
}

class HotelOffer {
  final String hotelName;
  final PriceQuote? quote;       // null khi chỉ có ước tính AI
  final AiEstimate? estimate;
  final String provider;         // 'ai_estimate' | 'amadeus' | 'booking' ...
  final DateTime fetchedAt;
  final String? deepLink;
}
```

Trong 2-3 tuần tới chỉ cần: (1) interface trên + `AiEstimateAdapter` bọc phần giá AI hiện có, (2) UI phần chi phí trong destination detail đọc qua `PricingProvider` thay vì đọc thẳng JSON của Gemini, (3) một `MockProviderAdapter` trả dữ liệu giả có cấu trúc thật để demo được cột "giá từ đối tác". Khi có tài khoản Amadeus/affiliate thật, chỉ viết thêm một adapter, không đụng UI. Ngoài ra vì các API này yêu cầu secret key thật sự, provider thật sẽ là lý do tự nhiên để bật Edge Function sau này (secret nằm ở server), đúng lộ trình "migrate bất kỳ lúc nào" của quyết định số 1.

---

## 5. Các việc mấu chốt trong 2-3 tuần tới

Nguyên tắc chọn việc: sửa khung trước, thêm tính năng sau. Không nhận task mới ngoài danh sách nếu chưa xong nhóm trước đó.

### Tuần 1: Identity và ranh giới module

- [ ] Thêm `id` UUID vào model trip phía Dart; mọi thao tác lưu/xóa/mở theo `id`. Migration DB bỏ unique `(user_id, name)`.
- [ ] Itinerary gắn `trip_id`, hỗ trợ nhiều version; hai trip cùng destination không còn đè nhau.
- [ ] Mở trip đã lưu phải restore đúng dữ liệu của trip đó (bỏ phụ thuộc `currentTrip` toàn cục).
- [ ] Gom mọi lời gọi Gemini về một interface `AITravelGateway`; screens không import Supabase/Gemini trực tiếp.
- [ ] Xử lý key trên web build: dùng key demo quota thấp cho GitHub Pages hoặc tắt auto-deploy; ghi rõ trong README.

### Tuần 2: Sync đúng và cache đúng

- [ ] Sync cloud-first: cloud là source of truth, so `updated_at`, xóa không bị hồi sinh, có xử lý khi offline (tối thiểu: báo và retry, khá hơn: hàng đợi ghi).
- [ ] Sửa RLS `ai_generated_cache`: bỏ quyền ghi của `anon`; cân nhắc chỉ cho đọc shared cache còn ghi thì thu hẹp; thêm TTL (`expires_at` + lọc khi đọc) và dọn rác entry nonce.
- [ ] Cache key chứa đủ input ảnh hưởng kết quả (ngày, số người, độ tuổi, notes, aiPrompt, prompt version); kết quả cá nhân hóa không đưa vào shared cloud cache.
- [ ] Hive box search history và AI cache scope theo user id.
- [ ] Test cho: cache key, sync xóa, hai trip cùng tên.

### Tuần 3: Trải nghiệm AI liền lạc và khung giá thật

- [ ] `TripContext` xuyên suốt planner, suggestions, detail, itinerary, chat; chat AI mở theo ngữ cảnh trip.
- [ ] Nhãn "Ước tính bởi AI" + `generated_at` trên mọi số liệu AI; bỏ hardcode `matchPercent = 98`, `rating = 4.5` khi lưu.
- [ ] `PricingProvider` interface + `AiEstimateAdapter` + `MockProviderAdapter`; UI chi phí đọc qua port này.
- [ ] Hội thoại AI của trip lưu lên Supabase (bảng `ai_conversations`/`ai_messages` tối giản) nếu còn thời gian; không thì để lại ghi chú TODO rõ ràng.
- [ ] Dọn demo: README setup, seed một tài khoản demo, kịch bản demo đi đúng luồng mục 3.

### Không làm trong phase này (đóng băng có chủ đích)

- Presence online/offline, community reviews, rating cộng đồng, share trip card vào chat, destination CDN (TASK-SB-05, 06, 07, 08 trong roadmap của học sinh).
- Tách Gemini về Edge Function (chỉ chuẩn bị seam, không migrate).
- Tích hợp provider giá thật (chỉ dựng port + mock).

---

## 6. Tiêu chí demo cuối khóa đạt yêu cầu (definition of done)

1. Đăng nhập trên hai trình duyệt/thiết bị: cùng danh sách trip, sửa checklist bên này thấy bên kia sau khi reload (realtime là điểm cộng, không bắt buộc).
2. Tạo được hai chuyến cùng điểm đến với ngày khác nhau, mỗi chuyến giữ đúng itinerary riêng.
3. Xóa trip trên thiết bị A, thiết bị B không thấy trip sống lại.
4. Một mạch demo liền: nhập yêu cầu, nhận gợi ý, hỏi AI trong ngữ cảnh, chốt trip, tạo itinerary, refine itinerary, mọi số liệu AI có nhãn ước tính.
5. Màn hình chi phí có hai loại giá phân biệt rõ: ước tính AI và "báo giá đối tác" (từ mock adapter), chứng minh khung PricingProvider hoạt động.
6. `flutter analyze` không lỗi mới, các test hiện có + test mới của tuần 2 pass.

## 7. Câu hỏi còn chờ chốt (học sinh trả lời trước khi code tuần 2)

1. Xóa offline có cần không, hay chấp nhận "xóa cần mạng"? (Quyết định này chọn giữa tombstone và xóa cloud-first.)
2. Shared AI cache trên cloud giữ lại hay bỏ hẳn, chỉ dùng Memory + Hive có TTL? (Bỏ thì đơn giản và an toàn hơn nhiều; giữ thì phải làm phần RLS + TTL cho đúng.)
3. Dữ liệu Hive cũ của các máy đang test: migrate lên cloud một lần hay reset sạch làm dữ liệu demo mới?
4. AI chat history có bắt buộc sync đa thiết bị trong demo không, hay để local và ghi vào mục "hướng phát triển"?
