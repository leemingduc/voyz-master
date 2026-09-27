import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:voyz/theme/app_theme.dart';

/// Ảnh điểm đến dùng chung cho mọi màn hình.
///
/// Các trạng thái:
/// - `isLoading` hoặc đang tải: vệt sáng skeleton shimmer chuyển động mượt mà kèm biểu tượng tên lửa AIVIVU.
/// - Tải xong: hiển thị ảnh với hiệu ứng fade-in 400ms mềm mại.
/// - Lỗi tải / rỗng: nền gradient tối, thêm icon núi và tên điểm đến mờ.
class DestinationImage extends StatelessWidget {
  const DestinationImage({
    super.key,
    required this.imageUrl,
    required this.destinationName,
    this.fit = BoxFit.cover,
    this.isLoading = false,
  });

  final String imageUrl;
  final String destinationName;
  final BoxFit fit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ShimmerLoadingBox();
    }

    if (imageUrl.isEmpty) {
      return _Fallback(name: destinationName);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 400),
      fadeInCurve: Curves.easeIn,
      placeholder: (_, _) => const ShimmerLoadingBox(),
      errorWidget: (_, _, _) => _Fallback(name: destinationName),
    );
  }
}

/// Khung shimmer skeleton quét sáng với dấu ấn tên lửa AIVIVU độc đáo.
class ShimmerLoadingBox extends StatefulWidget {
  const ShimmerLoadingBox({super.key});

  @override
  State<ShimmerLoadingBox> createState() => _ShimmerLoadingBoxState();
}

class _ShimmerLoadingBoxState extends State<ShimmerLoadingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final slide = -2.0 + progress * 4.0;
        final pulse = 0.85 + 0.15 * math.sin(progress * 2 * math.pi).abs();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(slide - 1.0, -0.5),
              end: Alignment(slide + 1.0, 0.5),
              colors: [
                AppTheme.surfaceDark,
                AppTheme.surfaceDark.withValues(alpha: 0.85),
                Colors.white.withValues(alpha: 0.08),
                AppTheme.surfaceDark.withValues(alpha: 0.85),
                AppTheme.surfaceDark,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.cyan.withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.cyan.withValues(alpha: 0.15),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: ShaderMask(
                      shaderCallback: AppTheme.brandGradient.createShader,
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Nền gradient tối. `name == null` là trạng thái không chữ.
class _Fallback extends StatelessWidget {
  const _Fallback({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final label = name;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceDark, AppTheme.backgroundDark],
        ),
      ),
      child: label == null
          ? null
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.landscape,
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  if (label.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
