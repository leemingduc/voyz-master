import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/plan_turn.dart';

void main() {
  const option = TripOption(
    title: 'Biển & lặn',
    destination: 'Côn Đảo, Việt Nam',
    numDays: 4,
    stops: ['Bến Đầm', 'Hòn Bảy Cạnh', 'Bãi Đầm Trầu'],
    imageStop: 'Hòn Bảy Cạnh',
    price: '~6.5M VND',
    aiInsight: 'Hợp nhóm bạn thích biển',
  );

  group('PlannerMessage', () {
    test('user message has no turn', () {
      final m = PlannerMessage.user('Du lịch Côn Đảo');
      expect(m.isUser, isTrue);
      expect(m.text, 'Du lịch Côn Đảo');
      expect(m.turn, isNull);
    });

    test('agent message takes text from the turn reply', () {
      final turn = PlanTurn(reply: 'Bạn đi mấy ngày?', trip: TripData());
      final m = PlannerMessage.agent(turn);
      expect(m.isUser, isFalse);
      expect(m.text, 'Bạn đi mấy ngày?');
      expect(m.turn, same(turn));
    });
  });

  group('PlanTurn and TripOption', () {
    test('hasOptions reflects the list', () {
      expect(PlanTurn(reply: 'q', trip: TripData()).hasOptions, isFalse);
      expect(
        PlanTurn(reply: 'r', trip: TripData(), options: [option]).hasOptions,
        isTrue,
      );
    });

    test('copyWith replaces only what is given', () {
      final withImage = option.copyWith(imageUrl: 'https://x/y.jpg');
      expect(withImage.imageUrl, 'https://x/y.jpg');
      expect(withImage.title, option.title);
      expect(withImage.stops, option.stops);

      final turn = PlanTurn(reply: 'r', trip: TripData(), raw: '{}');
      final updated = turn.copyWith(options: [withImage]);
      expect(updated.options.single.imageUrl, 'https://x/y.jpg');
      expect(updated.raw, '{}');
      expect(updated.reply, 'r');
    });

    test('round-trips an AI message for the saved planner conversation', () {
      final message = PlannerMessage.agent(
        PlanTurn(
          reply: 'Đây là các phương án phù hợp.',
          trip: TripData(destination: 'Côn Đảo', numDays: 4),
          options: const [option],
          raw: '{"reply":"Đây là các phương án phù hợp."}',
        ),
      );

      final restored = PlannerMessage.fromMap(message.toMap());

      expect(restored.isUser, isFalse);
      expect(restored.text, message.text);
      expect(restored.turn!.trip.destination, 'Côn Đảo');
      expect(restored.turn!.options.single.title, option.title);
      expect(restored.turn!.raw, message.turn!.raw);
    });

    test('saved conversations retain their id and message history', () {
      final conversation = PlannerConversation(
        id: 'planner-1',
        messages: [
          PlannerMessage.user('Plan a weekend in Seoul'),
          PlannerMessage.agent(
            PlanTurn(reply: 'How many people?', trip: TripData()),
          ),
        ],
        createdAt: DateTime(2026, 10, 7),
        updatedAt: DateTime(2026, 10, 8),
      );

      final restored = PlannerConversation.fromMap(conversation.toMap());

      expect(restored.id, 'planner-1');
      expect(restored.messages, hasLength(2));
      expect(restored.title, 'Plan a weekend in Seoul');
      expect(restored.updatedAt, DateTime(2026, 10, 8));
    });
  });

  group('tripForOption', () {
    test('sets destination, numDays and the chosen route in aiPrompt', () {
      final turn = PlanTurn(
        reply: 'r',
        trip: TripData(destination: 'Côn Đảo', participants: '2'),
        options: const [option],
      );
      final trip = tripForOption(turn, option, [
        'Du lịch Côn Đảo',
        '  ',
        '4 ngày, 2 người',
      ]);
      expect(trip.destination, 'Côn Đảo, Việt Nam');
      expect(trip.numDays, 4);
      expect(trip.participants, '2');
      expect(
        trip.aiPrompt,
        'Du lịch Côn Đảo\n4 ngày, 2 người\n'
        'Phương án đã chọn: Biển & lặn, 4 ngày, '
        'lộ trình: Bến Đầm, Hòn Bảy Cạnh, Bãi Đầm Trầu.',
      );
    });
  });
}
