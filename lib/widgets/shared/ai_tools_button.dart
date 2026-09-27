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
/// Thiết kế icon tròn đặc trưng AIVIVU, không có chữ, gọn gàng.
class AIToolsButton extends StatelessWidget {
  const AIToolsButton({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  void _openAITools() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const AIToolsScreen()),
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
      return _buildButton(context);
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

        return _buildButton(context);
      },
    );
  }

  Widget _buildButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n?.aiToolsTitle ?? 'AI Tools',
      child: Tooltip(
        message: l10n?.aiToolsTitle ?? 'AI Tools',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openAITools,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: 50,
              height: 50,
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
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
