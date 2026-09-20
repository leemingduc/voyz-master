import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:voyz/theme/app_theme.dart';

/// Ảnh điểm đến dùng chung cho mọi màn hình.
///
/// Ba trạng thái, một kiểu nhìn:
/// - `imageUrl` rỗng: vẽ fallback ngay, không tạo request mạng.
/// - Đang tải: nền gradient tối, không spinner.
/// - Lỗi tải: cùng gradient, thêm icon núi và tên điểm đến mờ.
///
/// Widget chỉ lo phần ảnh. Overlay, badge, tiêu đề vẫn nằm trong Stack
/// của màn hình gọi.
class DestinationImage extends StatelessWidget {
  const DestinationImage({
    super.key,
    required this.imageUrl,
    required this.destinationName,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final String destinationName;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final Widget image = imageUrl.isEmpty
        ? _Fallback(name: destinationName)
        : CachedNetworkImage(
            imageUrl: imageUrl,
            fit: fit,
            // name null: đang tải, chỉ nền gradient, không icon, không chữ.
            placeholder: (_, _) => const _Fallback(name: null),
            errorWidget: (_, _, _) => _Fallback(name: destinationName),
          );
    return image;
  }
}

/// Nền gradient tối. `name == null` là trạng thái đang tải (không icon, không chữ).
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
