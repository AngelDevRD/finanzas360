import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'ai_settings.dart';
import 'chat_message.dart';

class AiChatException implements Exception {
  AiChatException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Cliente de chat compatible con la API de "chat completions" estilo
/// OpenAI. Cualquier proveedor compatible (OpenAI, Groq, OpenRouter,
/// Together, un proxy propio, etc.) funciona solo cambiando `baseUrl` y
/// `model` en Ajustes — no hay nada específico de un proveedor en el código.
class AiChatRepository {
  Future<String> send({
    required AiSettings settings,
    required String systemPrompt,
    required List<ChatMessage> history,
  }) async {
    if (!settings.isConfigured) {
      throw AiChatException(
        'Configura tu API key en el asistente antes de chatear.',
      );
    }

    final uri = Uri.parse('${settings.baseUrl}/chat/completions');
    final body = jsonEncode({
      'model': settings.model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        for (final m in history) {'role': m.role, 'content': m.content},
      ],
    });

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${settings.apiKey}',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw AiChatException('No se pudo conectar con el asistente: $e');
    }

    if (response.statusCode != 200) {
      final snippet = response.body.length > 300
          ? response.body.substring(0, 300)
          : response.body;
      throw AiChatException(
        'El asistente respondió con error ${response.statusCode}: $snippet',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    final content = choices != null && choices.isNotEmpty
        ? (choices.first['message']?['content'] as String?)
        : null;
    if (content == null || content.trim().isEmpty) {
      throw AiChatException('El asistente no devolvió una respuesta válida.');
    }
    return content.trim();
  }
}

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  return AiChatRepository();
});
