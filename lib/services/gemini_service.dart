import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:voyz/data/trip_data.dart';
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
/// user's active locale. All methods check Multi-Tier cache first; only
/// calls the API on cache miss.
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

  /// The single Gemini model used by every AI feature in the app.
  static const modelName = 'gemini-3.1-flash-lite';

  GenerativeModel? _model;

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
    if (_model != null) return _model!;
    _model = _createModel(
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
        maxOutputTokens:
            8192, // Itinerary plans with nested days/items need ~5000+ tokens
      ),
    );
    return _model!;
  }

  /// Asynchronously pre-caches image URLs in the background and updates the multi-tier cache.
  void _precacheAndStoreImages(
    String cacheKey,
    List<DestinationSuggestion> suggestions, {
    required String featureType,
    String? destination,
    required String languageCode,
  }) {
    Future.microtask(() async {
      try {
        final names = suggestions.map((s) => s.name).toList();
        final imageUrls = await ImageService.instance.getImageUrls(names);
        final cached = await _aiCache.getResponse(cacheKey);
        if (cached != null) {
          await _aiCache.putResponse(
            cacheKey,
            cached.payload,
            featureType: featureType,
            destination: destination,
            languageCode: languageCode,
            imageUrls: imageUrls,
          );
        }
      } catch (e) {
        debugPrint('Image pre-caching error (non-fatal): $e');
      }
    });
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
    final cacheKey = _aiCache.buildKey('explore_trending', {
      'limit': limit,
      'lang': languageCode,
    });

    if (!forceRefresh) {
      final cached = await _aiCache.getResponse(cacheKey);
      if (cached != null) {
        return parseSuggestionsSync(cached.payload, imageUrls: cached.imageUrls);
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

    await _aiCache.putResponse(
      cacheKey,
      text,
      featureType: 'explore_trending',
      languageCode: languageCode,
    );

    final suggestions = parseSuggestionsSync(text);

    // Pre-cache images in background so next time they load instantly
    _precacheAndStoreImages(
      cacheKey,
      suggestions,
      featureType: 'explore_trending',
      languageCode: languageCode,
    );

    return suggestions;
  }

  // ── Suggestions ──────────────────────────────────────────────────────────

  /// Get AI travel suggestions based on user's trip preferences.
  ///
  /// **Phase 1 (fast, ~1-2s or <100ms on cache):** Returns suggestions immediately.
  /// If pre-cached images are available from the multi-tier cache, they are rendered right away.
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
    });

    // Check Multi-Tier cache (Memory -> Hive -> Supabase)
    if (!forceRefresh) {
      final cached = await _aiCache.getResponse(cacheKey);
      if (cached != null) {
        return parseSuggestionsSync(cached.payload, imageUrls: cached.imageUrls);
      }
    }

    // Cache miss — call Gemini API
    final prompt = _buildSuggestionsPrompt(trip, limit, languageCode);
    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) return [];

    // Save to multi-tier cache
    await _aiCache.putResponse(
      cacheKey,
      text,
      featureType: 'suggestions',
      destination: trip.destination.isNotEmpty ? trip.destination : null,
      languageCode: languageCode,
    );

    final suggestions = parseSuggestionsSync(text);

    // Pre-cache images in background
    _precacheAndStoreImages(
      cacheKey,
      suggestions,
      featureType: 'suggestions',
      destination: trip.destination.isNotEmpty ? trip.destination : null,
      languageCode: languageCode,
    );

    return suggestions;
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
        imageUrl: (s.imageUrl.isNotEmpty) ? s.imageUrl : (imageUrls[s.name] ?? ''),
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
  ///
  /// If [imageUrls] map is provided, image URLs are attached immediately.
  List<DestinationSuggestion> parseSuggestionsSync(
    String text, {
    Map<String, String>? imageUrls,
  }) {
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
      final cachedImage = imageUrls?[name] ?? '';
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
      return DestinationSuggestion.fromJson(map, cachedImage);
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
  "price": "~4.2M ${trip.currency}",
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
    final cacheKey = _aiCache.buildKey('detail', {
      'name': destinationName,
      'lang': languageCode,
    });

    // Check cache
    if (!forceRefresh) {
      final cached = await _aiCache.getResponse(cacheKey);
      if (cached != null) {
        return _parseDetail(cached.payload, destinationName);
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
    await _aiCache.putResponse(
      cacheKey,
      text,
      featureType: 'detail',
      destination: destinationName,
      languageCode: languageCode,
    );

    return _parseDetail(text, destinationName);
  }

  /// Parse raw JSON text into a DestinationDetail with image.
  Future<DestinationDetail> _parseDetail(
    String text,
    String destinationName,
  ) async {
    final Map<String, dynamic> json =
        safeJsonDecode(text) as Map<String, dynamic>;
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
  "totalBudget": "~4.2M ${trip.currency}",
  "budgetBreakdown": [
    {"label": "Transport", "amount": "1.7M ${trip.currency}", "fraction": 0.40, "icon": "flight"},
    {"label": "Stay", "amount": "1.2M ${trip.currency}", "fraction": 0.30, "icon": "hotel"},
    {"label": "Food", "amount": "0.8M ${trip.currency}", "fraction": 0.20, "icon": "restaurant"},
    {"label": "Activities", "amount": "0.5M ${trip.currency}", "fraction": 0.10, "icon": "kayaking"}
  ]
}

Quy tắc:
- tags: 4 thẻ phù hợp nhất với điểm đến, có emoji phía trước
- weather: thời tiết thực tế cho thời gian du lịch
- budgetBreakdown: chia ngân sách thành 4 loại, tổng fraction = 1.0
- icon chỉ dùng: flight, hotel, restaurant, kayaking
- Mọi trường tiền tệ phải ghi cả số tiền và mã ${trip.currency}, đồng thời phù hợp với ngân sách $budget
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
    String? additionalInstruction,
  }) async {
    final cacheKey = _aiCache.buildKey('itinerary', {
      'name': destinationName,
      'numDays': numDays,
      'lang': languageCode,
      'instruction': additionalInstruction,
    });

    // Check cache
    if (!forceRefresh) {
      final cached = await _aiCache.getResponse(cacheKey);
      if (cached != null) {
        final Map<String, dynamic> json =
            safeJsonDecode(cached.payload) as Map<String, dynamic>;
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
      additionalInstruction,
    );
    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('noAiResponse');
    }

    // Save to cache
    await _aiCache.putResponse(
      cacheKey,
      text,
      featureType: 'itinerary',
      destination: destinationName,
      languageCode: languageCode,
    );

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

  String _buildItineraryPrompt(
    String destinationName,
    int numDays,
    TripData trip,
    int limit,
    String languageCode,
    String? additionalInstruction,
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
        maxOutputTokens: 1024,
      ),
    );

    final response = await chatModel.generateContent(contents);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('noAiResponse');
    }
    return text.trim();
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

    final cached = await _aiCache.getResponse(cacheKey);
    if (cached != null) {
      final Map<String, dynamic> json =
          safeJsonDecode(cached.payload) as Map<String, dynamic>;
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

    await _aiCache.putResponse(
      cacheKey,
      text,
      featureType: 'comparison',
      languageCode: languageCode,
    );

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
    final cached = await _aiCache.getResponse(cacheKey);
    if (cached != null) {
      final Map<String, dynamic> json =
          safeJsonDecode(cached.payload) as Map<String, dynamic>;
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
    await _aiCache.putResponse(
      cacheKey,
      text,
      featureType: 'best_time',
      destination: destination,
      languageCode: languageCode,
    );

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
      final cached = await _aiCache.getResponse(cacheKey);
      if (cached != null) {
        return _parseCulturalTips(cached.payload, destinationName);
      }
    }

    // Cache miss — call Gemini API
    final prompt = _buildCulturalTipsPrompt(destinationName, languageCode);
    final response = await _gemini.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('noAiResponse');
    }

    // Save to cache
    await _aiCache.putResponse(
      cacheKey,
      text,
      featureType: 'cultural_tips',
      destination: destinationName,
      languageCode: languageCode,
    );

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
