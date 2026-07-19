# Profile Phone Number Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a normal editable contact phone number to the Profile screen and persist it in Supabase Auth `user_metadata.phone_number`.

**Architecture:** Extend the existing `ProfileService` and `UserProfile` model because the current Profile screen already reads and writes user metadata there. Keep the UI change inside `ProfileScreen`, following the current glass-card form style and snackbar error handling.

**Tech Stack:** Flutter, Dart, Supabase Flutter Auth, existing `GlassCard` and `GradientButton` widgets, `flutter analyze`, `flutter test`.

## Global Constraints

- The phone number is normal contact information, not login, OTP, MFA, or account recovery data.
- Store the value in Supabase Auth `user_metadata` under `phone_number`.
- Preserve existing metadata keys such as `display_name`, `username`, and `avatar_url` whenever the phone number is updated.
- Empty phone number is allowed.
- Non-empty phone number must contain at least 8 digits.
- Non-empty phone number may only contain digits, spaces, `+`, `-`, `(`, and `)`.
- Do not add a new `profiles` database table or Supabase migration.
- Do not add Supabase phone auth, OTP confirmation, MFA, or phone-based sign-in.

---

## File Structure

- Modify `lib/services/profile_service.dart`
  - Owns `UserProfile` and all Profile-related Supabase Auth metadata reads/writes.
  - Adds the `phoneNumber` value and an `updateContactInfo` method.
- Modify `lib/screens/profile_screen.dart`
  - Owns Profile screen state, input validation, save button state, and UI rendering.
  - Adds the phone-number input and save flow inside the existing profile details section.
- No new Supabase migration is required.
- No new dependency is required.

---

### Task 1: Profile Metadata Service

**Files:**
- Modify: `lib/services/profile_service.dart`
- Verify: `flutter analyze`

**Interfaces:**
- Produces: `UserProfile({required String email, required String displayName, required String? avatarUrl, required String phoneNumber})`
- Produces: `Future<String> updateContactInfo({required String phoneNumber})`
- Consumes: Existing `SupabaseService.instance.auth` and `UserAttributes(data: ...)`

- [ ] **Step 1: Update `UserProfile` to carry `phoneNumber`**

In `lib/services/profile_service.dart`, change the `UserProfile` class to:

```dart
class UserProfile {
  const UserProfile({
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.phoneNumber,
  });

  final String email;
  final String displayName;
  final String? avatarUrl;
  final String phoneNumber;
}
```

- [ ] **Step 2: Read `phone_number` from auth metadata**

In `ProfileService.currentProfile()`, after reading `avatarUrl`, add:

```dart
final phoneNumber = metadata['phone_number']?.toString().trim() ?? '';
```

Then return:

```dart
return UserProfile(
  email: user.email ?? '',
  displayName: displayName,
  avatarUrl: avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl,
  phoneNumber: phoneNumber,
);
```

- [ ] **Step 3: Preserve `phoneNumber` when saving avatars**

In `ProfileScreen` this task is not edited yet, so ensure service-level behavior keeps metadata intact. `saveAvatar()` already spreads existing metadata:

```dart
await _auth.updateUser(
  UserAttributes(data: {...?user.userMetadata, 'avatar_url': avatarUrl}),
);
```

Leave this intact so `phone_number` is preserved after it exists.

- [ ] **Step 4: Add metadata update method**

In `ProfileService`, below `saveAvatar`, add:

```dart
Future<String> updateContactInfo({required String phoneNumber}) async {
  final user = _requireUser();
  final normalizedPhone = phoneNumber.trim();

  await _auth.updateUser(
    UserAttributes(
      data: {...?user.userMetadata, 'phone_number': normalizedPhone},
    ),
  );

  return normalizedPhone;
}
```

- [ ] **Step 5: Run analyzer for service compile errors**

Run:

```bash
flutter analyze
```

Expected: Analyzer may now fail only if call sites constructing `UserProfile` have not been updated yet, because Task 2 owns those UI call sites. There should be no syntax errors in `profile_service.dart`.

- [ ] **Step 6: Commit Task 1**

Run:

```bash
git add lib/services/profile_service.dart
git commit -m "feat: add profile phone metadata service"
```

Expected: commit succeeds.

---

### Task 2: Profile Phone UI and Save Flow

**Files:**
- Modify: `lib/screens/profile_screen.dart`
- Verify: `flutter analyze`
- Verify: `flutter test`

