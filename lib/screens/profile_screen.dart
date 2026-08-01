import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/services/avatar_image_picker.dart';
import 'package:voyz/services/profile_service.dart';
import 'package:voyz/data/mock_data.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/glass_card.dart';
import 'package:voyz/widgets/shared/gradient_button.dart';
import 'package:voyz/utils/error_localizer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  late UserProfile _profile;
  PickedAvatarImage? _pickedImage;
  double _zoom = 1;
  double _offsetX = 0;
  double _offsetY = 0;
  bool _isSavingAvatar = false;
  bool _isChangingPassword = false;
  bool _isSavingContactInfo = false;

  @override
  void initState() {
    super.initState();
    _profile = ProfileService.instance.currentProfile();
    _phoneController.text = _profile.phoneNumber;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await pickAvatarImage();
      if (image == null || !mounted) return;
      setState(() {
        _pickedImage = image;
        _zoom = 1;
        _offsetX = 0;
        _offsetY = 0;
      });
    } on UnsupportedError {
      if (mounted)
        _showMessage(
          AppLocalizations.of(context)!.avatarUploadWebOnly,
          isError: true,
        );
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _saveAvatar() async {
    final image = _pickedImage;
    if (image == null) return;

    setState(() => _isSavingAvatar = true);
    try {
      final cropped = await cropAvatarImage(
        bytes: image.bytes,
        mimeType: image.mimeType,
        zoom: _zoom,
        offsetX: _offsetX,
        offsetY: _offsetY,
      );
      final avatarUrl = await ProfileService.instance.saveAvatar(cropped);
      if (!mounted) return;
      setState(() {
        _profile = UserProfile(
          email: _profile.email,
          displayName: _profile.displayName,
          avatarUrl: avatarUrl,
          phoneNumber: _profile.phoneNumber,
        );
        _pickedImage = null;
      });
      _showMessage(AppLocalizations.of(context)!.avatarSaved);
    } on UnsupportedError {
      if (mounted)
        _showMessage(
          AppLocalizations.of(context)!.avatarEditingWebOnly,
          isError: true,
        );
    } on AuthException catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showMessage(
          ErrorLocalizer.getLocalizedMessage(error, l10n),
          isError: true,
        );
      }
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showMessage(
          ErrorLocalizer.getLocalizedMessage(error, l10n),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAvatar = false);
    }
  }

  String? _phoneValidationMessage(String phoneNumber) {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) return null;

    final l10n = AppLocalizations.of(context)!;
    final allowedCharacters = RegExp(r'^[0-9+\-() ]+$');
    if (!allowedCharacters.hasMatch(trimmed)) {
      return l10n.phoneInvalidChars;
    }

    final digitCount = RegExp(r'\d').allMatches(trimmed).length;
    if (digitCount < 8) {
      return l10n.phoneMinDigits;
    }

    return null;
  }

  Future<void> _saveContactInfo() async {
    final phoneNumber = _phoneController.text.trim();
    final validationMessage = _phoneValidationMessage(phoneNumber);
    if (validationMessage != null) {
      _showMessage(validationMessage, isError: true);
      return;
    }

    setState(() => _isSavingContactInfo = true);
    try {
      final savedPhoneNumber = await ProfileService.instance.updateContactInfo(
        phoneNumber: phoneNumber,
      );
      if (!mounted) return;
      setState(() {
        _profile = UserProfile(
          email: _profile.email,
          displayName: _profile.displayName,
          avatarUrl: _profile.avatarUrl,
          phoneNumber: savedPhoneNumber,
        );
        _phoneController.text = savedPhoneNumber;
      });
      _showMessage(AppLocalizations.of(context)!.contactInfoSaved);
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSavingContactInfo = false);
    }
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context)!;
    final password = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 6) {
      _showMessage(l10n.passwordMinLength, isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showMessage(l10n.passwordMismatch, isError: true);
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      await ProfileService.instance.updatePassword(password);
      if (!mounted) return;
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showMessage(AppLocalizations.of(context)!.passwordUpdated);
    } on AuthException catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showMessage(
          ErrorLocalizer.getLocalizedMessage(error, l10n),
          isError: true,
        );
      }
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showMessage(
          ErrorLocalizer.getLocalizedMessage(error, l10n),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : const Color(0xFF475569),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.4,
            colors: [Color(0xFF1A1C2E), AppTheme.backgroundDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(theme: theme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAccountCard(theme),
                          const SizedBox(height: 16),
                          _buildLanguageCard(theme),
                          const SizedBox(height: 16),
                          _buildPasswordCard(theme),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.userProfile,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.profileSubtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 620;
              final avatar = _buildAvatarEditor(theme);
              final details = _buildProfileDetails(theme);

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [avatar, const SizedBox(height: 20), details],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 260, child: avatar),
                  const SizedBox(width: 24),
                  Expanded(child: details),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarEditor(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final canSave = _pickedImage != null && !_isSavingAvatar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.center,
          child: _AvatarPreview(
            pickedBytes: _pickedImage?.bytes,
            avatarUrl: _profile.avatarUrl,
            zoom: _zoom,
            offsetX: _offsetX,
            offsetY: _offsetY,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _isSavingAvatar ? null : _pickImage,
          icon: const Icon(Icons.upload_file, size: 18),
          label: Text(l10n.uploadPhoto),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        ),
        if (_pickedImage != null) ...[
          const SizedBox(height: 14),
          _SliderRow(
            label: l10n.zoom,
            value: _zoom,
            min: 1,
            max: 3,
            onChanged: (value) => setState(() => _zoom = value),
          ),
          _SliderRow(
            label: l10n.horizontal,
            value: _offsetX,
            min: -1,
            max: 1,
            onChanged: (value) => setState(() => _offsetX = value),
          ),
          _SliderRow(
            label: l10n.vertical,
            value: _offsetY,
            min: -1,
            max: 1,
            onChanged: (value) => setState(() => _offsetY = value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSavingAvatar
                      ? null
                      : () => setState(() {
                          _zoom = 1;
                          _offsetX = 0;
                          _offsetY = 0;
                        }),
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: Text(l10n.reset),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  label: _isSavingAvatar ? l10n.saving : l10n.save,
                  icon: Icons.save,
                  height: 44,
                  onPressed: canSave ? _saveAvatar : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProfileDetails(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = _profile.displayName.isEmpty
        ? l10n.noDisplayName
        : _profile.displayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoRow(
          icon: Icons.person_outline,
          label: l10n.displayName,
          value: displayName,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.mail_outline,
          label: l10n.email,
          value: _profile.email,
        ),
        const SizedBox(height: 12),
        _ContactPhoneField(controller: _phoneController),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 220,
            child: GradientButton(
              label: _isSavingContactInfo
                  ? l10n.savingContactInfo
                  : l10n.saveContactInfo,
              icon: Icons.save,
              height: 46,
              onPressed: _isSavingContactInfo ? null : _saveContactInfo,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.avatarStorageNote,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Language Card (Task 3) ───────────────────────────────────────────────

  Widget _buildLanguageCard(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final controller = LocaleProvider.of(context);
    final currentLocale = controller.value;

    // Map locale → localized display label
    String localizedLabel(String key) => switch (key) {
      'english' => l10n.english,
      'vietnamese' => l10n.vietnamese,
      'korean' => l10n.korean,
      _ => key,
    };

    const options = [
      (Locale('en'), 'english'),
      (Locale('vi'), 'vietnamese'),
      (Locale('ko'), 'korean'),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.language,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final option in options)
            RadioListTile<Locale>(
              contentPadding: EdgeInsets.zero,
              value: option.$1,
              groupValue: currentLocale,
              onChanged: (locale) async {
                if (locale == null) return;
                await controller.setLocale(locale);
                if (mounted) {
                  _showMessage(AppLocalizations.of(context)!.languageSaved);
                }
              },
              title: Text(
                localizedLabel(option.$2),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.changePassword,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _PasswordField(
            controller: _newPasswordController,
            label: l10n.newPassword,
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _confirmPasswordController,
            label: l10n.confirmPassword,
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 220,
              child: GradientButton(
                label: _isChangingPassword ? l10n.updating : l10n.update,
                icon: Icons.lock_reset,
                height: 46,
                onPressed: _isChangingPassword ? null : _changePassword,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: l10n.back,
          ),
          const SizedBox(width: 4),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.brandGradient.createShader(bounds),
            child: Text(
              MockData.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const Spacer(),
          Text(
            l10n.profile,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.pickedBytes,
    required this.avatarUrl,
    required this.zoom,
    required this.offsetX,
    required this.offsetY,
  });

  final Uint8List? pickedBytes;
  final String? avatarUrl;
  final double zoom;
  final double offsetX;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 184,
      height: 184,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withValues(alpha: 0.26),
            blurRadius: 22,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: const Color(0xFF12182B),
          child: pickedBytes != null
              ? Transform.translate(
                  offset: Offset(offsetX * 50, offsetY * 50),
                  child: Transform.scale(
                    scale: zoom,
                    child: Image.memory(
                      pickedBytes!,
                      width: 176,
                      height: 176,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : _SavedAvatar(avatarUrl: avatarUrl),
        ),
      ),
    );
  }
}

class _SavedAvatar extends StatelessWidget {
  const _SavedAvatar({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    if (url == null) {
      return Icon(
        Icons.person,
        size: 74,
        color: Colors.white.withValues(alpha: 0.65),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, _, _) => Icon(
        Icons.person,
        size: 74,
        color: Colors.white.withValues(alpha: 0.65),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }
}

class _ContactPhoneField extends StatelessWidget {
  const _ContactPhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: l10n.phoneNumber,
        hintText: l10n.phoneHint,
        prefixIcon: const Icon(Icons.phone_outlined),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }
}
