import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:voyz/models/chat_theme_model.dart';
import 'package:voyz/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Chat Theme Picker Screen
// ─────────────────────────────────────────────────────────────────────────────

class ChatThemeScreen extends StatefulWidget {
  const ChatThemeScreen({
    super.key,
    required this.currentThemeId,
    required this.onThemeSelected,
  });

  final String currentThemeId;
  final ValueChanged<ChatThemePreset> onThemeSelected;

  @override
  State<ChatThemeScreen> createState() => _ChatThemeScreenState();
}

class _ChatThemeScreenState extends State<ChatThemeScreen>
    with TickerProviderStateMixin {
  late String _selectedId;
  late AnimationController _previewAnim;
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentThemeId;
    _previewAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _previewAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  ChatThemePreset get _selectedTheme =>
      kChatThemes.firstWhere((t) => t.id == _selectedId);

  void _select(ChatThemePreset theme) {
    if (_selectedId == theme.id) return;
    setState(() => _selectedId = theme.id);
    _previewAnim.forward(from: 0);
  }

  void _apply() {
    widget.onThemeSelected(_selectedTheme);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Giao diện Chat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _apply,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _selectedTheme.accentColor,
                    _selectedTheme.accentColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Áp dụng',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Live preview pane ───────────────────────────────────────
          Expanded(
            flex: 5,
            child: FadeTransition(
              opacity: _previewAnim,
              child: _ChatPreviewPane(theme: _selectedTheme),
            ),
          ),

          // ── Theme grid picker ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.palette_outlined,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chọn giao diện',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: kChatThemes.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final theme = kChatThemes[index];
                      final isActive = theme.id == _selectedId;
                      return _ThemeTile(
                        theme: theme,
                        isActive: isActive,
                        pulseAnim: _pulseAnim,
                        onTap: () => _select(theme),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Preview Pane
// ─────────────────────────────────────────────────────────────────────────────

class _ChatPreviewPane extends StatelessWidget {
  const _ChatPreviewPane({required this.theme});

  final ChatThemePreset theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: theme.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Wallpaper pattern overlay
          _WallpaperOverlay(
            wallpaper: theme.wallpaper,
            color: theme.accentColor,
          ),

          // Chat bubbles preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Their message
                _PreviewBubble(
                  isMine: false,
                  text: 'Chào! Bạn đang ở đâu vậy? 😊',
                  time: '14:22',
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _PreviewBubble(
                  isMine: true,
                  text: 'Mình đang ở Đà Nẵng nè ✈️ Tuyệt lắm!',
                  time: '14:23',
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _PreviewBubble(
                  isMine: false,
                  text: 'Ôi hay quá! Mình muốn đến đó lắm 🌊',
                  time: '14:23',
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _PreviewBubble(
                  isMine: true,
                  text: 'Plan trip cùng nhau đi! ${theme.emoji}',
                  time: '14:24',
                  theme: theme,
                ),
                const SizedBox(height: 12),

                // Preview input dock
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.inputBarColor.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sentiment_satisfied_alt,
                        color: theme.accentColor.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nhắn tin...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: theme.myBubbleGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Theme label overlay at top
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${theme.emoji}  ${theme.name}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview Bubble
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewBubble extends StatelessWidget {
  const _PreviewBubble({
    required this.isMine,
    required this.text,
    required this.time,
    required this.theme,
  });

  final bool isMine;
  final String text;
  final String time;
  final ChatThemePreset theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMine
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMine) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.accentColor.withValues(alpha: 0.25),
            child: Icon(Icons.person, size: 18, color: theme.accentColor),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMine ? theme.myBubbleGradient : null,
              color: isMine ? null : theme.theirBubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
              border: isMine
                  ? null
                  : Border.all(
                      color: theme.accentColor.withValues(alpha: 0.15),
                    ),
              boxShadow: isMine
                  ? [
                      BoxShadow(
                        color: theme.accentColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: isMine
                        ? theme.myBubbleTextColor
                        : theme.theirBubbleTextColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color:
                            (isMine
                                    ? theme.myBubbleTextColor
                                    : theme.theirBubbleTextColor)
                                .withValues(alpha: 0.65),
                        fontSize: 10,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 3),
                      Icon(
                        Icons.done_all,
                        size: 12,
                        color: theme.myBubbleTextColor.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme Tile (grid item)
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.theme,
    required this.isActive,
    required this.pulseAnim,
    required this.onTap,
  });

  final ChatThemePreset theme;
  final bool isActive;
  final AnimationController pulseAnim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 78,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? theme.accentColor
                : Colors.white.withValues(alpha: 0.12),
            width: isActive ? 2.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: theme.accentColor.withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(gradient: theme.backgroundGradient),
                ),
              ),

              // Wallpaper pattern (mini)
              Positioned.fill(
                child: _WallpaperOverlay(
                  wallpaper: theme.wallpaper,
                  color: theme.accentColor,
                  mini: true,
                ),
              ),

              // Bubble color swatches
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Their bubble swatch
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.theirBubbleColor,
                        border: Border.all(
                          color: theme.accentColor.withValues(alpha: 0.2),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // My bubble swatch
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: theme.myBubbleGradient,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                          bottomLeft: Radius.circular(1),
                          bottomRight: Radius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Emoji + name label
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      theme.emoji,
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      theme.name,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              // Active check badge
              if (isActive)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: theme.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wallpaper Pattern Painter
// ─────────────────────────────────────────────────────────────────────────────

class _WallpaperOverlay extends StatelessWidget {
  const _WallpaperOverlay({
    required this.wallpaper,
    required this.color,
    this.mini = false,
  });

  final ChatWallpaper wallpaper;
  final Color color;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    if (wallpaper == ChatWallpaper.none) return const SizedBox.shrink();
    return Opacity(
      opacity: mini ? 0.12 : 0.06,
      child: CustomPaint(
        painter: _PatternPainter(wallpaper: wallpaper, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter({required this.wallpaper, required this.color});

  final ChatWallpaper wallpaper;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (wallpaper) {
      case ChatWallpaper.stars:
        _drawStars(canvas, size, paint);
      case ChatWallpaper.bubbles:
        _drawBubbles(canvas, size, paint);
      case ChatWallpaper.waves:
        _drawWaves(canvas, size, paint);
      case ChatWallpaper.grid:
        _drawGrid(canvas, size, paint);
      case ChatWallpaper.hearts:
        _drawHearts(canvas, size, paint);
      case ChatWallpaper.travel:
        _drawPlanes(canvas, size, paint);
      case ChatWallpaper.tread:
        _drawTread(canvas, size, paint);
      case ChatWallpaper.none:
        break;
    }
  }

  void _drawStars(Canvas canvas, Size size, Paint paint) {
    const rng = _SimpleRng(seed: 42);
    for (var i = 0; i < 60; i++) {
      final x = rng.next(i * 7) * size.width;
      final y = rng.next(i * 13) * size.height;
      final r = rng.next(i * 3) * 3 + 1;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _drawBubbles(Canvas canvas, Size size, Paint p) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const rng = _SimpleRng(seed: 17);
    for (var i = 0; i < 18; i++) {
      final x = rng.next(i * 11) * size.width;
      final y = rng.next(i * 7) * size.height;
      final r = rng.next(i * 5) * 20 + 8;
      canvas.drawCircle(Offset(x, y), r, stroke);
    }
  }

  void _drawWaves(Canvas canvas, Size size, Paint p) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var row = 0; row < 10; row++) {
      final path = Path();
      final y0 = size.height * row / 10;
      path.moveTo(0, y0);
      for (var x = 0; x <= size.width; x += 20) {
        path.lineTo(x.toDouble(), y0 + 6 * math.sin(x / 30.0 + row));
      }
      canvas.drawPath(path, stroke);
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint p) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    const step = 28.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), stroke);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), stroke);
    }
  }

  void _drawHearts(Canvas canvas, Size size, Paint paint) {
    const rng = _SimpleRng(seed: 99);
    for (var i = 0; i < 20; i++) {
      final x = rng.next(i * 9) * size.width;
      final y = rng.next(i * 4) * size.height;
      final s = rng.next(i * 2) * 8 + 5;
      _drawHeart(canvas, Offset(x, y), s, paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size * 1.2,
      center.dy - size * 0.6,
      center.dx - size * 2,
      center.dy + size * 0.6,
      center.dx,
      center.dy + size * 1.5,
    );
    path.cubicTo(
      center.dx + size * 2,
      center.dy + size * 0.6,
      center.dx + size * 1.2,
      center.dy - size * 0.6,
      center.dx,
      center.dy + size * 0.3,
    );
    canvas.drawPath(path, paint);
  }

  void _drawPlanes(Canvas canvas, Size size, Paint p) {
    const rng = _SimpleRng(seed: 55);
    for (var i = 0; i < 12; i++) {
      final x = rng.next(i * 13) * size.width;
      final y = rng.next(i * 8) * size.height;
      final s = rng.next(i) * 8 + 6;
      _drawPlane(canvas, Offset(x, y), s, p);
    }
  }

  void _drawTread(Canvas canvas, Size size, Paint p) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    const step = 42.0;
    for (var y = -step; y <= size.height + step; y += step) {
      for (var x = -step; x <= size.width + step; x += step) {
        final path = Path()
          ..moveTo(x, y + step * 0.2)
          ..lineTo(x + step * 0.5, y + step * 0.5)
          ..lineTo(x, y + step * 0.8);
        canvas.drawPath(path, stroke);
        final mirrored = Path()
          ..moveTo(x + step, y + step * 0.2)
          ..lineTo(x + step * 0.5, y + step * 0.5)
          ..lineTo(x + step, y + step * 0.8);
        canvas.drawPath(mirrored, stroke);
      }
    }
  }

  void _drawPlane(Canvas canvas, Offset c, double s, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy - s)
      ..lineTo(c.dx + s * 1.5, c.dy)
      ..lineTo(c.dx, c.dy + s * 0.5)
      ..lineTo(c.dx - s * 1.5, c.dy)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.wallpaper != wallpaper || old.color != color;
}

/// Tiny deterministic pseudo-RNG so patterns are stable.
class _SimpleRng {
  const _SimpleRng({required this.seed});
  final int seed;

  double next(int index) {
    final n = (seed ^ (index * 2654435761)) & 0xFFFFFFFF;
    return (n % 1000) / 1000.0;
  }
}
