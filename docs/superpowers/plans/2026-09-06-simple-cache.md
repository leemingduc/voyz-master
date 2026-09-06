# Simple Cache Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thu `AiCacheService` về một tầng Hive có TTL, bỏ tầng Supabase, bỏ ảnh khỏi cache, xoá `CacheService` chết, sửa cache key cho đủ input.

**Architecture:** Một Hive box `ai_cache_v3`, mỗi entry là JSON `{payload, expiresAt}`. `GeminiService` chỉ còn gọi `get`/`put`/`buildKey`. Ảnh do `ImageService` tra sau khi có payload, không lưu trong cache.

**Tech Stack:** Flutter, Hive (`hive_flutter`), `crypto` (md5), Supabase (chỉ để lấy `userId`).

**Spec:** `docs/superpowers/specs/2026-09-06-simple-cache-and-trip-identity-design.md` phần 1.

## Global Constraints

- Nhánh: tạo từ `master` mới nhất, tên mô tả việc (ví dụ `simple-cache`). Không push lên `master`. Mở PR khi xong.
- Trước PR: `flutter analyze` không lỗi mới, `flutter test` pass.
- Không dùng em dash hay en dash trong bất kỳ text nào (comment, commit, doc).
- Không hardcode URL ảnh.
- Không chạm `lib/data/` (thuộc plan trip-identity).
- `lib/services/ai_cache_service.dart` sau khi xong dưới 80 dòng.

---

### Task 1: Viết lại `AiCacheService` một tầng có TTL

**Files:**
- Modify: `lib/services/ai_cache_service.dart` (viết lại toàn bộ)
- Test: `test/services/ai_cache_service_test.dart` (viết lại toàn bộ)

**Interfaces:**
- Produces:
  - `static const String AiCacheService.boxName = 'ai_cache_v3'`
  - `static const Duration AiCacheService.ttl = Duration(days: 7)`
  - `Future<void> init()`
  - `String buildKey(String prefix, Map<String, dynamic> parts)`
  - `String? get(String key)` (đồng bộ, null khi không có hoặc hết hạn)
  - `Future<void> put(String key, String payload)`
  - `Future<void> clear()`

- [ ] **Step 1: Viết test mới (thay toàn bộ file cũ)**

```dart
// test/services/ai_cache_service_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:voyz/services/ai_cache_service.dart';

void main() {
  late Directory tempDir;
  final cache = AiCacheService.instance;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ai_cache_test_');
    Hive.init(tempDir.path);
    await cache.init();
  });

  setUp(() async => cache.clear());

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('buildKey', () {
    test('cung input, dao thu tu map va list van cho cung key', () {
      final a = cache.buildKey('suggestions', {
        'destination': 'Da Nang',
        'interests': ['Beach', 'Food'],
      });
      final b = cache.buildKey('suggestions', {
        'interests': ['Food', 'Beach'],
        'destination': 'Da Nang',
      });
      expect(a, equals(b));
    });

    test('khac participants cho key khac', () {
      final a = cache.buildKey('suggestions', {'budget': 'moderate', 'participants': '2'});
      final b = cache.buildKey('suggestions', {'budget': 'moderate', 'participants': '4'});
      expect(a, isNot(equals(b)));
    });

    test('khac prefix cho key khac', () {
      final a = cache.buildKey('detail', {'name': 'Hue'});
      final b = cache.buildKey('itinerary', {'name': 'Hue'});
      expect(a, isNot(equals(b)));
    });
  });

  group('get / put', () {
    test('put roi get tra dung payload', () async {
      await cache.put('k1', '{"ok":true}');
      expect(cache.get('k1'), equals('{"ok":true}'));
    });

    test('key chua co tra null', () {
      expect(cache.get('khong_ton_tai'), isNull);
    });

    test('put ghi expiresAt cach now khoang 7 ngay', () async {
      await cache.put('k2', 'x');
      final raw = Hive.box<String>(AiCacheService.boxName).get('k2')!;
      final expiresAt = DateTime.parse(jsonDecode(raw)['expiresAt'] as String);
      final expected = DateTime.now().add(AiCacheService.ttl);
      expect(expiresAt.difference(expected).inMinutes.abs(), lessThan(1));
    });

    test('entry het han tra null va bi xoa khoi box', () async {
      final box = Hive.box<String>(AiCacheService.boxName);
      await box.put('k3', jsonEncode({
        'payload': 'cu',
        'expiresAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      }));
      expect(cache.get('k3'), isNull);
      expect(box.containsKey('k3'), isFalse);
    });

    test('entry thieu expiresAt coi la het han', () async {
      final box = Hive.box<String>(AiCacheService.boxName);
      await box.put('k4', jsonEncode({'payload': 'cu'}));
      expect(cache.get('k4'), isNull);
    });
  });
}
```

