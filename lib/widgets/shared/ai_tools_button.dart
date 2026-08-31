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
    return StreamBuilder<AuthState>(
      stream: SupabaseService.instance.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = SupabaseService.instance.auth.currentSession;
        if (session == null) {
          return const SizedBox.shrink();
        }

        final l10n = AppLocalizations.of(context);

        return Semantics(
          button: true,
          label: l10n?.aiToolsTitle ?? 'AI Tools',
          child: FloatingActionButton.extended(
            heroTag: 'global-ai-tools-button',
            onPressed: _openAITools,
            backgroundColor: AppTheme.primaryPink,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(
              l10n?.aiToolsTitle ?? 'AI Tools',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

