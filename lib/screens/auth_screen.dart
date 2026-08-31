import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/data/mock_data.dart';
import 'package:voyz/services/supabase_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/utils/error_localizer.dart';
import 'package:voyz/widgets/shared/ai_tools_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AIToolsButtonVisibility.isHidden.value = true;
  }

  @override
  void dispose() {
    AIToolsButtonVisibility.isHidden.value = false;
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.length < 6) {
      _showMessage(l10n.emailPasswordRequired);
      return;
    }

    if (_isRegister) {
      final username = _usernameController.text.trim();
      if (username.isEmpty) {
        _showMessage(l10n.usernameRequired);
        return;
      }

      if (password != confirmPassword) {
        _showMessage(l10n.passwordMismatch);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final auth = SupabaseService.instance.auth;
      if (_isRegister) {
        await _register(auth, _usernameController.text.trim(), email, password);
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showMessage(ErrorLocalizer.getLocalizedMessage(error, l10n));
      }
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showMessage(ErrorLocalizer.getLocalizedMessage(error, l10n));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register(
    GoTrueClient auth,
    String username,
    String email,
    String password,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final response = await auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'display_name': username},
    );

    if (response.user == null) {
      throw AuthException(l10n.accountCreationFailed);
    }

    if (response.session == null) {
      if (!mounted) return;
      _showMessage(l10n.accountCreated);
      setState(() => _isRegister = false);
      return;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF475569),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [Color(0xFF1A1C2E), AppTheme.backgroundDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.brandGradient.createShader(bounds),
                      child: Text(
                        MockData.appName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegister ? l10n.createAccount : l10n.welcomeBack,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_isRegister) ...[
                      _AuthField(
                        controller: _usernameController,
                        label: l10n.username,
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _AuthField(
                      controller: _emailController,
                      label: l10n.email,
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _AuthField(
                      controller: _passwordController,
                      label: l10n.password,
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    if (_isRegister) ...[
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _confirmPasswordController,
                        label: l10n.confirmPassword,
                        icon: Icons.lock_reset,
                        obscureText: true,
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isRegister ? l10n.register : l10n.login),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _isRegister = !_isRegister),
                      child: Text(
                        _isRegister
                            ? l10n.haveAccountLogin
                            : l10n.needAccountRegister,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }
}
