class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  /// 'user' o 'assistant'.
  final String role;
  final String content;

  bool get isUser => role == 'user';
}
