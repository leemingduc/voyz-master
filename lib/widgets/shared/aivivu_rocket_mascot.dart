import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:voyz/theme/app_theme.dart';

/// Linh vật "Bé tên lửa thám hiểm AIVIVU" vẽ bằng vector sống động,
/// bay lượn bồng bềnh trong vũ trụ với vệt lửa và stardust phát sáng.
class AivivuRocketMascot extends StatefulWidget {
  const AivivuRocketMascot({super.key, this.size = 72.0});

  final double size;

  @override
  State<AivivuRocketMascot> createState() => _AivivuRocketMascotState();
}

class _AivivuRocketMascotState extends State<AivivuRocketMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
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
        final t = _controller.value;
        final bobbingY = math.sin(t * 2 * math.pi) * 5.0;
        final tiltAngle = math.sin(t * 2 * math.pi) * 0.04;
        final flameScale = 0.85 + 0.3 * math.sin(t * 4 * math.pi).abs();

        return Transform.translate(
          offset: Offset(0, bobbingY),
          child: Transform.rotate(
            angle: tiltAngle,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _AivivuRocketPainter(
                  progress: t,
                  flameScale: flameScale,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AivivuRocketPainter extends CustomPainter {
  _AivivuRocketPainter({required this.progress, required this.flameScale});

  final double progress;
  final double flameScale;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    canvas.save();
    // Tilted flying angle: 25 degrees
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 7);

    // 1. Vẽ ngọn lửa phản lực ở đuôi
    _drawFlame(canvas, flameScale);

    // 2. Vẽ cánh bên (fins)
    _drawFins(canvas);

    // 3. Vẽ thân tên lửa chibi
    _drawBody(canvas);

    // 4. Vẽ mũi tên lửa gradient
    _drawNoseCone(canvas);

    // 5. Vẽ kính chắn gió và mắt cười đáng yêu
    _drawVisorAndEyes(canvas);

    canvas.restore();

    // 6. Vẽ các hạt stardust lấp lánh xung quanh
    _drawStardust(canvas, size, progress);
  }

  void _drawFlame(Canvas canvas, double scale) {
    final flameHeight = 24.0 * scale;
    final flameWidth = 14.0 * scale;

    // Ngọn lửa ngoài (hồng/cam phát sáng)
    final outerFlamePath = Path()
      ..moveTo(-flameWidth / 2, 22)
      ..quadraticBezierTo(0, 22 + flameHeight, 0, 22 + flameHeight + 4)
      ..quadraticBezierTo(0, 22 + flameHeight, flameWidth / 2, 22)
      ..close();

    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryPink,
          const Color(0xFFFF9E00),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(-flameWidth, 22, flameWidth * 2, flameHeight + 6));

    canvas.drawPath(outerFlamePath, outerPaint);

    // Ngọn lửa trong (vàng/cyan sáng)
    final innerFlamePath = Path()
      ..moveTo(-flameWidth / 3, 22)
      ..quadraticBezierTo(0, 22 + flameHeight * 0.6, 0, 22 + flameHeight * 0.7)
      ..quadraticBezierTo(0, 22 + flameHeight * 0.6, flameWidth / 3, 22)
      ..close();

    final innerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, AppTheme.cyan],
      ).createShader(Rect.fromLTWH(-flameWidth, 22, flameWidth * 2, flameHeight * 0.7));

    canvas.drawPath(innerFlamePath, innerPaint);
  }

  void _drawFins(Canvas canvas) {
    final finPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.violet, AppTheme.primaryPink],
      ).createShader(const Rect.fromLTWH(-28, 6, 56, 20));

    // Cánh trái
    final leftFin = Path()
      ..moveTo(-12, 10)
      ..quadraticBezierTo(-24, 14, -26, 26)
      ..quadraticBezierTo(-18, 24, -10, 22)
      ..close();
    canvas.drawPath(leftFin, finPaint);

    // Cánh phải
    final rightFin = Path()
      ..moveTo(12, 10)
      ..quadraticBezierTo(24, 14, 26, 26)
      ..quadraticBezierTo(18, 24, 10, 22)
      ..close();
    canvas.drawPath(rightFin, finPaint);
  }

  void _drawBody(Canvas canvas) {
    // Thân tên lửa bầu bĩnh
    final bodyPath = Path()
      ..moveTo(-13, 22)
      ..quadraticBezierTo(-15, -4, 0, -22)
      ..quadraticBezierTo(15, -4, 13, 22)
      ..quadraticBezierTo(0, 24, -13, 22)
      ..close();

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
      ).createShader(const Rect.fromLTWH(-16, -24, 32, 48));

    // Đổ bóng thân nhẹ
    canvas.drawShadow(bodyPath, AppTheme.violet.withValues(alpha: 0.5), 6, true);
    canvas.drawPath(bodyPath, bodyPaint);

    // Đai kim loại ở đáy
    final nozzlePaint = Paint()..color = const Color(0xFF475569);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, 21, 18, 4),
        const Radius.circular(2),
      ),
      nozzlePaint,
    );
  }

  void _drawNoseCone(Canvas canvas) {
    final nosePath = Path()
      ..moveTo(-9, -12)
      ..quadraticBezierTo(-13, -15, 0, -26)
      ..quadraticBezierTo(13, -15, 9, -12)
      ..quadraticBezierTo(0, -9, -9, -12)
      ..close();

    final nosePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.primaryPink, AppTheme.violet],
      ).createShader(const Rect.fromLTWH(-14, -26, 28, 18));

    canvas.drawPath(nosePath, nosePaint);
  }

  void _drawVisorAndEyes(Canvas canvas) {
    // Vòm kính phi hành gia
    final visorRect = const Rect.fromLTWH(-9, -7, 18, 16);
    final visorPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: [
          const Color(0xFFE0F7FA),
          AppTheme.cyan,
          const Color(0xFF006064),
        ],
      ).createShader(visorRect);

    canvas.drawOval(visorRect, visorPaint);

    // Viền vòm kính
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(visorRect, rimPaint);

    // Cặp mắt cười vui tươi (hình cung cong)
    final eyePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;

    // Mắt trái
    final leftEye = Path()
      ..moveTo(-5.5, 0.5)
      ..quadraticBezierTo(-3.5, -2.5, -1.5, 0.5);
    canvas.drawPath(leftEye, eyePaint);

    // Mắt phải
    final rightEye = Path()
      ..moveTo(1.5, 0.5)
      ..quadraticBezierTo(3.5, -2.5, 5.5, 0.5);
    canvas.drawPath(rightEye, eyePaint);

    // Đốm sáng phản chiếu ở góc vòm kính
    final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(const Offset(-4, -4), 1.2, glintPaint);
  }

  void _drawStardust(Canvas canvas, Size size, double p) {
    // 3 ngôi sao nhỏ tỏa sáng xung quanh
    final starPaint = Paint()..color = AppTheme.cyan;

    final stars = [
      Offset(size.width * 0.2, size.height * 0.25),
      Offset(size.width * 0.82, size.height * 0.3),
      Offset(size.width * 0.28, size.height * 0.78),
    ];

    for (int i = 0; i < stars.length; i++) {
      final phase = (p + i * 0.33) % 1.0;
      final opacity = 0.3 + 0.7 * (1.0 - (2.0 * phase - 1.0).abs());
      final starSize = 2.5 + 1.5 * math.sin(phase * math.pi);

      starPaint.color = (i == 1 ? AppTheme.primaryPink : AppTheme.cyan)
          .withValues(alpha: opacity);

      _drawSparkle(canvas, stars[i], starSize, starPaint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AivivuRocketPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.flameScale != flameScale;
  }
}
