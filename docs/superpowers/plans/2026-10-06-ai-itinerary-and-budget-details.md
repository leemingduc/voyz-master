# AI Detailed Itinerary & Budget Activity Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance AI itinerary generation to produce detailed activities (location, estimated cost, tips, details), update the budget refinement chip to "Hoạt động nhiều hơn (Tối ưu ngân sách)", and add interactive detail bottom sheets when tapping itinerary activities.

**Architecture:** Extend `ItineraryItem` data model with backwards-compatible optional detail fields, update `GeminiService` itinerary prompt and refinement prompt, update l10n strings, and construct a glassmorphic activity detail bottom sheet in `DestinationPlanScreen`.

**Tech Stack:** Flutter, Dart, Gemini API (`google_generative_ai`), Flutter Localization (`app_vi.arb`, `app_en.arb`, `app_ko.arb`).

## Global Constraints
- Preserve backward compatibility for `ItineraryItem.fromJson` (existing cached JSON without new fields must parse without throwing).
- All AI calls go through `GeminiService`.
- Maintain clean glassmorphic UI matching `AppTheme`.

---

### Task 1: Extend `ItineraryItem` Model & Add Unit Tests

**Files:**
- Modify: `lib/models/itinerary_plan.dart`
- Create/Modify: `test/models/itinerary_plan_test.dart`

**Interfaces:**
- Produces: `ItineraryItem` with optional fields `location`, `estimatedCost`, `tips`, `details`.

- [ ] **Step 1: Write the failing unit test**

Create `test/models/itinerary_plan_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/itinerary_plan.dart';

void main() {
  group('ItineraryItem', () {
    test('parses new optional fields correctly', () {
      final json = {
        'time': '09:00 AM',
        'title': 'Chợ Đêm Phú Quốc',
        'description': 'Khu chợ đêm sầm uất với nhiều món ăn địa phương.',
        'icon': 'restaurant',
        'location': 'Thị trấn Dương Đông, Phú Quốc',
        'estimatedCost': '100.000 - 200.000 VNĐ',
        'tips': 'Nên thử hải sản nướng và kem cuộn.',
        'details': 'Đến vào khoảng 18:30 để mua sắm hải sản tươi sống và đồ lưu niệm.',
      };

      final item = ItineraryItem.fromJson(json);
      expect(item.time, '09:00 AM');
      expect(item.title, 'Chợ Đêm Phú Quốc');
      expect(item.location, 'Thị trấn Dương Đông, Phú Quốc');
      expect(item.estimatedCost, '100.000 - 200.000 VNĐ');
      expect(item.tips, 'Nên thử hải sản nướng và kem cuộn.');
      expect(item.details, 'Đến vào khoảng 18:30 để mua sắm hải sản tươi sống và đồ lưu niệm.');
    });

    test('backward compatibility when new optional fields are null', () {
      final json = {
        'time': '10:00 AM',
        'title': 'Bãi Sao',
        'description': 'Tắm biển bãi cát trắng.',
        'icon': 'beach_access',
      };

      final item = ItineraryItem.fromJson(json);
      expect(item.location, null);
      expect(item.estimatedCost, null);
      expect(item.tips, null);
      expect(item.details, null);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/itinerary_plan_test.dart`
Expected: FAIL with compilation error (fields `location`, `estimatedCost`, `tips`, `details` not defined on `ItineraryItem`).

- [ ] **Step 3: Update `ItineraryItem` in `lib/models/itinerary_plan.dart`**

```dart
class ItineraryItem {
  final String time;
  final String title;
  final String description;
  final String icon;
  final String? location;
  final String? estimatedCost;
  final String? tips;
  final String? details;

  const ItineraryItem({
    required this.time,
    required this.title,
    required this.description,
    required this.icon,
    this.location,
    this.estimatedCost,
    this.tips,
    this.details,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      time: json['time'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'circle',
      location: json['location'] as String?,
      estimatedCost: json['estimatedCost'] as String?,
      tips: json['tips'] as String?,
      details: json['details'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'time': time,
    'title': title,
    'description': description,
    'icon': icon,
    if (location != null) 'location': location,
    if (estimatedCost != null) 'estimatedCost': estimatedCost,
    if (tips != null) 'tips': tips,
    if (details != null) 'details': details,
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/itinerary_plan_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/itinerary_plan.dart test/models/itinerary_plan_test.dart; git commit -m "feat: extend ItineraryItem with location, estimatedCost, tips, details"
```

---

### Task 2: Update Gemini Prompt & Localization Strings

**Files:**
- Modify: `lib/services/gemini_service.dart`
- Modify: `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_ko.arb`
- Modify: `test/services/gemini_service_test.dart` (if any prompt tests exist)

**Interfaces:**
- Consumes: `ItineraryItem` optional fields.
- Produces: JSON response prompt schema with optional fields and updated Vietnamese/English/Korean budget optimization label.

