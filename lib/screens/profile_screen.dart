import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/data/ai_model_settings.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/data/friend_message_notification_settings.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/services/avatar_image_picker.dart';
import 'package:voyz/services/profile_service.dart';
import 'package:voyz/theme/app_theme.dart';
import 'package:voyz/widgets/shared/aivivu_wordmark.dart';
import 'package:voyz/widgets/shared/background_music_button.dart';
import 'package:voyz/widgets/shared/glass_card.dart';
import 'package:voyz/widgets/shared/gradient_button.dart';
import 'package:voyz/widgets/shared/profile_avatar.dart';
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
  final _displayNameController = TextEditingController();

  late UserProfile _profile;
  PickedAvatarImage? _pickedImage;
  double _zoom = 1;
  double _offsetX = 0;
  double _offsetY = 0;
  bool _isSavingAvatar = false;
  bool _isChangingPassword = false;
  bool _isSavingContactInfo = false;
  bool _isSavingDisplayName = false;
  bool _isSavingPreferences = false;
  String _preferredCurrency = 'VND';
  Set<String> _travelStyles = <String>{};

  @override
  void initState() {
    super.initState();
    _profile = ProfileService.instance.currentProfile();
    _phoneController.text = _profile.phoneNumber;
    _displayNameController.text = _profile.displayName;
    _preferredCurrency = _profile.preferredCurrency;
    _travelStyles = _profile.travelStyles.toSet();
    _loadCloudProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _displayNameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCloudProfile() async {
    final profile = await ProfileService.instance.loadCurrentProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _phoneController.text = profile.phoneNumber;
      _displayNameController.text = profile.displayName;
      _preferredCurrency = profile.preferredCurrency;
      _travelStyles = profile.travelStyles.toSet();
    });
    await CurrencyProvider.of(
      context,
    ).setDisplayCurrency(profile.preferredCurrency);
  }

  Future<void> _saveDisplayName() async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      _showMessage('Vui lòng nhập tên hiển thị.', isError: true);
      return;
    }

    setState(() => _isSavingDisplayName = true);
    try {
      final profile = await ProfileService.instance.updateDisplayName(
        displayName: displayName,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _displayNameController.text = profile.displayName;
      });
      _showMessage('Đã lưu tên hiển thị.');
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSavingDisplayName = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSavingPreferences = true);
    try {
      final profile = await ProfileService.instance.updateTravelPreferences(
        travelStyles: _travelStyles.toList(),
        preferredCurrency: _preferredCurrency,
      );
      await CurrencyProvider.of(
        context,
      ).setDisplayCurrency(profile.preferredCurrency);
      if (!mounted) return;
      setState(() => _profile = profile);
      _showMessage('Travel preferences saved');
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSavingPreferences = false);
    }
  }

  Future<void> _showAvatarPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AvatarPickerSheet(
        currentAvatarUrl: _profile.avatarUrl,
        isSaving: _isSavingAvatar,
        onUploadPhoto: () {
          Navigator.of(ctx).pop();
          _pickImage();
        },
        onSelectPreset: (presetId) {
          Navigator.of(ctx).pop();
          _savePresetAvatar(presetId);
        },
      ),
    );
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
          travelStyles: _profile.travelStyles,
          preferredCurrency: _profile.preferredCurrency,
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

  Future<void> _savePresetAvatar(String presetId) async {
    setState(() => _isSavingAvatar = true);
    try {
      final avatarUrl = await ProfileService.instance.savePresetAvatar(
        presetId,
      );
      if (!mounted) return;
      setState(() {
        _profile = _profile.copyWith(avatarUrl: avatarUrl);
        _pickedImage = null;
      });
      _showMessage('Đã lưu ảnh đại diện.');
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
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
          travelStyles: _profile.travelStyles,
          preferredCurrency: _profile.preferredCurrency,
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
            colors: [AppTheme.surfaceDark, AppTheme.backgroundDark],
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
                          _buildBackgroundMusicCard(),
                          const SizedBox(height: 16),
                          _buildFriendMessageNotificationCard(),
                          const SizedBox(height: 16),
                          _buildAiModelCard(),
                          const SizedBox(height: 16),
                          _buildPreferencesCard(theme),
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
          onPressed: _isSavingAvatar ? null : _showAvatarPicker,
          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _displayNameController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _isSavingDisplayName ? null : _saveDisplayName(),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            labelText: l10n.displayName,
            prefixIcon: const Icon(Icons.person_outline),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 180,
            child: GradientButton(
              label: _isSavingDisplayName ? l10n.saving : 'Lưu tên',
              icon: Icons.save,
              height: 42,
              onPressed: _isSavingDisplayName ? null : _saveDisplayName,
            ),
          ),
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
      ],
    );
  }

  // â”€â”€ Language Card (Task 3) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildLanguageCard(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final controller = LocaleProvider.of(context);
    final currentLocale = controller.value;

    // Map locale â†’ localized display label
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

  // ── AI model card ─────────────────────────────────────────────────────

  Widget _buildBackgroundMusicCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.music_note_rounded, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhạc nền',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Bật hoặc tắt nhạc khi sử dụng ứng dụng',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          BackgroundMusicButton(),
        ],
      ),
    );
  }

  Widget _buildFriendMessageNotificationCard() {
    final settings = FriendMessageNotificationSettings.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: settings.enabled,
      builder: (context, enabled, _) => GlassCard(
        padding: const EdgeInsets.all(18),
        child: SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: enabled,
          onChanged: settings.save,
          secondary: const Icon(
            Icons.notifications_active_outlined,
            color: Colors.white70,
          ),
          title: const Text(
            'Thông báo tin nhắn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: const Text(
            'Hiển thị banner và số tin nhắn mới từ bạn bè.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          activeTrackColor: AppTheme.cyan,
        ),
      ),
    );
  }

  Widget _buildAiModelCard() {
    final l10n = AppLocalizations.of(context)!;
    final current = AiModelSettings.instance.current;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.aiModel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.aiModelDescription,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 12),
          for (final option in supportedAiModels)
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: option.id,
              groupValue: current,
              onChanged: (id) async {
                if (id == null) return;
                await AiModelSettings.instance.save(id);
                if (mounted) {
                  setState(() {});
                  _showMessage(l10n.aiModelSaved);
                }
              },
              title: Text(
                option.label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                option.id,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(ThemeData theme) {
    const styles = [
      'Beach',
      'Adventure',
      'Culture',
      'Food',
      'Nature',
      'Luxury',
      'Budget',
      'Slow travel',
    ];

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Travel preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _preferredCurrency,
            dropdownColor: const Color(0xFF1E1B2E),
            decoration: InputDecoration(
              labelText: 'Preferred currency',
              prefixIcon: const Icon(Icons.payments_outlined),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            items: supportedCurrencies
                .map(
                  (currency) => DropdownMenuItem(
                    value: currency.code,
                    child: Text('${currency.code} - ${currency.name}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _preferredCurrency = value);
            },
          ),
          const SizedBox(height: 14),
          const Text(
            'Travel styles',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: styles.map((style) {
              final selected = _travelStyles.contains(style);
              return FilterChip(
                selected: selected,
                label: Text(style),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _travelStyles.add(style);
                    } else {
                      _travelStyles.remove(style);
                    }
                  });
                },
                selectedColor: AppTheme.primaryPink.withValues(alpha: 0.28),
                checkmarkColor: Colors.white,
                labelStyle: const TextStyle(color: Colors.white),
                backgroundColor: Colors.white.withValues(alpha: 0.06),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 220,
              child: GradientButton(
                label: _isSavingPreferences ? 'Saving' : 'Save preferences',
                icon: Icons.save,
                height: 46,
                onPressed: _isSavingPreferences ? null : _savePreferences,
              ),
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
          const AivivuWordmark(fontSize: 18),
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

    return ProfileAvatar(avatarUrl: url, radius: 88);
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
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        height: 1.45,
        letterSpacing: 0.2,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.cyan, width: 1.5),
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
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        height: 1.45,
        letterSpacing: 0.2,
      ),
      decoration: InputDecoration(
        labelText: l10n.phoneNumber,
        hintText: l10n.phoneHint,
        prefixIcon: const Icon(Icons.phone_outlined),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.cyan, width: 1.5),
        ),
      ),
    );
  }
}

