class AssistantChatSession {
  final int id;
  final String title;
  final DateTime createdAt;
  final bool active;
  final String? lastMessagePreview;

  AssistantChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.active,
    this.lastMessagePreview,
  });

  factory AssistantChatSession.fromJson(Map<String, dynamic> json) {
    return AssistantChatSession(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'New chat',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      active: json['active'] as bool? ?? false,
      lastMessagePreview: json['lastMessagePreview'] as String?,
    );
  }
}