- [ ] **Step 2: Chạy test, xác nhận fail vì API chưa tồn tại**

Run: `flutter test test/services/ai_cache_service_test.dart`
Expected: FAIL khi compile, lỗi kiểu `The getter 'boxName' isn't defined` và `put`/`get` sai chữ ký.

- [ ] **Step 3: Viết lại `lib/services/ai_cache_service.dart`**

```dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/services/supabase_service.dart';

/// Cache một tầng cho phản hồi AI. Chỉ là cache: mất là được phép.
///
/// Mỗi entry trong box là JSON string `{"payload": "...", "expiresAt": "ISO-8601"}`.
/// Muốn xem cache đang có gì: mở box Hive [boxName].
class AiCacheService {
  AiCacheService._();
  static final AiCacheService instance = AiCacheService._();

  /// Tăng số version mỗi khi sửa prompt: box mới, cache cũ tự bị bỏ qua.
  static const boxName = 'ai_cache_v3';

  /// Một TTL cho mọi feature. Explore muốn mới thì đã có nút refresh.
  static const ttl = Duration(days: 7);

  static const _oldBoxNames = ['gemini_cache', 'gemini_multi_tier_cache_v2'];

  Box<String>? _box;

  Future<void> init() async {
    if (_box != null) return;
    for (final name in _oldBoxNames) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
    }
    try {
      _box = await Hive.openBox<String>(boxName);
    } catch (e) {
      debugPrint('AiCacheService init error: $e');
    }
  }

  /// Key md5 từ prefix + mọi input ảnh hưởng đến kết quả + userId hiện tại.
  String buildKey(String prefix, Map<String, dynamic> parts) {
    final sorted = parts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final buffer = StringBuffer(prefix);
    for (final entry in sorted) {
      buffer.write('|${entry.key}=');
      if (entry.value is List) {
        final list = List<String>.from(entry.value as List)..sort();
        buffer.write(list.join(','));
      } else {
        buffer.write(entry.value.toString().trim().toLowerCase());
      }
    }
    buffer.write('|user=$_userId');
    return md5.convert(utf8.encode(buffer.toString())).toString();
  }

  /// Trả payload nếu còn hạn; hết hạn hoặc hỏng thì xoá và trả null.
  String? get(String key) {
    final raw = _box?.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.tryParse(map['expiresAt']?.toString() ?? '');
      if (expiresAt == null || expiresAt.isBefore(DateTime.now())) {
        _box?.delete(key);
        return null;
      }
      return map['payload']?.toString();
    } catch (_) {
      _box?.delete(key);
      return null;
    }
  }

  Future<void> put(String key, String payload) async {
    final entry = jsonEncode({
      'payload': payload,
      'expiresAt': DateTime.now().add(ttl).toIso8601String(),
    });
    await _box?.put(key, entry);
  }

  Future<void> clear() async => _box?.clear();

  String get _userId {
    try {
      return SupabaseService.instance.auth.currentUser?.id ?? 'anonymous';
    } catch (_) {
      // Test hoặc khởi động offline: chưa có Supabase.
      return 'anonymous';
    }
  }
}
```

- [ ] **Step 4: Chạy test, xác nhận pass**

Run: `flutter test test/services/ai_cache_service_test.dart`
Expected: 8 tests PASS. (Lúc này `gemini_service.dart` và `main.dart` chưa compile được với API mới, đó là việc của Task 2 và 3; test này chỉ import `ai_cache_service.dart` và `supabase_service.dart` nên vẫn chạy.)

