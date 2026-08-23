import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/itinerary_plan.dart';
import 'package:voyz/services/supabase_service.dart';

/// InheritedWidget-based provider for sharing trip data and saved items
/// across screens with two-way Offline-First Cloud Sync (Hive + Supabase).
class SavedTripsProvider extends StatefulWidget {
  const SavedTripsProvider({super.key, required this.child});
  final Widget child;

  @override
  State<SavedTripsProvider> createState() => SavedTripsProviderState();

  /// Convenience accessor.
  static SavedTripsProviderState of(BuildContext context) {
    final state = context.findAncestorStateOfType<SavedTripsProviderState>();
    assert(state != null, 'No SavedTripsProvider found in widget tree');
    return state!;
  }
}

class SavedTripsProviderState extends State<SavedTripsProvider> {
  static const _boxPrefix = 'saved_trip_workspaces_';
  static const _legacyBoxName = 'saved_trip_workspaces';
  static const _migrationBoxName = 'storage_migrations';
  static const _currentTripKey = '__current_trip';
  static const _itineraryPrefix = '__itinerary_';

  TripData _currentTrip = TripData();
  final List<SavedItem> _savedItems = [];
  final Map<String, ItineraryPlan> _itineraries = {};
  Box<Map>? _box;
  String? _activeUserId;
  StreamSubscription? _authSubscription;
  Future<void> _persistenceQueue = Future.value();

  TripData get currentTrip => _currentTrip;
  List<SavedItem> get savedItems => List.unmodifiable(_savedItems);
  List<SavedItem> get tripWorkspaces =>
      _savedItems.where((item) => item.tripData != null).toList();
  List<SavedItem> get wishlistItems =>
      _savedItems.where((item) => item.tripData == null).toList();

  ItineraryPlan? itineraryFor(String destinationName) =>
      _itineraries[destinationName];

  @override
  void initState() {
    super.initState();
    _loadSavedItems();
    try {
      _authSubscription = SupabaseService.instance.auth.onAuthStateChange
          .listen((_) => _loadSavedItems());
    } on AssertionError {
      // Widget tests and offline startup can run before Supabase is available.
    }
  }

  Future<void> _loadSavedItems() async {
    final userId = _currentUserId;
    final box = await Hive.openBox<Map>(_boxNameFor(userId));
    await _migrateLegacyDataIfNeeded(box, userId);
    if (!mounted || userId != _currentUserId) return;

    final items = <SavedItem>[];
    final itineraries = <String, ItineraryPlan>{};
    var currentTrip = TripData();
    for (final entry in box.toMap().entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (key == _currentTripKey) {
        currentTrip = TripData.fromMap(value);
      } else if (key.startsWith(_itineraryPrefix)) {
        final plan = ItineraryPlan.fromJson(Map<String, dynamic>.from(value));
        if (plan.destinationName.isNotEmpty) {
          itineraries[plan.destinationName] = plan;
        }
      } else {
        final item = SavedItem.fromMap(value);
        if (item.name.isNotEmpty) items.add(item);
      }
    }
    items.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    setState(() {
      _box = box;
      _activeUserId = userId;
      _currentTrip = currentTrip;
      _savedItems
        ..clear()
        ..addAll(items);
      _itineraries
        ..clear()
        ..addAll(itineraries);
    });

    // Background two-way sync with Supabase Cloud
    if (userId != 'anonymous') {
      unawaited(_syncFromSupabase(userId));
    }
  }

