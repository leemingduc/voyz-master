import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:voyz/models/chat_message.dart';
import 'package:voyz/services/chat_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'chat_history_service_test_',
    );
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('keeps saved chatbot conversations until one is deleted', () async {
    const destination = '__history_test__';
    final service = ChatHistoryService.instance;
    final first = await service.saveConversation([
      ChatMessage.user('Plan a Hanoi food trip'),
      ChatMessage.ai('How many days do you have?'),
    ], destinationName: destination);
    final second = await service.saveConversation([
      ChatMessage.user('Plan a Hue heritage trip'),
    ], destinationName: destination);

    final reloaded = await service.loadConversations(
      destinationName: destination,
    );
    expect(reloaded.conversations, hasLength(2));
    expect(reloaded.activeConversationId, second.activeConversationId);

    final remaining = await service.deleteConversation(
      first.activeConversationId!,
      destinationName: destination,
    );
    expect(remaining.conversations, hasLength(1));
    expect(remaining.conversations.single.title, 'Plan a Hue heritage trip');
  });

  test(
    'serializes overlapping chatbot saves without dropping a conversation',
    () async {
      const destination = '__overlapping_history_test__';
      final service = ChatHistoryService.instance;

      await Future.wait([
        service.saveConversation([
          ChatMessage.user('First saved conversation'),
        ], destinationName: destination),
        service.saveConversation([
          ChatMessage.user('Second saved conversation'),
        ], destinationName: destination),
      ]);

      final reloaded = await service.loadConversations(
        destinationName: destination,
      );
      expect(reloaded.conversations, hasLength(2));
    },
  );
}
