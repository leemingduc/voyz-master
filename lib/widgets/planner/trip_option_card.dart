import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/models/plan_turn.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/currency_amount_text.dart';
import 'package:voyz/widgets/shared/destination_image.dart';

/// Thẻ phương án chuyến đi trong planner chat. Giữ kiểu thẻ gợi ý cũ,
/// thay sao/đánh giá bằng lộ trình và badge % bằng badge số ngày.
class TripOptionCard extends StatelessWidget {
  const TripOptionCard({super.key, required this.option, required this.onTap});

  final TripOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DestinationImage(
                    imageUrl: option.imageUrl,
                    destinationName: option.imageStop,
                    isLoading: option.imageUrl.isEmpty,
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        l10n.tripDays(option.numDays),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(option: option, theme: theme, l10n: l10n),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.route,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          option.stops.join(' → '),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (option.aiInsight.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InsightBox(text: option.aiInsight, l10n: l10n),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        l10n.viewDetails,
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
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
}

class _Header extends StatelessWidget {
  const _Header({
    required this.option,
    required this.theme,
    required this.l10n,
  });

  final TripOption option;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(fontSize: 10, color: Color(0xFF94A3B8));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option.destination,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        if (option.price.isNotEmpty) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CurrencyAmountText(
                option.price,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.tertiary,
                ),
                originalStyle: muted,
                textAlign: TextAlign.right,
              ),
              Text(l10n.perPerson, style: muted.copyWith(letterSpacing: 0.5)),
              Text(l10n.aiEstimateLabel, style: muted),
            ],
          ),
        ],
      ],
    );
  }
}

class _InsightBox extends StatelessWidget {
  const _InsightBox({required this.text, required this.l10n});

  final String text;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, height: 1.5),
          children: [
            TextSpan(
              text: l10n.aiInsightPrefix,
              style: TextStyle(fontWeight: FontWeight.w700, color: accent),
            ),
            TextSpan(
              text: text,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
