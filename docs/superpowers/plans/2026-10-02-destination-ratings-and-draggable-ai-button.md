# Destination Ratings Baseline & Draggable AI Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuẩn hóa số liệu đánh giá điểm đến (100 vote gốc 5 sao, tự động cộng dồn theo đánh giá người dùng) và hỗ trợ kéo thả nút AI Tool tự do trên toàn màn hình.

**Architecture:** 
- Xây dựng tiện ích tính toán `DestinationRatingCalculator` với công thức base 100 votes / 5.0 rating, áp dụng đồng bộ trong database trigger (Supabase SQL migration), model `DestinationSuggestion` và giao diện `DestinationDetailScreen`.
- Chuyển đổi nút AI Tool sang widget `DraggableAIToolsButton` tích hợp `GestureDetector` nhận diện cử chỉ kéo thả, giới hạn trong vùng an toàn `SafeArea` của màn hình và phân biệt click vs drag.

**Tech Stack:** Flutter, Dart, Supabase SQL, Flutter Test.

## Global Constraints

- Không push/commit trực tiếp lên `master`. Nhánh hiện tại: `destination-ratings-and-draggable-ai-button`.
- Tuân thủ quy tắc trong `AGENTS.md`: Mọi số liệu AI sinh là ước tính, không import `google_generative_ai` hoặc `supabase_flutter` trực tiếp trong screens ngoài trừ tầng service/repository.
- `flutter analyze` không lỗi, toàn bộ `flutter test` phải pass.

---

### Task 1: Tiện ích tính toán Rating/Review và Cập nhật Model

**Files:**
- Create: `lib/utils/destination_rating_calculator.dart`
- Modify: `lib/models/destination_suggestion.dart`
- Test: `test/utils/destination_rating_calculator_test.dart`

**Interfaces:**
- Consumes: danh sách điểm đánh giá của người dùng `Iterable<int>` hoặc tổng số đánh giá.
- Produces: `DestinationRatingCalculator.calculateReviewCount(int userReviewCount)` -> `int`, `DestinationRatingCalculator.calculateAverageRating(Iterable<int> ratings)` -> `double`.

- [ ] **Step 1: Viết test cho `DestinationRatingCalculator`**

Tạo `test/utils/destination_rating_calculator_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/utils/destination_rating_calculator.dart';
import 'package:voyz/models/destination_suggestion.dart';

void main() {
  group('DestinationRatingCalculator', () {
    test('returns base 100 votes and 5.0 rating when no user reviews', () {
      expect(DestinationRatingCalculator.calculateReviewCount(0), 100);
      expect(DestinationRatingCalculator.calculateAverageRating([]), 5.0);
    });

    test('correctly calculates new rating and count when user reviews added', () {
      // 1 user review of 4 stars -> (500 + 4) / 101 = 4.990099...
      expect(DestinationRatingCalculator.calculateReviewCount(1), 101);
      final avg1 = DestinationRatingCalculator.calculateAverageRating([4]);
      expect(avg1, closeTo(4.99, 0.01));

      // 5 user reviews of 1 star -> (500 + 5) / 105 = 4.8095...
      expect(DestinationRatingCalculator.calculateReviewCount(5), 105);
      final avg5 = DestinationRatingCalculator.calculateAverageRating([1, 1, 1, 1, 1]);
      expect(avg5, closeTo(4.81, 0.01));
    });
  });

  group('DestinationSuggestion defaults', () {
    test('defaults to 100 reviews and 5.0 rating when 0 or not provided', () {
      final suggestion = DestinationSuggestion.fromSupabase({
        'name': 'Da Nang',
        'image_url': '',
        'match_percent': 90,
        'rating': 0,
        'review_count': 0,
      });
      expect(suggestion.reviewCount, 100);
      expect(suggestion.rating, 5.0);
    });
  });
}
```

- [ ] **Step 2: Chạy test để xác nhận test fail**

Chạy: `flutter test test/utils/destination_rating_calculator_test.dart`
Kỳ vọng: FAIL do chưa tạo `destination_rating_calculator.dart`.

- [ ] **Step 3: Cài đặt `DestinationRatingCalculator` và cập nhật `DestinationSuggestion`**

