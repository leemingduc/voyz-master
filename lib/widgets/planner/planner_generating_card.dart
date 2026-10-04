import 'dart:async';
import 'package:flutter/material.dart';
import 'package:voyz/theme/app_theme.dart';

/// Thẻ hiệu ứng chờ AI tạo gợi ý chuyến đi với thông điệp luân phiên sinh động.
class PlannerGeneratingCard extends StatefulWidget {
  const PlannerGeneratingCard({super.key});

  @override
  State<PlannerGeneratingCard> createState() => _PlannerGeneratingCardState();
}

class _PlannerGeneratingCardState extends State<PlannerGeneratingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  Timer? _messageTimer;
  int _currentMessageIndex = 0;

  static const List<String> _messages = [
    'Đang phân tích sở thích và mong muốn của bạn...',
    'Khám phá và chọn lọc các điểm đến phù hợp nhất...',
    'Tính toán lộ trình tối ưu và dự toán ngân sách...',
    'Đang hoàn tất các phương án du lịch tuyệt vời...',
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _messageTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: AppTheme.cyan.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cyan.withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'AIVIVU AI PLANNER',
                  style: TextStyle(
                    color: AppTheme.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 24,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _messages[_currentMessageIndex],
                  key: ValueKey<int>(_currentMessageIndex),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Thanh shimmer line
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 4,
                width: double.infinity,
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    final progress = _shimmerController.value;
                    final slide = -1.5 + progress * 3.0;

                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(slide - 0.5, 0),
                          end: Alignment(slide + 0.5, 0),
                          colors: [
                            Colors.white.withValues(alpha: 0.05),
                            AppTheme.cyan,
                            AppTheme.primaryPink,
                            Colors.white.withValues(alpha: 0.05),
                          ],
                          stops: const [0.0, 0.45, 0.55, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
