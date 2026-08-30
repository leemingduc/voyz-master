import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:voyz/models/destination_detail.dart';

/// Service to fetch real destination photography from verifiable sources.
///
/// Priority chain:
///   1. Wikipedia REST summary (vi rồi en) — 1 request, CORS chính thức,
///      server trả sẵn URL thumbnail hợp lệ nên không bao giờ dính 400/404
///      do tự đoán hash path hay kích thước thumb.
///   2. Wikimedia Commons full-text search.
///   3. Chuỗi rỗng — UI đã có errorWidget placeholder ở mọi call site.
///
/// KHÔNG có URL viết tay trong code: mọi URL curated thuộc về bảng
/// `destinations` và phải qua `tool/verify_image_urls.dart` trước khi vào seed.
class ImageService {
  ImageService._();
  static final ImageService instance = ImageService._();

  /// Swap được trong test bằng MockClient. Mọi HTTP call trong service này
  /// phải đi qua client này.
  static http.Client client = http.Client();

  final Map<String, String> _cache = {};

  /// Gets the single most iconic photo for a destination.
  /// Returns an empty string when no verifiable image is found;
  /// the UI's errorWidget renders the placeholder in that case.
  Future<String> getImageUrl(String destinationName) async {
    if (_cache.containsKey(destinationName)) {
      return _cache[destinationName]!;
    }

    final placeName = destinationName.split(',').first.trim();

    // 1. Wikipedia REST summary (vi rồi en)
    String? url = await _fetchWikipediaSummaryImage(placeName, 'vi');
    url ??= await _fetchWikipediaSummaryImage(placeName, 'en');

    // 2. Wikimedia Commons full-text search
    url ??= await _fetchCommonsImage(placeName);

    // 3. Bó tay: trả rỗng, UI errorWidget lo phần placeholder.
    final result = url ?? '';
    _cache[destinationName] = result;
    return result;
  }

  /// Fetches image URLs for all destinations in parallel.
  Future<Map<String, String>> getImageUrls(List<String> names) async {
    final futures = names.map((name) => getImageUrl(name));
    final urls = await Future.wait(futures);
    return {for (int i = 0; i < names.length; i++) names[i]: urls[i]};
  }

  /// Backward-compatible alias: the REST summary chain is already the fast
  /// path (1 request per destination), so "fast" and "full" are the same now.
  Future<Map<String, String>> getImageUrlsFast(List<String> names) =>
      getImageUrls(names);

  /// Fetches multiple supplementary photos for specific landmarks of a destination.
  Future<List<DestinationLandmarkPhoto>> getLandmarkPhotos(
    String destinationName,
    List<String> landmarkTitles,
  ) async {
    final futures = landmarkTitles.map((title) async {
      final query = title.isNotEmpty
          ? '$title, $destinationName'
          : destinationName;
      final url = await getImageUrl(query);
      return DestinationLandmarkPhoto(title: title, imageUrl: url);
    });
    return Future.wait(futures);
  }

  // ── Wikipedia REST summary ──────────────────────────────────────────────

  /// Lấy ảnh đại diện qua Wikipedia REST summary (1 request, CORS chính thức).
  /// Trả null nếu không có trang, không có ảnh, hoặc ảnh dính blocklist.
  Future<String?> _fetchWikipediaSummaryImage(String query, String lang) async {
    try {
      final uri = Uri.parse(
        'https://$lang.wikipedia.org/api/rest_v1/page/summary/'
        '${Uri.encodeComponent(query)}',
      );
      final res = await client.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is! Map) return null;

      final thumb = data['thumbnail'];
      final thumbUrl = thumb is Map ? thumb['source']?.toString() : null;
      if (thumbUrl == null || thumbUrl.isEmpty || !_isGoodImage(thumbUrl)) {
        return null;
      }

      // Nâng thumb lên 1280px CHỈ khi ảnh gốc đủ lớn: Wikimedia trả 400
      // nếu yêu cầu thumbnail lớn hơn ảnh gốc.
      final original = data['originalimage'];
      final originalWidth =
          original is Map ? (original['width'] as num?)?.toInt() ?? 0 : 0;
      if (originalWidth >= 1280 && thumbUrl.contains('px-')) {
        return thumbUrl.replaceFirst(RegExp(r'/\d+px-'), '/1280px-');
      }
      return thumbUrl;
    } catch (_) {
      return null;
    }
  }

  // ── Wikimedia Commons full-text search ─────────────────────────────────

  Future<String?> _fetchCommonsImage(String placeName) async {
    final searchTerms =
        '"$placeName" (landscape OR panorama OR aerial OR travel OR beach OR temple OR skyline OR mountain OR bay OR waterfall) '
        '-map -flag -logo -coat -seal -diagram -icon -svg -portrait -headshot';
    try {
      final uri = Uri.parse(
        'https://commons.wikimedia.org/w/api.php'
        '?action=query'
        '&generator=search'
        '&gsrnamespace=6'
        '&gsrsearch=${Uri.encodeComponent(searchTerms)}'
        '&gsrlimit=8'
        '&prop=imageinfo'
        '&iiprop=url|dimensions'
        '&iiurlwidth=960'
        '&format=json'
        '&formatversion=2'
        '&origin=*',
      );
      final response =
          await client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final j = jsonDecode(response.body) as Map<String, dynamic>;
      final pages = j['query']?['pages'] as List<dynamic>?;
      if (pages == null) return null;

      for (final page in pages) {
        final title = (page['title'] as String?) ?? '';
        if (!_isGoodImageTitle(title)) continue;
        final imageInfoList = (page['imageinfo'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>();
        if (imageInfoList == null || imageInfoList.isEmpty) continue;
        final ii = imageInfoList.first;
        final w = (ii['width'] as num?)?.toInt() ?? 0;
        final h = (ii['height'] as num?)?.toInt() ?? 1;
        if (w < 600 || (w / h) < 1.1) continue;
        final url = (ii['thumburl'] as String?) ?? (ii['url'] as String?);
        if (url != null && _isGoodImage(url)) return url;
      }
    } catch (_) {}
    return null;
  }

  // ── Image Quality Guards ────────────────────────────────────────────────

  bool _isGoodImageTitle(String title) {
    if (!_isPhotoFile(title)) return false;
    return _isGoodImage(title);
  }

  bool _isPhotoFile(String title) {
    final lower = title.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  bool _isGoodImage(String urlOrTitle) {
    final lower = urlOrTitle.toLowerCase();
    const blocklist = [
      'flag', 'map', 'ban_do', 'location', 'coat_of_arms', 'emblem',
      'logo', 'diagram', '.svg', 'seal', 'icon', 'portrait', 'headshot',
      'blank', 'stub', 'placeholder', 'commons-logo',
    ];
    return !blocklist.any((b) => lower.contains(b));
  }
}
