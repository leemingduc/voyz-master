import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/data/trip_data.dart';

/// InheritedWidget-based provider for sharing trip data and saved items
/// across screens without adding a state management dependency.
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
  static const _boxName = 'saved_trip_workspaces';

  TripData _currentTrip = TripData();
  final List<SavedItem> _savedItems = [];
  Box<Map>? _box;

  TripData get currentTrip => _currentTrip;
  List<SavedItem> get savedItems => List.unmodifiable(_savedItems);
  List<SavedItem> get tripWorkspaces =>
      _savedItems.where((item) => item.tripData != null).toList();
  List<SavedItem> get wishlistItems =>
      _savedItems.where((item) => item.tripData == null).toList();

  @override
  void initState() {
    super.initState();
    _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    final box = await Hive.openBox<Map>(_boxName);
    final items = box.values
        .map(SavedItem.fromMap)
        .where((item) => item.name.isNotEmpty)
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    if (!mounted) return;
    setState(() {
      _box = box;
      _savedItems
        ..clear()
        ..addAll(items);
    });
  }

  Future<void> _persist() async {
    final box = _box ?? await Hive.openBox<Map>(_boxName);
    _box = box;
    await box.clear();
    for (final item in _savedItems) {
      await box.put(item.name, item.toMap());
    }
  }

  /// Update the current trip form data.
  void updateTrip(TripData trip) {
    setState(() => _currentTrip = trip);
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
    setState(() {
      _savedItems.insert(
        0,
        SavedItem(
          name: name,
          imageUrl: imageUrl,
          price: price,
          matchPercent: matchPercent,
          rating: rating,
          reviewCount: reviewCount,
          aiInsight: aiInsight,
          tripData: _currentTrip.copyWith(),
        ),
      );
    });
    _persist();
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
    setState(() {
      _savedItems.insert(
        0,
        SavedItem(
          name: name,
          imageUrl: imageUrl,
          price: price,
          matchPercent: matchPercent,
          rating: rating,
          reviewCount: reviewCount,
          aiInsight: aiInsight,
          tripData: null,
        ),
      );
    });
    _persist();
    return true;
  }

  void updateWorkspace(SavedItem item, SavedItem updated) {
    final index = _savedItems.indexOf(item);
    if (index == -1) return;
    setState(() => _savedItems[index] = updated);
    _persist();
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
  }

  @override
  Widget build(BuildContext context) => widget.child;
}