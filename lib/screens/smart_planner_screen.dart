import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/data/mock_data.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/screens/trip_consultation_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/services/profile_service.dart';
import 'package:voyz/services/search_history_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/aivivu_wordmark.dart';
import 'package:voyz/widgets/shared/account_menu_button.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
import 'package:voyz/widgets/shared/glass_card.dart';
import 'package:voyz/widgets/shared/interest_chip.dart';

class SmartPlannerScreen extends StatefulWidget {
  const SmartPlannerScreen({super.key});

  @override
  State<SmartPlannerScreen> createState() => _SmartPlannerScreenState();
}

class _SmartPlannerScreenState extends State<SmartPlannerScreen> {
  final _promptController = TextEditingController();

  String _selectedBudgetTier = 'moderate';
  late List<bool> _selectedInterests;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final trip = SavedTripsProvider.of(context).currentTrip;
      UserProfile? profile;
      try {
        profile = await ProfileService.instance.loadCurrentProfile();
        await CurrencyProvider.of(context).setDisplayCurrency(
          trip.currency.isNotEmpty ? trip.currency : profile.preferredCurrency,
        );
      } catch (_) {}
      if (!mounted) return;

      final preferredStyles =
          profile?.travelStyles
              .map((style) => style.toLowerCase().replaceAll(' ', '_'))
              .toSet() ??
          const <String>{};
      final selectedInterestKeys = trip.selectedInterests.isNotEmpty
          ? trip.selectedInterests.toSet()
          : preferredStyles;

      setState(() {
        _selectedBudgetTier = trip.budget.isNotEmpty ? trip.budget : 'moderate';
        _promptController.text = trip.aiPrompt;

        _selectedInterests = List.filled(MockData.interests.length, false);
        for (int i = 0; i < MockData.interests.length; i++) {
          if (selectedInterestKeys.contains(MockData.interests[i])) {
            _selectedInterests[i] = true;
          }
        }
      });
    });
    _selectedInterests = List.from(MockData.interestsSelected);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  bool _validateInput() {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.plannerPromptRequired),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
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
        _saveCurrentState();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SavedScreen()),
          (route) => false,
        );
        break;
    }
  }

  void _saveCurrentState() {
    final selected = <String>[];
    for (int i = 0; i < MockData.interests.length; i++) {
      if (_selectedInterests[i]) selected.add(MockData.interests[i]);
    }
    SavedTripsProvider.of(context).updateTrip(
      TripData(
        destination: SavedTripsProvider.of(context).currentTrip.destination,
        departDate: SavedTripsProvider.of(context).currentTrip.departDate,
        returnDate: SavedTripsProvider.of(context).currentTrip.returnDate,
        budget: _selectedBudgetTier,
        currency: CurrencyProvider.of(context).value,
        participants: SavedTripsProvider.of(context).currentTrip.participants,
        ageRange: SavedTripsProvider.of(context).currentTrip.ageRange,
        additionalNotes: SavedTripsProvider.of(
          context,
        ).currentTrip.additionalNotes,
        aiPrompt: _promptController.text,
        selectedInterests: selected,
      ),
    );
  }

  Future<void> _onGetSuggestions() async {
    if (!_validateInput()) return;
    _saveCurrentState();
    await SearchHistoryService.instance.recordTripSearch(
      SavedTripsProvider.of(context).currentTrip,
    );

    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TripConsultationScreen()));
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
              Padding(
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
                    const AccountMenuButton(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
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
            ],
          ),
        ),
      ),
      bottomSheet: BottomNavBar(currentIndex: 0, onTap: _onNavTap),
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
      onSuggest: _onGetSuggestions,
      onExplore: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ExploreScreen()));
      },
    );

    final quickPrompts = _QuickPromptChips(
      onSelected: (promptText) => _promptController.text = promptText,
    );

    final filters = LayoutBuilder(
      builder: (context, constraints) {
        final canUseTwoColumns = constraints.maxWidth >= 560;
        final budget = _buildBudgetTierSelector(l10n);
        final interests = _buildInterests(l10n);
        if (!canUseTwoColumns) {
          return Column(
            children: [budget, const SizedBox(height: 12), interests],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: budget),
            const SizedBox(width: 14),
            Expanded(child: interests),
          ],
        );
      },
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
              prompt,
              const SizedBox(height: 12),
              quickPrompts,
              const SizedBox(height: 20),
              filters,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(flex: 9, child: _CosmicEarthArtwork()),
            const SizedBox(width: 42),
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  intro,
                  const SizedBox(height: 22),
                  prompt,
                  const SizedBox(height: 12),
                  quickPrompts,
                  const SizedBox(height: 20),
                  filters,
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetTierSelector(AppLocalizations l10n) {
    final tiers = [
      (key: 'economy', label: l10n.budgetTierEconomy, badge: '🪙'),
      (key: 'moderate', label: l10n.budgetTierModerate, badge: '☕'),
      (key: 'premium', label: l10n.budgetTierPremium, badge: '💎'),
      (key: 'luxury', label: l10n.budgetTierLuxury, badge: '👑'),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF94A3B8),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.budgetTier.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 24) / 4;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tiers.map((tier) {
                  final isSelected =
                      _selectedBudgetTier.toLowerCase() == tier.key;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _selectedBudgetTier = tier.key;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: itemWidth,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFFE91E63), Color(0xFFFF4081)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : const Color(0xFF1E293B).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF80AB)
                              : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE91E63,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tier.badge,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tier.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterests(AppLocalizations l10n) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sell,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.interests.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(MockData.interests.length, (i) {
              final interestKey = MockData.interests[i];
              final localizedLabel = _getLocalizedInterest(interestKey, l10n);
              return InterestChip(
                label: localizedLabel,
                isSelected: _selectedInterests[i],
                onTap: () {
                  setState(
                    () => _selectedInterests[i] = !_selectedInterests[i],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AiPromptBox extends StatelessWidget {
  const _AiPromptBox({
    required this.controller,
    required this.onSuggest,
    required this.onExplore,
  });

  final TextEditingController controller;
  final VoidCallback onSuggest;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.search, color: primaryColor, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: 2,
                  minLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: l10n.aiPromptHint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontSize: 16,
                      height: 1.25,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onExplore,
                    icon: const Icon(Icons.explore_outlined, size: 19),
                    label: Text(l10n.explore),
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
                Container(
                  height: 48,
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
                      onTap: onSuggest,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 19,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              l10n.getAiSuggestions,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
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
    const prompts = [
      'Tokyo mùa hoa anh đào',
      'Đà Lạt 3 ngày 2 đêm',
      'Bali nghỉ dưỡng',
      'Phú Quốc ngắm hoàng hôn',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Gợi ý nhanh:',
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
