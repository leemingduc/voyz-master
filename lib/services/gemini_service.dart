import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:voyz/data/ai_model_settings.dart';
import 'package:voyz/data/mock_data.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/ai_function_call.dart';
import 'package:voyz/models/best_time_travel.dart';
import 'package:voyz/models/chat_message.dart';
import 'package:voyz/models/cultural_tips.dart';
import 'package:voyz/models/destination_comparison.dart';
import 'package:voyz/models/destination_detail.dart';
import 'package:voyz/models/destination_suggestion.dart';
import 'package:voyz/models/itinerary_plan.dart';

import 'package:voyz/services/ai_cache_service.dart';
import 'package:voyz/services/image_service.dart';

/// Central service for interacting with the Gemini Flash 3 API.
///
/// Prompts include a language instruction so the AI responds in the
/// user's active locale. Every feature checks the Hive cache first and
/// only calls the API on a miss.
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  final AiCacheService _aiCache = AiCacheService.instance;

  // ── Language helpers ────────────────────────────────────────────────

  /// Returns a language instruction appended to every Gemini prompt.
  /// JSON keys, numeric values, and icon identifiers remain language-neutral.
  static String languageInstruction(String languageCode) {
    return switch (languageCode) {
      'vi' => 'Write every human-readable JSON value in Vietnamese.',
      'ko' => 'Write every human-readable JSON value in Korean.',
      _ => 'Write every human-readable JSON value in English.',
    };
  }

  /// Returns a language instruction for the conversational, plain-text chat.
  static String chatLanguageInstruction(String languageCode) {
    return switch (languageCode) {
      'vi' => 'Reply in Vietnamese.',
      'ko' => 'Reply in Korean.',
      _ => 'Reply in English.',
    };
  }

  /// The Gemini model used by every AI feature, as picked in Profile.
  String get modelName => AiModelSettings.instance.current;

  GenerativeModel? _model;
  String? _modelNameInUse;

  /// Returns a configured Gemini API key or throws the app-level config error.
  ///
  /// Keep this validation shared by JSON and chat requests so they cannot
  /// disagree about whether the key loaded from `.env` is usable.
  static String requireApiKey(String? value) {
    final apiKey = value?.trim();
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('apiKeyNotSet');
    }
    return apiKey;
  }

  /// Builds each feature-specific request client with the shared model and key.
  GenerativeModel _createModel({required GenerationConfig generationConfig}) {
    return GenerativeModel(
      model: modelName,
      apiKey: requireApiKey(dotenv.env['GEMINI_API_KEY']),
      generationConfig: generationConfig,
    );
  }

  GenerativeModel get _gemini {
    // Rebuild when the user switched model in Profile since the last call.
    if (_model != null && _modelNameInUse == modelName) return _model!;
    _modelNameInUse = modelName;
    _model = _createModel(
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
        // Thinking models count their thinking tokens against this limit,
        // so it is well above what the JSON itself needs.
        maxOutputTokens: 12288,
      ),
    );
    return _model!;
  }

  /// Tra URL ảnh cho danh sách gợi ý qua ImageService.
  /// Lỗi ảnh không làm hỏng kết quả AI: trả lại danh sách không ảnh.
  Future<List<DestinationSuggestion>> _withImages(
    List<DestinationSuggestion> suggestions,
  ) async {
    try {
      return await enrichSuggestionsWithImages(suggestions);
    } catch (e) {
      debugPrint('Image fetch error (non-fatal): $e');
      return suggestions;
    }
  }

  // ── Trích xuất TripData từ mô tả (planner hai bước) ──────────────────

  static const _validTiers = ['economy', 'moderate', 'premium', 'luxury'];

  /// Chuỗi từ JSON: trim, coi "null" (chữ) và rỗng là không có.
  String _cleanString(dynamic value) {
    final s = value?.toString().trim() ?? '';
    return (s.isEmpty || s.toLowerCase() == 'null') ? '' : s;
  }

  /// Bóc tách thông tin có cấu trúc từ mô tả chuyến đi. Không cache:
  /// người dùng sửa mô tả là phân tích lại.
  Future<TripData> extractTripData(
    String prompt, {
    String languageCode = 'vi',
  }) async {
    final text = (await _gemini.generateContent([
      Content.text(buildExtractPrompt(prompt, languageCode, DateTime.now())),
    ])).text;
    if (text == null || text.isEmpty) throw Exception('noAiResponse');
    return parseExtractedTripData(text, originalPrompt: prompt);
  }

  @visibleForTesting
  String buildExtractPrompt(
    String prompt,
    String languageCode,
    DateTime today,
  ) {
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    return '''
Bạn là trợ lý du lịch. Hôm nay là $todayStr. Đọc mô tả chuyến đi của người dùng và bóc tách thông tin.

Mô tả: "$prompt"

Trả về JSON đúng các key sau, không thêm key khác:
{
  "destination": "tên điểm đến, hoặc null nếu không nêu",
  "departDate": "yyyy-MM-dd hoặc null (chỉ khi mô tả nêu ngày hoặc mốc thời gian đủ rõ để tính từ hôm nay)",
  "returnDate": "yyyy-MM-dd hoặc null",
  "numDays": "số nguyên hoặc null",
  "budgetTier": "một trong: economy | moderate | premium | luxury, hoặc null",
  "participants": "số người, số nguyên hoặc null",
  "ageRange": "khoảng tuổi dạng chuỗi, hoặc null",
  "interests": ["chỉ dùng các giá trị: beach, adventure, culture, food, wellness"]
}

Quy tắc:
- Không đoán bừa: không có thông tin thì để null hoặc mảng rỗng.
- "tiết kiệm", "rẻ" là economy; "sang", "5 sao" là luxury; "cao cấp" là premium.
- CHỈ trả về JSON, KHÔNG thêm markdown hay text khác.
- "budgetTier" và "interests" luôn viết bằng tiếng Anh theo đúng danh sách trên, không dịch.
- ${languageInstruction(languageCode)}
''';
  }

  /// Parser thuần cho JSON trích xuất. Key thiếu hoặc sai thì để rỗng.
  @visibleForTesting
  TripData parseExtractedTripData(String text, {String originalPrompt = ''}) {
    final decoded = safeJsonDecode(text);
    final map = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    DateTime? depart = DateTime.tryParse(map['departDate']?.toString() ?? '');
    DateTime? ret = DateTime.tryParse(map['returnDate']?.toString() ?? '');
    final numDays = map['numDays'] is num
        ? (map['numDays'] as num).toInt()
        : int.tryParse(map['numDays']?.toString() ?? '');
    if (depart != null && ret == null && numDays != null && numDays > 0) {
      ret = depart.add(Duration(days: numDays - 1));
    }
    // Chỉ có ngày về mà không có ngày đi thì bỏ, form không dùng được.
    if (depart == null) ret = null;

    DateTime? dateOnly(DateTime? d) =>
        d == null ? null : DateTime(d.year, d.month, d.day);
    depart = dateOnly(depart);
    ret = dateOnly(ret);

    final tier = map['budgetTier']?.toString().trim().toLowerCase() ?? '';
    final participants = map['participants'];
    final participantsStr = participants is num
        ? participants.toInt().toString()
        : (int.tryParse(participants?.toString() ?? '')?.toString() ?? '');
    final interests = TripData.stringList(map['interests'])
        .map((e) => e.trim().toLowerCase())
        .where(MockData.interests.contains)
        .toList();

    return TripData(
      destination: _cleanString(map['destination']),
      departDate: depart,
      returnDate: ret,
      budget: _validTiers.contains(tier) ? tier : '',
      participants: participantsStr,
      ageRange: _cleanString(map['ageRange']),
      aiPrompt: originalPrompt,
      selectedInterests: interests,
    );
  }

  // ── Explore (independent, no TripData needed) ─────────────────────────

  // Chủ đề ngẫu nhiên dùng khi không truyền category.
  static final List<String> _randomExploreThemes = [
    'Thiên đường biển đảo nhiệt đới, làn nước trong xanh và bãi cát trắng hoang sơ',
    'Vùng núi cao hùng vĩ, mây mù giăng lối, đèo dốc hiểm trở và ruộng bậc thang',
    'Cố đô ngàn năm văn hiến, di sản văn hóa thế giới và những góc phố cổ kính',
    'Đô thị sôi động hiện đại, ánh đèn rực rỡ, ẩm thực đường phố và chợ đêm',
    'Nghỉ dưỡng tĩnh lặng giữa thiên nhiên, suối khoáng nóng, rừng thông xanh ngát',
    'Những viên ngọc ẩn (Hidden Gems) hoang sơ, kỳ bí, độc lạ ít người biết đến',
    'Kỳ quan thiên nhiên, quần thể hang động tráng lệ và cảnh quan độc nhất vô nhị',
    'Vùng đất văn hóa bản địa độc đáo, lễ hội sắc màu và ẩm thực phong phú',
  ];

  /// Get trending or randomly discovered travel destinations for free exploration.
  /// Does NOT require any user input, perfect for the Explore tab.
  ///
  /// [limit] number of destinations to return.
  /// [forceRefresh] if true, skips the cache read, draws a new random theme,
  /// and overwrites the same cache key. The theme is intentionally left out
  /// of the cache key so a refresh never adds extra entries.
  /// [category] optional specific travel category / theme.
  /// [languageCode] locale code for language-aware prompts (vi, en, ko).
  Future<List<DestinationSuggestion>> getExploreTrending({
    int limit = 10,
    bool forceRefresh = false,
    String? category,
    String languageCode = 'vi',
  }) async {
    final randomSeed = DateTime.now().millisecondsSinceEpoch % 100000;
    final theme =
        category ??
        _randomExploreThemes[randomSeed % _randomExploreThemes.length];

    final cacheKey = _aiCache.buildKey('explore_trending', {
      'limit': limit,
      'lang': languageCode,
      'category': category ?? '',
    });

    if (!forceRefresh) {
      final cached = _aiCache.get(cacheKey);
      if (cached != null) {
        return _withImages(parseSuggestionsSync(cached));
      }
    }

    final langInst = languageInstruction(languageCode);
    final prompt =
        '''
Bạn là chuyên gia tư vấn du lịch AI hàng đầu. Hãy gợi ý một danh sách $limit điểm đến du lịch ĐỘC ĐÁO, MỚI LẠ và NGẪU NHIÊN theo chủ đề:
👉 "$theme"

Yêu cầu tạo danh sách ngẫu nhiên & tươi mới:
- HÃY ĐA DẠNG HÓA TỐI ĐA các địa điểm, tránh lặp lại các gợi ý cũ!
- Kết hợp cả các điểm đến hấp dẫn tại Việt Nam và các kỳ quan trên thế giới.
- Bao gồm cả những viên ngọc ẩn (Hidden Gems) ít người biết và các điểm đến biểu tượng.
- Giá cả ước tính và số liệu đánh giá phải chân thực, hợp lý.

Trả về JSON array với đúng $limit phần tử, mỗi phần tử:
{
  "name": "Tên địa điểm, Quốc gia",
  "matchPercent": 95,
  "rating": 4.7,
  "reviewCount": 1820,
  "price": "~4.5M VNĐ",
  "aiInsight": "Lý do bất ngờ và hấp dẫn nhất nên khám phá địa điểm này ngay (1-2 câu)",
  "isTopMatch": false
}

Quy tắc:
- matchPercent thể hiện mức độ phù hợp và trending (65-99, sắp xếp giảm dần)
- rating từ 4.2 - 4.9
- reviewCount là ước tính số đánh giá thực tế (300 - 4500)
- price là chi phí ước tính thực tế cho 1 người/chuyến (ghi kèm đơn vị tiền tệ)
- Phần tử đầu tiên có isTopMatch = true
- CHỈ trả về JSON array, KHÔNG thêm markdown hay text khác
- $langInst
''';

    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) return [];

    await _aiCache.put(cacheKey, text);
    return _withImages(parseSuggestionsSync(text));
  }

  // ── Suggestions ──────────────────────────────────────────────────────────

  /// Get AI travel suggestions based on user's trip preferences.
  ///
  /// **Phase 1 (fast, ~1-2s or <100ms on cache):** Returns suggestions immediately.
  ///
  /// **Phase 2 (background):** Call [enrichSuggestionsWithImages] to back-fill
  /// image URLs asynchronously if not already cached.
  ///
  /// [trip] contains destination, budget, interests, dates, etc.
  /// [limit] controls the number of suggestions returned (default 10).
  /// [forceRefresh] if true, bypasses the cache and calls the API.
  Future<List<DestinationSuggestion>> getSuggestions(
    TripData trip, {
    int limit = 10,
    bool forceRefresh = false,
    String languageCode = 'vi',
  }) async {
    // Build cache key from the inputs that actually affect the result
    final cacheKey = _aiCache.buildKey('suggestions', {
      'destination': trip.destination,
      'budget': trip.budget,
      'currency': trip.currency,
      'interests': trip.selectedInterests,
      'limit': limit,
      'lang': languageCode,
      'aiPrompt': trip.aiPrompt.trim(),
      'notes': trip.additionalNotes.trim(),
      'depart': trip.departDate?.toIso8601String() ?? '',
      'return': trip.returnDate?.toIso8601String() ?? '',
      'participants': trip.participants.trim(),
      'ageRange': trip.ageRange.trim(),
    });

    if (!forceRefresh) {
      final cached = _aiCache.get(cacheKey);
      if (cached != null) return parseSuggestionsSync(cached);
    }

    // Cache miss — call Gemini API
    final prompt = buildSuggestionsPrompt(trip, limit, languageCode);
    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) return [];

    await _aiCache.put(cacheKey, text);
    return parseSuggestionsSync(text);
  }

  /// Phase 2: Back-fill image URLs into an existing list of suggestions.
  ///
  /// Call this after [getSuggestions] to enrich results with images in the
  /// background. All images are fetched in parallel via [ImageService].
  Future<List<DestinationSuggestion>> enrichSuggestionsWithImages(
    List<DestinationSuggestion> suggestions,
  ) async {
    final missingNames = suggestions
        .where((s) => s.imageUrl.isEmpty)
        .map((s) => s.name)
        .toList();

    if (missingNames.isEmpty) {
      return suggestions;
    }

    final imageUrls = await ImageService.instance.getImageUrls(missingNames);

    return suggestions.map((s) {
      return DestinationSuggestion(
        name: s.name,
        imageUrl: (s.imageUrl.isNotEmpty)
            ? s.imageUrl
            : (imageUrls[s.name] ?? ''),
        matchPercent: s.matchPercent,
        rating: s.rating,
        reviewCount: s.reviewCount,
        price: s.price,
        aiInsight: s.aiInsight,
        isTopMatch: s.isTopMatch,
      );
    }).toList();
  }

  /// Synchronously parse raw JSON text into DestinationSuggestions.
  /// Ảnh không nằm trong JSON của AI; tra sau bằng [enrichSuggestionsWithImages].
  List<DestinationSuggestion> parseSuggestionsSync(String text) {
    final decoded = safeJsonDecode(text);
    final List<dynamic> jsonList;
    if (decoded is List) {
      jsonList = decoded;
    } else if (decoded is Map) {
      final listValue = decoded.values.firstWhere(
        (v) => v is List,
        orElse: () => null,
      );
      if (listValue != null) {
        jsonList = listValue as List<dynamic>;
      } else {
        throw const FormatException(
          'Phản hồi từ AI không chứa danh sách điểm đến.',
        );
      }
    } else {
      throw const FormatException('Định dạng phản hồi của AI không hợp lệ.');
    }

    final suggestions = jsonList.whereType<Map>().map((e) {
      final rawMap = Map<String, dynamic>.from(e);
      final name = rawMap['name']?.toString() ?? '';
      final map = <String, dynamic>{
        'name': name,
        'matchPercent': (rawMap['matchPercent'] is num)
            ? (rawMap['matchPercent'] as num).toInt()
            : int.tryParse(rawMap['matchPercent']?.toString() ?? '') ?? 0,
        'rating': (rawMap['rating'] is num)
            ? (rawMap['rating'] as num).toDouble()
            : double.tryParse(rawMap['rating']?.toString() ?? '') ?? 0.0,
        'reviewCount': (rawMap['reviewCount'] is num)
            ? (rawMap['reviewCount'] as num).toInt()
            : int.tryParse(rawMap['reviewCount']?.toString() ?? '') ?? 0,
        'price': rawMap['price']?.toString() ?? '',
        'aiInsight': rawMap['aiInsight']?.toString() ?? '',
        'isTopMatch': rawMap['isTopMatch'] is bool
            ? rawMap['isTopMatch'] as bool
            : (rawMap['isTopMatch']?.toString().toLowerCase() == 'true'),
      };
      return DestinationSuggestion.fromJson(map, '');
    }).toList();

    // Mark the first item as top match if none is flagged.
    if (suggestions.isNotEmpty && !suggestions.any((s) => s.isTopMatch)) {
      final top = suggestions.first;
      suggestions[0] = DestinationSuggestion(
        name: top.name,
        imageUrl: top.imageUrl,
        matchPercent: top.matchPercent,
        rating: top.rating,
        reviewCount: top.reviewCount,
        price: top.price,
        aiInsight: top.aiInsight,
        isTopMatch: true,
      );
    }

    return suggestions;
  }

  /// Formats the budget tier into clear, realistic guidance for the AI model.
  static String _describeBudgetTier(String tier, String currency) {
    final lower = tier.toLowerCase();
    if (lower == 'economy' ||
        lower.contains('bình dân') ||
        lower.contains('알뜰')) {
      return 'Phân khúc Bình dân / Tiết kiệm: '
          'Lựa chọn homestay/khách sạn bình dân 1-2 sao, quán ăn địa phương/đường phố, '
          'di chuyển bằng xe máy/xe buýt/tàu. Ước tính chi phí thực tế: ~1.5M - 3.5M $currency cho chuyến 3 ngày trong nước, '
          'hoặc tương đương \$150-\$350 $currency cho chuyến quốc tế.';
    }
    if (lower == 'premium' ||
        lower.contains('cao cấp') ||
        lower.contains('고급')) {
      return 'Phân khúc Cao cấp: '
          'Lựa chọn khách sạn 4-5 sao / resort cao cấp, nhà hàng chất lượng, '
          'xe đưa đón riêng / chuyến bay giờ đẹp, tour trải nghiệm chất lượng cao. Ước tính chi phí thực tế: ~9M - 18M $currency cho chuyến 3 ngày trong nước, '
          'hoặc tương đương \$900-\$2200 $currency cho chuyến quốc tế.';
    }
    if (lower == 'luxury' ||
        lower.contains('hạng sang') ||
        lower.contains('럭셔리')) {
      return 'Phân khúc Hạng sang / Siêu sang: '
          'Lựa chọn resort 5 sao quốc tế / villa riêng tư sang trọng bậc nhất, ẩm thực fine dining / Michelin, '
          'dịch vụ VIP / du thuyền / trải nghiệm độc quyền. Ước tính chi phí thực tế: ~22M - 60M+ $currency cho chuyến 3 ngày trong nước, '
          'hoặc tương đương \$2500-\$7000+ $currency cho chuyến quốc tế.';
    }
    // Default: moderate / trung bình
    return 'Phân khúc Trung bình / Tiêu chuẩn: '
        'Lựa chọn khách sạn 3 sao / boutique hotel tiện nghi, nhà hàng đặc sản địa phương sạch sẽ, '
        'di chuyển taxi / xe công nghệ thuận tiện. Ước tính chi phí thực tế: ~4M - 8M $currency cho chuyến 3 ngày trong nước, '
        'hoặc tương đương \$450-\$850 $currency cho chuyến quốc tế.';
  }

  /// Builds the suggestions prompt. Public for testing only.
  @visibleForTesting
  String buildSuggestionsPrompt(TripData trip, int limit, String languageCode) {
    final hasTripDescription = trip.aiPrompt.trim().isNotEmpty;

    final interests = trip.selectedInterests.isNotEmpty
        ? trip.selectedInterests.join(', ')
        : 'du lịch tổng hợp';

    final destination = trip.destination.isNotEmpty
        ? trip.destination
        : hasTripDescription
        ? 'chưa xác định, hãy tự suy ra điểm đến phù hợp từ mô tả chuyến đi bên dưới'
        : 'Việt Nam';

    final budgetDescription = _describeBudgetTier(trip.budget, trip.currency);

    final dateInfo = trip.departDate != null && trip.returnDate != null
        ? 'từ ${_formatDate(trip.departDate!)} đến ${_formatDate(trip.returnDate!)}'
        : hasTripDescription
        ? 'linh hoạt (nếu mô tả chuyến đi nêu thời gian, hãy dùng thời gian đó)'
        : 'linh hoạt';

    final unknownHint = hasTripDescription
        ? 'không rõ (suy ra từ mô tả chuyến đi nếu có)'
        : 'không rõ';

    final additionalNotes = trip.additionalNotes.isNotEmpty
        ? '\nYêu cầu thêm: ${trip.additionalNotes}'
        : '';

    final aiPromptExtra = hasTripDescription
        ? '\nMô tả chuyến đi: ${trip.aiPrompt.trim()}'
        : '';

    final langInst = languageInstruction(languageCode);

    return '''
Bạn là chuyên gia tư vấn du lịch AI hàng đầu. Hãy gợi ý $limit điểm đến du lịch phù hợp nhất dựa trên thông tin thực tế.

Thông tin người dùng:
- Điểm đến mong muốn: $destination
- Mức ngân sách: $budgetDescription
- Sở thích: $interests
- Thời gian: $dateInfo
- Số người: ${trip.participants.isNotEmpty ? trip.participants : unknownHint}
- Độ tuổi: ${trip.ageRange.isNotEmpty ? trip.ageRange : unknownHint}$additionalNotes$aiPromptExtra

Trả về JSON array với đúng $limit phần tử, mỗi phần tử có cấu trúc:
{
  "name": "Tên địa điểm, Quốc gia",
  "matchPercent": 85,
  "rating": 4.6,
  "reviewCount": 1420,
  "price": "~4.5M ${trip.currency}",
  "aiInsight": "Nhận xét thực tế và hữu ích về sự phù hợp với chuyến đi của người dùng",
  "isTopMatch": false
}

Quy tắc quan trọng:
- price: Phải là con số thực tế theo giá thị trường hiện tại (ước tính chi phí tổng cho 1 người/chuyến đi) tương ứng với phân khúc ngân sách đã chọn và vị trí địa lý của điểm đến (ghi kèm đơn vị ${trip.currency}).
- matchPercent: Từ 65-98, sắp xếp giảm dần theo matchPercent.
- rating: Đánh giá thực tế từ 4.1 - 4.9 sao.
- reviewCount: Số lượng đánh giá thực tế ước tính (thường từ 250 đến 4500 đánh giá).
- aiInsight: Viết cô đọng, sắc sảo, nêu rõ điểm nổi bật vì sao điểm đến này đáng đi trong mùa/phân khúc này.
- Chỉ có đúng 1 phần tử đầu tiên có isTopMatch = true.
- CHỈ trả về JSON array, KHÔNG thêm markdown hay text khác.
- $langInst
''';
  }

  // ── Destination Detail ────────────────────────────────────────────────

  /// Get detailed information about a specific destination.
  ///
  /// [forceRefresh] if true, bypasses the cache.
  Future<DestinationDetail> getDestinationDetail(
    String destinationName,
    TripData trip, {
    bool forceRefresh = false,
    String languageCode = 'vi',
  }) async {
    final cacheKey = _aiCache.buildKey('detail', {
      'name': destinationName,
      'lang': languageCode,
      'aiPrompt': trip.aiPrompt.trim(),
      'budget': trip.budget,
      'currency': trip.currency,
      'depart': trip.departDate?.toIso8601String() ?? '',
      'return': trip.returnDate?.toIso8601String() ?? '',
    });

    // Check cache
    if (!forceRefresh) {
      final cached = _aiCache.get(cacheKey);
      if (cached != null) return _parseDetail(cached, destinationName);
    }

    // Cache miss — call Gemini API
    final prompt = buildDetailPrompt(destinationName, trip, languageCode);
    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Không nhận được phản hồi từ AI.');
    }

    // Save to cache
    await _aiCache.put(cacheKey, text);

    return _parseDetail(text, destinationName);
  }

  /// Landmark AI đặt tên thường không có trang Wikipedia riêng. Ô nào rỗng
  /// thì dùng ảnh chính của điểm đến để gallery không có ô trống. Ảnh chính
  /// cũng rỗng thì giữ nguyên, widget chung sẽ vẽ fallback.
  @visibleForTesting
  static List<DestinationLandmarkPhoto> fillEmptyLandmarkImages(
    List<DestinationLandmarkPhoto> gallery,
    String mainImageUrl,
  ) {
    if (mainImageUrl.isEmpty) return gallery;
    return [
      for (final photo in gallery)
        photo.imageUrl.isEmpty
            ? DestinationLandmarkPhoto(
                title: photo.title,
                imageUrl: mainImageUrl,
              )
            : photo,
    ];
  }

  /// Parse raw JSON text into a DestinationDetail with image and photo gallery.
  Future<DestinationDetail> _parseDetail(
    String text,
    String destinationName,
  ) async {
    final Map<String, dynamic> json =
        safeJsonDecode(text) as Map<String, dynamic>;
    final name = json['name'] as String? ?? destinationName;
    final imageUrl = await ImageService.instance.getImageUrl(name);

    final rawLandmarks =
        (json['galleryLandmarks'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    final gallery = await ImageService.instance.getLandmarkPhotos(
      name,
      rawLandmarks.isNotEmpty
          ? rawLandmarks
          : [name, '$name beach', '$name city', '$name mountain'],
    );

    return DestinationDetail.fromJson(
      json,
      imageUrl,
      gallery: fillEmptyLandmarkImages(gallery, imageUrl),
    );
  }

  /// Builds the destination detail prompt. Public for testing only.
  @visibleForTesting
  String buildDetailPrompt(
    String destinationName,
    TripData trip,
    String languageCode,
  ) {
    final hasTripDescription = trip.aiPrompt.trim().isNotEmpty;

    final dateInfo = trip.departDate != null && trip.returnDate != null
        ? '${_formatDateShort(trip.departDate!)} - ${_formatDateShort(trip.returnDate!)}'
        : 'Linh hoạt';

    final tripDescription = hasTripDescription
        ? '\nMô tả chuyến đi của người dùng: ${trip.aiPrompt.trim()}'
        : '';

    final dateRule = hasTripDescription && trip.departDate == null
        ? '\n- Nếu mô tả chuyến đi nêu thời gian cụ thể, dùng thời gian đó cho dateRange thay vì "Linh hoạt".'
        : '';

    final budgetDescription = _describeBudgetTier(trip.budget, trip.currency);
    final langInst = languageInstruction(languageCode);

    return '''
Bạn là chuyên gia tư vấn du lịch AI. Hãy cung cấp thông tin chi tiết, ước tính chi phí thực tế và các địa danh biểu tượng cụ thể cho điểm đến "$destinationName".

Mức ngân sách & phân khúc: $budgetDescription
Thời gian dự kiến: $dateInfo$tripDescription

Trả về JSON object với cấu trúc:
{
  "name": "$destinationName",
  "location": "Tỉnh/Vùng, Quốc gia",
  "tags": ["🌿 Nghỉ dưỡng", "🏖️ Biển đảo", "🤿 Lặn biển", "🌅 Cảnh đẹp"],
  "weather": "Nắng đẹp, 28-32°C",
  "dateRange": "$dateInfo",
  "totalBudget": "~4.8M ${trip.currency}",
  "galleryLandmarks": [
    "Tên địa danh/thắng cảnh nổi tiếng 1 cụ thể của $destinationName",
    "Tên địa danh/thắng cảnh nổi tiếng 2 cụ thể của $destinationName",
    "Tên địa danh/thắng cảnh nổi tiếng 3 cụ thể của $destinationName",
    "Tên địa danh/thắng cảnh nổi tiếng 4 cụ thể của $destinationName"
  ],
  "budgetBreakdown": [
    {"label": "Transport", "amount": "1.8M ${trip.currency}", "fraction": 0.38, "icon": "flight"},
    {"label": "Stay", "amount": "1.5M ${trip.currency}", "fraction": 0.31, "icon": "hotel"},
    {"label": "Food", "amount": "1.0M ${trip.currency}", "fraction": 0.21, "icon": "restaurant"},
    {"label": "Activities", "amount": "0.5M ${trip.currency}", "fraction": 0.10, "icon": "kayaking"}
  ]
}

Quy tắc:
- galleryLandmarks: 4 địa danh/thắng cảnh/công trình nổi tiếng và đặc trưng nhất của $destinationName (ví dụ: Đà Nẵng thì là Cầu Vàng Bà Nà Hills, Bãi biển Mỹ Khê, Cầu Rồng, Bán đảo Sơn Trà).
- totalBudget: Phải là ước tính chi phí thực tế cho 1 người/chuyến đi dựa trên phân khúc ngân sách đã chọn và chi phí thực tế của $destinationName.
- budgetBreakdown: Phân chia chi phí thực tế thành 4 nhóm (Transport - Đi lại, Stay - Lưu trú, Food - Ăn uống, Activities - Vui chơi/Tham quan). Tổng 4 khoản tiền phải bằng đúng totalBudget, và tổng fraction = 1.0.
- icon chỉ dùng: flight, hotel, restaurant, kayaking
- tags: 4 thẻ ngắn gọn, đặc trưng nhất cho điểm đến, có kèm emoji.
- weather: Dự báo thời tiết thực tế theo mùa của điểm đến.
- Mọi trường tiền tệ phải ghi số tiền kèm mã ${trip.currency}.
- CHỈ trả về JSON object, KHÔNG thêm markdown hay text khác.$dateRule
- $langInst
''';
  }

  // ── Itinerary Plan ────────────────────────────────────────────────────

  /// Generate a day-by-day itinerary plan for a destination.
  ///
  /// [numDays] number of days in the itinerary.
  /// [limit] max activities per day (default 4).
  /// [forceRefresh] if true, bypasses the cache.
  Future<ItineraryPlan> getItineraryPlan(
    String destinationName,
    int numDays,
    TripData trip, {
    int limit = 4,
    bool forceRefresh = false,
    String languageCode = 'vi',
    String? additionalInstruction,
  }) async {
    final cacheKey = _aiCache.buildKey('itinerary', {
      'name': destinationName,
      'numDays': numDays,
      'limit': limit,
      'lang': languageCode,
      'instruction': additionalInstruction ?? '',
      'aiPrompt': trip.aiPrompt.trim(),
      'depart': trip.departDate?.toIso8601String() ?? '',
      'return': trip.returnDate?.toIso8601String() ?? '',
    });

    // Check cache
    if (!forceRefresh) {
      final cached = _aiCache.get(cacheKey);
      if (cached != null) {
        final Map<String, dynamic> json =
            safeJsonDecode(cached) as Map<String, dynamic>;
        return ItineraryPlan.fromJson(json);
      }
    }

    // Cache miss — call Gemini API
    final prompt = buildItineraryPrompt(
      destinationName,
      numDays,
      trip,
      limit,
      languageCode,
      additionalInstruction,
    );
    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('noAiResponse');
    }

    // Save to cache
    await _aiCache.put(cacheKey, text);

    try {
      final Map<String, dynamic> json =
          safeJsonDecode(text) as Map<String, dynamic>;
      return ItineraryPlan.fromJson(json);
    } catch (e, stackTrace) {
      debugPrint('=== JSON Parse Error ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('========================');
      rethrow;
    }
  }

  /// Builds the itinerary prompt. Public for testing only.
  @visibleForTesting
  String buildItineraryPrompt(
    String destinationName,
    int numDays,
    TripData trip,
    int limit,
    String languageCode,
    String? additionalInstruction,
  ) {
    final hasTripDescription = trip.aiPrompt.trim().isNotEmpty;

    final dateInfo = trip.departDate != null && trip.returnDate != null
        ? '${_formatDateShort(trip.departDate!)} - ${_formatDateShort(trip.returnDate!)}'
        : 'Linh hoạt';

    final tripDescription = hasTripDescription
        ? '\nMô tả chuyến đi của người dùng: ${trip.aiPrompt.trim()}'
        : '';

    final dayCountInstruction = hasTripDescription && trip.departDate == null
        ? '\nNếu mô tả chuyến đi nêu số ngày cụ thể, hãy lên kế hoạch đúng số ngày đó (tối đa 7 ngày) thay vì $numDays ngày.'
        : '';

    final languageName = languageCode == 'vi'
        ? 'Vietnamese'
        : languageCode == 'ko'
        ? 'Korean'
        : 'English';

    return '''
Bạn là chuyên gia du lịch AI. Hãy lên kế hoạch du lịch chi tiết $numDays ngày tại "$destinationName".

Thời gian: $dateInfo$tripDescription$dayCountInstruction

${additionalInstruction == null || additionalInstruction.trim().isEmpty ? '' : 'Ưu tiên điều chỉnh: ${additionalInstruction.trim()}'}

Trả về JSON object với cấu trúc:
{
  "destinationName": "$destinationName",
  "dateRange": "$dateInfo",
  "days": [
    {
      "dayNumber": 1,
      "title": "Day 1: Arrival & Coastal Relaxation",
      "subtitle": "Experience the serene beauty of the islands.",
      "items": [
        {
          "time": "09:00 AM",
          "title": "Arrival at Airport",
          "description": "Mô tả ngắn gọn về hoạt động",
          "icon": "flight_land"
        }
      ]
    }
  ],
  "proTip": "Mẹo hữu ích cho chuyến đi"
}

- Mỗi ngày có tối đa $limit hoạt động
- Tổng cộng $numDays ngày
- title: "Day X: Tiêu đề ngắn" — subtitle: 1 câu mô tả
- items.time: "HH:MM AM/PM" — items.icon: flight_land|hotel|restaurant|beach_access
- items.description: 1 câu, ngắn gọn
- proTip: 1 mẹo thực tế
- Viết toàn bộ nội dung bằng $languageName
- CHỈ trả về JSON object, KHÔNG thêm markdown hay text khác
''';
  }

  // ── Chat ─────────────────────────────────────────────────────────────────

  /// Send a chat message to the AI travel assistant and receive a response.
  ///
  /// [message] is the user's current message.
  /// [history] is the prior conversation (excluding the current message).
  /// [languageCode] locale code for language-aware response (vi, en, ko).
  Future<String> chat(
    String message, {
    required List<ChatMessage> history,
    String languageCode = 'vi',
    String? destinationName,
  }) async {
    final langInst = chatLanguageInstruction(languageCode);

    // Build conversation turns from history
    final contents = <Content>[];

    // System context as first user turn
    contents.add(
      Content.text(
        'You are a friendly AI travel assistant. Help users plan trips, '
        'discover destinations, and answer travel-related questions. '
        'Be concise, helpful, and enthusiastic about travel. '
        'Reply only with natural, plain text. Never return JSON, code fences, '
        'a schema, or a list of data types. '
        '${destinationName == null || destinationName.isEmpty ? '' : 'The user is currently viewing $destinationName; keep the answer grounded in that destination. '} '
        '$langInst',
      ),
    );

    // Add history as alternating user/model turns
    for (final msg in history) {
      if (msg.isUser) {
        contents.add(Content.text(msg.text));
      } else {
        contents.add(Content('model', [TextPart(msg.text)]));
      }
    }

    // Add current user message
    contents.add(Content.text(message));

    // Use a text-only model config for chat (not JSON mode)
    final chatModel = _createModel(
      generationConfig: GenerationConfig(
        responseMimeType: 'text/plain',
        temperature: 0.8,
        maxOutputTokens: 3072,
      ),
    );

    final response = await chatModel.generateContent(contents);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('noAiResponse');
    }
    return text.trim();
  }

  /// Send a chat message with AI Function Calling capabilities enabled.
  ///
  /// Gemini can detect user intent and return function call requests for:
  /// - `navigateToPage` (saved, planner, explore)
  /// - `createTravelPlan` (destination, durationDays, budgetTier, interests, notes)
  Future<AIFunctionCallResult> chatWithFunctionCalling(
    String message, {
    required List<ChatMessage> history,
    String languageCode = 'vi',
    String? destinationName,
  }) async {
    final langInst = chatLanguageInstruction(languageCode);

    final contents = <Content>[];

    // System instruction defining AI persona and tool guidance
    contents.add(
      Content.text(
        'You are an intelligent AI travel assistant for the Voyz app. '
        'Help users plan trips, discover destinations, navigate screens, compare places, check travel timing, read cultural guides, and answer travel questions. '
        'You have access to tools for web app actions: '
        '1. Use "navigateToPage" tool when user asks to open/go to "saved", "planner", "explore", or "ai_tools" page. '
        '2. Use "createTravelPlan" tool when user asks to plan a trip or build an itinerary for a destination. '
        '3. Use "compareDestinations" tool when user asks to compare 2 or 3 destinations. '
        '4. Use "getBestTimeToTravel" tool when user asks when is the best time or month to visit a destination. '
        '5. Use "getCulturalTips" tool when user asks for local etiquette, do\'s & don\'ts, phrases, or cultural advice for a destination. '
        '6. Use "viewDestinationDetail" tool when user asks to see details, landmarks, or guide for a specific destination. '
        'Be helpful, concise, friendly, and enthusiastic. '
        '${destinationName == null || destinationName.isEmpty ? '' : 'The user is currently viewing $destinationName. '} '
        '$langInst',
      ),
    );

    // Add prior conversation history
    for (final msg in history) {
      if (msg.isUser) {
        contents.add(Content.text(msg.text));
      } else {
        contents.add(Content('model', [TextPart(msg.text)]));
      }
    }

    // Add current user prompt
    contents.add(Content.text(message));

    final tools = _buildFunctionCallingTools();
    final modelWithTools = GenerativeModel(
      model: modelName,
      apiKey: requireApiKey(dotenv.env['GEMINI_API_KEY']),
      tools: tools,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
    );

    final response = await modelWithTools.generateContent(contents);

    String? functionName;
    Map<String, dynamic>? arguments;

    final functionCalls = response.functionCalls.toList();
    if (functionCalls.isNotEmpty) {
      final call = functionCalls.first;
      functionName = call.name;
      arguments = Map<String, dynamic>.from(call.args);
    }

    var text = response.text?.trim() ?? '';
    if (text.isEmpty) {
      if (functionName == 'navigateToPage') {
        final page = arguments?['page']?.toString().toLowerCase() ?? '';
        final pageLabel = switch (page) {
          'saved' => 'Chuyến đi đã lưu (Saved)',
          'planner' => 'Lên kế hoạch (Planner)',
          'explore' => 'Khám phá (Explore)',
          'ai_tools' => 'Trung tâm công cụ AI (AI Tools)',
          _ => page,
        };
        text = 'Đang chuyển sang trang $pageLabel giúp bạn...';
      } else if (functionName == 'createTravelPlan') {
        final dest = arguments?['destination']?.toString() ?? 'điểm đến';
        final days = arguments?['durationDays'];
        final daysText = days != null ? ' ($days ngày)' : '';
        text = 'Đã khởi tạo kế hoạch du lịch $dest$daysText cho bạn! Đang mở trang lịch trình...';
      } else if (functionName == 'compareDestinations') {
        final raw = arguments?['destinations'];
        final destList = TripData.stringList(raw);
        final dests = destList.join(' và ');
        text = 'Đang chuẩn bị bảng so sánh chi tiết cho ${dests.isNotEmpty ? dests : "các điểm đến"}...';
      } else if (functionName == 'getBestTimeToTravel') {
        final dest = arguments?['destination']?.toString() ?? 'điểm đến';
        text = 'Đang phân tích thời điểm lý tưởng nhất để du lịch $dest...';
      } else if (functionName == 'getCulturalTips') {
        final dest = arguments?['destination']?.toString() ?? 'điểm đến';
        text = 'Đang tổng hợp hướng dẫn văn hóa và mẹo ứng xử tại $dest...';
      } else if (functionName == 'viewDestinationDetail') {
        final dest = arguments?['destination']?.toString() ?? 'điểm đến';
        text = 'Đang mở thông tin chi tiết về $dest...';
      } else {
        text = 'Tôi đã nhận được yêu cầu của bạn.';
      }
    }

    return AIFunctionCallResult(
      responseText: text,
      functionName: functionName,
      arguments: arguments,
    );
  }

  /// Builds tools for AI Function Calling (Page Navigation & Travel Planning & AI Tools).
  List<Tool> _buildFunctionCallingTools() {
    return [
      Tool(
        functionDeclarations: [
          FunctionDeclaration(
            'navigateToPage',
            'Switch or navigate screen view to one of the main app pages: "saved" (trang đã lưu), "planner" (trang lên kế hoạch), "explore" (trang khám phá), or "ai_tools" (trung tâm công cụ AI). Use this tool whenever user asks to open or go to these screens.',
            Schema.object(
              properties: {
                'page': Schema.string(
                  description: 'Target page ID: "saved", "planner", "explore", or "ai_tools"',
                ),
              },
              requiredProperties: ['page'],
            ),
          ),
          FunctionDeclaration(
            'createTravelPlan',
            'Create or generate a travel itinerary plan for a specific destination with parameters like destination name, duration in days, budget tier, travel interests, and notes. Use this tool whenever user asks to plan a trip or build an itinerary.',
            Schema.object(
              properties: {
                'destination': Schema.string(
                  description: 'Destination name, e.g., Đà Lạt, Phú Quốc, Tokyo, Paris, Sapa',
                ),
                'durationDays': Schema.integer(
                  description: 'Duration of the trip in days (e.g. 3, 5, 7)',
                  nullable: true,
                ),
                'budgetTier': Schema.string(
                  description: 'Budget tier: "budget", "moderate", or "luxury"',
                  nullable: true,
                ),
                'interests': Schema.array(
                  description: 'List of interest tags, e.g. ["beach", "food", "culture", "adventure", "wellness"]',
                  items: Schema.string(),
                  nullable: true,
                ),
                'notes': Schema.string(
                  description: 'Additional travel notes or special preferences',
                  nullable: true,
                ),
              },
              requiredProperties: ['destination'],
            ),
          ),
          FunctionDeclaration(
            'compareDestinations',
            'Compare 2 or 3 travel destinations side-by-side by cost, weather, food, and activities. Use this tool whenever user asks to compare two or three destinations (e.g. compare Da Lat and Sapa).',
            Schema.object(
              properties: {
                'destinations': Schema.array(
                  description: 'List of 2 to 3 destination names to compare, e.g. ["Đà Lạt", "Sapa"]',
                  items: Schema.string(),
                ),
              },
              requiredProperties: ['destinations'],
            ),
          ),
          FunctionDeclaration(
            'getBestTimeToTravel',
            'Analyze the best month, season, weather, and practical travel tips for a destination. Use this tool whenever user asks when is the best time to visit a destination.',
            Schema.object(
              properties: {
                'destination': Schema.string(
                  description: 'Destination name, e.g., Nha Trang, Đà Lạt, Tokyo',
                ),
              },
              requiredProperties: ['destination'],
            ),
          ),
          FunctionDeclaration(
            'getCulturalTips',
            'Get local cultural etiquette, do\'s & don\'ts, essential local phrases, and temple/dining rules for a destination. Use this tool whenever user asks about culture, etiquette, or rules for a destination.',
            Schema.object(
              properties: {
                'destination': Schema.string(
                  description: 'Destination name, e.g., Tokyo, Bali, Kyoto',
                ),
              },
              requiredProperties: ['destination'],
            ),
          ),
          FunctionDeclaration(
            'viewDestinationDetail',
            'View detailed information, landmark photo gallery, and travel guide for a specific destination. Use this tool whenever user asks to see details or view information for a destination.',
            Schema.object(
              properties: {
                'destination': Schema.string(
                  description: 'Destination name, e.g., Phú Quốc, Đà Nẵng, Paris',
                ),
              },
              requiredProperties: ['destination'],
            ),
          ),
        ],
      ),
    ];
  }


  // ── Compare Destinations ──────────────────────────────────────────────────

  /// Compare 2-3 travel destinations side by side using AI.
  ///
  /// [destinations] list of 2-3 destination names to compare.
  /// [languageCode] locale code for language-aware response (vi, en, ko).
  Future<DestinationComparison> compareDestinations(
    List<String> destinations, {
    String languageCode = 'vi',
  }) async {
    final cacheKey = _aiCache.buildKey('comparison', {
      'destinations': destinations,
      'lang': languageCode,
    });

    final cached = _aiCache.get(cacheKey);
    if (cached != null) {
      final Map<String, dynamic> json =
          safeJsonDecode(cached) as Map<String, dynamic>;
      return DestinationComparison.fromJson(json);
    }

    final langInst = languageInstruction(languageCode);
    final destList = destinations.map((d) => '"$d"').join(', ');

    final prompt =
        '''
Bạn là chuyên gia du lịch AI. Hãy so sánh các điểm đến sau: $destList.

Trả về JSON object với cấu trúc:
{
  "destinations": [
    {
      "name": "Tên điểm đến",
      "summary": "Mô tả ngắn 1-2 câu",
      "overallScore": 8.5,
      "pros": ["Ưu điểm 1", "Ưu điểm 2", "Ưu điểm 3"],
      "cons": ["Nhược điểm 1", "Nhược điểm 2"]
    }
  ],
  "recommendation": "Đề xuất tổng quan từ AI",
  "aspects": [
    {
      "label": "Chi phí",
      "icon": "attach_money",
      "details": [
        {"destination": "Tên điểm đến", "value": "Thấp", "score": 8}
      ]
    }
  ]
}

Quy tắc:
- destinations: thông tin chi tiết cho mỗi điểm đến
- overallScore: 0.0-10.0
- pros/cons: 3-4 điểm mỗi loại
- aspects: 4-5 tiêu chí so sánh (Chi phí, Thời tiết, Ẩm thực, Hoạt động, An toàn)
- icon chỉ dùng: attach_money, wb_sunny, restaurant, local_activity, security
- recommendation: 2-3 câu tóm tắt điểm đến nào phù hợp nhất và tại sao
- $langInst
- CHỈ trả về JSON object, KHÔNG thêm markdown hay text khác
''';

    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('noAiResponse');
    }

    await _aiCache.put(cacheKey, text);

    final Map<String, dynamic> json =
        safeJsonDecode(text) as Map<String, dynamic>;
    return DestinationComparison.fromJson(json);
  }

  // ── Best Time to Travel ───────────────────────────────────────────────────

  /// Get AI analysis of the best time to travel to a destination.
  ///
  /// [destination] the destination name to analyze.
  /// [languageCode] locale code for language-aware response (vi, en, ko).
  Future<BestTimeTravel> getBestTimeToTravel(
    String destination, {
    String languageCode = 'vi',
  }) async {
    final cacheKey = _aiCache.buildKey('best_time', {
      'dest': destination,
      'lang': languageCode,
    });

    // Check cache
    final cached = _aiCache.get(cacheKey);
    if (cached != null) {
      final Map<String, dynamic> json =
          safeJsonDecode(cached) as Map<String, dynamic>;
      return BestTimeTravel.fromJson(json);
    }

    final langInst = languageInstruction(languageCode);

    final prompt =
        '''
Bạn là chuyên gia du lịch AI. Hãy phân tích thời điểm tốt nhất để du lịch đến "$destination".

Trả về JSON object với cấu trúc:
{
  "destination": "$destination",
  "summary": "Tóm tắt tổng quan về thời điểm du lịch tốt nhất",
  "bestMonth": "Tháng 3",
  "monthlyData": [
    {
      "month": "Tháng 1",
      "temperature": "25-30°C",
      "rainfall": "Thấp",
      "suitabilityScore": 7,
      "highlight": "Lễ hội năm mới"
    }
  ],
  "seasons": [
    {
      "name": "Mùa khô",
      "period": "Tháng 11 - Tháng 4",
      "description": "Thời tiết khô ráo, ít mưa",
      "rating": 5
    }
  ],
  "tips": [
    {
      "icon": "lightbulb",
      "title": "Đặt phòng sớm",
      "description": "Đặt phòng trước 2-3 tháng vào mùa cao điểm"
    }
  ]
}

Quy tắc:
- monthlyData: 12 tháng trong năm
- suitabilityScore: 1-10 (10 là tốt nhất)
- seasons: 2-4 mùa phù hợp với khí hậu địa phương
- season.rating: 1-5 sao
- tips: 3-5 mẹo thực tế
- tip.icon chỉ dùng: lightbulb, event, local_offer, warning, check_circle
- $langInst
- CHỈ trả về JSON object, KHÔNG thêm markdown hay text khác
''';

    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('noAiResponse');
    }

    // Save to cache
    await _aiCache.put(cacheKey, text);

    final Map<String, dynamic> json =
        safeJsonDecode(text) as Map<String, dynamic>;
    return BestTimeTravel.fromJson(json);
  }

  // ── Cultural Tips ──────────────────────────────────────────────────────

  /// Get AI-generated cultural tips for a specific destination.
  ///
  /// Returns customs, do's & don'ts, basic phrases, dining etiquette,
  /// and sacred site guidelines.
  Future<CulturalTips> getCulturalTips(
    String destinationName, {
    bool forceRefresh = false,
    String languageCode = 'vi',
  }) async {
    final cacheKey = _aiCache.buildKey('cultural_tips', {
      'name': destinationName,
      'lang': languageCode,
    });

    // Check cache
    if (!forceRefresh) {
      final cached = _aiCache.get(cacheKey);
      if (cached != null) return _parseCulturalTips(cached, destinationName);
    }

    // Cache miss — call Gemini API
    final prompt = _buildCulturalTipsPrompt(destinationName, languageCode);
    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('noAiResponse');
    }

    // Save to cache
    await _aiCache.put(cacheKey, text);
    return _parseCulturalTips(text, destinationName);
  }

  Future<CulturalTips> _parseCulturalTips(
    String text,
    String destinationName,
  ) async {
    final Map<String, dynamic> json =
        safeJsonDecode(text) as Map<String, dynamic>;
    final name = json['destinationName'] as String? ?? destinationName;
    final imageUrl = await ImageService.instance.getImageUrl(name);
    json['imageUrl'] = imageUrl;
    return CulturalTips.fromJson(json);
  }

  String _buildCulturalTipsPrompt(String destinationName, String languageCode) {
    final langInst = languageInstruction(languageCode);

    return '''
Bạn là chuyên gia văn hóa du lịch AI. Hãy cung cấp hướng dẫn văn hóa chi tiết cho điểm đến "$destinationName".

Trả về JSON object với cấu trúc chính xác sau:
{
  "destinationName": "$destinationName",
  "dos": [
    "Nên làm 1",
    "Nên làm 2",
    "Nên làm 3",
    "Nên làm 4",
    "Nên làm 5"
  ],
  "donts": [
    "Không nên làm 1",
    "Không nên làm 2",
    "Không nên làm 3",
    "Không nên làm 4",
    "Không nên làm 5"
  ],
  "phrases": [
    {"native": "Xin chào", "translation": "Hello", "pronunciation": "sin chow"},
    {"native": "Cảm ơn", "translation": "Thank you", "pronunciation": "kam uhn"},
    {"native": "Xin lỗi", "translation": "Sorry", "pronunciation": "sin loi"},
    {"native": "Bao nhiêu?", "translation": "How much?", "pronunciation": "bao nyew"},
    {"native": "Tạm biệt", "translation": "Goodbye", "pronunciation": "tam byet"},
    {"native": "Ngon", "translation": "Delicious", "pronunciation": "ngon"}
  ],
  "diningEtiquette": [
    "Quy tắc ăn uống 1",
    "Quy tắc ăn uống 2",
    "Quy tắc ăn uống 3"
  ],
  "sacredSites": [
    "Quy tắc đền/chùa 1",
    "Quy tắc đền/chùa 2",
    "Quy tắc đền/chùa 3"
  ],
  "generalAdvice": "Lời khuyên tổng quan 1-2 câu về văn hóa địa phương"
}

Quy tắc:
- dos: 4-6 điều NÊN làm khi đến $destinationName (giao tiếp, ứng xử, ăn mặc)
- donts: 4-6 điều KHÔNG NÊN làm (kiêng kỵ, sai lầm thường gặp)
- phrases: 5-8 câu giao tiếp cơ bản hữu ích nhất cho khách du lịch
  + native: câu viết bằng ngôn ngữ địa phương
  + translation: dịch sang tiếng Anh
  + pronunciation: phiên âm cách đọc cho người Việt/Anh
- diningEtiquette: 3-4 quy tắc khi ăn uống tại $destinationName
- sacredSites: 3-4 quy tắc khi tham quan đền, chùa, nhà thờ, nơi linh thiêng
- generalAdvice: 1-2 câu tóm tắt lời khuyên văn hóa quan trọng nhất
- Nội dung phải CHÍNH XÁC, cụ thể cho $destinationName, không generic
- $langInst
- CHỈ trả về JSON object, KHÔNG thêm markdown hay text khác
''';
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Safely decodes JSON from AI response, removing any markdown code block wrappers
  /// or leading/trailing non-JSON text.
  ///
  /// Also performs healing for common Gemini model output errors:
  /// - JSON array closed with `}` instead of `]`
  /// - Truncated JSON due to token limits
  dynamic safeJsonDecode(String text) {
    var cleaned = text.trim();

    // Strip markdown code fences
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    // Attempt 1: direct decode
    try {
      return jsonDecode(cleaned);
    } catch (_) {}

    // Attempt 2: heal JSON array closed with } instead of ] (Gemini model bug)
    // e.g. "[{...}, {...}}" → "[{...}, {...}]"
    final healedArray = _healJsonArray(cleaned);
    if (healedArray != cleaned) {
      try {
        return jsonDecode(healedArray);
      } catch (_) {}
    }

    // Attempt 3: heal truncated JSON (AI ran out of tokens mid-output)
    final healedTruncated = _healTruncatedJson(cleaned);
    if (healedTruncated != null) {
      try {
        return jsonDecode(healedTruncated);
      } catch (_) {}
    }

    // Attempt 4: extract innermost JSON object/array from surrounding text
    final startIdx = cleaned.indexOf(RegExp(r'\[|\{'));
    if (startIdx != -1) {
      final sub = cleaned.substring(startIdx);
      final healedSub = _healJsonArray(sub);
      try {
        return jsonDecode(healedSub);
      } catch (_) {}
      // Try extracting just up to the last valid closer
      final endIdx = sub.lastIndexOf(RegExp(r'\]|\}'));
      if (endIdx > 0) {
        final extracted = sub.substring(0, endIdx + 1);
        try {
          return jsonDecode(extracted);
        } catch (_) {}
        // Last resort: heal extracted substring
        try {
          return jsonDecode(_healJsonArray(extracted));
        } catch (_) {}
      }
      // Attempt 5: heal truncated extracted substring
      final healedExtractedTruncated = _healTruncatedJson(sub);
      if (healedExtractedTruncated != null) {
        try {
          return jsonDecode(healedExtractedTruncated);
        } catch (_) {}
      }
    }

    throw const FormatException(
      'Không thể phân tích cú pháp JSON từ phản hồi AI.',
    );
  }

  /// Heals a JSON string where an array was incorrectly closed with `}` instead of `]`.
  /// Gemini sometimes ends a top-level `[` array with `}` due to model quirks.
  String _healJsonArray(String s) {
    final trimmed = s.trim();
    if (!trimmed.startsWith('[')) return trimmed;

    // The array starts with [. Find what character closes it.
    // We walk from the end: if it ends with }, replace with ]
    if (trimmed.endsWith('}')) {
      return '${trimmed.substring(0, trimmed.length - 1)}]';
    }
    return trimmed;
  }

  /// Attempts to heal truncated JSON caused by AI running out of tokens mid-output.
  ///
  /// Strategy: scan from the end and close any unclosed brackets/braces and
  /// strings so the result is valid JSON. Returns `null` if healing fails.
  String? _healTruncatedJson(String s) {
    var trimmed = s.trim();
    if (trimmed.isEmpty) return null;

    // Step 1: Find the last valid closing bracket position
    // Work backwards to find where the JSON becomes incomplete
    var lastValidPos = trimmed.length;
    var inString = false;
    var escaped = false;

    // Scan from end to find incomplete parts
    for (var i = trimmed.length - 1; i >= 0; i--) {
      final c = trimmed[i];
      if (c == '"' && (i == 0 || trimmed[i - 1] != r'\')) {
        inString = !inString;
      }
      // Stop at first complete object/array boundary when not in string
      if (!inString && (c == '}' || c == ']')) {
        lastValidPos = i + 1;
        break;
      }
    }

    // If we didn't find a valid end, try the whole string
    var workStr = lastValidPos < trimmed.length
        ? trimmed.substring(0, lastValidPos)
        : trimmed;

    // Step 2: Clean up trailing fragments
    workStr = workStr.trimRight();

    // Remove trailing incomplete key-value pair
    if (workStr.endsWith(',')) {
      workStr = workStr.substring(0, workStr.length - 1).trimRight();
    }

    // Remove trailing incomplete string value
    final lastQuote = workStr.lastIndexOf('"');
    if (lastQuote != -1) {
      final afterQuote = workStr.substring(lastQuote + 1).trimRight();
      if (afterQuote.isEmpty || afterQuote.endsWith(',')) {
        // String is incomplete, remove it
        workStr = workStr.substring(0, lastQuote);
        // Also remove the key if exists
        final prevComma = workStr.lastIndexOf(',');
        if (prevComma != -1) {
          workStr = workStr.substring(0, prevComma);
        }
      }
    }

    // Step 3: Track open brackets and strings for proper closing
    final stack = <String>[];
    inString = false;
    escaped = false;

    for (var i = 0; i < workStr.length; i++) {
      final c = workStr[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (c == r'\') {
        escaped = true;
        continue;
      }
      if (c == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;

      if (c == '{') {
        stack.add('}');
      } else if (c == '[') {
        stack.add(']');
      } else if (c == '}' || c == ']') {
        if (stack.isNotEmpty) stack.removeLast();
      }
    }

    // Step 4: Close any open strings and brackets
    if (inString) {
      workStr = '$workStr"';
    }

    final closing = stack.reversed.join();
    if (closing.isEmpty) return null;

    final result = '$workStr$closing';

    // Verify it actually parses
    try {
      jsonDecode(result);
      return result;
    } catch (_) {
      return null;
    }
  }
}
