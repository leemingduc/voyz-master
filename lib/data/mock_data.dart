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
          'https://lh3.googleusercontent.com/aida-public/AB6AXuD80FbU1ZxfueAUUWKR7XyjmN9bvxplR8TDjnwnn8r7c8f17IHQCZVUOP3GzkryHJlsVWyK5mW4FYIPJapdR8Dt8dAnp9gfyvxIIw7e44v3DRwz0xaOOqLxDizWaY5JaVw_fH6WlPc5MuaBRLgNAaB4LYzfWvEpoFMzNSIdrd_5M6Lrvhneg8GES-JtcUlxZYyOFJeTt6AHdm1rtyuNmaR8cP4qbVNjWpqD0jSFeHWgNbUuhj_00vL53F8e7wsORrgn_7MDAGFlE_A',
      'matchPercent': 98,
      'rating': 4.5,
      'reviewCount': 120,
      'price': '~4.2M VNĐ',
      'aiInsight':
          'Perfect for your wellness budget. Dry season now — best conditions of the year.',
      'isTopMatch': true,
    },
    {
      'name': 'Phú Quốc, Vietnam',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCgsNyLnIesjUjaXFGT5ibGButcaojYwEP1xbYEpw6FW9Eqary49L_WAyhptrnwRDQ2SavSS8YI0HI6fRUjtRSMVkFMp0e49HHfHjp-sGbMF18wbQhqXoqCiuUaNpnWMGW8bRtI3GlqydnB7wSPnEbTKAXmMf6FveaHANavCrQvnLQYa4J2pb_xWbZt5H01XSoJcFniRBUxAFGXmC6T6Qa57VitgMB2M4GCo5t9eJb9qw6WaTJeBiqDZXxOdJZp0ov4xy6VffHLZIs',
      'matchPercent': 92,
      'rating': 5.0,
      'reviewCount': 450,
      'price': '~3.8M VNĐ',
      'aiInsight':
          'Great value for money. Suits your beach + relaxation preference.',
      'isTopMatch': false,
    },
    {
      'name': 'Đà Nẵng, Vietnam',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDKEZDG6D0KnziIG-l_8kLA4xvZJ4IIHPHUt5EHzzvRSyeHhJEPAzJHJ1KSBK2XjphQxjVnStF1-lUxr0Y8s0iw_C3VBS4bRxSVrBjVAorjxq1xC_5u8U98uJ7aLA_mqxtBXJxfiX9kBP4UWRAD8qvWPTFRCn4FXnLn8VadxI_n7T_f0MY6IIKLuswvo3QyyEkyEByEhSx1y5C4JzgYy6RoBf_JMBAgo9cRpGHwvwm3BYlAQdD66BBfzM10pfgjVwAi3F-MoD1FPZ0',
      'matchPercent': 85,
      'rating': 4.0,
      'reviewCount': 300,
      'price': '~3.5M VNĐ',
      'aiInsight':
          'Vibrant city with beautiful beaches and amazing street food.',
      'isTopMatch': false,
    },
  ];

  // ── Destination Detail ────────────────────────────────────────────────
  static const String detailHeroImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD9mKE5z6lt8WySqOaYHRkne9ZruciDlXdjhHmrzWfnUhZ75XOFLu6Gw80QNF4mFhsiDDNMcwAwWghAoSsirumh5QIWq0D2UH2syDIvaHu3e1Yu45V8bMec3pwRzR4UB63UwtE3Pu-Gm-g3FE9EG0SVGwYKnbYrh8e4wN0v60VTsCyRXXSTYfBGf5klyAdAtNqRkKOTkMDWUoFiS2XA2CeMRBaUkHfwDg9ZLryzs1gv1hBTWXKR8bAi5myXVQVxecOqw8uMi5tmUJ8';

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
