import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/models/plan_turn.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('planner_session_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('keeps multiple AI planner conversations and reopens one', (
    tester,
  ) async {
    final providerKey = GlobalKey<SavedTripsProviderState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SavedTripsProvider(key: providerKey, child: const SizedBox()),
      ),
    );

    final message = PlannerMessage.user('Đi biển 3 ngày cho 2 người');
    await providerKey.currentState!.updatePlannerMessages([message]);
    await tester.pump();

    expect(providerKey.currentState!.plannerMessages, hasLength(1));
    expect(providerKey.currentState!.plannerMessages.single.text, message.text);

    final firstId = providerKey.currentState!.activePlannerConversationId!;
    await providerKey.currentState!.startNewPlannerConversation();
    await tester.pump();

    expect(providerKey.currentState!.plannerMessages, isEmpty);
    await providerKey.currentState!.updatePlannerMessages([
      PlannerMessage.user('Đi Hàn Quốc mùa thu'),
    ]);

    expect(providerKey.currentState!.plannerConversations, hasLength(2));
    final restored = await providerKey.currentState!.openPlannerConversation(
      firstId,
    );

    expect(restored.single.text, message.text);
  });

  testWidgets('restores suggestion history after the planner is recreated', (
    tester,
  ) async {
    final firstProviderKey = GlobalKey<SavedTripsProviderState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SavedTripsProvider(
          key: firstProviderKey,
          child: const SizedBox(),
        ),
      ),
    );
    await firstProviderKey.currentState!.updatePlannerMessages([
      PlannerMessage.user('Gợi ý chuyến đi cuối tuần'),
    ]);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    final restoredProviderKey = GlobalKey<SavedTripsProviderState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SavedTripsProvider(
          key: restoredProviderKey,
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(restoredProviderKey.currentState!.plannerConversations, isNotEmpty);
    expect(
      restoredProviderKey.currentState!.plannerMessages.single.text,
      'Gợi ý chuyến đi cuối tuần',
    );
  });
}
