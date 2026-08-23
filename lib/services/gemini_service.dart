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
  /// Does NOT require any user input — perfect for the Explore tab.
  ///
  /// [limit] number of destinations to return.
  /// [forceRefresh] if true, generates a completely new random batch of destinations.
  /// [category] optional specific travel category / theme.
  /// [languageCode] locale code for language-aware prompts (vi, en, ko).
  Future<List<DestinationSuggestion>> getExploreTrending({
    int limit = 10,
    bool forceRefresh = false,
    String? category,
    String languageCode = 'vi',
  }) async {
    final randomSeed = DateTime.now().millisecondsSinceEpoch % 100000;
    final theme = category ??
        _randomExploreThemes[randomSeed % _randomExploreThemes.length];

    final cacheKey = _aiCache.buildKey('explore_trending', {
      'limit': limit,
      'lang': languageCode,
      if (!forceRefresh && category != null) 'category': category,
      if (forceRefresh) 'nonce': randomSeed,
    });

    if (!forceRefresh) {
      final cached = await _aiCache.getResponse(cacheKey);
      if (cached != null) {
        return parseSuggestionsSync(cached.payload, imageUrls: cached.imageUrls);
      }
    }

    final langInst = languageInstruction(languageCode);
    final prompt = '''
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

  /// Formats the budget tier into clear, realistic guidance for the AI model.
  static String _describeBudgetTier(String tier, String currency) {
    final lower = tier.toLowerCase();
    if (lower == 'economy' || lower.contains('bình dân') || lower.contains('알뜰')) {
      return 'Phân khúc Bình dân / Tiết kiệm: '
          'Lựa chọn homestay/khách sạn bình dân 1-2 sao, quán ăn địa phương/đường phố, '
          'di chuyển bằng xe máy/xe buýt/tàu. Ước tính chi phí thực tế: ~1.5M - 3.5M $currency cho chuyến 3 ngày trong nước, '
          'hoặc tương đương \$150-\$350 $currency cho chuyến quốc tế.';
    }
    if (lower == 'premium' || lower.contains('cao cấp') || lower.contains('고급')) {
      return 'Phân khúc Cao cấp: '
          'Lựa chọn khách sạn 4-5 sao / resort cao cấp, nhà hàng chất lượng, '
          'xe đưa đón riêng / chuyến bay giờ đẹp, tour trải nghiệm chất lượng cao. Ước tính chi phí thực tế: ~9M - 18M $currency cho chuyến 3 ngày trong nước, '
          'hoặc tương đương \$900-\$2200 $currency cho chuyến quốc tế.';
    }
    if (lower == 'luxury' || lower.contains('hạng sang') || lower.contains('럭셔리')) {
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

    final budgetDescription = _describeBudgetTier(trip.budget, trip.currency);

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
Bạn là chuyên gia tư vấn du lịch AI hàng đầu. Hãy gợi ý $limit điểm đến du lịch phù hợp nhất dựa trên thông tin thực tế.

Thông tin người dùng:
- Điểm đến mong muốn: $destination
- Mức ngân sách: $budgetDescription
- Sở thích: $interests
- Thời gian: $dateInfo
- Số người: ${trip.participants.isNotEmpty ? trip.participants : 'không rõ'}
- Độ tuổi: ${trip.ageRange.isNotEmpty ? trip.ageRange : 'không rõ'}$additionalNotes$aiPromptExtra

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

    final budgetDescription = _describeBudgetTier(trip.budget, trip.currency);
    final langInst = languageInstruction(languageCode);

    return '''
Bạn là chuyên gia tư vấn du lịch AI. Hãy cung cấp thông tin chi tiết và ước tính chi phí thực tế cho điểm đến "$destinationName".

Mức ngân sách & phân khúc: $budgetDescription
Thời gian dự kiến: $dateInfo

Trả về JSON object với cấu trúc:
{
  "name": "$destinationName",
  "location": "Tỉnh/Vùng, Quốc gia",
  "tags": ["🌿 Nghỉ dưỡng", "🏖️ Biển đảo", "🤿 Lặn biển", "🌅 Cảnh đẹp"],
  "weather": "Nắng đẹp, 28-32°C",
  "dateRange": "$dateInfo",
  "totalBudget": "~4.8M ${trip.currency}",
  "budgetBreakdown": [
    {"label": "Transport", "amount": "1.8M ${trip.currency}", "fraction": 0.38, "icon": "flight"},
    {"label": "Stay", "amount": "1.5M ${trip.currency}", "fraction": 0.31, "icon": "hotel"},
    {"label": "Food", "amount": "1.0M ${trip.currency}", "fraction": 0.21, "icon": "restaurant"},
    {"label": "Activities", "amount": "0.5M ${trip.currency}", "fraction": 0.10, "icon": "kayaking"}
  ]
}

Quy tắc:
- totalBudget: Phải là ước tính chi phí thực tế cho 1 người/chuyến đi dựa trên phân khúc ngân sách đã chọn và chi phí thực tế của $destinationName.
- budgetBreakdown: Phân chia chi phí thực tế thành 4 nhóm (Transport - Đi lại, Stay - Lưu trú, Food - Ăn uống, Activities - Vui chơi/Tham quan). Tổng 4 khoản tiền phải bằng đúng totalBudget, và tổng fraction = 1.0.
- icon chỉ dùng: flight, hotel, restaurant, kayaking
- tags: 4 thẻ ngắn gọn, đặc trưng nhất cho điểm đến, có kèm emoji.
- weather: Dự báo thời tiết thực tế theo mùa của điểm đến.
- Mọi trường tiền tệ phải ghi số tiền kèm mã ${trip.currency}.
- CHỈ trả về JSON object, KHÔNG thêm markdown hay text khác.
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
