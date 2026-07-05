import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuración del asistente de IA. El usuario pega su propia API key
/// (compatible con la API de OpenAI / chat completions); nada de esto se
/// commitea al repo, solo vive en SharedPreferences del dispositivo.
class AiSettings {
  const AiSettings({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  final String apiKey;
  final String baseUrl;
  final String model;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  AiSettings copyWith({String? apiKey, String? baseUrl, String? model}) {
    return AiSettings(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
    );
  }

  static const defaultBaseUrl = 'https://api.openai.com/v1';
  static const defaultModel = 'gpt-4o-mini';
}

const _keyApiKey = 'ai_api_key';
const _keyBaseUrl = 'ai_base_url';
const _keyModel = 'ai_model';

class AiSettingsController extends Notifier<AiSettings> {
  @override
  AiSettings build() {
    _loadSaved();
    return const AiSettings(
      apiKey: '',
      baseUrl: AiSettings.defaultBaseUrl,
      model: AiSettings.defaultModel,
    );
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    state = AiSettings(
      apiKey: prefs.getString(_keyApiKey) ?? '',
      baseUrl: prefs.getString(_keyBaseUrl) ?? AiSettings.defaultBaseUrl,
      model: prefs.getString(_keyModel) ?? AiSettings.defaultModel,
    );
  }

  Future<void> save({
    required String apiKey,
    String? baseUrl,
    String? model,
  }) async {
    final next = state.copyWith(
      apiKey: apiKey,
      baseUrl: (baseUrl == null || baseUrl.trim().isEmpty)
          ? AiSettings.defaultBaseUrl
          : baseUrl,
      model: (model == null || model.trim().isEmpty)
          ? AiSettings.defaultModel
          : model,
    );
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, next.apiKey);
    await prefs.setString(_keyBaseUrl, next.baseUrl);
    await prefs.setString(_keyModel, next.model);
  }

  Future<void> clearApiKey() async {
    state = state.copyWith(apiKey: '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiKey);
  }
}

final aiSettingsProvider = NotifierProvider<AiSettingsController, AiSettings>(
  AiSettingsController.new,
);
