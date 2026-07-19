import 'package:voyz/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class to localize error messages from Supabase and other services
class ErrorLocalizer {
  /// Translates an error to a localized message
  ///
  /// Handles AuthException from Supabase and common error keys from our services
  static String getLocalizedMessage(Object error, AppLocalizations l10n) {
    // Handle Supabase AuthException
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      // Map common Supabase auth errors to localized keys
      if (message.contains('invalid login credentials') ||
          message.contains('invalid_credentials')) {
        return l10n.invalidLoginCredentials;
      }

      if (message.contains('email not confirmed') ||
          message.contains('email_not_confirmed')) {
        return l10n.emailNotConfirmed;
      }

      if (message.contains('user already registered') ||
          message.contains('user_already_exists') ||
          message.contains('duplicate key')) {
        return l10n.userAlreadyExists;
      }

      // Check for our custom error keys
      if (message == 'loginrequired') {
        return l10n.loginRequired;
      }
    }

    // Handle generic Exception with our custom error keys
    if (error is Exception) {
      final errorMessage = error.toString().toLowerCase();

      // Extract the message from "Exception: message"
      final message = errorMessage.replaceFirst('exception:', '').trim();

      if (message == 'noairesponse') {
        return l10n.noAiResponse;
      }

      if (message.contains('apikeynotset') ||
          message.contains('gemini_api_key is not set')) {
        return l10n.apiKeyNotSet;
      }

      if (message == 'loginrequired') {
        return l10n.loginRequired;
      }
    }

    // Default fallback for unknown errors
    return l10n.genericError;
  }
}
