import 'package:flutter/material.dart';
import 'package:voyz/theme/app_theme.dart';

class AivivuWordmark extends StatelessWidget {
  const AivivuWordmark({super.key, this.fontSize = 26, this.alignment});

  final double fontSize;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      'AIVIVU',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        letterSpacing: 2.1,
        height: 1,
        shadows: [
          Shadow(color: AppTheme.cyan.withValues(alpha: 0.26), blurRadius: 9),
        ],
      ),
    );

    return Align(
      alignment: alignment ?? Alignment.centerLeft,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: AppTheme.brandGradient.createShader,
        child: text,
      ),
    );
  }
}
