import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/theme/app_theme.dart';

/// Bottom navigation bar shared across Planner, Suggestions, Detail, and Plan
/// screens. Renders 3 items: AI Planner, Explore, Saved.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.currentIndex, this.onTap});

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final items = [
      _NavItem(
        icon: Icons.auto_awesome_outlined,
        activeIcon: Icons.auto_awesome,
        label: l10n.home,
      ),
      _NavItem(
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore,
        label: l10n.explore,
      ),
      _NavItem(
        icon: Icons.bookmark_outline,
        activeIcon: Icons.bookmark,
        label: l10n.savedTrips,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 28, left: 8, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isActive = i == currentIndex;
          final color = isActive
              ? theme.colorScheme.primary
              : const Color(0xFF64748B);

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap?.call(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: color,
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
