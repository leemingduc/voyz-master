import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/services/avatar_image_picker.dart';
import 'package:voyz/services/profile_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/glass_card.dart';
import 'package:voyz/widgets/shared/gradient_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late UserProfile _profile;
  PickedAvatarImage? _pickedImage;
  double _zoom = 1;
  double _offsetX = 0;
  double _offsetY = 0;
  bool _isSavingAvatar = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _profile = ProfileService.instance.currentProfile();
  }

  @override
  void dispose() {
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
        );
        _pickedImage = null;
      });
      _showMessage('Avatar da duoc luu.');
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSavingAvatar = false);
    }
  }

  Future<void> _changePassword() async {
    final password = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 6) {
      _showMessage('Mat khau moi can it nhat 6 ky tu.', isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Xac nhan mat khau khong khop.', isError: true);
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      await ProfileService.instance.updatePassword(password);
      if (!mounted) return;
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showMessage('Mat khau da duoc cap nhat.');
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
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
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ho so nguoi dung',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Avatar va email se duoc giu lai sau moi lan dang nhap.',
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
          label: const Text('Upload anh'),
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
            label: 'Zoom',
            value: _zoom,
            min: 1,
            max: 3,
            onChanged: (value) => setState(() => _zoom = value),
          ),
          _SliderRow(
            label: 'Ngang',
            value: _offsetX,
            min: -1,
            max: 1,
            onChanged: (value) => setState(() => _offsetX = value),
          ),
          _SliderRow(
            label: 'Doc',
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
                  label: const Text('Dat lai'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  label: _isSavingAvatar ? 'Dang luu' : 'Luu',
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
    final displayName = _profile.displayName.isEmpty
        ? 'Chua co ten hien thi'
        : _profile.displayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoRow(icon: Icons.person_outline, label: 'Ten hien thi', value: displayName),
        const SizedBox(height: 12),
        _InfoRow(icon: Icons.mail_outline, label: 'Email', value: _profile.email),
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
                  'Anh duoc luu trong Supabase Storage bucket avatars va URL duoc ghi vao user metadata.',
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

  Widget _buildPasswordCard(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doi mat khau',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _PasswordField(
            controller: _newPasswordController,
            label: 'Mat khau moi',
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _confirmPasswordController,
            label: 'Xac nhan mat khau',
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 220,
              child: GradientButton(
                label: _isChangingPassword ? 'Dang cap nhat' : 'Cap nhat',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 4),
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.brandGradient.createShader(bounds),
            child: const Text(
              'AIVIVU',
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
            'Profile',
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
          width: 54,
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
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

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
