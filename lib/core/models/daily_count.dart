class DailyCount {
  final DateTime date;
  final int count;

  DailyCount({required this.date, required this.count});

  factory DailyCount.fromJson(Map<String, dynamic> json) {
    return DailyCount(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int? ?? 0,
    );
  }
}
