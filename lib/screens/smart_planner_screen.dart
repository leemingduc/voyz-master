import 'package:flutter/material.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/screens/suggestions_screen.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/services/profile_service.dart';
import 'package:voyz/services/search_history_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/account_menu_button.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
import 'package:voyz/widgets/shared/gradient_button.dart';

class SmartPlannerScreen extends StatefulWidget {
  const SmartPlannerScreen({super.key});

  @override
  State<SmartPlannerScreen> createState() => _SmartPlannerScreenState();
}

class _SmartPlannerScreenState extends State<SmartPlannerScreen> {
  final _promptController = TextEditingController();
  bool _isAnalyzing = false;
  UserProfile? _profile;

  final List<String> _inspirationPrompts = const [
    'Đi Đà Lạt 3 ngày với gia đình, tiết kiệm',
    'Nghỉ dưỡng biển Phú Quốc 4 ngày cao cấp',
    'Khám phá ẩm thực và văn hóa Hà Nội cuối tuần',
    'Tour trekking Sapa săn mây khám phá thiên nhiên',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final trip = SavedTripsProvider.of(context).currentTrip;
      _promptController.text = trip.aiPrompt;

      try {
        _profile = await ProfileService.instance.loadCurrentProfile();
        if (_profile != null && mounted) {
          await CurrencyProvider.of(context).setDisplayCurrency(
            trip.currency.isNotEmpty ? trip.currency : _profile!.preferredCurrency,
          );
        }
      } catch (_) {}
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

  Future<void> _onGetSuggestions() async {
    if (!_validateInput() || _isAnalyzing) return;

    final prompt = _promptController.text.trim();
    final languageCode = LocaleProvider.of(context).value.languageCode;
    // Cache context-dependent values before any await to avoid
    // use_build_context_synchronously warnings.
    final currency = CurrencyProvider.of(context).value;
    setState(() => _isAnalyzing = true);

    TripData tripToSave;
    try {
      final extracted = await GeminiService.instance.extractTripData(
        prompt,
        languageCode: languageCode,
      );

      final defaultInterests = _profile?.travelStyles
              .map((s) => s.toLowerCase().replaceAll(' ', '_'))
              .toList() ??
          <String>[];

      tripToSave = extracted.copyWith(
        aiPrompt: prompt,
        currency: currency,
        selectedInterests: extracted.selectedInterests.isNotEmpty
            ? extracted.selectedInterests
            : defaultInterests,
      );
    } catch (e) {
      debugPrint('AI extraction fallback: $e');
      tripToSave = TripData(
        aiPrompt: prompt,
        currency: currency,
        budget: 'moderate',
      );
    }

    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    SavedTripsProvider.of(context).updateTrip(tripToSave);
    try {
      await SearchHistoryService.instance.recordTripSearch(tripToSave);
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SuggestionsScreen()),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        // Already on Planner
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [const Color(0xFF1A1C2E), AppTheme.backgroundDark],
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
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appName,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
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
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        l10n.plannerGreeting,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _AiPromptBox(controller: _promptController),
                      const SizedBox(height: 20),

                      // Gợi ý mẫu (Inspiration Chips)
                      Text(
                        'Gợi ý cho bạn',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _inspirationPrompts.map((promptText) {
                          return ActionChip(
                            avatar: const Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Color(0xFF818CF8),
                            ),
                            label: Text(
                              promptText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onPressed: () {
                              setState(() {
                                _promptController.text = promptText;
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 36),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ExploreScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                ),
                              ),
                              child: Text(
                                l10n.explore,
                                style: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: GradientButton(
                              label: _isAnalyzing
                                  ? l10n.analyzingTrip
                                  : 'Gợi ý chuyến đi',
                              icon: _isAnalyzing
                                  ? Icons.hourglass_top
                                  : Icons.auto_awesome,
                              height: 52,
                              onPressed: _isAnalyzing ? null : _onGetSuggestions,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0, onTap: _onNavTap),
    );
  }
}

class _AiPromptBox extends StatelessWidget {
  const _AiPromptBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 20),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: l10n.aiPromptHint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: primaryColor.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              l10n.aiPowered,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: primaryColor.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
