/// Model for destination detail displayed on the Destination Detail screen.
class DestinationDetail {
  final String name;
  final String location;
  final String imageUrl;
  final List<String> tags;
  final String weather;
  final String dateRange;
  final String totalBudget;
  final List<BudgetItem> budgetBreakdown;
  final List<DestinationLandmarkPhoto> gallery;

  const DestinationDetail({
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.tags,
    required this.weather,
    required this.dateRange,
    required this.totalBudget,
    required this.budgetBreakdown,
    this.gallery = const [],
  });

  factory DestinationDetail.fromJson(
    Map<String, dynamic> json,
    String imageUrl, {
    List<DestinationLandmarkPhoto> gallery = const [],
  }) {
    return DestinationDetail(
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      imageUrl: imageUrl,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      weather: json['weather'] as String? ?? '',
      dateRange: json['dateRange'] as String? ?? '',
      totalBudget: json['totalBudget'] as String? ?? '',
      budgetBreakdown:
          (json['budgetBreakdown'] as List<dynamic>?)
              ?.map((e) => BudgetItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      gallery: gallery,
    );
  }
}

/// A specific landmark photo in the destination gallery.
class DestinationLandmarkPhoto {
  final String title;
  final String imageUrl;

  const DestinationLandmarkPhoto({
    required this.title,
    required this.imageUrl,
  });

  factory DestinationLandmarkPhoto.fromJson(Map<String, dynamic> json) {
    return DestinationLandmarkPhoto(
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'imageUrl': imageUrl,
  };
}

/// A single line-item in the estimated budget breakdown.
class BudgetItem {
  final String label;
  final String amount;
  final double fraction;
  final String icon;

  const BudgetItem({
    required this.label,
    required this.amount,
    required this.fraction,
    required this.icon,
  });

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      label: json['label'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      fraction: (json['fraction'] as num?)?.toDouble() ?? 0.0,
      icon: json['icon'] as String? ?? 'circle',
    );
  }

  Map<String, dynamic> toMap() => {
    'label': label,
    'amount': amount,
    'fraction': fraction,
    'icon': icon,
  };
}
