import 'dart:async';

import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/models/chat_message.dart';
import 'package:voyz/screens/smart_planner_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/services/chat_history_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';

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
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await ChatHistoryService.instance.load(destinationName: widget.destinationName);
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(history);
      if (_messages.isEmpty) {
        _messages.add(
          ChatMessage.ai(AppLocalizations.of(context)!.chatWelcome),
        );
      }
    });
    unawaited(_persistMessages());
  }

  Future<void> _persistMessages() =>
      ChatHistoryService.instance.save(_messages, destinationName: widget.destinationName);

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
    unawaited(_persistMessages());

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await GeminiService.instance.chat(
        text,
        // The current user message was just appended above; pass only prior
        // messages so it is not duplicated in the prompt.
        history: _messages.take(_messages.length - 1).toList(),
        languageCode: LocaleProvider.of(context).value.languageCode,
        destinationName: widget.destinationName,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage.ai(response));
          _isSending = false;
        });
        unawaited(_persistMessages());
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _messages.add(ChatMessage.ai(l10n.chatError));
          _isSending = false;
        });
        unawaited(_persistMessages());
        _scrollToBottom();
      }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.chatTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              final l10n = AppLocalizations.of(context)!;
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage.ai(l10n.chatCleared));
              });
              unawaited(_persistMessages());
            },
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
                return _ChatBubble(message: message);
              },
            ),
          ),

          // Loading indicator
          if (_isSending)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryPink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.chatAiReply,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
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
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.chatInputHint,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
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
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3, onTap: _onNavTap),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

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
            child: Container(
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
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
