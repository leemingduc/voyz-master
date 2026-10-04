# Loading And Image Effects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Triển khai hiệu ứng gõ chữ Messenger, hiệu ứng chờ gợi ý chuyến đi đa thông điệp sinh động, và hiệu ứng shimmer skeleton tải ảnh kèm fade-in mềm mại cho app AIVIVU.

**Architecture:** Tạo 3 thành phần UI độc lập, tái sử dụng cao (`TypingIndicatorBubble`, `ShimmerLoadingBox` tích hợp trong `DestinationImage`, và `PlannerGeneratingCard`), sau đó tích hợp vào `SmartPlannerScreen` và `ChatScreen`.

**Tech Stack:** Flutter / Dart, `CachedNetworkImage`, `AppTheme`. Không thêm thư viện bên ngoài.

## Global Constraints
- Tuân thủ quy tắc `AGENTS.md`: code đơn giản, ngắn gọn, không thêm dependencies mới vào `pubspec.yaml`.
- Tất cả animation phải có khả năng dispose sạch sẽ để tránh memory leak.
- Tất cả test chạy pass 100% bằng `flutter test`.

---

### Task 1: Component `TypingIndicatorBubble` (Messenger-Style Typing Dots)

**Files:**
- Create: `lib/widgets/shared/typing_indicator_bubble.dart`
- Test: `test/widgets/typing_indicator_bubble_test.dart`

**Interfaces:**
- Produces: `class TypingIndicatorBubble extends StatefulWidget`
  - Constructor: `const TypingIndicatorBubble({super.key, this.label})`
  - Khi không truyền label: chỉ hiện 3 chấm nảy (Messenger style).
  - Khi có label (optional): hiện thêm dòng text mờ bên cạnh nếu cần.

- [ ] **Step 1: Write failing test for TypingIndicatorBubble**

Create `test/widgets/typing_indicator_bubble_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/shared/typing_indicator_bubble.dart';

void main() {
  testWidgets('TypingIndicatorBubble renders AI avatar and 3 dots', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TypingIndicatorBubble(),
        ),
      ),
    );

    // Verify AI sparkle icon exists
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

    // Verify typing dots container exists
    expect(find.byType(TypingIndicatorBubble), findsOneWidget);

    // Pump frames to verify animation runs without errors
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/typing_indicator_bubble_test.dart`  
Expected: FAIL (file or class not found)

- [ ] **Step 3: Implement TypingIndicatorBubble**

Create `lib/widgets/shared/typing_indicator_bubble.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:voyz/theme/app_theme.dart';

/// Hiệu ứng gõ chữ 3 chấm nảy (Messenger style typing indicator) của AI.
class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key, this.label});

  final String? label;

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: AppTheme.brandGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 5),
                _buildDot(1),
                const SizedBox(width: 5),
                _buildDot(2),
                if (widget.label != null && widget.label!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.label!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final start = index * 0.2;
    final end = start + 0.5;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        double offset = 0.0;
        if (value >= start && value <= end) {
          final progress = (value - start) / 0.5;
          // Sin curve for bounce: 0 -> -4 -> 0
          offset = -4.0 * (1.0 - (2.0 * progress - 1.0).abs());
        }

        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppTheme.primaryPink.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/typing_indicator_bubble_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/shared/typing_indicator_bubble.dart test/widgets/typing_indicator_bubble_test.dart
git commit -m "feat: add TypingIndicatorBubble widget with 3-dot bouncing animation"
```

---

### Task 2: Shimmer Placeholder & Smooth Fade-in cho `DestinationImage`

**Files:**
- Modify: `lib/widgets/shared/destination_image.dart`
- Test: `test/widgets/destination_image_test.dart`

**Interfaces:**
- `DestinationImage` giữ nguyên API:
  `DestinationImage({super.key, required this.imageUrl, required this.destinationName, this.fit = BoxFit.cover, this.isLoading = false})`
  (Hỗ trợ thêm `isLoading` tùy chọn nếu màn hình cha muốn báo đang nạp ảnh).
- Produces: `ShimmerLoadingBox` dùng nội bộ hoặc dùng chung cho hiệu ứng quét sáng skeleton.

- [ ] **Step 1: Write test for DestinationImage loading shimmer**

Create `test/widgets/destination_image_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/shared/destination_image.dart';

void main() {
  testWidgets('DestinationImage renders ShimmerLoadingBox when imageUrl is empty and loading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DestinationImage(
            imageUrl: '',
            destinationName: 'Đà Nẵng',
            isLoading: true,
          ),
        ),
      ),
    );

    // Verify shimmer widget renders when loading
    expect(find.byType(ShimmerLoadingBox), findsOneWidget);
  });

  testWidgets('DestinationImage renders Fallback with name when not loading and empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DestinationImage(
            imageUrl: '',
            destinationName: 'Đà Lạt',
            isLoading: false,
          ),
        ),
      ),
    );

    expect(find.text('Đà Lạt'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/destination_image_test.dart`  
