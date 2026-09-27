import 'package:flutter/material.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/aivivu_rocket_mascot.dart';

/// Loading indicator đặc trưng của app AIVIVU với Bé tên lửa thám hiểm.
class AivivuLoadingIndicator extends StatelessWidget {
  const AivivuLoadingIndicator({
    super.key,
    this.message,
    this.size = 80.0,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Hào quang tỏa sáng phía sau
              Container(
                width: size * 1.1,
                height: size * 1.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cyan.withValues(alpha: 0.18),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              AivivuRocketMascot(size: size),
            ],
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
