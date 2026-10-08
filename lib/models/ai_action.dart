enum AiActionType {
  navigateDestination,
  navigateScreen,
  setTripData;

  static AiActionType fromString(String? value) {
    switch (value) {
      case 'navigateDestination':
        return AiActionType.navigateDestination;
      case 'setTripData':
        return AiActionType.setTripData;
      case 'navigateScreen':
      default:
        return AiActionType.navigateScreen;
    }
  }

  String toFormattedString() {
    switch (this) {
      case AiActionType.navigateDestination:
        return 'navigateDestination';
      case AiActionType.setTripData:
        return 'setTripData';
      case AiActionType.navigateScreen:
        return 'navigateScreen';
    }
  }
}

class AiAction {
  final AiActionType type;
  final String target;
  final String label;
  final Map<String, dynamic>? parameters;

  const AiAction({
    required this.type,
    required this.target,
    required this.label,
    this.parameters,
  });

  factory AiAction.fromJson(Map<String, dynamic> json) {
    return AiAction(
      type: AiActionType.fromString(json['type']?.toString()),
      target: json['target']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      parameters: json['parameters'] is Map<String, dynamic>
          ? json['parameters'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.toFormattedString(),
        'target': target,
        'label': label,
        if (parameters != null) 'parameters': parameters,
      };
}