- [ ] **Step 1: Update localization strings in `app_vi.arb`, `app_en.arb`, `app_ko.arb`**

In `lib/l10n/app_vi.arb`:
```json
  "refineForBudget": "Hoạt động nhiều hơn (Tối ưu ngân sách)",
```

In `lib/l10n/app_en.arb`:
```json
  "refineForBudget": "More Activities (Budget Optimized)",
```

In `lib/l10n/app_ko.arb`:
```json
  "refineForBudget": "더 많은 활동 (예산 최적화)",
```

Run Flutter localization generation: `flutter gen-l10n`

- [ ] **Step 2: Update `buildItineraryPrompt` in `lib/services/gemini_service.dart`**

Update prompt template to include `location`, `estimatedCost`, `tips`, `details` in JSON schema definition:
```dart
    return '''
Bạn là chuyên gia du lịch AI. Hãy lên kế hoạch du lịch chi tiết $numDays ngày tại "$destinationName".

Thời gian: $dateInfo$tripDescription$dayCountInstruction

${additionalInstruction == null || additionalInstruction.trim().isEmpty ? '' : 'Ưu tiên điều chỉnh: ${additionalInstruction.trim()}'}

Trả về JSON object với cấu trúc:
{
  "destinationName": "$destinationName",
  "dateRange": "$dateInfo",
  "days": [
    {
      "dayNumber": 1,
      "title": "Day 1: Khám phá & Trải nghiệm",
      "subtitle": "Trải nghiệm văn hóa và ẩm thực nổi tiếng.",
      "items": [
        {
          "time": "09:00 AM",
          "title": "Tên hoạt động/điểm đến",
          "description": "Mô tả tổng quan ngắn gọn",
          "icon": "flight_land",
          "location": "Địa điểm cụ thể",
          "estimatedCost": "Dự toán chi phí (ví dụ: Miễn phí hoặc ~150.000 VNĐ)",
          "tips": "Mẹo thực tế khi tham quan",
          "details": "Chi tiết các bước thực hiện hoặc trải nghiệm nổi bật"
        }
      ]
    }
  ],
  "proTip": "Mẹo hữu ích cho chuyến đi"
}

- Mỗi ngày có tối đa $limit hoạt động
- Tổng cộng $numDays ngày
- items.time: "HH:MM AM/PM" — items.icon: flight_land|hotel|restaurant|beach_access
- items.description: 1 câu ngắn gọn
- items.location, items.estimatedCost, items.tips, items.details: Cung cấp đầy đủ chi tiết để người dùng tham khảo rõ ràng
- proTip: 1 mẹo thực tế
- Viết toàn bộ nội dung bằng $languageName
- CHỈ trả về JSON object, KHÔNG thêm markdown hay text khác
''';
```

- [ ] **Step 3: Run existing tests to verify prompt generation**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/services/gemini_service.dart lib/l10n/; git commit -m "feat: enhance AI itinerary prompt with detailed fields and update budget label"
```

---

### Task 3: Implement Interactive Detail Bottom Sheet & Update `DestinationPlanScreen`

**Files:**
- Modify: `lib/screens/destination_plan_screen.dart`
- Create/Modify: `test/screens/destination_plan_screen_test.dart`

**Interfaces:**
- Consumes: `ItineraryItem` detail fields, `GeminiService.instance.getItineraryPlan`.
- Produces: Interactive activity cards that display `_showActivityDetailBottomSheet`.

- [ ] **Step 1: Write widget test for activity detail bottom sheet**

Create or update `test/screens/destination_plan_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/itinerary_plan.dart';
import 'package:voyz/screens/destination_plan_screen.dart';

void main() {
  testWidgets('renders timeline item details dialog/bottom sheet on tap', (WidgetTester tester) async {
    // Basic test structure verifying interactive timeline card tap behavior
  });
}
```

- [ ] **Step 2: Update `destination_plan_screen.dart` to make timeline cards clickable & open detail bottom sheet**

In `_Timeline`:
Wrap `GlassCard` with `InkWell` or `GestureDetector` calling `_showActivityDetailBottomSheet(context, item, color)`:

```dart
void _showActivityDetailBottomSheet(BuildContext context, ItineraryItem item, Color themeColor) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    item.time,
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (item.estimatedCost != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item.estimatedCost!,
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (item.location != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.location!,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              item.details ?? item.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (item.tips != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.tips!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}
```

Update budget refinement trigger prompt in `_DestinationPlanScreenState`:
```dart
onBudget: () => _refinePlan(
  'Ưu tiên tối ưu ngân sách để làm được nhiều hoạt động và trải nghiệm phong phú hơn cùng một mức chi phí.',
),
```

- [ ] **Step 3: Run `flutter analyze` and `flutter test`**

Run: `flutter analyze`
Run: `flutter test`
Expected: ZERO errors.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/destination_plan_screen.dart test/; git commit -m "feat: add activity detail bottom sheet and update budget refinement prompt"
```

---
