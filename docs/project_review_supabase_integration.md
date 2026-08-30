# Review tổng thể Voyz và định hướng tích hợp Supabase

> Ngày review: 23/08/2026  
> Commit được review: `539ae23` (`master`)  
> Phạm vi: toàn bộ Flutter app, các service dữ liệu/HTTP, test hiện có và migrations trong thư mục `supabase/`  
> Hình thức: static review + chạy `flutter analyze` và `flutter test`; không thay đổi code ứng dụng  
> Giới hạn: chưa kiểm tra database Supabase đang deploy thực tế vì checkout này không được link với project và không có local Supabase stack đang chạy. Các nhận xét database dựa trên migration được commit trong repo.

## 1. Kết luận ngắn

Voyz đã vượt xa một prototype UI/HTTP ban đầu. Ứng dụng hiện có luồng người dùng tương đối đầy đủ: đăng ký/đăng nhập, lập yêu cầu chuyến đi, nhận gợi ý AI, xem chi tiết, tạo itinerary, lưu workspace, AI tools, hồ sơ, bạn bè và nhắn tin.

Supabase cũng đã được dùng, nhưng mới là tích hợp từng mảng:

- Đã dùng Supabase Auth cho đăng ký, đăng nhập, session và đổi mật khẩu.
- Đã dùng Supabase Storage cho avatar.
- Đã dùng Postgres cho social profile, friendship và friend message.
- Có migration cho search history nhưng app vẫn ghi search history vào Hive.
- Trip, wishlist, itinerary, checklist, note, booking reference, AI chat history và AI cache vẫn ở local Hive.
- Gemini vẫn được gọi trực tiếp từ Flutter bằng API key đóng gói trong `.env` asset.

Vì vậy, trạng thái hợp lý nhất là: **UI prototype tốt, Supabase foundation đã có, nhưng nguồn dữ liệu chính của nghiệp vụ travel vẫn chưa nằm ở backend**.

Ba việc nên ưu tiên trước:

1. Đưa Gemini call qua Supabase Edge Function để không phát hành Gemini key trong app, đồng thời có auth, quota, logging và validation tập trung.
2. Sửa RLS/data integrity của friendship trước khi coi social feature là an toàn.
3. Chuyển `Trip Workspace` từ một blob local theo tên địa điểm thành domain dữ liệu có UUID, owner/member, RLS và đồng bộ đa thiết bị.

Không nên chuyển mọi local state lên Supabase. UI state, cache ảnh, draft tạm, locale/currency cache và loading state vẫn nên ở client. Supabase nên là nguồn dữ liệu chính cho dữ liệu người dùng cần giữ lâu, chia sẻ hoặc truy cập trên nhiều thiết bị.

## 2. Bản đồ tính năng và nguồn dữ liệu hiện tại

| Nhóm tính năng | Luồng hiện tại | Nguồn dữ liệu/persistence | Trạng thái Supabase | Nhận xét |
|---|---|---|---|---|
| Auth | Email/password sign-up, sign-in, session gate, sign-out, đổi password | Supabase Auth | Đã tích hợp | Foundation tốt cho phase 2 |
| Profile | Display name/avatar/phone lấy từ `auth.users.user_metadata` | Auth metadata | Tích hợp một phần | Có thêm `social_profiles`, tạo hai nơi chứa profile |
| Avatar | Upload `${user.id}/avatar.png` | Supabase Storage bucket `avatars` public | Đã tích hợp | RLS theo folder đúng hướng; cần quyết định rõ public/private |
| Planner form | Điểm đến, ngày, budget, người đi, độ tuổi, interest, notes, prompt | `SavedTripsProvider` + Hive | Chưa | Dữ liệu cốt lõi nhưng chỉ tồn tại trên một thiết bị |
| Search history | Ghi mỗi lần bấm lấy gợi ý | Hive box `search_history` | Migration có nhưng app không dùng | Đây là một tích hợp dở dang rõ ràng |
| AI suggestions | Flutter build prompt và gọi Gemini | Gemini trực tiếp + Hive cache | Chưa | Key nằm ở client; cache key thiếu một số input |
| Explore trending | Gemini tạo danh sách “trending” | Gemini trực tiếp + cache không TTL | Chưa | Nội dung có tính thời gian nhưng có thể không bao giờ refresh |
| Destination detail | Gemini tạo weather, tags, budget breakdown | Gemini trực tiếp + Hive cache | Chưa | Dữ liệu AI đang được trình bày gần như dữ liệu thực tế |
| Itinerary | Gemini tạo plan; app lưu theo destination name | Gemini + Hive | Chưa | Nhiều chuyến cùng điểm đến có thể dùng nhầm plan |
| Wishlist | Lưu snapshot destination | Hive theo user ID | Chưa | Không sync đa thiết bị |
| Trip Workspace | Checklist, note, booking ref, shared person | Hive theo user ID | Chưa | “Shared person” mới là chuỗi text, chưa phải chia sẻ thật |
| AI chat | Multi-turn Gemini chat | Gemini trực tiếp + Hive history theo user | Chưa | Có thể giữ local hoặc sync tùy mục tiêu sản phẩm |
| Friends | Search profile, request, accept | Supabase Postgres | Đã tích hợp | Cần harden RLS và privacy của email search |
| Friend chat | Load/send message | Supabase Postgres, poll mỗi 4 giây | Tích hợp một phần | Nên dùng Realtime thay polling |
| Currency | Gọi Frankfurter, cache 6 giờ | HTTP trực tiếp + Hive | Chưa và chưa cần ngay | Thiết kế local-first hợp lý cho app học tập |
| Destination images | Wikipedia/Wikimedia HTTP | HTTP trực tiếp + memory/image cache | Chưa và chưa cần ngay | Có thể giữ adapter ngoài client ở phase 2 |
| Locale, display currency, music | Setting cá nhân trên thiết bị | Hive/local | Chưa | Có thể giữ local; chỉ sync preference nếu muốn đa thiết bị |

