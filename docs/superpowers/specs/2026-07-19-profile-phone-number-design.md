# Profile Phone Number Design

## Context

The app now has a `ProfileScreen` backed by Supabase Auth user metadata. The
current profile surface reads the signed-in user's email, display name, and
avatar URL, and writes avatar updates back to `user_metadata`.

This feature adds a normal contact phone number to the profile. It is not used
for login, OTP, MFA, or account recovery in this iteration.

## Goals

- Let a signed-in user view, add, edit, and clear their contact phone number on
  the Profile screen.
- Store the value in Supabase Auth `user_metadata` under `phone_number`.
- Preserve existing metadata keys such as `display_name`, `username`, and
  `avatar_url` whenever the phone number is updated.
- Keep the Profile UI consistent with the existing dark glass style.

## Non-Goals

- No Supabase phone auth, OTP confirmation, MFA, or phone-based sign-in.
- No new `profiles` database table or Supabase migration.
- No strict country-specific phone formatting.

## User Experience

In the "Ho so nguoi dung" card, the profile details section will include a
phone-number input with a phone icon. The field is prefilled from
`user_metadata.phone_number` when present.

The user can type a phone number and tap a gradient save button. On success, the
screen updates local state and shows a snackbar. If the user clears the field
and saves, the stored phone value becomes empty so the number is effectively
removed.

Error messages follow the existing snackbar pattern used for avatar and password
updates.

## Data Model

`UserProfile` gains:

```dart
final String phoneNumber;
```

`ProfileService.currentProfile()` reads:

```dart
metadata['phone_number']
```

`ProfileService.updateContactInfo()` updates auth metadata with:

```dart
UserAttributes(data: {...?user.userMetadata, 'phone_number': phoneNumber})
```

The service keeps the value trimmed but otherwise preserves user-entered
formatting, such as `+84 912 345 678`.

## Validation

Because this is a contact field, not verified auth data, validation stays light:

- Empty value is allowed.
- Non-empty value must contain at least 8 digits.
- Non-empty value may only contain digits, spaces, `+`, `-`, `(`, and `)`.

This avoids rejecting reasonable international formats while still catching
obvious accidental text.

## Components

- `ProfileService`
  - Extend `UserProfile` with `phoneNumber`.
  - Add `updateContactInfo({required String phoneNumber})`.
- `ProfileScreen`
  - Add `_phoneController`.
  - Initialize it from `_profile.phoneNumber`.
  - Dispose it with the other controllers.
  - Add `_isSavingContactInfo`.
  - Add `_saveContactInfo()` with validation and snackbar handling.
  - Render the phone input and save button inside the existing profile details
    column.

## Error Handling

Auth errors use `AuthException.message`, matching current avatar/password
handling. Other errors are surfaced through the existing snackbar helper.

The save button is disabled while a phone metadata update is in progress.

## Verification

- Run `flutter analyze`.
- Run the existing Flutter tests if dependencies and environment are available.
- Manually inspect that Profile still displays email/avatar and that saving a
  phone number preserves avatar metadata.
