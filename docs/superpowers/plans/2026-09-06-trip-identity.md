# Trip Identity and Cloud-First Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mỗi chuyến đi có `id` UUID, itinerary gắn `tripId`, Supabase là dữ liệu và Hive chỉ là ảnh chụp; mọi thao tác lưu/sửa/xoá chờ cloud xong mới đổi state.

**Architecture:** `SavedItem.id` sinh ở client bằng `uuid`. `SavedTripsProvider` viết lại: `load()` đọc Hive rồi thay bằng cloud; mọi hàm ghi `await` Supabase (upsert `onConflict: 'id'`) rồi mới `setState` và ghi Hive theo từng key. Không realtime, không merge, không chạy nền. Screens `await` các hàm ghi trong try/catch và hiện snackbar khi lỗi.

**Tech Stack:** Flutter, Hive, `supabase_flutter`, package `uuid`.

**Spec:** `docs/superpowers/specs/2026-09-06-simple-cache-and-trip-identity-design.md` phần 2.

## Global Constraints

- Nhánh: tạo từ `master` mới nhất, tên mô tả việc (ví dụ `trip-identity`). Không push lên `master`. Mở PR khi xong.
- Trước PR: `flutter analyze` không lỗi mới, `flutter test` pass.
- Không dùng em dash hay en dash trong bất kỳ text nào.
- Không chạm `lib/services/ai_cache_service.dart` và `lib/services/gemini_service.dart` (thuộc plan simple-cache).
- Số ngày itinerary tính cả ngày đi và ngày về, kẹp 1..7, mặc định 3.
- `lib/data/saved_trips_provider.dart` không có ngưỡng số dòng cứng; yêu cầu là ngắn hơn bản cũ (497 dòng) nhờ bỏ merge sync, realtime, persistence queue, migration box cũ. Không xoá dòng trống hay nén code để đạt con số.

---

### Task 1: Model có danh tính: `SavedItem.id`, `ItineraryPlan.tripId`, `TripData.dayCount()`

**Files:**
- Modify: `pubspec.yaml` (thêm dependency `uuid`)
- Modify: `lib/data/trip_data.dart` (class `TripData` và `SavedItem`)
- Modify: `lib/models/itinerary_plan.dart` (class `ItineraryPlan`)
- Test: `test/data/saved_trips_sync_test.dart` (thêm test)

**Interfaces:**
- Produces:
  - `SavedItem.id` (`String`, UUID v4, bất biến), constructor nhận `String? id`; không còn `cloudId`.
  - `ItineraryPlan.tripId` (`String`, mặc định `''`), `ItineraryPlan copyWith({String? tripId})`.
  - `int TripData.dayCount({int fallback = 3})`.

- [ ] **Step 1: Thêm dependency**

Trong `pubspec.yaml`, dưới dòng `supabase_flutter: ^2.9.1` thêm:

```yaml
  uuid: ^4.4.0
```

Run: `flutter pub get`

- [ ] **Step 2: Viết test mới (thêm vào cuối group hiện có trong `test/data/saved_trips_sync_test.dart`)**

```dart
    test('SavedItem tu sinh id UUID va giu nguyen qua toMap/fromMap', () {
      final item = SavedItem(
        name: 'Hue',
        imageUrl: '',
        price: '',
        matchPercent: 0,
        rating: 0,
        reviewCount: 0,
        aiInsight: '',
      );
      expect(item.id, hasLength(36));
      final restored = SavedItem.fromMap(item.toMap());
      expect(restored.id, equals(item.id));
      expect(SavedItem.fromMap(restored.toMap()).id, equals(item.id));
    });

    test('SavedItem.fromMap thieu id thi sinh id moi', () {
      final restored = SavedItem.fromMap({'name': 'Hue'});
      expect(restored.id, hasLength(36));
    });

    test('hai SavedItem cung name khac id la hai item', () {
      SavedItem make() => SavedItem(
            name: 'Da Nang',
            imageUrl: '',
            price: '',
            matchPercent: 0,
            rating: 0,
            reviewCount: 0,
            aiInsight: '',
            tripData: TripData(destination: 'Da Nang'),
          );
      final a = make();
      final b = make();
      expect(a.id, isNot(equals(b.id)));
      expect(a.copyWith(workspaceNotes: 'x').id, equals(a.id));
    });

    test('ItineraryPlan giu tripId qua toMap/fromJson va copyWith', () {
      const plan = ItineraryPlan(
        destinationName: 'Hue',
        dateRange: '3 days',
        days: [],
        proTip: '',
        tripId: 'trip-123',
      );
      expect(ItineraryPlan.fromJson(plan.toMap()).tripId, equals('trip-123'));
      expect(plan.copyWith(tripId: 'trip-456').tripId, equals('trip-456'));
      expect(plan.copyWith(tripId: 'trip-456').destinationName, equals('Hue'));
    });

    test('TripData.dayCount tinh ca ngay di va ngay ve, kep 1..7', () {
      expect(
        TripData(departDate: DateTime(2026, 6, 1), returnDate: DateTime(2026, 6, 3)).dayCount(),
        equals(3),
      );
      expect(TripData().dayCount(), equals(3));
      expect(TripData().dayCount(fallback: 5), equals(5));
      expect(
        TripData(departDate: DateTime(2026, 6, 1), returnDate: DateTime(2026, 6, 20)).dayCount(),
        equals(7),
      );
      expect(
        TripData(departDate: DateTime(2026, 6, 1), returnDate: DateTime(2026, 6, 1)).dayCount(),
        equals(1),
      );
    });
```