## 3. Luồng nghiệp vụ hiện tại

```text
Supabase Auth
    |
    v
Smart Planner --ghi local--> current TripData (Hive)
    |
    +--ghi local--> search_history (Hive)
    |
    v
GeminiService --API key trong app--> Gemini
    |
    +--> Suggestions --> Destination Detail --> Itinerary
    |                                      |
    |                                      +--ghi local--> itinerary theo destination name
    |
    +--cache raw JSON không TTL--> Hive gemini_cache
    |
    v
SavedTripsProvider --ghi local--> Wishlist / Trip Workspace / Checklist / Note

Supabase Postgres (luồng riêng)
    +--> social_profiles
    +--> friendships
    +--> friend_messages <--Flutter poll 4 giây/lần--
```

Điểm quan trọng là Auth/Social đã ở backend, nhưng travel domain vẫn chạy như một local demo. Hai nửa này chưa tạo thành một hệ thống dữ liệu thống nhất.

## 4. Domain model nên thống nhất trước khi thiết kế DB

Code hiện tại dùng `TripData`, `SavedItem`, “wishlist”, “workspace” và itinerary theo cách khá gần nhau. Trước khi thêm table, nên thống nhất các thuật ngữ sau:

| Thuật ngữ đề xuất | Ý nghĩa | Không nên đồng nhất với |
|---|---|---|
| `TravelRequest` | Bộ tiêu chí người dùng nhập để xin gợi ý: nơi muốn đi, ngày, budget, người đi, interest, notes | Một chuyến đi đã được chọn |
| `DestinationSuggestion` | Kết quả AI tạm thời cho một `TravelRequest` | Destination catalog hoặc dữ liệu factual đã xác minh |
| `WishlistItem` | Một destination snapshot mà user muốn giữ lại | Một trip đã có lịch trình |
| `TripWorkspace` | Chuyến đi user quyết định theo đuổi; có owner, member, ngày, budget, checklist, note | Tên điểm đến |
| `ItineraryVersion` | Một lần AI tạo/refine itinerary cho một workspace | Itinerary duy nhất vĩnh viễn của destination |
| `TripMember` | User thật được cấp quyền vào workspace | Chuỗi email/tên tự do trong `sharedWith` |
| `AIConversation` | Một thread hỏi đáp AI | Friend chat giữa hai user |
| `Friendship` | Quan hệ giữa hai user với state transition rõ ràng | Quyền tham gia Trip Workspace |

Hai scenario cho thấy model hiện tại chưa đủ:

- Một user đi Đà Nẵng tháng 6 với gia đình và lại đi Đà Nẵng tháng 12 với bạn. Key theo destination name sẽ coi hai workspace/itinerary là một.
- User nhập một email vào `sharedWith`. Người có email đó hiện không nhận được quyền đọc hoặc cập nhật workspace; đây chỉ là nhãn UI, không phải collaboration.

## 5. Các phát hiện theo mức ưu tiên

