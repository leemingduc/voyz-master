import 'package:flutter/material.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/models/ai_action.dart';
import 'package:voyz/models/chat_message.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/utils/error_localizer.dart';

/// A compact, destination-aware AI chat opened from the detail-page AI button.
class DestinationQuickChat extends StatefulWidget {
  const DestinationQuickChat({
    super.key,
    required this.destinationName,
    required this.onDestinationSelected,
  });

  final String destinationName;
  final ValueChanged<String> onDestinationSelected;

  @override
  State<DestinationQuickChat> createState() => _DestinationQuickChatState();
}

class _DestinationQuickChatState extends State<DestinationQuickChat> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isOpen = false;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage.user(text));
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final result = await GeminiService.instance.chatWithActions(
        text,
        history: _messages.take(_messages.length - 1).toList(),
        languageCode: LocaleProvider.of(context).value.languageCode,
        destinationName: widget.destinationName,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage.ai(result.reply, action: result.action));
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage.ai(
            ErrorLocalizer.getLocalizedMessage(
              e,
              AppLocalizations.of(context)!,
            ),
          ),
        );
        _isSending = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleAction(AiAction action) {
    switch (action.type) {
      case AiActionType.navigateDestination:
      case AiActionType.setTripData:
        final destination = action.target.trim();
        if (destination.isNotEmpty) widget.onDestinationSelected(destination);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;

    if (!_isOpen) {
      return Semantics(
        button: true,
        label: l10n.aiChatbotTitle,
        child: Tooltip(
          message: l10n.aiChatbotTitle,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => setState(() => _isOpen = true),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.forum_outlined,
                        color: AppTheme.cyan,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.aiChatbotTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width >= 600 ? 360 : width - 32,
        height: 360,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.cyan,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.aiChatbotTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.destinationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.back,
                    onPressed: () => setState(() => _isOpen = false),
                    icon: const Icon(Icons.minimize, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.chatWelcome,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _QuickChatBubble(
                        message: _messages[index],
                        onActionPressed: _handleAction,
                      ),
                    ),
            ),
            if (_isSending)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isSending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: l10n.chatInputHint,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: const Icon(Icons.send, color: AppTheme.cyan),
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

class _QuickChatBubble extends StatelessWidget {
  const _QuickChatBubble({
    required this.message,
    required this.onActionPressed,
  });

  final ChatMessage message;
  final ValueChanged<AiAction> onActionPressed;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final action = message.action;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.primaryPink.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
          if (action != null &&
              (action.type == AiActionType.navigateDestination ||
                  action.type == AiActionType.setTripData)) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => onActionPressed(action),
              icon: const Icon(Icons.location_on_outlined, size: 16),
              label: Text(action.label),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.cyan,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
