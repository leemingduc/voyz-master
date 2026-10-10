import 'dart:async';

import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/destination_detail.dart';
import 'package:voyz/models/plan_turn.dart';
import 'package:voyz/screens/destination_plan_screen.dart';
import 'package:voyz/screens/best_time_screen.dart';
import 'package:voyz/screens/cultural_tips_screen.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/screens/smart_planner_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/screens/friends_screen.dart';
import 'package:voyz/services/community_review_service.dart';
import 'package:voyz/services/destination_repository.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/utils/destination_rating_calculator.dart';
import 'package:voyz/widgets/shared/account_menu_button.dart';
import 'package:voyz/widgets/shared/aivivu_loading_indicator.dart';
import 'package:voyz/widgets/shared/aivivu_rocket_mascot.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
import 'package:voyz/widgets/shared/currency_amount_text.dart';
import 'package:voyz/widgets/shared/destination_image.dart';
import 'package:voyz/widgets/shared/gradient_button.dart';
import 'package:voyz/widgets/shared/share_destination_bottom_sheet.dart';

/// Destination Detail screen - hero image, tags, weather, budget breakdown.
class DestinationDetailScreen extends StatefulWidget {
  const DestinationDetailScreen({
    super.key,
    required this.destinationName,
    this.savedItem,
    this.suggestedOptions = const [],
    this.selectedSuggestionIndex = 0,
  });

  final String destinationName;

  /// Khác null khi mở từ danh sách đã lưu: dùng tripData của trip đó,
  /// không dùng currentTrip toàn cục.
  final SavedItem? savedItem;

  final List<TripOption> suggestedOptions;
  final int selectedSuggestionIndex;

  /// Các phương án từ cùng một lượt gợi ý AI. Chỉ có khi mở từ Planner.
  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  DestinationDetail? _detail;
  String? _activeHeroUrl;
  String? _destinationId;
  final _reviewController = TextEditingController();
  List<CommunityReview> _reviews = const [];
  int _reviewRating = 5;
  bool _isSavingReview = false;
  bool _isLoadingReviews = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  late String _destinationName;
  late int _selectedSuggestionIndex;
  final Map<int, DestinationDetail> _aiDetailCache = {};

  SavedItem? _savedItem;

  TripData get _trip =>
      _savedItem?.tripData ?? SavedTripsProvider.of(context).currentTrip;

  TripOption? get _activeAiSuggestion {
    if (_selectedSuggestionIndex < 0 ||
        _selectedSuggestionIndex >= widget.suggestedOptions.length) {
      return null;
    }
    return widget.suggestedOptions[_selectedSuggestionIndex];
  }

