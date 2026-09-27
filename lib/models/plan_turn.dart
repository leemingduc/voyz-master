import 'package:voyz/data/trip_data.dart';

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
  return turn.trip.copyWith(
    destination: option.destination,
    numDays: option.numDays,
    aiPrompt: lines.join('\n'),
  );
}
