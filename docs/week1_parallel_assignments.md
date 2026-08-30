# Tuần 1: Giao việc song song cho 2 bạn (kèm hợp đồng chung đã chốt)

> Ngày giao: 30/08/2026 (cập nhật lần 2 tối 30/08, sau khi review PR #9). Thời hạn: 1 tuần, giáo viên review cuối tuần.
> Baseline code: master sau merge PR #9 (commit `4661929`). Hai bạn tạo nhánh từ master MỚI NHẤT, không dùng checkout cũ.
> Tài liệu nền: `project_phase2_core_architecture_alignment.md` (đọc mục 3 và 4 trước khi bắt đầu).
> File này là NGUỒN DUY NHẤT của tuần 1. Cả hai bạn load nguyên file này vào AI agent của mình. Mỗi bạn chỉ làm phần của mình, phần còn lại đọc để hiểu ngữ cảnh.

## 0. Cách làm việc chung (bắt buộc)

1. Mỗi bạn một nhánh từ `master` mới nhất:
   - Bạn A: `week1/trip-identity`
   - Bạn B: `week1/ai-gateway`
2. Chỉ sửa file trong danh sách "Files sở hữu" của mình. Cần sửa file của bạn kia thì KHÔNG tự sửa, ghi TODO comment và nhắn nhau.
3. Hợp đồng ở mục 1 là bất biến trong tuần. Muốn đổi bất kỳ chữ ký hàm hoặc tên cột nào trong hợp đồng phải hỏi giáo viên trước.
4. Trước khi mở PR: `flutter analyze` không lỗi mới, `flutter test` pass toàn bộ.
5. Commit nhỏ, message rõ ràng. Cuối tuần mỗi bạn một PR vào `master`.
6. Thứ tự merge: PR của bạn A merge trước, bạn B rebase lên rồi merge sau (xung đột nếu có sẽ chỉ nằm ở phần import và call site trong `screens/`, bạn B tự resolve).
7. Checkpoint giữa tuần (ngày 3): hai bạn chạy thử nhánh của nhau 15 phút, xác nhận không dẫm chân.
8. ĐÓNG BĂNG SCOPE trong tuần 1: không làm thêm bất kỳ tính năng nào thuộc sprint 2/3 của roadmap cũ (community reviews, trip_collaborators, destinations repository, chat threads, presence). Phần đã merge trong PR #9 (commit `b1642aa`) giữ nguyên hiện trạng, không mở rộng, không sửa trừ khi việc tuần 1 bắt buộc chạm vào.

## 0.1. Hiện trạng sau PR #9 (đọc để hiểu ngữ cảnh, KHÔNG phải việc để làm)

PR #9 đã đưa vào master các phần sau. Tất cả được giữ nguyên và đóng băng trong tuần 1:

| Phần mới | Nội dung | Ảnh hưởng đến tuần 1 |
|---|---|---|
| Bảng `profiles` + trigger sync từ Auth | Sở thích du lịch, tiền tệ mặc định; Smart Planner tự điền từ profile | Không ảnh hưởng, hai bạn không đụng |
| `chat_threads` / `chat_messages` + cloud sync trong `chat_history_service.dart` | Một thread cho mỗi (user, destination) | Không ảnh hưởng tuần 1 |
| `trip_collaborators` + mở rộng RLS `saved_trips` cho collaborator | `addSharedPerson` giờ tạo collaborator row thật; select/update `saved_trips` không còn chỉ là của owner | ẢNH HƯỞNG BẠN A, xem ghi chú trong mục 2 |
| Realtime subscription `_subscribeToSavedTrips` trong provider | Mỗi thay đổi bảng kích hoạt lại `_syncFromSupabase` | ẢNH HƯỞNG BẠN A, sync phải idempotent |
| `destinations` + `featured_destinations` + seed 4 điểm đến + `destination_repository.dart` | Explore và Destination Detail giờ đọc DB trước, Gemini chỉ là fallback | ẢNH HƯỞNG BẠN B, xem ghi chú trong mục 3 |
| `community_reviews` + trigger tính rating + `community_review_service.dart` + UI review | Rating cộng đồng thật trên detail screen | Không đụng tuần 1 |
| Storage bucket `destination-media` public | Upload ảnh điểm đến | Không đụng tuần 1 |

Các file sau đóng băng với CẢ HAI bạn (không sửa, không refactor): `destination_repository.dart`, `community_review_service.dart`, `chat_history_service.dart`, `profile_service.dart`, `profile_screen.dart`, migration `20260829000100_sprint_2_3_travel_cloud.sql`.

Các vấn đề đã biết của PR #9, GHI NHẬN NHƯNG HOÃN (giáo viên sẽ giao ở tuần sau, tuần này không ai sửa):
- `chat_history_service.save()` xóa toàn bộ message của thread rồi ghi lại từ đầu sau MỖI tin nhắn: tốn ghi, có race khi hai thiết bị cùng chat.
- Policy bucket `destination-media`: mọi user đăng nhập upload được vào mọi đường dẫn, chưa giới hạn theo vai trò.
- Policy update `trip_collaborators`: collaborator có thể tự sửa row của mình (kể cả `role`), tức tự nâng quyền viewer thành editor qua REST.
- `_subscribeToSavedTrips` stream không filter, mỗi thay đổi của bất kỳ trip nào cũng kéo full re-sync.

---

## 1. HỢP ĐỒNG CHUNG ĐÃ CHỐT (đóng băng, cả hai cùng tuân theo)

Đây là hai điểm giao duy nhất giữa hai người. Code dưới đây là chữ ký chuẩn, copy nguyên văn.

### 1.1. Interface `AITravelGateway` (bạn B tạo file, bạn A chỉ được gọi qua nó nếu cần)

File mới: `lib/services/ai_travel_gateway.dart`

```dart
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/best_time_travel.dart';
import 'package:voyz/models/chat_message.dart';
import 'package:voyz/models/cultural_tips.dart';
import 'package:voyz/models/destination_comparison.dart';
import 'package:voyz/models/destination_detail.dart';
import 'package:voyz/models/destination_suggestion.dart';
import 'package:voyz/models/itinerary_plan.dart';
import 'package:voyz/services/gemini_service.dart';

/// Cổng duy nhất cho mọi lời gọi AI của app.
/// Screens KHÔNG import gemini_service.dart hay google_generative_ai nữa.
abstract class AITravelGateway {
  Future<List<DestinationSuggestion>> getExploreTrending({
    int limit = 10,
    bool forceRefresh = false,
    String? category,
    String languageCode = 'vi',
  });

  Future<List<DestinationSuggestion>> getSuggestions(
    TripData trip, {
    int limit = 10,
    bool forceRefresh = false,
    String languageCode = 'vi',
  });

  Future<List<DestinationSuggestion>> enrichSuggestionsWithImages(
    List<DestinationSuggestion> suggestions,
  );

  Future<DestinationDetail> getDestinationDetail(
    String destinationName,
    TripData trip, {
    bool forceRefresh = false,
    String languageCode = 'vi',
  });

  Future<ItineraryPlan> getItineraryPlan(
    String destinationName,
    int numDays,
    TripData trip, {
    int limit = 4,
    bool forceRefresh = false,
    String languageCode = 'vi',
    String? additionalInstruction,
  });

  Future<String> chat(
    String message, {
    required List<ChatMessage> history,
    String languageCode = 'vi',
    String? destinationName,
  });

  Future<DestinationComparison> compareDestinations(
    List<String> destinations, {
    String languageCode = 'vi',
  });

  Future<BestTimeTravel> getBestTimeToTravel(
    String destination, {
    String languageCode = 'vi',
  });

  Future<CulturalTips> getCulturalTips(
    String destinationName, {
    bool forceRefresh = false,
    String languageCode = 'vi',
  });
}

/// Service locator đơn giản: production trỏ vào GeminiService,
/// test có thể gán một FakeAITravelGateway.
AITravelGateway aiTravelGateway = GeminiService.instance;
```

Ghi chú hợp đồng:
- Chữ ký các hàm giữ NGUYÊN như `GeminiService` hiện tại (đã đối chiếu code ngày 30/08), vì vậy việc tách interface là thuần cơ học, không đổi hành vi.
- `GeminiService` sửa một dòng: `class GeminiService implements AITravelGateway`.
- Nếu file model nào chưa tồn tại đúng đường dẫn import trên (ví dụ `chat_message.dart` nằm chỗ khác), bạn B sửa đường dẫn import cho đúng thực tế, KHÔNG đổi chữ ký hàm.
- `TripData` giữ nguyên hình dạng hiện tại trong tuần này. `TripContext` là việc của tuần 3, chưa làm.

### 1.2. Trip identity: `SavedItem` có `id`, itinerary gắn `tripId` (bạn A tạo, bạn B không đụng)

Sửa `lib/data/trip_data.dart`, class `SavedItem` thêm trường đầu tiên:

```dart
class SavedItem {
  final String id;        // UUID v4, sinh khi tạo item, bất biến suốt vòng đời
  final String name;      // giữ lại, chỉ còn là nhãn hiển thị, KHÔNG còn là khóa
  // ... các trường còn lại giữ nguyên
}
```

Quy tắc bắt buộc:
- Thêm package `uuid: ^4.4.0` vào `pubspec.yaml`. Sinh id bằng `const Uuid().v4()` tại thời điểm tạo item.
- `toMap()` ghi `'id'`; `fromMap()` đọc `'id'`, nếu thiếu (dữ liệu Hive cũ) thì sinh mới một lần và giữ nguyên từ đó.
- `copyWith` phải giữ nguyên `id`.
- `ItineraryPlan` thêm trường `String tripId` (rỗng cho dữ liệu cũ); itinerary của một trip tra theo `tripId`, không theo `destinationName`.
- Mọi API của `SavedTripsProviderState` thao tác theo id: `itineraryFor(String tripId)`, xóa/sửa item theo `item.id`. Cho phép hai item cùng `name`.
- **Về trường `cloudId` (PR #9, commit `b1642aa` vừa thêm):** `cloudId` bị thay thế bởi `id`. Vì client tự sinh UUID và upsert với `onConflict: 'id'`, không cần chờ server cấp id nữa. Bạn A xóa `cloudId`, chuyển mọi chỗ đang dùng nó (kể cả `_syncCollaboratorToCloud`) sang `item.id`. Không giữ hai danh tính song song.

Hợp đồng database (bạn A viết migration mới, không sửa migration đã deploy):

```sql
-- Migration mới: 20260831000100_trip_identity.sql
-- 1. saved_trips: id do client cấp, bỏ unique theo tên
alter table public.saved_trips drop constraint if exists saved_trips_user_name_unique;
-- (id uuid primary key đã có sẵn từ migration 20260823000200)

-- 2. saved_itineraries: gắn theo trip, hỗ trợ nhiều version
alter table public.saved_itineraries add column if not exists trip_id uuid;
alter table public.saved_itineraries add column if not exists version integer not null default 1;
alter table public.saved_itineraries add column if not exists is_current boolean not null default true;
alter table public.saved_itineraries drop constraint if exists saved_itineraries_user_dest_unique;
create unique index if not exists saved_itineraries_trip_version_idx
  on public.saved_itineraries (trip_id, version) where trip_id is not null;
```

Quy tắc upsert phía client sau thay đổi này:
- `saved_trips`: upsert với `onConflict: 'id'`, payload luôn kèm `'id': item.id`.
- `saved_itineraries`: insert version mới = max(version) + 1 của trip đó, set `is_current = true` và bỏ cờ ở version cũ. Tuần này chỉ cần đọc bản `is_current`.

### 1.3. Điểm giao duy nhất trong screens

`destination_detail_screen.dart` và các screen khác là vùng giao:
- Bạn A: được sửa LOGIC trong screens (restore trip data, truyền `SavedItem`/id qua navigation).
- Bạn B: trong screens CHỈ được đổi kiểu tham chiếu (`GeminiService.instance` thành `aiTravelGateway`) và dòng import. Không sửa logic, không format lại file.

---

## 2. GIAO VIỆC BẠN A: Trip identity và ngữ nghĩa sync

### Mục tiêu tuần

Chuyến đi có danh tính thật (UUID), hai chuyến cùng điểm đến không đè nhau, dữ liệu mở lại đúng, xóa không hồi sinh khi sync.

### Các bước theo thứ tự

1. Thêm `uuid` package; thêm `id` vào `SavedItem` và `tripId` vào `ItineraryPlan` đúng hợp đồng 1.2 (kèm `toMap`/`fromMap`/`copyWith`).
2. Viết migration `20260831000100_trip_identity.sql` đúng hợp đồng 1.2.
3. Sửa `SavedTripsProvider`:
   - Upsert/delete cloud theo `id` (`onConflict: 'id'`); key trong Hive box cũng đổi sang `item.id`.
   - `itineraryFor(tripId)`, `saveItinerary` nhận `tripId`.
   - Bỏ mọi check trùng theo `name` (`_savedItems.any((e) => e.name == name)`), thay bằng logic phù hợp: wishlist có thể vẫn chặn trùng theo name, trip workspace thì không.
   - Gỡ trường `cloudId` (PR #9): `_syncCollaboratorToCloud` và mọi chỗ dùng `cloudId` chuyển sang `item.id`. Bảng `trip_collaborators.trip_id` đang FK tới `saved_trips.id` nên tương thích sẵn với hợp đồng.
4. Sửa ngữ nghĩa sync trong `_syncFromSupabase`:
   - Cloud là source of truth. So khớp theo `id`.
   - Item local không có trên cloud: chỉ đẩy lên nếu là item tạo offline chưa từng sync (gợi ý: cờ `pendingSync` trong Hive hoặc so `updated_at`); item đã từng sync mà cloud không còn nghĩa là bị xóa nơi khác, phải xóa local, không đẩy lại.
   - Ghi lên cloud kèm `updated_at`; bản có `updated_at` mới hơn thắng.
   - QUAN TRỌNG (thay đổi từ PR #9): query trong `_syncFromSupabase` không còn lọc `.eq('user_id', userId)`, nên kết quả select giờ gồm cả trip của NGƯỜI KHÁC share cho mình qua `trip_collaborators`. Quy tắc: chỉ trip mình sở hữu (`user_id == mình`) mới tham gia logic đẩy lên/xóa đối chiếu; trip cộng tác chỉ merge để đọc, tuyệt đối không đẩy lại với `user_id` của mình và không xóa trên cloud khi local thiếu.
   - Chú ý: PR #9 đã thêm realtime subscription (`_subscribeToSavedTrips`) gọi lại `_syncFromSupabase` mỗi khi bảng đổi. Logic merge/xóa phải idempotent (chạy lại nhiều lần không tạo trùng, không xóa nhầm), nếu không vòng lặp ghi sẽ tự kích hoạt sync liên tục.
5. Sửa navigation: `SavedScreen` mở một trip phải truyền cả `SavedItem` (hoặc id) và restore `item.tripData` trong `DestinationDetailScreen`, không dùng `currentTrip` toàn cục cho trip đã lưu.
6. Migration dữ liệu Hive cũ: item cũ không id thì sinh id khi load lần đầu (đã nằm trong `fromMap`), ghi đè lại box một lần.
7. Test bắt buộc (mở rộng `test/data/saved_trips_sync_test.dart`):
   - Hai trip cùng `name` cùng tồn tại, itinerary riêng theo `tripId`.
   - Item cloud bị xóa thì sau sync local cũng mất, không resurrect.
   - `fromMap` với map thiếu `id` sinh id hợp lệ và giữ ổn định.

### Files sở hữu

- `pubspec.yaml` (chỉ thêm dependency `uuid`)
- `lib/data/trip_data.dart`, `lib/data/saved_trips_provider.dart`
- `lib/models/itinerary_plan.dart`
- `lib/screens/saved_screen.dart`, `lib/screens/destination_plan_screen.dart` (phần logic), `lib/screens/destination_detail_screen.dart` (phần restore dữ liệu)
- `supabase/migrations/20260831000100_trip_identity.sql` (file mới)
- `test/data/`

### Cấm đụng

- `lib/services/gemini_service.dart`, `lib/services/ai_cache_service.dart`, `lib/services/search_history_service.dart`
- `lib/services/ai_travel_gateway.dart` (của bạn B)
- Các file đóng băng của PR #9 nêu ở mục 0.1 (`destination_repository.dart`, `community_review_service.dart`, `chat_history_service.dart`, `profile_service.dart`, `profile_screen.dart`)
- `.github/workflows/`
- Migration `ai_generated_cache` và migration `20260829000100_sprint_2_3_travel_cloud.sql`

### Tiêu chí nghiệm thu (giáo viên chạy cuối tuần)

- [ ] Tạo 2 chuyến "Đà Nẵng" ngày khác nhau: cả 2 cùng hiện, mỗi chuyến giữ đúng form data và itinerary riêng.
- [ ] Mở lại trip cũ: ngày, số người, ngân sách hiển thị đúng của trip đó.
- [ ] Đăng nhập 2 trình duyệt: xóa trip ở bên này, reload bên kia trip biến mất và không sống lại.
- [ ] `flutter test` pass, có tối thiểu 3 test mới kể trên.

---

## 3. GIAO VIỆC BẠN B: AITravelGateway và cache hardening

### Mục tiêu tuần

Mọi lời gọi AI đi qua một interface duy nhất; cache đúng (đủ key, có TTL, không rò rỉ giữa user, không cho người lạ ghi); key Gemini trên web build công khai được xử lý.

### Các bước theo thứ tự

1. Tạo `lib/services/ai_travel_gateway.dart` đúng nguyên văn hợp đồng 1.1. Cho `GeminiService implements AITravelGateway`. Compile xanh trước khi làm gì tiếp.
2. Đổi call site ở 8 screens đang gọi `GeminiService.instance` (`chat_screen`, `cultural_tips_screen`, `suggestions_screen`, `destination_plan_screen`, `compare_screen`, `best_time_screen`, `destination_detail_screen`, `explore_screen`) sang `aiTravelGateway`. Chỉ đổi tham chiếu và import, không đổi logic (quy tắc 1.3). Lưu ý từ PR #9: trong `explore_screen` và `destination_detail_screen`, Gemini giờ là FALLBACK sau khi đọc `DestinationRepository`; vẫn đổi các call site fallback đó sang `aiTravelGateway`, còn phần gọi `DestinationRepository`/`CommunityReviewService` giữ nguyên, không đụng.
3. Sửa cache key trong `gemini_service.dart`: key của `suggestions` và `itinerary` phải chứa MỌI input có mặt trong prompt (ngày đi/về, participants, ageRange, additionalNotes, aiPrompt, limit) cộng thêm `prompt_version` (hằng số, tăng khi sửa prompt).
4. Thêm TTL cho `AiCacheService`:
   - Lưu `created_at` + `ttl` theo feature (gợi ý: explore 24h, suggestions 7 ngày, detail 7 ngày, best_time/cultural 30 ngày).
   - Entry hết hạn coi như miss ở cả 3 tầng.
   - Kết quả CÁ NHÂN HÓA (prompt chứa notes/aiPrompt của user) chỉ cache ở Memory + Hive theo user, KHÔNG ghi lên bảng `ai_generated_cache` dùng chung.
   - Bỏ cơ chế `nonce` tạo key rác khi force refresh của Explore: force refresh thì bỏ qua cache đọc nhưng ghi đè vào key chuẩn.
5. Viết migration mới `20260831000200_harden_ai_cache.sql`:
   - Thu hồi quyền của `anon`: chỉ `authenticated` được select; bỏ policy insert/update `to anon`.
   - Insert/update chỉ cho `authenticated` (chấp nhận được cho lớp học; ghi chú trong file: về lâu dài phần ghi nên chuyển về server side).
   - Thêm cột `expires_at timestamptz`; đọc phía client lọc `expires_at > now()`.
6. Hive box scope theo user: `gemini_multi_tier_cache` và `search_history` mở theo tên box có user id (theo mẫu `_boxPrefix + userId` mà `SavedTripsProvider` đang dùng), user đăng xuất/đổi tài khoản không thấy cache của nhau.
7. Xử lý key trên GitHub Pages: tạo secret `GEMINI_API_KEY_DEMO` (key riêng, quota thấp nhất có thể) và trỏ workflow dùng secret này; thêm comment cảnh báo trong `deploy-web.yml` rằng key trong web build là công khai. (Việc tạo key demo trên Google AI Studio là của giáo viên, bạn B chỉ đổi workflow và báo lại.)
8. Test bắt buộc (mở rộng `test/services/ai_cache_service_test.dart` + file mới):
   - Hai input khác `additionalNotes` sinh hai cache key khác nhau.
   - Entry quá `expires_at`/TTL trả về miss.
   - Một `FakeAITravelGateway` dùng được trong widget test (chứng minh seam hoạt động).

### Files sở hữu

- `lib/services/ai_travel_gateway.dart` (file mới), `lib/services/gemini_service.dart`, `lib/services/ai_cache_service.dart`, `lib/services/search_history_service.dart`
- 8 screens kể trên (CHỈ dòng import và tham chiếu `aiTravelGateway`)
- `supabase/migrations/20260831000200_harden_ai_cache.sql` (file mới)
- `.github/workflows/deploy-web.yml`
- `test/services/`

### Cấm đụng

- `lib/data/trip_data.dart`, `lib/data/saved_trips_provider.dart`, `lib/models/itinerary_plan.dart`
- `lib/screens/saved_screen.dart`
- Các file đóng băng của PR #9 nêu ở mục 0.1 (`destination_repository.dart`, `community_review_service.dart`, `chat_history_service.dart`, `profile_service.dart`, `profile_screen.dart`)
- Migration `trip_identity` (của bạn A) và migration `20260829000100_sprint_2_3_travel_cloud.sql`
- Logic bên trong screens (ngoài việc đổi tham chiếu)

### Tiêu chí nghiệm thu (giáo viên chạy cuối tuần)

- [ ] `grep -r "GeminiService.instance" lib/screens/` trả về 0 kết quả; xóa import `google_generative_ai` khỏi `lib/screens/` vẫn compile.
- [ ] Hai tài khoản với notes khác nhau không nhận chung một kết quả suggestions từ cache.
- [ ] Bảng `ai_generated_cache` không còn policy nào cho `anon` ghi.
- [ ] Force refresh Explore không tạo dòng cache mới mỗi lần bấm.
- [ ] `flutter test` pass, có tối thiểu 3 test mới kể trên.

---

## 4. Kịch bản tuần và rủi ro

| Ngày | Bạn A | Bạn B |
|---|---|---|
| 1 | Đọc file này + doc kiến trúc; model `id`/`tripId` + migration | Đọc file này + doc kiến trúc; tạo interface, `implements`, compile xanh |
| 2-3 | Provider theo id, upsert/delete theo id | Đổi call sites; sửa cache key + prompt_version |
| 3 | Checkpoint chung 15 phút: chạy thử nhánh của nhau | Checkpoint chung |
| 4-5 | Ngữ nghĩa sync (xóa, updated_at), navigation restore | TTL, migration harden cache, box theo user, workflow key demo |
| 6 | Test + tự chạy tiêu chí nghiệm thu, mở PR | Test + tự chạy tiêu chí nghiệm thu, mở PR |
| 7 | Giáo viên review, merge A trước, B rebase rồi merge | |

Rủi ro cần biết trước:
- Nếu bạn A đổi tên hàm provider mà screens của bạn B đã đổi tham chiếu, sẽ conflict: KHÔNG xảy ra nếu cả hai tôn trọng mục "cấm đụng".
- Dữ liệu Supabase hiện có trên bảng `saved_trips` là dữ liệu test, được phép xóa sạch khi chạy migration mới nếu vướng (đã thống nhất với giáo viên).
- Câu hỏi phát sinh về hợp đồng: hỏi giáo viên, không tự quyết.

---

## 5. Task dự phòng: cải tiến trải nghiệm ảnh (nhận khi xong việc chính của mình)

> Bối cảnh bắt buộc đọc trước: `docs/lessons/2026-08-31-image-stability-walkthrough.md` (đặc biệt mục 3.5 và checklist mục 4). Nền tảng ảnh đã được sửa ổn định trong PR #10 + commit `2bee056`; task này là lớp polish UX bên trên, KHÔNG đụng lại kiến trúc nguồn ảnh.
>
> Ai nhận: bạn nào xong trước phần việc chính. Nếu là bạn B thì phần 5.1 (chạm screens) phải để bạn A review trước khi merge, theo đúng ranh giới sở hữu file của tuần.

Hiện trạng sau khi nền tảng ảnh đã ổn định (đã xác minh 30/08 tối):
- Loading indicator chỉ có ở Explore và gallery detail; 4 chỗ còn lại (Suggestions, Saved, hero của detail, Cultural Tips) trống trơn trong lúc tải.
- Fallback khi không có ảnh hoạt động ở cả 7 chỗ nhưng mỗi nơi một icon/màu khác nhau, không phải một thumbnail mặc định có chủ đích.
- Nhánh vi.wikipedia gần như luôn 404 vì AI trả tên không dấu ("Da Nang") còn tên bài vi.wiki có dấu ("Đà Nẵng"): tốn 1 request thừa mỗi ảnh và gây nhiễu console. Nhánh en cứu được các điểm đến lớn.
- Landmark do AI tự đặt tên ("Bai Chay Beach", "Thung Nham Bird Park"...) thường không có bài Wikipedia lẫn kết quả Commons đạt lọc, gallery hiện icon trống.

### 5.1. Widget `DestinationImage` dùng chung

- Tạo `lib/widgets/shared/destination_image.dart`: bọc `CachedNetworkImage`, xử lý đủ 3 trạng thái: URL rỗng hiện fallback NGAY (không chờ error), đang tải hiện placeholder nhất quán (nền gradient + icon mờ hoặc shimmer), lỗi hiện fallback nhất quán (gradient + icon núi + tên điểm đến chữ mờ). Nhận `imageUrl`, `destinationName`, `fit`, `borderRadius`.
- Thay cả 7 call site đang tự viết `CachedNetworkImage` (grep `CachedNetworkImage(` trong `lib/screens/`), xóa 7 bản placeholder/errorWidget chép tay.
- Đây là bài học về widget dùng chung: 7 biến thể của cùng một logic nghĩa là thiếu một abstraction.

### 5.2. Heuristic thứ tự ngôn ngữ trong `ImageService`

- Trong chuỗi `getImageUrl`: tên KHÔNG chứa ký tự có dấu tiếng Việt thì hỏi `en` trước rồi `vi`; có dấu thì giữ `vi` trước. Cắt gần hết 404 nhiễu và giảm 1 request cho đa số ảnh.
- Viết test MockClient cho cả hai nhánh heuristic (xem mẫu ở `test/services/image_service_test.dart`).

### 5.3. Gallery landmark không còn ô trống

- Khi ảnh landmark trong destination detail rỗng, fallback về ảnh chính của điểm đến (mờ/tối đi để phân biệt) thay vì icon trống. Nâng cao (tùy chọn): sửa prompt để Gemini trả kèm `wikiTitle` cho từng landmark rồi tra theo title đó.

### Tiêu chí nghiệm thu

- [ ] Mở Suggestions/Saved/Cultural Tips lúc mạng chậm: thấy placeholder loading, không còn ô trống trắng.
- [ ] Mọi trạng thái không-có-ảnh trong app trông giống nhau (một design duy nhất).
- [ ] Console khi mở Explore với điểm đến tên tiếng Anh: không còn chuỗi 404 `vi.wikipedia.org`.
- [ ] Gallery landmark không có ô icon trống.
- [ ] `dart run tool/verify_image_urls.dart` vẫn PASS, `flutter analyze` không lỗi mới, `flutter test` pass kèm test heuristic mới.
- [ ] KHÔNG thêm bất kỳ URL ảnh viết tay nào vào code (quy tắc bất di bất dịch từ walkthrough).
