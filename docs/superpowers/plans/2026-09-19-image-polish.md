# Image Polish Implementation Plan (roadmap 2.4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mọi ảnh điểm đến lỗi trong app trông giống nhau, và `ImageService` tốn ít request hơn (đúng ngôn ngữ trước, không tra lại kết quả rỗng trong 10 phút, chạy theo lô 3), gallery landmark không còn ô trống, Explore fallback được khi Supabase lỗi.

**Architecture:** Một widget mới `DestinationImage` bọc `CachedNetworkImage` với ba trạng thái và thay sáu call site. `ImageService` giữ nguyên chuỗi nguồn (Wikipedia REST vi/en rồi Commons) nhưng đổi thứ tự ngôn ngữ theo dấu tiếng Việt, cache rỗng có hạn, và giới hạn 3 request đồng thời. `GeminiService._parseDetail` điền ảnh chính vào landmark rỗng qua một hàm thuần test được. Không đổi nguồn ảnh, không đổi model, không đổi DB.

**Tech Stack:** Flutter, `cached_network_image`, `http` + `MockClient` (package `http/testing.dart`) cho test.

**Spec:** `docs/superpowers/specs/2026-09-19-image-polish-design.md`

## Global Constraints

- Nhánh `image-polish` đã tách từ `master` (`a2e90cd`). Không push lên `master`. Xong thì mở PR.
- Trước PR: `flutter analyze` không lỗi mới, `flutter test` pass, `dart run tool/verify_image_urls.dart` pass.
- Không dùng em dash hay en dash trong bất kỳ text nào (code, comment, commit).
- Không hardcode URL ảnh. Không thêm nguồn ảnh mới. Không sửa `tool/verify_image_urls.dart`.
- Không đụng ba avatar (`friends_screen.dart`, `account_menu_button.dart`, `profile_screen.dart`), không đụng `supabase/`, không đụng `lib/data/`.
- Không widget test (bar của project). Widget được kiểm bằng `flutter analyze` và nghiệm thu tay.
- Không commit các file `ios/`, `macos/` đang thay đổi sẵn trong working tree (xcconfig, Podfile). Chỉ `git add` đúng file của task.
- Mỗi test trong `image_service_test.dart` dùng tên điểm đến riêng (như hiện tại) vì `ImageService.instance` là singleton có cache trong memory dùng chung giữa các test.

---

### Task 1: Widget chung `DestinationImage`

**Files:**
- Create: `lib/widgets/shared/destination_image.dart`

**Interfaces:**
- Produces: `DestinationImage({required String imageUrl, required String destinationName, BoxFit fit = BoxFit.cover, BorderRadius? borderRadius})`. Task 2 dùng đúng chữ ký này.

- [ ] **Step 1: Tạo file widget**

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:voyz/theme/app_theme.dart';