Expected: FAIL (`isLoading` not defined or `ShimmerLoadingBox` not found)

- [ ] **Step 3: Implement ShimmerLoadingBox and update DestinationImage**

Update `lib/widgets/shared/destination_image.dart`:
- Thêm `final bool isLoading;` vào `DestinationImage` (mặc định `false`, hoặc tự động `true` nếu `imageUrl.isEmpty && destinationName.isNotEmpty`).
- Tích hợp `ShimmerLoadingBox`: animation lặp lại quét gradient sáng từ trái qua phải, ở giữa có icon ảnh mờ chuyển động thở.
- Cấu hình `CachedNetworkImage` với `placeholder: (_, _) => const ShimmerLoadingBox()`, `fadeInDuration: const Duration(milliseconds: 400)`, `fadeInCurve: Curves.easeIn`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/destination_image_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/shared/destination_image.dart test/widgets/destination_image_test.dart
git commit -m "feat: add ShimmerLoadingBox and smooth fade-in to DestinationImage"
```

---

### Task 3: Component `PlannerGeneratingCard` (Cosmic Suggestions Loading Card)

**Files:**
- Create: `lib/widgets/planner/planner_generating_card.dart`
- Test: `test/widgets/planner_generating_card_test.dart`

**Interfaces:**
- Produces: `class PlannerGeneratingCard extends StatefulWidget`
  - Constructor: `const PlannerGeneratingCard({super.key})`
  - Chu kỳ đổi thông điệp mỗi 2.2 giây giữa 4 câu gợi cảm hứng bằng `Timer.periodic`.
  - Hiệu ứng vệt sáng gradient chạy qua (cosmic shimmer line).

- [ ] **Step 1: Write test for PlannerGeneratingCard**

Create `test/widgets/planner_generating_card_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/planner/planner_generating_card.dart';

void main() {
  testWidgets('PlannerGeneratingCard cycles messages and renders shimmer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlannerGeneratingCard(),
        ),
      ),
    );

    // Initial message exists
    expect(find.byType(PlannerGeneratingCard), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

    // Fast-forward 2.5 seconds to verify message cycles
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/planner_generating_card_test.dart`  
Expected: FAIL (file or class not found)

- [ ] **Step 3: Implement PlannerGeneratingCard**

Create `lib/widgets/planner/planner_generating_card.dart` với:
- `Timer.periodic(const Duration(milliseconds: 2200))` đổi index thông điệp.
- `AnimatedSwitcher` chuyển đổi mượt mà giữa các thông điệp.
- Thanh tiến trình phát sáng shimmer gradient.
- Dispose sạch sẽ `Timer` và `AnimationController`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/planner_generating_card_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/planner/planner_generating_card.dart test/widgets/planner_generating_card_test.dart
git commit -m "feat: add PlannerGeneratingCard with cycling messages and cosmic glow"
```

---

### Task 4: Tích hợp vào `SmartPlannerScreen`, `TripOptionCard` và `ChatScreen`

**Files:**
- Modify: `lib/screens/smart_planner_screen.dart`
- Modify: `lib/widgets/planner/trip_option_card.dart`
- Modify: `lib/screens/chat_screen.dart`

- [ ] **Step 1: Update TripOptionCard to show shimmer while option.imageUrl is empty**
Trong `lib/widgets/planner/trip_option_card.dart`:
Khi `option.imageUrl.isEmpty`, truyền `isLoading: true` vào `DestinationImage` để hiển thị skeleton shimmer cho ảnh điểm đến thay vì khung rỗng.

- [ ] **Step 2: Update SmartPlannerScreen to use PlannerGeneratingCard and TypingIndicatorBubble**
Trong `lib/screens/smart_planner_screen.dart`:
Khi `_isSending == true`:
- Nếu lượt đang gọi là `forceOptions` (hoặc đang tạo phương án chuyến đi): Hiển thị `PlannerGeneratingCard()`.
- Nếu là hội thoại bình thường: Hiển thị `TypingIndicatorBubble()`.

- [ ] **Step 3: Update ChatScreen to use TypingIndicatorBubble**
Trong `lib/screens/chat_screen.dart`:
Thay thế `CircularProgressIndicator` cũ bằng `TypingIndicatorBubble()`.

- [ ] **Step 4: Run full test suite and analyze**
Run:
`flutter analyze`
`flutter test`  
Expected: All tests PASS, no new warnings.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/smart_planner_screen.dart lib/widgets/planner/trip_option_card.dart lib/screens/chat_screen.dart
git commit -m "feat: integrate Messenger typing bubble and cosmic suggestion loader into planner and chat"
```
