import 'package:flutter/material.dart';
import 'package:voyz/theme/app_theme.dart';

class AivivuPageBackground extends StatelessWidget {
  const AivivuPageBackground({
    super.key,
    required this.child,
    this.padding = true,
  });

  final Widget child;
  final bool padding;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1180),
      child: child,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.75, -0.9),
          radius: 1.25,
          colors: [Color(0xFF101C28), AppTheme.backgroundDark],
        ),
      ),
      child: Center(
        child: padding
            ? Padding(padding: AppTheme.pagePadding(context), child: content)
            : content,
      ),
    );
  }
}
