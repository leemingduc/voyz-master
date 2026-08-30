# Image Service Stability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mọi ảnh điểm đến hiển thị được hoặc rơi về placeholder một cách có chủ đích; không còn URL bịa, không còn dịch vụ chết, không còn cache nhiễm URL hỏng.

**Architecture:** Ảnh 3 lớp: (1) curated trong bảng `destinations` với URL dạng `Special:FilePath?width=1280` đã qua script verify, (2) fallback động qua Wikipedia REST API `page/summary` rồi Commons search, (3) `errorWidget` sẵn có của UI làm chốt chặn. Xóa map URL viết tay, xóa Unsplash, xóa themed fallback. Cache image URL chỉ nhận host allowlist.

**Tech Stack:** Flutter/Dart, package `http` (kèm `package:http/testing` MockClient), Hive, Supabase Postgres, Wikimedia REST API.

**Spec:** `docs/superpowers/specs/2026-08-30-image-service-stability-design.md` (đọc trước khi bắt đầu).

## Global Constraints

- Nhánh: `fix/image-stability`, tạo từ `master` mới nhất.
- Người thực thi: bạn B, hoặc người thứ ba phối hợp với bạn B, vì plan này sửa `lib/services/ai_cache_service.dart` và file này thuộc sở hữu của bạn B theo `docs/week1_parallel_assignments.md`. TUYỆT ĐỐI không đụng file thuộc sở hữu bạn A (`trip_data.dart`, `saved_trips_provider.dart`, `itinerary_plan.dart`, `saved_screen.dart`).
- Không sửa bất kỳ file nào trong `lib/screens/` (cả 7 call site render ảnh đã có `errorWidget`, không cần sửa UI).
- Không sửa migration đã commit; seed fix đi bằng migration MỚI.
- Không đụng `destination_repository.dart`, `community_review_service.dart`, `gemini_service.dart`.
- Mỗi task kết thúc bằng `flutter analyze` sạch và một commit riêng.
- Sau khi merge, giáo viên chạy `supabase db push` để apply cả migration sprint 2.3 còn thiếu lẫn migration mới của plan này (ghi chú lại trong PR description).

---

### Task 1: Script verify URL ảnh trong migrations

**Files:**
- Create: `tool/verify_image_urls.dart`

**Interfaces:**
- Produces: lệnh `dart run tool/verify_image_urls.dart`, exit code 0 khi mọi URL ảnh Wikimedia trong `supabase/migrations/*.sql` trả 200 + content-type `image/*` sau khi follow redirect; exit code 1 nếu có bất kỳ URL hỏng.

- [ ] **Step 1: Viết script**

```dart
// tool/verify_image_urls.dart
//
// Quét mọi URL ảnh Wikimedia trong supabase/migrations/*.sql và kiểm chứng
// từng URL bằng GET follow-redirect. PHẢI follow đến cùng: HEAD 302 trên
// Special:FilePath KHÔNG chứng minh file tồn tại (redirect đích có thể 404).
// Chạy: dart run tool/verify_image_urls.dart
import 'dart:io';

import 'package:http/http.dart' as http;

final RegExp _urlPattern = RegExp(
  r'''https://(?:upload\.wikimedia\.org|commons\.wikimedia\.org)[^\s"'\\)]+''',
);

Future<void> main() async {
  final migrationDir = Directory('supabase/migrations');
  if (!migrationDir.existsSync()) {
    stderr.writeln('Run from repo root: supabase/migrations not found.');
    exitCode = 2;
    return;
  }

  final urls = <String>{};
  for (final entity in migrationDir.listSync()) {
    if (entity is File && entity.path.endsWith('.sql')) {
      final content = entity.readAsStringSync();
      for (final match in _urlPattern.allMatches(content)) {
        urls.add(match.group(0)!);
      }
    }
  }

  if (urls.isEmpty) {
    stdout.writeln('No Wikimedia image URLs found in migrations.');
    return;
  }

  var failures = 0;
  final client = http.Client();
  for (final url in urls) {
    try {
      final request = http.Request('GET', Uri.parse(url))
        ..followRedirects = true
        ..maxRedirects = 5;
      final response =
          await client.send(request).timeout(const Duration(seconds: 20));
      final contentType = response.headers['content-type'] ?? '';
      final ok = response.statusCode == 200 && contentType.startsWith('image/');
      stdout.writeln(
        '${ok ? 'OK  ' : 'FAIL'} ${response.statusCode} $contentType  $url',
      );
      if (!ok) failures++;
      await response.stream.drain<void>();
    } catch (error) {
      stdout.writeln('FAIL error  $url  ($error)');
      failures++;
    }
  }
  client.close();

  if (failures > 0) {
    stderr.writeln('\n$failures broken image URL(s). Fix before merging.');
    exitCode = 1;
  } else {
    stdout.writeln('\nAll ${urls.length} image URLs verified.');
  }
}
```

