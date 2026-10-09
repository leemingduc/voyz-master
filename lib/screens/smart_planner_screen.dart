import 'dart:async';

import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/models/plan_turn.dart';
import 'package:voyz/screens/destination_detail_screen.dart';
import 'package:voyz/screens/compare_screen.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/screens/friends_screen.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/services/profile_service.dart';
import 'package:voyz/services/search_history_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/utils/error_localizer.dart';
import 'package:voyz/widgets/planner/planner_bubble.dart';
import 'package:voyz/widgets/planner/planner_generating_card.dart';
import 'package:voyz/widgets/planner/trip_option_card.dart';
import 'package:voyz/widgets/shared/aivivu_wordmark.dart';
import 'package:voyz/widgets/shared/account_menu_button.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
import 'package:voyz/widgets/shared/typing_indicator_bubble.dart';

/// Planner AI-first dạng chat. Trước lượt gửi đầu là màn hero như cũ; sau đó
/// là hội thoại với AI, AI hỏi thêm khi thiếu thông tin rồi đưa 3 thẻ phương
/// án. Chọn thẻ thì mở màn chi tiết như chạm một gợi ý trước đây.
/// Mỗi hội thoại được lưu cục bộ và có thể mở lại từ lịch sử.
class SmartPlannerScreen extends StatefulWidget {
  const SmartPlannerScreen({super.key});

  @override
  State<SmartPlannerScreen> createState() => _SmartPlannerScreenState();
}

class _SmartPlannerScreenState extends State<SmartPlannerScreen> {
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();

  /// Sở thích lấy từ profile, dùng khi AI không suy ra được sở thích nào.
  List<String> _profileInterests = const [];

  final List<PlannerMessage> _messages = [];
  bool _isSending = false;
  Object? _error;

  /// Lượt đang chạy có bắt buộc đưa phương án không, để "Thử lại" gọi lại y hệt.
  bool _lastForce = false;

  bool get _inChat => _messages.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _messages.addAll(SavedTripsProvider.of(context).plannerMessages);
    _loadMissingImages(_messages);
    unawaited(_restoreSavedMessages());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final trip = SavedTripsProvider.of(context).currentTrip;
      final currency = CurrencyProvider.of(context);
      UserProfile? profile;
      try {
        profile = await ProfileService.instance.loadCurrentProfile();
        await currency.setDisplayCurrency(
          trip.currency.isNotEmpty ? trip.currency : profile.preferredCurrency,
        );
      } catch (_) {}
      if (!mounted) return;

