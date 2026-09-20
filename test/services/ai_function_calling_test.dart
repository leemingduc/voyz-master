import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/ai_function_call.dart';
import 'package:voyz/models/chat_message.dart';

void main() {
  group('AIFunctionCallResult', () {
    test('identifies presence of function call correctly', () {
      const navResult = AIFunctionCallResult(
        responseText: 'Đang chuyển trang...',
        functionName: 'navigateToPage',
        arguments: {'page': 'saved'},
      );

      expect(navResult.hasFunctionCall, isTrue);
      expect(navResult.functionName, 'navigateToPage');
      expect(navResult.arguments?['page'], 'saved');

      const plainResult = AIFunctionCallResult(
        responseText: 'Chào bạn, tôi có thể giúp gì cho bạn?',
      );

      expect(plainResult.hasFunctionCall, isFalse);
      expect(plainResult.functionName, isNull);
    });

    test('supports new function calls for compare, best time, culture, and detail', () {
      const compareResult = AIFunctionCallResult(
        responseText: 'Đang so sánh Đà Lạt và Sapa...',
        functionName: 'compareDestinations',
        arguments: {
          'destinations': ['Đà Lạt', 'Sapa']
        },
      );
      expect(compareResult.hasFunctionCall, isTrue);
      expect(compareResult.functionName, 'compareDestinations');

      const bestTimeResult = AIFunctionCallResult(
        responseText: 'Đang phân tích thời điểm đi Nha Trang...',
        functionName: 'getBestTimeToTravel',
        arguments: {'destination': 'Nha Trang'},
      );
      expect(bestTimeResult.hasFunctionCall, isTrue);
      expect(bestTimeResult.arguments?['destination'], 'Nha Trang');

      const cultureResult = AIFunctionCallResult(
        responseText: 'Đang tổng hợp mẹo văn hóa Tokyo...',
        functionName: 'getCulturalTips',
        arguments: {'destination': 'Tokyo'},
      );
      expect(cultureResult.hasFunctionCall, isTrue);

      const detailResult = AIFunctionCallResult(
        responseText: 'Đang mở thông tin Phú Quốc...',
        functionName: 'viewDestinationDetail',
        arguments: {'destination': 'Phú Quốc'},
      );
      expect(detailResult.hasFunctionCall, isTrue);
    });

    test('ChatMessage supports function call action metadata', () {
      final msg = ChatMessage.ai(
        'Đang mở trang chuyến đi đã lưu',
        actionName: 'navigateToPage',
        actionSummary: '✨ Điều hướng: Trang SAVED',
      );

      expect(msg.isUser, isFalse);
      expect(msg.actionName, 'navigateToPage');
      expect(msg.actionSummary, contains('SAVED'));

      final map = msg.toMap();
      expect(map['actionName'], 'navigateToPage');
      expect(map['actionSummary'], contains('SAVED'));

      final restored = ChatMessage.fromMap(map);
      expect(restored.actionName, 'navigateToPage');
      expect(restored.actionSummary, contains('SAVED'));
    });
  });
}
