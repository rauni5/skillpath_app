enum ChatRole { user, assistant }

ChatRole chatRoleFromString(String? value) {
  switch (value) {
    case 'ASSISTANT':
      return ChatRole.assistant;
    case 'USER':
    default:
      return ChatRole.user;
  }
}

class ChatMessage {
  final int id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      role: chatRoleFromString(json['role'] as String?),
      content: json['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
