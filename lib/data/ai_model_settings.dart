import 'package:hive/hive.dart';

/// Gemini models the user can pick in Profile. The first entry is the default.
///
/// Only names on this list are accepted, so a stale or mistyped value in
/// storage falls back to the default instead of breaking every AI call.
const List<AiModelOption> supportedAiModels = <AiModelOption>[
  AiModelOption(id: 'gemini-3.1-flash-lite', label: 'Gemini 3.1 Flash Lite'),
  AiModelOption(id: 'gemini-3.5-flash-lite', label: 'Gemini 3.5 Flash Lite'),
  AiModelOption(id: 'gemini-3.8-flash', label: 'Gemini 3.8 Flash'),
  AiModelOption(id: 'gemini-3.1-pro-preview', label: 'Gemini 3.1 Pro Preview'),
];

class AiModelOption {
  const AiModelOption({required this.id, required this.label});

  /// Model code sent to the Gemini API, for example `gemini-3.8-flash`.
  final String id;

  /// Human readable name shown in the picker.
  final String label;
}

/// Remembers which Gemini model the app calls.
///
/// Loaded once at startup. `GeminiService` reads [current] on every request
/// and `AiCacheService` mixes it into cache keys, so switching applies to the
/// next AI call and never returns a result produced by another model.
class AiModelSettings {
  AiModelSettings._();
  static final AiModelSettings instance = AiModelSettings._();

  static const String _boxName = 'app_settings';
  static const String _modelIdKey = 'ai_model_id';

  String current = supportedAiModels.first.id;

  Future<void> load() async {
    final box = await Hive.openBox<String>(_boxName);
    current = resolve(box.get(_modelIdKey));
  }

  Future<void> save(String id) async {
    current = resolve(id);
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_modelIdKey, current);
  }

  /// Returns [id] when it is a supported model, otherwise the default.
  static String resolve(String? id) {
    return supportedAiModels.any((model) => model.id == id)
        ? id!
        : supportedAiModels.first.id;
  }
}