      setState(() {
        _profileInterests =
            profile?.travelStyles
                .map((style) => style.toLowerCase().replaceAll(' ', '_'))
                .toList() ??
            const [];
      });
    });
  }

  Future<void> _restoreSavedMessages() async {
    final provider = SavedTripsProvider.of(context);
    await provider.load();
    if (!mounted || _messages.isNotEmpty) return;
    final savedMessages = provider.plannerMessages;
    if (savedMessages.isEmpty) return;
    setState(() => _messages.addAll(savedMessages));
    _loadMissingImages(savedMessages);
  }

  void _loadMissingImages(Iterable<PlannerMessage> messages) {
    for (final message in messages) {
      final turn = message.turn;
      if (turn != null &&
          turn.hasOptions &&
          turn.options.any((option) => option.imageUrl.isEmpty)) {
        unawaited(_loadImages(message));
      }
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showPromptRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.describeTripRequired),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const FriendsScreen()),
          (route) => false,
        );
        break;
    }
  }

  /// Gửi tin nhắn đang gõ. "Gợi ý luôn" được bấm khi ô trống: không thêm
  /// tin mới, chỉ bắt AI đưa phương án.
  Future<void> _send({bool forceOptions = false}) async {
    if (_isSending) return;
    final text = _promptController.text.trim();
    if (text.isEmpty && !(forceOptions && _inChat)) {
      if (!_inChat) _showPromptRequired();
      return;
    }
    setState(() {
      if (text.isNotEmpty) _messages.add(PlannerMessage.user(text));
      _promptController.clear();
    });
    // Finish writing the user's request before asking the AI so this
    // suggestion thread remains available after the app is reopened.
    await _persistMessages();
    await _runTurn(forceOptions: forceOptions);
  }

  Future<void> _runTurn({required bool forceOptions}) async {
    final languageCode = LocaleProvider.of(context).value.languageCode;
    setState(() {
      _isSending = true;
      _error = null;
      _lastForce = forceOptions;
    });
    _scrollToBottom();
    try {
      final turn = await GeminiService.instance.planTurn(
        List.of(_messages),
        forceOptions: forceOptions,
        languageCode: languageCode,
      );
      if (turn.reply.isEmpty && !turn.hasOptions) {
        throw Exception('noAiResponse');
      }
      if (!mounted) return;
      final message = PlannerMessage.agent(turn);
      setState(() {
        _messages.add(message);
        _isSending = false;
      });
      await _persistMessages();
      _scrollToBottom();
      if (turn.hasOptions) unawaited(_loadImages(message));
    } catch (e) {
      debugPrint('SmartPlanner: planTurn failed: $e');
      if (!mounted) return;
      setState(() {
        _error = e;
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  /// Ảnh về sau text: thay đúng tin nhắn đó, bỏ qua nếu chat đã bị làm mới.
  Future<void> _loadImages(PlannerMessage message) async {
    final turn = message.turn!;
    final options = await GeminiService.instance.enrichOptionsWithImages(
      turn.options,
    );
    if (!mounted) return;
    final index = _messages.indexOf(message);
    if (index < 0) return;
    setState(() {
      _messages[index] = PlannerMessage.agent(turn.copyWith(options: options));
    });
    unawaited(_persistMessages());
  }

  void _newChat() {
    setState(() {
      _messages.clear();
      _error = null;
      _promptController.clear();
    });
    unawaited(SavedTripsProvider.of(context).startNewPlannerConversation());
  }

  Future<void> _persistMessages() =>
      SavedTripsProvider.of(context).updatePlannerMessages(_messages);

  Future<void> _openConversation(String id) async {
    final messages = await SavedTripsProvider.of(
      context,
    ).openPlannerConversation(id);
    if (!mounted || messages.isEmpty) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(messages);
      _error = null;
      _promptController.clear();
    });
    _loadMissingImages(messages);
    _scrollToBottom();
  }

  Future<void> _showConversationMenu() async {
    final provider = SavedTripsProvider.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      showDragHandle: true,
      builder: (sheetContext) => _PlannerConversationSheet(
        conversations: provider.plannerConversations,
        onNewConversation: () {
          Navigator.pop(sheetContext);
          _newChat();
        },
        onOpenConversation: (id) {
          Navigator.pop(sheetContext);
          unawaited(_openConversation(id));
        },
        onDeleteConversation: (id) {
          Navigator.pop(sheetContext);
          unawaited(_deleteConversation(id));
        },
      ),
    );
  }

  Future<void> _deleteConversation(String id) async {
    final provider = SavedTripsProvider.of(context);
    final isActive = provider.activePlannerConversationId == id;
    await provider.deletePlannerConversation(id);
    if (!mounted || !isActive) return;
    setState(() {
      _messages.clear();
      _error = null;
      _promptController.clear();
    });
  }

  List<String> _comparisonDestinations(PlanTurn turn) {
    final destinations = <String>[];
    final seen = <String>{};
    for (final option in turn.options) {
      final destination = option.destination.trim();
      if (destination.isEmpty || !seen.add(destination.toLowerCase())) continue;
      destinations.add(destination);
    }
    return destinations;
  }

  void _compareOptions(PlanTurn turn) {
    final destinations = _comparisonDestinations(turn);
    if (destinations.length < 2) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompareScreen(
          initialDestinations: destinations,
          initialTrip: turn.trip,
        ),
      ),
    );
  }

  Future<void> _pickOption(PlanTurn turn, TripOption option) async {
    final provider = SavedTripsProvider.of(context);
    final currency = CurrencyProvider.of(context).value;
    final userMessages = [
      for (final m in _messages)
        if (m.isUser) m.text,
    ];
    final trip = tripForOption(turn, option, userMessages);
    provider.updateTrip(
      trip.copyWith(
        currency: currency,
        selectedInterests: trip.selectedInterests.isEmpty
            ? _profileInterests
            : null,
      ),
    );
    await SearchHistoryService.instance.recordTripSearch(provider.currentTrip);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DestinationDetailScreen(
          destinationName: option.destination,
          suggestedOptions: turn.options,
          selectedSuggestionIndex: turn.options.indexOf(option),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [AppTheme.surfaceDark, AppTheme.backgroundDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(l10n),
              Expanded(
                child: _inChat
                    ? _buildChat(l10n)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLg,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1260),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildPlannerHero(theme, l10n),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              if (_inChat) _buildChatDock(l10n),
            ],
          ),
        ),
      ),
      bottomSheet: BottomNavBar(currentIndex: 0, onTap: _onNavTap),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AivivuWordmark(fontSize: 20),
              Text(
                l10n.smartPlanner,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.plannerSuggestionHistory,
                onPressed: _isSending ? null : _showConversationMenu,
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
              if (_inChat)
                IconButton(
                  tooltip: l10n.goBack,
                  onPressed: _isSending ? null : _newChat,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              const AccountMenuButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChat(AppLocalizations l10n) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            for (final message in _messages) ...[
              if (message.text.isNotEmpty)
                PlannerBubble(text: message.text, isUser: message.isUser),
              if (message.turn != null) ...[
                for (final option in message.turn!.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TripOptionCard(
                      option: option,
                      onTap: () => _pickOption(message.turn!, option),
                    ),
                  ),
                if (_comparisonDestinations(message.turn!).length >= 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _compareOptions(message.turn!),
                        icon: const Icon(Icons.compare_arrows),
                        label: Text(l10n.compareButton),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.cyan,
                          side: BorderSide(
                            color: AppTheme.cyan.withValues(alpha: 0.45),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
            if (_isSending)
              if (_lastForce || _messages.length <= 1)
                const PlannerGeneratingCard()
              else
                TypingIndicatorBubble(label: l10n.chatAiReply),
            if (_error != null)
              _ErrorRow(
                message: ErrorLocalizer.getLocalizedMessage(_error!, l10n),
                retryLabel: l10n.retry,
                onRetry: () => _runTurn(forceOptions: _lastForce),
              ),
          ],
        ),
      ),
    );
  }

  /// Ô nhập ở đáy khi đang chat. Chừa chỗ cho thanh điều hướng nổi.
  Widget _buildChatDock(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 76),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _AiPromptBox(
            controller: _promptController,
            hintText: l10n.plannerChatHint,
            minLines: 1,
            maxLines: 3,
            actionLabel: _isSending ? l10n.analyzingTrip : l10n.plannerSend,
            actionIcon: Icons.send,
            onAction: _isSending ? null : _send,
            secondaryLabel: l10n.suggestNow,
            secondaryIcon: Icons.auto_awesome_outlined,
            onSecondary: _isSending ? null : () => _send(forceOptions: true),
          ),
        ),
      ),
    );
  }

  Widget _buildPlannerHero(ThemeData theme, AppLocalizations l10n) {
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.cyan.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.cyan,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.smartPlanner.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: AppTheme.brandGradient.createShader,
          child: Text(
            l10n.plannerGreeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.9,
              height: 1.12,
            ),
          ),
        ),
      ],
    );

    final prompt = _AiPromptBox(
      controller: _promptController,
      hintText: l10n.aiPromptHint,
      minLines: 3,
      maxLines: 5,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      actionHeight: 52,
      searchIconSize: 28,
      innerContentPadding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 6,
      ),
      actionLabel: _isSending ? l10n.analyzingTrip : l10n.getAiSuggestions,
      actionIcon: Icons.auto_awesome,
      onAction: _isSending ? null : _send,
      secondaryLabel: l10n.explore,
      secondaryIcon: Icons.explore_outlined,
      onSecondary: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ExploreScreen()));
      },
    );

    final quickPrompts = _QuickPromptChips(
      onSelected: (promptText) => _promptController.text = promptText,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [prompt, const SizedBox(height: 16), quickPrompts],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        if (!isDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              intro,
              const SizedBox(height: 20),
              const _CosmicEarthArtwork(),
              const SizedBox(height: 24),
              content,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(flex: 9, child: _CosmicEarthArtwork()),
            const SizedBox(width: 44),
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [intro, const SizedBox(height: 24), content],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlannerConversationSheet extends StatelessWidget {
  const _PlannerConversationSheet({
    required this.conversations,
    required this.onNewConversation,
    required this.onOpenConversation,
    required this.onDeleteConversation,
  });

  final List<PlannerConversation> conversations;
  final VoidCallback onNewConversation;
  final ValueChanged<String> onOpenConversation;
  final ValueChanged<String> onDeleteConversation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Text(
                l10n.plannerSuggestionHistory,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.add_comment_outlined,
                color: AppTheme.cyan,
              ),
              title: Text(
                l10n.newPlannerChat,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: onNewConversation,
            ),
            const Divider(height: 1),
            if (conversations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.noPlannerConversations,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.forum_outlined,
                        color: Colors.white70,
                      ),
                      title: Text(
                        conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${conversation.messages.length} ${l10n.messagesLabel}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      onTap: () => onOpenConversation(conversation.id),
                      trailing: IconButton(
                        tooltip: l10n.deletePlannerConversation,
                        onPressed: () => onDeleteConversation(conversation.id),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

/// Ô prompt dùng cho cả hero và dock chat. Nút phụ viền cyan đổi theo chế
/// độ: Khám phá ở hero, "Gợi ý luôn" khi đang chat.
class _AiPromptBox extends StatelessWidget {
  const _AiPromptBox({
    required this.controller,
    required this.hintText,
    required this.minLines,
    required this.maxLines,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 16),
    this.actionHeight = 48,
    this.searchIconSize = 26,
    this.innerContentPadding = const EdgeInsets.symmetric(
      horizontal: 4,
      vertical: 4,
    ),
  });

  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;
  final String actionLabel;
  final IconData actionIcon;

  /// Null khi đang chờ AI.
  final VoidCallback? onAction;
  final String secondaryLabel;
  final IconData secondaryIcon;

  /// Null khi đang chờ AI.
  final VoidCallback? onSecondary;

  final EdgeInsetsGeometry padding;
  final double actionHeight;
  final double searchIconSize;
  final EdgeInsetsGeometry innerContentPadding;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.9),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.12),
            blurRadius: 20,
          ),
        ],
      ),
      padding: padding,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.search,
                  color: primaryColor,
                  size: searchIconSize,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: maxLines,
                  minLines: minLines,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.45,
                    letterSpacing: 0.2,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontSize: 16,
                      height: 1.45,
                      letterSpacing: 0.2,
                    ),
                    border: InputBorder.none,
                    isDense: false,
                    contentPadding: innerContentPadding,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: primaryColor.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                SizedBox(
                  height: actionHeight,
                  child: OutlinedButton.icon(
                    onPressed: onSecondary,
                    icon: Icon(secondaryIcon, size: 19),
                    label: Text(secondaryLabel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.cyan,
                      backgroundColor: AppTheme.cyan.withValues(alpha: 0.08),
                      side: const BorderSide(color: AppTheme.cyan, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                Opacity(
                  opacity: onAction == null ? 0.6 : 1,
                  child: Container(
                    height: actionHeight,
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.magenta.withValues(alpha: 0.36),
                          blurRadius: 20,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onAction,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                actionLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(actionIcon, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _QuickPromptChips extends StatelessWidget {
  const _QuickPromptChips({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prompts = [
      l10n.quickPromptTokyo,
      l10n.quickPromptDaLat,
      l10n.quickPromptBali,
      l10n.quickPromptPhuQuoc,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.quickPromptsLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.56),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        ...prompts.map(
          (prompt) => ActionChip(
            label: Text(prompt),
            onPressed: () => onSelected(prompt),
            avatar: const Icon(Icons.auto_awesome, size: 14),
          ),
        ),
      ],
    );
  }
}

class _CosmicEarthArtwork extends StatelessWidget {
  const _CosmicEarthArtwork();

  static const _earthAssetPath = 'assets/images/cosmic_earth.png';

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.violet.withValues(alpha: 0.24),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                _earthAssetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0xFF143651), AppTheme.backgroundDark],
                    ),
                  ),
                  child: const Icon(
                    Icons.public,
                    color: AppTheme.cyan,
                    size: 96,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.backgroundDark.withValues(alpha: 0.12),
                    ],
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
