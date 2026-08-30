import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/destination_suggestion.dart';

void main() {
  group('DestinationSuggestion image url contract', () {
    // Ảnh rỗng là trạng thái hợp lệ: UI có errorWidget placeholder ở mọi
    // call site. Model KHÔNG được tự chèn fallback URL cứng, vì đó chính là
    // nguồn của các URL bịa/chết trước đây (xem spec
    // docs/superpowers/specs/2026-08-30-image-service-stability-design.md).
    test('keeps image empty when Supabase row has no image_url', () {
      final suggestion = DestinationSuggestion.fromSupabase({
        'name': 'Mystery Beach',
        'category': 'beach',
        'match_percent': 91,
      });

      expect(suggestion.imageUrl, isEmpty);
    });

    test('keeps image empty when cached map has no imageUrl', () {
      final suggestion = DestinationSuggestion.fromMap({
        'name': 'Mystery Mountain',
        'imageUrl': '',
      });

      expect(suggestion.imageUrl, isEmpty);
    });

    test('passes a real image url through unchanged', () {
      const url =
          'https://commons.wikimedia.org/wiki/Special:FilePath/Phu_Quoc_Beach.jpg?width=1280';
      final suggestion = DestinationSuggestion.fromSupabase({
        'name': 'Phu Quoc, Vietnam',
        'image_url': url,
      });

      expect(suggestion.imageUrl, url);
    });
  });
}
