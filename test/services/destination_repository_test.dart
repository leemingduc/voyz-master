import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/services/destination_repository.dart';

void main() {
  test('curated Explore rows do not mark a destination as the top match', () {
    final items = featuredSuggestionsFromRows([
      {
        'destinations': {
          'name': 'Da Lat, Vietnam',
          'image_url': 'https://upload.wikimedia.org/example.jpg',
          'match_percent': 90,
          'rating': 0,
          'review_count': 0,
          'price': '~3.5M VND',
          'ai_insight': 'Cool mountain air.',
        },
      },
      {
        'destinations': {
          'name': 'Phu Quoc, Vietnam',
          'image_url': 'https://upload.wikimedia.org/example-2.jpg',
          'match_percent': 90,
          'rating': 0,
          'review_count': 0,
          'price': '~4M VND',
          'ai_insight': 'Island escape.',
        },
      },
    ]);

    expect(items, hasLength(2));
    expect(items.every((item) => !item.isTopMatch), isTrue);
  });
}
