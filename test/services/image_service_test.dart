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
}
