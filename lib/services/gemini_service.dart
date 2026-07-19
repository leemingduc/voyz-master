import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/destination_detail.dart';
import 'package:voyz/models/destination_suggestion.dart';
import 'package:voyz/models/itinerary_plan.dart';

import 'package:voyz/services/cache_service.dart';
import 'package:voyz/services/image_service.dart';

/// Central service for interacting with the Gemini Flash 3 API.
///
/// Prompts include a language instruction so the AI responds in the
/// user's active locale. All methods check Hive cache first; only
/// calls the API on cache miss.
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  final CacheService _cache = CacheService.instance;

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

  GenerativeModel? _model;

  GenerativeModel get _gemini {
    if (_model != null) return _model!;
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('apiKeyNotSet');
    }
    _model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
        maxOutputTokens: 4096, // 10 destination objects need ~3000 tokens; 1200 caused truncation
      ),
    );
    return _model!;
  }

  // ── Explore (independent, no TripData needed) ─────────────────────────

  /// Get trending travel destinations for free exploration.
  /// Does NOT require any user input — perfect for the Explore tab.
  ///
  /// [limit] number of destinations to return.
  /// [forceRefresh] if true, bypasses the cache.
  /// [languageCode] locale code for language-aware prompts (vi, en, ko).
  Future<List<DestinationSuggestion>> getExploreTrending({
    int limit = 10,
    bool forceRefresh = false,
    String languageCode = 'vi',
  }) async {
    final cacheKey = _cache.buildKey('explore_trending', {
      'limit': limit,
      'lang': languageCode,
    });

    if (!forceRefresh) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        return parseSuggestionsSync(cached);
      }
    }

    final langInst = languageInstruction(languageCode);
    final prompt =
        '''
Bạn là chuyên gia du lịch AI. Hãy gợi ý $limit điểm đến du lịch đang thịnh hành nhất hiện nay, bao gồm cả trong nước Việt Nam và quốc tế.

Ưu tiên các điểm đến:
- Đa dạng vùng miền (biển, núi, thành phố, thiên nhiên hoang sơ)
- Phù hợp với mùa du lịch hiện tại
- Có cả địa điểm bình dân và cao cấp
- Mix giữa Việt Nam và quốc tế

Trả về JSON array với đúng $limit phần tử, mỗi phần tử:
{
  "name": "Tên địa điểm, Quốc gia",
  "matchPercent": 85,
  "rating": 4.5,
  "reviewCount": 1200,
  "price": "~4.2M VNĐ",
  "aiInsight": "Lý do nên đến ngay thời điểm này (1-2 câu)",
  "isTopMatch": false
}

Quy tắc:
- matchPercent thể hiện mức độ trending (60-99)
- rating từ 1.0-5.0
- reviewCount là ước tính số đánh giá
- price là chi phí ước tính cho 1 người/chuyến
- aiInsight nên đề cập lý do trending (mùa lễ hội, thời tiết đẹp, ...)
- Phần tử đầu tiên có isTopMatch = true
- CHỈ trả về JSON array, KHÔNG thêm markdown hay text khác
- $langInst
''';

    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) return [];

    await _cache.put(cacheKey, text);
    return parseSuggestionsSync(text);
  }

  // ── Suggestions ──────────────────────────────────────────────────────────

  /// Get AI travel suggestions based on user's trip preferences.
  ///
  /// **Phase 1 (fast, ~1-2s):** Returns text-only suggestions immediately.
  /// Images are left as empty strings so the UI can render right away.
  ///
  /// **Phase 2 (background):** Call [enrichSuggestionsWithImages] to back-fill
  /// image URLs asynchronously while the user is already browsing the results.
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
    final cacheKey = _cache.buildKey('suggestions', {
      'destination': trip.destination,
      'budget': trip.budget,
      'currency': trip.currency,
      'interests': trip.selectedInterests,
      'limit': limit,
      'lang': languageCode,
    });

    // Check cache
    if (!forceRefresh) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        // Cache hit: parse text synchronously, no image fetch needed here.
        // CachedNetworkImage will handle images from its own persistent cache.
        return parseSuggestionsSync(cached);
      }
    }

    // Cache miss — call Gemini API
    final prompt = _buildSuggestionsPrompt(trip, limit, languageCode);
    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) return [];

    // Save to cache
    await _cache.put(cacheKey, text);

    // Phase 1: return text-only list instantly (no image fetching yet).
    return parseSuggestionsSync(text);
  }

  /// Phase 2: Back-fill image URLs into an existing list of suggestions.
  ///
  /// Call this after [getSuggestions] to enrich results with images in the
  /// background. All images are fetched in parallel via [ImageService].
  Future<List<DestinationSuggestion>> enrichSuggestionsWithImages(
    List<DestinationSuggestion> suggestions,
  ) async {
    final names = suggestions.map((s) => s.name).toList();
    final imageUrls = await ImageService.instance.getImageUrls(names);

    return suggestions.map((s) {
      return DestinationSuggestion(
        name: s.name,
        imageUrl: imageUrls[s.name] ?? '',
        matchPercent: s.matchPercent,
        rating: s.rating,
        reviewCount: s.reviewCount,
        price: s.price,
        aiInsight: s.aiInsight,
        isTopMatch: s.isTopMatch,
      );
    }).toList();
  }

  /// Synchronously parse raw JSON text into text-only DestinationSuggestions.
  ///
  /// Images are left as empty strings — they are loaded lazily by the widget
  /// layer (CachedNetworkImage) or back-filled via [enrichSuggestionsWithImages].
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
        throw const FormatException('Phản hồi từ AI không chứa danh sách điểm đến.');
      }
    } else {
      throw const FormatException('Định dạng phản hồi của AI không hợp lệ.');
    }

    final suggestions = jsonList
        .whereType<Map>()
        .map((e) {
          final rawMap = Map<String, dynamic>.from(e);
          final map = <String, dynamic>{
            'name': rawMap['name']?.toString() ?? '',
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
        })
        .toList();

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

  String _buildSuggestionsPrompt(
    TripData trip,
    int limit,
    String languageCode,
  ) {
    final interests = trip.selectedInterests.isNotEmpty
        ? trip.selectedInterests.join(', ')
        : 'du lịch tổng hợp';

    final destination = trip.destination.isNotEmpty
        ? trip.destination
        : 'Việt Nam';

    final budget = trip.budget.isNotEmpty
        ? '${trip.budget} ${trip.currency}'
        : 'không giới hạn';

    final dateInfo = trip.departDate != null && trip.returnDate != null
        ? 'từ ${_formatDate(trip.departDate!)} đến ${_formatDate(trip.returnDate!)}'
        : 'linh hoạt';

    final additionalNotes = trip.additionalNotes.isNotEmpty
        ? '\nYêu cầu thêm: ${trip.additionalNotes}'
        : '';

    final aiPromptExtra = trip.aiPrompt.isNotEmpty
        ? '\nMô tả chuyến đi: ${trip.aiPrompt}'
        : '';

    final langInst = languageInstruction(languageCode);

    return '''
Bạn là chuyên gia du lịch AI. Hãy gợi ý $limit điểm đến du lịch phù hợp nhất.

Thông tin người dùng:
- Điểm đến mong muốn: $destination
- Ngân sách: $budget
- Sở thích: $interests
- Thời gian: $dateInfo
- Số người: ${trip.participants.isNotEmpty ? trip.participants : 'không rõ'}
- Độ tuổi: ${trip.ageRange.isNotEmpty ? trip.ageRange : 'không rõ'}$additionalNotes$aiPromptExtra

Trả về JSON array với đúng $limit phần tử, mỗi phần tử có cấu trúc:
{
  "name": "Tên địa điểm, Quốc gia",
  "matchPercent": 85,
  "rating": 4.5,
  "reviewCount": 120,
  "price": "~4.2M VNĐ",
  "aiInsight": "Nhận xét ngắn gọn về sự phù hợp với người dùng",
  "isTopMatch": false
}

Quy tắc:
- matchPercent từ 60-99, sắp xếp giảm dần theo matchPercent
- rating từ 1.0-5.0
- reviewCount là số lượng đánh giá ước tính
- price phải phù hợp với ngân sách người dùng, ghi bằng ${trip.currency}
- aiInsight phải cụ thể, liên quan đến sở thích và ngân sách người dùng
- Chỉ có 1 phần tử đầu tiên có isTopMatch = true
- CHỈ trả về JSON array, KHÔNG thêm markdown hay text khác
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
    final cacheKey = _cache.buildKey('detail', {
      'name': destinationName,
      'lang': languageCode,
    });

    // Check cache
    if (!forceRefresh) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        return _parseDetail(cached, destinationName);
      }
    }

    // Cache miss — call Gemini API
    final prompt = _buildDetailPrompt(destinationName, trip, languageCode);
    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Không nhận được phản hồi từ AI.');
    }

    // Save to cache
    await _cache.put(cacheKey, text);

    return _parseDetail(text, destinationName);
  }

  /// Parse raw JSON text into a DestinationDetail with image.
  Future<DestinationDetail> _parseDetail(
    String text,
    String destinationName,
  ) async {
    final Map<String, dynamic> json = safeJsonDecode(text) as Map<String, dynamic>;
    final name = json['name'] as String? ?? destinationName;
    final imageUrl = await ImageService.instance.getImageUrl(name);
    return DestinationDetail.fromJson(json, imageUrl);
  }

  String _buildDetailPrompt(
    String destinationName,
    TripData trip,
    String languageCode,
  ) {
    final dateInfo = trip.departDate != null && trip.returnDate != null
        ? '${_formatDateShort(trip.departDate!)} - ${_formatDateShort(trip.returnDate!)}'
        : 'Mar 15 - Mar 18';

    final budget = trip.budget.isNotEmpty
        ? '${trip.budget} ${trip.currency}'
        : '5M VNĐ';

    final langInst = languageInstruction(languageCode);

    return '''
Bạn là chuyên gia du lịch AI. Hãy cung cấp thông tin chi tiết về điểm đến "$destinationName".

Ngân sách người dùng: $budget
Thời gian: $dateInfo

Trả về JSON object với cấu trúc:
{
  "name": "$destinationName",
  "location": "Tỉnh/Vùng",
  "tags": ["🌿 Wellness", "🏖️ Beach", "🤿 Diving", "🌅 Scenic"],
  "weather": "Sunny, 32°C",
  "dateRange": "$dateInfo",
  "totalBudget": "~4.2M VNĐ",
  "budgetBreakdown": [
    {"label": "Transport", "amount": "1.7M", "fraction": 0.40, "icon": "flight"},
    {"label": "Stay", "amount": "1.2M", "fraction": 0.30, "icon": "hotel"},
    {"label": "Food", "amount": "0.8M", "fraction": 0.20, "icon": "restaurant"},
    {"label": "Activities", "amount": "0.5M", "fraction": 0.10, "icon": "kayaking"}
  ]
}

Quy tắc:
- tags: 4 thẻ phù hợp nhất với điểm đến, có emoji phía trước
- weather: thời tiết thực tế cho thời gian du lịch
- budgetBreakdown: chia ngân sách thành 4 loại, tổng fraction = 1.0
- icon chỉ dùng: flight, hotel, restaurant, kayaking
- Số liệu phải phù hợp với ngân sách $budget
- CHỈ trả về JSON object, KHÔNG thêm markdown hay text khác
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
  }) async {
    final cacheKey = _cache.buildKey('itinerary', {
      'name': destinationName,
      'numDays': numDays,
      'lang': languageCode,
    });

    // Check cache
    if (!forceRefresh) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        final Map<String, dynamic> json =
            safeJsonDecode(cached) as Map<String, dynamic>;
        return ItineraryPlan.fromJson(json);
      }
    }

    // Cache miss — call Gemini API
    final prompt = _buildItineraryPrompt(
      destinationName,
      numDays,
      trip,
      limit,
      languageCode,
    );
    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('noAiResponse');
    }

    // Save to cache
    await _cache.put(cacheKey, text);

    final Map<String, dynamic> json = safeJsonDecode(text) as Map<String, dynamic>;
    return ItineraryPlan.fromJson(json);
  }

  String _buildItineraryPrompt(
    String destinationName,
    int numDays,
    TripData trip,
    int limit,
    String languageCode,
  ) {
    final dateInfo = trip.departDate != null && trip.returnDate != null
        ? '${_formatDateShort(trip.departDate!)} - ${_formatDateShort(trip.returnDate!)}'
        : 'MAR 15 - MAR 18';

    final languageName = languageCode == 'vi'
        ? 'Vietnamese'
        : languageCode == 'ko'
        ? 'Korean'
        : 'English';

    return '''
Bạn là chuyên gia du lịch AI. Hãy lên kế hoạch du lịch chi tiết $numDays ngày tại "$destinationName".

Thời gian: $dateInfo

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

Quy tắc:
- Mỗi ngày có tối đa $limit hoạt động
- Tổng cộng $numDays ngày
- title cho mỗi ngày: "Day X: Tiêu đề ngắn gọn" (tiếng Anh)
- subtitle: mô tả ngắn bằng tiếng Anh
- items.time: định dạng "HH:MM AM/PM"
- items.icon chỉ dùng: flight_land, hotel, restaurant, beach_access
- items.description: viết bằng tiếng Anh, 1-2 câu
- proTip: mẹo thực tế bằng tiếng Anh
- Write all human-readable content (title, subtitle, description, proTip) in $languageName
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
    final healed = _healJsonArray(cleaned);
    if (healed != cleaned) {
      try {
        return jsonDecode(healed);
      } catch (_) {}
    }

    // Attempt 3: extract innermost JSON object/array from surrounding text
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
    }

    throw const FormatException('Không thể phân tích cú pháp JSON từ phản hồi AI.');
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
}