  @override
  void initState() {
    super.initState();
    _savedItem = widget.savedItem;
    _destinationName = widget.destinationName;
    _selectedSuggestionIndex = widget.selectedSuggestionIndex
        .clamp(
          0,
          widget.suggestedOptions.isEmpty
              ? 0
              : widget.suggestedOptions.length - 1,
        )
        .toInt();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final destinationName = _destinationName;
    final suggestionIndex = _selectedSuggestionIndex;
    final isAiSuggestion = widget.suggestedOptions.isNotEmpty;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trip = _trip;
      final cachedAiDetail = isAiSuggestion
          ? _aiDetailCache[suggestionIndex]
          : null;
      final DestinationDetail detail;
      if (cachedAiDetail != null) {
        detail = cachedAiDetail;
      } else if (isAiSuggestion) {
        // A planner suggestion can share a destination with another option but
        // have a different theme and route. Its detail must therefore use the
        // selected AI prompt instead of the generic database detail.
        detail = await GeminiService.instance.getDestinationDetail(
          destinationName,
          trip,
          languageCode: LocaleProvider.of(context).value.languageCode,
        );
        _aiDetailCache[suggestionIndex] = detail;
      } else {
        final dbDetail = await DestinationRepository.instance
            .getDestinationDetail(destinationName);
        detail =
            dbDetail ??
            await GeminiService.instance.getDestinationDetail(
              destinationName,
              trip,
              languageCode: LocaleProvider.of(context).value.languageCode,
            );
      }
      if (mounted &&
          _destinationName == destinationName &&
          (!isAiSuggestion || _selectedSuggestionIndex == suggestionIndex)) {
        setState(() {
          _detail = detail;
          _activeHeroUrl = detail.imageUrl;
          _isLoading = false;
        });
        unawaited(_prefetchItinerary(destinationName));
        unawaited(_loadReviews(destinationName));
      }
    } catch (e) {
      if (mounted && _destinationName == destinationName) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReviews([String? targetDestination]) async {
    final destinationName = targetDestination ?? _destinationName;
    setState(() => _isLoadingReviews = true);
    try {
      final destinationId = await DestinationRepository.instance
          .getDestinationIdByName(destinationName);
      if (destinationId == null) {
        if (mounted && _destinationName == destinationName) {
          setState(() => _isLoadingReviews = false);
        }
        return;
      }
      final reviews = await CommunityReviewService.instance.listForDestination(
        destinationId,
      );
      if (!mounted || _destinationName != destinationName) return;
      setState(() {
        _destinationId = destinationId;
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (error) {
      debugPrint('Review load skipped: $error');
      if (mounted && _destinationName == destinationName) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _submitReview() async {
    final destinationId = _destinationId;
    if (destinationId == null || _isSavingReview) return;
    setState(() => _isSavingReview = true);
    try {
      await CommunityReviewService.instance.upsertReview(
        destinationId: destinationId,
        rating: _reviewRating,
        comment: _reviewController.text,
      );
      _reviewController.clear();
      await _loadReviews();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review saved')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSavingReview = false);
    }
  }

  Future<void> _prefetchItinerary(String destinationName) async {
    try {
      final trip = _trip;
      await GeminiService.instance.getItineraryPlan(
        destinationName,
        trip.dayCount(),
        trip,
        limit: 6,
        languageCode: LocaleProvider.of(context).value.languageCode,
      );
    } catch (error) {
      debugPrint('Itinerary prefetch skipped: $error');
    }
  }

  void _selectAiSuggestion(int index) {
    if (index < 0 || index >= widget.suggestedOptions.length) return;
    if (index == _selectedSuggestionIndex) return;

    final option = widget.suggestedOptions[index];
    final currentTrip = _trip;
    final selection =
        'Phương án đã chọn: ${option.title}, ${option.numDays} ngày, '
        'lộ trình: ${option.stops.join(', ')}.';
    SavedTripsProvider.of(context).updateTrip(
      currentTrip.copyWith(
        destination: option.destination,
        numDays: option.numDays,
        aiPrompt: '${currentTrip.aiPrompt}\n$selection'.trim(),
      ),
    );
    setState(() {
      _selectedSuggestionIndex = index;
      _destinationName = option.destination;
      _activeHeroUrl = null;
      _destinationId = null;
      _reviews = const [];
      _savedItem = null;
    });
    unawaited(_loadDetail());
  }

  /*
  List<TripOption> get _switchableOptions {
    final source = _regionalOptions.isNotEmpty
        ? _regionalOptions
        : [...widget.suggestedOptions, ..._alternativeOptions];
    final seen = <String>{};
    final destinations = source.where((option) {
      final destination = option.destination.trim();
      return destination.isNotEmpty && seen.add(destination.toLowerCase());
    }).toList();
    if (!seen.contains(_destinationName.trim().toLowerCase())) {
      destinations.insert(
        0,
        TripOption(
          title: 'Đang xem',
          destination: _destinationName,
          numDays: _trip.dayCount(),
          stops: [_destinationName],
          imageStop: _destinationName,
          price: '',
          aiInsight: '',
        ),
      );
      seen.add(_destinationName.trim().toLowerCase());
    }
    if (destinations.length >= 2) return destinations;

    // Khi người dùng đã nêu một thành phố, Planner giữ cùng điểm đến gốc cho
    // các phương án và thay đổi các điểm dừng. Lúc đó dùng chính các điểm dừng
    // riêng này để người dùng chuyển thẳng sang detail của địa danh khác.
    for (final option in source) {
      for (final stop in option.stops) {
        final name = stop.trim();
        if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
        destinations.add(
          TripOption(
            title: option.title,
            destination: name,
            numDays: option.numDays,
            stops: option.stops,
            imageStop: name,
            price: option.price,
            aiInsight: option.aiInsight,
            imageUrl: option.imageUrl,
          ),
        );
      }
    }
    return destinations;
  }

  Future<void> _loadAlternativeOptions() async {
    if (widget.suggestedOptions.isNotEmpty || _regionalOptions.isNotEmpty) {
      return;
    }

    final messages = SavedTripsProvider.of(context).plannerMessages;
    for (final message in messages.reversed) {
      final options = message.turn?.options ?? const <TripOption>[];
      if (options.isNotEmpty) {
        if (mounted) setState(() => _alternativeOptions = options);
        return;
      }
    }

    final suggestions = await DestinationRepository.instance
        .getDestinationsByCategory(categoryKey: 'random', limit: 3);
    if (!mounted) return;
    setState(() {
      _alternativeOptions = suggestions
          .map(
            (suggestion) => TripOption(
              title: suggestion.aiInsight,
              destination: suggestion.name,
              numDays: _trip.dayCount(),
              stops: [suggestion.name],
              imageStop: suggestion.name,
              price: suggestion.price,
              aiInsight: suggestion.aiInsight,
              imageUrl: suggestion.imageUrl,
            ),
          )
          .where((option) => option.destination.isNotEmpty)
          .toList();
    });
  }

  Future<void> _switchDestination(TripOption option) async {
    final destination = option.destination.trim();
    if (destination.isEmpty || destination == _destinationName) return;

    final currentTrip = _trip;
    final previousDestination = _destinationName;
    final previousSavedItem = _savedItem;
    final selectedRoute =
        'Phương án đã chọn: ${option.title}, ${option.numDays} ngày, '
        'lộ trình: ${option.stops.join(', ')}.';
    final prompt = [currentTrip.aiPrompt.trim(), selectedRoute]
        .where((line) => line.isNotEmpty)
        .join('\n');
    SavedTripsProvider.of(context).updateTrip(
      currentTrip.copyWith(
        destination: destination,
        numDays: option.numDays,
        aiPrompt: prompt,
      ),
    );
    setState(() {
      _destinationName = destination;
      _activeHeroUrl = null;
      _destinationId = null;
      _reviews = const [];
      _savedItem = null;
    });
    final loaded = await _loadDetail();
    if (!mounted || loaded || _destinationName != destination) return;

    SavedTripsProvider.of(context).updateTrip(currentTrip);
    setState(() {
      _destinationName = previousDestination;
      _savedItem = previousSavedItem;
      _error = null;
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không thể tải địa điểm này. Vui lòng thử lại.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _compareOptions() {
    final destinations = _switchableOptions
        .map((option) => option.destination.trim())
        .take(3)
        .toList();
    if (destinations.length < 2) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompareScreen(
          initialDestinations: destinations,
          initialTrip: _trip,
        ),
      ),
    );
  }

  Future<void> _showDestinationBottomSheet() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DestinationPickerSheet(
        options: _switchableOptions,
        currentDestination: _destinationName,
      ),
    );
    if (!mounted || selected == null) return;
    if (selected == -1) {
      _compareOptions();
    } else if (selected >= 0 && selected < _switchableOptions.length) {
      _switchDestination(_switchableOptions[selected]);
    }
  }

  */
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

  void _onShare(BuildContext context) {
    ShareDestinationBottomSheet.show(
      context,
      destinationName: _detail?.name ?? _destinationName,
      destinationId: _destinationName,
      imageUrl: _detail?.imageUrl,
      subtitle: _detail != null
          ? '${_detail!.tags.take(2).join(' • ')} • ${_detail!.totalBudget}'
          : null,
    );
  }

  Future<SavedItem> _saveCurrentDetail() async {
    final d = _detail!;
    final totalVotes = DestinationRatingCalculator.calculateReviewCount(
      _reviews.length,
    );
    final average = DestinationRatingCalculator.calculateAverageRating(
      _reviews.map((r) => r.rating),
    );
    final existingItem = _savedItem;
    if (existingItem != null) {
      final updated = existingItem.copyWith(
        name: d.name,
        imageUrl: d.imageUrl,
        price: d.totalBudget,
        rating: average ?? existingItem.rating,
        reviewCount: totalVotes > 0 ? totalVotes : existingItem.reviewCount,
        tripData: _trip,
      );
      await SavedTripsProvider.of(context).updateWorkspace(updated);
      return updated;
    }
    return SavedTripsProvider.of(context).saveFullTrip(
      name: d.name,
      imageUrl: d.imageUrl,
      price: d.totalBudget,
      matchPercent: 98,
      rating: average ?? 0.0,
      reviewCount: totalVotes,
      aiInsight: AppLocalizations.of(context)!.defaultAiInsight,
      tripData: _trip,
    );
  }

  Future<void> _onSaveInfo(BuildContext context) async {
    if (_isSaving) return;
    if (_detail == null) return;
    final l10n = AppLocalizations.of(context)!;
    _isSaving = true;
    try {
      final item = await _saveCurrentDetail();
      if (!context.mounted) return;
      setState(() => _savedItem = item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bookmark_added, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.tripInfoSaved)),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    } finally {
      _isSaving = false;
    }
  }

  /// Có itinerary tức là có trip: chưa lưu thì lưu trước rồi mới mở plan.
  Future<void> _onGenerateItinerary() async {
    if (_isSaving) return;
    if (_detail == null) return;
    _isSaving = true;
    try {
      _savedItem ??= await _saveCurrentDetail();
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DestinationPlanScreen(
            tripId: _savedItem!.id,
            destinationName: _destinationName,
            dateRange: _detail!.dateRange,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    } finally {
      _isSaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeAiSuggestion = _activeAiSuggestion;

    if (_isLoading && _detail == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: AivivuLoadingIndicator(
            message: AppLocalizations.of(context)!.loadingDetail,
            size: 88,
          ),
        ),
      );
    }

    if (_detail == null) {
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.015, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: CustomScrollView(
              key: ValueKey('${d.name}:$_selectedSuggestionIndex'),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroSection(
                    theme: theme,
                    imageUrl: _activeHeroUrl ?? d.imageUrl,
                    destinationName: d.name,
                    onShare: () => _onShare(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.sizeOf(context).width >= 900
                          ? 40
                          : 24,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LocationSubtitle(
                              theme: theme,
                              location: d.location,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              d.name,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (activeAiSuggestion != null) ...[
                              const SizedBox(height: 10),
                              _AiSuggestionTheme(option: activeAiSuggestion),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFBBF24),
                                  size: 18,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _ratingSummary(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (widget.suggestedOptions.length >= 2) ...[
                              _AiSuggestionSelector(
                                options: widget.suggestedOptions,
                                selectedIndex: _selectedSuggestionIndex,
                                onSelected: _selectAiSuggestion,
                              ),
                              const SizedBox(height: 16),
                            ],
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
                            _WeatherCard(theme: theme, weather: d.weather),
                            const SizedBox(height: 16),
                            _BudgetCard(
                              theme: theme,
                              totalBudget: d.totalBudget,
                              breakdown: d.budgetBreakdown,
                            ),
                            const SizedBox(height: 24),
                            _buildReviewsSection(theme),
                            const SizedBox(height: 32),
                            _ActionButtons(
                              theme: theme,
                              onSaveInfo: () => _onSaveInfo(context),
                              onGenerateItinerary: _onGenerateItinerary,
                              destinationName: d.name,
                            ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
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

  /// "4.5 (12 lượt)" khi đã có đánh giá, "Chưa có đánh giá" khi chưa có.
  String _ratingSummary() {
    final average = DestinationRatingCalculator.calculateAverageRating(
      _reviews.map((r) => r.rating),
    );
    if (average == null) {
      return DestinationRatingCalculator.formatVotes(0);
    }
    final votes = DestinationRatingCalculator.formatVotes(
      DestinationRatingCalculator.calculateReviewCount(_reviews.length),
    );
    return '${average.toStringAsFixed(1)} ($votes)';
  }

  Widget _buildReviewsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rate, color: Color(0xFFFBBF24), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Community reviews',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                _ratingSummary(),
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _reviewRating = value),
                icon: Icon(
                  value <= _reviewRating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFBBF24),
                ),
              );
            }),
          ),
          TextField(
            controller: _reviewController,
            minLines: 2,
            maxLines: 3,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.45,
              letterSpacing: 0.2,
            ),
            decoration: InputDecoration(
              hintText: 'Share a quick tip for other travelers',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 14,
                height: 1.45,
                letterSpacing: 0.2,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.cyan, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _destinationId == null || _isSavingReview
                  ? null
                  : _submitReview,
              icon: Icon(
                _isSavingReview ? Icons.hourglass_empty : Icons.send,
                size: 16,
              ),
              label: Text(_isSavingReview ? 'Saving' : 'Post review'),
            ),
          ),
          if (_isLoadingReviews) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: AivivuRocketMascot(size: 32),
            ),
          ] else if (_reviews.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._reviews.take(3).map((review) => _ReviewTile(review: review)),
          ],
        ],
      ),
    );
  }
}

