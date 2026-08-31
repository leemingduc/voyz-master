import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/data/mock_data.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/screens/destination_detail_screen.dart';
import 'package:voyz/screens/smart_planner_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
import 'package:voyz/widgets/shared/currency_amount_text.dart';

/// Saved & Wishlist screen — displays saved trips and wishlist items.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
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
        // Already on Saved
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = SavedTripsProvider.of(context);
    final allItems = provider.savedItems;
    final workspaceCount = provider.tripWorkspaces.length;
    final wishlistCount = provider.wishlistItems.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0A16), Color(0xFF1A1528)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              _Header(
                workspaceCount: workspaceCount,
                wishlistCount: wishlistCount,
              ),

              // ── Content ──
              Expanded(
                child: _ItemListView(
                  items: allItems,
                  onRemoved: () => setState(() {}),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: BottomNavBar(currentIndex: 2, onTap: _onNavTap),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.workspaceCount, required this.wishlistCount});

  final int workspaceCount;
  final int wishlistCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48), // balance placeholder
          Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.brandGradient.createShader(bounds),
                child: Text(
                  MockData.appName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Trip Workspace',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$workspaceCount workspaces / $wishlistCount wishlist',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(width: 48), // balance placeholder
        ],
      ),
    );
  }
}

// ── Item List View ──────────────────────────────────────────────────────

class _ItemListView extends StatelessWidget {
  const _ItemListView({required this.items, this.onRemoved});
  final List<SavedItem> items;
  final VoidCallback? onRemoved;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DestinationDetailScreen(destinationName: items[index].name),
              ),
            );
          },
          child: _SavedItemCard(item: items[index], onRemoved: onRemoved),
        );
      },
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 40,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.noSavedYet,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.emptySavedHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Saved Item Card ─────────────────────────────────────────────────────

class _SavedItemCard extends StatelessWidget {
  const _SavedItemCard({required this.item, this.onRemoved});
  final SavedItem item;
  final VoidCallback? onRemoved;

  Future<void> _showAddDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required ValueChanged<String> onSubmit,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFullTrip = item.tripData != null;

    return Container(
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
            aspectRatio: 16 / 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, e, s) => Container(
                    color: const Color(0xFF1E293B),
                    child: const Icon(
                      Icons.image,
                      color: Colors.white24,
                      size: 48,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: isFullTrip ? AppTheme.brandGradient : null,
                      color: isFullTrip
                          ? null
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFullTrip
                              ? Icons.dashboard_customize
                              : Icons.favorite,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isFullTrip
                              ? 'Workspace'
                              : AppLocalizations.of(context)!.wishlist,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.matchPercent}% ${AppLocalizations.of(context)!.match}',
                      style: const TextStyle(
                        fontSize: 11,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    CurrencyAmountText(
                      item.price,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.tertiary,
                      ),
                      originalStyle: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _TrustRow(item: item),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.aiInsight,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFullTrip) ...[
                  const SizedBox(height: 14),
                  _WorkspacePanel(item: item, showAddDialog: _showAddDialog),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      SavedTripsProvider.of(context).removeSavedItem(item);
                      onRemoved?.call();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.savedItemRemoved,
                          ),
                          backgroundColor: const Color(0xFF475569),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.remove,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
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

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.item});

  final SavedItem item;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const _MiniBadge(icon: Icons.psychology, label: 'AI match'),
        const _MiniBadge(icon: Icons.payments, label: 'Cost estimate'),
        if (item.rating > 0)
          _MiniBadge(
            icon: Icons.star,
            label: '${item.rating.toStringAsFixed(1)} reference',
          ),
      ],
    );
  }
}

class _WorkspacePanel extends StatelessWidget {
  const _WorkspacePanel({required this.item, required this.showAddDialog});

  final SavedItem item;
  final Future<void> Function(
    BuildContext context, {
    required String title,
    required String hint,
    required ValueChanged<String> onSubmit,
  })
  showAddDialog;

  @override
  Widget build(BuildContext context) {
    final provider = SavedTripsProvider.of(context);
    final doneCount = item.checklist.where((entry) => entry.isDone).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.dashboard_customize,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Trip Workspace',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '$doneCount/${item.checklist.length} ready',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WorkspaceStatRow(item: item),
          const SizedBox(height: 12),
          ...List.generate(item.checklist.length, (index) {
            final entry = item.checklist[index];
            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              value: entry.isDone,
              onChanged: (_) => provider.toggleChecklistItem(item, index),
              title: Text(
                entry.text,
                style: TextStyle(
                  color: entry.isDone
                      ? Colors.white.withValues(alpha: 0.38)
                      : Colors.white.withValues(alpha: 0.78),
                  decoration: entry.isDone ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white38,
                  fontSize: 12,
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.workspaceNotes,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Notes',
              labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            onChanged: (value) => provider.updateWorkspaceNotes(item, value),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChipButton(
                icon: Icons.confirmation_number,
                label: 'Add booking',
                onTap: () => showAddDialog(
                  context,
                  title: 'Add booking',
                  hint: 'Flight, hotel, tour code...',
                  onSubmit: (value) => provider.addBookingRef(item, value),
                ),
              ),
              _ActionChipButton(
                icon: Icons.group_add,
                label: 'Share with',
                onTap: () => showAddDialog(
                  context,
                  title: 'Share with',
                  hint: 'Name or email',
                  onSubmit: (value) => provider.addSharedPerson(item, value),
                ),
              ),
            ],
          ),
          if (item.bookingRefs.isNotEmpty || item.sharedWith.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...item.bookingRefs.map(
                  (ref) =>
                      _MiniBadge(icon: Icons.confirmation_number, label: ref),
                ),
                ...item.sharedWith.map(
                  (person) => _MiniBadge(icon: Icons.person, label: person),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkspaceStatRow extends StatelessWidget {
  const _WorkspaceStatRow({required this.item});

  final SavedItem item;

  @override
  Widget build(BuildContext context) {
    final trip = item.tripData;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const _MiniBadge(icon: Icons.favorite, label: 'Wishlist'),
        _MiniBadge(
          icon: Icons.calendar_today,
          label: trip?.departDate == null
              ? 'Flexible dates'
              : 'Itinerary ready',
        ),
        _MiniBadge(
          icon: Icons.payments,
          label: item.price.isEmpty ? 'Budget TBD' : item.price,
          moneyValue: item.price.isEmpty ? null : item.price,
        ),
        _MiniBadge(
          icon: Icons.note_alt,
          label: item.workspaceNotes.isEmpty ? 'No notes' : 'Notes saved',
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.label, this.moneyValue});

  final IconData icon;
  final String label;
  final String? moneyValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: Colors.transparent, size: 0),
          Icon(icon, color: const Color(0xFF94A3B8), size: 13),
          const SizedBox(width: 5),
          if (moneyValue == null)
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            CurrencyAmountText(
              moneyValue!,
              showOriginal: false,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.primaryPink.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryPink.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryPink, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryPink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