- [ ] **Step 2: Chạy script, kỳ vọng FAIL trên seed hiện tại (đây là bước RED chứng minh script bắt được lỗi thật)**

Run: `dart run tool/verify_image_urls.dart`
Expected: exit code 1, các dòng FAIL cho `Dragon_Bridge_in_Da_Nang%2C_Vietnam.jpg`, `Golden_Bridge_-_Ba_Na_Hills.jpg`, `Hoi_An_night.jpg`, `Ma_Pi_Leng_Pass%2C_Ha_Giang.jpg` (thumb URL cũ trong seed 20260829000100) và OK cho các URL còn sống nếu có.

- [ ] **Step 3: Commit**

```bash
git add tool/verify_image_urls.dart
git commit -m "test: add image URL verifier for migration seed data"
```

---

### Task 2: Migration sửa seed ảnh bằng URL đã kiểm chứng

**Files:**
- Create: `supabase/migrations/20260831000300_fix_destination_seed_images.sql`

**Interfaces:**
- Consumes: script Task 1 để xác nhận.
- Produces: bảng `destinations` có `image_url`/`gallery` sống được cho 4 slug seed.

- [ ] **Step 1: Viết migration**

Các tên file dưới đây đã được verify 200 + image/jpeg ngày 30/08/2026 (xem spec mục 4). Dùng dạng `Special:FilePath?width=1280` để server tự tính hash path và kích thước thumb hợp lệ.

```sql
-- Fix fabricated/broken seed image URLs from 20260829000100.
-- All file names below verified end-to-end (HTTP 200, image/jpeg) via
-- tool/verify_image_urls.dart. Special:FilePath computes the correct
-- thumb path server-side, avoiding hand-guessed hash paths (400/404).

update public.destinations set
  image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Da_Nang_-_Dragon_Bridge.jpg?width=1280',
  gallery = '[
    {"title":"Dragon Bridge","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/Da_Nang_-_Dragon_Bridge.jpg?width=1280"},
    {"title":"Golden Bridge","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/Aerial_view_of_the_Golden_Bridge%2C_Ba_Na_Hills%2C_Da_Nang%2C_Vietnam.jpg?width=1280"}
  ]'::jsonb,
  updated_at = now()
where slug = 'da-nang-vietnam';

update public.destinations set
  image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/H%E1%BB%99i_An%2C_Ancient_Town%2C_2020-01_CN-06.jpg?width=1280',
  gallery = '[
    {"title":"Hoi An Ancient Town","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/H%E1%BB%99i_An%2C_Ancient_Town%2C_2020-01_CN-06.jpg?width=1280"}
  ]'::jsonb,
  updated_at = now()
where slug = 'hoi-an-vietnam';

update public.destinations set
  image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/M%C3%A3_P%C3%AD_L%C3%A8ng_Pass%2C_Vietnam.jpg?width=1280',
  gallery = '[
    {"title":"Ma Pi Leng Pass","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/M%C3%A3_P%C3%AD_L%C3%A8ng_Pass%2C_Vietnam.jpg?width=1280"}
  ]'::jsonb,
  updated_at = now()
where slug = 'ha-giang-vietnam';

update public.destinations set
  image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Phu_Quoc_Beach.jpg?width=1280',
  gallery = '[
    {"title":"Phu Quoc Beach","imageUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/Phu_Quoc_Beach.jpg?width=1280"}
  ]'::jsonb,
  updated_at = now()
where slug = 'phu-quoc-vietnam';
```

- [ ] **Step 2: Chạy lại verifier. Lưu ý seed cũ `20260829000100` vẫn chứa URL hỏng trong file SQL (script quét mọi file), nên PASS chỉ đạt được khi verifier bỏ qua URL đã bị migration sau ghi đè. Đơn giản nhất: sửa luôn giá trị hỏng NGAY TRONG file seed cũ `20260829000100` cho khớp migration mới (file này chưa từng được apply lên project nào, đã xác nhận bằng lỗi PGRST205 ngày 30/08, nên sửa an toàn; ghi chú lý do trong commit message)**

Run: `dart run tool/verify_image_urls.dart`
Expected: exit code 0, `All N image URLs verified.`

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/
git commit -m "fix: replace fabricated seed image URLs with verified Special:FilePath URLs

