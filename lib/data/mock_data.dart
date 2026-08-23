/// Static mock data extracted from Stitch design screens.
///
/// All text, URLs, and lists live here so widgets stay purely presentational.
class MockData {
  MockData._();

  // ── App Branding ──────────────────────────────────────────────────────
  static const String appName = 'AIVIVU';

  // ── Smart Planner ─────────────────────────────────────────────────────

  static const String profileImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCWKzJjIC-bCxkKLNaEMpT1-pEwOTknOSyDbRwNxHcwt3sePJQsJYIdFLMQUs8hwT-JRUBOzHiyDr85CdA2-3heHgP_k-aGXNenCqzpTSZnT7579AJv7FaUfT9F6Ec5OgKDuwIr2G8FXEwiTwrSMxnzxjvRvFa8isrU2XoG-mGZmNI_OxGjbza5ikkwPjcvbQfmXsiLCCShCt0dzMpEvXVNWIlFGuuKfpT-kcO6AhtYrF2A-4PRAhNNU2YZF-gOaCSzzUFrHUGL8HQ';

  static const List<String> interests = [
    'beach',
    'adventure',
    'culture',
    'food',
    'wellness',
  ];

  static const List<bool> interestsSelected = [true, false, false, true, false];

  static const List<String> currencies = ['VNĐ', 'USD', 'EUR', 'THB'];

  // ── Suggestions ───────────────────────────────────────────────────────
  static const String suggestionsSearchSummary =
      'Bali, Indonesia · 3 days · 5M VNĐ';

  static const List<Map<String, dynamic>> destinations = [
    {
      'name': 'Côn Đảo, Vietnam',
      'imageUrl':
          'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?auto=format&fit=crop&w=1200&q=80',
      'matchPercent': 98,
      'rating': 4.7,
      'reviewCount': 1420,
      'price': '~4.8M VNĐ',
      'aiInsight':
          'Bãi biển nguyên sơ, làn nước trong xanh màu ngọc bích và không gian nghỉ dưỡng tĩnh lặng hoàn hảo.',
      'isTopMatch': true,
    },
    {
      'name': 'Phú Quốc, Vietnam',
      'imageUrl':
          'https://images.unsplash.com/photo-1589308078059-be1415eab4c3?auto=format&fit=crop&w=1200&q=80',
      'matchPercent': 92,
      'rating': 4.8,
      'reviewCount': 3250,
      'price': '~5.2M VNĐ',
      'aiInsight':
          'Bãi Sao cát trắng mịn, hoàng hôn rực rỡ tại Thị trấn Hoàng Hôn và ẩm thực hải sản phong phú.',
      'isTopMatch': false,
    },
    {
      'name': 'Đà Nẵng, Vietnam',
      'imageUrl':
          'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1200&q=80',
      'matchPercent': 88,
      'rating': 4.6,
      'reviewCount': 4100,
      'price': '~4.5M VNĐ',
      'aiInsight':
          'Thành phố biển đáng sống, Cầu Vàng Bà Nà Hills và bãi biển Mỹ Khê tuyệt đẹp.',
      'isTopMatch': false,
    },
  ];

  // ── Destination Detail ────────────────────────────────────────────────
  static const String detailHeroImageUrl =
      'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?auto=format&fit=crop&w=1200&q=80';

  static const String detailLocation = 'Ba Ria - Vung Tau';
  static const String detailName = 'Côn Đảo, Vietnam';
  static const String detailWeather = 'Sunny, 32°C';
  static const String detailDateRange = 'Mar 15 - Mar 18';
  static const String detailBudget = '~4.2M VNĐ';

  static const List<String> detailTags = [
    '🌿 Wellness',
    '🏖️ Beach',
    '🤿 Diving',
    '🌅 Scenic',
  ];

  static const List<Map<String, dynamic>> budgetBreakdown = [
    {
      'label': 'Transport',
      'amount': '1.7M VNĐ',
      'fraction': 0.40,
      'icon': 'flight',
    },
    {'label': 'Stay', 'amount': '1.2M VNĐ', 'fraction': 0.30, 'icon': 'hotel'},
    {'label': 'Food', 'amount': '0.8M VNĐ', 'fraction': 0.20, 'icon': 'restaurant'},
    {
      'label': 'Activities',
      'amount': '0.5M VNĐ',
      'fraction': 0.10,
      'icon': 'kayaking',
    },
  ];

  // ── Destination Plan (Itinerary) ──────────────────────────────────────
  static const List<String> dayTabs = ['Day 1', 'Day 2', 'Day 3'];

  static const String dayTitle = 'Day 1: Arrival & Coastal Relaxation';
  static const String daySubtitle =
      'Experience the serene beauty of the islands.';

  static const String proTip =
      'Book your evening spa session 2 hours in advance for the best view.';

  static const List<Map<String, dynamic>> itineraryItems = [
    {
      'time': '09:00 AM',
      'title': 'Arrival at Con Dao Airport',
      'description':
          'Smooth landing at VCS. Your private transfer will be waiting outside.',
      'icon': 'flight_land',
      'isFirst': true,
    },
    {
      'time': '11:00 AM',
      'title': 'Check-in at Beachfront Resort',
      'description':
          'Drop your bags and enjoy a complimentary welcome drink with a sea view.',
      'icon': 'hotel',
      'isFirst': false,
    },
    {
      'time': '01:00 PM',
      'title': 'Lunch at Local Seafood Hut',
      'description':
          "Try the famous 'Oc Vu Nang' and grilled calamari by the shore.",
      'icon': 'restaurant',
      'isFirst': false,
    },
    {
      'time': '03:00 PM',
      'title': 'Sunset Beach Walk',
      'description':
          'Stroll along the white sands as the sky turns into a canvas of pink and orange.',
      'icon': 'beach_access',
      'isFirst': false,
    },
  ];
}
