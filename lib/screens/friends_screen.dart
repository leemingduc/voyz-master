import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/data/friend_message_visibility_store.dart';
import 'package:voyz/models/chat_theme_model.dart';
import 'package:voyz/data/friend_message_notification_settings.dart';
import 'package:voyz/screens/chat_theme_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/screens/smart_planner_screen.dart';
import 'package:voyz/screens/destination_detail_screen.dart';
import 'package:voyz/services/friends_service.dart';
import 'package:voyz/services/friend_message_notification_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/profile_avatar.dart';
import 'package:voyz/widgets/shared/account_menu_button.dart';
import 'package:voyz/widgets/shared/aivivu_header.dart';
import 'package:voyz/widgets/shared/aivivu_loading_indicator.dart';
import 'package:voyz/widgets/shared/aivivu_rocket_mascot.dart';
import 'package:voyz/widgets/shared/aivivu_wordmark.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  List<Friendship> _friendships = [];
  List<SocialProfile> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  _FriendsListTab _selectedTab = _FriendsListTab.friends;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final friendships = await FriendsService.instance.getFriendships();
      if (!mounted) return;
      setState(() {
        _friendships = friendships;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _search() async {
    setState(() => _isSearching = true);
    try {
      final results = await FriendsService.instance.searchProfiles(
        _searchController.text,
      );
      if (!mounted) return;
      setState(() => _searchResults = results);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendRequest(SocialProfile profile) async {
    try {
      await FriendsService.instance.sendFriendRequest(profile.userId);
      if (!mounted) return;
      _showMessage('Friend request sent');
      await _load();
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _accept(Friendship friendship) async {
    try {
      await FriendsService.instance.acceptFriendRequest(friendship.id);
      await FriendMessageNotificationService.instance.refresh();
      if (!mounted) return;
      _showMessage('Friend request accepted');
      await _load();
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _removeFriend(Friendship friendship) async {
    final friend = friendship.friend;
    final name = friend.displayName.isEmpty ? friend.email : friend.displayName;
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Xóa bạn bè?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn sẽ xóa $name khỏi danh sách bạn bè. Cuộc trò chuyện của hai người cũng sẽ bị xóa.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa bạn'),
          ),
        ],
      ),
    );
    if (shouldRemove != true || !mounted) return;

    try {
      await FriendsService.instance.removeFriend(friendship.id);
      await FriendMessageNotificationService.instance.refresh();
      if (!mounted) return;
      _showMessage('Đã xóa $name khỏi danh sách bạn bè');
      await _load();
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
    }
  }

  void _openChat(Friendship friendship) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendChatScreen(friendship: friendship),
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SmartPlannerScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ExploreScreen()),
          (route) => false,
        );
        break;
      case 2:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SavedScreen()),
          (route) => false,
        );
        break;
      case 3:
        break;
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : const Color(0xFF475569),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, int>>(
      valueListenable:
          FriendMessageNotificationService.instance.unreadByFriendship,
      builder: (context, unreadByFriendship, _) {
        final accepted = _friendships
            .where((f) => f.status == 'accepted')
            .toList();
        final pending = _friendships
            .where((f) => f.status == 'pending')
            .toList();
        final friendUserIds = accepted
            .map((friendship) => friendship.friend.userId)
            .where((userId) => userId.isNotEmpty)
            .toSet();

        return Scaffold(
          bottomSheet: BottomNavBar(currentIndex: 3, onTap: _onNavTap),
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.4,
                colors: [AppTheme.surfaceDark, AppTheme.backgroundDark],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _Header(onRefresh: _load),
                  Expanded(
                    child: _isLoading
                        ? const AivivuLoadingIndicator(size: 80)
                        : _error != null
                        ? _ErrorState(error: _error!, onRetry: _load)
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                            children: [
                              _SearchPanel(
                                controller: _searchController,
                                isSearching: _isSearching,
                                results: _searchResults,
                                friendUserIds: friendUserIds,
                                onSearch: _search,
                                onSendRequest: _sendRequest,
                              ),
                              const SizedBox(height: 18),
                              _FriendsListTabs(
                                selectedTab: _selectedTab,
                                friendsCount: accepted.length,
                                requestsCount: pending.length,
                                onChanged: (tab) {
                                  setState(() => _selectedTab = tab);
                                },
                              ),
                              const SizedBox(height: 10),
                              if (_selectedTab == _FriendsListTab.friends)
                                if (accepted.isEmpty)
                                  const _EmptyPanel(
                                    icon: Icons.people_outline,
                                    title: 'No friends yet',
                                    subtitle:
                                        'Search by email or display name to add someone.',
                                  )
                                else
                                  ...accepted.map(
                                    (friendship) => _FriendTile(
                                      friendship: friendship,
                                      onTap: () => _openChat(friendship),
                                      onRemove: () => _removeFriend(friendship),
                                      unreadCount:
                                          unreadByFriendship[friendship.id] ??
                                          0,
                                    ),
                                  )
                              else if (pending.isEmpty)
                                const _EmptyPanel(
                                  icon: Icons.inbox_outlined,
                                  title: 'No pending requests',
                                  subtitle:
                                      'Incoming and outgoing requests appear here.',
                                )
                              else
                                ...pending.map(
                                  (friendship) => _RequestTile(
                                    friendship: friendship,
                                    onAccept: () => _accept(friendship),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _FriendsListTab { friends, requests }

class _FriendsListTabs extends StatelessWidget {
  const _FriendsListTabs({
    required this.selectedTab,
    required this.friendsCount,
    required this.requestsCount,
    required this.onChanged,
  });

  final _FriendsListTab selectedTab;
  final int friendsCount;
  final int requestsCount;
  final ValueChanged<_FriendsListTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FriendsTabButton(
              label: 'Friends',
              icon: Icons.people_alt_outlined,
              count: friendsCount,
              isSelected: selectedTab == _FriendsListTab.friends,
              onTap: () => onChanged(_FriendsListTab.friends),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _FriendsTabButton(
              label: 'Requests',
              icon: Icons.mark_email_unread_outlined,
              count: requestsCount,
              isSelected: selectedTab == _FriendsListTab.requests,
              onTap: () => onChanged(_FriendsListTab.requests),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsTabButton extends StatelessWidget {
  const _FriendsTabButton({
    required this.label,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected ? Colors.white : Colors.white70;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label, $count',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryPink.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryPink.withValues(alpha: 0.7)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foregroundColor),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: isSelected ? 0.18 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Friends',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
          const SizedBox(width: 4),
          const AccountMenuButton(),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.isSearching,
    required this.results,
    required this.friendUserIds,
    required this.onSearch,
    required this.onSendRequest,
  });

  final TextEditingController controller;
  final bool isSearching;
  final List<SocialProfile> results;
  final Set<String> friendUserIds;
  final VoidCallback onSearch;
  final ValueChanged<SocialProfile> onSendRequest;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find friends',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.45,
                    letterSpacing: 0.2,
                  ),
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText: 'Email or display name',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 15,
                      height: 1.45,
                      letterSpacing: 0.2,
                    ),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.cyan,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: isSearching ? null : onSearch,
                child: isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: AivivuRocketMascot(size: 16),
                      )
                    : const Text('Search'),
              ),
            ],
          ),
          if (results.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...results.map(
              (profile) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _Avatar(url: profile.avatarUrl),
                title: Text(
                  profile.displayName.isEmpty
                      ? profile.email
                      : profile.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  profile.email,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
                trailing: friendUserIds.contains(profile.userId)
                    ? const _FriendStatusBadge()
                    : IconButton(
                        tooltip: 'Add friend',
                        onPressed: () => onSendRequest(profile),
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          color: AppTheme.primaryPink,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FriendStatusBadge extends StatelessWidget {
  const _FriendStatusBadge();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đã là bạn bè',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cyan.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.45)),
        ),
        child: const Text(
          'Đã là bạn bè',
          style: TextStyle(
            color: AppTheme.cyan,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friendship,
    required this.onTap,
    required this.onRemove,
    required this.unreadCount,
  });

  final Friendship friendship;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final friend = friendship.friend;
    return _Panel(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _Avatar(url: friend.avatarUrl),
        title: Text(
          friend.displayName.isEmpty ? friend.email : friend.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          friend.email,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Xóa bạn bè',
              onPressed: onRemove,
              icon: const Icon(
                Icons.person_remove_outlined,
                color: Colors.white70,
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.white70),
                if (unreadCount > 0)
                  Positioned(
                    top: -8,
                    right: -10,
                    child: _UnreadBadge(count: unreadCount),
                  ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.primaryPink,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.friendship, required this.onAccept});

  final Friendship friendship;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final currentId = FriendsService.instance.currentUserId;
    final isIncoming = friendship.addresseeId == currentId;
    final friend = friendship.friend;
    return _Panel(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _Avatar(url: friend.avatarUrl),
        title: Text(
          friend.displayName.isEmpty ? friend.email : friend.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          isIncoming ? 'Wants to connect' : 'Request sent',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
        trailing: isIncoming
            ? FilledButton(onPressed: onAccept, child: const Text('Accept'))
            : const Icon(Icons.schedule, color: Colors.white54),
      ),
    );
  }
}

class FriendChatScreen extends StatefulWidget {
  const FriendChatScreen({super.key, required this.friendship});

  final Friendship friendship;

  @override
  State<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends State<FriendChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<FriendMessage> _messages = [];
  StreamSubscription<List<FriendMessage>>? _streamSub;
  StreamSubscription<FriendChatTheme?>? _themeStreamSub;
  RealtimeChannel? _themeBroadcastChannel;
  bool _isSending = false;
  bool _showEmojiPicker = false;
  // IDs of locally recalled messages — guards against stream restoring deleted rows
  final Set<String> _recalledIds = {};
  final Set<String> _hiddenMessageIds = {};
  DateTime? _clearedAt;
  // Active chat theme
  ChatThemePreset _chatTheme = kChatThemes.first;

  final List<String> _quickEmojis = [
    '👋',
    '❤️',
    '✈️',
    '🔥',
    '✨',
    '🎉',
    '😊',
    '🙌',
    '👍',
    '💬',
  ];

  @override
  void initState() {
    super.initState();
    FriendMessageNotificationService.instance.openConversation(
      widget.friendship.id,
    );
    _initializeMessages();
    _loadTheme();
  }

  Future<void> _initializeMessages() async {
    final userId = FriendsService.instance.currentUserId;
    try {
      final results = await Future.wait<Object?>([
        FriendMessageVisibilityStore.hiddenMessageIdsForUser(userId),
        FriendMessageVisibilityStore.clearedAtForUser(
          userId: userId,
          friendshipId: widget.friendship.id,
        ),
      ]);
      if (!mounted) return;
      _hiddenMessageIds.addAll(results[0]! as Set<String>);
      _clearedAt = results[1] as DateTime?;
    } catch (error) {
      debugPrint('Friend message visibility setup error: $error');
    }

    try {
      final remoteClearedAt = await FriendsService.instance
          .conversationClearedAtForCurrentUser(widget.friendship.id);
      if (mounted &&
          remoteClearedAt != null &&
          (_clearedAt == null || remoteClearedAt.isAfter(_clearedAt!))) {
        _clearedAt = remoteClearedAt;
        await FriendMessageVisibilityStore.clearConversationForUser(
          userId: userId,
          friendshipId: widget.friendship.id,
          clearedAt: remoteClearedAt,
        );
      }
    } catch (error) {
      // Keep the on-device value as a fallback when the migration has not
      // been applied yet or the device is temporarily offline.
      debugPrint('Friend conversation clear sync error: $error');
    }
    if (mounted) _initRealtimeMessages();
  }

  Future<void> _loadTheme() async {
    String? id;
    try {
      id = (await FriendsService.instance.getChatTheme(
        widget.friendship.id,
      ))?.themeId;
    } catch (error) {
      debugPrint('Friend chat theme load error: $error');
    }
    id ??= await ChatThemeStore.load(widget.friendship.id);
    if (!mounted) return;
    setState(() => _chatTheme = ChatThemeStore.resolve(id));
    _listenToChatTheme();
    _listenToChatThemeBroadcast();
  }

  void _listenToChatTheme() {
    try {
      _themeStreamSub = FriendsService.instance
          .streamChatTheme(widget.friendship.id)
          .listen(
            (change) {
              if (!mounted || change == null) return;
              final theme = ChatThemeStore.resolve(change.themeId);
              if (_chatTheme.id != theme.id) {
                setState(() => _chatTheme = theme);
              }
              ChatThemeStore.save(widget.friendship.id, theme.id);
            },
            onError: (error) {
              debugPrint('Friend chat theme stream error: $error');
            },
          );
    } catch (error) {
      debugPrint('Friend chat theme stream setup error: $error');
    }
  }

  void _listenToChatThemeBroadcast() {
    try {
      _themeBroadcastChannel = FriendsService.instance
          .subscribeToChatThemeBroadcast(
            friendshipId: widget.friendship.id,
            onThemeChanged: (payload) {
              if (!mounted) return;
              final themeId = payload['theme_id']?.toString();
              final changedBy = payload['changed_by_user_id']?.toString();
              if (themeId == null || changedBy == null) return;
              _applyIncomingChatTheme(
                themeId: themeId,
                changedByUserId: changedBy,
              );
            },
          );
    } catch (error) {
      debugPrint('Friend chat theme broadcast setup error: $error');
    }
  }

  void _applyIncomingChatTheme({
    required String themeId,
    required String changedByUserId,
  }) {
    if (changedByUserId == FriendsService.instance.currentUserId) return;
    final theme = ChatThemeStore.resolve(themeId);
    if (_chatTheme.id == theme.id) return;
    setState(() => _chatTheme = theme);
    ChatThemeStore.save(widget.friendship.id, theme.id);
  }

  Future<void> _openThemePicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThemeScreen(
          currentThemeId: _chatTheme.id,
          onThemeSelected: (theme) async {
            if (theme.id == _chatTheme.id) return;
            try {
              await FriendsService.instance.changeChatTheme(
                friendshipId: widget.friendship.id,
                themeId: theme.id,
                themeName: theme.name,
              );
              final broadcastChannel = _themeBroadcastChannel;
              if (broadcastChannel != null) {
                try {
                  await FriendsService.instance.broadcastChatThemeChange(
                    channel: broadcastChannel,
                    themeId: theme.id,
                    changedByUserId: FriendsService.instance.currentUserId,
                  );
                } catch (error) {
                  debugPrint('Friend chat theme broadcast error: $error');
                }
              }
              await ChatThemeStore.save(widget.friendship.id, theme.id);
              if (!mounted) return;
              setState(() => _chatTheme = theme);
            } catch (error) {
              if (mounted) _showMessage(error.toString(), isError: true);
            }
          },
        ),
      ),
    );
  }

  void _initRealtimeMessages() {
    _loadMessages();
    try {
      _streamSub = FriendsService.instance
          .streamMessages(widget.friendship.id)
          .listen(
            (messages) {
              if (!mounted) return;
              // Filter out any messages recalled locally to prevent stream from restoring them
              final filtered = messages.where(_isVisibleMessage).toList();
              setState(() => _messages = filtered);
              FriendMessageNotificationService.instance.markRead(
                widget.friendship.id,
              );
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToBottom(),
              );
            },
            onError: (error) {
              debugPrint('Friend chat realtime stream error: $error');
            },
          );
    } catch (e) {
      debugPrint('Friend chat stream setup error: $e');
    }
  }

  @override
  void dispose() {
    FriendMessageNotificationService.instance.closeConversation(
      widget.friendship.id,
    );
    _streamSub?.cancel();
    _themeStreamSub?.cancel();
    final broadcastChannel = _themeBroadcastChannel;
    if (broadcastChannel != null) {
      FriendsService.instance.closeRealtimeChannel(broadcastChannel);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final messages = await FriendsService.instance.getMessages(
        widget.friendship.id,
      );
      if (!mounted) return;
      // Filter out any locally recalled messages (guards against server race conditions)
      final filtered = messages.where(_isVisibleMessage).toList();
      setState(() => _messages = filtered);
      FriendMessageNotificationService.instance.markRead(widget.friendship.id);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (error) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _isVisibleMessage(FriendMessage message) {
    final clearedAt = _clearedAt;
    return !_recalledIds.contains(message.id) &&
        !_hiddenMessageIds.contains(message.id) &&
        (clearedAt == null || message.createdAt.isAfter(clearedAt));
  }

  Future<void> _send([String? customText]) async {
    final textToSend = customText ?? _messageController.text;
    final body = textToSend.trim();
    if (body.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await FriendsService.instance.sendMessage(widget.friendship.id, body);
      if (customText == null) {
        _messageController.clear();
      }
      await _loadMessages(silent: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateHeader(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return 'Hôm nay';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'Hôm qua';
    }
    final dayStr = local.day.toString().padLeft(2, '0');
    final monthStr = local.month.toString().padLeft(2, '0');
    return '$dayStr/$monthStr/${local.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final locA = a.toLocal();
    final locB = b.toLocal();
    return locA.year == locB.year &&
        locA.month == locB.month &&
        locA.day == locB.day;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : const Color(0xFF475569),
      ),
    );
  }

  Future<void> _deleteForMe(FriendMessage message) async {
    setState(() {
      _hiddenMessageIds.add(message.id);
      _messages.removeWhere((item) => item.id == message.id);
    });
    try {
      await FriendMessageVisibilityStore.hideForUser(
        userId: FriendsService.instance.currentUserId,
        messageId: message.id,
      );
      if (mounted) _showMessage('Đã xóa tin nhắn ở phía bạn');
    } catch (error) {
      if (!mounted) return;
      setState(() => _hiddenMessageIds.remove(message.id));
      await _loadMessages(silent: true);
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _clearConversationForMe() async {
    final clearedAt = DateTime.now();
    final previousClearedAt = _clearedAt;
    final previousMessages = List<FriendMessage>.from(_messages);
    setState(() {
      _clearedAt = clearedAt;
      _messages = [];
    });
    try {
      await FriendsService.instance.clearConversationForCurrentUser(
        friendshipId: widget.friendship.id,
        clearedAt: clearedAt,
      );
    } catch (error) {
      // The local marker still keeps this device consistent while a later
      // session can retry syncing to Supabase.
      debugPrint('Friend conversation clear save error: $error');
    }
    try {
      await FriendMessageVisibilityStore.clearConversationForUser(
        userId: FriendsService.instance.currentUserId,
        friendshipId: widget.friendship.id,
        clearedAt: clearedAt,
      );
      if (mounted) _showMessage('Đã xóa cuộc trò chuyện ở phía bạn');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _clearedAt = previousClearedAt;
        _messages = previousMessages;
      });
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _recallForEveryone(FriendMessage message) async {
    // Optimistic update: hide immediately in UI
    setState(() {
      _recalledIds.add(message.id);
      _messages.removeWhere((m) => m.id == message.id);
    });
    try {
      await FriendsService.instance.deleteMessage(message.id);
      if (!mounted) return;
      _showMessage('Đã thu hồi tin nhắn cho cả hai bên');
    } catch (error) {
      if (!mounted) return;
      // Revert optimistic update on failure — message was not deleted on server
      setState(() => _recalledIds.remove(message.id));
      await _loadMessages(silent: true);
      _showMessage(error.toString(), isError: true);
    }
  }

  void _showOptionsSheet(FriendMessage message, bool isMine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.white70),
                title: const Text(
                  'Sao chép tin nhắn',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.body));
                  _showMessage('Đã sao chép tin nhắn');
                },
              ),
              if (isMine)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Xóa ở phía bạn',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Tin nhắn vẫn hiển thị với bạn bè',
                    style: TextStyle(color: Colors.white54),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteForMe(message);
                  },
                ),
              if (isMine)
                ListTile(
                  leading: const Icon(
                    Icons.undo_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Thu hồi cho cả hai bên',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  subtitle: const Text(
                    'Tin nhắn sẽ biến mất với cả hai người',
                    style: TextStyle(color: Colors.white54),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _recallForEveryone(message);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentId = FriendsService.instance.currentUserId;
    final friend = widget.friendship.friend;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AivivuHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const AivivuWordmark(text: 'AIVIVU CHAT', fontSize: 21),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(gradient: _chatTheme.backgroundGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Wallpaper pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.06,
                child: CustomPaint(
                  painter: WallpaperPainter(
                    wallpaper: _chatTheme.wallpaper,
                    color: _chatTheme.accentColor,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _FriendChatHeaderBar(
                  friend: friend,
                  friendshipId: widget.friendship.id,
                  accentColor: _chatTheme.accentColor,
                  onClearChat: _clearConversationForMe,
                  onChangeTheme: _openThemePicker,
                ),
                Expanded(
                  child: _messages.isEmpty
                      ? _EmptyChatView(
                          friend: friend,
                          accentColor: _chatTheme.accentColor,
                          bubbleGradient: _chatTheme.myBubbleGradient,
                          onSendQuick: (text) => _send(text),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMine = message.senderId == currentId;
                            final isLastMessageFromMe =
                                isMine &&
                                !message.isSystem &&
                                !_messages
                                    .skip(index + 1)
                                    .any(
                                      (item) =>
                                          !item.isSystem &&
                                          item.senderId == currentId,
                                    );
                            final showDateHeader =
                                index == 0 ||
                                !_isSameDay(
                                  _messages[index - 1].createdAt,
                                  message.createdAt,
                                );

                            return Column(
                              children: [
                                if (showDateHeader)
                                  _DateChip(
                                    label: _formatDateHeader(message.createdAt),
                                  ),
                                if (message.isSystem)
                                  _SystemChatEvent(
                                    message: message,
                                    accentColor: _chatTheme.accentColor,
                                  )
                                else
                                  _ChatMessageBubble(
                                    message: message,
                                    isMine: isMine,
                                    showDeliveryStatus:
                                        isLastMessageFromMe &&
                                        message.isDelivered,
                                    friend: friend,
                                    timeString: _formatTime(message.createdAt),
                                    myBubbleGradient:
                                        _chatTheme.myBubbleGradient,
                                    myBubbleTextColor:
                                        _chatTheme.myBubbleTextColor,
                                    theirBubbleColor:
                                        _chatTheme.theirBubbleColor,
                                    theirBubbleTextColor:
                                        _chatTheme.theirBubbleTextColor,
                                    accentColor: _chatTheme.accentColor,
                                    onLongPress: () =>
                                        _showOptionsSheet(message, isMine),
                                  ),
                              ],
                            );
                          },
                        ),
                ),
                _ChatInputDock(
                  controller: _messageController,
                  isSending: _isSending,
                  showEmojiPicker: _showEmojiPicker,
                  quickEmojis: _quickEmojis,
                  accentColor: _chatTheme.accentColor,
                  sendGradient: _chatTheme.myBubbleGradient,
                  inputBarColor: _chatTheme.inputBarColor,
                  onToggleEmoji: () {
                    setState(() => _showEmojiPicker = !_showEmojiPicker);
                  },
                  onEmojiSelect: (emoji) {
                    _messageController.text += emoji;
                    _messageController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _messageController.text.length),
                    );
                  },
                  onSend: () => _send(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A persistent conversation event. Unlike a snackbar, this is stored with the
/// messages and is therefore visible to both participants on every device.
class _SystemChatEvent extends StatelessWidget {
  const _SystemChatEvent({required this.message, required this.accentColor});

  final FriendMessage message;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.palette_outlined, size: 15, color: accentColor),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  message.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    required this.isMine,
    required this.showDeliveryStatus,
    required this.friend,
    required this.timeString,
    required this.myBubbleGradient,
    required this.myBubbleTextColor,
    required this.theirBubbleColor,
    required this.theirBubbleTextColor,
    required this.accentColor,
    this.onLongPress,
  });

  final FriendMessage message;
  final bool isMine;
  final bool showDeliveryStatus;
  final SocialProfile friend;
  final String timeString;
  final Gradient myBubbleGradient;
  final Color myBubbleTextColor;
  final Color theirBubbleColor;
  final Color theirBubbleTextColor;
  final Color accentColor;
  final VoidCallback? onLongPress;

  String get _deliveryStatusLabel => message.isRead ? 'Đã xem' : 'Đã nhận';

  Color get _deliveryStatusColor =>
      message.isRead ? AppTheme.cyan : Colors.white.withValues(alpha: 0.65);

  bool get _isDestinationShare => message.body.contains('📍 [Địa điểm]');

  String _parseDestinationName() {
    for (final line in message.body.split('\n')) {
      if (line.startsWith('📍 [Địa điểm] ')) {
        return line.replaceFirst('📍 [Địa điểm] ', '').trim();
      }
    }
    return '';
  }

  String? _parseNote() {
    for (final line in message.body.split('\n')) {
      if (line.startsWith('💬 Lời nhắn: ')) {
        return line.replaceFirst('💬 Lời nhắn: ', '').trim();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isDestinationShare) {
      return _buildDestinationCard(context);
    }
    return _buildNormalBubble(context);
  }

  Widget _buildDestinationCard(BuildContext context) {
    final name = _parseDestinationName();
    final note = _parseNote();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _Avatar(url: friend.avatarUrl),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 270),
                decoration: BoxDecoration(
                  color: isMine
                      ? AppTheme.primaryPink.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  border: Border.all(
                    color: AppTheme.primaryPink.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink.withValues(alpha: 0.2),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(17),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.primaryPink,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Địa điểm được chia sẻ',
                            style: TextStyle(
                              color: AppTheme.primaryPink,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (note != null && note.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              '"$note"',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: name.isNotEmpty
                                  ? () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => DestinationDetailScreen(
                                          destinationName: name,
                                        ),
                                      ),
                                    )
                                  : null,
                              icon: const Icon(Icons.explore, size: 14),
                              label: const Text(
                                'Xem chi tiết địa điểm',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryPink,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timeString,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 10,
                                  ),
                                ),
                                if (isMine) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message.isDelivered
                                        ? Icons.done_all_rounded
                                        : Icons.done_rounded,
                                    size: 13,
                                    color: message.isRead
                                        ? AppTheme.cyan
                                        : Colors.white.withValues(alpha: 0.45),
                                  ),
                                  if (showDeliveryStatus) ...[
                                    const SizedBox(width: 3),
                                    Text(
                                      _deliveryStatusLabel,
                                      style: TextStyle(
                                        color: _deliveryStatusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _Avatar(url: friend.avatarUrl),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 290),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: isMine ? myBubbleGradient : null,
                  color: isMine ? null : theirBubbleColor,
                  boxShadow: isMine
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                  border: isMine
                      ? null
                      : Border.all(color: accentColor.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.body,
                      style: TextStyle(
                        color: isMine
                            ? myBubbleTextColor
                            : theirBubbleTextColor,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeString,
                          style: TextStyle(
                            color:
                                (isMine
                                        ? myBubbleTextColor
                                        : theirBubbleTextColor)
                                    .withValues(alpha: 0.65),
                            fontSize: 11,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isDelivered
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 14,
                            color: message.isRead
                                ? AppTheme.cyan
                                : myBubbleTextColor.withValues(alpha: 0.7),
                          ),
                          if (showDeliveryStatus) ...[
                            const SizedBox(width: 3),
                            Text(
                              _deliveryStatusLabel,
                              style: TextStyle(
                                color: _deliveryStatusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView({
    required this.friend,
    required this.onSendQuick,
    required this.accentColor,
    required this.bubbleGradient,
  });

  final SocialProfile friend;
  final ValueChanged<String> onSendQuick;
  final Color accentColor;
  final Gradient bubbleGradient;

  @override
  Widget build(BuildContext context) {
    final displayName = friend.displayName.isEmpty
        ? friend.email
        : friend.displayName;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: bubbleGradient,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppTheme.surfaceDark,
                child: ProfileAvatar(avatarUrl: friend.avatarUrl, radius: 34),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chat with $displayName',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No messages yet. Send a quick greeting to get started! 👋',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _QuickChip(
                  label: 'Say Hi 👋',
                  accentColor: accentColor,
                  onTap: () => onSendQuick('Hi there! 👋'),
                ),
                _QuickChip(
                  label: 'Plan a trip ✈️',
                  accentColor: accentColor,
                  onTap: () => onSendQuick('Want to plan a trip together? ✈️'),
                ),
                _QuickChip(
                  label: 'How are you? 😊',
                  accentColor: accentColor,
                  onTap: () => onSendQuick('How are you doing today? 😊'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.onTap,
    required this.accentColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: accentColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInputDock extends StatelessWidget {
  const _ChatInputDock({
    required this.controller,
    required this.isSending,
    required this.showEmojiPicker,
    required this.quickEmojis,
    required this.onToggleEmoji,
    required this.onEmojiSelect,
    required this.onSend,
    required this.accentColor,
    required this.sendGradient,
    required this.inputBarColor,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool showEmojiPicker;
  final List<String> quickEmojis;
  final VoidCallback onToggleEmoji;
  final ValueChanged<String> onEmojiSelect;
  final VoidCallback onSend;
  final Color accentColor;
  final Gradient sendGradient;
  final Color inputBarColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: inputBarColor.withValues(alpha: 0.97),
          border: Border(
            top: BorderSide(color: accentColor.withValues(alpha: 0.12)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showEmojiPicker) ...[
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: quickEmojis.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final emoji = quickEmojis[index];
                    return InkWell(
                      onTap: () => onEmojiSelect(emoji),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                IconButton(
                  tooltip: 'Emoji',
                  onPressed: onToggleEmoji,
                  icon: Icon(
                    Icons.sentiment_satisfied_alt,
                    color: showEmojiPicker ? accentColor : Colors.white60,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.45,
                      letterSpacing: 0.2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 14,
                        height: 1.45,
                        letterSpacing: 0.2,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.07),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: accentColor, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: sendGradient,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: isSending ? null : onSend,
                    icon: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: AivivuRocketMascot(size: 18),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.margin});

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: child,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(avatarUrl: url, radius: 20);
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Icon(icon, color: Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 42),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _FriendChatHeaderBar extends StatelessWidget {
  const _FriendChatHeaderBar({
    required this.friend,
    required this.friendshipId,
    required this.accentColor,
    this.onClearChat,
    this.onChangeTheme,
  });

  final SocialProfile friend;
  final String friendshipId;
  final Color accentColor;
  final VoidCallback? onClearChat;
  final VoidCallback? onChangeTheme;

  @override
  Widget build(BuildContext context) {
    final displayName = friend.displayName.isEmpty
        ? friend.email
        : friend.displayName;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(color: accentColor.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              _Avatar(url: friend.avatarUrl),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  friend.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            color: AppTheme.surfaceDark,
            onSelected: (value) {
              if (value == 'clear') {
                onClearChat?.call();
              } else if (value == 'theme') {
                onChangeTheme?.call();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                height: 58,
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: FriendMessageNotificationSettings
                      .instance
                      .mutedFriendshipIds,
                  builder: (context, mutedFriendshipIds, _) {
                    final isEnabled = !mutedFriendshipIds.contains(
                      friendshipId,
                    );
                    return SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: isEnabled,
                      activeTrackColor: AppTheme.cyan,
                      onChanged: (value) {
                        FriendMessageNotificationSettings.instance.setEnabled(
                          friendshipId,
                          value,
                        );
                      },
                      secondary: Icon(
                        isEnabled
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        color: isEnabled ? accentColor : Colors.white54,
                      ),
                      title: const Text(
                        'Thông báo tin nhắn',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, size: 20, color: accentColor),
                    const SizedBox(width: 10),
                    const Text(
                      'Giao diện chat',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.white70),
                    SizedBox(width: 10),
                    Text(
                      'Xóa toàn bộ cuộc trò chuyện',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WallpaperPainter — shared painter used by FriendChatScreen and
// ChatThemeScreen (re-exported from chat_theme_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

class WallpaperPainter extends CustomPainter {
  const WallpaperPainter({required this.wallpaper, required this.color});

  final ChatWallpaper wallpaper;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (wallpaper) {
      case ChatWallpaper.stars:
        _drawStars(canvas, size, paint);
      case ChatWallpaper.bubbles:
        _drawBubbles(canvas, size, paint);
      case ChatWallpaper.waves:
        _drawWaves(canvas, size, paint);
      case ChatWallpaper.grid:
        _drawGrid(canvas, size, paint);
      case ChatWallpaper.hearts:
        _drawHearts(canvas, size, paint);
      case ChatWallpaper.travel:
        _drawPlanes(canvas, size, paint);
      case ChatWallpaper.tread:
        _drawTread(canvas, size, paint);
      case ChatWallpaper.none:
        break;
    }
  }

  void _drawStars(Canvas canvas, Size size, Paint paint) {
    const rng = _WallRng(seed: 42);
    for (var i = 0; i < 80; i++) {
      final x = rng.next(i * 7) * size.width;
      final y = rng.next(i * 13) * size.height;
      final r = rng.next(i * 3) * 3 + 1;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _drawBubbles(Canvas canvas, Size size, Paint p) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const rng = _WallRng(seed: 17);
    for (var i = 0; i < 22; i++) {
      final x = rng.next(i * 11) * size.width;
      final y = rng.next(i * 7) * size.height;
      final r = rng.next(i * 5) * 24 + 8;
      canvas.drawCircle(Offset(x, y), r, stroke);
    }
  }

  void _drawWaves(Canvas canvas, Size size, Paint p) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var row = 0; row < 14; row++) {
      final path = Path();
      final y0 = size.height * row / 14;
      path.moveTo(0, y0);
      for (var x = 0; x <= size.width.toInt(); x += 20) {
        path.lineTo(x.toDouble(), y0 + 7 * math.sin(x / 30.0 + row));
      }
      canvas.drawPath(path, stroke);
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint p) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    const step = 28.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), stroke);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), stroke);
    }
  }

  void _drawHearts(Canvas canvas, Size size, Paint paint) {
    const rng = _WallRng(seed: 99);
    for (var i = 0; i < 28; i++) {
      final x = rng.next(i * 9) * size.width;
      final y = rng.next(i * 4) * size.height;
      final s = rng.next(i * 2) * 10 + 5;
      _drawHeart(canvas, Offset(x, y), s, paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size * 1.2,
      center.dy - size * 0.6,
      center.dx - size * 2,
      center.dy + size * 0.6,
      center.dx,
      center.dy + size * 1.5,
    );
    path.cubicTo(
      center.dx + size * 2,
      center.dy + size * 0.6,
      center.dx + size * 1.2,
      center.dy - size * 0.6,
      center.dx,
      center.dy + size * 0.3,
    );
    canvas.drawPath(path, paint);
  }

  void _drawPlanes(Canvas canvas, Size size, Paint p) {
    const rng = _WallRng(seed: 55);
    for (var i = 0; i < 18; i++) {
      final x = rng.next(i * 13) * size.width;
      final y = rng.next(i * 8) * size.height;
      final s = rng.next(i) * 10 + 6;
      _drawPlane(canvas, Offset(x, y), s, p);
    }
  }

  void _drawTread(Canvas canvas, Size size, Paint p) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    const step = 42.0;
    for (var y = -step; y <= size.height + step; y += step) {
      for (var x = -step; x <= size.width + step; x += step) {
        final path = Path()
          ..moveTo(x, y + step * 0.2)
          ..lineTo(x + step * 0.5, y + step * 0.5)
          ..lineTo(x, y + step * 0.8);
        canvas.drawPath(path, stroke);
        final mirrored = Path()
          ..moveTo(x + step, y + step * 0.2)
          ..lineTo(x + step * 0.5, y + step * 0.5)
          ..lineTo(x + step, y + step * 0.8);
        canvas.drawPath(mirrored, stroke);
      }
    }
  }

  void _drawPlane(Canvas canvas, Offset c, double s, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy - s)
      ..lineTo(c.dx + s * 1.5, c.dy)
      ..lineTo(c.dx, c.dy + s * 0.5)
      ..lineTo(c.dx - s * 1.5, c.dy)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(WallpaperPainter old) =>
      old.wallpaper != wallpaper || old.color != color;
}

class _WallRng {
  const _WallRng({required this.seed});
  final int seed;

  double next(int index) {
    final n = (seed ^ (index * 2654435761)) & 0xFFFFFFFF;
    return (n % 1000) / 1000.0;
  }
}
