# In-App Destination Sharing with Friends Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable users to share destinations and saved trips directly with friends inside the app chat, complete with custom notes and interactive destination cards in chat messages.

**Architecture:** Create a `ShareDestinationBottomSheet` widget that queries `FriendsService` for accepted friends, sends structured destination share messages, integrates with `DestinationDetailScreen` & `SavedScreen`, and renders clickable destination cards in `FriendChatScreen`.

**Tech Stack:** Flutter, Supabase (`FriendsService`), Dart.

## Global Constraints
- All friend interactions use `FriendsService`.
- If user has no friends or is not logged in, provide a graceful "Copy Link" fallback option.
- Maintain clean glassmorphic UI matching `AppTheme`.

---

### Task 1: Create `ShareDestinationBottomSheet` Widget & Tests

**Files:**
- Create: `lib/widgets/shared/share_destination_bottom_sheet.dart`
- Create: `test/widgets/share_destination_bottom_sheet_test.dart`

**Interfaces:**
- Consumes: `FriendsService.instance.getFriendships()`, `FriendsService.instance.sendMessage()`.
- Produces: `ShareDestinationBottomSheet.show(context, {destinationName, destinationId, imageUrl, extraInfo})`.

- [ ] **Step 1: Write widget test for `ShareDestinationBottomSheet`**

Create `test/widgets/share_destination_bottom_sheet_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/shared/share_destination_bottom_sheet.dart';

void main() {
  testWidgets('renders ShareDestinationBottomSheet header and copy link fallback button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShareDestinationBottomSheet(
            destinationName: 'Đà Nẵng',
            destinationId: 'da-nang-1',
          ),
        ),
      ),
    );

    expect(find.text('Chia sẻ địa điểm'), findsOneWidget);
    expect(find.text('Đà Nẵng'), findsOneWidget);
    expect(find.text('Sao chép liên kết'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/share_destination_bottom_sheet_test.dart`
Expected: FAIL (widget `ShareDestinationBottomSheet` not created yet).

- [ ] **Step 3: Implement `ShareDestinationBottomSheet` in `lib/widgets/shared/share_destination_bottom_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voyz/services/friends_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/glass_card.dart';

class ShareDestinationBottomSheet extends StatefulWidget {
  const ShareDestinationBottomSheet({
    super.key,
    required this.destinationName,
    this.destinationId,
    this.imageUrl,
    this.subtitle,
  });

  final String destinationName;
  final String? destinationId;
  final String? imageUrl;
  final String? subtitle;

  static Future<void> show(
    BuildContext context, {
    required String destinationName,
    String? destinationId,
    String? imageUrl,
    String? subtitle,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ShareDestinationBottomSheet(
        destinationName: destinationName,
        destinationId: destinationId,
        imageUrl: imageUrl,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<ShareDestinationBottomSheet> createState() =>
      _ShareDestinationBottomSheetState();
}

class _ShareDestinationBottomSheetState
    extends State<ShareDestinationBottomSheet> {
  final _noteController = TextEditingController();
  List<Friendship> _friends = [];
  final Set<String> _selectedFriendshipIds = {};
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final friendships = await FriendsService.instance.getFriendships();
      final accepted = friendships.where((f) => f.isAccepted).toList();
      if (!mounted) return;
      setState(() {
        _friends = accepted;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendToSelected() async {
    if (_selectedFriendshipIds.isEmpty) return;
    setState(() => _isSending = true);

    final note = _noteController.text.trim();
    final messageBody =
        '📍 [Địa điểm] ${widget.destinationName}\n'
        '${widget.subtitle != null ? "${widget.subtitle}\n" : ""}'
        '${note.isNotEmpty ? "💬 Lời nhắn: $note\n" : ""}'
        '🔗 voyz://destination?name=${Uri.encodeComponent(widget.destinationName)}';

    try {
      for (final friendshipId in _selectedFriendshipIds) {
        await FriendsService.instance.sendMessage(friendshipId, messageBody);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã chia sẻ "${widget.destinationName}" cho ${_selectedFriendshipIds.length} người bạn!',
          ),
          backgroundColor: AppTheme.primaryPink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _copyLink() {
    final link = 'https://voyz.app/destination?name=${Uri.encodeComponent(widget.destinationName)}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép liên kết địa điểm!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chia sẻ địa điểm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.destinationName,
                    style: TextStyle(
                      color: AppTheme.primaryPink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Thêm lời nhắn (ví dụ: Đi nơi này với mình nhé!)...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chọn bạn bè trong app:',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null || _friends.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white54, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chưa có danh sách bạn bè kết nối trong app.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _friends.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, index) {
                  final friendship = _friends[index];
                  final isSelected = _selectedFriendshipIds.contains(friendship.id);
                  final friend = friendship.friend;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedFriendshipIds.remove(friendship.id);
                        } else {
                          _selectedFriendshipIds.add(friendship.id);
                        }
                      });
                    },
                    child: Container(
                      width: 84,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryPink.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryPink
                              : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppTheme.primaryPink.withValues(alpha: 0.3),
                            child: Text(
                              friend.displayName.isNotEmpty
                                  ? friend.displayName[0].toUpperCase()
                                  : 'T',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            friend.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyLink,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Sao chép liên kết'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_selectedFriendshipIds.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendToSelected,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, size: 16),
                    label: Text('Gửi (${_selectedFriendshipIds.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/share_destination_bottom_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/shared/share_destination_bottom_sheet.dart test/widgets/share_destination_bottom_sheet_test.dart; git commit -m "feat: add ShareDestinationBottomSheet widget and tests"
```

