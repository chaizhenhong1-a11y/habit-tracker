class Habit {
  final String id;
  String name;
  List<String> completedDates;
  String type; // 'good' 或 'bad'

  Habit({
    required this.id,
    required this.name,
    required this.completedDates,
    this.type = 'good', // 默认好习惯
  });

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      completedDates: List<String>.from(map['completedDates'] ?? []),
      type: map['type'] as String? ?? 'good',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'completedDates': completedDates,
      'type': type,
    };
  }
}