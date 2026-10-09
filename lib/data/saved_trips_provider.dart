import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/itinerary_plan.dart';
import 'package:voyz/models/plan_turn.dart';
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
  static const _plannerMessagesKey = '__planner_messages';
  static const _plannerConversationsKey = '__planner_conversations';
  static const _oldBoxNames = ['saved_trip_workspaces', 'storage_migrations'];

  TripData _currentTrip = TripData();
  final List<SavedItem> _items = [];
  final Map<String, ItineraryPlan> _itineraries = {}; // key = tripId
  // Các hội thoại Gợi ý AI được lưu cục bộ theo tài khoản.
  List<PlannerConversation> _plannerConversations = const [];
  String? _activePlannerConversationId;
  Box<Map>? _box;
  StreamSubscription? _authSubscription;
  final Set<String> _deletedOldBoxes = {};
  Future<void>? _inFlightLoad;
  String? _inFlightLoadUserId;
  bool _isLoading = true;
  String? _loadError;

  TripData get currentTrip => _currentTrip;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  List<PlannerMessage> get plannerMessages => List<PlannerMessage>.unmodifiable(
    _activePlannerConversation?.messages ?? const [],
  );
  List<PlannerConversation> get plannerConversations =>
      List<PlannerConversation>.unmodifiable(_plannerConversations);
  String? get activePlannerConversationId => _activePlannerConversationId;
  PlannerConversation? get _activePlannerConversation {
    final id = _activePlannerConversationId;
    if (id == null) return null;
    for (final conversation in _plannerConversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

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

  /// Gộp các lần gọi load() trùng userId đang chạy dở thành một Future.
  Future<void> load() {
    final userId = _userId;
    final inFlight = _inFlightLoad;
    if (inFlight != null && _inFlightLoadUserId == userId) return inFlight;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    final future = _loadInternal(userId);
    _inFlightLoad = future;
    _inFlightLoadUserId = userId;
    return future.whenComplete(() {
      if (_inFlightLoadUserId == userId) {
        _inFlightLoad = null;
        _inFlightLoadUserId = null;
      }
      if (mounted && userId == _userId) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _loadInternal(String userId) async {
    await _deleteOldBoxesOnce(userId);
    final box = await Hive.openBox<Map>('$_boxPrefix$userId');
    if (!mounted || userId != _userId) return; // user đổi trong lúc mở box
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
        for (final row in tripRows)
          _itemFromRow(Map<String, dynamic>.from(row)),
      ];
      final plans = <String, ItineraryPlan>{};
      for (final row in planRows) {
        final map = Map<String, dynamic>.from(row);
        final planData = _deepMap(map['plan_data'] as Map? ?? {});
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
      debugPrint(
        'SavedTripsProvider: cloud load failed, keeping Hive snapshot: $e',
      );
      if (mounted && userId == _userId) {
        setState(() => _loadError = e.toString());
      }
    }
  }

  void _readFromHive(Box<Map> box) {
    final items = <SavedItem>[];
    final plans = <String, ItineraryPlan>{};
    var plannerConversations = <PlannerConversation>[];
    var activePlannerConversationId = '';
    var legacyPlannerMessages = <PlannerMessage>[];
    var current = TripData();
    for (final entry in box.toMap().entries) {
      final key = entry.key.toString();
      try {
        if (key == _currentTripKey) {
          current = TripData.fromMap(entry.value);
        } else if (key == _plannerConversationsKey) {
          final saved = _plannerConversationsFromMap(entry.value);
          plannerConversations = saved.conversations;
          activePlannerConversationId = saved.activeId;
        } else if (key == _plannerMessagesKey) {
          legacyPlannerMessages = _plannerMessagesFromMap(entry.value);
        } else if (key.startsWith(_itineraryPrefix)) {
          final plan = ItineraryPlan.fromJson(_deepMap(entry.value));
          if (plan.tripId.isNotEmpty) plans[plan.tripId] = plan;
        } else {
          items.add(SavedItem.fromMap(entry.value));
        }
      } catch (e) {
        debugPrint('SavedTripsProvider: corrupt Hive entry "$key" skipped: $e');
      }
    }
    if (plannerConversations.isEmpty && legacyPlannerMessages.isNotEmpty) {
      final conversation = PlannerConversation(messages: legacyPlannerMessages);
      plannerConversations = [conversation];
      activePlannerConversationId = conversation.id;
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
      _plannerConversations = plannerConversations;
      _activePlannerConversationId =
          plannerConversations.any(
            (conversation) => conversation.id == activePlannerConversationId,
          )
          ? activePlannerConversationId
          : null;
    });
  }

  List<PlannerMessage> _plannerMessagesFromMap(Map<dynamic, dynamic> map) {
    final rawMessages = map['messages'];
    if (rawMessages is! List) return const [];
    return rawMessages
        .whereType<Map>()
        .map(PlannerMessage.fromMap)
        .where((message) => message.text.isNotEmpty)
        .toList();
  }

  ({List<PlannerConversation> conversations, String activeId})
  _plannerConversationsFromMap(Map<dynamic, dynamic> map) {
    final rawConversations = map['conversations'];
    if (rawConversations is! List) {
      return (conversations: const [], activeId: '');
    }
    final conversations =
        rawConversations
            .whereType<Map>()
            .map(PlannerConversation.fromMap)
            .where((conversation) => conversation.messages.isNotEmpty)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return (
      conversations: conversations,
      activeId: map['activeId']?.toString() ?? '',
    );
  }

  /// Hive/Supabase jsonb trả về map/list lồng nhau kiểu dynamic; chuyển đệ quy
  /// sang `Map<String, dynamic>` để ItineraryPlan.fromJson không ném TypeError.
  Map<String, dynamic> _deepMap(Map raw) =>
      raw.map((key, value) => MapEntry(key.toString(), _deepConvert(value)));

  dynamic _deepConvert(dynamic value) {
    if (value is Map) return _deepMap(value);
    if (value is List) return value.map(_deepConvert).toList();
    return value;
  }

  /// Ghi đè ảnh chụp: xoá key không còn trên cloud, put từng item và plan.
  Future<void> _writeSnapshot(
    Box<Map> box,
    List<SavedItem> items,
    Map<String, ItineraryPlan> plans,
  ) async {
    final keep = <String>{
      _currentTripKey,
      if (_plannerConversations.isNotEmpty) _plannerConversationsKey,
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
    await _writePlannerConversations(box);
  }

  Future<void> _deleteOldBoxesOnce(String userId) async {
    for (final name in [..._oldBoxNames, 'saved_trip_workspaces_$userId']) {
      if (_deletedOldBoxes.contains(name)) continue;
      _deletedOldBoxes.add(name);
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

  Future<void> updatePlannerMessages(Iterable<PlannerMessage> messages) async {
    // The planner can be used as soon as the first screen is visible, while
    // this provider may still be opening its Hive box. Wait for that initial
    // load before changing the in-memory history, then write the exact turn
    // that was supplied by the screen.
    await _ensurePlannerStorage();
    final updated = List<PlannerMessage>.of(messages);
    if (updated.isEmpty) return;
    final active = _activePlannerConversation;
    final conversation = active == null
        ? PlannerConversation(messages: updated)
        : active.copyWith(messages: updated, updatedAt: DateTime.now());
    setState(() {
      _plannerConversations = [
        conversation,
        ..._plannerConversations.where((item) => item.id != conversation.id),
      ];
      _activePlannerConversationId = conversation.id;
    });
    await _persistPlannerConversations();
  }

  /// Starts a blank conversation while preserving every previous one.
  Future<void> startNewPlannerConversation() async {
    await _ensurePlannerStorage();
    if (_activePlannerConversationId == null) return;
    setState(() => _activePlannerConversationId = null);
    await _persistPlannerConversations();
  }

  Future<List<PlannerMessage>> openPlannerConversation(String id) async {
    await _ensurePlannerStorage();
    final conversation = _plannerConversations.where((item) => item.id == id);
    if (conversation.isEmpty) return const [];
    final selected = conversation.first;
    setState(() {
      _activePlannerConversationId = selected.id;
      _plannerConversations = [
        selected.copyWith(updatedAt: DateTime.now()),
        ..._plannerConversations.where((item) => item.id != selected.id),
      ];
    });
    await _persistPlannerConversations();
    return plannerMessages;
  }

  Future<void> deletePlannerConversation(String id) async {
    await _ensurePlannerStorage();
    setState(() {
      _plannerConversations = _plannerConversations
          .where((conversation) => conversation.id != id)
          .toList();
      if (_activePlannerConversationId == id) {
        _activePlannerConversationId = null;
      }
    });
    await _persistPlannerConversations();
  }

  /// Kept for older callers: clear only the active conversation.
  Future<void> clearPlannerMessages() async {
    final id = _activePlannerConversationId;
    if (id == null) return;
    await deletePlannerConversation(id);
  }

  Future<void> _persistPlannerConversations() async {
    await _ensurePlannerStorage();
    final box = _box;
    if (box == null) return;
    await _writePlannerConversations(box);
  }

  Future<void> _ensurePlannerStorage() async {
    if (_box != null) return;
    await load();
  }

  Future<void> _writePlannerConversations(Box<Map> box) async {
    if (_plannerConversations.isEmpty) {
      await box.delete(_plannerConversationsKey);
      await box.delete(_plannerMessagesKey);
      return;
    }
    await box.put(_plannerConversationsKey, {
      'activeId': _activePlannerConversationId,
      'conversations': _plannerConversations
          .map((conversation) => conversation.toMap())
          .toList(),
    });
    await box.delete(_plannerMessagesKey);
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
    TripData? tripData,
  }) async {
    final item = SavedItem(
      name: name,
      imageUrl: imageUrl,
      price: price,
      matchPercent: matchPercent,
      rating: rating,
      reviewCount: reviewCount,
      aiInsight: aiInsight,
      tripData: (tripData ?? _currentTrip).copyWith(),
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
    checklist[index] = WorkspaceChecklistItem(
      text: current.text,
      isDone: !current.isDone,
    );
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
    await updateWorkspace(
      item.copyWith(sharedWith: [...item.sharedWith, trimmed]),
    );
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
    if (!mounted || userId != _userId) return;
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
    if (!mounted || userId != _userId) return;
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
    if (!mounted || userId != _userId) return;
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

  Future<void> _syncCollaboratorToCloud(
    SavedItem item,
    String emailOrName,
  ) async {
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
    'saved_at': item.savedAt.toUtc().toIso8601String(),
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
          ? rawChecklist
                .whereType<Map>()
                .map(WorkspaceChecklistItem.fromMap)
                .toList()
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
