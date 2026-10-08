import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/ai_action.dart';
import 'package:voyz/services/gemini_service.dart';

void main() {
  group('GeminiService chatWithActions Parser Tests', () {
    test('parseChatActionResponse correctly extracts JSON action block', () {
      const response = '''
Mình sẽ đưa bạn tới Côn Đảo ngay nhé!
```json
{
  "action": {
    "type": "navigateDestination",
    "target": "Côn Đảo",
    "label": "Mở trang Côn Đảo"
  }
}
```''';

      final parsed = GeminiService.instance.parseChatActionResponse(response);
      expect(parsed.reply.trim(), equals('Mình sẽ đưa bạn tới Côn Đảo ngay nhé!'));
      expect(parsed.action, isNotNull);
      expect(parsed.action?.type, equals(AiActionType.navigateDestination));
      expect(parsed.action?.target, equals('Côn Đảo'));
      expect(parsed.action?.label, equals('Mở trang Côn Đảo'));
    });

    test('parseChatActionResponse handles plain text without action block', () {
      const response = 'Côn Đảo có bãi Đầm Trầu rất đẹp.';
      final parsed = GeminiService.instance.parseChatActionResponse(response);
      expect(parsed.reply, equals(response));
      expect(parsed.action, isNull);
    });
  });
}
