# Spec: Cache đơn giản và danh tính chuyến đi (roadmap mục 2.2 và 2.3)

> Ngày: 06/09/2026. Trạng thái: đã duyệt thiết kế với giáo viên, chờ viết plan.
> Baseline: `master` sau PR #12 (`0e5bb51`).
> Roadmap gốc: `docs/project_phase3_roadmap_ai_first.md` mục 2.2 và 2.3. Spec này cụ thể hoá và **cắt gọn thêm** so với roadmap (xem mục 4). Khi hai tài liệu khác nhau, spec này thắng.
> Hai phần dưới đây là hai nhánh, hai PR độc lập. Phần 1 không chạm `lib/data/`, phần 2 không chạm `ai_cache_service.dart`.

## 0. Nguyên tắc thiết kế

- Mỗi dữ liệu có đúng một nơi ở. Cache ở Hive. Dữ liệu người dùng lưu ở Supabase. Không có nơi nào giữ hai bản phải hoà giải.
- Không có việc chạy nền. Ghi cloud thì `await`, thành công mới đổi state. Thất bại thì báo lỗi và không đổi gì.
- Debug được bằng mắt: mở một box Hive là hiểu cache, mở một bảng Supabase là hiểu dữ liệu.

---

## Phần 1. Cache đơn giản (`AiCacheService`)

### 1.1. Hiện trạng cần bỏ

`lib/services/ai_cache_service.dart` (297 dòng) có 3 tầng Memory / Hive / Supabase, không TTL, entry kèm `imageUrls` và bộ lọc `sanitizeImageUrls`, RPC đếm hit. `gemini_service.dart` có `_precacheAndStoreImages` chạy nền đọc lại rồi ghi lại entry để gắn ảnh, và `nonce` ngẫu nhiên khi force refresh Explore. `lib/services/cache_service.dart` (60 dòng) là code chết, chỉ còn `init()` trong `main.dart`. Bảng `ai_generated_cache` cho `anon` ghi.

### 1.2. Thiết kế mới

Một tầng duy nhất: một Hive box tên `ai_cache_v3`. Hive `Box` (không lazy) đã giữ dữ liệu trong RAM nên không cần map memory riêng.

```dart
class AiCacheService {
  static const boxName = 'ai_cache_v3';      // tăng số khi sửa prompt, cache cũ tự mất
  static const ttl = Duration(days: 7);      // một TTL cho mọi feature

  Future<void> init();                       // mở box; xoá box cũ gemini_cache, gemini_multi_tier_cache_v2 một lần
  String buildKey(String prefix, Map<String, dynamic> parts); // md5, tự nối userId hiện tại
  String? get(String key);                   // null nếu không có hoặc hết hạn (hết hạn thì xoá luôn)
  Future<void> put(String key, String payload);
  Future<void> clear();
}
```

Entry lưu trong box là JSON string:

```json
{"payload": "<JSON thô từ Gemini>", "expiresAt": "2026-09-13T10:00:00.000Z"}
```

Quy tắc:
- `buildKey` giữ logic hiện có (sort key, sort list, trim + lowercase) và nối thêm `|user=<userId hoặc anonymous>` trước khi băm. Hai user trên cùng máy không đọc chung cache. Không có box theo user, không có listener auth.
- `get` đọc đồng bộ. Entry thiếu `expiresAt` hoặc `expiresAt < now` coi là hết hạn: xoá khỏi box, trả `null`.
- `put` ghi `expiresAt = now + ttl`. Không có tham số `featureType`, `destination`, `languageCode`, `imageUrls`.
- Cache không chứa URL ảnh. Ảnh luôn tra qua `ImageService` sau khi có payload, dù payload đến từ cache hay từ Gemini.
- Xoá `CachedAiResponse`, `sanitizeImageUrls`, `_saveToSupabase`, `_incrementHitCount`. Giữ import `supabase_service.dart` chỉ để lấy `userId` cho key; không còn đọc/ghi bảng nào.
- Explore: theme ngẫu nhiên cố ý KHÔNG nằm trong key, để force refresh ghi đè cùng một key thay vì thêm entry.
- Phạm vi "một tầng duy nhất" là `AiCacheService`. `DestinationRepository` vẫn giữ box `curated_destinations_cache` (TTL 6h) riêng cho dữ liệu curated, không đụng trong phần này.

### 1.3. Thay đổi trong `gemini_service.dart`

