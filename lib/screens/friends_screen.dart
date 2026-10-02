import 'dart:async';

import 'package:flutter/material.dart';
import 'package:voyz/services/friends_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/profile_avatar.dart';
import 'package:voyz/widgets/shared/aivivu_header.dart';
import 'package:voyz/widgets/shared/aivivu_wordmark.dart';

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
  }

  void _initRealtimeMessages() {
    _loadMessages();
    try {
      _streamSub = FriendsService.instance
          .streamMessages(widget.friendship.id)
          .listen(
            (messages) {
              if (!mounted) return;
              setState(() => _messages = messages);
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
      setState(() => _messages = messages);
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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AivivuWordmark(fontSize: 21),
            SizedBox(width: 8),
            Text(
              'CHAT',
              style: TextStyle(
                color: AppTheme.cyan,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [Color(0xFF141927), AppTheme.backgroundDark],
          ),
        ),
        child: Column(
          children: [
            _FriendChatHeaderBar(
              friend: friend,
              onClearChat: () {
                setState(() => _messages = []);
              },
            ),
            Expanded(
              child: _messages.isEmpty
                  ? _EmptyChatView(
                      friend: friend,
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
  });

  final FriendMessage message;
  final bool isMine;
  final SocialProfile friend;
  final String timeString;

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
            child: Container(
              constraints: const BoxConstraints(maxWidth: 290),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                gradient: isMine
                    ? const LinearGradient(
                        colors: [AppTheme.primaryPink, AppTheme.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMine ? null : Colors.white.withValues(alpha: 0.08),
                boxShadow: isMine
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryPink.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
                border: isMine
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
                    style: const TextStyle(
                      color: Colors.white,
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
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
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
  });

  final SocialProfile friend;
  final ValueChanged<String> onSendQuick;

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
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryPink, AppTheme.cyan],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: 0.3),
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
                  onTap: () => onSendQuick('Hi there! 👋'),
                ),
                _QuickChip(
                  label: 'Plan a trip ✈️',
                  onTap: () => onSendQuick('Want to plan a trip together? ✈️'),
                ),
                _QuickChip(
                  label: 'How are you? 😊',
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
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

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
              color: AppTheme.cyan.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.cyan,
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
  });

  final TextEditingController controller;
  final bool isSending;
  final bool showEmojiPicker;
  final List<String> quickEmojis;
  final VoidCallback onToggleEmoji;
  final ValueChanged<String> onEmojiSelect;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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
                          color: Colors.white.withValues(alpha: 0.06),
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
                    color: showEmojiPicker ? AppTheme.cyan : Colors.white60,
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
                        borderSide: const BorderSide(
                          color: AppTheme.cyan,
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
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryPink, AppTheme.cyan],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPink.withValues(alpha: 0.35),
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
    this.onClearChat,
  });

  final SocialProfile friend;
  final VoidCallback? onClearChat;

  @override
  Widget build(BuildContext context) {
    final displayName =
        friend.displayName.isEmpty ? friend.email : friend.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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
                      color: AppTheme.surfaceDark,
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
          if (onClearChat != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              color: AppTheme.surfaceDark,
              onSelected: (value) {
                if (value == 'clear') {
                  onClearChat?.call();
                }
              },
              itemBuilder: (context) => [
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

