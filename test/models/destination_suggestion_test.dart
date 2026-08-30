import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/destination_suggestion.dart';

void main() {
  group('DestinationSuggestion image fallback', () {
    test('adds a fallback image when Supabase row has no image_url', () {
      final suggestion = DestinationSuggestion.fromSupabase({
        'name': 'Mystery Beach',
        'category': 'beach',
        'match_percent': 91,
      });

      expect(suggestion.imageUrl, isNotEmpty);
      expect(Uri.parse(suggestion.imageUrl).isAbsolute, isTrue);
    });

    test('adds a fallback image when cached map has no imageUrl', () {
      final suggestion = DestinationSuggestion.fromMap({
        'name': 'Mystery Mountain',
        'imageUrl': '',
      });

      expect(suggestion.imageUrl, isNotEmpty);
      expect(Uri.parse(suggestion.imageUrl).isAbsolute, isTrue);
    });
  });
}
