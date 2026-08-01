/// Model for AI-generated best time to travel analysis.
class BestTimeTravel {
  final String destination;
  final String summary;
  final List<MonthInfo> monthlyData;
  final String bestMonth;
  final List<TravelTip> tips;
  final List<SeasonInfo> seasons;

  const BestTimeTravel({
    required this.destination,
    required this.summary,
    required this.monthlyData,
    required this.bestMonth,
    required this.tips,
    required this.seasons,
  });

  factory BestTimeTravel.fromJson(Map<String, dynamic> json) {
    return BestTimeTravel(
      destination: json['destination'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      monthlyData:
          (json['monthlyData'] as List<dynamic>?)
              ?.map((e) => MonthInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bestMonth: json['bestMonth'] as String? ?? '',
      tips:
          (json['tips'] as List<dynamic>?)
              ?.map((e) => TravelTip.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      seasons:
          (json['seasons'] as List<dynamic>?)
              ?.map((e) => SeasonInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Per-month travel recommendation data.
class MonthInfo {
  final String month;
  final String temperature;
  final String rainfall;
  final int suitabilityScore;
  final String highlight;

  const MonthInfo({
    required this.month,
    required this.temperature,
    required this.rainfall,
    required this.suitabilityScore,
    required this.highlight,
  });

  factory MonthInfo.fromJson(Map<String, dynamic> json) {
    return MonthInfo(
      month: json['month'] as String? ?? '',
      temperature: json['temperature'] as String? ?? '',
      rainfall: json['rainfall'] as String? ?? '',
      suitabilityScore: (json['suitabilityScore'] as num?)?.toInt() ?? 0,
      highlight: json['highlight'] as String? ?? '',
    );
  }
}

/// A practical travel tip for the destination.
class TravelTip {
  final String icon;
  final String title;
  final String description;

  const TravelTip({
    required this.icon,
    required this.title,
    required this.description,
  });

  factory TravelTip.fromJson(Map<String, dynamic> json) {
    return TravelTip(
      icon: json['icon'] as String? ?? 'lightbulb',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// Seasonal travel information.
class SeasonInfo {
  final String name;
  final String period;
  final String description;
  final int rating;

  const SeasonInfo({
    required this.name,
    required this.period,
    required this.description,
    required this.rating,
  });

  factory SeasonInfo.fromJson(Map<String, dynamic> json) {
    return SeasonInfo(
      name: json['name'] as String? ?? '',
      period: json['period'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
    );
  }
}
