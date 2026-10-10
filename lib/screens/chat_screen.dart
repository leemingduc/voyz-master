import 'dart:async';

import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/models/ai_action.dart';
import 'package:voyz/models/chat_message.dart';
import 'package:voyz/screens/destination_detail_screen.dart';
import 'package:voyz/screens/smart_planner_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/screens/friends_screen.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/services/chat_history_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/aivivu_header.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
import 'package:voyz/widgets/shared/typing_indicator_bubble.dart';

/// AI Travel Chatbot screen — chat directly with the AI travel assistant.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.destinationName});

  final String? destinationName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  List<ChatConversation> _conversations = const [];
  String? _activeConversationId;
  bool _isLoadingHistory = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    ChatConversationHistory history;
    try {
      history = await ChatHistoryService.instance.loadConversations(
        destinationName: widget.destinationName,
      );
    } catch (error) {
      debugPrint('Chat history load skipped: $error');
      history = const ChatConversationHistory(conversations: []);
    }
    if (!mounted) return;
    setState(() {
      _conversations = history.conversations;
      final activeId = history.activeConversationId;
      final activeConversation = activeId != null
          ? history.conversations
                .where((conversation) => conversation.id == activeId)
                .firstOrNull
          : null;
      if (activeConversation != null &&
          activeConversation.messages.isNotEmpty) {
        _activeConversationId = activeId;
        _messages
          ..clear()
          ..addAll(activeConversation.messages);
      } else {
        _activeConversationId = null;
        _messages
          ..clear()
          ..add(ChatMessage.ai(AppLocalizations.of(context)!.chatWelcome));
      }
      _isLoadingHistory = false;
    });
  }

  Future<void> _persistMessages() async {
    if (!_messages.any((message) => message.isUser)) return;
    final history = await ChatHistoryService.instance.saveConversation(
      _messages,
      conversationId: _activeConversationId,
      destinationName: widget.destinationName,
    );
    if (!mounted) return;
    setState(() {
      _conversations = history.conversations;
      _activeConversationId = history.activeConversationId;
    });
  }

  void _newChat() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _activeConversationId = null;
      _messages
        ..clear()
        ..add(ChatMessage.ai(l10n.chatWelcome));
    });
    unawaited(
      ChatHistoryService.instance.startNewConversation(
        destinationName: widget.destinationName,
      ),
    );
  }

  Future<void> _openConversation(String id) async {
    final history = await ChatHistoryService.instance.openConversation(
      id,
      destinationName: widget.destinationName,
    );
    if (!mounted) return;
    final conversation = history.conversations.where(
      (item) => item.id == history.activeConversationId,
    );
    if (conversation.isEmpty) return;
    setState(() {
      _conversations = history.conversations;
      _activeConversationId = history.activeConversationId;
      _messages
        ..clear()
        ..addAll(conversation.first.messages);
    });
    _scrollToBottom();
  }

  Future<void> _deleteConversation(String id) async {
    final history = await ChatHistoryService.instance.deleteConversation(
      id,
      destinationName: widget.destinationName,
    );
    if (!mounted) return;
    final wasActive = _activeConversationId == id;
    setState(() {
      _conversations = history.conversations;
      _activeConversationId = history.activeConversationId;
      if (wasActive) {
        _messages
          ..clear()
          ..add(ChatMessage.ai(AppLocalizations.of(context)!.chatWelcome));
      }
    });
  }

  Future<void> _showConversationMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      showDragHandle: true,
      builder: (sheetContext) => _ChatConversationSheet(
        conversations: _conversations,
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || _isLoadingHistory) return;
    final languageCode = LocaleProvider.of(context).value.languageCode;

    setState(() {
      _messages.add(ChatMessage.user(text));
      _isSending = true;
    });
    // Do not start the network request until the user's turn is on disk. This
    // makes the conversation survive an immediate app close/background event.
    await _persistMessages();
    if (!mounted) return;

    _messageController.clear();
    _scrollToBottom();

    try {
      final result = await GeminiService.instance.chatWithActions(
        text,
        // The current user message was just appended above; pass only prior
        // messages so it is not duplicated in the prompt.
        history: _messages.take(_messages.length - 1).toList(),
        languageCode: languageCode,
        destinationName: widget.destinationName,
      );

      if (mounted) {
        final aiMsg = ChatMessage.ai(result.reply, action: result.action);
        setState(() {
          _messages.add(aiMsg);
          _isSending = false;
        });
        await _persistMessages();
        _scrollToBottom();

        if (result.action != null) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted && result.action != null) {
              _executeAiAction(result.action!);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _messages.add(ChatMessage.ai(l10n.chatError));
          _isSending = false;
        });
        await _persistMessages();
        _scrollToBottom();
      }
    }
  }

  void _executeAiAction(AiAction action) {
    if (!mounted) return;
    switch (action.type) {
      case AiActionType.navigateDestination:
        if (action.target.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  DestinationDetailScreen(destinationName: action.target),
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
        if (action.target.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  DestinationDetailScreen(destinationName: action.target),
            ),
          );
        }
        break;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const FriendsScreen()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AivivuHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.newPlannerChat,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _isSending || _isLoadingHistory ? null : _newChat,
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.plannerConversationHistory,
            icon: const Icon(Icons.history_outlined),
            onPressed: _isSending || _isLoadingHistory
                ? null
                : _showConversationMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(
                  message: message,
                  onActionPressed: _executeAiAction,
                );
              },
            ),
          ),

          // Loading indicator
          if (_isSending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TypingIndicatorBubble(
                label: AppLocalizations.of(context)!.chatAiReply,
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.45,
                      letterSpacing: 0.2,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.chatInputHint,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 15,
                        height: 1.45,
                        letterSpacing: 0.2,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: AppTheme.cyan,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _isLoadingHistory
                        ? null
                        : (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending || _isLoadingHistory
                        ? null
                        : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0, onTap: _onNavTap),
    );
  }
}

class _ChatConversationSheet extends StatelessWidget {
  const _ChatConversationSheet({
    required this.conversations,
    required this.onOpenConversation,
    required this.onDeleteConversation,
  });

  final List<ChatConversation> conversations;
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
                l10n.plannerConversationHistory,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, this.onActionPressed});

  final ChatMessage message;
  final ValueChanged<AiAction>? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final action = message.action;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primaryPink.withValues(alpha: 0.2)
                        : AppTheme.surfaceDark,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? AppTheme.primaryPink.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => onActionPressed?.call(action),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.cyan.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.rocket_launch,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            action.label.isNotEmpty
                                ? action.label
                                : 'Thực hiện ngay',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
