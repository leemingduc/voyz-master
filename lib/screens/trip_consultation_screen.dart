import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/data/mock_data.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/chat_message.dart';
import 'package:voyz/screens/suggestions_screen.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/glass_card.dart';

/// Interactive AI Trip Consultation screen.
///
/// Allows users to discuss trip ideas, adjust budget, dates, and interests,
/// and confirm before generating destination suggestions and detailed itineraries.
class TripConsultationScreen extends StatefulWidget {
  const TripConsultationScreen({super.key});

  @override
  State<TripConsultationScreen> createState() => _TripConsultationScreenState();
}

class _TripConsultationScreenState extends State<TripConsultationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isInfoExpanded = false;
  bool _isAiResponding = false;
  bool _initialized = false;
  String _selectedBudgetTier = 'moderate';
  Set<String> _selectedInterests = {'culture', 'food'};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initFromTrip();
    }
  }

  void _initFromTrip() {
    final trip = SavedTripsProvider.of(context).currentTrip;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _selectedBudgetTier = trip.budget.isNotEmpty ? trip.budget : 'moderate';
      _selectedInterests = Set<String>.from(
        trip.selectedInterests.isNotEmpty
            ? trip.selectedInterests
            : MockData.interests.take(2),
      );

      final promptText = trip.aiPrompt.isNotEmpty
          ? trip.aiPrompt
          : (trip.destination.isNotEmpty ? trip.destination : 'Kỳ nghỉ sắp tới');

      final greeting = l10n.consultationInitialPrompt(promptText);
      _messages.add(ChatMessage.ai(greeting));
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _syncTripData() {
    final provider = SavedTripsProvider.of(context);
    final oldTrip = provider.currentTrip;
    final updatedTrip = TripData(
      destination: oldTrip.destination,
      departDate: oldTrip.departDate,
      returnDate: oldTrip.returnDate,
      budget: _selectedBudgetTier,
      currency: oldTrip.currency,
      participants: oldTrip.participants,
      ageRange: oldTrip.ageRange,
      additionalNotes: oldTrip.additionalNotes,
      aiPrompt: oldTrip.aiPrompt,
      selectedInterests: _selectedInterests.toList(),
    );
    provider.updateTrip(updatedTrip);
  }

  Future<void> _handleSendMessage([String? customText]) async {
    final text = (customText ?? _textController.text).trim();
    if (text.isEmpty || _isAiResponding) return;

    if (customText == null) {
      _textController.clear();
    }

    setState(() {
      _messages.add(ChatMessage.user(text));
      _isAiResponding = true;
    });
    _scrollToBottom();

    try {
      final trip = SavedTripsProvider.of(context).currentTrip;
      final languageCode = LocaleProvider.of(context).value.languageCode;

      final reply = await GeminiService.instance.consultTrip(
        message: text,
        history: _messages.take(_messages.length - 1).toList(),
        currentTrip: trip,
        languageCode: languageCode,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage.ai(reply));
          _isAiResponding = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _messages.add(ChatMessage.ai(l10n.chatError));
          _isAiResponding = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _onConfirmAndProceed() {
    _syncTripData();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SuggestionsScreen()),
    );
  }

  String _getLocalizedInterest(String interestKey, AppLocalizations l10n) {
    switch (interestKey) {
      case 'beach':
        return l10n.beach;
      case 'adventure':
        return l10n.adventure;
      case 'culture':
        return l10n.culture;
      case 'food':
        return l10n.food;
      case 'wellness':
        return l10n.wellness;
      default:
        return interestKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
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
              _buildTopBar(l10n),
              _buildCollapsibleTripInfo(l10n),
              Expanded(child: _buildChatList(l10n)),
              _buildQuickChips(l10n),
              _buildInputArea(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tripConsultationTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Aivivu AI Travel Companion',
                  style: TextStyle(
                    color: AppTheme.cyan.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 38,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.magenta.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onConfirmAndProceed,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        l10n.confirmAndSeeSuggestions,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleTripInfo(AppLocalizations l10n) {
    final tiers = [
      (key: 'economy', label: l10n.budgetTierEconomy, badge: '🪙'),
      (key: 'moderate', label: l10n.budgetTierModerate, badge: '☕'),
      (key: 'premium', label: l10n.budgetTierPremium, badge: '💎'),
      (key: 'luxury', label: l10n.budgetTierLuxury, badge: '👑'),
    ];

    final currentBadge = tiers.firstWhere(
      (t) => t.key == _selectedBudgetTier.toLowerCase(),
      orElse: () => tiers[1],
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isInfoExpanded = !_isInfoExpanded;
                });
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.cyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tune, color: AppTheme.cyan, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.tripInfo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${currentBadge.badge} ${currentBadge.label}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isInfoExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (_isInfoExpanded) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.budgetTier,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tiers.map((tier) {
                  final isSelected = _selectedBudgetTier.toLowerCase() == tier.key;
                  return ChoiceChip(
                    label: Text('${tier.badge} ${tier.label}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedBudgetTier = tier.key;
                        });
                        _syncTripData();
                        _handleInfoChangedNotification(l10n);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.interests,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: MockData.interests.map((key) {
                  final isSelected = _selectedInterests.contains(key);
                  return FilterChip(
                    label: Text(_getLocalizedInterest(key, l10n)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(key);
                        } else {
                          _selectedInterests.remove(key);
                        }
                      });
                      _syncTripData();
                      _handleInfoChangedNotification(l10n);
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleInfoChangedNotification(AppLocalizations l10n) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.tripInfoUpdated),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildChatList(AppLocalizations l10n) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _messages.length + (_isAiResponding ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isAiResponding) {
          return _buildTypingBubble();
        }
        final msg = _messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.magenta.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: const BoxConstraints(maxWidth: 340),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.cyan, AppTheme.violet],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: AppTheme.cyan.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.cyan, AppTheme.violet],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.cyan),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI đang phân tích...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
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

  Widget _buildQuickChips(AppLocalizations l10n) {
    final chips = [
      (label: l10n.quickChipRelaxed, text: l10n.quickChipRelaxed),
      (label: l10n.quickChipFoodie, text: l10n.quickChipFoodie),
      (label: l10n.quickChipBudget, text: l10n.quickChipBudget),
      (label: l10n.quickChipReady, text: l10n.quickChipReady),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: chips.map((chip) {
          final isReady = chip.text == l10n.quickChipReady;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: isReady
                  ? AppTheme.magenta.withValues(alpha: 0.18)
                  : AppTheme.surfaceDark.withValues(alpha: 0.8),
              side: BorderSide(
                color: isReady
                    ? AppTheme.magenta.withValues(alpha: 0.5)
                    : Colors.white12,
              ),
              label: Text(
                chip.label,
                style: TextStyle(
                  color: isReady ? const Color(0xFFFF80AB) : Colors.white70,
                  fontSize: 12,
                  fontWeight: isReady ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onPressed: () {
                if (isReady) {
                  _onConfirmAndProceed();
                } else {
                  _handleSendMessage(chip.text);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nhập câu hỏi hoặc điều chỉnh với AI...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _handleSendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _handleSendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