Tạo `lib/utils/destination_rating_calculator.dart`:
```dart
class DestinationRatingCalculator {
  DestinationRatingCalculator._();

  static const int baseVotes = 100;
  static const double baseRating = 5.0;
  static const double baseScore = baseVotes * baseRating; // 500.0

  static int calculateReviewCount(int userReviewCount) {
    return baseVotes + userReviewCount;
  }

  static double calculateAverageRating(Iterable<int> ratings) {
    if (ratings.isEmpty) return baseRating;
    final totalScore = baseScore + ratings.fold<int>(0, (sum, r) => sum + r);
    final totalCount = baseVotes + ratings.length;
    return totalScore / totalCount;
  }
}
```

Cập nhật `lib/models/destination_suggestion.dart`:
Trong factory `DestinationSuggestion.fromSupabase`, `fromJson`, `fromMap`:
- Nếu `rating <= 0.0` thì gán `5.0`.
- Nếu `reviewCount <= 0` thì gán `100`.

- [ ] **Step 4: Chạy lại test xác nhận pass**

Chạy: `flutter test test/utils/destination_rating_calculator_test.dart`
Kỳ vọng: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/utils/destination_rating_calculator.dart lib/models/destination_suggestion.dart test/utils/destination_rating_calculator_test.dart
git commit -m "feat: add DestinationRatingCalculator and update suggestion defaults"
```

---

### Task 2: Supabase Migration cho Destination Ratings Trigger & Seed

**Files:**
- Create: `supabase/migrations/20261002000100_base_destination_ratings.sql`

**Interfaces:**
- Consumes: bảng `public.destinations`, `public.community_reviews`.
- Produces: trigger `public.refresh_destination_review_stats` tự động tính base 100 vote / 5.0 rating.

- [ ] **Step 1: Tạo file migration**

Tạo `supabase/migrations/20261002000100_base_destination_ratings.sql`:
```sql
-- Update review calculation trigger to incorporate 100 virtual base votes with 5.0 stars
create or replace function public.refresh_destination_review_stats(target_destination_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.destinations d
  set
    rating = (
      select round((500.0 + coalesce(sum(r.rating), 0)) / (100.0 + count(*)), 2)
      from public.community_reviews r
      where r.destination_id = target_destination_id
    ),
    review_count = (
      select 100 + count(*)::integer
      from public.community_reviews r
      where r.destination_id = target_destination_id
    ),
    updated_at = now()
  where d.id = target_destination_id;
end;
$$;

-- Refresh all existing destinations
update public.destinations d
set
  rating = coalesce((
    select round((500.0 + coalesce(sum(r.rating), 0)) / (100.0 + count(*)), 2)
    from public.community_reviews r
    where r.destination_id = d.id
  ), 5.0),
  review_count = coalesce((
    select 100 + count(*)::integer
    from public.community_reviews r
    where r.destination_id = d.id
  ), 100),
  updated_at = now();
```

- [ ] **Step 2: Commit migration**

```bash
git add supabase/migrations/20261002000100_base_destination_ratings.sql
git commit -m "feat: add migration for base 100 votes and 5.0 stars calculation"
```

---

### Task 3: Cập nhật Hiển thị Review & Đánh giá trong DestinationDetailScreen

**Files:**
- Modify: `lib/screens/destination_detail_screen.dart`
- Test: `test/screens/destination_detail_screen_test.dart`

**Interfaces:**
- Consumes: `_reviews` từ `CommunityReviewService`, `DestinationRatingCalculator`.
- Produces: Header số sao `${average.toStringAsFixed(1)} ($totalVotes)` và lưu trip với rating chuẩn.

- [ ] **Step 1: Viết widget test kiểm tra hiển thị số vote và rating gốc**

Tạo/cập nhật `test/screens/destination_detail_screen_test.dart`:
Kiểm tra rằng khi chưa có review, màn hình hiển thị `5.0 (100)`. Khi có 1 review 4 sao, hiển thị `5.0 (101)`.

- [ ] **Step 2: Chạy test để kiểm tra trạng thái ban đầu**

Chạy: `flutter test test/screens/destination_detail_screen_test.dart`

- [ ] **Step 3: Cập nhật `destination_detail_screen.dart`**

Trong `_buildReviewsSection`:
```dart
    final totalVotes = DestinationRatingCalculator.calculateReviewCount(_reviews.length);
    final average = DestinationRatingCalculator.calculateAverageRating(
      _reviews.map((r) => r.rating),
    );
```
Hiển thị:
```dart
    Text(
      '${average.toStringAsFixed(1)} ($totalVotes)',
      style: const TextStyle(color: Color(0xFFFBBF24)),
    ),
```
Trong `_saveCurrentDetail()`:
Thay thế `rating: 4.5, reviewCount: 120` bằng:
```dart
    final totalVotes = DestinationRatingCalculator.calculateReviewCount(_reviews.length);
    final average = DestinationRatingCalculator.calculateAverageRating(
      _reviews.map((r) => r.rating),
    );
    return SavedTripsProvider.of(context).saveFullTrip(
      name: d.name,
      imageUrl: d.imageUrl,
      price: d.totalBudget,
      matchPercent: 98,
      rating: average,
      reviewCount: totalVotes,
      aiInsight: AppLocalizations.of(context)!.defaultAiInsight,
      tripData: _trip,
    );
```

- [ ] **Step 4: Chạy test xác nhận pass**

Chạy: `flutter test test/screens/destination_detail_screen_test.dart`
Kỳ vọng: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/destination_detail_screen.dart test/screens/destination_detail_screen_test.dart
git commit -m "feat: display base 100 votes and recalculated average rating in DestinationDetailScreen"
```

---

### Task 4: Nút AI Tool kéo thả tự do (`DraggableAIToolsButton`)

**Files:**
- Modify: `lib/widgets/shared/ai_tools_button.dart`
- Modify: `lib/main.dart`
- Modify: `test/widgets/ai_tools_button_test.dart`

**Interfaces:**
- Consumes: `navigatorKey: GlobalKey<NavigatorState>`
- Produces: `DraggableAIToolsButton` cho phép kéo di chuyển tự do trên màn hình, không trôi khỏi viền, click để mở `AIToolsScreen`.

- [ ] **Step 1: Viết widget test cho tính năng kéo thả và click của nút AI Tool**

Cập nhật `test/widgets/ai_tools_button_test.dart`:
- Test nút hiển thị đúng ban đầu.
- Test thao tác drag làm thay đổi vị trí của nút.
- Test thao tác tap đơn thuần vẫn mở `AIToolsScreen` (hoặc gọi route push).

- [ ] **Step 2: Chạy test để xác nhận fail**

Chạy: `flutter test test/widgets/ai_tools_button_test.dart`

- [ ] **Step 3: Cài đặt `DraggableAIToolsButton` trong `ai_tools_button.dart` và tích hợp vào `main.dart`**

Trong `lib/widgets/shared/ai_tools_button.dart`:
- Tạo `DraggableAIToolsButton` là `StatefulWidget`:
  - Lưu static `Offset? _savedOffset` để giữ vị trí qua các lần reload hoặc chuyển màn hình.
  - Xử lý `GestureDetector`:
    - `onPanStart`: ghi nhận tọa độ bắt đầu, reset quãng đường kéo `_dragDistance = 0`.
    - `onPanUpdate`: cộng dồn `_dragDistance += details.delta.distance`. Cập nhật tọa độ `_offset` và giới hạn trong `clamp` với viền màn hình (trừ đi padding an toàn và kích thước nút 58x58).
    - `onPanEnd`: nếu `_dragDistance < 5.0`, kích hoạt `_openAITools()`.
- Cập nhật `lib/main.dart`:
  - Thay thế `Positioned(right: 16, bottom: ...)` bằng `DraggableAIToolsButton(navigatorKey: _navigatorKey)`.

- [ ] **Step 4: Chạy lại test xác nhận pass**

Chạy: `flutter test test/widgets/ai_tools_button_test.dart`
Kỳ vọng: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/shared/ai_tools_button.dart lib/main.dart test/widgets/ai_tools_button_test.dart
git commit -m "feat: make AI tools button freely draggable across screen"
```

---

### Task 5: Kiểm tra tổng thể (Analyze & Tests)

**Files:**
- Toàn bộ repo

- [ ] **Step 1: Chạy `flutter analyze`**

Chạy: `flutter analyze`
Kỳ vọng: No issues found!

- [ ] **Step 2: Chạy toàn bộ bộ test**

Chạy: `flutter test`
Kỳ vọng: All tests pass!

- [ ] **Step 3: Commit nếu có sửa đổi bổ sung**

```bash
git commit -m "chore: verify tests and static analysis pass"
```
