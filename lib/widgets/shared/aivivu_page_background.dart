import 'package:flutter/material.dart';
import 'package:voyz/theme/app_theme.dart';

class AivivuPageBackground extends StatelessWidget {
  const AivivuPageBackground({
    super.key,
    required this.child,
    this.padding = true,
    this.constrainContent = true,
  });

  final Widget child;
  final bool padding;
  final bool constrainContent;

  @override
  Widget build(BuildContext context) {
    final content = constrainContent
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: child,
          )
        : child;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.72, -0.88),
              radius: 1.4,
              colors: [Color(0xFF102034), AppTheme.backgroundDark],
            ),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            key: const ValueKey('cosmic_star_field'),
            painter: _CosmicStarFieldPainter(),
          ),
        ),
        Center(
          child: padding
              ? Padding(padding: AppTheme.pagePadding(context), child: content)
              : content,
        ),
      ],
    );
  }
}

class _CosmicStarFieldPainter extends CustomPainter {
  const _CosmicStarFieldPainter();

  static const _stars = <Offset>[
    Offset(0.06, 0.12),
    Offset(0.18, 0.27),
    Offset(0.31, 0.08),
    Offset(0.47, 0.18),
    Offset(0.59, 0.05),
    Offset(0.73, 0.23),
    Offset(0.88, 0.14),
    Offset(0.11, 0.54),
    Offset(0.25, 0.69),
    Offset(0.41, 0.49),
    Offset(0.56, 0.77),
    Offset(0.72, 0.61),
    Offset(0.91, 0.83),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.28);
    for (var index = 0; index < _stars.length; index++) {
      final star = _stars[index];
      paint.color = Colors.white.withValues(alpha: index.isEven ? 0.34 : 0.18);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        index.isEven ? 1.25 : 0.8,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicStarFieldPainter oldDelegate) => false;
}
