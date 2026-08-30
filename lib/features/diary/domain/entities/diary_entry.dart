class DiaryEntry {
  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.mood = 'happy',
    this.imagePath,
  });

  final String id;
  String title;
  String content;
  DateTime date;
  String mood;
  String? imagePath;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
    'mood': mood,
    'imagePath': imagePath,
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      date: DateTime.parse(json['date'] as String),
      mood: json['mood'] as String? ?? 'happy',
      imagePath: json['imagePath'] as String?,
    );
  }
}
