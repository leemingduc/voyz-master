import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/models/best_time_travel.dart';
import 'package:voyz/screens/smart_planner_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
import 'package:voyz/widgets/shared/glass_card.dart';
import 'package:voyz/widgets/shared/gradient_button.dart';

/// AI Best Time to Travel screen — analyze when to visit a destination.
class BestTimeScreen extends StatefulWidget {
  const BestTimeScreen({super.key, this.initialDestination});

  final String? initialDestination;

  @override
  State<BestTimeScreen> createState() => _BestTimeScreenState();
}

class _BestTimeScreenState extends State<BestTimeScreen> {
  final _destinationController = TextEditingController();

  BestTimeTravel? _bestTime;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final destination = widget.initialDestination?.trim();
    if (destination != null && destination.isNotEmpty) {
      _destinationController.text = destination;
      WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final destination = _destinationController.text.trim();

    if (destination.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.bestTimeMinError),
          backgroundColor: AppTheme.primaryPink,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _bestTime = null;
    });

    try {
      final result = await GeminiService.instance.getBestTimeToTravel(
        destination,
        languageCode: LocaleProvider.of(context).value.languageCode,
      );

      if (mounted) {
        setState(() {
          _bestTime = result;
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
        title: Text(AppLocalizations.of(context)!.bestTimeTitle),
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
                    AppLocalizations.of(context)!.bestTimeInputHeader,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _destinationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.bestTimeHint,
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
                        ? AppLocalizations.of(context)!.bestTimeLoading
                        : AppLocalizations.of(context)!.bestTimeButton,
                    icon: Icons.calendar_today,
                    onPressed: _isLoading ? null : _analyze,
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

            // Results
            if (_bestTime != null) ...[
              // Summary card
              GlassCard(
                glowColor: AppTheme.primaryPink,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppTheme.primaryPink,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _bestTime!.destination,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _bestTime!.summary,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.bestTimeBestMonth(_bestTime!.bestMonth),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Seasons
              Text(
                AppLocalizations.of(context)!.bestTimeSeasons,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._bestTime!.seasons.map(
                (season) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SeasonCard(season: season),
                ),
              ),

              const SizedBox(height: 16),

              // Monthly data
              Text(
                AppLocalizations.of(context)!.bestTimeMonthly,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _bestTime!.monthlyData.length,
                  itemBuilder: (context, index) {
                    final month = _bestTime!.monthlyData[index];
                    return _MonthCard(
                      month: month,
                      isBest: month.month == _bestTime!.bestMonth,
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Tips
              Text(
                AppLocalizations.of(context)!.bestTimeTips,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._bestTime!.tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TipCard(tip: tip),
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

class _SeasonCard extends StatelessWidget {
  const _SeasonCard({required this.season});

  final SeasonInfo season;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      season.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      season.period,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < season.rating ? Icons.star : Icons.star_border,
                    color: AppTheme.primaryPink,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            season.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.month, required this.isBest});

  final MonthInfo month;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        glowColor: isBest ? AppTheme.primaryPink : null,
        borderColor: isBest ? AppTheme.primaryPink : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    month.month,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isBest)
                  Icon(Icons.star, color: AppTheme.primaryPink, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.thermostat, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  month.temperature,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text(
                  month.rainfall,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${month.suitabilityScore}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.primaryPink,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                month.highlight,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  height: 1.4,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final TravelTip tip;

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'flight_takeoff':
        return Icons.flight_takeoff;
      case 'hotel':
        return Icons.hotel;
      case 'event':
        return Icons.event;
      case 'attach_money':
        return Icons.attach_money;
      case 'calendar_today':
        return Icons.calendar_today;
      default:
        return Icons.lightbulb;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryPink.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIcon(tip.icon),
              color: AppTheme.primaryPink,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.4,
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