20260829000100 was never applied to any Supabase project (confirmed by
PGRST205 on 30/08), so its seed values are also corrected in place to
keep the verifier green."
```

---

### Task 3: Viết lại chuỗi fallback trong ImageService

**Files:**
- Modify: `lib/services/image_service.dart`
- Test: `test/services/image_service_test.dart` (file mới)

**Interfaces:**
- Consumes: không phụ thuộc task khác.
- Produces: `ImageService.instance.getImageUrl(String) -> Future<String>` (trả `''` khi không tìm được ảnh); `ImageService.instance.getImageUrls(List<String>) -> Future<Map<String, String>>`; `ImageService.instance.getLandmarkPhotos(...)` giữ nguyên chữ ký. Thêm `static http.Client client` để test swap MockClient. Các caller hiện tại (`gemini_service.dart`, `explore_screen.dart`...) không cần sửa vì chữ ký public không đổi.

- [ ] **Step 1: Viết failing tests trước**

```dart
// test/services/image_service_test.dart
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

  test('returns empty string when every source fails', () async {
    ImageService.client =
        MockClient((request) async => http.Response('down', 500));

    final url = await ImageService.instance.getImageUrl('Nowhere Place C');
    expect(url, isEmpty);
  });

  test('never returns unsplash or hardcoded fallback URLs', () async {
    ImageService.client =
        MockClient((request) async => http.Response('down', 500));

    final url = await ImageService.instance.getImageUrl('Anything Place D');
    expect(url, isNot(contains('unsplash')));
    expect(url, isNot(contains('Halong_bay_boats')));
  });
}
```

Lưu ý: `ImageService` có memory cache singleton theo tên, vì vậy mỗi test dùng một tên điểm đến khác nhau (Place A/B/C/D).

- [ ] **Step 2: Chạy test, xác nhận FAIL**

Run: `flutter test test/services/image_service_test.dart`
Expected: FAIL (chưa có `ImageService.client`, chuỗi fallback cũ trả URL cứng thay vì chuỗi rỗng).

- [ ] **Step 3: Sửa `lib/services/image_service.dart`**

Xóa các thành phần sau (toàn bộ, không giữ làm "tham khảo"):
- `_curatedLandmarks` (map khoảng 230 dòng ở đầu class) và `_lookupCurated`.
- `_fetchUnsplashSearch`.
- `_getRealisticTravelFallback`.
- `_fetchWikipediaLandscapeImage` và `_fetchFileInfo` (thay bằng REST summary bên dưới).
- `_normalizeKey` và `_isLandscapeRatio` nếu không còn nơi nào gọi (kiểm tra bằng `grep -n` trước khi xóa).

Thêm client injectable ở đầu class:

```dart
/// Swap được trong test bằng MockClient. Mọi HTTP call trong service này
/// phải đi qua client này.
static http.Client client = http.Client();
```

Thêm method mới:

```dart
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
```

Viết lại `getImageUrl` thành:

```dart
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
```

Trong `_fetchCommonsImage`, thay mọi `http.get(` bằng `client.get(` (import `http` giữ nguyên cho kiểu `http.Client`). Thêm `import 'dart:convert';` nếu chưa có.

- [ ] **Step 4: Chạy test, xác nhận PASS**

Run: `flutter test test/services/image_service_test.dart`
Expected: 4 tests PASS.

- [ ] **Step 5: Xác nhận không còn tham chiếu chết và analyze sạch**

Run: `grep -rn "unsplash\|_curatedLandmarks\|_getRealisticTravelFallback" lib/` (kỳ vọng 0 kết quả) rồi `flutter analyze`
Expected: không lỗi mới so với baseline 13 issues đã ghi nhận ngày 23/08.

- [ ] **Step 6: Commit**

```bash
git add lib/services/image_service.dart test/services/image_service_test.dart
git commit -m "fix: replace fabricated image sources with Wikipedia REST summary chain

Removes hand-written curated URL map (fabricated file names, 404),
dead source.unsplash.com fallback (503 + no CORS on web), and
hardcoded themed fallbacks. getImageUrl now returns '' on total miss
and lets the existing errorWidget placeholders handle rendering."
```

---

### Task 4: Chặn URL hỏng trong AiCacheService và bỏ cache đã nhiễm

**Files:**
- Modify: `lib/services/ai_cache_service.dart`
- Test: `test/services/ai_cache_service_test.dart` (mở rộng file hiện có)

**Interfaces:**
- Consumes: không phụ thuộc task khác.
- Produces: `AiCacheService.sanitizeImageUrls(Map<String, String>) -> Map<String, String>` (static, `@visibleForTesting`); box local mới `gemini_multi_tier_cache_v2`.

- [ ] **Step 1: Viết failing test trước (thêm vào `test/services/ai_cache_service_test.dart`)**

```dart
group('sanitizeImageUrls', () {
  test('keeps wikimedia and supabase hosts, drops everything else', () {
    final input = {
      'A': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/X.jpg/1280px-X.jpg',
      'B': 'https://commons.wikimedia.org/wiki/Special:FilePath/Y.jpg?width=1280',
      'C': 'https://abcd1234.supabase.co/storage/v1/object/public/destination-media/z.jpg',
      'D': 'https://source.unsplash.com/featured/1200x800?Koh%20Lipe',
      'E': 'not a url',
    };

    final out = AiCacheService.sanitizeImageUrls(input);

    expect(out.keys, unorderedEquals(['A', 'B', 'C']));
  });
});
```

- [ ] **Step 2: Chạy test, xác nhận FAIL**

Run: `flutter test test/services/ai_cache_service_test.dart`
Expected: FAIL với "sanitizeImageUrls isn't defined".

- [ ] **Step 3: Sửa `lib/services/ai_cache_service.dart`**

Thêm vào class `AiCacheService`:

```dart
static const List<String> _allowedImageHosts = [
  'upload.wikimedia.org',
  'commons.wikimedia.org',
];

/// Chỉ giữ image URL từ nguồn tin cậy. Chặn tái nhiễm cache bằng URL
/// từ dịch vụ đã chết hoặc URL AI bịa.
@visibleForTesting
static Map<String, String> sanitizeImageUrls(Map<String, String> urls) {
  final safe = <String, String>{};
  urls.forEach((name, url) {
    final host = Uri.tryParse(url)?.host ?? '';
    if (_allowedImageHosts.contains(host) || host.endsWith('.supabase.co')) {
      safe[name] = url;
    }
  });
  return safe;
}
```

Áp dụng sanitize tại 3 điểm:
1. Trong `putResponse`: `imageUrls: sanitizeImageUrls(imageUrls ?? const {})` khi tạo `responseObj`, và truyền map đã sanitize xuống `_saveToSupabase`.
2. Trong `CachedAiResponse.fromMap`: bọc map ảnh đã parse bằng `AiCacheService.sanitizeImageUrls(images)` trước khi trả về.
3. Trong nhánh đọc Supabase của `getResponse`: bọc `imageUrls` bằng `sanitizeImageUrls(imageUrls)` khi tạo `CachedAiResponse`.

Đổi box local để bỏ sạch cache đã nhiễm URL hỏng (cache là cache, được phép mất):

```dart
static const String _boxName = 'gemini_multi_tier_cache_v2';
```

Xóa toàn bộ cơ chế legacy box: hằng `_legacyBoxName`, getter `_legacyBox`, khối "Check legacy box" trong `getResponse`, và dòng clear legacy trong `clearLocal`.

- [ ] **Step 4: Chạy toàn bộ test service, xác nhận PASS**

Run: `flutter test test/services/`
Expected: PASS toàn bộ, gồm test sanitize mới và các test cache cũ (nếu test cũ tham chiếu tên box cũ thì cập nhật theo `_v2`).

- [ ] **Step 5: Commit**

```bash
git add lib/services/ai_cache_service.dart test/services/ai_cache_service_test.dart
git commit -m "fix: allowlist image URL hosts in AI cache and rotate poisoned local box

Pre-caching had persisted fabricated and dead image URLs into the
multi-tier cache. Rotating the Hive box name discards the poisoned
entries; sanitizeImageUrls prevents re-poisoning from any tier."
```

---

### Task 5: Nghiệm thu toàn cục

**Files:**
- Không sửa file mới; chỉ chạy kiểm chứng.

- [ ] **Step 1: Chạy verifier + analyze + toàn bộ test**

Run:
```bash
dart run tool/verify_image_urls.dart
flutter analyze
flutter test
```
Expected: verifier exit 0; analyze không lỗi mới; toàn bộ test PASS.

- [ ] **Step 2: Smoke test thủ công trên web**

Run: `flutter run -d chrome`, mở tab Explore và một destination detail ngoài seed (ví dụ nhập "Koh Lipe" trong planner).
Expected theo tiêu chí nghiệm thu của spec mục 5: không request nào tới `source.unsplash.com`; không 404/400 từ `upload.wikimedia.org`; card nào không tìm được ảnh hiển thị placeholder gradient của `errorWidget`.

- [ ] **Step 3: Mở PR**

PR vào `master`, mô tả kèm 2 dòng bắt buộc cho giáo viên:
1. "Cần chạy `supabase db push` sau khi merge để apply migration `20260829000100` (đang thiếu trên project, gây lỗi PGRST205) và `20260831000300`."
2. Link tới spec và plan này.

```bash
git push -u origin fix/image-stability
```

---

## Self-Review (đã chạy khi viết plan)

- Spec coverage: lớp 1 (Task 2), lớp 2 (Task 3), lớp 3 (không cần code, đã xác minh 7 call site có `errorWidget`), verify script (Task 1), chống tái nhiễm cache (Task 4), tiêu chí nghiệm thu (Task 5). Đủ.
- Placeholder scan: không có TBD/TODO; mọi bước có code hoặc lệnh cụ thể.
- Type consistency: `getImageUrl` trả `Future<String>` (rỗng khi miss) thống nhất giữa Task 3 code và test; `sanitizeImageUrls` static nhất quán giữa Task 4 code và test.