- [ ] **Step 5: Commit**

```bash
git add lib/services/ai_cache_service.dart test/services/ai_cache_service_test.dart
git commit -m "refactor: single-tier Hive AI cache with 7-day TTL"
```

---

### Task 2: Chuyển `GeminiService` sang API cache mới, bỏ ảnh khỏi cache, sửa key

**Files:**
- Modify: `lib/services/gemini_service.dart`
- Modify: `lib/services/image_service.dart` (xoá `getImageUrlsFast`, dòng 57-60)
- Test: `test/services/gemini_service_test.dart` (đã có, phải vẫn pass)

**Interfaces:**
- Consumes: `AiCacheService.get(key)`, `put(key, payload)`, `buildKey(prefix, parts)` từ Task 1.
- Produces: `parseSuggestionsSync(String text)` không còn tham số `imageUrls`. Public API còn lại của `GeminiService` không đổi chữ ký.

- [ ] **Step 1: Xoá `_precacheAndStoreImages`**

Xoá toàn bộ method từ dòng doc comment `/// Asynchronously pre-caches image URLs in the background ...` đến dấu `}` đóng method (hiện ở khoảng dòng 89 đến 116). Thêm helper mới ngay vị trí đó:

```dart
  /// Tra URL ảnh cho danh sách gợi ý qua ImageService.
  /// Lỗi ảnh không làm hỏng kết quả AI: trả lại danh sách không ảnh.
  Future<List<DestinationSuggestion>> _withImages(
    List<DestinationSuggestion> suggestions,
  ) async {
    try {
      return await enrichSuggestionsWithImages(suggestions);
    } catch (e) {
      debugPrint('Image fetch error (non-fatal): $e');
      return suggestions;
    }
  }
```

- [ ] **Step 2: Sửa `getExploreTrending`**

Thay phần từ `final cacheKey = _aiCache.buildKey('explore_trending', {` đến hết `if (!forceRefresh) { ... }` bằng:

```dart
    final cacheKey = _aiCache.buildKey('explore_trending', {
      'limit': limit,
      'lang': languageCode,
      'category': category ?? '',
    });

    if (!forceRefresh) {
      final cached = _aiCache.get(cacheKey);
      if (cached != null) {
        return _withImages(parseSuggestionsSync(cached));
      }
    }
```

Giữ nguyên biến `randomSeed` và `theme` (vẫn dùng cho prompt). Thay toàn bộ phần sau `if (text == null || text.isEmpty) return [];` (từ `await _aiCache.putResponse(` đến hết method) bằng:

```dart
    await _aiCache.put(cacheKey, text);
    return _withImages(parseSuggestionsSync(text));
```

- [ ] **Step 3: Sửa `getSuggestions`**

Thêm hai dòng vào map của `buildKey('suggestions', {...})`:

```dart
      'participants': trip.participants.trim(),
      'ageRange': trip.ageRange.trim(),
```

Thay block đọc cache bằng:

```dart
    if (!forceRefresh) {
      final cached = _aiCache.get(cacheKey);
      if (cached != null) return parseSuggestionsSync(cached);
    }
```

Thay toàn bộ phần sau `if (text == null || text.isEmpty) return [];` (từ `await _aiCache.putResponse(` đến hết method, gồm cả lời gọi `_precacheAndStoreImages`) bằng:

```dart
    await _aiCache.put(cacheKey, text);
    return parseSuggestionsSync(text);
```

Sửa doc comment của method: xoá câu "If pre-cached images are available from the multi-tier cache, they are rendered right away." Suggestions screen đã gọi `enrichSuggestionsWithImages` ở pha 2, không đổi.

- [ ] **Step 4: Sửa `parseSuggestionsSync`**

Chữ ký mới và body: bỏ tham số `imageUrls`, bỏ dòng `final cachedImage = imageUrls?[name] ?? '';`, đổi `DestinationSuggestion.fromJson(map, cachedImage)` thành `DestinationSuggestion.fromJson(map, '')`.

```dart
  /// Synchronously parse raw JSON text into DestinationSuggestions.
  /// Ảnh không nằm trong JSON của AI; tra sau bằng [enrichSuggestionsWithImages].
  List<DestinationSuggestion> parseSuggestionsSync(String text) {
```

