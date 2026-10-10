enum AiActionType {
  navigateDestination,
  navigateScreen,
  setTripData,
  updateLanguage,
  updateDisplayName,
  updatePhoneNumber,
  saveDestination,
  setBackgroundMusic;

  static AiActionType fromString(String? value) {
    switch (value) {
      case 'navigateDestination':
        return AiActionType.navigateDestination;
      case 'setTripData':
        return AiActionType.setTripData;
      case 'navigateScreen':
        return AiActionType.navigateScreen;
      case 'updateLanguage':
        return AiActionType.updateLanguage;
      case 'updateDisplayName':
        return AiActionType.updateDisplayName;
      case 'updatePhoneNumber':
        return AiActionType.updatePhoneNumber;
      case 'saveDestination':
        return AiActionType.saveDestination;
      case 'setBackgroundMusic':
      case 'toggleBackgroundMusic':
        return AiActionType.setBackgroundMusic;
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
      case AiActionType.updateLanguage:
        return 'updateLanguage';
      case AiActionType.updateDisplayName:
        return 'updateDisplayName';
      case AiActionType.updatePhoneNumber:
        return 'updatePhoneNumber';
      case AiActionType.saveDestination:
        return 'saveDestination';
      case AiActionType.setBackgroundMusic:
        return 'setBackgroundMusic';
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

  /// Converts the chatbot music target to an explicit desired state.
  /// Unknown targets must not toggle playback, because that can invert intent.
  static bool? backgroundMusicEnabled(String target) {
    switch (target.trim().toLowerCase()) {
      case 'on':
      case 'play':
      case 'b\u1eadt':
      case 'bat':
        return true;
      case 'off':
      case 'pause':
      case 'stop':
      case 't\u1eaft':
      case 'tat':
        return false;
      default:
        return null;
    }
  }

  /// Recognises explicit background-music requests without relying on AI JSON.
  static AiAction? backgroundMusicActionForPrompt(String prompt) {
    final text = prompt.trim().toLowerCase();
    final mentionsMusic =
        text.contains('nh\u1ea1c') || text.contains('background music');
    if (!mentionsMusic) return null;

    final turnOn =
        text.contains('b\u1eadt') ||
        text.contains('bat nhac') ||
        text.contains('turn on') ||
        text.contains('play music');
    final turnOff =
        text.contains('t\u1eaft') ||
        text.contains('tat nhac') ||
        text.contains('turn off') ||
        text.contains('stop music');
    if (turnOn == turnOff) return null;

    final enabled = turnOn;
    return AiAction(
      type: AiActionType.setBackgroundMusic,
      target: enabled ? 'on' : 'off',
      label: enabled ? 'Turn on background music' : 'Turn off background music',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.toFormattedString(),
    'target': target,
    'label': label,
    if (parameters != null) 'parameters': parameters,
  };
}
