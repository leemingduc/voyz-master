# AI Tool Navigation Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable AI Tool Chat to parse structured AI action payloads and automatically/interactively execute navigation commands to app screens and destination pages.

**Architecture:** Add `AiAction` data model, update `ChatMessage` to hold optional `action`, update `GeminiService.chatWithActions()` to instruct Gemini to generate structured action JSON when appropriate, and update `ChatScreen` to display interactive Action Cards and perform navigation.

**Tech Stack:** Dart, Flutter, Gemini AI API (`google_generative_ai`).

## Global Constraints
- AGENTS.md git rules: Never commit directly to `master`. Work on feature branch `fix-save-status-and-ai-navigation`.
- All AI calls must go through `GeminiService`.
- Must pass `flutter analyze` with 0 new errors and `flutter test` pass 100%.

---

### Task 1: Create `AiAction` Model and Update `ChatMessage`

**Files:**
- Create: `lib/models/ai_action.dart`
- Test: `test/models/ai_action_test.dart`
- Modify: `lib/models/chat_message.dart`

**Interfaces:**
- Consumes: None
- Produces: `AiAction`, `AiActionType`, `ChatMessage.action`

- [ ] **Step 1: Write the failing test for `AiAction` model**

Create `test/models/ai_action_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/ai_action.dart';

void main() {
  group('AiAction Tests', () {
    test('fromJson parses navigateDestination action correctly', () {
      final json = {
        'type': 'navigateDestination',
        'target': 'Phú Quốc',
        'label': 'Mở trang Phú Quốc',
        'parameters': {'numDays': 3}
      };

      final action = AiAction.fromJson(json);
      expect(action.type, equals(AiActionType.navigateDestination));
      expect(action.target, equals('Phú Quốc'));
      expect(action.label, equals('Mở trang Phú Quốc'));
      expect(action.parameters?['numDays'], equals(3));
    });

    test('fromJson handles invalid or missing fields gracefully', () {
      final json = <String, dynamic>{};
      final action = AiAction.fromJson(json);
      expect(action.type, equals(AiActionType.navigateScreen));
      expect(action.target, equals(''));
      expect(action.label, equals(''));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/ai_action_test.dart`
Expected: FAIL (missing `lib/models/ai_action.dart`)

- [ ] **Step 3: Implement `AiAction` model**

Create `lib/models/ai_action.dart`:
```dart
enum AiActionType {
  navigateDestination,
  navigateScreen,
  setTripData;

  static AiActionType fromString(String? value) {
    switch (value) {
      case 'navigateDestination':
        return AiActionType.navigateDestination;
      case 'setTripData':
        return AiActionType.setTripData;
      case 'navigateScreen':
      default:
        return AiActionType.navigateScreen;
    }
  }

  String toFormattedString() {
    switch (this) {
      case AiActionType.navigateDestination:
        return 'navigateDestination';
      case AiActionType.setTripData:
        return 'setTripData';
      case AiActionType.navigateScreen:
        return 'navigateScreen';
    }
  }
}

class AiAction {
  final AiActionType type;
  final String target;
  final String label;
  final Map<String, dynamic>? parameters;

  const AiAction({
    required this.type,
    required this.target,
    required this.label,
    this.parameters,
  });

  factory AiAction.fromJson(Map<String, dynamic> json) {
    return AiAction(
      type: AiActionType.fromString(json['type']?.toString()),
      target: json['target']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      parameters: json['parameters'] is Map<String, dynamic>
          ? json['parameters'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.toFormattedString(),
        'target': target,
        'label': label,
        if (parameters != null) 'parameters': parameters,
      };
}
```

- [ ] **Step 4: Update `ChatMessage` model**

In `lib/models/chat_message.dart`, add `final AiAction? action` parameter and update `toMap`/`fromMap`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/models/ai_action_test.dart test/models/chat_message_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/models/ai_action.dart lib/models/chat_message.dart test/models/ai_action_test.dart
git commit -m "feat: add AiAction model and update ChatMessage"
```

---

### Task 2: Implement `GeminiService.chatWithActions`

**Files:**
- Modify: `lib/services/gemini_service.dart`
- Modify/Create: `test/services/gemini_service_action_test.dart`

**Interfaces:**
- Consumes: `AiAction` model
- Produces: `GeminiService.chatWithActions(...)` returning `({String reply, AiAction? action})`

- [ ] **Step 1: Write failing test for `chatWithActions` parser**

Create `test/services/gemini_service_action_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/ai_action.dart';
import 'package:voyz/services/gemini_service.dart';