/// Ảnh điểm đến dùng chung cho mọi màn hình.
///
/// Ba trạng thái, một kiểu nhìn:
/// - `imageUrl` rỗng: vẽ fallback ngay, không tạo request mạng.
/// - Đang tải: nền gradient tối, không spinner.
/// - Lỗi tải: cùng gradient, thêm icon núi và tên điểm đến mờ.
///
/// Widget chỉ lo phần ảnh. Overlay, badge, tiêu đề vẫn nằm trong Stack
/// của màn hình gọi.
class DestinationImage extends StatelessWidget {
  const DestinationImage({
    super.key,
    required this.imageUrl,
    required this.destinationName,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String imageUrl;
  final String destinationName;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget image = imageUrl.isEmpty
        ? _Fallback(name: destinationName)
        : CachedNetworkImage(
            imageUrl: imageUrl,
            fit: fit,
            placeholder: (_, _) => const _Fallback(name: null),
            errorWidget: (_, _, _) => _Fallback(name: destinationName),
          );
    final radius = borderRadius;
    if (radius == null) return image;
    return ClipRRect(borderRadius: radius, child: image);
  }
}

/// Nền gradient tối. `name == null` là trạng thái đang tải (không icon, không chữ).
class _Fallback extends StatelessWidget {
  const _Fallback({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final label = name;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceDark, AppTheme.backgroundDark],
        ),
      ),
      child: label == null
          ? null
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.landscape,
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  if (label.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/widgets/shared/destination_image.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/shared/destination_image.dart
git commit -m "feat: DestinationImage shared widget with one fallback look for empty, loading, and error states

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Thay sáu call site bằng `DestinationImage`

**Files:**
- Modify: `lib/screens/suggestions_screen.dart` (dòng 2 import, khoảng dòng 399 trong `_CardImage.build`)
- Modify: `lib/screens/saved_screen.dart` (dòng 2 import, khoảng dòng 295)
- Modify: `lib/screens/explore_screen.dart` (dòng 2 import, khoảng dòng 401)
- Modify: `lib/screens/cultural_tips_screen.dart` (dòng 2 import, khoảng dòng 230-238, xoá hàm `_gradientFallback` khoảng dòng 271-289)
- Modify: `lib/screens/destination_detail_screen.dart` (dòng 4 import, `_HeroSection` khoảng dòng 426-430 và 649-676, ô gallery khoảng dòng 1253-1268)

**Interfaces:**
- Consumes: `DestinationImage` từ Task 1.

Quy tắc chung cho mọi chỗ: giữ nguyên `Stack`, overlay gradient, badge, tiêu đề xung quanh. Chỉ thay đúng node `CachedNetworkImage(...)` bằng `DestinationImage(...)`. Sau khi thay, file nào không còn `CachedNetworkImage` thì xoá dòng `import 'package:cached_network_image/cached_network_image.dart';` và thêm `import 'package:voyz/widgets/shared/destination_image.dart';` (giữ import theo thứ tự alphabet như các import `package:voyz/...` khác).

- [ ] **Step 1: `suggestions_screen.dart`**

Trong `_CardImage.build`, thay:

```dart
          CachedNetworkImage(
            imageUrl: data['imageUrl'] as String,
            fit: BoxFit.cover,
            errorWidget: (_, e, s) => Container(
              color: const Color(0xFF1E293B),
              child: const Icon(Icons.image, color: Colors.white24, size: 48),
            ),
          ),
```

bằng:

```dart
          DestinationImage(
            imageUrl: data['imageUrl'] as String,
            destinationName: data['name'] as String,
          ),
```

Đổi import như quy tắc chung.

- [ ] **Step 2: `saved_screen.dart`**

Thay:

```dart
                CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, e, s) => Container(
                    color: const Color(0xFF1E293B),
                    child: const Icon(
                      Icons.image,
                      color: Colors.white24,
                      size: 48,
                    ),
                  ),
                ),
```

bằng:

```dart
                DestinationImage(
                  imageUrl: item.imageUrl,
                  destinationName: item.name,
                ),
```

Đổi import như quy tắc chung.

- [ ] **Step 3: `explore_screen.dart`**

Thay:

```dart
                    CachedNetworkImage(
                      imageUrl: destination.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: const Color(0xFF1E1B2E),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: const Color(0xFF1E1B2E),
                        child: const Icon(
                          Icons.landscape,
                          color: Colors.white24,
                          size: 48,
                        ),
                      ),
                    ),
```

bằng:

```dart
                    DestinationImage(
                      imageUrl: destination.imageUrl,
                      destinationName: destination.name,
                    ),
```

Đổi import như quy tắc chung.

- [ ] **Step 4: `cultural_tips_screen.dart`**

Thay khối if/else:

```dart
            if (tips.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: tips.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    _gradientFallback(tips.destinationName),
              )
            else
              _gradientFallback(tips.destinationName),
```

bằng:

```dart
            DestinationImage(
              imageUrl: tips.imageUrl,
              destinationName: tips.destinationName,
            ),
```

Xoá toàn bộ hàm `Widget _gradientFallback(String name) { ... }` (từ dòng khai báo tới dấu `}` đóng của nó, khoảng 19 dòng). Đổi import như quy tắc chung. Nếu `AppTheme` không còn dùng chỗ nào khác trong file thì analyzer sẽ báo unused import, khi đó xoá luôn dòng import `app_theme.dart`.

- [ ] **Step 5: `destination_detail_screen.dart` hero**

Thêm field `destinationName` vào `_HeroSection`:

```dart
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.theme,
    required this.imageUrl,
    required this.destinationName,
    required this.onShare,
  });
  final ThemeData theme;
  final String imageUrl;
  final String destinationName;
  final VoidCallback onShare;
```

Chỗ gọi (khoảng dòng 426) thêm tham số:

```dart
                child: _HeroSection(
                  theme: theme,
                  imageUrl: _activeHeroUrl ?? d.imageUrl,
                  destinationName: d.name,
                  onShare: () => _onShare(context),
                ),
```

Trong `_HeroSection.build`, thay:

```dart
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            errorWidget: (ctx, url, err) =>
                Container(color: const Color(0xFF1E293B)),
          ),
```

bằng:

```dart
          DestinationImage(
            imageUrl: imageUrl,
            destinationName: destinationName,
          ),
```

- [ ] **Step 6: `destination_detail_screen.dart` gallery**

Trong `_LandmarkGallerySectionState`, ô gallery (bên trong `ClipRRect` > `Stack`), thay:

```dart
                        CachedNetworkImage(
                          imageUrl: photo.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            color: const Color(0xFF1E1B2E),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: const Color(0xFF1E1B2E),
                            child: const Icon(
                              Icons.landscape,
                              color: Colors.white24,
                            ),
                          ),
                        ),
```

bằng:

```dart
                        DestinationImage(
                          imageUrl: photo.imageUrl,
                          destinationName: photo.title,
                        ),
```

File này giờ không còn `CachedNetworkImage`, đổi import như quy tắc chung.

- [ ] **Step 7: Kiểm không còn call site tự viết**

Run: `grep -rn "CachedNetworkImage\|cached_network_image" lib/screens lib/widgets`
Expected: chỉ còn `lib/screens/profile_screen.dart` (avatar, ngoài phạm vi) và `lib/widgets/shared/destination_image.dart`.

- [ ] **Step 8: Analyze và test**

Run: `flutter analyze && flutter test`
Expected: analyze không có lỗi mới (19 info/warning có sẵn trên master là bình thường), `All tests passed!`

- [ ] **Step 9: Commit**

```bash
git add lib/screens/suggestions_screen.dart lib/screens/saved_screen.dart lib/screens/explore_screen.dart lib/screens/cultural_tips_screen.dart lib/screens/destination_detail_screen.dart
git commit -m "refactor: six destination image call sites use DestinationImage, drop per-screen fallbacks

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: `ImageService` hỏi đúng ngôn ngữ trước (TDD)

**Files:**
- Modify: `lib/services/image_service.dart` (dòng 1-5 import, dòng 30-48 `getImageUrl`)
- Test: `test/services/image_service_test.dart`

**Interfaces:**
- Produces: `static bool hasVietnameseDiacritics(String s)` trên `ImageService`, `@visibleForTesting`.

- [ ] **Step 1: Viết test fail**

Thêm vào cuối `main()` trong `test/services/image_service_test.dart`:

```dart
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
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/services/image_service_test.dart`
Expected: FAIL, lỗi biên dịch `hasVietnameseDiacritics` không tồn tại.

- [ ] **Step 3: Sửa `image_service.dart`**

Thêm import (sau `dart:convert`):

```dart
import 'package:flutter/foundation.dart';
```

Thêm vào class `ImageService`, ngay sau `final Map<String, String> _cache = {};`:

```dart
  static final _vietnameseDiacritics = RegExp(
    r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
    caseSensitive: false,
  );

  /// Tên có dấu tiếng Việt thì trang vi.wikipedia gần như chắc chắn tồn tại,
  /// nên hỏi vi trước. Tên không dấu (đa số tên AI sinh) hỏi en trước để
  /// tránh một request 404 thừa.
  @visibleForTesting
  static bool hasVietnameseDiacritics(String s) =>
      _vietnameseDiacritics.hasMatch(s);
```

Trong `getImageUrl`, thay hai dòng:

```dart
    String? url = await _fetchWikipediaSummaryImage(placeName, 'vi');
    url ??= await _fetchWikipediaSummaryImage(placeName, 'en');
```

bằng:

```dart
    final langs = hasVietnameseDiacritics(placeName)
        ? const ['vi', 'en']
        : const ['en', 'vi'];
    String? url;
    for (final lang in langs) {
      url = await _fetchWikipediaSummaryImage(placeName, lang);
      if (url != null) break;
    }
```

Sửa doc comment đầu class, dòng `1. Wikipedia REST summary (vi rồi en)` thành `1. Wikipedia REST summary (vi rồi en với tên có dấu, en rồi vi với tên không dấu)`.

- [ ] **Step 4: Chạy toàn bộ test file**

Run: `flutter test test/services/image_service_test.dart`
Expected: PASS toàn bộ. Lưu ý: hai test cũ `uses 1280px thumbnail...` và `keeps original thumbnail...` mock host `vi.wikipedia.org` với tên không dấu ("Large Place A"). Sau thay đổi, request đầu đi `en` (404 trong mock) rồi mới `vi` (200), nên kết quả vẫn đúng và test vẫn pass. Không sửa hai test đó.

- [ ] **Step 5: Commit**

```bash
git add lib/services/image_service.dart test/services/image_service_test.dart
git commit -m "feat: ImageService asks en.wikipedia first for unaccented names, vi first for accented names

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Cache kết quả rỗng có hạn 10 phút (TDD)

**Files:**
- Modify: `lib/services/image_service.dart` (`_cache`, `getImageUrl`)
- Test: `test/services/image_service_test.dart`

**Interfaces:**
- Produces: `static DateTime Function() now = DateTime.now;` và `static const negativeTtl = Duration(minutes: 10);` trên `ImageService`.

- [ ] **Step 1: Viết test fail**

Thêm group mới vào cuối `main()`:

```dart
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
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/services/image_service_test.dart`
Expected: FAIL, lỗi biên dịch `now` không tồn tại.

- [ ] **Step 3: Sửa `image_service.dart`**

Thay dòng `final Map<String, String> _cache = {};` bằng:

```dart
  /// Cache trong phiên. URL tìm được giữ suốt phiên; URL rỗng chỉ giữ
  /// [negativeTtl] để một lần lỗi mạng không làm điểm đến mất ảnh tới khi
  /// restart.
  final Map<String, ({String url, DateTime fetchedAt})> _cache = {};

  static const negativeTtl = Duration(minutes: 10);

  /// Swap được trong test để đẩy thời gian.
  static DateTime Function() now = DateTime.now;
```

Trong `getImageUrl`, thay:

```dart
    if (_cache.containsKey(destinationName)) {
      return _cache[destinationName]!;
    }
```

bằng:

```dart
    final hit = _cache[destinationName];
    if (hit != null) {
      final stillFresh =
          hit.url.isNotEmpty || now().difference(hit.fetchedAt) < negativeTtl;
      if (stillFresh) return hit.url;
    }
```

và thay:

```dart
    final result = url ?? '';
    _cache[destinationName] = result;
    return result;
```

bằng:

```dart
    final result = url ?? '';
    _cache[destinationName] = (url: result, fetchedAt: now());
    return result;
```

- [ ] **Step 4: Chạy test**

Run: `flutter test test/services/image_service_test.dart`
Expected: PASS toàn bộ.

- [ ] **Step 5: Commit**

```bash
git add lib/services/image_service.dart test/services/image_service_test.dart
git commit -m "feat: ImageService retries empty image lookups after 10 minutes instead of caching them for the session

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Tra ảnh theo lô 3 (TDD)

**Files:**
- Modify: `lib/services/image_service.dart` (`getImageUrls`, `getLandmarkPhotos`)
- Test: `test/services/image_service_test.dart`

**Interfaces:**
- Produces: `static const batchSize = 3;` trên `ImageService`. Chữ ký `getImageUrls(List<String>)` và `getLandmarkPhotos(String, List<String>)` không đổi.

- [ ] **Step 1: Viết test fail**

Thêm vào cuối `main()`:

```dart
  test('getImageUrls runs at most 3 lookups at a time', () async {
    var inFlight = 0;
    var maxInFlight = 0;
    ImageService.client = MockClient((request) async {
      inFlight++;
      if (inFlight > maxInFlight) maxInFlight = inFlight;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      inFlight--;
      return http.Response('not found', 404);
    });

    final names = List.generate(7, (i) => 'Batch Place K$i');
    final urls = await ImageService.instance.getImageUrls(names);

    expect(urls.length, 7);
    expect(maxInFlight, lessThanOrEqualTo(ImageService.batchSize));
    expect(maxInFlight, greaterThan(1));
  });
```

Ghi chú cho người làm: mỗi tên chạy en, vi, Commons tuần tự (một request tại một thời điểm cho một tên), nên số request đồng thời đúng bằng số tên đang chạy song song. `Future.wait` toàn bộ 7 tên sẽ cho `maxInFlight == 7` và test fail.

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/services/image_service_test.dart`
Expected: FAIL, lỗi biên dịch `batchSize` không tồn tại.

- [ ] **Step 3: Sửa `image_service.dart`**

Thêm sau `static const negativeTtl`:

```dart
  /// Số tên tra song song tối đa. Bắn cả 10 gợi ý cùng lúc (tới 30 request)
  /// dễ dính 429 từ Wikimedia.
  static const batchSize = 3;
```

Thay toàn bộ `getImageUrls` và `getLandmarkPhotos`:

```dart
  /// Tra URL ảnh cho nhiều điểm đến, tối đa [batchSize] tên song song.
  Future<Map<String, String>> getImageUrls(List<String> names) async {
    final urls = await _inBatches(names, getImageUrl);
    return {for (int i = 0; i < names.length; i++) names[i]: urls[i]};
  }

  /// Tra ảnh cho từng landmark của một điểm đến, tối đa [batchSize] song song.
  /// Landmark không có ảnh trả `imageUrl` rỗng; GeminiService điền ảnh chính
  /// của điểm đến vào chỗ rỗng.
  Future<List<DestinationLandmarkPhoto>> getLandmarkPhotos(
    String destinationName,
    List<String> landmarkTitles,
  ) async {
    final urls = await _inBatches(landmarkTitles, (title) {
      final query = title.isNotEmpty ? '$title, $destinationName' : destinationName;
      return getImageUrl(query);
    });
    return [
      for (int i = 0; i < landmarkTitles.length; i++)
        DestinationLandmarkPhoto(title: landmarkTitles[i], imageUrl: urls[i]),
    ];
  }

  /// Chạy [run] trên từng phần tử, [batchSize] phần tử một lúc, giữ thứ tự.
  Future<List<String>> _inBatches(
    List<String> items,
    Future<String> Function(String) run,
  ) async {
    final results = <String>[];
    for (var i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      results.addAll(await Future.wait(items.sublist(i, end).map(run)));
    }
    return results;
  }
```

- [ ] **Step 4: Chạy test**

Run: `flutter test test/services/image_service_test.dart`
Expected: PASS toàn bộ.

- [ ] **Step 5: Commit**

```bash
git add lib/services/image_service.dart test/services/image_service_test.dart
git commit -m "feat: ImageService looks up images in batches of 3 instead of fanning out every name at once

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Landmark rỗng lấy ảnh chính (TDD)

**Files:**
- Modify: `lib/services/gemini_service.dart` (`_parseDetail`, khoảng dòng 574-598)
- Test: `test/services/gemini_service_test.dart`

**Interfaces:**
- Produces: `static List<DestinationLandmarkPhoto> fillEmptyLandmarkImages(List<DestinationLandmarkPhoto> gallery, String mainImageUrl)` trên `GeminiService`, `@visibleForTesting`. `gemini_service.dart` đã import `package:flutter/foundation.dart` và `package:voyz/models/destination_detail.dart`.

- [ ] **Step 1: Viết test fail**

Thêm import vào đầu `test/services/gemini_service_test.dart` nếu chưa có:

```dart
import 'package:voyz/models/destination_detail.dart';
```

Thêm group vào cuối `main()`:

```dart
  group('fillEmptyLandmarkImages', () {
    const main = 'https://upload.wikimedia.org/x/Main.jpg';

    test('landmark rong lay anh chinh, landmark co anh giu nguyen', () {
      final gallery = [
        const DestinationLandmarkPhoto(title: 'Cau Vang', imageUrl: ''),
        const DestinationLandmarkPhoto(
          title: 'Ba Na',
          imageUrl: 'https://upload.wikimedia.org/x/BaNa.jpg',
        ),
      ];

      final filled = GeminiService.fillEmptyLandmarkImages(gallery, main);

      expect(filled[0].title, 'Cau Vang');
      expect(filled[0].imageUrl, main);
      expect(filled[1].imageUrl, 'https://upload.wikimedia.org/x/BaNa.jpg');
    });

    test('anh chinh rong thi giu gallery nguyen ven', () {
      final gallery = [
        const DestinationLandmarkPhoto(title: 'Cau Vang', imageUrl: ''),
      ];

      final filled = GeminiService.fillEmptyLandmarkImages(gallery, '');

      expect(filled.single.imageUrl, isEmpty);
    });
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: FAIL, lỗi biên dịch `fillEmptyLandmarkImages` không tồn tại.

- [ ] **Step 3: Sửa `gemini_service.dart`**

Thêm hàm ngay trước `Future<DestinationDetail> _parseDetail(`:

```dart
  /// Landmark AI đặt tên thường không có trang Wikipedia riêng. Ô nào rỗng
  /// thì dùng ảnh chính của điểm đến để gallery không có ô trống. Ảnh chính
  /// cũng rỗng thì giữ nguyên, widget chung sẽ vẽ fallback.
  @visibleForTesting
  static List<DestinationLandmarkPhoto> fillEmptyLandmarkImages(
    List<DestinationLandmarkPhoto> gallery,
    String mainImageUrl,
  ) {
    if (mainImageUrl.isEmpty) return gallery;
    return [
      for (final photo in gallery)
        photo.imageUrl.isEmpty
            ? DestinationLandmarkPhoto(title: photo.title, imageUrl: mainImageUrl)
            : photo,
    ];
  }
```

Trong `_parseDetail`, thay dòng cuối:

```dart
    return DestinationDetail.fromJson(json, imageUrl, gallery: gallery);
```

bằng:

```dart
    return DestinationDetail.fromJson(
      json,
      imageUrl,
      gallery: fillEmptyLandmarkImages(gallery, imageUrl),
    );
```

- [ ] **Step 4: Chạy test**

Run: `flutter test test/services/gemini_service_test.dart`
Expected: PASS toàn bộ.

- [ ] **Step 5: Commit**

```bash
git add lib/services/gemini_service.dart test/services/gemini_service_test.dart
git commit -m "feat: detail gallery landmarks without a photo fall back to the destination's main image

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: Explore fallback sang Gemini khi repository ném exception

**Files:**
- Modify: `lib/screens/explore_screen.dart` (`_loadExplore`, khoảng dòng 49-84)

Không có unit test (màn hình, đúng bar của project). Kiểm bằng analyze và nghiệm thu tay ở Task 8.

- [ ] **Step 1: Sửa `_loadExplore`**

Thay:

```dart
      var results = await DestinationRepository.instance.getFeaturedDestinations(
        categoryKey: _selectedCategoryKey,
        limit: 10,
        forceRefresh: forceRefresh,
      );

      if (results.isEmpty) {
```

bằng:

```dart
      // Repository lỗi (mạng, Supabase) coi như rỗng để rơi xuống Gemini,
      // thay vì hiện màn lỗi khi vẫn còn nguồn thứ hai.
      List<DestinationSuggestion> results;
      try {
        results = await DestinationRepository.instance.getFeaturedDestinations(
          categoryKey: _selectedCategoryKey,
          limit: 10,
          forceRefresh: forceRefresh,
        );
      } catch (_) {
        results = const [];
      }

      if (results.isEmpty) {
```

`DestinationSuggestion` đã được import trong file (field `_destinations` dùng nó).

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/screens/explore_screen.dart`
Expected: không lỗi mới.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/explore_screen.dart
git commit -m "fix: explore falls back to Gemini trending when the destination repository throws, not only when it is empty

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: Kiểm tra cuối, nghiệm thu tay, mở PR

**Files:** không sửa code trừ khi bước kiểm phát hiện lỗi.

- [ ] **Step 1: Kiểm tự động**

Run:
```bash
flutter analyze
flutter test
dart run tool/verify_image_urls.dart
grep -rn $'\xe2\x80\x94\|\xe2\x80\x93' lib/widgets/shared/destination_image.dart lib/services/image_service.dart lib/screens/explore_screen.dart docs/superpowers/specs/2026-09-19-image-polish-design.md docs/superpowers/plans/2026-09-19-image-polish.md
```
Expected: analyze không lỗi mới so với master (19 info/warning có sẵn), `All tests passed!`, verifier pass, grep không có kết quả.

- [ ] **Step 2: Nghiệm thu tay trên web (`flutter run -d chrome`)**

Tick từng dòng trong spec mục 9:
- Tắt mạng (DevTools > Network > Offline) rồi mở lần lượt Explore, Suggestions, Saved, Cultural tips, Detail: mọi ô ảnh hiện cùng một gradient tối với icon núi và tên mờ.
- Bật mạng, mở Explore với category có tên điểm đến tiếng Anh: console không còn 404 `vi.wikipedia.org`.
- Mở Detail một điểm đến bất kỳ, cuộn tới gallery: không còn ô trống, landmark không có ảnh riêng hiện ảnh chính.
- Đổi `SUPABASE_URL` trong `.env` thành giá trị sai, chạy lại, mở Explore: vẫn ra danh sách từ Gemini. Đổi lại `.env` sau khi kiểm.

Ghi kết quả vào phần mô tả PR (dòng nào pass, dòng nào chưa).

- [ ] **Step 3: Push nhánh và mở PR**

```bash
git push -u origin image-polish
gh pr create --title "Image polish: shared DestinationImage, trimmed ImageService requests (roadmap 2.4)" --body "$(cat <<'EOF'
## Roadmap 2.4: polish ảnh trên nền đã ổn định

Spec: docs/superpowers/specs/2026-09-19-image-polish-design.md
Nghiên cứu nguồn ảnh: docs/research/2026-09-19-gemini-image-sources.md

- Widget chung `DestinationImage` thay 6 call site, một kiểu fallback cho rỗng / đang tải / lỗi.
- `ImageService`: en trước với tên không dấu, cache rỗng 10 phút, tra theo lô 3.
- Gallery landmark rỗng lấy ảnh chính của điểm đến.
- Explore fallback sang Gemini cả khi repository ném exception.
- Không đổi nguồn ảnh, không đụng avatar, không migration.

## Nghiệm thu tay
(dán kết quả Task 8 Step 2 vào đây)

## Kiểm tự động
flutter analyze: không lỗi mới. flutter test: pass. verify_image_urls: pass.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