- [ ] **Step 3: Chạy test, xác nhận fail**

Run: `flutter test test/data/saved_trips_sync_test.dart`
Expected: FAIL khi compile (`id`, `tripId`, `copyWith`, `dayCount` chưa có).

- [ ] **Step 4: Sửa `TripData`**

Trong `lib/data/trip_data.dart`, thêm vào class `TripData` sau method `toMap()`:

```dart
  /// Số ngày của chuyến đi, tính cả ngày đi và ngày về. Không có ngày thì dùng fallback.
  int dayCount({int fallback = 3}) {
    if (departDate == null || returnDate == null) return fallback;
    return (returnDate!.difference(departDate!).inDays + 1).clamp(1, 7).toInt();
  }
```

- [ ] **Step 5: Sửa `SavedItem`**

Thêm import ở đầu file `lib/data/trip_data.dart`:

```dart
import 'package:uuid/uuid.dart';
```

Trong class `SavedItem`:
- Thay dòng `final String? cloudId;` bằng `final String id;`
- Trong constructor: thay `this.cloudId,` bằng `String? id,` và thêm vào phần initializer list `id = id ?? const Uuid().v4(),` (đặt trước `savedAt = ...`).
- Trong `fromMap`: thay `cloudId: map['cloudId']?.toString(),` bằng `id: map['id']?.toString(),` (null thì constructor tự sinh).
- Trong `copyWith`: xoá tham số `String? cloudId,`; thay `cloudId: cloudId ?? this.cloudId,` bằng `id: id,` (id không bao giờ đổi).
- Trong `toMap`: thay `'cloudId': cloudId,` bằng `'id': id,`.

Constructor sau khi sửa:

```dart
  SavedItem({
    String? id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.matchPercent,
    required this.rating,
    required this.reviewCount,
    required this.aiInsight,
    this.tripData,
    DateTime? savedAt,
    List<WorkspaceChecklistItem>? checklist,
    this.workspaceNotes = '',
    List<String>? bookingRefs,
    List<String>? sharedWith,
  }) : id = id ?? const Uuid().v4(),
       savedAt = savedAt ?? DateTime.now(),
       checklist = checklist ?? _defaultChecklist(),
       bookingRefs = bookingRefs ?? const [],
       sharedWith = sharedWith ?? const [];
```

- [ ] **Step 6: Sửa `ItineraryPlan`**

Trong `lib/models/itinerary_plan.dart`, class `ItineraryPlan`:

```dart
class ItineraryPlan {
  final String destinationName;
  final String dateRange;
  final List<ItineraryDay> days;
  final String proTip;

  /// Id của trip sở hữu itinerary này. Rỗng khi plan chưa gắn trip.
  final String tripId;

  const ItineraryPlan({
    required this.destinationName,
    required this.dateRange,
    required this.days,
    required this.proTip,
    this.tripId = '',
  });

  factory ItineraryPlan.fromJson(Map<String, dynamic> json) {
    return ItineraryPlan(
      destinationName: json['destinationName'] as String? ?? '',
      dateRange: json['dateRange'] as String? ?? '',
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      proTip: json['proTip'] as String? ?? '',
      tripId: json['tripId']?.toString() ?? '',
    );
  }

  ItineraryPlan copyWith({String? tripId}) => ItineraryPlan(
        destinationName: destinationName,
        dateRange: dateRange,
        days: days,
        proTip: proTip,
        tripId: tripId ?? this.tripId,
      );

  Map<String, dynamic> toMap() => {
    'destinationName': destinationName,
    'dateRange': dateRange,
    'days': days.map((day) => day.toMap()).toList(),
    'proTip': proTip,
    'tripId': tripId,
  };
}
```

- [ ] **Step 7: Chạy test, xác nhận pass**

Run: `flutter test test/data/saved_trips_sync_test.dart`
Expected: PASS toàn bộ (3 test cũ + 5 test mới). `flutter analyze lib/data/trip_data.dart lib/models/itinerary_plan.dart` sạch. Lỗi ở `saved_trips_provider.dart` (còn dùng `cloudId`) là bình thường, sửa ở Task 3.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/data/trip_data.dart lib/models/itinerary_plan.dart test/data/saved_trips_sync_test.dart
git commit -m "feat: SavedItem gets client-generated UUID id, ItineraryPlan gets tripId, TripData.dayCount"
```

---

### Task 2: Migration Supabase

**Files:**
- Create: `supabase/migrations/20260907000100_trip_identity.sql`

**Interfaces:**
- Produces: `saved_trips` không còn unique `(user_id, name)`; `saved_itineraries.trip_id` (uuid, not null, unique, FK cascade); `search_history` có policy DELETE.

- [ ] **Step 1: Tạo file migration**

```sql
-- supabase/migrations/20260907000100_trip_identity.sql
-- Spec: docs/superpowers/specs/2026-09-06-simple-cache-and-trip-identity-design.md phan 2.4