---

### Task 2: Integrate `ShareDestinationBottomSheet` into `DestinationDetailScreen` & `SavedScreen`

**Files:**
- Modify: `lib/screens/destination_detail_screen.dart`
- Modify: `lib/screens/saved_screen.dart`

- [ ] **Step 1: Update `_onShare` in `DestinationDetailScreen`**

Replace Toast-only `_onShare` method in `lib/screens/destination_detail_screen.dart`:
```dart
  void _onShare(BuildContext context) {
    if (_detail == null) return;
    ShareDestinationBottomSheet.show(
      context,
      destinationName: _detail!.name,
      destinationId: widget.destinationId,
      imageUrl: _detail!.imageUrl,
      subtitle: '${_detail!.category} • ${_detail!.rating}★',
    );
  }
```

- [ ] **Step 2: Update Share Action in `SavedScreen`**

In `lib/screens/saved_screen.dart`, update `_ActionChipButton` for Share to open `ShareDestinationBottomSheet.show`:
```dart
  ShareDestinationBottomSheet.show(
    context,
    destinationName: item.destinationName,
    destinationId: item.tripId,
  );
```

- [ ] **Step 3: Run static checks**

Run: `flutter analyze`
Expected: ZERO errors.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/destination_detail_screen.dart lib/screens/saved_screen.dart; git commit -m "feat: integrate ShareDestinationBottomSheet into DestinationDetailScreen and SavedScreen"
```

---

### Task 3: Interactive Shared Destination Cards in `FriendChatScreen`

**Files:**
- Modify: `lib/screens/friends_screen.dart`

- [ ] **Step 1: Update `_ChatBubble` in `FriendChatScreen` to detect destination messages**

In `FriendChatScreen` inside `lib/screens/friends_screen.dart`:
Detect if `message.body` contains `📍 [Địa điểm]` or `voyz://destination?name=`.
If detected, render a special interactive destination card inside the chat bubble with:
- Location pin icon & destination name
- Subtitle / personal note
- Button: **"Xem chi tiết địa điểm"** -> opens `DestinationDetailScreen(destinationId: '', destinationName: parsedName, category: 'Khám phá')`.

- [ ] **Step 2: Run `flutter analyze` and `flutter test`**

Run: `flutter analyze`
Run: `flutter test`
Expected: ZERO errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/friends_screen.dart; git commit -m "feat: render interactive shared destination card in FriendChatScreen"
```

---
