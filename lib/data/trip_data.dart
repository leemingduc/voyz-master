// Data model for trip planner form and saved items.

class TripData {
  String destination;
  DateTime? departDate;
  DateTime? returnDate;
  String budget;
  String currency;
  String participants;
  String ageRange;
  String additionalNotes;
  String aiPrompt;
  List<String> selectedInterests;

  TripData({
    this.destination = '',
    this.departDate,
    this.returnDate,
    this.budget = '',
    this.currency = 'VND',
    this.participants = '',
    this.ageRange = '',
    this.additionalNotes = '',
    this.aiPrompt = '',
    this.selectedInterests = const [],
  });

  factory TripData.fromMap(Map<dynamic, dynamic> map) {
    return TripData(
      destination: map['destination']?.toString() ?? '',
      departDate: _parseDate(map['departDate']),
      returnDate: _parseDate(map['returnDate']),
      budget: map['budget']?.toString() ?? '',
      currency: map['currency']?.toString() ?? 'VND',
      participants: map['participants']?.toString() ?? '',
      ageRange: map['ageRange']?.toString() ?? '',
      additionalNotes: map['additionalNotes']?.toString() ?? '',
      aiPrompt: map['aiPrompt']?.toString() ?? '',
      selectedInterests: stringList(map['selectedInterests']),
    );
  }

  TripData copyWith({
    String? destination,
    DateTime? departDate,
    DateTime? returnDate,
    String? budget,
    String? currency,
    String? participants,
    String? ageRange,
    String? additionalNotes,
    String? aiPrompt,
    List<String>? selectedInterests,
  }) {
    return TripData(
      destination: destination ?? this.destination,
      departDate: departDate ?? this.departDate,
      returnDate: returnDate ?? this.returnDate,
      budget: budget ?? this.budget,
      currency: currency ?? this.currency,
      participants: participants ?? this.participants,
      ageRange: ageRange ?? this.ageRange,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      aiPrompt: aiPrompt ?? this.aiPrompt,
      selectedInterests: selectedInterests ?? this.selectedInterests,
    );
  }

  Map<String, dynamic> toMap() => {
    'destination': destination,
    'departDate': departDate?.toIso8601String(),
    'returnDate': returnDate?.toIso8601String(),
    'budget': budget,
    'currency': currency,
    'participants': participants,
    'ageRange': ageRange,
    'additionalNotes': additionalNotes,
    'aiPrompt': aiPrompt,
    'selectedInterests': selectedInterests,
  };

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static List<String> stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }
}

class WorkspaceChecklistItem {
  final String text;
  final bool isDone;

  const WorkspaceChecklistItem({required this.text, this.isDone = false});

  factory WorkspaceChecklistItem.fromMap(Map<dynamic, dynamic> map) {
    return WorkspaceChecklistItem(
      text: map['text']?.toString() ?? '',
      isDone: map['isDone'] == true,
    );
  }

  Map<String, dynamic> toMap() => {'text': text, 'isDone': isDone};
}

/// Represents a saved destination: either a full trip workspace or wishlist card.
class SavedItem {
  final String? cloudId;
  final String name;
  final String imageUrl;
  final String price;
  final int matchPercent;
  final double rating;
  final int reviewCount;
  final String aiInsight;
  final TripData? tripData;
  final DateTime savedAt;
  final List<WorkspaceChecklistItem> checklist;
  final String workspaceNotes;
  final List<String> bookingRefs;
  final List<String> sharedWith;

  SavedItem({
    this.cloudId,
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
  }) : savedAt = savedAt ?? DateTime.now(),
       checklist = checklist ?? _defaultChecklist(),
       bookingRefs = bookingRefs ?? const [],
       sharedWith = sharedWith ?? const [];

  factory SavedItem.fromMap(Map<dynamic, dynamic> map) {
    final tripMap = map['tripData'];
    return SavedItem(
      cloudId: map['cloudId']?.toString(),
      name: map['name']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      price: map['price']?.toString() ?? '',
      matchPercent: (map['matchPercent'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      aiInsight: map['aiInsight']?.toString() ?? '',
      tripData: tripMap is Map ? TripData.fromMap(tripMap) : null,
      savedAt: DateTime.tryParse(map['savedAt']?.toString() ?? ''),
      checklist: (map['checklist'] as List?)
          ?.whereType<Map>()
          .map(WorkspaceChecklistItem.fromMap)
          .where((item) => item.text.isNotEmpty)
          .toList(),
      workspaceNotes: map['workspaceNotes']?.toString() ?? '',
      bookingRefs: TripData.stringList(map['bookingRefs']),
      sharedWith: TripData.stringList(map['sharedWith']),
    );
  }

  SavedItem copyWith({
    String? cloudId,
    String? name,
    String? imageUrl,
    String? price,
    int? matchPercent,
    double? rating,
    int? reviewCount,
    String? aiInsight,
    TripData? tripData,
    DateTime? savedAt,
    List<WorkspaceChecklistItem>? checklist,
    String? workspaceNotes,
    List<String>? bookingRefs,
    List<String>? sharedWith,
  }) {
    return SavedItem(
      cloudId: cloudId ?? this.cloudId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      matchPercent: matchPercent ?? this.matchPercent,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      aiInsight: aiInsight ?? this.aiInsight,
      tripData: tripData ?? this.tripData,
      savedAt: savedAt ?? this.savedAt,
      checklist: checklist ?? this.checklist,
      workspaceNotes: workspaceNotes ?? this.workspaceNotes,
      bookingRefs: bookingRefs ?? this.bookingRefs,
      sharedWith: sharedWith ?? this.sharedWith,
    );
  }

  Map<String, dynamic> toMap() => {
    'cloudId': cloudId,
    'name': name,
    'imageUrl': imageUrl,
    'price': price,
    'matchPercent': matchPercent,
    'rating': rating,
    'reviewCount': reviewCount,
    'aiInsight': aiInsight,
    'tripData': tripData?.toMap(),
    'savedAt': savedAt.toIso8601String(),
    'checklist': checklist.map((item) => item.toMap()).toList(),
    'workspaceNotes': workspaceNotes,
    'bookingRefs': bookingRefs,
    'sharedWith': sharedWith,
  };

  static List<WorkspaceChecklistItem> _defaultChecklist() => const [
    WorkspaceChecklistItem(text: 'Passport / personal ID'),
    WorkspaceChecklistItem(text: 'Flight, hotel, or tour booking'),
    WorkspaceChecklistItem(text: 'Cash, cards, and travel insurance'),
    WorkspaceChecklistItem(text: 'Charger, SIM/eSIM, and medicine'),
  ];
}
