import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voyz/data/mock_data.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/theme/app_theme.dart';

/// Hàng chip cho thấy AI đã hiểu gì từ mô tả chuyến đi. Chip rỗng hiện mờ.
/// Chạm vào chip để sửa đúng một giá trị.
class TripChips extends StatelessWidget {
  const TripChips({super.key, required this.trip, required this.onChanged});

  final TripData trip;
  final ValueChanged<TripData> onChanged;

  static String interestLabel(String key, AppLocalizations l10n) {
    switch (key) {
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
        return key;
    }
  }

  static String tierLabel(String tier, AppLocalizations l10n) {
    switch (tier) {
      case 'economy':
        return l10n.budgetTierEconomy;
      case 'moderate':
        return l10n.budgetTierModerate;
      case 'premium':
        return l10n.budgetTierPremium;
      case 'luxury':
        return l10n.budgetTierLuxury;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM');
    final dates = trip.departDate == null
        ? ''
        : trip.returnDate == null
        ? dateFormat.format(trip.departDate!)
        : '${dateFormat.format(trip.departDate!)} - '
              '${dateFormat.format(trip.returnDate!)}';
    final interests = trip.selectedInterests
        .map((key) => interestLabel(key, l10n))
        .join(', ');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TripChip(
          icon: Icons.place_outlined,
          title: l10n.destination,
          value: trip.destination,
          emptyValue: l10n.chipAiWillSuggest,
          onTap: () async {
            final value = await _editText(
              context,
              l10n.destination,
              trip.destination,
            );
            if (value != null) onChanged(trip.copyWith(destination: value));
          },
        ),
        _TripChip(
          icon: Icons.calendar_today_outlined,
          title: l10n.dates,
          value: dates,
          emptyValue: l10n.chipFlexible,
          onTap: () async {
            final now = DateTime.now();
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(now.year, now.month, now.day),
              lastDate: now.add(const Duration(days: 730)),
              initialDateRange: trip.departDate != null
                  ? DateTimeRange(
                      start: trip.departDate!,
                      end: trip.returnDate ?? trip.departDate!,
                    )
                  : null,
            );
            if (range != null) {
              onChanged(
                trip.copyWith(departDate: range.start, returnDate: range.end),
              );
            }
          },
        ),
        _TripChip(
          icon: Icons.group_outlined,
          title: l10n.participants,
          value: trip.participants,
          emptyValue: l10n.chipNotSet,
          onTap: () async {
            final value = await _editText(
              context,
              l10n.participants,
              trip.participants,
              number: true,
            );
            if (value != null) onChanged(trip.copyWith(participants: value));
          },
        ),
        _TripChip(
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.budgetTier,
          value: tierLabel(trip.budget, l10n),
          emptyValue: l10n.chipNotSet,
          onTap: () async {
            final tier = await _pickTier(context, trip.budget);
            if (tier != null) onChanged(trip.copyWith(budget: tier));
          },
        ),
        _TripChip(
          icon: Icons.favorite_border,
          title: l10n.interests,
          value: interests,
          emptyValue: l10n.chipNotSet,
          onTap: () async {
            final picked = await _pickInterests(
              context,
              trip.selectedInterests,
            );
            if (picked != null) {
              onChanged(trip.copyWith(selectedInterests: picked));
            }
          },
        ),
      ],
    );
  }

  Future<String?> _editText(
    BuildContext context,
    String title,
    String initial, {
    bool number = false,
  }) {
    final controller = TextEditingController(text: initial);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: number ? TextInputType.number : TextInputType.text,
              onSubmitted: (value) => Navigator.pop(context, value.trim()),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickTier(BuildContext context, String current) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final tier in const [
              'economy',
              'moderate',
              'premium',
              'luxury',
            ])
              ListTile(
                title: Text(tierLabel(tier, l10n)),
                trailing: tier == current
                    ? const Icon(Icons.check, color: AppTheme.cyan)
                    : null,
                onTap: () => Navigator.pop(context, tier),
              ),
          ],
        ),
      ),
    );
  }

  Future<List<String>?> _pickInterests(
    BuildContext context,
    List<String> current,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final selected = current.toSet();
    return showModalBottomSheet<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final key in MockData.interests)
                    FilterChip(
                      label: Text(interestLabel(key, l10n)),
                      selected: selected.contains(key),
                      onSelected: (on) => setSheetState(
                        () => on ? selected.add(key) : selected.remove(key),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  MockData.interests.where(selected.contains).toList(),
                ),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripChip extends StatelessWidget {
  const _TripChip({
    required this.icon,
    required this.title,
    required this.value,
    required this.emptyValue,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String emptyValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.isEmpty;
    final color = isEmpty ? Colors.white.withValues(alpha: 0.45) : Colors.white;

    return ActionChip(
      avatar: Icon(icon, size: 16, color: isEmpty ? color : AppTheme.cyan),
      label: Text(
        '$title: ${isEmpty ? emptyValue : value}',
        style: TextStyle(
          color: color,
          fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      side: BorderSide(
        color: isEmpty
            ? Colors.white.withValues(alpha: 0.12)
            : AppTheme.cyan.withValues(alpha: 0.45),
      ),
      onPressed: onTap,
    );
  }
}