- [ ] **Step 5: Sửa `getDestinationDetail`**

Map key mới:

```dart
    final cacheKey = _aiCache.buildKey('detail', {
      'name': destinationName,
      'lang': languageCode,
      'aiPrompt': trip.aiPrompt.trim(),
      'budget': trip.budget,
      'currency': trip.currency,
      'depart': trip.departDate?.toIso8601String() ?? '',
      'return': trip.returnDate?.toIso8601String() ?? '',
    });
```

Đọc cache:

```dart
    if (!forceRefresh) {
      final cached = _aiCache.get(cacheKey);
      if (cached != null) return _parseDetail(cached, destinationName);
    }
```

Ghi cache: thay `await _aiCache.putResponse(cacheKey, text, featureType: 'detail', destination: destinationName, languageCode: languageCode);` bằng `await _aiCache.put(cacheKey, text);`.

- [ ] **Step 6: Sửa `getItineraryPlan`**

Map key thêm:

```dart
      'depart': trip.departDate?.toIso8601String() ?? '',
      'return': trip.returnDate?.toIso8601String() ?? '',
```

Đọc cache:

```dart
    if (!forceRefresh) {
      final cached = _aiCache.get(cacheKey);
      if (cached != null) {
        final Map<String, dynamic> json =
            safeJsonDecode(cached) as Map<String, dynamic>;
        return ItineraryPlan.fromJson(json);
      }
    }
```

Ghi cache: thay lời gọi `putResponse(...)` bằng `await _aiCache.put(cacheKey, text);`.

- [ ] **Step 7: Sửa `compareDestinations`, `getBestTimeToTravel`, `getCulturalTips`**

Ở cả ba method, áp cùng một mẫu:
- `final cached = await _aiCache.getResponse(cacheKey);` thành `final cached = _aiCache.get(cacheKey);`
- mọi `cached.payload` thành `cached`
- `await _aiCache.putResponse(cacheKey, text, featureType: ..., ...);` thành `await _aiCache.put(cacheKey, text);`

Ví dụ `getCulturalTips` sau khi sửa:

```dart
    if (!forceRefresh) {
      final cached = _aiCache.get(cacheKey);
      if (cached != null) return _parseCulturalTips(cached, destinationName);
    }
    // ... prompt và generateContent giữ nguyên ...
    await _aiCache.put(cacheKey, text);
    return _parseCulturalTips(text, destinationName);
```

- [ ] **Step 8: Sửa doc comment class và xoá alias ảnh**

Trong `gemini_service.dart`, đổi câu "All methods check Multi-Tier cache first; only calls the API on cache miss." thành "Every feature checks the Hive cache first and only calls the API on a miss."

Trong `lib/services/image_service.dart`, xoá method `getImageUrlsFast` cùng doc comment của nó (dòng 57-60).

- [ ] **Step 9: Kiểm tra không còn API cũ**

Run: `grep -n "getResponse\|putResponse\|_precacheAndStoreImages\|getImageUrlsFast\|imageUrls:" lib/services/gemini_service.dart lib/services/image_service.dart`
Expected: không có kết quả.

- [ ] **Step 10: Chạy analyze và test**

Run: `flutter analyze lib/services/ && flutter test test/services/`
Expected: analyze chỉ còn lỗi ở `lib/main.dart` (import `cache_service.dart`, xử lý ở Task 3), `test/services/` PASS toàn bộ.

- [ ] **Step 11: Commit**

```bash
git add lib/services/gemini_service.dart lib/services/image_service.dart
git commit -m "refactor: GeminiService uses single-tier cache, images resolved via ImageService"
```

---

### Task 3: Xoá `CacheService`, xoá test trùng, migration drop bảng

**Files:**
- Delete: `lib/services/cache_service.dart`
- Delete: `test/gemini_service_test.dart` (bản trùng ở sai thư mục; bản đúng là `test/services/gemini_service_test.dart`)
- Modify: `lib/main.dart` (dòng 11 import và dòng 36 init)
- Create: `supabase/migrations/20260907000200_drop_ai_generated_cache.sql`

