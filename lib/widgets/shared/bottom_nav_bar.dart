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
    final l10n = AppLocalizations.of(context)!;
    final activeIndex = currentIndex.clamp(0, 2);

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

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.94),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isActive = i == activeIndex;
            final color = isActive ? AppTheme.cyan : AppTheme.textMuted;

            return Expanded(
              child: Semantics(
                selected: isActive,
                button: true,
                child: InkWell(
                  onTap: () => onTap?.call(i),
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          key: isActive
                              ? const ValueKey('bottom_nav_active_indicator')
                              : null,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          width: 42,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: isActive
                                ? AppTheme.cyan.withValues(alpha: 0.16)
                                : Colors.transparent,
                            border: isActive
                                ? Border.all(
                                    color: AppTheme.cyan.withValues(
                                      alpha: 0.28,
                                    ),
                                  )
                                : null,
                          ),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: color,
                            size: 21,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: color,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
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
