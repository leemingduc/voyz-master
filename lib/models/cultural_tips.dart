/// Model for AI-generated cultural travel tips.
class CulturalTips {
  final String destinationName;
  final String imageUrl;
  final List<String> dos;
  final List<String> donts;
  final List<CulturalPhrase> phrases;
  final List<String> diningEtiquette;
  final List<String> sacredSites;
  final String generalAdvice;

  const CulturalTips({
    required this.destinationName,
    this.imageUrl = '',
    required this.dos,
    required this.donts,
    required this.phrases,
    required this.diningEtiquette,
    required this.sacredSites,
    this.generalAdvice = '',
  });

  factory CulturalTips.fromJson(Map<String, dynamic> json) {
    return CulturalTips(
      destinationName: json['destinationName'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      dos:
          (json['dos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      donts:
          (json['donts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      phrases:
          (json['phrases'] as List<dynamic>?)
              ?.map((e) => CulturalPhrase.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      diningEtiquette:
          (json['diningEtiquette'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sacredSites:
          (json['sacredSites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      generalAdvice: json['generalAdvice'] as String? ?? '',
    );
  }
}

/// A single phrase entry with native text, translation, and pronunciation.
class CulturalPhrase {
  final String native;
  final String translation;
  final String pronunciation;

  const CulturalPhrase({
    required this.native,
    required this.translation,
    this.pronunciation = '',
  });

  factory CulturalPhrase.fromJson(Map<String, dynamic> json) {
    return CulturalPhrase(
      native: json['native'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      pronunciation: json['pronunciation'] as String? ?? '',
    );
  }
}