- [ ] **Step 1: Xoá file và dòng init**

```bash
git rm lib/services/cache_service.dart test/gemini_service_test.dart
```

Trong `lib/main.dart`: xoá dòng `import 'package:voyz/services/cache_service.dart';` và dòng `await CacheService.instance.init();`.

- [ ] **Step 2: Tạo migration**

```sql
-- supabase/migrations/20260907000200_drop_ai_generated_cache.sql
-- Cache AI giờ chỉ nằm ở Hive trên máy người dùng (spec 2026-09-06 phần 1).
-- Bảng dùng chung này từng cho anon ghi (cache poisoning) và không có TTL.
drop function if exists public.increment_ai_cache_hit(text);
drop table if exists public.ai_generated_cache;
```

- [ ] **Step 3: Kiểm tra toàn repo**

Run: `grep -rn "ai_generated_cache\|CacheService\b\|CachedAiResponse\|_precacheAndStoreImages" lib/`
Expected: không có kết quả. (`AiCacheService` vẫn có, `CacheService\b` chỉ khớp tên class cũ.)

Run: `wc -l lib/services/ai_cache_service.dart`
Expected: dưới 80.

- [ ] **Step 4: Analyze và test toàn bộ**

Run: `flutter analyze && flutter test`
Expected: analyze không lỗi mới so với `master`; toàn bộ test PASS.

- [ ] **Step 5: Commit**

```bash
git add -A lib/main.dart supabase/migrations/20260907000200_drop_ai_generated_cache.sql
git commit -m "chore: remove dead CacheService, drop shared ai_generated_cache table"
```

---

### Task 4: Nghiệm thu tay và mở PR

**Files:** không sửa code.

- [ ] **Step 1: Chạy app, kiểm tra 4 tiêu chí của spec mục 1.6**

1. Mở Explore, bấm refresh 3 lần. Mở Hive box `ai_cache_v3` (debug: `Hive.box<String>('ai_cache_v3').length` in ra console) và xác nhận số entry không tăng thêm 3.
2. Planner với budget economy, mở detail một điểm đến; quay lại đổi premium, mở lại cùng điểm đến: phần ngân sách khác nhau.
3. Đăng xuất, đăng nhập user khác, mở Suggestions cùng input: có gọi Gemini lại (thấy loading, không hiện tức thì).
4. Suggestions và Explore vẫn có ảnh sau khi tải xong.

- [ ] **Step 2: Nhờ giáo viên chạy migration**

Migration `20260907000200` cần `supabase db push` từ tài khoản giáo viên. Ghi vào mô tả PR.

- [ ] **Step 3: Mở PR**

```bash
git push -u origin simple-cache
gh pr create --title "Simple single-tier AI cache with TTL" --body "$(cat <<'BODY'
## Summary
- AiCacheService: one Hive box ai_cache_v3, entries {payload, expiresAt}, 7-day TTL, userId in key
- Removed Supabase cache tier, image URLs in cache, dead CacheService, explore nonce
- Cache keys now include every prompt input (participants, ageRange, budget, currency, dates)
- Migration drops ai_generated_cache (teacher: run supabase db push)

Spec: docs/superpowers/specs/2026-09-06-simple-cache-and-trip-identity-design.md part 1

## Test plan
- [ ] flutter analyze, flutter test pass
- [ ] Explore refresh x3 does not add 3 entries
- [ ] Budget tier change gives different detail
- [ ] Second user on same device does not reuse first user's cache
BODY
)"
```

---

## Self-review

- Spec 1.2 (API 5 hàm, entry JSON, userId trong key, TTL 7 ngày, xoá box cũ): Task 1.
- Spec 1.3 (get/put, bỏ precache, bỏ nonce, key đủ input, xoá `getImageUrlsFast`): Task 2.
- Spec 1.4 (xoá `cache_service.dart`, dòng init, migration): Task 3.
- Spec 1.5 (test mới, xoá test trùng): Task 1 và Task 3.
- Spec 1.6 (nghiệm thu): Task 3 step 3 và Task 4.
- Tên hàm nhất quán: `get`, `put`, `buildKey`, `clear`, `init`, `_withImages`, `parseSuggestionsSync(String)`.
