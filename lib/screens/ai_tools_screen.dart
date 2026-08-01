import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/screens/chat_screen.dart';
import 'package:voyz/screens/compare_screen.dart';
import 'package:voyz/screens/best_time_screen.dart';
import 'package:voyz/screens/smart_planner_screen.dart';
import 'package:voyz/screens/explore_screen.dart';
import 'package:voyz/screens/saved_screen.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
import 'package:voyz/widgets/shared/glass_card.dart';

/// AI Tools hub screen — access all AI-powered features.
class AIToolsScreen extends StatelessWidget {
  const AIToolsScreen({super.key});

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SmartPlannerScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ExploreScreen()),
          (route) => false,
        );
        break;
      case 2:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SavedScreen()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.aiToolsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            GlassCard(
              glowColor: AppTheme.primaryPink,
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppTheme.primaryPink,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.aiToolsTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.aiToolsSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // AI Chatbot
            _AIToolCard(
              icon: Icons.chat,
              gradient: [AppTheme.primaryPink, AppTheme.secondaryOrange],
              title: AppLocalizations.of(context)!.aiChatbotTitle,
              subtitle: AppLocalizations.of(context)!.aiChatbotSubtitle,
              description: AppLocalizations.of(context)!.aiChatbotDesc,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              ),
            ),

            const SizedBox(height: 16),

            // Compare Destinations
            _AIToolCard(
              icon: Icons.compare_arrows,
              gradient: [AppTheme.accentBlue, Colors.purple],
              title: AppLocalizations.of(context)!.aiCompareTitle,
              subtitle: AppLocalizations.of(context)!.aiCompareSubtitle,
              description: AppLocalizations.of(context)!.aiCompareDesc,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompareScreen()),
              ),
            ),

            const SizedBox(height: 16),

            // Best Time to Travel
            _AIToolCard(
              icon: Icons.calendar_today,
              gradient: [Colors.green, Colors.teal],
              title: AppLocalizations.of(context)!.aiBestTimeTitle,
              subtitle: AppLocalizations.of(context)!.aiBestTimeSubtitle,
              description: AppLocalizations.of(context)!.aiBestTimeDesc,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BestTimeScreen()),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }
}

class _AIToolCard extends StatelessWidget {
  const _AIToolCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.primaryPink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
