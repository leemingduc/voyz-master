import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:voyz/models/destination_detail.dart';

/// Service to fetch real, high-quality, authentic destination photography.
///
/// Priority chain:
///   1. Curated registry (hand-verified, accurate per destination)
///   2. Wikipedia landscape image (multi-image scan, filters thumbnails/maps)
///   3. Wikimedia Commons (full-text search for travel photos)
///   4. Unsplash Source (keyword search — no key required)
///   5. Themed generic fallback
class ImageService {
  ImageService._();
  static final ImageService instance = ImageService._();

  final Map<String, String> _cache = {};

  static String fallbackImageUrlFor(
    String destinationName, {
    String? category,
  }) {
    final normalized = _normalizeKey(
      [
        destinationName,
        category,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' '),
    );
    return _getRealisticTravelFallback(normalized);
  }

  // ── Curated Registry ──────────────────────────────────────────────────────
  // Every URL is hand-verified to show the correct iconic view of that destination.
  static final Map<String, String> _curatedLandmarks = {
    // ─ 🇻🇳 Việt Nam ─────────────────────────────────────────────────────────
    // Phú Quốc — bãi biển Phú Quốc
    'phu quoc':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Phu_quoc_beach.JPG/960px-Phu_quoc_beach.JPG',
    // Côn Đảo — biển trong xanh Côn Đảo
    'con dao':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Con_Dao_Islands.jpg/960px-Con_Dao_Islands.jpg',
    // Đà Nẵng — Cầu Rồng
    'da nang':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Dragon_Bridge_Da_Nang_1.jpg/960px-Dragon_Bridge_Da_Nang_1.jpg',
    // Bà Nà Hills — Cầu Vàng
    'ba na hills':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Golden_Bridge_-_Ba_Na_Hills.jpg/1280px-Golden_Bridge_-_Ba_Na_Hills.jpg',
    'ba na':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Golden_Bridge_-_Ba_Na_Hills.jpg/1280px-Golden_Bridge_-_Ba_Na_Hills.jpg',
    'golden bridge':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Golden_Bridge_-_Ba_Na_Hills.jpg/1280px-Golden_Bridge_-_Ba_Na_Hills.jpg',
    // Hội An — Phố đèn lồng đêm
    'hoi an':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/71/Hoi_An_night.jpg/1280px-Hoi_An_night.jpg',
    // Hạ Long — vịnh Hạ Long thuyền buồm
    'ha long':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/Halong_bay_boats.jpg/1280px-Halong_bay_boats.jpg',
    'vinh ha long':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/Halong_bay_boats.jpg/1280px-Halong_bay_boats.jpg',
    'halong':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/Halong_bay_boats.jpg/1280px-Halong_bay_boats.jpg',
    // Hà Giang — Đèo Mã Pí Lèng
    'ha giang':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/Ma_Pi_Leng_Pass%2C_Ha_Giang.jpg/1280px-Ma_Pi_Leng_Pass%2C_Ha_Giang.jpg',
    // Sapa — ruộng bậc thang
    'sa pa':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Sapa_rice_field.jpg/1280px-Sapa_rice_field.jpg',
    'sapa':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Sapa_rice_field.jpg/1280px-Sapa_rice_field.jpg',
    // Ninh Bình — Tràng An / Tam Cốc thuyền
    'ninh binh':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Trang_An_Scenic_Landscape_Complex_-_Ninh_Binh.jpg/1280px-Trang_An_Scenic_Landscape_Complex_-_Ninh_Binh.jpg',
    'trang an':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Trang_An_Scenic_Landscape_Complex_-_Ninh_Binh.jpg/1280px-Trang_An_Scenic_Landscape_Complex_-_Ninh_Binh.jpg',
    'tam coc':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Tam_Coc%2C_Ninh_B%C3%ACnh.jpg/1280px-Tam_Coc%2C_Ninh_B%C3%ACnh.jpg',
    // Đà Lạt — thành phố sương mù / hoa dã quỳ
    'da lat':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/Da_Lat_Xuan_Huong_Lake.jpg/1280px-Da_Lat_Xuan_Huong_Lake.jpg',
    'dalat':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/Da_Lat_Xuan_Huong_Lake.jpg/1280px-Da_Lat_Xuan_Huong_Lake.jpg',
    // Nha Trang — bãi biển Nha Trang
    'nha trang':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Nha_Trang_beach.jpg/1280px-Nha_Trang_beach.jpg',
    // Huế — Hoàng Thành Huế
    'hue':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Imperial_Citadel_of_Hue%2C_Vietnam.jpg/1280px-Imperial_Citadel_of_Hue%2C_Vietnam.jpg',
    'hue citadel':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Imperial_Citadel_of_Hue%2C_Vietnam.jpg/1280px-Imperial_Citadel_of_Hue%2C_Vietnam.jpg',
    // Hà Nội — Hồ Hoàn Kiếm & Tháp Rùa
    'ha noi':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/HoanKiem_Lake_Turtle_Tower_Hanoi_Vietnam.jpg/1280px-HoanKiem_Lake_Turtle_Tower_Hanoi_Vietnam.jpg',
    'hanoi':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/HoanKiem_Lake_Turtle_Tower_Hanoi_Vietnam.jpg/1280px-HoanKiem_Lake_Turtle_Tower_Hanoi_Vietnam.jpg',
    'hoan kiem':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/HoanKiem_Lake_Turtle_Tower_Hanoi_Vietnam.jpg/1280px-HoanKiem_Lake_Turtle_Tower_Hanoi_Vietnam.jpg',
    // TP. HCM — Dinh Độc Lập / skyline
    'ho chi minh':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/Ho_Chi_Minh_City_Skyline.jpg/1280px-Ho_Chi_Minh_City_Skyline.jpg',
    'sai gon':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/Ho_Chi_Minh_City_Skyline.jpg/1280px-Ho_Chi_Minh_City_Skyline.jpg',
    'saigon':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/Ho_Chi_Minh_City_Skyline.jpg/1280px-Ho_Chi_Minh_City_Skyline.jpg',
    // Quy Nhơn — bãi biển Quy Nhơn
    'quy nhon':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/Quy_Nhon_Beach%2C_Binh_Dinh.jpg/1280px-Quy_Nhon_Beach%2C_Binh_Dinh.jpg',
    // Mũi Né — đồi cát vàng
    'mui ne':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/Mui_Ne_Sand_Dunes.jpg/1280px-Mui_Ne_Sand_Dunes.jpg',
    'phan thiet':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/Mui_Ne_Sand_Dunes.jpg/1280px-Mui_Ne_Sand_Dunes.jpg',
    // Phong Nha — hang Sơn Đoòng
    'phong nha':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Son_Doong_cave_-_Phong_Nha.jpg/1280px-Son_Doong_cave_-_Phong_Nha.jpg',
    'son doong':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Son_Doong_cave_-_Phong_Nha.jpg/1280px-Son_Doong_cave_-_Phong_Nha.jpg',
    'quang binh':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Son_Doong_cave_-_Phong_Nha.jpg/1280px-Son_Doong_cave_-_Phong_Nha.jpg',
    // Cần Thơ — chợ nổi Cái Răng
    'can tho':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/71/Cai_Rang_floating_market_Can_Tho.jpg/1280px-Cai_Rang_floating_market_Can_Tho.jpg',
    // Vũng Tàu — Tượng Chúa Kitô
    'vung tau':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Christ_of_Vung_Tau.jpg/1280px-Christ_of_Vung_Tau.jpg',
    // Cao Bằng — Thác Bản Giốc
    'cao bang':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Ban_Gioc_Waterfall_Cao_Bang.jpg/1280px-Ban_Gioc_Waterfall_Cao_Bang.jpg',
    'ban gioc':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Ban_Gioc_Waterfall_Cao_Bang.jpg/1280px-Ban_Gioc_Waterfall_Cao_Bang.jpg',
    // Mộc Châu — đồi chè xanh mướt
    'moc chau':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Moc_Chau_tea_hills.jpg/1280px-Moc_Chau_tea_hills.jpg',
    // Mai Châu — thung lũng Mai Châu
    'mai chau':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Mai_Chau_Valley.jpg/1280px-Mai_Chau_Valley.jpg',
    // Mù Cang Chải — ruộng bậc thang vàng mùa lúa chín
    'mu cang chai':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Mu_Cang_Chai_terraced_rice_fields.jpg/1280px-Mu_Cang_Chai_terraced_rice_fields.jpg',
    // Phú Yên — Gành Đá Đĩa
    'phu yen':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/99/Ganh_Da_Dia_Phu_Yen.jpg/1280px-Ganh_Da_Dia_Phu_Yen.jpg',
    // Lý Sơn — cảnh đảo lý sơn
    'ly son':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c9/Ly_Son_Island%2C_Quang_Ngai.jpg/1280px-Ly_Son_Island%2C_Quang_Ngai.jpg',
    // Cát Bà — vịnh Lan Hạ
    'cat ba':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Cat_Ba_Island_Vietnam.jpg/1280px-Cat_Ba_Island_Vietnam.jpg',
    // Hồ Ba Bể
    'ba be':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/Ba_Be_Lake.jpg/1280px-Ba_Be_Lake.jpg',

    // ─ 🌏 Quốc Tế ────────────────────────────────────────────────────────────
    // Bali — đền Tanah Lot
    'bali':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Tanah_Lot_Temple_Bali.jpg/1280px-Tanah_Lot_Temple_Bali.jpg',
    // Bangkok — Chùa Wat Pho / wat arun
    'bangkok':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/Wat_Arun_at_dusk_Bangkok_Thailand.jpg/1280px-Wat_Arun_at_dusk_Bangkok_Thailand.jpg',
    // Phuket — Khao Phing Kan (James Bond Island)
    'phuket':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f8/Khao_Phing_Kan_James_Bond_Island_Thailand.jpg/1280px-Khao_Phing_Kan_James_Bond_Island_Thailand.jpg',
    // Chiang Mai — Doi Suthep temple
    'chiang mai':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Doi_Suthep_Temple_Chiang_Mai.jpg/1280px-Doi_Suthep_Temple_Chiang_Mai.jpg',
    // Tokyo — Mt.Fuji với sakura
    'tokyo':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Mount_Fuji_from_Hotel_Mt._Fuji_2010.jpg/1280px-Mount_Fuji_from_Hotel_Mt._Fuji_2010.jpg',
    // Kyoto — cổng Fushimi Inari
    'kyoto':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Fushimi_Inari-taisha_entrance_torii_and_lanterns_Kyoto_Japan.jpg/1280px-Fushimi_Inari-taisha_entrance_torii_and_lanterns_Kyoto_Japan.jpg',
    'fushimi inari':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Fushimi_Inari-taisha_entrance_torii_and_lanterns_Kyoto_Japan.jpg/1280px-Fushimi_Inari-taisha_entrance_torii_and_lanterns_Kyoto_Japan.jpg',
    // Osaka — lâu đài Osaka
    'osaka':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b4/Osaka_Castle%2C_Osaka%2C_Japan.jpg/1280px-Osaka_Castle%2C_Osaka%2C_Japan.jpg',
    // Seoul — Gyeongbokgung palace
    'seoul':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Gyeongbokgung_Palace%2C_Seoul%2C_Korea.jpg/1280px-Gyeongbokgung_Palace%2C_Seoul%2C_Korea.jpg',
    'gyeongbokgung':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/83/Gyeongbokgung_Palace%2C_Seoul%2C_Korea.jpg/1280px-Gyeongbokgung_Palace%2C_Seoul%2C_Korea.jpg',
    // Busan — Gamcheon Cultural Village
    'busan':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Gamcheon_Culture_Village%2C_Busan%2C_Korea.jpg/1280px-Gamcheon_Culture_Village%2C_Busan%2C_Korea.jpg',
    // Jeju — Jeongbang waterfall / Hallasan
    'jeju':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Jeongbang_Falls_Jeju_Korea.jpg/1280px-Jeongbang_Falls_Jeju_Korea.jpg',
    // Singapore — Marina Bay Sands
    'singapore':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/Marina_Bay_Sands_2010.jpg/1280px-Marina_Bay_Sands_2010.jpg',
    // Paris — Tháp Eiffel
    'paris':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/af/Tour_eiffel_at_sunrise_from_the_trocadero.jpg/1280px-Tour_eiffel_at_sunrise_from_the_trocadero.jpg',
    'eiffel':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/af/Tour_eiffel_at_sunrise_from_the_trocadero.jpg/1280px-Tour_eiffel_at_sunrise_from_the_trocadero.jpg',
    // Rome — Đấu trường Colosseum
    'rome':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Colosseo_2020.jpg/1280px-Colosseo_2020.jpg',
    'colosseum':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Colosseo_2020.jpg/1280px-Colosseo_2020.jpg',
    // London — cầu London + Big Ben
    'london':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Big_Ben_Clock_Tower_2012-07-25.jpg/1280px-Big_Ben_Clock_Tower_2012-07-25.jpg',
    // New York — Manhattan skyline
    'new york':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Southwest_corner_of_Central_Park%2C_looking_east%2C_NYC.jpg/1280px-Southwest_corner_of_Central_Park%2C_looking_east%2C_NYC.jpg',
    'new york city':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Southwest_corner_of_Central_Park%2C_looking_east%2C_NYC.jpg/1280px-Southwest_corner_of_Central_Park%2C_looking_east%2C_NYC.jpg',
    'manhattan':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Southwest_corner_of_Central_Park%2C_looking_east%2C_NYC.jpg/1280px-Southwest_corner_of_Central_Park%2C_looking_east%2C_NYC.jpg',
    // Sydney — Opera House
    'sydney':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Sydney_Australia._%28bySmithies%29.jpg/1280px-Sydney_Australia._%28bySmithies%29.jpg',
    'sydney opera house':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Sydney_Australia._%28bySmithies%29.jpg/1280px-Sydney_Australia._%28bySmithies%29.jpg',
    // Maldives — bungalow nước xanh
    'maldives':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Maldives_atolls.jpg/1280px-Maldives_atolls.jpg',
    // Santorini — nhà trắng mái xanh Oia
    'santorini':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Santorini_Oia_01.jpg/1280px-Santorini_Oia_01.jpg',
    'oia':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Santorini_Oia_01.jpg/1280px-Santorini_Oia_01.jpg',
    // Dubai — Burj Khalifa
    'dubai':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Burj_Khalifa_building_2014.jpg/1280px-Burj_Khalifa_building_2014.jpg',
    'burj khalifa':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Burj_Khalifa_building_2014.jpg/1280px-Burj_Khalifa_building_2014.jpg',
    // Thụy Sĩ — Interlaken
    'interlaken':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Interlaken-Rosenlaui_2012-08-26.jpg/1280px-Interlaken-Rosenlaui_2012-08-26.jpg',
    // Siem Reap — Angkor Wat
    'siem reap':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Angkor_Wat%2C_Angkor%2C_Cambodia.jpg/1280px-Angkor_Wat%2C_Angkor%2C_Cambodia.jpg',
    'angkor wat':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Angkor_Wat%2C_Angkor%2C_Cambodia.jpg/1280px-Angkor_Wat%2C_Angkor%2C_Cambodia.jpg',
    'angkor':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Angkor_Wat%2C_Angkor%2C_Cambodia.jpg/1280px-Angkor_Wat%2C_Angkor%2C_Cambodia.jpg',
    // Luang Prabang — thác Kuang Si
    'luang prabang':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/97/Kuang_Si_Falls_Luang_Prabang_Laos.jpg/1280px-Kuang_Si_Falls_Luang_Prabang_Laos.jpg',
    // Boracay — White Beach
    'boracay':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/Boracay_white_beach_sunset.jpg/1280px-Boracay_white_beach_sunset.jpg',
    // Palawan — El Nido
    'palawan':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/El_Nido_Palawan_Philippines.jpg/1280px-El_Nido_Palawan_Philippines.jpg',
    'el nido':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/El_Nido_Palawan_Philippines.jpg/1280px-El_Nido_Palawan_Philippines.jpg',
    // Hà Nội landmarks
    'van mieu':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Van_Mieu_Hanoi.jpg/1280px-Van_Mieu_Hanoi.jpg',
    'lang ho chi minh':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Ho_Chi_Minh_Mausoleum%2C_Hanoi.jpg/1280px-Ho_Chi_Minh_Mausoleum%2C_Hanoi.jpg',
    // Đà Nẵng landmarks
    'cau rong':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7c/Dragon_Bridge_in_Da_Nang%2C_Vietnam.jpg/1280px-Dragon_Bridge_in_Da_Nang%2C_Vietnam.jpg',
    'my khe':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b0/My_Khe_Beach%2C_Da_Nang.jpg/1280px-My_Khe_Beach%2C_Da_Nang.jpg',
    'son tra':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a3/Son_Tra_Peninsula_Da_Nang.jpg/1280px-Son_Tra_Peninsula_Da_Nang.jpg',
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Fast single-image fetch: curated registry → Wikipedia thumbnail only.
  /// No full article scan, no Commons search — returns in ~200ms or less.
  /// Falls back to themed fallback if not found.
  Future<String> getImageUrlFast(String destinationName) async {
    final cacheKey = 'fast_$destinationName';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final placeName = destinationName.split(',').first.trim();
    final normalized = _normalizeKey(placeName);

    // 1. Curated registry — instant, no network
    final curated = _lookupCurated(normalized);
    if (curated != null) {
      _cache[cacheKey] = curated;
      return curated;
    }

    // 2. Wikipedia pageimages thumbnail only (1 HTTP request)
    String? url = await _fetchWikipediaThumbnailOnly(placeName, 'vi');
    url ??= await _fetchWikipediaThumbnailOnly(placeName, 'en');

    // 3. Themed fallback (instant)
    url ??= _getRealisticTravelFallback(normalized);

    _cache[cacheKey] = url;
    return url;
  }

  /// Fetches 1 fast image URL for each destination in parallel.
  Future<Map<String, String>> getImageUrlsFast(List<String> names) async {
    final futures = names.map((name) => getImageUrlFast(name));
    final urls = await Future.wait(futures);
    return {for (int i = 0; i < names.length; i++) names[i]: urls[i]};
  }

  /// Wikipedia thumbnail-only fetch: 1 API call, no article image scan.
  Future<String?> _fetchWikipediaThumbnailOnly(
    String query,
    String lang,
  ) async {
    try {
      final uri = Uri.parse(
        'https://$lang.wikipedia.org/w/api.php'
        '?action=query'
        '&titles=${Uri.encodeComponent(query)}'
        '&prop=pageimages'
        '&format=json'
        '&formatversion=2'
        '&pithumbsize=960'
        '&pilimit=1'
        '&origin=*',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final pages = j['query']?['pages'] as List<dynamic>?;
      if (pages == null || pages.isEmpty) return null;
      final page = pages.first as Map<String, dynamic>;
      final thumbnail = page['thumbnail'] as Map<String, dynamic>?;
      if (thumbnail == null) return null;
      final src = thumbnail['source'] as String?;
      if (src == null || !_isGoodImage(src)) return null;
      final w = (thumbnail['width'] as num?)?.toInt() ?? 0;
      final h = (thumbnail['height'] as num?)?.toInt() ?? 1;
      if (w < 300 || (w / h) < 0.9) return null;
      return src;
    } catch (_) {
      return null;
    }
  }

  /// Gets the single most iconic photo for a destination.
  /// Uses full resolution chain: curated → Wikipedia full scan → Commons → LoremFlickr → fallback.
  Future<String> getImageUrl(String destinationName) async {
    if (_cache.containsKey(destinationName)) {
      return _cache[destinationName]!;
    }

    final placeName = destinationName.split(',').first.trim();
    final normalized = _normalizeKey(placeName);

    // 1. Curated registry (best accuracy)
    final curated = _lookupCurated(normalized);
    if (curated != null) {
      _cache[destinationName] = curated;
      return curated;
    }

    // 2. Wikipedia — scan multiple images to pick best landscape shot
    String? url = await _fetchWikipediaLandscapeImage(placeName, 'vi');
    url ??= await _fetchWikipediaLandscapeImage(placeName, 'en');

    // 3. Wikimedia Commons full-text search
    url ??= await _fetchCommonsImage(placeName);

    // 4. LoremFlickr keyword search (no API key needed, CORS friendly)
    url ??= await _fetchLoremFlickrSearch(placeName);

    // 5. Themed fallback
    url ??= _getRealisticTravelFallback(normalized);

    _cache[destinationName] = url;
    return url;
  }

  /// Fetches image URLs for all destinations in parallel.
  Future<Map<String, String>> getImageUrls(List<String> names) async {
    final futures = names.map((name) => getImageUrl(name));
    final urls = await Future.wait(futures);
    return {for (int i = 0; i < names.length; i++) names[i]: urls[i]};
  }

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

  // ── Curated Lookup ─────────────────────────────────────────────────────────
  String? _lookupCurated(String normalized) {
    // Exact match first
    if (_curatedLandmarks.containsKey(normalized)) {
      return _curatedLandmarks[normalized];
    }
    // Substring match (longest key wins to avoid "hue" matching "luang prabang" etc.)
    String? best;
    int bestLen = 0;
    for (final entry in _curatedLandmarks.entries) {
      final k = entry.key;
      if ((normalized.contains(k) || k.contains(normalized)) &&
          k.length > bestLen) {
        best = entry.value;
        bestLen = k.length;
      }
    }
    return best;
  }

  // ── Normalization ───────────────────────────────────────────────────────────
  static String _normalizeKey(String input) {
    const withDiacritics =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const withoutDiacritics =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';

    var result = input.toLowerCase();
    for (int i = 0; i < withDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return result
        .replaceAll('thanh pho ', '')
        .replaceAll('tp. ', '')
        .replaceAll('tp ', '')
        .replaceAll('tinh ', '')
        .replaceAll('quan ', '')
        .replaceAll('huyen ', '')
        .replaceAll('viet nam', '')
        .replaceAll('vietnam', '')
        .trim();
  }

  // ── Wikipedia — landscape-aware image fetch ─────────────────────────────────
  // Uses pageimages + extraimages to pick the best landscape/travel shot,
  // skipping portrait-mode thumbnails, maps and logos.
  Future<String?> _fetchWikipediaLandscapeImage(
    String query,
    String lang,
  ) async {
    try {
      // Step 1: resolve best article title
      final searchUri = Uri.parse(
        'https://$lang.wikipedia.org/w/api.php'
        '?action=opensearch'
        '&search=${Uri.encodeComponent(query)}'
        '&limit=1'
        '&format=json'
        '&origin=*',
      );
      final searchRes = await http
          .get(searchUri)
          .timeout(const Duration(seconds: 5));
      String articleTitle = query;
      if (searchRes.statusCode == 200) {
        final j = jsonDecode(searchRes.body) as List<dynamic>;
        final titles = j[1] as List<dynamic>;
        if (titles.isNotEmpty) articleTitle = titles.first as String;
      }

      // Step 2: fetch multiple images from the article
      final imgUri = Uri.parse(
        'https://$lang.wikipedia.org/w/api.php'
        '?action=query'
        '&titles=${Uri.encodeComponent(articleTitle)}'
        '&prop=images|pageimages'
        '&format=json'
        '&formatversion=2'
        '&pithumbsize=960'
        '&imlimit=20'
        '&origin=*',
      );
      final imgRes = await http.get(imgUri).timeout(const Duration(seconds: 5));
      if (imgRes.statusCode != 200) return null;

      final j = jsonDecode(imgRes.body) as Map<String, dynamic>;
      final pages = j['query']?['pages'] as List<dynamic>?;
      if (pages == null || pages.isEmpty) return null;
      final page = pages.first as Map<String, dynamic>;

      // 2a. Check pageimages thumbnail (often good)
      final thumbnail = page['thumbnail'] as Map<String, dynamic>?;
      if (thumbnail != null) {
        final src = thumbnail['source'] as String?;
        if (src != null && _isGoodImage(src) && _isLandscapeRatio(thumbnail)) {
          return src;
        }
      }

      // 2b. Scan article images list for best landscape photo
      final images = page['images'] as List<dynamic>?;
      if (images != null) {
        for (final img in images) {
          final title = (img['title'] as String?) ?? '';
          if (!_isGoodImageTitle(title)) continue;

          final infoUrl = await _fetchFileInfo(title, lang);
          if (infoUrl != null) return infoUrl;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _fetchFileInfo(String fileTitle, String lang) async {
    try {
      final uri = Uri.parse(
        'https://$lang.wikipedia.org/w/api.php'
        '?action=query'
        '&titles=${Uri.encodeComponent(fileTitle)}'
        '&prop=imageinfo'
        '&iiprop=url|dimensions'
        '&iiurlwidth=960'
        '&format=json'
        '&formatversion=2'
        '&origin=*',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final pages = j['query']?['pages'] as List<dynamic>?;
      if (pages == null || pages.isEmpty) return null;
      final info =
          (pages.first as Map<String, dynamic>)['imageinfo'] as List<dynamic>?;
      if (info == null || info.isEmpty) return null;
      final ii = info.first as Map<String, dynamic>;
      final w = (ii['width'] as num?)?.toInt() ?? 0;
      final h = (ii['height'] as num?)?.toInt() ?? 1;
      // Only wide landscape images
      if (w < 400 || h == 0 || (w / h) < 1.1) return null;
      final url = (ii['thumburl'] as String?) ?? (ii['url'] as String?);
      if (url == null || !_isGoodImage(url)) return null;
      return url;
    } catch (_) {
      return null;
    }
  }

  // ── Wikimedia Commons ───────────────────────────────────────────────────────
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
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
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

  // ── LoremFlickr Keyword Search (no API key, CORS friendly) ──────────────────
  Future<String?> _fetchLoremFlickrSearch(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final testUrl = 'https://loremflickr.com/960/640/$encoded';
      final res = await http
          .get(Uri.parse(testUrl))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 || res.statusCode == 302) {
        final finalUrl = res.request?.url.toString() ?? testUrl;
        if (_isGoodImage(finalUrl)) return finalUrl;
      }
    } catch (_) {}
    return null;
  }

  // ── Image Quality Guards ────────────────────────────────────────────────────
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
      'flag',
      'map',
      'ban_do',
      'location',
      'coat_of_arms',
      'emblem',
      'logo',
      'diagram',
      '.svg',
      'seal',
      'icon',
      'portrait',
      'headshot',
      'blank',
      'stub',
      'placeholder',
      'commons-logo',
    ];
    return !blocklist.any((b) => lower.contains(b));
  }

  bool _isLandscapeRatio(Map<String, dynamic> thumbnail) {
    final w = (thumbnail['width'] as num?)?.toInt() ?? 0;
    final h = (thumbnail['height'] as num?)?.toInt() ?? 1;
    return w > 0 && (w / h) >= 1.0;
  }

  // ── Themed Fallbacks ────────────────────────────────────────────────────────
  static String _getRealisticTravelFallback(String query) {
    // Beach / island destinations
    if (query.contains('beach') ||
        query.contains('island') ||
        query.contains('bien') ||
        query.contains('dao') ||
        query.contains('bay')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Nha_Trang_Beach_Khanh_Hoa.jpg/1280px-Nha_Trang_Beach_Khanh_Hoa.jpg';
    }
    // Mountain / highland
    if (query.contains('mountain') ||
        query.contains('nui') ||
        query.contains('hill') ||
        query.contains('pass') ||
        query.contains('terraced')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Sapa_rice_field.jpg/1280px-Sapa_rice_field.jpg';
    }
    // Temple / heritage
    if (query.contains('temple') ||
        query.contains('chua') ||
        query.contains('citadel') ||
        query.contains('heritage') ||
        query.contains('ancient')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/71/Hoi_An_night.jpg/1280px-Hoi_An_night.jpg';
    }
    // Waterfall / cave
    if (query.contains('waterfall') ||
        query.contains('cave') ||
        query.contains('thac') ||
        query.contains('hang')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Ban_Gioc_Waterfall_Cao_Bang.jpg/1280px-Ban_Gioc_Waterfall_Cao_Bang.jpg';
    }
    // Default — iconic Ha Long Bay
    return 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/Halong_bay_boats.jpg/1280px-Halong_bay_boats.jpg';
  }
}
