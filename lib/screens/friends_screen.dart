import 'dart:async';

import 'package:flutter/material.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/services/friends_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/aivivu_header.dart';

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

  Future<void> _inviteFriendToTrip(SavedItem trip) async {
    final l10n = AppLocalizations.of(context)!;
    final eligibleFriends = _friendships
        .where(
          (friendship) =>
              friendship.isAccepted &&
              !trip.sharedWith.contains(friendship.friend.email),
        )
        .toList();

    if (eligibleFriends.isEmpty) {
      _showMessage(l10n.inviteFriendNone, isError: true);
      return;
    }

    final selected = await showModalBottomSheet<Friendship>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.inviteFriendToTripTitle(trip.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...eligibleFriends.map(
                (friendship) => ListTile(
                  leading: _Avatar(url: friendship.friend.avatarUrl),
                  title: Text(
                    friendship.friend.displayName.isEmpty
                        ? friendship.friend.email
                        : friendship.friend.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    friendship.friend.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.person_add_alt_1,
                    color: AppTheme.cyan,
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(friendship),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || selected == null) return;
    SavedTripsProvider.of(context).addSharedPerson(trip, selected.friend.email);
    _showMessage(l10n.inviteFriendSuccess);
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
    final groupTrips = SavedTripsProvider.of(context).tripWorkspaces;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AivivuHeader(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.4,
            colors: [AppTheme.surfaceDark, AppTheme.backgroundDark],
          ),
        ),
        child: Column(
          children: [
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
                          icon: Icons.explore_outlined,
                          title: l10n.groupTripsTitle,
                          count: groupTrips.length,
                        ),
                        const SizedBox(height: 10),
                        if (groupTrips.isEmpty)
                          _EmptyPanel(
                            icon: Icons.group_outlined,
                            title: l10n.groupTripsEmptyTitle,
                            subtitle: l10n.groupTripsEmptyHint,
                          )
                        else
                          ...groupTrips.map(
                            (trip) => _GroupTripTile(
                              trip: trip,
                              onInvite: () => _inviteFriendToTrip(trip),
                            ),
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
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText: 'Email or display name',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
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

class _GroupTripTile extends StatelessWidget {
  const _GroupTripTile({required this.trip, required this.onInvite});

  final SavedItem trip;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final memberCount = trip.sharedWith.length + 1;

    return _Panel(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.violet.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flight_takeoff_outlined,
                  color: AppTheme.cyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  trip.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.sync,
                size: 18,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.group_outlined, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                l10n.groupTripMembers(memberCount),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onInvite,
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: Text(l10n.inviteFriendToTrip),
              ),
            ],
          ),
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

  Future<void> _send() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await FriendsService.instance.sendMessage(widget.friendship.id, body);
      _messageController.clear();
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

  @override
  Widget build(BuildContext context) {
    final currentId = FriendsService.instance.currentUserId;
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: const AivivuHeader(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMine = message.senderId == currentId;
                return Align(
                  alignment: isMine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMine
                          ? AppTheme.primaryPink
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      message.body,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.07),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _send,
                    icon: const Icon(Icons.send),
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
    final value = url;
    return CircleAvatar(
      backgroundColor: AppTheme.primaryPink.withValues(alpha: 0.22),
      backgroundImage: value == null || value.isEmpty
          ? null
          : NetworkImage(value),
      child: value == null || value.isEmpty
          ? const Icon(Icons.person, color: Colors.white)
          : null,
    );
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