  Future<void> _syncFromSupabase(String userId) async {
    try {
      final client = SupabaseService.instance.client;

      // 1. Fetch saved trips from cloud
      final tripRows = await client
          .from('saved_trips')
          .select()
          .eq('user_id', userId)
          .order('saved_at', ascending: false);

      final cloudItems = <SavedItem>[];
      for (final row in tripRows) {
        final map = Map<String, dynamic>.from(row);
        final isWishlist = map['is_wishlist'] == true;
        final rawTripData = map['trip_data'];
        TripData? tripData;
        if (!isWishlist && rawTripData is Map) {
          tripData = TripData.fromMap(rawTripData);
        }

        final rawChecklist = map['checklist'];
        List<WorkspaceChecklistItem>? checklist;
        if (rawChecklist is List) {
          checklist = rawChecklist
              .whereType<Map>()
              .map(WorkspaceChecklistItem.fromMap)
              .toList();
        }

        cloudItems.add(
          SavedItem(
            name: map['name']?.toString() ?? '',
            imageUrl: map['image_url']?.toString() ?? '',
            price: map['price']?.toString() ?? '',
            matchPercent: (map['match_percent'] as num?)?.toInt() ?? 0,
            rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
            reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
            aiInsight: map['ai_insight']?.toString() ?? '',
            tripData: tripData,
            savedAt: DateTime.tryParse(map['saved_at']?.toString() ?? ''),
            checklist: checklist,
            workspaceNotes: map['workspace_notes']?.toString() ?? '',
            bookingRefs: TripData.stringList(map['booking_refs']),
            sharedWith: TripData.stringList(map['shared_with']),
          ),
        );
      }

      // 2. Fetch saved itineraries from cloud
      final itineraryRows = await client
          .from('saved_itineraries')
          .select()
          .eq('user_id', userId);

      final cloudItineraries = <String, ItineraryPlan>{};
      for (final row in itineraryRows) {
        final map = Map<String, dynamic>.from(row);
        final destName = map['destination_name']?.toString() ?? '';
        final rawPlan = map['plan_data'];
        if (destName.isNotEmpty && rawPlan is Map) {
          final plan = ItineraryPlan.fromJson(Map<String, dynamic>.from(rawPlan));
          cloudItineraries[destName] = plan;
        }
      }

      if (!mounted || userId != _currentUserId) return;

      // Merge cloud items with local items (if local has items not on cloud, push them)
      final existingNames = cloudItems.map((e) => e.name).toSet();
      for (final localItem in _savedItems) {
        if (!existingNames.contains(localItem.name)) {
          cloudItems.add(localItem);
          _syncItemToCloud(localItem, userId);
        }
      }

      cloudItems.sort((a, b) => b.savedAt.compareTo(a.savedAt));

      // Update state and cache
      setState(() {
        _savedItems
          ..clear()
          ..addAll(cloudItems);
        _itineraries.addAll(cloudItineraries);
      });

      // Update local Hive box
      final box = _box;
      if (box != null) {
        for (final item in cloudItems) {
          await box.put(item.name, item.toMap());
        }
        for (final entry in cloudItineraries.entries) {
          await box.put('$_itineraryPrefix${entry.key}', entry.value.toMap());
        }
      }
    } catch (e) {
      debugPrint('SavedTripsProvider Supabase sync error: $e');
    }
  }

  Future<void> _persist() {
    final userId = _currentUserId;
    if (_activeUserId != userId) {
      unawaited(_loadSavedItems());
      return Future.value();
    }
    _persistenceQueue = _persistenceQueue.then((_) async {
      final box = _box ?? await Hive.openBox<Map>(_boxNameFor(userId));
      _box = box;
      await box.clear();
      await box.put(_currentTripKey, _currentTrip.toMap());
      for (final item in _savedItems) {
        await box.put(item.name, item.toMap());
      }
      for (final entry in _itineraries.entries) {
        await box.put('$_itineraryPrefix${entry.key}', entry.value.toMap());
      }
    });
    return _persistenceQueue;
  }

