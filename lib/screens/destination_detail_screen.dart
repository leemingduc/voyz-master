import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/models/destination_detail.dart';
import 'package:voyz/screens/destination_plan_screen.dart';
import 'package:voyz/screens/best_time_screen.dart';
import 'package:voyz/screens/chat_screen.dart';
import 'package:voyz/screens/cultural_tips_screen.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/screens/smart_planner_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
import 'package:voyz/widgets/shared/gradient_button.dart';
import 'package:voyz/widgets/shared/currency_amount_text.dart';

/// Destination Detail screen — hero image, tags, weather, budget breakdown.
class DestinationDetailScreen extends StatefulWidget {
  const DestinationDetailScreen({super.key, required this.destinationName});

  final String destinationName;

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  DestinationDetail? _detail;
  String? _activeHeroUrl;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trip = SavedTripsProvider.of(context).currentTrip;
      final detail = await GeminiService.instance.getDestinationDetail(
        widget.destinationName,
        trip,
        languageCode: LocaleProvider.of(context).value.languageCode,
      );
      if (mounted) {
        setState(() {
          _detail = detail;
          _activeHeroUrl = detail.imageUrl;
          _isLoading = false;
        });
        unawaited(_prefetchItinerary());
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

  Future<void> _prefetchItinerary() async {
    try {
      final trip = SavedTripsProvider.of(context).currentTrip;
      int numDays = 3;
      if (trip.departDate != null && trip.returnDate != null) {
        numDays = trip.returnDate!.difference(trip.departDate!).inDays;
        if (numDays < 1) numDays = 1;
        if (numDays > 7) numDays = 7;
      }

      await GeminiService.instance.getItineraryPlan(
        widget.destinationName,
        numDays,
        trip,
        limit: 3,
        languageCode: LocaleProvider.of(context).value.languageCode,
      );
    } catch (error) {
      debugPrint('Itinerary prefetch skipped: $error');
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

  void _onShare(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.share, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.shareLinkCopied),
          ],
        ),
        backgroundColor: AppTheme.primaryPink.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onSaveInfo(BuildContext context) {
    if (_detail == null) return;
    final d = _detail!;
    final added = SavedTripsProvider.of(context).saveFullTrip(
      name: d.name,
      imageUrl: d.imageUrl,
      price: d.totalBudget,
      matchPercent: 98,
      rating: 4.5,
      reviewCount: 120,
      aiInsight: AppLocalizations.of(context)!.defaultAiInsight,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              added ? Icons.bookmark_added : Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                added
                    ? AppLocalizations.of(context)!.tripInfoSaved
                    : AppLocalizations.of(context)!.alreadySavedMessage(d.name),
              ),
            ),
          ],
        ),
        backgroundColor: added
            ? const Color(0xFF10B981)
            : const Color(0xFF475569),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.loadingDetail,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _detail == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.cannotLoadDetail,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? AppLocalizations.of(context)!.unknownError,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(AppLocalizations.of(context)!.goBack),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _loadDetail,
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.retry),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final d = _detail!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroSection(
                  theme: theme,
                  imageUrl: _activeHeroUrl ?? d.imageUrl,
                  onShare: () => _onShare(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LocationSubtitle(theme: theme, location: d.location),
                      const SizedBox(height: 8),
                      Text(
                        d.name,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TagsRow(tags: d.tags),
                      if (d.gallery.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _LandmarkGallerySection(
                          gallery: d.gallery,
                          fallbackUrl: d.imageUrl,
                          onSelectPhoto: (url) {
                            setState(() {
                              _activeHeroUrl = url;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      _WeatherCard(
                        theme: theme,
                        weather: d.weather,
                        dateRange: d.dateRange,
                      ),
                      const SizedBox(height: 16),
                      _BudgetCard(
                        theme: theme,
                        totalBudget: d.totalBudget,
                        breakdown: d.budgetBreakdown,
                      ),
                      const SizedBox(height: 32),
                      _ActionButtons(
                        theme: theme,
                        onSaveInfo: () => _onSaveInfo(context),
                        destinationName: d.name,
                        dateRange: d.dateRange,
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(currentIndex: 1, onTap: _onNavTap),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.theme,
    required this.imageUrl,
    required this.onShare,
  });
  final ThemeData theme;
  final String imageUrl;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            errorWidget: (ctx, url, err) =>
                Container(color: const Color(0xFF1E293B)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
                colors: [Colors.transparent, AppTheme.backgroundDark],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleBtn(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    _CircleBtn(icon: Icons.share, onTap: onShare),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: AppTheme.primaryPink, size: 22),
      ),
    );
  }
}

class _LocationSubtitle extends StatelessWidget {
  const _LocationSubtitle({required this.theme, required this.location});
  final ThemeData theme;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.location_on, color: theme.colorScheme.tertiary, size: 20),
        const SizedBox(width: 4),
        Text(
          location.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.tertiary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                tag,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.theme,
    required this.weather,
    required this.dateRange,
  });
  final ThemeData theme;
  final String weather;
  final String dateRange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.wb_sunny,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  dateRange,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.theme,
    required this.totalBudget,
    required this.breakdown,
  });
  final ThemeData theme;
  final String totalBudget;
  final List<BudgetItem> breakdown;

  static const _colors = [
    AppTheme.primaryPink,
    AppTheme.secondaryOrange,
    AppTheme.accentBlue,
    Color(0x33FFFFFF),
  ];
  static const _icons = {
    'flight': Icons.flight,
    'hotel': Icons.hotel,
    'restaurant': Icons.restaurant,
    'kayaking': Icons.kayaking,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.estimatedBudget,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CurrencyAmountText(
                    totalBudget,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    originalStyle: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.payments,
                  color: theme.colorScheme.tertiary,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: List.generate(breakdown.length, (i) {
                  final item = breakdown[i];
                  return Expanded(
                    flex: (item.fraction * 100).round(),
                    child: Container(color: _colors[i % _colors.length]),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: List.generate(breakdown.length, (i) {
              final item = breakdown[i];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _icons[item.icon] ?? Icons.circle,
                    size: 14,
                    color: _colors[i % _colors.length],
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.label}: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      CurrencyAmountText(
                        item.amount,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        originalStyle: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.theme,
    required this.onSaveInfo,
    required this.destinationName,
    required this.dateRange,
  });
  final ThemeData theme;
  final VoidCallback onSaveInfo;
  final String destinationName;
  final String dateRange;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GradientButton(
          label: AppLocalizations.of(context)!.generateAiItinerary,
          icon: Icons.auto_awesome,
          height: 56,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DestinationPlanScreen(
                destinationName: destinationName,
                dateRange: dateRange,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OutlineBtn(
                label: AppLocalizations.of(context)!.contextBestTime,
                icon: Icons.calendar_month,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        BestTimeScreen(initialDestination: destinationName),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutlineBtn(
                label: AppLocalizations.of(context)!.contextAskAboutDestination,
                icon: Icons.auto_awesome,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ChatScreen(destinationName: destinationName),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GradientButton(
          label: AppLocalizations.of(context)!.culturalTipsButton,
          icon: Icons.theater_comedy,
          height: 56,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CulturalTipsScreen(destinationName: destinationName),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OutlineBtn(
                label: AppLocalizations.of(context)!.saveInfo,
                icon: Icons.bookmark,
                onPressed: onSaveInfo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.bookNow,
                          style: TextStyle(
                            color: AppTheme.backgroundDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: AppTheme.backgroundDark,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.icon, this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandmarkGallerySection extends StatefulWidget {
  const _LandmarkGallerySection({
    required this.gallery,
    required this.fallbackUrl,
    required this.onSelectPhoto,
  });

  final List<DestinationLandmarkPhoto> gallery;
  final String fallbackUrl;
  final ValueChanged<String> onSelectPhoto;

  @override
  State<_LandmarkGallerySection> createState() =>
      _LandmarkGallerySectionState();
}

class _LandmarkGallerySectionState extends State<_LandmarkGallerySection> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.gallery.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFFE91E63),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'THẮNG CẢNH BIỂU TƯỢNG & ẢNH THỰC TẾ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.gallery.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final photo = widget.gallery[index];
              final isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  widget.onSelectPhoto(photo.imageUrl);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE91E63)
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFE91E63).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: photo.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            color: const Color(0xFF1E1B2E),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: const Color(0xFF1E1B2E),
                            child: const Icon(Icons.landscape, color: Colors.white24),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Text(
                            photo.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE91E63),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

