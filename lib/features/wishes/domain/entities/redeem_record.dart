class RedeemRecord {
  const RedeemRecord({
    required this.rewardName,
    required this.emoji,
    required this.cost,
    required this.time,
  });

  final String rewardName;
  final String emoji;
  final int cost;
  final DateTime time;

  Map<String, dynamic> toJson() => {
    'rewardName': rewardName,
    'emoji': emoji,
    'cost': cost,
    'time': time.toIso8601String(),
  };

  factory RedeemRecord.fromJson(Map<String, dynamic> json) {
    return RedeemRecord(
      rewardName: json['rewardName'] as String,
      emoji: json['emoji'] as String,
      cost: json['cost'] as int,
      time: DateTime.parse(json['time'] as String),
    );
  }
}
