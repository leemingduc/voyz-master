import 'package:flutter/material.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/aivivu_wordmark.dart';

class AivivuHeader extends StatelessWidget implements PreferredSizeWidget {
  const AivivuHeader({
    super.key,
    this.leading,
    this.actions = const [],
    this.bottom,
  });

  final Widget? leading;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading,
      titleSpacing: leading == null ? 20 : 4,
      title: const AivivuWordmark(fontSize: 21),
      actions: actions,
      bottom: bottom,
      backgroundColor: AppTheme.surfaceDark.withValues(alpha: 0.76),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(
        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    );
  }
}
