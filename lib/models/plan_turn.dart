import 'package:voyz/data/trip_data.dart';
import 'package:uuid/uuid.dart';

/// Một phương án chuyến đi AI đưa ra trong planner chat: một chủ đề,
/// một thời lượng và lộ trình nhiều điểm dừng trong cùng điểm đến gốc.
class TripOption {
  const TripOption({
    required this.title,
    required this.destination,
    required this.numDays,
    required this.stops,
    required this.imageStop,
    required this.price,
    required this.aiInsight,
    this.imageUrl = '',
  });

  /// Chủ đề, ví dụ "Biển & lặn ngắm san hô".
  final String title;

  /// Điểm đến gốc dạng "Côn Đảo, Việt Nam". Truyền nguyên cho màn chi tiết.
  final String destination;
  final int numDays;

  /// 3-5 địa danh có tên riêng theo thứ tự đi.
  final List<String> stops;

  /// Địa danh tiêu biểu nhất cho chủ đề, dùng để tra ảnh.
  final String imageStop;

  /// Giá ước tính của AI (chuỗi kèm mã tiền tệ), không phải báo giá.
  final String price;
  final String aiInsight;

  /// Rỗng tới khi tra ảnh xong; rỗng mãi thì UI vẽ placeholder.
  final String imageUrl;

  TripOption copyWith({String? imageUrl}) => TripOption(
    title: title,
    destination: destination,
    numDays: numDays,
    stops: stops,
    imageStop: imageStop,
    price: price,
    aiInsight: aiInsight,
    imageUrl: imageUrl ?? this.imageUrl,
  );

  factory TripOption.fromMap(Map<dynamic, dynamic> map) => TripOption(
    title: map['title']?.toString() ?? '',
    destination: map['destination']?.toString() ?? '',
    numDays: int.tryParse(map['numDays']?.toString() ?? '') ?? 0,
    stops: TripData.stringList(map['stops']),
    imageStop: map['imageStop']?.toString() ?? '',
    price: map['price']?.toString() ?? '',
    aiInsight: map['aiInsight']?.toString() ?? '',
    imageUrl: map['imageUrl']?.toString() ?? '',
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'destination': destination,
    'numDays': numDays,
    'stops': stops,
    'imageStop': imageStop,
    'price': price,
    'aiInsight': aiInsight,
    'imageUrl': imageUrl,
  };
}

/// Một lượt trả lời của AI trong planner chat.
class PlanTurn {
  const PlanTurn({
    required this.reply,
    required this.trip,
    this.options = const [],
    this.raw = '',
  });

  /// Câu hỏi thêm, hoặc câu giới thiệu khi có phương án.
  final String reply;

  /// Mọi thông tin chuyến đi đã biết tới lượt này.
  final TripData trip;

  /// Rỗng khi AI đang hỏi thêm.
  final List<TripOption> options;

  /// JSON gốc, gửi lại cho AI làm lịch sử hội thoại.
  final String raw;

  bool get hasOptions => options.isNotEmpty;

  PlanTurn copyWith({List<TripOption>? options}) => PlanTurn(
    reply: reply,
    trip: trip,
    options: options ?? this.options,
    raw: raw,
  );

  factory PlanTurn.fromMap(Map<dynamic, dynamic> map) => PlanTurn(
    reply: map['reply']?.toString() ?? '',
    trip: map['trip'] is Map
        ? TripData.fromMap(map['trip'] as Map)
        : TripData(),
    options: (map['options'] as List? ?? const [])
        .whereType<Map>()
        .map(TripOption.fromMap)
        .toList(),
    raw: map['raw']?.toString() ?? '',
  );

  Map<String, dynamic> toMap() => {
    'reply': reply,
    'trip': trip.toMap(),
    'options': options.map((option) => option.toMap()).toList(),
    'raw': raw,
  };
}

/// Một tin nhắn trong planner chat: của người dùng ([turn] null) hoặc của AI.
class PlannerMessage {
  const PlannerMessage._(this.text, this.turn);

  factory PlannerMessage.user(String text) => PlannerMessage._(text, null);

  factory PlannerMessage.agent(PlanTurn turn) =>
      PlannerMessage._(turn.reply, turn);

  final String text;
  final PlanTurn? turn;

  bool get isUser => turn == null;

  factory PlannerMessage.fromMap(Map<dynamic, dynamic> map) {
    final turn = map['turn'];
    if (turn is Map) return PlannerMessage.agent(PlanTurn.fromMap(turn));
    return PlannerMessage.user(map['text']?.toString() ?? '');
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    if (turn != null) 'turn': turn!.toMap(),
  };
}

/// Một cuộc trò chuyện đã lưu trong phần Gợi ý AI.
class PlannerConversation {
  PlannerConversation({
    String? id,
    required this.messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final List<PlannerMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get title {
    var text = '';
    for (final message in messages) {
      if (message.isUser) {
        text = message.text.trim();
        break;
      }
    }
    if (text.isEmpty && messages.isNotEmpty) text = messages.first.text.trim();
    if (text.length <= 48) return text;
    return '${text.substring(0, 48)}…';
  }

  PlannerConversation copyWith({
    List<PlannerMessage>? messages,
    DateTime? updatedAt,
  }) => PlannerConversation(
    id: id,
    messages: messages ?? this.messages,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory PlannerConversation.fromMap(Map<dynamic, dynamic> map) {
    final rawMessages = map['messages'];
    return PlannerConversation(
      id: map['id']?.toString(),
      messages: rawMessages is List
          ? rawMessages
                .whereType<Map>()
                .map(PlannerMessage.fromMap)
                .where(
                  (message) => message.text.isNotEmpty || message.turn != null,
                )
                .toList()
          : const [],
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'messages': messages.map((message) => message.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// TripData giao cho màn chi tiết khi người dùng chọn [option].
///
/// Lộ trình đã chọn nằm trong `aiPrompt`: prompt chi tiết và itinerary đã đọc
/// `aiPrompt`, nên itinerary bám theo lộ trình mà không phải sửa hai màn đó.
TripData tripForOption(
  PlanTurn turn,
  TripOption option,
  List<String> userMessages,
) {
  final chosen =
      'Phương án đã chọn: ${option.title}, ${option.numDays} ngày, '
      'lộ trình: ${option.stops.join(', ')}.';
  final lines = [
    ...userMessages.map((m) => m.trim()).where((m) => m.isNotEmpty),
    chosen,
  ];
  final start =
      turn.trip.departDate ?? DateTime.now().add(const Duration(days: 1));
  final departDate = DateTime(start.year, start.month, start.day);
  return turn.trip.copyWith(
    destination: option.destination,
    numDays: option.numDays,
    departDate: departDate,
    returnDate: departDate.add(Duration(days: option.numDays - 1)),
    aiPrompt: lines.join('\n'),
  );
}
