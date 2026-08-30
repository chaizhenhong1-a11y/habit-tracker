enum HabitTrackingMode {
  binary,
  quantity;

  String get storageValue => name;

  static HabitTrackingMode fromStorage(Object? value) {
    return HabitTrackingMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => HabitTrackingMode.binary,
    );
  }
}

class Habit {
  Habit({
    required this.id,
    required this.name,
    required List<String> completedDates,
    this.type = 'good',
    this.trackingMode = HabitTrackingMode.binary,
    this.targetValue = 1,
    this.unit = '',
    List<int>? scheduledWeekdays,
    Map<String, double>? progressByDate,
  }) : completedDates = List<String>.from(completedDates),
       scheduledWeekdays = _normalizeWeekdays(scheduledWeekdays),
       progressByDate = Map<String, double>.from(progressByDate ?? const {});

  final String id;
  String name;
  List<String> completedDates;
  String type;
  HabitTrackingMode trackingMode;
  double targetValue;
  String unit;
  List<int> scheduledWeekdays;
  Map<String, double> progressByDate;

  bool get isGood => type == 'good';
  bool get isBad => type == 'bad';
  bool get isQuantity => trackingMode == HabitTrackingMode.quantity;

  bool isScheduledOn(DateTime date) => scheduledWeekdays.contains(date.weekday);

  bool isCompletedOn(String dateKey) => completedDates.contains(dateKey);

  double progressOn(String dateKey) {
    if (trackingMode == HabitTrackingMode.binary) {
      return isCompletedOn(dateKey) ? 1 : 0;
    }
    return progressByDate[dateKey] ?? 0;
  }

  double progressRatioOn(String dateKey) {
    final target = effectiveTargetValue;
    return (progressOn(dateKey) / target).clamp(0.0, 1.0);
  }

  double get effectiveTargetValue => targetValue > 0 ? targetValue : 1;

  void setCompletedOn(String dateKey, {required bool completed}) {
    if (completed) {
      if (!completedDates.contains(dateKey)) {
        completedDates.add(dateKey);
      }
      if (trackingMode == HabitTrackingMode.quantity) {
        progressByDate[dateKey] = effectiveTargetValue;
      }
      return;
    }

    completedDates.remove(dateKey);
    if (trackingMode == HabitTrackingMode.quantity) {
      progressByDate.remove(dateKey);
    }
  }

  void setProgressOn(String dateKey, double value) {
    final normalized = value < 0 ? 0.0 : value;

    if (trackingMode == HabitTrackingMode.binary) {
      setCompletedOn(dateKey, completed: normalized >= 1);
      return;
    }

    if (normalized == 0) {
      progressByDate.remove(dateKey);
    } else {
      progressByDate[dateKey] = normalized;
    }

    final completed = normalized >= effectiveTargetValue;
    if (completed && !completedDates.contains(dateKey)) {
      completedDates.add(dateKey);
    } else if (!completed) {
      completedDates.remove(dateKey);
    }
  }

  Habit copyWith({
    String? id,
    String? name,
    List<String>? completedDates,
    String? type,
    HabitTrackingMode? trackingMode,
    double? targetValue,
    String? unit,
    List<int>? scheduledWeekdays,
    Map<String, double>? progressByDate,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      completedDates: completedDates ?? this.completedDates,
      type: type ?? this.type,
      trackingMode: trackingMode ?? this.trackingMode,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      scheduledWeekdays: scheduledWeekdays ?? this.scheduledWeekdays,
      progressByDate: progressByDate ?? this.progressByDate,
    );
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    final rawProgress = map['progressByDate'];
    final progress = <String, double>{};
    if (rawProgress is Map) {
      for (final entry in rawProgress.entries) {
        final value = entry.value;
        if (value is num) {
          progress[entry.key.toString()] = value.toDouble();
        }
      }
    }

    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      completedDates: List<String>.from(map['completedDates'] ?? const []),
      type: map['type'] as String? ?? 'good',
      trackingMode: HabitTrackingMode.fromStorage(map['trackingMode']),
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 1,
      unit: map['unit'] as String? ?? '',
      scheduledWeekdays: (map['scheduledWeekdays'] as List?)
          ?.whereType<num>()
          .map((value) => value.toInt())
          .toList(),
      progressByDate: progress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'completedDates': List<String>.from(completedDates),
      'type': type,
      'trackingMode': trackingMode.storageValue,
      'targetValue': effectiveTargetValue,
      'unit': unit,
      'scheduledWeekdays': List<int>.from(scheduledWeekdays),
      'progressByDate': Map<String, double>.from(progressByDate),
    };
  }

  static List<int> _normalizeWeekdays(List<int>? values) {
    if (values == null || values.isEmpty) {
      return const [1, 2, 3, 4, 5, 6, 7];
    }
    final result = values.where((day) => day >= 1 && day <= 7).toSet().toList()
      ..sort();
    return result.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : result;
  }
}
