# AIVIVU Mascot Loading Effects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây dựng linh vật "Bé tên lửa thám hiểm AIVIVU" độc đáo và component `AivivuLoadingIndicator` thay thế các vòng quay `CircularProgressIndicator` đơn điệu, đồng thời bổ sung dấu ấn riêng AIVIVU vào hiệu ứng nạp ảnh `DestinationImage`.

**Architecture:** Sử dụng Flutter `CustomPainter` để vẽ linh vật tên lửa chibi vector sắc nét, hoạt họa bay bổng mượt mà, bao bọc trong component `AivivuLoadingIndicator`, sau đó tích hợp vào `DestinationDetailScreen`, `DestinationPlanScreen`, `CulturalTipsScreen`, `ExploreScreen`, và `DestinationImage`.

**Tech Stack:** Flutter / Dart, CustomPainter, AnimationController. Không dùng dependency ngoài.

## Global Constraints
- Tuân thủ quy định `AGENTS.md`.
- Tất cả animation phải có khả năng dispose sạch sẽ.
- Tất cả unit test & widget test pass 100%.

---

### Task 1: Component `AivivuRocketMascot` (Linh vật Tên Lửa Thám Hiểm AIVIVU)

**Files:**
- Create: `lib/widgets/shared/aivivu_rocket_mascot.dart`
- Test: `test/widgets/aivivu_rocket_mascot_test.dart`

**Interfaces:**
- Produces: `class AivivuRocketMascot extends StatefulWidget`
  - Constructor: `const AivivuRocketMascot({super.key, this.size = 72.0})`
  - Hoạt họa: Bồng bềnh nhấp nhô (bobbing), nghiêng góc nhẹ, ngọn lửa đuôi và vệt sao stardust co giãn nhịp nhàng.

- [ ] **Step 1: Write test for AivivuRocketMascot**

Create `test/widgets/aivivu_rocket_mascot_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/shared/aivivu_rocket_mascot.dart';

void main() {
  testWidgets('AivivuRocketMascot renders custom paint and runs animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AivivuRocketMascot(size: 80)),
        ),
      ),
    );

    expect(find.byType(AivivuRocketMascot), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Pump animation frames
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/aivivu_rocket_mascot_test.dart`  
Expected: FAIL (file or class not found)

- [ ] **Step 3: Implement AivivuRocketMascot with CustomPainter**

Create `lib/widgets/shared/aivivu_rocket_mascot.dart`:
- `CustomPainter` vẽ thân tên lửa bo tròn, vòm kính mắt cười cyan thân thiện, cánh vây gradient tím hồng, ngọn lửa đuôi vàng hồng, và 3 hạt sao stardust.
- `AnimationController` điều khiển chuyển động lượn sóng và nhấp nháy stardust.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/aivivu_rocket_mascot_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/shared/aivivu_rocket_mascot.dart test/widgets/aivivu_rocket_mascot_test.dart
git commit -m "feat: add AivivuRocketMascot vector chibi rocket widget"
```

---

### Task 2: Component `AivivuLoadingIndicator` (Biểu tượng loading đặc trưng toàn app)

**Files:**
- Create: `lib/widgets/shared/aivivu_loading_indicator.dart`
- Test: `test/widgets/aivivu_loading_indicator_test.dart`

**Interfaces:**
- Produces: `class AivivuLoadingIndicator extends StatelessWidget`
  - Constructor: `const AivivuLoadingIndicator({super.key, this.message, this.size = 80.0})`
  - Kết hợp `AivivuRocketMascot` ở trên và dòng thông điệp du lịch ở dưới.

- [ ] **Step 1: Write test for AivivuLoadingIndicator**

Create `test/widgets/aivivu_loading_indicator_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/shared/aivivu_loading_indicator.dart';
import 'package:voyz/widgets/shared/aivivu_rocket_mascot.dart';