  void _syncItemToCloud(SavedItem item, [String? targetUserId]) {
    final userId = targetUserId ?? _currentUserId;
    if (userId == 'anonymous') return;

    final client = SupabaseService.instance.client;
    final payload = {
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

    client
        .from('saved_trips')
        .upsert(payload, onConflict: 'user_id,name')
        .then((_) {})
        .catchError((e) {
      debugPrint('Error syncing saved item to Supabase: $e');
    });
  }

  void _deleteItemFromCloud(String name) {
    final userId = _currentUserId;
    if (userId == 'anonymous') return;

    final client = SupabaseService.instance.client;
    client
        .from('saved_trips')
        .delete()
        .eq('user_id', userId)
        .eq('name', name)
        .then((_) {})
        .catchError((e) {
      debugPrint('Error deleting saved item from Supabase: $e');
    });
  }

  void _syncItineraryToCloud(String destinationName, ItineraryPlan plan) {
    final userId = _currentUserId;
    if (userId == 'anonymous') return;

    final client = SupabaseService.instance.client;
    final payload = {
      'user_id': userId,
      'destination_name': destinationName,
      'plan_data': plan.toMap(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    client
        .from('saved_itineraries')
        .upsert(payload, onConflict: 'user_id,destination_name')
        .then((_) {})
        .catchError((e) {
      debugPrint('Error syncing itinerary to Supabase: $e');
    });
  }

  String get _currentUserId {
    try {
      return SupabaseService.instance.auth.currentUser?.id ?? 'anonymous';
    } on AssertionError {
      return 'anonymous';
    }
  }

  String _boxNameFor(String userId) => '$_boxPrefix$userId';

  Future<void> _migrateLegacyDataIfNeeded(Box<Map> box, String userId) async {
    if (box.isNotEmpty || userId == 'anonymous') return;

    final migrationBox = await Hive.openBox<String>(_migrationBoxName);
    if (migrationBox.containsKey(_legacyBoxName)) return;

    final legacyBox = await Hive.openBox<Map>(_legacyBoxName);
    if (legacyBox.isNotEmpty) {
      await box.putAll(legacyBox.toMap());
    }
    await migrationBox.put(_legacyBoxName, userId);
  }

  /// Update the current trip form data.
  void updateTrip(TripData trip) {
    setState(() => _currentTrip = trip);
    _persist();
  }

  void saveItinerary(ItineraryPlan plan) {
    if (plan.destinationName.isEmpty) return;
    setState(() => _itineraries[plan.destinationName] = plan);
    _persist();
    _syncItineraryToCloud(plan.destinationName, plan);
  }

  /// Save the full trip (planner data + destination detail) to the saved list.
  /// Returns false if the item already exists (duplicate by name).
  bool saveFullTrip({
    required String name,
    required String imageUrl,
    required String price,
    required int matchPercent,
    required double rating,
    required int reviewCount,
    required String aiInsight,
  }) {
    if (_savedItems.any((e) => e.name == name)) return false;
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
    setState(() {
      _savedItems.insert(0, item);
    });
    _persist();
    _syncItemToCloud(item);
    return true;
  }

  /// Save only the destination card to the wishlist (no planner data).
  /// Returns false if the item already exists (duplicate by name).
  bool saveToWishlist({
    required String name,
    required String imageUrl,
    required String price,
    required int matchPercent,
    required double rating,
    required int reviewCount,
    required String aiInsight,
  }) {
    if (_savedItems.any((e) => e.name == name)) return false;
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
    setState(() {
      _savedItems.insert(0, item);
    });
    _persist();
    _syncItemToCloud(item);
    return true;
  }

  void updateWorkspace(SavedItem item, SavedItem updated) {
    final index = _savedItems.indexOf(item);
    if (index == -1) return;
    setState(() => _savedItems[index] = updated);
    _persist();
    _syncItemToCloud(updated);
  }

  void toggleChecklistItem(SavedItem item, int index) {
    if (index < 0 || index >= item.checklist.length) return;
    final checklist = List<WorkspaceChecklistItem>.of(item.checklist);
    final current = checklist[index];
    checklist[index] = WorkspaceChecklistItem(
      text: current.text,
      isDone: !current.isDone,
    );
    updateWorkspace(item, item.copyWith(checklist: checklist));
  }

  void updateWorkspaceNotes(SavedItem item, String notes) {
    updateWorkspace(item, item.copyWith(workspaceNotes: notes));
  }

  void addBookingRef(SavedItem item, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    updateWorkspace(
      item,
      item.copyWith(bookingRefs: [...item.bookingRefs, trimmed]),
    );
  }

  void addSharedPerson(SavedItem item, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    updateWorkspace(
      item,
      item.copyWith(sharedWith: [...item.sharedWith, trimmed]),
    );
  }

  /// Remove an item from saved list.
  void removeSavedItem(SavedItem item) {
    setState(() => _savedItems.remove(item));
    _persist();
    _deleteItemFromCloud(item.name);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