class _AiSuggestionSelector extends StatelessWidget {
  const _AiSuggestionSelector({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<TripOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = index == selectedIndex;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minWidth: 154, maxWidth: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.cyan.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.cyan.withValues(alpha: 0.52)
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title.isEmpty ? option.destination : option.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? AppTheme.cyan : Colors.white,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    if (option.title.isNotEmpty &&
                        option.destination.isNotEmpty &&
                        option.destination != option.title) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AiSuggestionTheme extends StatelessWidget {
  const _AiSuggestionTheme({required this.option});

  final TripOption option;

  @override
  Widget build(BuildContext context) {
    final route = option.stops.where((stop) => stop.trim().isNotEmpty).take(3);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppTheme.cyan, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.cyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (route.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    route.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/*
class _DestinationSwitcher extends StatelessWidget {
  const _DestinationSwitcher({
    required this.options,
    required this.currentDestination,
    required this.onSelect,
    required this.onCompare,
    required this.onOpenMobile,
  });

  final List<TripOption> options;
  final String currentDestination;
  final ValueChanged<TripOption> onSelect;
  final VoidCallback onCompare;
  final VoidCallback onOpenMobile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final button = OutlinedButton.icon(
          onPressed: constraints.maxWidth < 700 ? onOpenMobile : () {},
          icon: const Icon(Icons.sync, size: 18),
          label: const Text('🔄 Đổi địa điểm'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.cyan,
            side: BorderSide(color: AppTheme.cyan.withValues(alpha: 0.45)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
        if (constraints.maxWidth < 700) return button;

        return PopupMenuButton<int>(
          tooltip: 'Đổi địa điểm',
          color: AppTheme.surfaceDark,
          constraints: const BoxConstraints(maxWidth: 360),
          onSelected: (value) {
            if (value == -1) {
              onCompare();
            } else if (value >= 0 && value < options.length) {
              onSelect(options[value]);
            }
          },
          itemBuilder: (context) => [
            for (var index = 0; index < options.length; index++)
              PopupMenuItem<int>(
                value: index,
                child: _DestinationPickerItem(
                  option: options[index],
                  isSelected:
                      options[index].destination.trim().toLowerCase() ==
                      currentDestination.trim().toLowerCase(),
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem<int>(
              value: -1,
              child: Row(
                children: [
                  Icon(Icons.balance, color: AppTheme.cyan, size: 20),
                  SizedBox(width: 10),
                  Text('⚖ So sánh các lựa chọn'),
                ],
              ),
            ),
          ],
          child: IgnorePointer(child: button),
        );
      },
    );
  }
}

class _DestinationPickerSheet extends StatelessWidget {
  const _DestinationPickerSheet({
    required this.options,
    required this.currentDestination,
  });

  final List<TripOption> options;
  final String currentDestination;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đổi địa điểm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected =
                      option.destination.trim().toLowerCase() ==
                      currentDestination.trim().toLowerCase();
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      onTap: () => Navigator.pop(context, index),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.cyan.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.cyan.withValues(alpha: 0.55)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: _DestinationPickerItem(
                          option: option,
                          isSelected: isSelected,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.balance, color: AppTheme.cyan),
              title: const Text(
                '⚖ So sánh các lựa chọn',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              onTap: () => Navigator.pop(context, -1),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationPickerItem extends StatelessWidget {
  const _DestinationPickerItem({required this.option, required this.isSelected});

  final TripOption option;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? AppTheme.cyan : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (option.title.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  option.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isSelected) const Icon(Icons.check_circle, color: AppTheme.cyan),
      ],
    );
  }
}

*/
class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final CommunityReview review;

  @override
  Widget build(BuildContext context) {
    final displayName = review.userName.isNotEmpty
        ? review.userName
        : 'Anonymous';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF94A3B8), size: 14),
              const SizedBox(width: 4),
              Text(
                displayName,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${review.createdAt.month}/${review.createdAt.day}/${review.createdAt.year}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                color: const Color(0xFFFBBF24),
                size: 14,
              ),
            ),
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.theme,
    required this.imageUrl,
    required this.destinationName,
    required this.onShare,
  });
  final ThemeData theme;
  final String imageUrl;
  final String destinationName;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DestinationImage(
            imageUrl: imageUrl,
            destinationName: destinationName,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CircleBtn(icon: Icons.share, onTap: onShare),
                        const SizedBox(width: 8),
                        const AccountMenuButton(),
                      ],
                    ),
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
  const _WeatherCard({required this.theme, required this.weather});
  final ThemeData theme;
  final String weather;

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
    required this.onGenerateItinerary,
    required this.destinationName,
  });
  final ThemeData theme;
  final VoidCallback onSaveInfo;
  final VoidCallback onGenerateItinerary;
  final String destinationName;

  @override
  Widget build(BuildContext context) {
    final itineraryButton = GradientButton(
      label: AppLocalizations.of(context)!.generateAiItinerary,
      icon: Icons.auto_awesome,
      height: 56,
      onPressed: onGenerateItinerary,
    );
    final culturalTipsButton = GradientButton(
      label: AppLocalizations.of(context)!.culturalTipsButton,
      icon: Icons.theater_comedy,
      height: 56,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CulturalTipsScreen(destinationName: destinationName),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              itineraryButton,
              const SizedBox(height: 12),
              _bestTimeButton(context),
              const SizedBox(height: 12),
              culturalTipsButton,
              const SizedBox(height: 12),
              _OutlineBtn(
                label: AppLocalizations.of(context)!.saveInfo,
                icon: Icons.bookmark,
                onPressed: onSaveInfo,
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: itineraryButton),
                const SizedBox(width: 12),
                Expanded(child: _bestTimeButton(context, height: 56)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: culturalTipsButton),
                const SizedBox(width: 12),
                Expanded(
                  child: _OutlineBtn(
                    label: AppLocalizations.of(context)!.saveInfo,
                    icon: Icons.bookmark,
                    height: 56,
                    onPressed: onSaveInfo,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  _OutlineBtn _bestTimeButton(BuildContext context, {double height = 48}) {
    return _OutlineBtn(
      label: AppLocalizations.of(context)!.contextBestTime,
      icon: Icons.calendar_month,
      height: height,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BestTimeScreen(initialDestination: destinationName),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.label,
    required this.icon,
    this.height = 48,
    this.onPressed,
  });
  final String label;
  final IconData icon;
  final double height;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
                              color: const Color(
                                0xFFE91E63,
                              ).withValues(alpha: 0.35),
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
                        DestinationImage(
                          imageUrl: photo.imageUrl,
                          destinationName: photo.title,
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