void main() {
  group('GeminiService chatWithActions Parser Tests', () {
    test('parseChatActionResponse correctly extracts JSON action block', () {
      const response = '''
Mình sẽ đưa bạn tới Côn Đảo ngay nhé!
```json
{
  "action": {
    "type": "navigateDestination",
    "target": "Côn Đảo",
    "label": "Mở trang Côn Đảo"
  }
}
```''';

      final parsed = GeminiService.instance.parseChatActionResponse(response);
      expect(parsed.reply.trim(), equals('Mình sẽ đưa bạn tới Côn Đảo ngay nhé!'));
      expect(parsed.action, isNotNull);
      expect(parsed.action?.type, equals(AiActionType.navigateDestination));
      expect(parsed.action?.target, equals('Côn Đảo'));
    });

    test('parseChatActionResponse handles standard plain text without action', () {
      const response = 'Côn Đảo có bãi Đầm Trầu rất đẹp.';
      final parsed = GeminiService.instance.parseChatActionResponse(response);
      expect(parsed.reply, equals(response));
      expect(parsed.action, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/gemini_service_action_test.dart`
Expected: FAIL (`parseChatActionResponse` not found)

- [ ] **Step 3: Implement `parseChatActionResponse` and `chatWithActions` in `GeminiService`**

In `lib/services/gemini_service.dart`:
Add helper `parseChatActionResponse` and `chatWithActions` method instructing model to output ````json {"action": {...}} ```` block when navigation is requested.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/gemini_service_action_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/services/gemini_service.dart test/services/gemini_service_action_test.dart
git commit -m "feat: add chatWithActions parsing in GeminiService"
```

---

### Task 3: Render Action Cards and Handle Navigation in `ChatScreen`

**Files:**
- Modify: `lib/screens/chat_screen.dart`
- Test: `test/screens/chat_screen_test.dart`

**Interfaces:**
- Consumes: `AiAction`, `GeminiService.chatWithActions`
- Produces: Interactive Action Card UI & navigation in `ChatScreen`

- [ ] **Step 1: Update `_sendMessage` in `ChatScreen` to call `chatWithActions`**

In `lib/screens/chat_screen.dart`:
Update `_sendMessage` to parse response from `GeminiService.instance.chatWithActions(...)` and append `ChatMessage.ai(result.reply, action: result.action)`.

- [ ] **Step 2: Add Action Card Widget to `_ChatBubble`**

In `_ChatBubble` in `lib/screens/chat_screen.dart`:
If `message.action != null`, render a stylish action button/card below the message bubble:
```dart
if (message.action != null) ...[
  const SizedBox(height: 8),
  ElevatedButton.icon(
    onPressed: () => _executeAiAction(message.action!),
    icon: const Icon(Icons.rocket_launch, size: 16),
    label: Text(message.action!.label.isNotEmpty ? message.action!.label : 'Thực hiện'),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
]
```

- [ ] **Step 3: Implement `_executeAiAction` in `_ChatScreenState`**

Add navigation handler:
```dart
void _executeAiAction(AiAction action) {
  switch (action.type) {
    case AiActionType.navigateDestination:
      if (action.target.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestinationDetailScreen(destinationName: action.target),
          ),
        );
      }
      break;
    case AiActionType.navigateScreen:
      final target = action.target.toLowerCase();
      if (target.contains('saved') || target.contains('lưu')) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SavedScreen()),
          (route) => false,
        );
      } else if (target.contains('explore') || target.contains('khám phá')) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ExploreScreen()),
          (route) => false,
        );
      } else if (target.contains('friends') || target.contains('bạn')) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const FriendsScreen()),
          (route) => false,
        );
      } else if (target.contains('planner') || target.contains('kế hoạch')) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SmartPlannerScreen()),
          (route) => false,
        );
      }
      break;
    case AiActionType.setTripData:
      // Option to update SavedTripsProvider.currentTrip
      break;
  }
}
```

- [ ] **Step 4: Run full verification suite**

Run: `flutter analyze && flutter test`
Expected: 0 errors, ALL tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/chat_screen.dart
git commit -m "feat: render action cards and handle navigation in ChatScreen"
```
