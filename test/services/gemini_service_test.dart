import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/services/gemini_service.dart';

void main() {
  group('languageInstruction', () {
    test('returns Vietnamese instruction for vi', () {
      final result = GeminiService.languageInstruction('vi');
      expect(result, contains('Vietnamese'));
    });

    test('returns Korean instruction for ko', () {
      final result = GeminiService.languageInstruction('ko');
      expect(result, contains('Korean'));
    });

    test('returns English instruction for en', () {
      final result = GeminiService.languageInstruction('en');
      expect(result, contains('English'));
    });

    test('returns English instruction for unsupported language', () {
      final result = GeminiService.languageInstruction('fr');
      expect(result, contains('English'));
    });
  });

  group('extractChatText', () {
    test('returns plain text unchanged', () {
      expect(
        GeminiService.extractChatText('Chào bạn, mình có thể giúp gì?'),
        'Chào bạn, mình có thể giúp gì?',
      );
    });

    test('extracts the response field from a JSON payload', () {
      expect(
        GeminiService.extractChatText(
          '{"response":"Bạn nên đi Đà Nẵng vào tháng 3 nhé."}',
        ),
        'Bạn nên đi Đà Nẵng vào tháng 3 nhé.',
      );
    });

    test('extracts nested text from a fenced JSON payload', () {
      expect(
        GeminiService.extractChatText(
          '```json\n{"response":{"text":"Nội dung trả lời"}}\n```',
        ),
        'Nội dung trả lời',
      );
    });
  });
}
