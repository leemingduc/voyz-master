import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voyz/services/image_service.dart';

void main() {
  test('uses 1280px thumbnail when original image is large enough', () async {
    ImageService.client = MockClient((request) async {
      if (request.url.host == 'vi.wikipedia.org' &&
          request.url.path.contains('/page/summary/')) {
        return http.Response(
          jsonEncode({
            'thumbnail': {
              'source':
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Test.jpg/320px-Test.jpg',
              'width': 320,
              'height': 213,
            },
            'originalimage': {
              'source':
                  'https://upload.wikimedia.org/wikipedia/commons/b/bf/Test.jpg',
              'width': 4000,
              'height': 2600,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });

    final url = await ImageService.instance.getImageUrl('Large Place A');
    expect(url, contains('/1280px-'));
  });

  test('keeps original thumbnail when source image is small', () async {
    ImageService.client = MockClient((request) async {
      if (request.url.host == 'vi.wikipedia.org' &&
          request.url.path.contains('/page/summary/')) {
        return http.Response(
          jsonEncode({
            'thumbnail': {
              'source':
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Small.jpg/320px-Small.jpg',
              'width': 320,
              'height': 213,
            },
            'originalimage': {
              'source':
                  'https://upload.wikimedia.org/wikipedia/commons/b/bf/Small.jpg',
              'width': 800,
              'height': 520,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });

    final url = await ImageService.instance.getImageUrl('Small Place B');
    expect(url, contains('/320px-'));
    expect(url, isNot(contains('/1280px-')));
  });

  test('falls back to English summary when Vietnamese page is missing',
      () async {
    ImageService.client = MockClient((request) async {
      if (request.url.host == 'en.wikipedia.org' &&
          request.url.path.contains('/page/summary/')) {
        return http.Response(
          jsonEncode({
            'thumbnail': {
              'source':
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/En.jpg/640px-En.jpg',
              'width': 640,
              'height': 420,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });

    final url = await ImageService.instance.getImageUrl('English Place C');
    expect(url, contains('En.jpg'));
  });

  test('returns empty string when every source fails', () async {
    ImageService.client =
        MockClient((request) async => http.Response('down', 500));

    final url = await ImageService.instance.getImageUrl('Nowhere Place D');
    expect(url, isEmpty);
  });

  test('never returns unsplash, loremflickr, or hardcoded fallback URLs',
      () async {
    ImageService.client =
        MockClient((request) async => http.Response('down', 500));

    final url = await ImageService.instance.getImageUrl('Anything Place E');
    expect(url, isNot(contains('unsplash')));
    expect(url, isNot(contains('loremflickr')));
    expect(url, isNot(contains('Halong_bay_boats')));
  });

  test('rejects blocklisted images (maps, flags, logos)', () async {
    ImageService.client = MockClient((request) async {
      if (request.url.path.contains('/page/summary/')) {
        return http.Response(
          jsonEncode({
            'thumbnail': {
              'source':
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Location_map_region.png/320px-Location_map_region.png',
              'width': 320,
              'height': 320,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });

    final url = await ImageService.instance.getImageUrl('Map Place F');
    expect(url, isEmpty);
  });

  group('language order', () {
    test('hasVietnameseDiacritics detects accented names', () {
      expect(ImageService.hasVietnameseDiacritics('Đà Lạt'), isTrue);
      expect(ImageService.hasVietnameseDiacritics('Hội An'), isTrue);
      expect(ImageService.hasVietnameseDiacritics('Da Lat'), isFalse);
      expect(ImageService.hasVietnameseDiacritics('Kyoto'), isFalse);
    });

    test('unaccented name asks en first and skips vi when en has an image',
        () async {
      final hosts = <String>[];
      ImageService.client = MockClient((request) async {
        hosts.add(request.url.host);
        if (request.url.host == 'en.wikipedia.org') {
          return http.Response(
            jsonEncode({
              'thumbnail': {
                'source':
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Lang.jpg/640px-Lang.jpg',
                'width': 640,
                'height': 420,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });

      final url = await ImageService.instance.getImageUrl('Lang Place G');
      expect(url, contains('Lang.jpg'));
      expect(hosts, ['en.wikipedia.org']);
    });

    test('accented name asks vi first', () async {
      final hosts = <String>[];
      ImageService.client = MockClient((request) async {
        hosts.add(request.url.host);
        return http.Response('not found', 404);
      });

      await ImageService.instance.getImageUrl('Đà Lạt Place H');
      expect(hosts.first, 'vi.wikipedia.org');
      expect(hosts[1], 'en.wikipedia.org');
    });
  });

  group('negative cache', () {
    tearDown(() {
      ImageService.now = DateTime.now;
    });

    test('empty result is not refetched within 10 minutes', () async {
      var calls = 0;
      ImageService.client = MockClient((request) async {
        calls++;
        return http.Response('not found', 404);
      });
      final t0 = DateTime(2026, 9, 19, 10, 0);
      ImageService.now = () => t0;

      await ImageService.instance.getImageUrl('Empty Place I');
      final firstRoundCalls = calls;
      expect(firstRoundCalls, greaterThan(0));

      ImageService.now = () => t0.add(const Duration(minutes: 9));
      await ImageService.instance.getImageUrl('Empty Place I');
      expect(calls, firstRoundCalls);
    });

    test('empty result is refetched after 10 minutes', () async {
      var calls = 0;
      ImageService.client = MockClient((request) async {
        calls++;
        return http.Response('not found', 404);
      });
      final t0 = DateTime(2026, 9, 19, 11, 0);
      ImageService.now = () => t0;

      await ImageService.instance.getImageUrl('Empty Place J');
      final firstRoundCalls = calls;

      ImageService.now = () => t0.add(const Duration(minutes: 11));
      await ImageService.instance.getImageUrl('Empty Place J');
      expect(calls, greaterThan(firstRoundCalls));
    });
  });
}
