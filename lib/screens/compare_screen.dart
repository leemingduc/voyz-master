import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/models/destination_comparison.dart';
import 'package:voyz/screens/smart_planner_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
import 'package:voyz/widgets/shared/glass_card.dart';
import 'package:voyz/widgets/shared/gradient_button.dart';

/// AI Destination Comparison screen — compare 2-3 destinations side by side.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _dest1Controller = TextEditingController();
  final _dest2Controller = TextEditingController();
  final _dest3Controller = TextEditingController();

  DestinationComparison? _comparison;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _dest1Controller.dispose();
    _dest2Controller.dispose();
    _dest3Controller.dispose();
    super.dispose();
  }

  Future<void> _compare() async {
    final dest1 = _dest1Controller.text.trim();
    final dest2 = _dest2Controller.text.trim();
    final dest3 = _dest3Controller.text.trim();

    if (dest1.isEmpty || dest2.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.compareMinError),
          backgroundColor: AppTheme.primaryPink,
        ),
      );
      return;
    }

    final destinations = [dest1, dest2];
    if (dest3.isNotEmpty) destinations.add(dest3);

    setState(() {
      _isLoading = true;
      _error = null;
      _comparison = null;
    });

    try {
      final result = await GeminiService.instance.compareDestinations(
        destinations,
        languageCode: LocaleProvider.of(context).value.languageCode,
      );

      if (mounted) {
        setState(() {
          _comparison = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
        title: Text(AppLocalizations.of(context)!.compareTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input section
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(context)!.compareInputHeader,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dest1Controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.compareDest1Hint,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dest2Controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.compareDest2Hint,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dest3Controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.compareDest3Hint,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: _isLoading
                        ? AppLocalizations.of(context)!.compareLoading
                        : AppLocalizations.of(context)!.compareButton,
                    icon: Icons.compare_arrows,
                    onPressed: _isLoading ? null : _compare,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            // Comparison results
            if (_comparison != null) ...[
              // Recommendation
              GlassCard(
                glowColor: AppTheme.primaryPink,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.recommend,
                          color: AppTheme.primaryPink,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.compareRecommendation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _comparison!.recommendation,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Destination cards
              ..._comparison!.destinations.map(
                (dest) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _DestinationCard(destination: dest),
                ),
              ),

              // Aspects comparison
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.compareDetail,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._comparison!.aspects.map(
                (aspect) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AspectCard(aspect: aspect),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3, onTap: _onNavTap),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.destination});

  final ComparedDestination destination;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  destination.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${destination.overallScore.toStringAsFixed(1)}/10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            destination.summary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (destination.pros.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.comparePros,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...destination.pros.map(
              (pro) => Padding(
                padding: const EdgeInsets.only(left: 26, bottom: 4),
                child: Text(
                  '• $pro',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
          if (destination.cons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.compareCons,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...destination.cons.map(
              (con) => Padding(
                padding: const EdgeInsets.only(left: 26, bottom: 4),
                child: Text(
                  '• $con',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
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

class _AspectCard extends StatelessWidget {
  const _AspectCard({required this.aspect});

  final ComparisonAspect aspect;

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'attach_money':
        return Icons.attach_money;
      case 'cloud':
        return Icons.cloud;
      case 'sports':
        return Icons.sports;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.compare_arrows;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(aspect.icon),
                color: AppTheme.primaryPink,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                aspect.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...aspect.details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      detail.destination,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detail.value,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${detail.score}/10',
                      style: TextStyle(
                        color: AppTheme.primaryPink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