-- Du lieu test cu khong co trip_id, reset sach (da thong nhat voi giao vien).
delete from public.saved_itineraries;
delete from public.saved_trips;

-- saved_trips: id do client sinh, cho phep hai chuyen cung ten.
alter table public.saved_trips drop constraint if exists saved_trips_user_name_unique;

-- saved_itineraries: gan theo trip, mot trip mot itinerary.
alter table public.saved_itineraries
  add column if not exists trip_id uuid references public.saved_trips(id) on delete cascade;
alter table public.saved_itineraries drop constraint if exists saved_itineraries_user_dest_unique;
alter table public.saved_itineraries alter column trip_id set not null;
create unique index if not exists saved_itineraries_trip_idx
  on public.saved_itineraries (trip_id);

-- search_history: cho phep xoa lich su cua minh.
drop policy if exists "Users can delete their own search history" on public.search_history;
create policy "Users can delete their own search history"
  on public.search_history for delete to authenticated
  using (auth.uid() = user_id);
```

- [ ] **Step 2: Kiểm tra cú pháp bằng mắt và tên constraint**

Run: `grep -n "saved_trips_user_name_unique\|saved_itineraries_user_dest_unique" supabase/migrations/20260823000200_create_saved_trips_and_itineraries.sql`
Expected: 2 dòng, đúng tên constraint mà migration mới drop.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260907000100_trip_identity.sql
git commit -m "feat(db): saved_trips keyed by client id, saved_itineraries per trip, search_history delete policy"
```

Ghi chú cho PR: giáo viên chạy `supabase db push`. Nhánh này không chạy được đúng trên cloud cho đến khi migration được apply.

---

### Task 3: Viết lại `SavedTripsProvider` cloud-first

**Files:**
- Modify: `lib/data/saved_trips_provider.dart` (viết lại toàn bộ)

**Interfaces:**
- Consumes: `SavedItem.id`, `ItineraryPlan.tripId`, `ItineraryPlan.copyWith` từ Task 1.
- Produces (API mà Task 4 dùng):

```dart
TripData get currentTrip;
List<SavedItem> get savedItems;
List<SavedItem> get tripWorkspaces;
List<SavedItem> get wishlistItems;
ItineraryPlan? itineraryFor(String tripId);
SavedItem? itemById(String id);

Future<void> load();
void updateTrip(TripData trip);
Future<SavedItem> saveFullTrip({required String name, required String imageUrl, required String price,
    required int matchPercent, required double rating, required int reviewCount, required String aiInsight});
Future<bool> saveToWishlist({...cung tham so...});
Future<void> updateWorkspace(SavedItem updated);
Future<void> toggleChecklistItem(SavedItem item, int index);
Future<void> updateWorkspaceNotes(SavedItem item, String notes);
Future<void> addBookingRef(SavedItem item, String value);
Future<void> addSharedPerson(SavedItem item, String value);
Future<void> removeSavedItem(SavedItem item);
Future<void> saveItinerary(ItineraryPlan plan);   // plan.tripId phai khac rong
```

- [ ] **Step 1: Viết lại toàn bộ file**

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/itinerary_plan.dart';
import 'package:voyz/services/supabase_service.dart';

/// Giữ trip đang nhập và danh sách trip đã lưu.
///
/// Quy tắc: Supabase là dữ liệu, Hive là ảnh chụp để mở app hiện ngay.
/// Mọi hàm ghi đều `await` Supabase; thành công mới đổi state và Hive.
/// Thất bại thì ném lỗi để màn hình hiện snackbar. Không có gì chạy nền.
class SavedTripsProvider extends StatefulWidget {
  const SavedTripsProvider({super.key, required this.child});
  final Widget child;

  @override
  State<SavedTripsProvider> createState() => SavedTripsProviderState();

  static SavedTripsProviderState of(BuildContext context) {
    final state = context.findAncestorStateOfType<SavedTripsProviderState>();
    assert(state != null, 'No SavedTripsProvider found in widget tree');
    return state!;
  }
}

class SavedTripsProviderState extends State<SavedTripsProvider> {
  static const _boxPrefix = 'saved_trips_cache_';
  static const _currentTripKey = '__current_trip';
  static const _itineraryPrefix = '__itinerary_';
  static const _oldBoxNames = ['saved_trip_workspaces', 'storage_migrations'];

  TripData _currentTrip = TripData();
  final List<SavedItem> _items = [];
  final Map<String, ItineraryPlan> _itineraries = {}; // key = tripId
  Box<Map>? _box;
  StreamSubscription? _authSubscription;
  bool _oldBoxesDeleted = false;

