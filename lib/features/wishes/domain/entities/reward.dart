class Reward {
  const Reward({required this.name, required this.emoji, required this.cost});

  final String name;
  final String emoji;
  final int cost;

  Map<String, dynamic> toJson() => {'name': name, 'emoji': emoji, 'cost': cost};

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      cost: json['cost'] as int,
    );
  }
}