// ── Avatar picker bottom sheet ────────────────────────────────────────────────

class _AvatarPickerSheet extends StatefulWidget {
  const _AvatarPickerSheet({
    required this.currentAvatarUrl,
    required this.isSaving,
    required this.onUploadPhoto,
    required this.onSelectPreset,
  });

  final String? currentAvatarUrl;
  final bool isSaving;
  final VoidCallback onUploadPhoto;
  final void Function(String presetId) onSelectPreset;

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Title ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.face_retouching_natural,
                  color: AppTheme.cyan,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Chọn ảnh đại diện',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // ── Tab bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: AppTheme.brandGradient,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, size: 15),
                        SizedBox(width: 6),
                        Text('Tải ảnh lên'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 15),
                        SizedBox(width: 6),
                        Text('Avatar có sẵn'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab views ───────────────────────────────────────────────
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Upload from device
                _UploadTab(onUploadPhoto: widget.onUploadPhoto),

                // Tab 2: Preset avatars
                _PresetTab(
                  currentAvatarUrl: widget.currentAvatarUrl,
                  isSaving: widget.isSaving,
                  onSelectPreset: widget.onSelectPreset,
                ),
              ],
            ),
          ),

          SizedBox(height: bottomPad + 8),
        ],
      ),
    );
  }
}

class _UploadTab extends StatelessWidget {
  const _UploadTab({required this.onUploadPhoto});

  final VoidCallback onUploadPhoto;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon area
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.brandGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPink.withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_a_photo_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tải ảnh từ thiết bị',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hỗ trợ JPG, PNG. Bạn có thể\ncắt và chỉnh sửa sau khi chọn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 180,
                  child: GradientButton(
                    label: 'Chọn ảnh',
                    icon: Icons.folder_open_rounded,
                    height: 44,
                    onPressed: onUploadPhoto,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetTab extends StatelessWidget {
  const _PresetTab({
    required this.currentAvatarUrl,
    required this.isSaving,
    required this.onSelectPreset,
  });

  final String? currentAvatarUrl;
  final bool isSaving;
  final void Function(String presetId) onSelectPreset;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 16,
        children: presetAvatarIds.map((presetId) {
          final isSelected = currentAvatarUrl == 'preset:$presetId';
          final label = presetAvatarLabels[presetId] ?? presetId;
          return GestureDetector(
            onTap: isSaving ? null : () => onSelectPreset(presetId),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.cyan
                          : Colors.white.withValues(alpha: 0.12),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.cyan.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: ProfileAvatar(
                    avatarUrl: 'preset:$presetId',
                    radius: 28,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.cyan
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
