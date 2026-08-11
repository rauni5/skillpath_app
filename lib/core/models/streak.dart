class Streak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;

  Streak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
  });

  factory Streak.fromJson(Map<String, dynamic> json) {
    final rawDate = json['lastActivityDate'] as String?;
    return Streak(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastActivityDate: rawDate == null ? null : DateTime.tryParse(rawDate),
    );
  }
}