### P0 — Cần xử lý trước khi phát hành rộng hoặc bật billing

#### P0.1 Gemini key và toàn bộ AI call nằm trong client

Bằng chứng:

- `pubspec.yaml` khai báo `.env` là Flutter asset.
- `lib/services/gemini_service.dart:68-73` đọc `GEMINI_API_KEY` và tạo `GenerativeModel` ngay trong app.
- Tất cả AI feature đi qua singleton này, nên cùng chung vấn đề bảo mật/quota.
- Package `google_generative_ai` 0.4.7 mà project dùng hiện đã được Google đánh dấu deprecated và không còn kế hoạch cập nhật.

Một `.env` không được commit vẫn không bảo vệ secret khi file đó được bundle vào web/mobile app. Người dùng có thể trích key từ asset hoặc binary. Google cũng ghi rõ Gemini key không nên nằm trong mobile/web client production và nên gọi qua backend proxy.

Phân biệt rõ: `SUPABASE_PUBLISHABLE_KEY` được thiết kế để có mặt trong client và không phải secret; dữ liệu được bảo vệ bởi grants/RLS. Vấn đề ở đây là `GEMINI_API_KEY`, không phải publishable key của Supabase.

Đề xuất:

- Tạo một Supabase Edge Function làm `AI Travel Gateway`.
- Lưu Gemini credential trong Supabase Function Secrets.
- Flutter chỉ gửi feature name + input có cấu trúc + access token của user.
- Function thực hiện schema validation, giới hạn input/output, timeout, error mapping, rate limit và logging.
- Không cho client tự chọn model tùy ý. Model, temperature và max tokens là server configuration.
- Không log full prompt chứa notes hoặc thông tin cá nhân theo mặc định; ưu tiên input hash và metadata.

Đây là một **Seam** thật: production dùng Edge Function adapter, test dùng in-memory/fake adapter. UI chỉ cần học một **Interface** nhỏ như “generate suggestions”, “generate itinerary”, “chat”.

Tài liệu tham khảo chính thức:

- [Google: Gemini API key security](https://ai.google.dev/gemini-api/docs/api-key)
- [Supabase: Edge Functions phù hợp với small AI inference/LLM orchestration](https://supabase.com/docs/guides/functions)
- [Supabase: quản lý secrets cho Edge Functions](https://supabase.com/docs/guides/functions/secrets)
- [Deprecated Google AI Dart SDK](https://pub.dev/documentation/google_generative_ai/latest/)

#### P0.2 RLS friendship cho phép state transition không đúng vai trò

Bằng chứng trong `supabase/migrations/20260806000100_create_friends_social.sql`:

- Policy update ở dòng 99-104 cho phép **cả requester và addressee** update friendship miễn user vẫn là một participant.
- `FriendsService.acceptFriendRequest()` chỉ update `status = accepted` theo ID, không kiểm tra current user là addressee.
- `user_low` và `user_high` do client gửi khi insert; DB chưa ép hai giá trị này phải đúng ordered pair của requester/addressee.

Hậu quả:

- Requester có thể tự accept request của chính mình nếu gọi REST trực tiếp, dù UI không hiện nút đó.
- Client độc hại có thể gửi `user_low/user_high` sai để phá invariant unique pair hoặc tạo các cặp trùng logic.
- Policy update rộng cũng cho phép sửa các cột identity của friendship nếu grant mặc định cho phép.

Đề xuất:

- Không cho client insert/update trực tiếp các cột invariant.
- Dùng SQL function/RPC hoặc trigger để server tự tính ordered pair.
- Tách state transition: requester tạo/cancel; addressee accept/reject; mỗi participant có thể block theo rule rõ ràng.
- Policy `UPDATE` nên dùng `WITH CHECK` theo cả vai trò, state cũ và state mới; hoặc thu hồi update grant và chỉ expose RPC.
- Thêm DB tests chạy bằng hai user token khác nhau, không chỉ test UI.

Supabase nhấn mạnh rằng grants và policies là hai lớp riêng; cần kiểm tra cả hai, không chỉ bật RLS: [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security).

### P1 — Core work của phase Supabase

#### P1.1 Trip Workspace vẫn là local blob, chưa có identity và ownership chuẩn

Bằng chứng:

- `SavedTripsProvider` mở Hive box theo user ID, rồi clear và rewrite toàn bộ box khi persist.
- `SavedItem` không có UUID; duplicate và persistence key dựa trên `name`.
- Itinerary map cũng key theo `destinationName`.
- Checklist, note, booking refs và `sharedWith` nằm lồng trong cùng `SavedItem`.
- Khi bấm một card đã lưu, `SavedScreen` chỉ truyền destination name sang `DestinationDetailScreen`; screen đích lại dùng global `currentTrip`, không restore `item.tripData`. Vì vậy một workspace cũ có thể được render/generate theo form của chuyến gần nhất.

Hệ quả:

- Không sync giữa web/mobile hoặc hai thiết bị.
- Không hỗ trợ nhiều chuyến cùng destination.
- Không có concurrency control; thay đổi cuối cùng có thể ghi đè toàn bộ blob.
- Không thể làm sharing/RLS thật vì không có workspace ID và membership row.
- Không query/aggregate được checklist, trip status hay upcoming trip bằng SQL.

Ngoài ra, số ngày itinerary đang tính bằng `returnDate.difference(departDate).inDays`. Nếu nghiệp vụ coi cả ngày đi và ngày về đều là ngày du lịch, khoảng 01/06–03/06 phải là 3 ngày nhưng code tạo 2. Đây là quyết định domain cần chốt trước khi lưu date/duration vào DB.

Đây là mảng nên tích hợp Supabase đầu tiên vì nó chính là giá trị dài hạn của app, không phải cache.

#### P1.2 Migration search history đã có nhưng app không sử dụng

Bằng chứng:

- Migration tạo `public.search_history` với `user_id` và RLS.
- `lib/services/search_history_service.dart` chỉ mở Hive box `search_history` và không dùng Supabase.
- Box này không phân tách theo user ID; nếu sau này thêm màn hình đọc history, nhiều tài khoản trên cùng thiết bị có thể nhìn chung dữ liệu local.
- Migration `20260607030512_create_search_history.sql` là file rỗng; file thực tế nằm ở timestamp `20260607030717`.

Đề xuất:

- Chọn Supabase là source of truth cho authenticated search history.
- Hive chỉ là queue/cache offline, có user-scoped key.
- Có delete/retention policy rõ ràng vì prompt/notes có thể là dữ liệu cá nhân.
- Xóa hoặc ghi chú migration rỗng trong một migration cleanup có kiểm soát; không rewrite migration đã deploy nếu chưa xác minh remote state.

#### P1.3 AI cache có lỗi correctness, staleness và isolation

Bằng chứng:

- `CacheService` ghi vào một box global `gemini_cache`, không TTL và không scope theo user.
- Suggestions prompt dùng date, participants, age range, additional notes và `aiPrompt`, nhưng cache key chỉ có destination, budget, currency, interests, limit và language.
- Itinerary prompt dùng date và activity limit, nhưng cache key không chứa date range hoặc `limit`.
- Explore gọi nội dung “đang thịnh hành” và destination detail yêu cầu weather theo thời gian chuyến đi, nhưng cache có thể tồn tại vô hạn.

Hệ quả:

- Hai input khác nhau có thể nhận cùng một kết quả cũ.
- User B trên cùng thiết bị có thể nhận response được tạo từ notes/prompt của user A khi phần cache key trùng nhau.
- Nội dung có tính thời gian như trending/weather/best time có thể cũ nhưng UI không hiển thị thời điểm tạo.

Đề xuất ngắn hạn:

- Cache key phải bao gồm canonicalized full input có ảnh hưởng đến response, model version, prompt version và locale.
- Thêm `created_at`, `expires_at`, feature-specific TTL và user scope nếu response có personalization.
- Không dùng `forceRefresh` như cơ chế duy nhất để đảm bảo freshness.

Đề xuất khi có Edge Function:

- Server quyết định cacheability và TTL.
- Chỉ dùng shared cache cho input thật sự không có thông tin cá nhân.
- AI response lưu dài hạn phải gắn với `trip_id`/`itinerary_version`, không chỉ cache hash.

#### P1.4 App bắt buộc Supabase nhưng startup failure chưa graceful

`main()` catch lỗi `SupabaseService.init()` rồi vẫn render `AuthGate`; `AuthGate` truy cập `Supabase.instance.client` trực tiếp. Nếu `.env` thiếu hoặc Supabase init thất bại, catch ở startup không biến app thành offline mode thật mà chỉ trì hoãn lỗi.

Ngoài ra, repo khai báo `.env` là asset bắt buộc nhưng chỉ commit `.env.example`. Vì vậy một checkout mới không chạy `flutter test` ngay được nếu chưa tự tạo `.env`.

Đề xuất:

- Xem Supabase là required dependency và hiển thị configuration/fatal startup screen rõ ràng; hoặc thiết kế offline guest mode đầy đủ. Không giữ trạng thái nửa required, nửa optional.
- Document setup trong README và cung cấp script/config workflow không làm lộ secret.
- Tách config validation khỏi widget tree để có test riêng.

#### P1.5 Friend chat đang polling thay vì dùng Realtime

`FriendChatScreen` reload tối đa 100 messages mỗi 4 giây. Cách này đủ cho demo nhưng tạo request đều đặn, message có độ trễ và không scale tốt.

Đề xuất:

- Giữ initial paginated query.
- Subscribe insert event hoặc private Broadcast cho friendship hiện tại.
- Unsubscribe khi dispose và deduplicate bằng message UUID.
- Với scope lớp học, Postgres Changes là bước dễ học; nếu hướng đến scale, Supabase hiện khuyến nghị Broadcast vì bảo mật/khả năng mở rộng tốt hơn.

Tham khảo: [Supabase Realtime database changes](https://supabase.com/docs/guides/realtime/subscribing-to-database-changes).

#### P1.6 AI output đang được dùng như dữ liệu factual

Gemini tự tạo `rating`, `reviewCount`, price, weather, rainfall, safety score và nội dung “trending”. Đây là generated estimate, không phải dữ liệu đã được kiểm chứng. JSON parsing tốt không chứng minh nội dung đúng.

Khi lưu full trip từ detail screen, code còn gán cố định `matchPercent = 98`, `rating = 4.5`, `reviewCount = 120` thay vì giữ provenance/snapshot ban đầu. Điều này làm dữ liệu đã lưu trông chính xác hơn mức thực tế.

Đề xuất:

- Đổi copy/UI để phân biệt rõ `AI estimate` với verified data.
- Không lưu rating/reviewCount do AI sinh như master data.
- Nếu tính năng cần số liệu thật, thêm adapter cho nguồn factual tương ứng; AI chỉ giải thích/tổng hợp.
- Lưu `generated_at`, model/prompt version và disclaimer trên itinerary/detail snapshot.

### P2 — Cải thiện sau khi core data ổn định

#### P2.1 Profile đang có hai nguồn sự thật

`ProfileService` đọc/ghi display name, avatar, phone trong Auth user metadata. Migration social lại copy email/display name/avatar vào `social_profiles`. Trigger giúp sync một chiều từ Auth nhưng vẫn làm domain model khó hiểu.

Nên chọn:

- Auth chỉ giữ identity/session và metadata tối thiểu.
- `profiles` là source of truth cho display name, avatar path, phone và preference.
- Không dùng user-editable `raw_user_meta_data` làm authorization data. Hiện code chưa dùng nó để phân quyền, nên đây là nguyên tắc phòng ngừa khi mở rộng role/member.

#### P2.2 Profile search đang lộ email cho mọi authenticated user

Policy hiện cho mọi authenticated user select toàn bộ `social_profiles`; client search substring theo email và name. Với app lớp học có thể chấp nhận cho demo, nhưng không nên là default production privacy model.

Phương án an toàn hơn:

- Có unique public username và search theo username/display name.
- Invite bằng exact email qua RPC, chỉ trả về minimal public profile nếu match.
- Không cho client select cột email trong search result chung.

#### P2.3 Avatar bucket public cần quyết định sản phẩm rõ ràng

Public avatar đơn giản và hợp lý nếu avatar thực sự là public profile image. Nếu app dùng cho học sinh hoặc nhóm kín, cân nhắc private bucket + signed URL. Dù chọn cách nào, nên có file-size/content-type rules và cleanup file cũ/orphan.

#### P2.4 Module hiện tại còn shallow ở data seam

`SupabaseService` chỉ expose raw client/auth; phần lớn knowledge về table, RLS assumptions và mapping nằm trong các singleton khác. Đây là foundation được, nhưng khi chuyển trip lên DB không nên để các screen gọi `.from('trips')` trực tiếp.

Nên tạo các **Module** sâu theo use case:

- `Account` — profile và preference.
- `TripWorkspace` — create/load/update/share trip, checklist, booking ref và itinerary version.
- `AITravelGateway` — tất cả AI generation.
- `Social` — public profile, friendship state machine, chat.
- `ReferenceData` — image và exchange rate adapters.

Mỗi module có **Interface** nhỏ; Supabase/Hive/HTTP là **Adapter** nằm sau **Seam**. Điều này tăng **Locality**: đổi schema/RLS/serialization ở một nơi, không sửa nhiều screen.

#### P2.5 Documentation và test chưa theo kịp code

- README vẫn là Flutter starter text, chưa có kiến trúc, setup `.env`, Supabase migration hoặc cách test.
- Tài liệu cũ nhắc Gemini 3.5 Flash trong khi code dùng `gemini-3.1-flash-lite`.
- Báo cáo cũ tuyên bố analyzer sạch, nhưng baseline hiện có 13 issues.
- Test chủ yếu kiểm tra localization, money parsing và JSON healing. Chưa có test cho Auth, repository, saved trip persistence, cache key, RLS, Edge Function, friendship transitions hoặc realtime.
- Một test “heals array closed with `}`” thực tế truyền JSON đóng đúng bằng `]`, nên tên test và dữ liệu test không khớp.
- Friends và một phần Saved workspace vẫn có hardcoded English dù app quảng bá VI/EN/KO.
- Một số affordance mới dừng ở mức UI: share chỉ hiện snackbar “link copied” nhưng không tạo/copy link thật; nút Book Now có callback rỗng; avatar picker chỉ hoạt động trên web dù project có mobile targets.

## 6. Schema Supabase khuyến nghị cho phase 2

Mục tiêu của schema dưới đây là đủ sâu cho nghiệp vụ nhưng vẫn phù hợp một dự án học tập. Không cần normalize mọi JSON ngay từ đầu.

### 6.1 Core tables

#### `profiles`

- `user_id uuid primary key references auth.users`
- `username text unique`
- `display_name text`
- `avatar_path text`
- `phone_number text`
- `locale text`
- `display_currency text`
- `created_at`, `updated_at`

Public search view/RPC chỉ trả về `user_id`, `username`, `display_name`, `avatar_url`; không trả phone/email.

#### `trips`

- `id uuid primary key`
- `owner_id uuid not null`
- `title text`
- `destination_name text`
- `depart_date date`, `return_date date`
- `budget_amount numeric`, `budget_currency char(3)`
- `participants_count integer`
- `age_range text`
- `interests text[]`
- `notes text`
- `ai_prompt text`
- `status text check (...)` — ví dụ `draft`, `planning`, `ready`, `completed`, `archived`
- `created_at`, `updated_at`, optional `version integer`

Ràng buộc tối thiểu:

- `return_date >= depart_date`
- `budget_amount >= 0`
- `participants_count > 0`
- currency nằm trong danh sách app hỗ trợ

#### `trip_members`

- `trip_id uuid`
- `user_id uuid`
- `role text` — `owner`, `editor`, `viewer`
- `invite_status text` — `pending`, `accepted`, `declined`
- `invited_by uuid`
- `created_at`, `updated_at`
- primary key `(trip_id, user_id)`

Không dùng `sharedWith: List<String>` làm authorization.

#### `wishlist_items`

- `id uuid primary key`
- `user_id uuid`
- `destination_name text`
- `image_url text`
- `suggestion_snapshot jsonb`
- `saved_at timestamptz`
- unique phù hợp với rule sản phẩm, ví dụ `(user_id, normalized_destination_name)`

`suggestion_snapshot` là snapshot AI, không phải destination master data.

#### `itinerary_versions`

- `id uuid primary key`
- `trip_id uuid`
- `version integer`
- `plan jsonb`
- `refinement_instruction text`
- `model text`, `prompt_version text`
- `generated_at timestamptz`
- `is_current boolean`

Giai đoạn đầu, lưu plan trong JSONB là đủ. Chỉ tách `itinerary_days/items` thành tables khi app cần edit/query/collaborate ở cấp từng activity.

#### `trip_checklist_items`

- `id uuid primary key`
- `trip_id uuid`
- `text text`
- `is_done boolean`
- `sort_order integer`
- `created_by uuid`, `updated_at`

#### `trip_booking_refs`

- `id uuid primary key`
- `trip_id uuid`
- `label text`
- `reference text`
- `created_by uuid`, `created_at`

Không lưu password, payment token hoặc secret booking credential. Đây là dữ liệu nhạy cảm cần RLS và data minimization.

### 6.2 Tables có thể thêm sau

- `ai_conversations`, `ai_messages`: chỉ khi muốn AI chat sync đa thiết bị.
- `ai_generations`: audit/quota/cache metadata; tránh lưu full prompt mặc định.
- `notifications`: friend request, trip invite, itinerary update.
- `exchange_rate_snapshots`: chỉ khi muốn shared server cache/analytics; phase 2 chưa bắt buộc.

### 6.3 Existing tables cần harden

- `social_profiles`: chuyển thành `profiles` hoặc tạo public projection, không expose email rộng.
- `friendships`: server-computed pair, strict state transitions, thêm cancel/reject/unfriend semantics.
- `friend_messages`: thêm body length constraint, pagination index, Realtime publication/broadcast policy.
- `search_history`: app phải dùng thật; thêm delete/retention nếu lưu prompt/notes.

## 7. RLS matrix khuyến nghị

| Resource | Select | Insert | Update | Delete |
|---|---|---|---|---|
| `profiles` | Public fields qua view/RPC; full row chỉ owner | Trigger khi sign-up hoặc own row | Owner | Owner/admin theo policy sản phẩm |
| `trips` | Owner hoặc accepted member | `owner_id = auth.uid()` | Owner/editor; field nhạy cảm theo role | Owner |
| `trip_members` | Member của trip | Owner/inviter qua RPC | Invitee cập nhật own invite status; owner đổi role | Owner hoặc member tự rời |
| `wishlist_items` | Owner | Owner | Owner | Owner |
| `itinerary_versions` | Trip member | Owner/editor hoặc Edge Function | Hạn chế; ưu tiên immutable version | Owner |
| `trip_checklist_items` | Trip member | Owner/editor | Owner/editor | Owner/editor |
| `trip_booking_refs` | Chỉ member được phép xem | Owner/editor | Owner/editor | Owner/editor |
| `friendships` | Hai participant | Requester qua RPC | Theo state machine/role | Cancel/unfriend theo rule |
| `friend_messages` | Accepted friends | Sender là participant | Thường immutable | Theo product policy |

Ngoài RLS, cần kiểm tra/revoke grants không dùng. Đừng xem “đã bật RLS” là đủ nếu policy cho phép update quá rộng hoặc client được tự ghi invariant.

## 8. Kiến trúc tích hợp đề xuất

```text
Flutter Screens
    |
    +--> TripWorkspace Interface
    |       +--> Supabase Adapter (source of truth)
    |       +--> Hive Adapter (offline cache / pending writes)
    |
    +--> AITravelGateway Interface
    |       +--> Edge Function Adapter --> Gemini
    |       +--> Fake Adapter cho tests
    |
    +--> Social Interface
    |       +--> Supabase Postgres/RPC
    |       +--> Realtime subscription
    |
    +--> ReferenceData Interface
            +--> Wikipedia/Wikimedia Adapter
            +--> Frankfurter Adapter + local cache
```

Nguyên tắc source of truth:

- Supabase: account, profile, trip, membership, wishlist, itinerary version, collaboration, search history cần lưu lâu.
- Hive: offline cache, draft chưa submit, pending write queue, AI/reference cache có TTL.
- Widget state: loading, selected tab/day, controller text tạm, animation.
- External API: Gemini phải đi qua protected gateway; Wikipedia/Frankfurter có thể vẫn gọi trực tiếp ở phase này.

Không tạo thêm lớp chỉ để pass-through. Một module chỉ đáng có khi Interface của nó che được serialization, cache, retry, auth, error mapping hoặc business invariants cho nhiều caller.

## 9. Lộ trình triển khai khuyến nghị

### Sprint 0 — Security và baseline

Kết quả mong đợi:

- Gemini key không còn trong Flutter asset/binary.
- AI call có authenticated Edge Function, input schema, quota và error mapping.
- Friendship không thể tự accept hoặc phá ordered pair qua REST trực tiếp.
- README mô tả setup, migrations và cách chạy test.
- Có RLS integration tests cho hai user.

### Sprint 1 — Trip Workspace source of truth

Kết quả mong đợi:

- Có `trips`, `trip_members`, `wishlist_items`, `itinerary_versions`, `trip_checklist_items`, `trip_booking_refs` với UUID/RLS.
- User đăng nhập trên thiết bị khác vẫn thấy workspace.
- Hai trip cùng destination không đè nhau.
- Search history ghi vào table đã có.
- Hive dữ liệu cũ có migration/import rõ ràng hoặc được coi là demo data có thể bỏ, do giáo viên quyết định trước khi implement.

### Sprint 2 — Offline sync và collaboration

Kết quả mong đợi:

- Hive trở thành cache/pending queue thay vì source of truth.
- Trip member thật thay thế `sharedWith` text.
- Checklist/note update có conflict strategy tối thiểu dựa trên `updated_at` hoặc version.
- Friend chat và trip updates dùng Realtime; không poll toàn bộ message list mỗi 4 giây.

### Sprint 3 — AI data quality và observability

Kết quả mong đợi:

- Cache có TTL, prompt/model version và isolation đúng.
- AI estimates được dán nhãn rõ trong UI.
- Có usage/error metrics theo feature mà không log dư PII.
- Có tests cho cache key, schema validation, malformed AI output và Edge Function auth/rate limit.

## 10. Phần không nên đưa lên Supabase ngay

Để tránh biến phase 2 thành “mọi thứ đều là database”, nên giữ các phần sau ở client:

- Selected tab, selected itinerary day, loading/error state.
- Text controller trong lúc user đang nhập; chỉ sync draft nếu có requirement rõ.
- Theme/localization assets và danh sách interest tĩnh.
- Cached network images.
- Background music state.
- Exchange-rate memory/Hive cache 6 giờ hiện tại.
- Wikipedia/Wikimedia image lookup, trừ khi cần rate limiting, consistent server cache hoặc content moderation.

Locale và display currency có thể vừa lưu local để startup nhanh, vừa sync profile theo kiểu “last chosen preference”; không cần chặn app nếu sync lỗi.

## 11. Baseline chất lượng hiện tại

### Analyzer

`flutter analyze` hiện trả về 13 issues:

- 1 warning: `.env` được khai báo là asset nhưng không tồn tại trong checkout.
- 12 info: deprecated Dart/Flutter APIs và một số lint/style issues.

Các điểm đáng chú ý gồm `dart:html` deprecated, Radio API deprecated và `withOpacity` deprecated. Không có compile error được analyzer báo trong lần chạy này.

### Tests

Sau khi tạo `.env` placeholder tạm thời chỉ để build asset bundle:

- **37 tests pass**.
- Placeholder đã được xóa sau khi test.

Coverage hiện nghiêng mạnh về pure parsing/localization. Chưa có bằng chứng tự động cho các rủi ro quan trọng nhất của phase 2:

- Auth/session flow.
- Supabase schema và RLS với nhiều user.
- Friendship state transitions.
- Saved trip/workspace persistence và migration.
- Search history Supabase adapter.
- AI gateway auth, validation, quota và cache isolation.
- Realtime message delivery.

### Repo hygiene

- Worktree sạch trước review.
- `.env` được ignore đúng, nhưng setup chưa self-explanatory.
- README là boilerplate.
- Có một migration rỗng.
- Một số report cũ không còn phản ánh code hiện tại.

## 12. Checklist quyết định cho giáo viên trước khi giao học sinh implement

Các quyết định sau ảnh hưởng trực tiếp đến schema và không nên để học sinh tự suy đoán:

1. Một `TripWorkspace` có thể có nhiều destination hay chỉ một destination?
2. Người được share có quyền viewer hay editor? Owner có thể chuyển ownership không?
3. Có cần offline edit thật hay chỉ offline read cache?
4. Dữ liệu Hive hiện có cần migrate lên Supabase hay có thể reset vì đây là app học tập?
5. AI chat history có cần sync đa thiết bị không, hay giữ local để giảm dữ liệu cá nhân?
6. Search history giữ bao lâu và user có nút xóa không?
7. Avatar/profile có public với toàn bộ authenticated users không?
8. Rating/review/weather có cần dữ liệu verified từ provider thật hay chỉ là AI estimate có disclaimer?

Nếu chưa quyết định hết, vẫn có thể bắt đầu Sprint 0 vì security hardening không phụ thuộc các lựa chọn domain này.

## 13. Đánh giá cuối

Voyz là một project học tập có breadth tốt: học sinh đã thực hành UI, navigation, localization, async HTTP, parsing, caching, Auth, Storage và một phần Postgres/RLS. Điểm yếu hiện tại không phải thiếu thêm màn hình, mà là dữ liệu nghiệp vụ travel chưa có identity, ownership và source of truth rõ ràng.

Phase 2 nên tập trung vào việc biến `Trip Workspace` thành module sâu nhất của app. Khi module này có Interface nhỏ, Supabase adapter an toàn, Hive adapter làm cache và RLS đúng vai trò, những tính năng như cross-device, sharing, realtime và lịch sử AI sẽ trở thành hệ quả tự nhiên thay vì các feature rời rạc.