  TripData get currentTrip => _currentTrip;
  List<SavedItem> get savedItems => List.unmodifiable(_items);
  List<SavedItem> get tripWorkspaces =>
      _items.where((item) => item.tripData != null).toList();
  List<SavedItem> get wishlistItems =>
      _items.where((item) => item.tripData == null).toList();
  ItineraryPlan? itineraryFor(String tripId) => _itineraries[tripId];
  SavedItem? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    unawaited(load());
    try {
      _authSubscription = SupabaseService.instance.auth.onAuthStateChange
          .listen((_) => load());
    } catch (_) {
      // Widget test hoặc khởi động offline: chưa có Supabase.
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ── Load: Hive trước cho nhanh, rồi cloud thay toàn bộ ─────────────────

  Future<void> load() async {
    final userId = _userId;
    await _deleteOldBoxesOnce(userId);
    final box = await Hive.openBox<Map>('$_boxPrefix$userId');
    _box = box;
    _readFromHive(box);
    if (userId == 'anonymous') return;

    try {
      final client = SupabaseService.instance.client;
      final tripRows = await client
          .from('saved_trips')
          .select()
          .eq('user_id', userId)
          .order('saved_at', ascending: false);
      final planRows = await client
          .from('saved_itineraries')
          .select()
          .eq('user_id', userId);
      if (!mounted || userId != _userId) return;

      final items = [
        for (final row in tripRows) _itemFromRow(Map<String, dynamic>.from(row)),
      ];
      final plans = <String, ItineraryPlan>{};
      for (final row in planRows) {
        final map = Map<String, dynamic>.from(row);
        final planData = Map<String, dynamic>.from(map['plan_data'] as Map? ?? {});
        planData['tripId'] = map['trip_id']?.toString() ?? '';
        final plan = ItineraryPlan.fromJson(planData);
        if (plan.tripId.isNotEmpty) plans[plan.tripId] = plan;
      }

      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _itineraries
          ..clear()
          ..addAll(plans);
      });
      await _writeSnapshot(box, items, plans);
    } catch (e) {
      debugPrint('SavedTripsProvider: cloud load failed, keeping Hive snapshot: $e');
    }
  }

  void _readFromHive(Box<Map> box) {
    final items = <SavedItem>[];
    final plans = <String, ItineraryPlan>{};
    var current = TripData();
    for (final entry in box.toMap().entries) {
      final key = entry.key.toString();
      if (key == _currentTripKey) {
        current = TripData.fromMap(entry.value);
      } else if (key.startsWith(_itineraryPrefix)) {
        final plan = ItineraryPlan.fromJson(Map<String, dynamic>.from(entry.value));
        if (plan.tripId.isNotEmpty) plans[plan.tripId] = plan;
      } else {
        items.add(SavedItem.fromMap(entry.value));
      }
    }
    items.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    if (!mounted) return;
    setState(() {
      _currentTrip = current;
      _items
        ..clear()
        ..addAll(items);
      _itineraries
        ..clear()
        ..addAll(plans);
    });
  }

  /// Ghi đè ảnh chụp: xoá key không còn trên cloud, put từng item và plan.
  Future<void> _writeSnapshot(
    Box<Map> box,
    List<SavedItem> items,
    Map<String, ItineraryPlan> plans,
  ) async {
    final keep = <String>{
      _currentTripKey,
      ...items.map((item) => item.id),
      ...plans.keys.map((tripId) => '$_itineraryPrefix$tripId'),
    };
    for (final key in box.keys.map((k) => k.toString()).toList()) {
      if (!keep.contains(key)) await box.delete(key);
    }
    for (final item in items) {
      await box.put(item.id, item.toMap());
    }
    for (final plan in plans.values) {
      await box.put('$_itineraryPrefix${plan.tripId}', plan.toMap());
    }
  }

  Future<void> _deleteOldBoxesOnce(String userId) async {
    if (_oldBoxesDeleted) return;
    _oldBoxesDeleted = true;
    for (final name in [..._oldBoxNames, 'saved_trip_workspaces_$userId']) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
    }
  }

  // ── Trip đang nhập: chỉ Hive ────────────────────────────────────────────

  void updateTrip(TripData trip) {
    setState(() => _currentTrip = trip);
    unawaited(_box?.put(_currentTripKey, trip.toMap()));
  }

  // ── Ghi: cloud trước, thành công mới đổi state và Hive ─────────────────

  Future<SavedItem> saveFullTrip({
    required String name,
    required String imageUrl,
    required String price,
    required int matchPercent,
    required double rating,
    required int reviewCount,
    required String aiInsight,
  }) async {
    final item = SavedItem(
      name: name,
      imageUrl: imageUrl,
      price: price,
      matchPercent: matchPercent,
      rating: rating,
      reviewCount: reviewCount,
      aiInsight: aiInsight,
      tripData: _currentTrip.copyWith(),
    );
    await _upsertItem(item);
    return item;
  }

  /// false nếu wishlist đã có điểm đến cùng tên (không ghi gì).
  Future<bool> saveToWishlist({
    required String name,
    required String imageUrl,
    required String price,
    required int matchPercent,
    required double rating,
    required int reviewCount,
    required String aiInsight,
  }) async {
    if (wishlistItems.any((e) => e.name == name)) return false;
    final item = SavedItem(
      name: name,
      imageUrl: imageUrl,
      price: price,
      matchPercent: matchPercent,
      rating: rating,
      reviewCount: reviewCount,
      aiInsight: aiInsight,
      tripData: null,
    );
    await _upsertItem(item);
    return true;
  }

  Future<void> updateWorkspace(SavedItem updated) => _upsertItem(updated);

  Future<void> toggleChecklistItem(SavedItem item, int index) {
    if (index < 0 || index >= item.checklist.length) return Future.value();
    final checklist = List<WorkspaceChecklistItem>.of(item.checklist);
    final current = checklist[index];
    checklist[index] =
        WorkspaceChecklistItem(text: current.text, isDone: !current.isDone);
    return updateWorkspace(item.copyWith(checklist: checklist));
  }

  Future<void> updateWorkspaceNotes(SavedItem item, String notes) =>
      updateWorkspace(item.copyWith(workspaceNotes: notes));

  Future<void> addBookingRef(SavedItem item, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return Future.value();
    return updateWorkspace(
      item.copyWith(bookingRefs: [...item.bookingRefs, trimmed]),
    );
  }

  Future<void> addSharedPerson(SavedItem item, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    await updateWorkspace(item.copyWith(sharedWith: [...item.sharedWith, trimmed]));
    await _syncCollaboratorToCloud(item, trimmed);
  }

  Future<void> removeSavedItem(SavedItem item) async {
    final userId = _userId;
    if (userId != 'anonymous') {
      await SupabaseService.instance.client
          .from('saved_trips')
          .delete()
          .eq('id', item.id);
    }
    if (!mounted) return;
    setState(() {
      _items.removeWhere((e) => e.id == item.id);
      _itineraries.remove(item.id);
    });
    await _box?.delete(item.id);
    await _box?.delete('$_itineraryPrefix${item.id}');
  }

  Future<void> saveItinerary(ItineraryPlan plan) async {
    if (plan.tripId.isEmpty) {
      throw ArgumentError('ItineraryPlan.tripId is required');
    }
    final userId = _userId;
    if (userId != 'anonymous') {
      await SupabaseService.instance.client.from('saved_itineraries').upsert({
        'user_id': userId,
        'trip_id': plan.tripId,
        'destination_name': plan.destinationName,
        'plan_data': plan.toMap(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'trip_id');
    }
    if (!mounted) return;
    setState(() => _itineraries[plan.tripId] = plan);
    await _box?.put('$_itineraryPrefix${plan.tripId}', plan.toMap());
  }

  Future<void> _upsertItem(SavedItem item) async {
    final userId = _userId;
    if (userId != 'anonymous') {
      await SupabaseService.instance.client
          .from('saved_trips')
          .upsert(_rowFromItem(item, userId), onConflict: 'id');
    }
    if (!mounted) return;
    setState(() {
      final index = _items.indexWhere((e) => e.id == item.id);
      if (index == -1) {
        _items.insert(0, item);
      } else {
        _items[index] = item;
      }
    });
    await _box?.put(item.id, item.toMap());
  }

  Future<void> _syncCollaboratorToCloud(SavedItem item, String emailOrName) async {
    final userId = _userId;
    final email = emailOrName.trim().toLowerCase();
    if (userId == 'anonymous' || !email.contains('@')) return;
    await SupabaseService.instance.client.from('trip_collaborators').upsert({
      'trip_id': item.id,
      'owner_id': userId,
      'collaborator_email': email,
      'role': 'editor',
      'status': 'pending',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'trip_id,collaborator_email');
  }

  // ── Mapping row Supabase <-> SavedItem ─────────────────────────────────

  Map<String, dynamic> _rowFromItem(SavedItem item, String userId) => {
        'id': item.id,
        'user_id': userId,
        'name': item.name,
        'image_url': item.imageUrl,
        'price': item.price,
        'match_percent': item.matchPercent,
        'rating': item.rating,
        'review_count': item.reviewCount,
        'ai_insight': item.aiInsight,
        'is_wishlist': item.tripData == null,
        'trip_data': item.tripData?.toMap(),
        'checklist': item.checklist.map((e) => e.toMap()).toList(),
        'workspace_notes': item.workspaceNotes,
        'booking_refs': item.bookingRefs,
        'shared_with': item.sharedWith,
        'saved_at': item.savedAt.toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  SavedItem _itemFromRow(Map<String, dynamic> map) {
    final rawTripData = map['trip_data'];
    final rawChecklist = map['checklist'];
    return SavedItem(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      price: map['price']?.toString() ?? '',
      matchPercent: (map['match_percent'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      aiInsight: map['ai_insight']?.toString() ?? '',
      tripData: map['is_wishlist'] == true || rawTripData is! Map
          ? null
          : TripData.fromMap(rawTripData),
      savedAt: DateTime.tryParse(map['saved_at']?.toString() ?? ''),
      checklist: rawChecklist is List
          ? rawChecklist.whereType<Map>().map(WorkspaceChecklistItem.fromMap).toList()
          : null,
      workspaceNotes: map['workspace_notes']?.toString() ?? '',
      bookingRefs: TripData.stringList(map['booking_refs']),
      sharedWith: TripData.stringList(map['shared_with']),
    );
  }

  String get _userId {
    try {
      return SupabaseService.instance.auth.currentUser?.id ?? 'anonymous';
    } catch (_) {
      return 'anonymous';
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

- [ ] **Step 2: Kiểm tra kích thước và không còn API cũ**

Run: `wc -l lib/data/saved_trips_provider.dart && grep -n "cloudId\|_syncFromSupabase\|_subscribeToSavedTrips\|_persistenceQueue\|_migrateLegacyDataIfNeeded" lib/data/saved_trips_provider.dart`
Expected: ngắn hơn 497 dòng, grep không có kết quả.

- [ ] **Step 3: Analyze file**

Run: `flutter analyze lib/data/saved_trips_provider.dart`
Expected: không lỗi trong file này. Lỗi ở `lib/screens/` (chữ ký `itineraryFor`, `Future` thay `bool`) là bình thường, sửa ở Task 4.

- [ ] **Step 4: Commit**

```bash
git add lib/data/saved_trips_provider.dart
git commit -m "refactor: SavedTripsProvider cloud-first by id, no merge sync, no realtime"
```

---

### Task 4: Screens dùng `id`, `await` khi ghi, restore đúng trip

**Files:**
- Modify: `lib/screens/saved_screen.dart` (dòng 160-166 điều hướng, 440-450 xoá, `_WorkspacePanel` khoảng dòng 540-660)
- Modify: `lib/screens/destination_detail_screen.dart` (constructor, `_loadDetail`, `_prefetchItinerary`, `_onSaveInfo`, nút tạo itinerary khoảng dòng 930-940)
- Modify: `lib/screens/destination_plan_screen.dart` (constructor, `_loadPlan`, `_refinePlan`)
- Modify: `lib/screens/suggestions_screen.dart` (`_onAddToWishlist` khoảng dòng 586)

**Interfaces:**
- Consumes: toàn bộ API provider ở Task 3; `TripData.dayCount()`, `ItineraryPlan.copyWith` ở Task 1.
- Produces: `DestinationDetailScreen({required destinationName, SavedItem? savedItem})`; `DestinationPlanScreen({required tripId, required destinationName, required dateRange})`.

- [ ] **Step 1: `saved_screen.dart`, điều hướng truyền `SavedItem`**

Thay `DestinationDetailScreen(destinationName: items[index].name)` bằng:

```dart
                    DestinationDetailScreen(
                      destinationName: items[index].name,
                      savedItem: items[index],
                    ),
```

- [ ] **Step 2: `saved_screen.dart`, helper chạy thao tác ghi**

Thêm hàm top-level ở cuối file:

```dart
/// Chạy một thao tác ghi lên cloud; lỗi thì hiện snackbar, không đổi UI.
Future<void> runSave(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: const Color(0xFFB91C1C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
```

- [ ] **Step 3: `saved_screen.dart`, xoá item chờ cloud**

Thay `onTap` của nút xoá (đang gọi `removeSavedItem(item)` rồi hiện snackbar ngay) bằng:

```dart
                    onTap: () => runSave(context, () async {
                      await SavedTripsProvider.of(context).removeSavedItem(item);
                      onRemoved?.call();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.savedItemRemoved,
                          ),
                          backgroundColor: const Color(0xFF475569),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }),
```

- [ ] **Step 4: `saved_screen.dart`, `_WorkspacePanel` ghi qua `runSave`, ghi chú lưu khi rời ô**

Trong `build` của `_WorkspacePanel`, ngay sau `final provider = SavedTripsProvider.of(context);` thêm:

```dart
    var notesDraft = item.workspaceNotes;
    void saveNotes() {
      if (notesDraft == item.workspaceNotes) return;
      runSave(context, () => provider.updateWorkspaceNotes(item, notesDraft));
    }
```

Thay các callback:
- Checkbox: `onChanged: (_) => runSave(context, () => provider.toggleChecklistItem(item, index)),`
- Ô ghi chú: thay `onChanged: (value) => provider.updateWorkspaceNotes(item, value),` bằng ba dòng:

```dart
            onChanged: (value) => notesDraft = value,
            onFieldSubmitted: (_) => saveNotes(),
            onTapOutside: (_) => saveNotes(),
```

- Booking: `onSubmit: (value) => runSave(context, () => provider.addBookingRef(item, value)),`
- Share: `onSubmit: (value) => runSave(context, () => provider.addSharedPerson(item, value)),`

- [ ] **Step 5: `destination_detail_screen.dart`, nhận `SavedItem`, trip đúng của item**

Constructor và state:

```dart
class DestinationDetailScreen extends StatefulWidget {
  const DestinationDetailScreen({
    super.key,
    required this.destinationName,
    this.savedItem,
  });

  final String destinationName;

  /// Khác null khi mở từ danh sách đã lưu: dùng tripData của trip đó,
  /// không dùng currentTrip toàn cục.
  final SavedItem? savedItem;
  ...
}
```

Trong `_DestinationDetailScreenState` thêm field và getter (sau `String? _error;`):

```dart
  SavedItem? _savedItem;

  TripData get _trip =>
      _savedItem?.tripData ?? SavedTripsProvider.of(context).currentTrip;
```

Trong `initState`, trước `WidgetsBinding...`: `_savedItem = widget.savedItem;`

Thêm import `import 'package:voyz/data/trip_data.dart';` nếu chưa có.

Trong `_loadDetail`: thay `final trip = SavedTripsProvider.of(context).currentTrip;` bằng `final trip = _trip;`.

Thay toàn bộ `_prefetchItinerary` bằng:

```dart
  Future<void> _prefetchItinerary() async {
    try {
      final trip = _trip;
      await GeminiService.instance.getItineraryPlan(
        widget.destinationName,
        trip.dayCount(),
        trip,
        limit: 3,
        languageCode: LocaleProvider.of(context).value.languageCode,
      );
    } catch (error) {
      debugPrint('Itinerary prefetch skipped: $error');
    }
  }
```

- [ ] **Step 6: `destination_detail_screen.dart`, lưu chờ cloud và tạo itinerary**

Thay toàn bộ `_onSaveInfo` bằng hai hàm:

```dart
  Future<SavedItem> _saveCurrentDetail() {
    final d = _detail!;
    return SavedTripsProvider.of(context).saveFullTrip(
      name: d.name,
      imageUrl: d.imageUrl,
      price: d.totalBudget,
      matchPercent: 98,
      rating: 4.5,
      reviewCount: 120,
      aiInsight: AppLocalizations.of(context)!.defaultAiInsight,
    );
  }

  Future<void> _onSaveInfo(BuildContext context) async {
    if (_detail == null) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final item = await _saveCurrentDetail();
      if (!mounted) return;
      setState(() => _savedItem = item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bookmark_added, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.tripInfoSaved)),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFB91C1C)),
      );
    }
  }

  /// Có itinerary tức là có trip: chưa lưu thì lưu trước rồi mới mở plan.
  Future<void> _onGenerateItinerary() async {
    if (_detail == null) return;
    try {
      _savedItem ??= await _saveCurrentDetail();
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DestinationPlanScreen(
            tripId: _savedItem!.id,
            destinationName: widget.destinationName,
            dateRange: _detail!.dateRange,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFB91C1C)),
      );
    }
  }
```

Widget nút (class có các field `theme`, `onSaveInfo`, `destinationName`, `dateRange`, khoảng dòng 915): thêm field `final VoidCallback onGenerateItinerary;` và tham số constructor `required this.onGenerateItinerary`. Thay `onPressed` của `GradientButton` "generateAiItinerary" bằng `onPressed: onGenerateItinerary,`. Ở nơi tạo widget này (khoảng dòng 403, cạnh `onSaveInfo: () => _onSaveInfo(context),`) thêm `onGenerateItinerary: _onGenerateItinerary,`.

Nếu `AppLocalizations.alreadySavedMessage` không còn ai dùng sau bước này, giữ key trong arb, không xoá (dọn l10n thuộc plan planner).

- [ ] **Step 7: `destination_plan_screen.dart`, nhận `tripId`**

Constructor:

```dart
  const DestinationPlanScreen({
    super.key,
    required this.tripId,
    required this.destinationName,
    required this.dateRange,
  });

  final String tripId;
  final String destinationName;
  final String dateRange;
```

Trong `_loadPlan`, thay từ `final savedPlan = provider.itineraryFor(widget.destinationName);` đến trước `if (mounted) {` bằng:

```dart
      final savedPlan = provider.itineraryFor(widget.tripId);
      if (savedPlan != null) {
        setState(() {
          _plan = savedPlan;
          _isLoading = false;
        });
        return;
      }

      final trip = provider.itemById(widget.tripId)?.tripData ?? provider.currentTrip;
      final generated = await GeminiService.instance.getItineraryPlan(
        widget.destinationName,
        trip.dayCount(),
        trip,
        limit: 3,
        languageCode: LocaleProvider.of(context).value.languageCode,
      );
      final plan = generated.copyWith(tripId: widget.tripId);
```

Và trong `if (mounted) { ... }` thay `provider.saveItinerary(plan);` bằng `await provider.saveItinerary(plan);` (đặt sau `setState`). Khối `catch` giữ nguyên: lỗi lưu cloud sẽ hiện qua `_error`.

Trong `_refinePlan`: thay `final trip = provider.currentTrip;` bằng `final trip = provider.itemById(widget.tripId)?.tripData ?? provider.currentTrip;`. Sau lời gọi `getItineraryPlan(...)` thêm `.copyWith(tripId: widget.tripId)` vào kết quả:

```dart
      final plan = (await GeminiService.instance.getItineraryPlan(
        widget.destinationName,
        numDays,
        trip,
        limit: 3,
        forceRefresh: true,
        languageCode: LocaleProvider.of(context).value.languageCode,
        additionalInstruction: instruction,
      )).copyWith(tripId: widget.tripId);
```

Thay `provider.saveItinerary(plan);` bằng `await provider.saveItinerary(plan);`. Khối `catch` hiện có đã hiện snackbar.

- [ ] **Step 8: `suggestions_screen.dart`, wishlist chờ cloud**

Thay `_onAddToWishlist` (trong `_CardActions`) bằng:

```dart
  Future<void> _onAddToWishlist(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final name = data['name'] as String;
    bool added;
    try {
      added = await SavedTripsProvider.of(context).saveToWishlist(
        name: name,
        imageUrl: data['imageUrl'] as String,
        price: data['price'] as String,
        matchPercent: data['matchPercent'] as int,
        rating: (data['rating'] as num).toDouble(),
        reviewCount: data['reviewCount'] as int,
        aiInsight: data['aiInsight'] as String,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFB91C1C)),
      );
      return;
    }
    if (!context.mounted) return;
    // Giữ nguyên phần showSnackBar hiện có bên dưới, dùng biến `added`.
```

Phần `ScaffoldMessenger.of(context).showSnackBar(...)` hiện có với `added ? ... : ...` giữ nguyên, chỉ bảo đảm nó nằm sau khối try/catch trên và `l10n`/`name` không bị khai báo hai lần.

- [ ] **Step 9: Tìm call site còn sót**

Run: `grep -rn "DestinationPlanScreen(\|itineraryFor(\|saveItinerary(\|removeSavedItem(\|saveFullTrip(\|saveToWishlist(" lib/screens/`
Expected: mọi `DestinationPlanScreen(` có `tripId:`; mọi hàm ghi đứng sau `await` hoặc trong `runSave`.

- [ ] **Step 10: Analyze và test toàn bộ**

Run: `flutter analyze && flutter test`
Expected: analyze không lỗi mới so với `master`; toàn bộ test PASS.

- [ ] **Step 11: Commit**

```bash
git add lib/screens/saved_screen.dart lib/screens/destination_detail_screen.dart lib/screens/destination_plan_screen.dart lib/screens/suggestions_screen.dart
git commit -m "feat: screens pass SavedItem/tripId, await cloud writes, restore saved trip data"
```

---

### Task 5: Nghiệm thu tay và mở PR

**Files:** không sửa code.

- [ ] **Step 1: Giáo viên apply migration**

`supabase db push` với migration `20260907000100_trip_identity.sql`. Chưa apply thì upsert `saved_itineraries` sẽ lỗi vì thiếu cột `trip_id`.

- [ ] **Step 2: Chạy app, kiểm tra 5 tiêu chí của spec mục 2.8**

1. Tạo hai chuyến "Đà Nẵng" với ngày khác nhau (planner, gợi ý, detail, Lưu). Vào Saved: cả hai cùng hiện. Mở từng chuyến: ngày và ngân sách đúng của chuyến đó. Tạo itinerary cho mỗi chuyến: hai itinerary khác nhau.
2. Mở hai trình duyệt cùng tài khoản. Xoá một trip ở A, reload B: trip mất, không sống lại.
3. Tắt mạng (DevTools Offline), bấm Lưu ở detail: snackbar lỗi, Saved không có item mới. Bật mạng, bấm lại: lưu được.
4. Xoá một dòng lịch sử tìm kiếm, reload: dòng đó không quay lại.
5. Run: `grep -rn "cloudId\|_syncFromSupabase\|_subscribeToSavedTrips" lib/` trả về rỗng.

- [ ] **Step 3: Mở PR**

```bash
git push -u origin trip-identity
gh pr create --title "Trip identity by UUID, cloud-first SavedTripsProvider" --body "$(cat <<'BODY'
## Summary
- SavedItem.id (client UUID), ItineraryPlan.tripId, TripData.dayCount (inclusive, 1..7)
- Migration: drop unique (user_id, name); saved_itineraries keyed by trip_id; search_history DELETE policy; test rows reset
- SavedTripsProvider rewritten: load cloud-first into Hive snapshot, every write awaits Supabase, no merge sync, no realtime
- Screens pass SavedItem/tripId, restore saved trip data, show snackbar on write failure
- Rule: generating an itinerary saves the trip first

Spec: docs/superpowers/specs/2026-09-06-simple-cache-and-trip-identity-design.md part 2

Teacher: run supabase db push before testing.

## Test plan
- [ ] flutter analyze, flutter test pass
- [ ] Two "Da Nang" trips coexist with separate itineraries
- [ ] Delete on browser A, reload B: gone
- [ ] Offline save shows error, nothing changes
- [ ] Search history delete sticks
BODY
)"
```

---

## Self-review

- Spec 2.3 (model, `uuid`, `dayCount`): Task 1.
- Spec 2.4 (migration SQL nguyên văn): Task 2.
- Spec 2.5 (provider API, Hive snapshot, luồng load, luồng ghi, xoá box cũ, `addSharedPerson` dùng `item.id`): Task 3.
- Spec 2.6 (4 screens, quy tắc "có itinerary tức là có trip", `dayCount`): Task 4. Ghi chú thêm so với spec: ô ghi chú lưu khi rời ô (`onTapOutside`/`onFieldSubmitted`) thay cho mỗi phím gõ, vì mỗi lần ghi giờ là một request cloud.
- Spec 2.7 (test): Task 1 step 2 phủ 4 điểm của spec.
- Spec 2.8 (nghiệm thu): Task 5.
- Tên nhất quán giữa Task 3 và Task 4: `itineraryFor(tripId)`, `itemById(id)`, `saveFullTrip` trả `Future<SavedItem>`, `saveToWishlist` trả `Future<bool>`, `removeSavedItem`, `saveItinerary`, `toggleChecklistItem`, `updateWorkspaceNotes`, `addBookingRef`, `addSharedPerson`; `DestinationPlanScreen(tripId:, destinationName:, dateRange:)`; `DestinationDetailScreen(destinationName:, savedItem:)`.