- Mọi lời gọi `getResponse` thành `get`, `putResponse` thành `put(key, payload)`. Không truyền `imageUrls` vào `parseSuggestionsSync` nữa; hàm này bỏ tham số `imageUrls`.
- Xoá `_precacheAndStoreImages` và mọi chỗ gọi nó. Explore và Suggestions tra ảnh bằng `ImageService.getImageUrls` ngay sau khi có danh sách, như Suggestions đang làm ở pha 2. `ImageService.getImageUrlsFast` không còn ai gọi thì xoá.
- `getExploreTrending`: bỏ `nonce` và `randomSeed`. `forceRefresh` chỉ bỏ qua bước `get`, kết quả vẫn `put` vào key chuẩn.
- Bổ sung key cho đủ input của prompt:
  - `suggestions`: thêm `participants`, `ageRange`.
  - `detail`: thêm `budget`, `currency`, `departDate`, `returnDate`.
  - `itinerary`: thêm `departDate`, `returnDate`.
- Không thêm `promptVersion` vào key. Sửa prompt thì tăng số trong `boxName`.

### 1.4. Xoá và migration

- Xoá file `lib/services/cache_service.dart` và dòng `await CacheService.instance.init();` trong `lib/main.dart`.
- Migration `supabase/migrations/20260907000200_drop_ai_generated_cache.sql`:

```sql
drop function if exists public.increment_ai_cache_hit(text);
drop table if exists public.ai_generated_cache;
```

### 1.5. Test (`test/services/ai_cache_service_test.dart`)

Viết lại file vì API đổi. Dùng `Hive.init(tempDir)` như `test/data/locale_provider_test.dart`.
- `put` rồi `get` trả đúng payload.
- Entry có `expiresAt` trong quá khứ: `get` trả `null` và key không còn trong box.
- `put` cho `expiresAt` cách `now` khoảng 7 ngày (sai số 1 phút).
- `buildKey` cùng input cho cùng key; khác `participants` cho key khác; đảo thứ tự map cho cùng key.
- Xoá các test về `CachedAiResponse` và `sanitizeImageUrls`.

Test prompt builder hiện có trong `test/services/gemini_service_test.dart` giữ nguyên. `test/gemini_service_test.dart` ở sai thư mục: gộp các test chưa có (nhóm `parseSuggestionsSync`, 2 case `safeJsonDecode`) vào file trên rồi xoá. Không mất coverage.

### 1.6. Nghiệm thu

- [ ] `grep -rn "ai_generated_cache\|CacheService\b\|CachedAiResponse\|_precacheAndStoreImages" lib/` trả về rỗng.
- [ ] `lib/services/ai_cache_service.dart` dưới 100 dòng.
- [ ] Đổi budget tier rồi mở lại detail cùng điểm đến: nội dung ngân sách khác nhau.
- [ ] Bấm refresh Explore 3 lần: box Hive không tăng thêm 3 entry mới cho cùng input.
- [ ] Đăng nhập user khác trên cùng máy: Suggestions gọi Gemini lại, không dùng kết quả của user trước.
- [ ] `flutter analyze` không lỗi mới, `flutter test` pass.

---

## Phần 2. Danh tính chuyến đi và cloud-first (`SavedTripsProvider`)

### 2.1. Hiện trạng cần sửa

`SavedItem` không có `id`, có `cloudId` không dùng nhất quán. Upsert `saved_trips` theo `(user_id, name)`, itinerary theo `destination_name`, nên hai chuyến cùng điểm đến đè nhau. `_syncFromSupabase` merge theo tên, item xoá nơi khác sống lại. Realtime subscription kích hoạt sync lại toàn bộ. `_persist()` xoá cả box rồi ghi lại. Mở trip đã lưu dùng `currentTrip` toàn cục thay vì dữ liệu của trip đó. `search_history` không có DELETE policy nên xoá lịch sử là no-op trên cloud.

### 2.2. Quy tắc một câu

**Cloud là dữ liệu. Hive là ảnh chụp để mở app hiện ngay.** Mọi thao tác lưu, sửa, xoá đều `await` Supabase; thành công mới đổi state và ghi Hive; thất bại thì ném lỗi cho màn hình hiện snackbar.

| Dữ liệu | Ở đâu | Khi nào lên cloud |
|---|---|---|
| Nội dung đang gõ ở planner (`_currentTrip`) | Hive | Không bao giờ |
| Lịch sử yêu cầu (`search_history`) | Cloud | Khi bấm "Gợi ý" (có sẵn, không đổi) |
| Trip đã lưu, wishlist, checklist, ghi chú, booking refs | Cloud | Lúc bấm Lưu / sửa / xoá |
| Itinerary | Cloud | Lúc AI tạo hoặc refine xong |
| Cache AI | Hive | Không bao giờ |

### 2.3. Model (`lib/data/trip_data.dart`, `lib/models/itinerary_plan.dart`)

- Thêm package `uuid: ^4.4.0` vào `pubspec.yaml`.
- `SavedItem` thêm `final String id` là trường đầu tiên. Constructor nhận `String? id`, null thì `const Uuid().v4()`. Bỏ `cloudId`. `fromMap` đọc `map['id']`, thiếu thì sinh mới. `toMap` ghi `'id'`. `copyWith` giữ `id`.
- `ItineraryPlan` thêm `final String tripId` (mặc định `''`), có trong `fromJson`/`toMap`.
- `TripData` thêm helper tính số ngày, dùng chung cho plan screen và prefetch trong detail:

