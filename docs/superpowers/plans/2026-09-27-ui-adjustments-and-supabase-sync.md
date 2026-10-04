# UI Adjustments, Profile Audio, Supabase Save Sync, and Default Vietnamese Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển nút AI Tools thành nút tròn icon độc đáo và nâng cao vị trí; gỡ bỏ nút âm thanh nổi và đưa vào ProfileScreen thành hàng ngang rõ trạng thái; đồng bộ lưu địa điểm vào Supabase với nút bookmark ở đầu trang; đặt tiếng Việt làm ngôn ngữ mặc định.

**Architecture:** Tinh chỉnh các widget UI chia sẻ, cập nhật state của Profile và DestinationDetail, cập nhật cấu hình mặc định trong LocaleSettingsStore và main.dart.

**Tech Stack:** Flutter / Dart, Supabase, Hive, AppTheme. Không thêm dependencies ngoài.

## Global Constraints
- Tuân thủ quy định `AGENTS.md`.
- Tất cả unit test & widget test pass 100%.

---

### Task 1: Nút AI Tool icon-only đặc trưng AIVIVU & nâng vị trí

**Files:**
- Modify: `lib/widgets/shared/ai_tools_button.dart`
- Modify: `lib/main.dart`
- Test: `test/widgets/ai_tools_button_test.dart`

**Interfaces:**
- `AIToolsButton`: chuyển từ `FloatingActionButton.extended` sang nút tròn 48x48 gradient AIVIVU chỉ có icon `Icons.auto_awesome`.
- Trong `lib/main.dart`: vị trí `bottom` đổi từ `+ 92` thành `+ 124`.

- [ ] **Step 1: Write test for icon-only AIToolsButton**

Create `test/widgets/ai_tools_button_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/shared/ai_tools_button.dart';

void main() {
  testWidgets('AIToolsButton renders icon without text', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: Scaffold(
          body: AIToolsButton(navigatorKey: navKey),
        ),
      ),
    );

    // Should not render text 'AI Tools' inside button
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    expect(find.text('AI Tools'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/ai_tools_button_test.dart`  
Expected: FAIL (text 'AI Tools' currently exists)

- [ ] **Step 3: Update AIToolsButton and main.dart**

Update `lib/widgets/shared/ai_tools_button.dart` to make it a circular icon button with gradient and cyan border.  
Update `lib/main.dart` bottom position to `+ 124`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/ai_tools_button_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/shared/ai_tools_button.dart lib/main.dart test/widgets/ai_tools_button_test.dart
git commit -m "feat: redesign AIToolsButton as compact circular icon and raise position above chat dock"
```

---

### Task 2: Di chuyển nút âm thanh khỏi màn hình chính, đưa vào ProfileScreen

**Files:**
- Modify: `lib/services/background_music_service.dart`
- Modify: `lib/main.dart`
- Modify: `lib/screens/profile_screen.dart`
- Test: `test/screens/profile_music_setting_test.dart`

**Interfaces:**
- `BackgroundMusicService`: thêm `final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);` và cập nhật trong `play()`, `pause()`, `stop()`.
- `main.dart`: xóa `BackgroundMusicButton` khỏi `Stack`.
- `ProfileScreen`: thêm thẻ `_MusicSettingTile` nằm ngang trong danh sách cài đặt, hiển thị icon, tiêu đề, trạng thái "Đang bật" / "Đang tắt" và Switch.

- [ ] **Step 1: Write test for music setting in ProfileScreen**

Create `test/screens/profile_music_setting_test.dart` checking music setting tile renders.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/profile_music_setting_test.dart`  
Expected: FAIL

- [ ] **Step 3: Implement isPlayingNotifier, remove from main.dart, add to ProfileScreen**

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/profile_music_setting_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/services/background_music_service.dart lib/main.dart lib/screens/profile_screen.dart test/screens/profile_music_setting_test.dart
git commit -m "feat: move background music toggle into ProfileScreen as horizontal setting row"
```

---

### Task 3: Bổ sung nút Bookmark đầu trang & Đồng bộ lưu địa điểm vào Supabase

**Files:**
- Modify: `lib/screens/destination_detail_screen.dart`
- Test: `test/screens/destination_detail_save_test.dart`

**Interfaces:**
- Trong `DestinationDetailScreen`:
  - `_HeroSection`: thêm nút bookmark bên cạnh nút share.
  - Đồng bộ `_savedItem` với `SavedTripsProvider.savedItems` khi khởi tạo màn hình.
  - Nhấn bookmark thì lưu hoặc thông báo đã lưu.

- [ ] **Step 1: Write test for DestinationDetailScreen top bookmark button**

Create `test/screens/destination_detail_save_test.dart`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/destination_detail_save_test.dart`  
Expected: FAIL

- [ ] **Step 3: Implement top bookmark button and auto-detect saved state in DestinationDetailScreen**

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/destination_detail_save_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/destination_detail_screen.dart test/screens/destination_detail_save_test.dart
git commit -m "feat: add top bookmark button and sync saved status in DestinationDetailScreen"
```

---

### Task 4: Thiết lập ngôn ngữ mặc định là Tiếng Việt (`vi`)

**Files:**
- Modify: `lib/data/locale_provider.dart`
- Modify: `lib/main.dart`
- Test: `test/data/locale_default_vi_test.dart`

**Interfaces:**
- `LocaleSettingsStore.load()`: nếu `saved == null`, trả về `Locale('vi')`.
- `lib/main.dart`: fallback mặc định `Locale('vi')`.

- [ ] **Step 1: Write test for default Vietnamese locale**

Create `test/data/locale_default_vi_test.dart`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/locale_default_vi_test.dart`  
Expected: FAIL

- [ ] **Step 3: Update LocaleSettingsStore and main.dart**

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/locale_default_vi_test.dart`  
Expected: PASS

- [ ] **Step 5: Run full test suite & analyze**

Run:
`flutter analyze`
`flutter test`  
Expected: All tests PASS, no new warnings.

- [ ] **Step 6: Commit**

```bash
git add lib/data/locale_provider.dart lib/main.dart test/data/locale_default_vi_test.dart
git commit -m "feat: set default app language to Vietnamese"
```
