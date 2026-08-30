class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.titleKey,
    required this.target,
  });

  final String id;
  final String titleKey;
  final int target;
}

class AchievementProgress {
  const AchievementProgress({
    required this.definition,
    required this.currentValue,
  });

  final AchievementDefinition definition;
  final int currentValue;

  bool get isUnlocked => currentValue >= definition.target;

  double get progressRatio {
    if (definition.target <= 0) return 1;
    return (currentValue / definition.target).clamp(0.0, 1.0);
  }
}
