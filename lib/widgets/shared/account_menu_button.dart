import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/screens/auth_gate.dart';
import 'package:voyz/screens/friends_screen.dart';
import 'package:voyz/screens/profile_screen.dart';
import 'package:voyz/services/supabase_service.dart';

class AccountMenuButton extends StatefulWidget {
  const AccountMenuButton({super.key});

  @override
  State<AccountMenuButton> createState() => _AccountMenuButtonState();
}

class _AccountMenuButtonState extends State<AccountMenuButton> {
  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text('${l10n.signOut}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    await SupabaseService.instance.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate(showSplash: false)),
      (route) => false,
    );
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    if (mounted) setState(() {});
  }

  Future<void> _openFriends(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FriendsScreen()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = SupabaseService.instance.auth.currentUser;
    final email = user?.email ?? l10n.signIn;
    final avatarUrl = user?.userMetadata?['avatar_url']?.toString();

    return PopupMenuButton<String>(
      tooltip: email,
      onSelected: (value) {
        if (value == 'profile') _openProfile(context);
        if (value == 'friends') _openFriends(context);
        if (value == 'logout') _confirmLogout(context);
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.manage_accounts_outlined, size: 18),
              const SizedBox(width: 8),
              Text(l10n.profile),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'friends',
          child: Row(
            children: [
              Icon(Icons.people_alt_outlined, size: 18),
              SizedBox(width: 8),
              Text('Friends'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18),
              const SizedBox(width: 8),
              Text(l10n.signOut),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.25),
            backgroundImage: avatarUrl == null || avatarUrl.isEmpty
                ? null
                : NetworkImage(avatarUrl),
            child: avatarUrl == null || avatarUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
        ],
      ),
    );
  }
}