import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/ai_action.dart';

void main() {
  group('AiAction Tests', () {
    test('fromJson parses navigateDestination action correctly', () {
      final json = {
        'type': 'navigateDestination',
        'target': 'Phú Quốc',
        'label': 'Mở trang Phú Quốc',
        'parameters': {'numDays': 3},
      };

      final action = AiAction.fromJson(json);
      expect(action.type, equals(AiActionType.navigateDestination));
      expect(action.target, equals('Phú Quốc'));
      expect(action.label, equals('Mở trang Phú Quốc'));
      expect(action.parameters?['numDays'], equals(3));
    });

    test('fromJson handles invalid or missing fields gracefully', () {
      final json = <String, dynamic>{};
      final action = AiAction.fromJson(json);
      expect(action.type, equals(AiActionType.navigateScreen));
      expect(action.target, equals(''));
      expect(action.label, equals(''));
    });
  });
}
