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
}
