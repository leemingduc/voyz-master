import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voyz/models/chat_theme_model.dart';
import 'package:voyz/screens/chat_theme_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/screens/smart_planner_screen.dart';
import 'package:voyz/services/friends_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/profile_avatar.dart';
import 'package:voyz/widgets/shared/account_menu_button.dart';
import 'package:voyz/widgets/shared/aivivu_header.dart';
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
      if (!mounted) return;
      _showMessage('Friend request accepted');
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
    final accepted = _friendships.where((f) => f.status == 'accepted').toList();
    final pending = _friendships.where((f) => f.status == 'pending').toList();

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
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _ErrorState(error: _error!, onRetry: _load)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                        children: [
                          _SearchPanel(
                            controller: _searchController,
                            isSearching: _isSearching,
                            results: _searchResults,
                            onSearch: _search,
                            onSendRequest: _sendRequest,
                          ),
                          const SizedBox(height: 18),
                          _SectionTitle(
                            icon: Icons.people_alt_outlined,
                            title: 'Friends',
                            count: accepted.length,
                          ),
                          const SizedBox(height: 10),
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
                              ),
                            ),
                          const SizedBox(height: 18),
                          _SectionTitle(
                            icon: Icons.mark_email_unread_outlined,
                            title: 'Requests',
                            count: pending.length,
                          ),
                          const SizedBox(height: 10),
                          if (pending.isEmpty)
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
    required this.onSearch,
    required this.onSendRequest,
  });

  final TextEditingController controller;
  final bool isSearching;
  final List<SocialProfile> results;
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
                        child: CircularProgressIndicator(strokeWidth: 2),
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
                trailing: IconButton(
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

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friendship, required this.onTap});

  final Friendship friendship;
  final VoidCallback onTap;

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
        trailing: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
        onTap: onTap,
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
  bool _isSending = false;
  bool _showEmojiPicker = false;
  // IDs of locally recalled messages — guards against stream restoring deleted rows
  final Set<String> _recalledIds = {};
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
    _initRealtimeMessages();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final id = await ChatThemeStore.load(widget.friendship.id);
    if (!mounted) return;
    setState(() => _chatTheme = ChatThemeStore.resolve(id));
  }

  Future<void> _openThemePicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThemeScreen(
          currentThemeId: _chatTheme.id,
          onThemeSelected: (theme) async {
            await ChatThemeStore.save(widget.friendship.id, theme.id);
            if (!mounted) return;
            setState(() => _chatTheme = theme);
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
              final filtered = messages
                  .where((m) => !_recalledIds.contains(m.id))
                  .toList();
              setState(() => _messages = filtered);
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
    _streamSub?.cancel();
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
      final filtered = messages
          .where((m) => !_recalledIds.contains(m.id))
          .toList();
      setState(() => _messages = filtered);
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
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
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
    return locA.year == locB.year && locA.month == locB.month && locA.day == locB.day;
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

  Future<void> _deleteMessage(FriendMessage message) async {
    // Optimistic update: hide immediately in UI
    setState(() {
      _recalledIds.add(message.id);
      _messages.removeWhere((m) => m.id == message.id);
    });
    try {
      await FriendsService.instance.deleteMessage(message.id);
      if (!mounted) return;
      _showMessage('Đã thu hồi tin nhắn');
      // Reinitialize the realtime stream so its internal buffer re-fetches
      // from the server and does not re-surface the deleted message.
      await _streamSub?.cancel();
      _streamSub = null;
      _initRealtimeMessages();
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
                    Icons.undo_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Thu hồi tin nhắn',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message);
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
                  accentColor: _chatTheme.accentColor,
                  onClearChat: () {
                    setState(() => _messages = []);
                  },
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
                            final showDateHeader = index == 0 ||
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
                                _ChatMessageBubble(
                                  message: message,
                                  isMine: isMine,
                                  friend: friend,
                                  timeString: _formatTime(message.createdAt),
                                  myBubbleGradient: _chatTheme.myBubbleGradient,
                                  myBubbleTextColor: _chatTheme.myBubbleTextColor,
                                  theirBubbleColor: _chatTheme.theirBubbleColor,
                                  theirBubbleTextColor: _chatTheme.theirBubbleTextColor,
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

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    required this.isMine,
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
  final SocialProfile friend;
  final String timeString;
  final Gradient myBubbleGradient;
  final Color myBubbleTextColor;
  final Color theirBubbleColor;
  final Color theirBubbleTextColor;
  final Color accentColor;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                      : Border.all(
                          color: accentColor.withValues(alpha: 0.15),
                        ),
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
                        color: isMine ? myBubbleTextColor : theirBubbleTextColor,
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
                            color: (isMine ? myBubbleTextColor : theirBubbleTextColor)
                                .withValues(alpha: 0.65),
                            fontSize: 11,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 14,
                            color: myBubbleTextColor.withValues(alpha: 0.7),
                          ),
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
    final displayName =
        friend.displayName.isEmpty ? friend.email : friend.displayName;

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
            border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
            ),
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
                        borderSide: BorderSide(
                          color: accentColor,
                          width: 1.5,
                        ),
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryPink, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
        ),
      ],
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
    required this.accentColor,
    this.onClearChat,
    this.onChangeTheme,
  });

  final SocialProfile friend;
  final Color accentColor;
  final VoidCallback? onClearChat;
  final VoidCallback? onChangeTheme;

  @override
  Widget build(BuildContext context) {
    final displayName =
        friend.displayName.isEmpty ? friend.email : friend.displayName;

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
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 20,
                      color: accentColor,
                    ),
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
                    Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Clear chat view',
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
  const WallpaperPainter({
    required this.wallpaper,
    required this.color,
  });

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
      center.dx - size * 1.2, center.dy - size * 0.6,
      center.dx - size * 2, center.dy + size * 0.6,
      center.dx, center.dy + size * 1.5,
    );
    path.cubicTo(
      center.dx + size * 2, center.dy + size * 0.6,
      center.dx + size * 1.2, center.dy - size * 0.6,
      center.dx, center.dy + size * 0.3,
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
