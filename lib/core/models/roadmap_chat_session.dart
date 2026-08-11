class RoadmapChatSession {
  final int id;
  final String title;
  final DateTime createdAt;

  /// True only for the single most-recent session — the only one that
  /// still accepts new messages. Older sessions are read-only history.
  final bool active;
  final String? lastMessagePreview;

  RoadmapChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.active,
    this.lastMessagePreview,
  });

  factory RoadmapChatSession.fromJson(Map<String, dynamic> json) {
    return RoadmapChatSession(
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