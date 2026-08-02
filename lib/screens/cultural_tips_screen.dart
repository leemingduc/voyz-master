import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/models/cultural_tips.dart';
import 'package:voyz/services/gemini_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/glass_card.dart';

// ── Theme colors for sections ──
const Color _dosColor = Color(0xFF4ADE80);
const Color _dontsColor = Color(0xFFFF6B6B);
const Color _phrasesColor = Color(0xFF60A5FA);
const Color _diningColor = Color(0xFFFFB74D);
const Color _sacredColor = Color(0xFFBA68C8);
const Color _adviceColor = Color(0xFFF59E0B);

/// Màn hình hướng dẫn văn hóa AI — Do's & Don'ts, câu giao tiếp, ăn uống, đền chùa.
class CulturalTipsScreen extends StatefulWidget {
  const CulturalTipsScreen({super.key, required this.destinationName});

  final String destinationName;

  @override
  State<CulturalTipsScreen> createState() => _CulturalTipsScreenState();
}

class _CulturalTipsScreenState extends State<CulturalTipsScreen> {
  CulturalTips? _tips;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTips());
  }

  Future<void> _loadTips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tips = await GeminiService.instance.getCulturalTips(
        widget.destinationName,
        languageCode: LocaleProvider.of(context).value.languageCode,
      );
      if (mounted) {
        setState(() {
          _tips = tips;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [const Color(0xFF0A1628), AppTheme.backgroundDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──
              _buildTopBar(theme),
              // ── Body ──
              Expanded(child: _buildBody(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.emoji_objects, color: _adviceColor, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.culturalTips,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryPink),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loadingCulturalTips,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null || _tips == null) {
      return _buildErrorView(theme);
    }

    final tips = _tips!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero image ──
          _buildHeroImage(theme, tips),
          const SizedBox(height: 16),

          // ── General advice ──
          if (tips.generalAdvice.isNotEmpty) ...[
            _GeneralAdviceCard(theme: theme, advice: tips.generalAdvice),
            const SizedBox(height: 20),
          ],

          // ── Do's ──
          if (tips.dos.isNotEmpty) ...[
            _SectionCard(
              theme: theme,
              title: AppLocalizations.of(context)!.culturalDos,
              icon: Icons.check_circle,
              color: _dosColor,
              items: tips.dos,
            ),
            const SizedBox(height: 16),
          ],

          // ── Don'ts ──
          if (tips.donts.isNotEmpty) ...[
            _SectionCard(
              theme: theme,
              title: AppLocalizations.of(context)!.culturalDonts,
              icon: Icons.cancel,
              color: _dontsColor,
              items: tips.donts,
            ),
            const SizedBox(height: 16),
          ],

          // ── Phrases ──
          if (tips.phrases.isNotEmpty) ...[
            _PhrasesCard(
              theme: theme,
              title: AppLocalizations.of(context)!.basicPhrases,
              phrases: tips.phrases,
            ),
            const SizedBox(height: 16),
          ],

          // ── Dining ──
          if (tips.diningEtiquette.isNotEmpty) ...[
            _SectionCard(
              theme: theme,
              title: AppLocalizations.of(context)!.diningEtiquette,
              icon: Icons.restaurant,
              color: _diningColor,
              items: tips.diningEtiquette,
            ),
            const SizedBox(height: 16),
          ],

          // ── Sacred sites ──
          if (tips.sacredSites.isNotEmpty) ...[
            _SectionCard(
              theme: theme,
              title: AppLocalizations.of(context)!.sacredSites,
              icon: Icons.mosque,
              color: _sacredColor,
              items: tips.sacredSites,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroImage(ThemeData theme, CulturalTips tips) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: double.infinity,
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (tips.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: tips.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    _gradientFallback(tips.destinationName),
              )
            else
              _gradientFallback(tips.destinationName),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.backgroundDark.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            // Destination name
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Text(
                tips.destinationName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientFallback(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPink.withValues(alpha: 0.4),
            AppTheme.secondaryOrange.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.public,
          size: 64,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.cannotLoadCulturalTips,
              style: const TextStyle(
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
                  onPressed: _loadTips,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context)!.retry),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section card for Do's, Don'ts, Dining, Sacred ──

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.theme,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final ThemeData theme;
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color.withValues(alpha: 0.7), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.4,
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

// ── Phrases card ──

class _PhrasesCard extends StatelessWidget {
  const _PhrasesCard({
    required this.theme,
    required this.title,
    required this.phrases,
  });

  final ThemeData theme;
  final String title;
  final List<CulturalPhrase> phrases;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.translate, color: _phrasesColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _phrasesColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...phrases.map((p) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.native,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.translation,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  if (p.pronunciation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '/${p.pronunciation}/',
                      style: TextStyle(
                        color: _phrasesColor.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── General advice card ──

class _GeneralAdviceCard extends StatelessWidget {
  const _GeneralAdviceCard({required this.theme, required this.advice});

  final ThemeData theme;
  final String advice;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: _adviceColor,
      borderColor: _adviceColor.withValues(alpha: 0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _adviceColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: _adviceColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              advice,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