```dart
/// Số ngày của chuyến đi, tính cả ngày đi và ngày về. Không có ngày thì dùng fallback.
int dayCount({int fallback = 3}) {
  if (departDate == null || returnDate == null) return fallback;
  return (returnDate!.difference(departDate!).inDays + 1).clamp(1, 7).toInt();
}
```

### 2.4. Migration `supabase/migrations/20260907000100_trip_identity.sql`

```sql
-- Dữ liệu test cũ không có trip_id, reset sạch (đã thống nhất với giáo viên).
delete from public.saved_itineraries;
delete from public.saved_trips;

-- saved_trips: id do client sinh, cho phép hai chuyến cùng tên
alter table public.saved_trips drop constraint if exists saved_trips_user_name_unique;

-- saved_itineraries: gắn theo trip, một trip một itinerary
alter table public.saved_itineraries
  add column if not exists trip_id uuid references public.saved_trips(id) on delete cascade;
alter table public.saved_itineraries drop constraint if exists saved_itineraries_user_dest_unique;
alter table public.saved_itineraries alter column trip_id set not null;
create unique index if not exists saved_itineraries_trip_idx on public.saved_itineraries (trip_id);

-- search_history: cho phép xoá lịch sử của mình
drop policy if exists "Users can delete their own search history" on public.search_history;
create policy "Users can delete their own search history"
  on public.search_history for delete to authenticated
  using (auth.uid() = user_id);
```

RLS của `saved_trips` và `saved_itineraries` giữ nguyên. Cột `destination_name` trong `saved_itineraries` giữ lại để hiển thị.

### 2.5. Provider (`lib/data/saved_trips_provider.dart`, viết lại, ngắn hơn bản cũ 497 dòng; không đặt ngưỡng số dòng cứng)

State: `TripData _currentTrip`, `List<SavedItem> _items`, `Map<String, ItineraryPlan> _itineraries` (key = `tripId`).

Hive box `saved_trips_cache_<userId>` (`anonymous` khi chưa đăng nhập): key `__current_trip`, key `item.id` cho từng item, key `__itinerary_<tripId>`. Ghi từng key bằng `put`/`delete`, không `clear()` toàn box. Lần init đầu xoá hai box cũ `saved_trip_workspaces*` và `storage_migrations` bằng `Hive.deleteBoxFromDisk` (dữ liệu cũ được phép mất).

API công khai:

```dart
TripData get currentTrip;
List<SavedItem> get tripWorkspaces;   // tripData != null
List<SavedItem> get wishlistItems;    // tripData == null
ItineraryPlan? itineraryFor(String tripId);

void updateTrip(TripData trip);                                  // chỉ Hive
Future<SavedItem> saveFullTrip({...các trường như hiện tại, TripData? tripData}); // tạo item mới; tripData null thì dùng currentTrip
Future<bool> saveToWishlist({...});                              // false nếu wishlist đã có cùng name
Future<void> updateWorkspace(SavedItem updated);                 // upsert theo id
Future<void> removeSavedItem(SavedItem item);                    // delete theo id, itinerary cascade
Future<void> saveItinerary(ItineraryPlan plan);                  // plan.tripId phải khác rỗng
```

Luồng `load()` (gọi ở `initState` và mỗi lần `onAuthStateChange`):
1. Mở box, đọc Hive vào state để hiện ngay.
2. Nếu đã đăng nhập: `select` `saved_trips` và `saved_itineraries` với `.eq('user_id', userId)`, thay toàn bộ `_items` và `_itineraries`, ghi đè Hive (xoá key không còn trên cloud). Lỗi mạng thì giữ state từ Hive và `debugPrint`.

Luồng ghi (mẫu chung cho 4 hàm ghi):
1. Nếu chưa đăng nhập: chỉ đổi state và Hive (phục vụ widget test; `AuthGate` không cho vào planner khi chưa đăng nhập).
2. `await client.from(...).upsert(payload, onConflict: 'id')` hoặc `.delete().eq('id', ...)`. `saved_itineraries` dùng `onConflict: 'trip_id'`.
3. Thành công: `setState`, ghi Hive đúng key đó.
4. Thất bại: ném lại exception, không đổi gì.

Payload `saved_trips` như hiện tại, thêm `'id': item.id`, bỏ `cloudId`. Payload `saved_itineraries` thêm `'trip_id'`.

Xoá khỏi provider: `_syncFromSupabase`, `_subscribeToSavedTrips`, `_persistenceQueue`, `_migrateLegacyDataIfNeeded`, kiểm tra trùng tên trong `saveFullTrip`. `addSharedPerson` và `_syncCollaboratorToCloud` giữ nguyên, thay `cloudId` bằng `item.id`.

