/// Model for AI-generated destination comparison.
class DestinationComparison {
  final List<ComparedDestination> destinations;
  final String recommendation;
  final List<ComparisonAspect> aspects;

  const DestinationComparison({
    required this.destinations,
    required this.recommendation,
    required this.aspects,
  });

  factory DestinationComparison.fromJson(Map<String, dynamic> json) {
    return DestinationComparison(
      destinations:
          (json['destinations'] as List<dynamic>?)
              ?.map(
                (e) => ComparedDestination.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      recommendation: json['recommendation'] as String? ?? '',
      aspects:
          (json['aspects'] as List<dynamic>?)
              ?.map((e) => ComparisonAspect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// A single destination within a comparison.
class ComparedDestination {
  final String name;
  final String summary;
  final double overallScore;
  final List<String> pros;
  final List<String> cons;

  const ComparedDestination({
    required this.name,
    required this.summary,
    required this.overallScore,
    required this.pros,
    required this.cons,
  });

  factory ComparedDestination.fromJson(Map<String, dynamic> json) {
    return ComparedDestination(
      name: json['name'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
      pros:
          (json['pros'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      cons:
          (json['cons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }
}

/// A single aspect of comparison (e.g., cost, weather, activities).
class ComparisonAspect {
  final String label;
  final String icon;
  final List<AspectDetail> details;

  const ComparisonAspect({
    required this.label,
    required this.icon,
    required this.details,
  });

  factory ComparisonAspect.fromJson(Map<String, dynamic> json) {
    return ComparisonAspect(
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? 'compare',
      details:
          (json['details'] as List<dynamic>?)
              ?.map((e) => AspectDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Per-destination detail for a specific comparison aspect.
class AspectDetail {
  final String destination;
  final String value;
  final int score;

  const AspectDetail({
    required this.destination,
    required this.value,
    required this.score,
  });

  factory AspectDetail.fromJson(Map<String, dynamic> json) {
    return AspectDetail(
      destination: json['destination'] as String? ?? '',
      value: json['value'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }
}