void main() {
  testWidgets('AivivuLoadingIndicator renders mascot and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AivivuLoadingIndicator(message: 'AIVIVU đang chuẩn bị hành trình...'),
        ),
      ),
    );

    expect(find.byType(AivivuLoadingIndicator), findsOneWidget);
    expect(find.byType(AivivuRocketMascot), findsOneWidget);
    expect(find.text('AIVIVU đang chuẩn bị hành trình...'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/aivivu_loading_indicator_test.dart`  
Expected: FAIL (file or class not found)

- [ ] **Step 3: Implement AivivuLoadingIndicator**

Create `lib/widgets/shared/aivivu_loading_indicator.dart`:
- Hiển thị `AivivuRocketMascot`.
- Dưới tên lửa là vòng hào quang mờ và dòng thông điệp (mặc định *"AIVIVU đang bay đến điểm đến của bạn..."* hoặc theo `message`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/aivivu_loading_indicator_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/shared/aivivu_loading_indicator.dart test/widgets/aivivu_loading_indicator_test.dart
git commit -m "feat: add AivivuLoadingIndicator with rocket mascot and glowing message"
```

---

### Task 3: Thêm nét riêng AIVIVU vào hiệu ứng nạp ảnh `DestinationImage`

**Files:**
- Modify: `lib/widgets/shared/destination_image.dart`
- Modify: `test/widgets/destination_image_test.dart`

**Interfaces:**
- Trong `ShimmerLoadingBox`:
  - Thay vì icon phong cảnh mờ đơn điệu, hiển thị icon tên lửa mini AIVIVU (`Icons.rocket_launch_rounded` hoặc mini mascot) phát sáng gradient hồng tím.
  - Hiển thị dòng chữ: *"AIVIVU đang nạp ảnh..."*
  - Hiệu ứng thở nhẹ nhàng (breathing pulse).

- [ ] **Step 1: Update test for DestinationImage branded shimmer**

Update `test/widgets/destination_image_test.dart` để kiểm tra có chữ "AIVIVU đang nạp ảnh..." hoặc icon rocket khi `isLoading: true`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/destination_image_test.dart`  
Expected: FAIL

- [ ] **Step 3: Update ShimmerLoadingBox in DestinationImage**

Cập nhật `lib/widgets/shared/destination_image.dart` với biểu tượng rocket phát sáng và nhãn "AIVIVU đang nạp ảnh...".

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/destination_image_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/shared/destination_image.dart test/widgets/destination_image_test.dart
git commit -m "feat: enhance DestinationImage shimmer with AIVIVU rocket badge and loading text"
```

---

### Task 4: Thay thế CircularProgressIndicator bằng AivivuLoadingIndicator trên các màn hình chính

**Files:**
- Modify: `lib/screens/destination_detail_screen.dart`
- Modify: `lib/screens/destination_plan_screen.dart`
- Modify: `lib/screens/cultural_tips_screen.dart`
- Modify: `lib/screens/explore_screen.dart`

- [ ] **Step 1: Update destination_detail_screen.dart**
Thay `CircularProgressIndicator` ở trạng thái chờ detail bằng `AivivuLoadingIndicator(message: 'AIVIVU đang nạp thông tin điểm đến...')`.

- [ ] **Step 2: Update destination_plan_screen.dart**
Thay `CircularProgressIndicator` ở trạng thái chờ itinerary bằng `AivivuLoadingIndicator(message: 'AIVIVU đang tối ưu lịch trình chi tiết...')`.

- [ ] **Step 3: Update cultural_tips_screen.dart**
Thay `CircularProgressIndicator` bằng `AivivuLoadingIndicator(message: 'AIVIVU đang tổng hợp cẩm nang văn hoá...')`.

- [ ] **Step 4: Update explore_screen.dart**
Thay `CircularProgressIndicator` bằng `AivivuLoadingIndicator(message: 'AIVIVU đang khám phá các điểm đến...')`.

- [ ] **Step 5: Run full verification suite**
Run:
`flutter analyze`
`flutter test`  
Expected: All tests PASS, no new warnings.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/destination_detail_screen.dart lib/screens/destination_plan_screen.dart lib/screens/cultural_tips_screen.dart lib/screens/explore_screen.dart
git commit -m "feat: replace generic spinners with AivivuLoadingIndicator across main screens"
```
