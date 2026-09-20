import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/theme/app_theme.dart';

class TripChips extends StatelessWidget {
  final TripData trip;
  final ValueChanged<TripData> onTripChanged;

  const TripChips({
    super.key,
    required this.trip,
    required this.onTripChanged,
  });

  String _formatDates(DateTime? depart, DateTime? ret) {
    final formatter = DateFormat('dd/MM');
    if (depart != null && ret != null) {
      return '${formatter.format(depart)} - ${formatter.format(ret)}';
    } else if (depart != null) {
      return 'Từ ${formatter.format(depart)}';
    }
    return 'Thời gian linh hoạt';
  }

  String _getBudgetLabel(String tier, AppLocalizations l10n) {
    switch (tier.toLowerCase()) {
      case 'economy':
        return l10n.budgetTierEconomy;
      case 'moderate':
        return l10n.budgetTierModerate;
      case 'premium':
        return l10n.budgetTierPremium;
      case 'luxury':
        return l10n.budgetTierLuxury;
      default:
        return tier.isNotEmpty ? tier : l10n.budgetTierModerate;
    }
  }

  void _showDestinationSheet(BuildContext context) {
    final controller = TextEditingController(text: trip.destination);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Điểm đến',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nhập điểm đến...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onTripChanged(trip.copyWith(destination: controller.text.trim()));
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetSheet(BuildContext context, AppLocalizations l10n) {
    const tiers = ['economy', 'moderate', 'premium', 'luxury'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ngân sách',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tiers.map((tier) {
                final isSelected = trip.budget.toLowerCase() == tier;
                return ChoiceChip(
                  key: ValueKey('budget_option_$tier'),
                  label: Text(_getBudgetLabel(tier, l10n)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      Navigator.pop(ctx);
                      onTripChanged(trip.copyWith(budget: tier));
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipantsSheet(BuildContext context) {
    final currentCount = int.tryParse(trip.participants) ?? 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Số người tham gia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                    onPressed: currentCount > 1
                        ? () {
                            Navigator.pop(ctx);
                            onTripChanged(trip.copyWith(participants: '${currentCount - 1}'));
                          }
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$currentCount',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onTripChanged(trip.copyWith(participants: '${currentCount + 1}'));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      initialDateRange: trip.departDate != null && trip.returnDate != null
          ? DateTimeRange(start: trip.departDate!, end: trip.returnDate!)
          : null,
    );
    if (picked != null) {
      onTripChanged(trip.copyWith(
        departDate: picked.start,
        returnDate: picked.end,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasDest = trip.destination.isNotEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 8),
      child: Row(
        children: [
          // Destination Chip
          ActionChip(
            key: const ValueKey('trip_chip_destination'),
            avatar: const Icon(Icons.location_on_outlined, size: 16),
            label: Text(
              hasDest ? trip.destination : 'Điểm đến: AI gợi ý',
              style: TextStyle(
                color: hasDest ? Colors.white : Colors.white60,
                fontStyle: hasDest ? FontStyle.normal : FontStyle.italic,
              ),
            ),
            onPressed: () => _showDestinationSheet(context),
          ),
          const SizedBox(width: 8),

          // Date Chip
          ActionChip(
            key: const ValueKey('trip_chip_dates'),
            avatar: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(_formatDates(trip.departDate, trip.returnDate)),
            onPressed: () => _pickDateRange(context),
          ),
          const SizedBox(width: 8),

          // Budget Chip
          ActionChip(
            key: const ValueKey('trip_chip_budget'),
            avatar: const Icon(Icons.account_balance_wallet_outlined, size: 16),
            label: Text(_getBudgetLabel(trip.budget, l10n)),
            onPressed: () => _showBudgetSheet(context, l10n),
          ),
          const SizedBox(width: 8),

          // Participants Chip
          ActionChip(
            key: const ValueKey('trip_chip_participants'),
            avatar: const Icon(Icons.people_outline, size: 16),
            label: Text('${trip.participants.isNotEmpty ? trip.participants : "1"} người'),
            onPressed: () => _showParticipantsSheet(context),
          ),
        ],
      ),
    );
  }
}
