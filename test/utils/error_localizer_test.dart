import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/utils/error_localizer.dart';

/// Các lỗi dưới đây chép đúng dạng SDK google_generative_ai 0.4.7 ném ra
/// khi gọi Gemini API thật: 4xx thành ServerException/InvalidApiKey với
/// message gốc của Google, 5xx thành GenerativeAIException('Server Error ...').
void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));
  String localize(Object error) =>
      ErrorLocalizer.getLocalizedMessage(error, l10n);

  group('Gemini hết quota (429 RESOURCE_EXHAUSTED)', () {
    test('free tier quota exceeded', () {
      final error = ServerException(
        'You exceeded your current quota, please check your plan and billing '
        'details. For more information on this error, head to: '
        'https://ai.google.dev/gemini-api/docs/rate-limits.\n'
        '* Quota exceeded for metric: generativelanguage.googleapis.com/'
        'generate_content_free_tier_requests, limit: 10\n'
        'Please retry in 41.2s.',
      );
      expect(localize(error), l10n.aiQuotaExceeded);
    });

    test('resource has been exhausted', () {
      final error = ServerException(
        'Resource has been exhausted (e.g. check quota).',
      );
      expect(localize(error), l10n.aiQuotaExceeded);
    });
  });

  group('Gemini từ chối key', () {
    test('key sai (API_KEY_INVALID)', () {
      final error = InvalidApiKey(
        'API key not valid. Please pass a valid API key.',
      );
      expect(localize(error), l10n.aiKeyInvalid);
    });

    test('key bị Google khoá vì lộ (403 leaked)', () {
      final error = ServerException(
        'Your API key was reported as leaked. Please use another API key.',
      );
      expect(localize(error), l10n.aiKeyInvalid);
    });

    test('key bị khoá sau deploy (401 ACCESS_TOKEN_TYPE_UNSUPPORTED)', () {
      final error = ServerException(
        'API keys are not supported by this API. Expected OAuth2 access '
        'token or other authentication credentials that assert a principal.',
      );
      expect(localize(error), l10n.aiKeyInvalid);
    });
  });

  test('máy chủ Gemini quá tải (503)', () {
    final error = GenerativeAIException(
      'Server Error [503]: {"error": {"code": 503, "message": "The model is '
      'overloaded. Please try again later.", "status": "UNAVAILABLE"}}',
    );
    expect(localize(error), l10n.aiServerBusy);
  });

  test('AI trả JSON hỏng', () {
    expect(
      localize(const FormatException('Unexpected character')),
      l10n.aiInvalidResponse,
    );
  });

  test('mất mạng', () {
    expect(
      localize(http.ClientException('Failed to fetch')),
      l10n.networkError,
    );
  });

  test('lỗi key app tự ném vẫn giữ nguyên', () {
    expect(localize(Exception('noAiResponse')), l10n.noAiResponse);
    expect(localize(Exception('apiKeyNotSet')), l10n.apiKeyNotSet);
  });

  test('lỗi lạ rơi về thông báo chung', () {
    expect(localize(StateError('boom')), l10n.genericError);
  });
}