### 2.6. Screens

- `saved_screen.dart`: mở trip truyền `DestinationDetailScreen(destinationName: item.name, savedItem: item)`. Mọi thao tác ghi đi qua helper `runSave` (await + snackbar lỗi). Ô ghi chú: panel là `StatefulWidget` giữ bản nháp, lưu khi rời ô (`onTapOutside`/`onFieldSubmitted`), không lưu mỗi phím vì mỗi lần ghi là một request cloud. Snackbar sau khi xoá dùng `ScaffoldMessenger` đã capture trước `await`.
- `destination_detail_screen.dart`: thêm tham số `SavedItem? savedItem`, giữ state `SavedItem? _savedItem` khởi tạo từ tham số. `trip` cho AI = `_savedItem?.tripData ?? provider.currentTrip`. Nút Lưu: nếu `_savedItem` đã có (mở từ Saved hoặc đã lưu trong phiên) thì chỉ báo "đã lưu", không tạo thêm; ngược lại `_savedItem = await provider.saveFullTrip(..., tripData: _trip)`. Nút "Tạo itinerary": nếu `_savedItem == null` thì lưu trước rồi mới mở `DestinationPlanScreen(tripId: _savedItem!.id, destinationName: ...)`. Quy tắc: **có itinerary tức là có trip.** Prefetch itinerary dùng `trip.dayCount()`.
- `destination_plan_screen.dart`: nhận `tripId`, `itineraryFor(tripId)`, `numDays = trip.dayCount()`, plan tạo ra gán `tripId` trước khi `await saveItinerary`. Refine cũng vậy.
- `suggestions_screen.dart`: `saveToWishlist` thành `await` trong try/catch.

### 2.7. Test (`test/data/saved_trips_sync_test.dart` mở rộng)

- `SavedItem.fromMap` thiếu `id` sinh UUID hợp lệ; gọi `toMap` rồi `fromMap` lần nữa giữ nguyên `id`.
- Hai `SavedItem` cùng `name` khác `id` round-trip qua `toMap`/`fromMap` vẫn là hai item.
- `ItineraryPlan` round-trip giữ `tripId`.
- `TripData.dayCount()`: 01/06 đến 03/06 cho 3; không có ngày cho fallback 3; 10 ngày kẹp về 7.

### 2.8. Nghiệm thu

- [ ] Tạo hai chuyến "Đà Nẵng" ngày khác nhau: cả hai cùng hiện, mở lại mỗi chuyến đúng ngày và ngân sách của nó, itinerary riêng.
- [ ] Xoá trip trên trình duyệt A, reload trình duyệt B: trip mất và không sống lại.
- [ ] Tắt mạng rồi bấm Lưu: snackbar lỗi, danh sách không đổi. Bật mạng bấm lại: lưu được.
- [ ] Xoá một dòng lịch sử tìm kiếm rồi reload: dòng đó không quay lại.
- [ ] `grep -n "cloudId\|_syncFromSupabase\|_subscribeToSavedTrips" lib/` trả về rỗng.
- [ ] `flutter analyze` không lỗi mới, `flutter test` pass.

---

## 3. Không làm

Realtime cho `saved_trips`. Version itinerary. Bản nháp planner lên cloud. Offline queue, tombstone, so `updated_at`. Xem trip được người khác share (trip_collaborators giữ nguyên nhưng không đọc). Ảnh trong cache. TTL theo feature. Interface `AITravelGateway`.

## 4. Quyết định đã cắt so với roadmap và lý do

| Roadmap ghi | Spec này | Lý do |
|---|---|---|
| Cache 2 tầng Memory + Hive | 1 tầng Hive | Hive Box đã nằm trong RAM, map riêng là trùng lặp |
| Box cache theo user, listener auth | `userId` nối vào key | Một dòng thay cho box switching |
| TTL theo feature | Một TTL 7 ngày | Explore đã có nút refresh |
| Giữ `sanitizeImageUrls`, ảnh trong cache | Bỏ ảnh khỏi cache | Chính phần này từng gây sự cố ảnh; `ImageService` lo ảnh |
| `promptVersion` trong key | Số version trong tên box | Một hằng số thay cho một field ở mọi key |
| Cờ `pendingSync`, ghi nền | `await` cloud, thất bại báo lỗi | Không có hai nguồn phải hoà giải |
| Itinerary có `version`, `is_current` | Một trip một itinerary | Không demo lịch sử version |
| `_currentTrip` lên cloud với `status = 'draft'` | Giữ ở Hive | `search_history` đã ghi yêu cầu, nhập lại chọn từ lịch sử |
| Giữ realtime `saved_trips` | Bỏ | Cloud-first mỗi lần load là đủ |
