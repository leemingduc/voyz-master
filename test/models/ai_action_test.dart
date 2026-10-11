import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/ai_action.dart';

void main() {
  group('background music chatbot command', () {
    test('uses a state-setting action instead of a toggle action', () {
      final action = AiActionType.fromString('setBackgroundMusic');
      expect(action, AiActionType.setBackgroundMusic);
      expect(action.toFormattedString(), 'setBackgroundMusic');
    });

    test('recognises explicit on and off commands without toggling', () {
      expect(AiAction.backgroundMusicEnabled('on'), isTrue);
      expect(AiAction.backgroundMusicEnabled('off'), isFalse);
      expect(AiAction.backgroundMusicEnabled('b\u1eadt'), isTrue);
      expect(AiAction.backgroundMusicEnabled('t\u1eaft'), isFalse);
      expect(AiAction.backgroundMusicEnabled(''), isNull);
      expect(AiAction.backgroundMusicEnabled('toggle'), isNull);
    });
    test('creates both music actions directly from a user prompt', () {
      final on = AiAction.backgroundMusicActionForPrompt(
        'b\u1eadt nh\u1ea1c n\u1ec1n',
      );
      final off = AiAction.backgroundMusicActionForPrompt(
        't\u1eaft nh\u1ea1c n\u1ec1n',
      );

      expect(on?.type, AiActionType.setBackgroundMusic);
      expect(on?.target, 'on');
      expect(off?.type, AiActionType.setBackgroundMusic);
      expect(off?.target, 'off');
    });
  });
}
