import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/screens/suggestions_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/services/profile_service.dart';
import 'package:voyz/services/search_history_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/aivivu_wordmark.dart';
import 'package:voyz/widgets/shared/account_menu_button.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
import 'package:voyz/widgets/shared/trip_chips.dart';

/// Planner AI-first: người dùng chỉ mô tả chuyến đi, AI bóc tách thành
/// [TripData] và hiện dưới dạng chip để sửa nhanh trước khi xem gợi ý.
class SmartPlannerScreen extends StatefulWidget {
  const SmartPlannerScreen({super.key});

  @override
  State<SmartPlannerScreen> createState() => _SmartPlannerScreenState();
}

class _SmartPlannerScreenState extends State<SmartPlannerScreen> {
  final _promptController = TextEditingController();

  /// Thông tin chuyến đi hiện trên hàng chip.
  TripData _trip = TripData();

  /// Sở thích lấy từ profile, dùng khi AI không suy ra được sở thích nào.
  List<String> _profileInterests = const [];

  /// Mô tả đã phân tích gần nhất. Rỗng thì chưa có chip.
  String _analyzedPrompt = '';
  bool _isAnalyzing = false;

  bool get _analyzed =>
      _analyzedPrompt.isNotEmpty &&
      _promptController.text.trim() == _analyzedPrompt;

  @override
  void initState() {
    super.initState();
    // Sửa mô tả thì nút quay về "Phân tích".
    _promptController.addListener(() {
      if (mounted) setState(() {});
    });
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
        _trip = trip;
        _promptController.text = trip.aiPrompt;
        // Mở lại planner thì hiện lại chip của lần trước.
        _analyzedPrompt = trip.aiPrompt.trim();
      });
    });
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
          content: Text(AppLocalizations.of(context)!.describeTripRequired),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _onAnalyze() async {
    if (!_validateInput() || _isAnalyzing) return;
    final languageCode = LocaleProvider.of(context).value.languageCode;
    final prompt = _promptController.text.trim();
    setState(() => _isAnalyzing = true);
    try {
      final ai = await GeminiService.instance.extractTripData(
        prompt,
        languageCode: languageCode,
      );
      if (!mounted) return;
      setState(() {
        // Mô tả mới thì thay toàn bộ chip, không giữ giá trị của chuyến cũ.
        _trip = ai.selectedInterests.isEmpty
            ? ai.copyWith(selectedInterests: _profileInterests)
            : ai;
        _analyzedPrompt = prompt;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    SavedTripsProvider.of(context).updateTrip(
      _trip.copyWith(
        aiPrompt: _promptController.text,
        currency: CurrencyProvider.of(context).value,
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
    ).push(MaterialPageRoute(builder: (_) => const SuggestionsScreen()));
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
      actionLabel: _isAnalyzing
          ? l10n.analyzingTrip
          : (_analyzed ? l10n.getAiSuggestions : l10n.analyzeTrip),
      actionIcon: _analyzed ? Icons.arrow_forward : Icons.auto_awesome,
      onAction: _isAnalyzing
          ? null
          : (_analyzed ? _onGetSuggestions : _onAnalyze),
      onExplore: () {
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
      children: [
        prompt,
        const SizedBox(height: 12),
        if (_analyzedPrompt.isEmpty)
          quickPrompts
        else
          TripChips(
            trip: _trip,
            onChanged: (trip) => setState(() => _trip = trip),
          ),
      ],
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
            const SizedBox(width: 42),
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [intro, const SizedBox(height: 22), content],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AiPromptBox extends StatelessWidget {
  const _AiPromptBox({
    required this.controller,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    required this.onExplore,
  });

  final TextEditingController controller;
  final String actionLabel;
  final IconData actionIcon;

  /// Null khi đang phân tích.
  final VoidCallback? onAction;
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
                  maxLines: 4,
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
                Opacity(
                  opacity: onAction == null ? 0.6 : 1,
                  child: Container(
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
          AppLocalizations.of(context)!.quickPromptsLabel,
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