**Interfaces:**
- Consumes: `UserProfile.phoneNumber`
- Consumes: `ProfileService.instance.updateContactInfo({required String phoneNumber})`
- Produces: editable phone-number field in Profile details

- [ ] **Step 1: Add phone controller and saving state**

In `_ProfileScreenState`, near the existing password controllers, add:

```dart
final _phoneController = TextEditingController();
```

Near the existing boolean state fields, add:

```dart
bool _isSavingContactInfo = false;
```

- [ ] **Step 2: Initialize and dispose the controller**

In `initState()`, after `_profile = ProfileService.instance.currentProfile();`, add:

```dart
_phoneController.text = _profile.phoneNumber;
```

In `dispose()`, before disposing password controllers, add:

```dart
_phoneController.dispose();
```

- [ ] **Step 3: Preserve phone number when avatar state is rebuilt**

In `_saveAvatar()`, replace the `UserProfile` reconstruction with:

```dart
_profile = UserProfile(
  email: _profile.email,
  displayName: _profile.displayName,
  avatarUrl: avatarUrl,
  phoneNumber: _profile.phoneNumber,
);
```

- [ ] **Step 4: Add phone validation helper**

Inside `_ProfileScreenState`, add this method before `_saveContactInfo()`:

```dart
String? _phoneValidationMessage(String phoneNumber) {
  final trimmed = phoneNumber.trim();
  if (trimmed.isEmpty) return null;

  final allowedCharacters = RegExp(r'^[0-9+\-() ]+$');
  if (!allowedCharacters.hasMatch(trimmed)) {
    return 'So dien thoai chi gom so, khoang trang, +, -, (, ).';
  }

  final digitCount = RegExp(r'\d').allMatches(trimmed).length;
  if (digitCount < 8) {
    return 'So dien thoai can it nhat 8 chu so.';
  }

  return null;
}
```

- [ ] **Step 5: Add contact save method**

Inside `_ProfileScreenState`, add this method near `_changePassword()`:

```dart
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
    _showMessage('Thong tin lien he da duoc luu.');
  } on AuthException catch (error) {
    if (mounted) _showMessage(error.message, isError: true);
  } catch (error) {
    if (mounted) _showMessage(error.toString(), isError: true);
  } finally {
    if (mounted) setState(() => _isSavingContactInfo = false);
  }
}
```

- [ ] **Step 6: Add phone input and save button to profile details**

In `_buildProfileDetails`, after the email `_InfoRow`, add:

```dart
const SizedBox(height: 12),
_ContactPhoneField(controller: _phoneController),
const SizedBox(height: 14),
Align(
  alignment: Alignment.centerRight,
  child: SizedBox(
    width: 220,
    child: GradientButton(
      label: _isSavingContactInfo ? 'Dang luu' : 'Luu thong tin',
      icon: Icons.save,
      height: 46,
      onPressed: _isSavingContactInfo ? null : _saveContactInfo,
    ),
  ),
),
```

Keep the existing `const SizedBox(height: 18)` before the informational blue box after this new block.

- [ ] **Step 7: Add reusable phone field widget**

In `lib/screens/profile_screen.dart`, near `_PasswordField`, add:

```dart
class _ContactPhoneField extends StatelessWidget {
  const _ContactPhoneField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'So dien thoai',
        hintText: '+84 912 345 678',
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
```

- [ ] **Step 8: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: PASS with no new analyzer issues.

- [ ] **Step 9: Run tests**

Run:

```bash
flutter test
```

Expected: PASS for existing tests. If `.env`/Supabase environment prevents app initialization in tests, record the exact failure and run `flutter analyze` as the required compile verification.

- [ ] **Step 10: Manual verification**

Open Profile while signed in and verify:

- Email and avatar still render.
- Phone field starts empty when no metadata exists.
- Saving `+84 912 345 678` shows success.
- Saving `abc` shows validation error.
- Clearing the field and saving shows success and leaves the field empty.

- [ ] **Step 11: Commit Task 2**

Run:

```bash
git add lib/screens/profile_screen.dart
git commit -m "feat: add profile phone number field"
```

Expected: commit succeeds.

---

## Final Verification

- [ ] Run `git status --short --branch` and confirm only expected files are changed or the tree is clean.
- [ ] Run `flutter analyze` and confirm no issues.
- [ ] Run `flutter test` and confirm tests pass or document the exact environment blocker.
