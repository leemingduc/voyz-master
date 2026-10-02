import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/screens/ai_tools_screen.dart';
import 'package:voyz/services/supabase_service.dart';
import 'package:voyz/theme/app_theme.dart';

/// Controls whether the app-wide AI Tools shortcut is visible.
class AIToolsButtonVisibility {
  AIToolsButtonVisibility._();

  static final ValueNotifier<bool> isHidden = ValueNotifier(false);
}

/// A persistent shortcut to the AI tools hub, shown above app routes after login.
/// Hỗ trợ kéo di chuyển tự do đến mọi vị trí trên màn hình và giữ vị trí sau khi thả.
class AIToolsButton extends StatefulWidget {
  const AIToolsButton({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  /// Lưu vị trí đã kéo trên toàn ứng dụng để giữ nguyên khi chuyển màn hình.
  static Offset? savedPosition;

  @override
  State<AIToolsButton> createState() => _AIToolsButtonState();
}

class _AIToolsButtonState extends State<AIToolsButton> {
  static const double _buttonSize = 58.0;
  static const double _margin = 8.0;

  Offset? _offset;

  void _openAITools() {
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const AIToolsScreen()),
    );
  }

  Offset _effectivePosition(Size size, EdgeInsets padding) {
    if (_offset != null) return _offset!;
    if (AIToolsButton.savedPosition != null) {
      return _clampPosition(AIToolsButton.savedPosition!, size, padding);
    }
    final defaultX = size.width - padding.right - _buttonSize - 16.0;
    final defaultY = size.height - padding.bottom - 144.0 - _buttonSize;
    return _clampPosition(Offset(defaultX, defaultY), size, padding);
  }

  Offset _clampPosition(Offset pos, Size size, EdgeInsets padding) {
    final minX = padding.left + _margin;
    final maxX = (size.width - padding.right - _buttonSize - _margin).clamp(minX, double.infinity);
    final minY = padding.top + _margin;
    final maxY = (size.height - padding.bottom - _buttonSize - _margin).clamp(minY, double.infinity);

    return Offset(
      pos.dx.clamp(minX, maxX),
      pos.dy.clamp(minY, maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    Stream<AuthState>? authStream;
    try {
      authStream = SupabaseService.instance.auth.onAuthStateChange;
    } catch (_) {
      // Supabase chưa khởi tạo (ví dụ trong widget test)
    }

    if (authStream == null) {
      return _buildPositionedWrapper(context);
    }

    return StreamBuilder<AuthState>(
      stream: authStream,
      builder: (context, snapshot) {
        Session? session;
        try {
          session = SupabaseService.instance.auth.currentSession;
        } catch (_) {}
        if (session == null) {
          return const SizedBox.shrink();
        }

        return _buildPositionedWrapper(context);
      },
    );
  }

  Widget _buildPositionedWrapper(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final currentPos = _effectivePosition(size, padding);

    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openAITools,
      onPanUpdate: (details) {
        final nextPos = _clampPosition(
          Offset(currentPos.dx + details.delta.dx, currentPos.dy + details.delta.dy),
          size,
          padding,
        );
        setState(() {
          _offset = nextPos;
          AIToolsButton.savedPosition = nextPos;
        });
      },
      child: _buildButton(context),
    );

    final hasStack = context.findAncestorWidgetOfExactType<Stack>() != null;
    if (hasStack) {
      return Positioned(
        left: currentPos.dx,
        top: currentPos.dy,
        child: content,
      );
    }

    return content;
  }

  Widget _buildButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n?.aiToolsTitle ?? 'AI Tools',
      child: Container(
        width: _buttonSize,
        height: _buttonSize,
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.cyan.withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPink.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: 1.5,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
