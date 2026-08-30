import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/habit_controller.dart';
import '../../data/repositories/hive_habit_repository.dart';
import '../../domain/entities/habit.dart';
import '../../domain/services/habit_streak_calculator.dart';
import 'habit_calendar_page.dart';

class HabitListPage extends StatefulWidget {
  const HabitListPage({super.key});

  @override
  State<HabitListPage> createState() => _HabitListPageState();
}

class _HabitListPageState extends State<HabitListPage> {
  late final HabitController _controller;

  final List<_PendingDelete> _pendingDeletes = [];
  Timer? _clearTimer;

  static const _emojiList = <String>[
    '✅',
    '📚',
    '🏃',
    '💧',
    '🧘',
    '🎸',
    '💤',
    '🍎',
    '✍️',
    '🧹',
  ];

  @override
  void initState() {
    super.initState();
    _controller = HabitController(HiveHabitRepository.fromHabitsBox())
      ..addListener(_onControllerChanged)
      ..load();
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleHabit(Habit habit) {
    _controller.toggleToday(habit);
  }

  void _showHabitOptions(Habit habit) {
    final loc = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                habit.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(loc.translate('editHabit') ?? '编辑习惯'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showHabitEditor(habit: habit);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: Text(
                  loc.translate('deleteHabit') ?? '删除习惯',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(habit);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showHabitEditor({Habit? habit}) async {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final targetController = TextEditingController(
      text: habit?.isQuantity == true
          ? _formatNumber(habit!.effectiveTargetValue)
          : '1',
    );
    final unitController = TextEditingController(text: habit?.unit ?? '');

    var selectedEmoji = '✅';
    var selectedType = habit?.type ?? 'good';
    var trackingMode = habit?.trackingMode ?? HabitTrackingMode.binary;
    var weekdays = Set<int>.from(
      habit?.scheduledWeekdays ?? const [1, 2, 3, 4, 5, 6, 7],
    );

    if (habit != null) {
      var rawName = habit.name;
      for (final emoji in _emojiList) {
        if (rawName.startsWith(emoji)) {
          selectedEmoji = emoji;
          rawName = rawName.substring(emoji.length).trim();
          break;
        }
      }
      nameController.text = rawName;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colorScheme = Theme.of(context).colorScheme;
            final weekdayLabels = _weekdayLabels(context);

            return AlertDialog(
              title: Text(
                habit == null
                    ? (loc.translate('addHabit') ?? '新建习惯')
                    : (loc.translate('editHabit') ?? '编辑习惯'),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'good',
                            label: Text(
                              '😇 ${loc.translate('goodHabit') ?? '好习惯'}',
                            ),
                          ),
                          ButtonSegment(
                            value: 'bad',
                            label: Text(
                              '😈 ${loc.translate('badHabit') ?? '坏习惯'}',
                            ),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (selection) {
                          setDialogState(() => selectedType = selection.first);
                        },
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final emoji in _emojiList)
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setDialogState(() => selectedEmoji = emoji);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selectedEmoji == emoji
                                      ? colorScheme.primary.withValues(
                                          alpha: 0.12,
                                        )
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.03,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedEmoji == emoji
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: loc.translate('habitNameHint') ?? '习惯名称',
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        loc.translate('trackingMode') ?? '记录方式',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<HabitTrackingMode>(
                        segments: [
                          ButtonSegment(
                            value: HabitTrackingMode.binary,
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                            label: Text(
                              loc.translate('binaryTracking') ?? '完成 / 未完成',
                            ),
                          ),
                          ButtonSegment(
                            value: HabitTrackingMode.quantity,
                            icon: const Icon(Icons.speed_rounded),
                            label: Text(
                              loc.translate('quantityTracking') ?? '数值目标',
                            ),
                          ),
                        ],
                        selected: {trackingMode},
                        onSelectionChanged: (selection) {
                          setDialogState(() => trackingMode = selection.first);
                        },
                      ),
                      if (trackingMode == HabitTrackingMode.quantity) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: targetController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText:
                                      loc.translate('dailyTarget') ?? '每日目标',
                                  hintText:
                                      loc.translate('dailyTargetHint') ??
                                      '例如 30',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: unitController,
                                decoration: InputDecoration(
                                  labelText: loc.translate('unit') ?? '单位',
                                  hintText:
                                      loc.translate('unitHint') ??
                                      '分钟 / 杯 / km',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        loc.translate('habitFrequency') ?? '执行日期',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var day = 1; day <= 7; day++)
                            FilterChip(
                              label: Text(weekdayLabels[day - 1]),
                              selected: weekdays.contains(day),
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    weekdays.add(day);
                                  } else if (weekdays.length > 1) {
                                    weekdays.remove(day);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(loc.translate('cancel') ?? '取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = nameController.text.trim();
                    if (text.isEmpty || weekdays.isEmpty) return;

                    final target = trackingMode == HabitTrackingMode.quantity
                        ? double.tryParse(targetController.text.trim())
                        : 1.0;
                    if (target == null || target <= 0) return;

                    if (habit == null) {
                      _controller.add(
                        Habit(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: '$selectedEmoji $text',
                          completedDates: const [],
                          type: selectedType,
                          trackingMode: trackingMode,
                          targetValue: target,
                          unit: unitController.text.trim(),
                          scheduledWeekdays: weekdays.toList(),
                        ),
                      );
                    } else {
                      habit
                        ..name = '$selectedEmoji $text'
                        ..type = selectedType
                        ..trackingMode = trackingMode
                        ..targetValue = target
                        ..unit = unitController.text.trim()
                        ..scheduledWeekdays = (weekdays.toList()..sort());

                      if (trackingMode == HabitTrackingMode.binary) {
                        habit.progressByDate.clear();
                      }
                      _controller.update(habit);
                    }

                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    habit == null
                        ? (loc.translate('add') ?? '添加')
                        : (loc.translate('save') ?? '保存'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    targetController.dispose();
    unitController.dispose();
  }

  List<String> _weekdayLabels(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return [
      loc.translate('mondayShort') ?? 'Mon',
      loc.translate('tuesdayShort') ?? 'Tue',
      loc.translate('wednesdayShort') ?? 'Wed',
      loc.translate('thursdayShort') ?? 'Thu',
      loc.translate('fridayShort') ?? 'Fri',
      loc.translate('saturdayShort') ?? 'Sat',
      loc.translate('sundayShort') ?? 'Sun',
    ];
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  void _confirmDelete(Habit habit) {
    final loc = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(loc.translate('deleteConfirm') ?? '删除确认'),
          content: Text(
            '${loc.translate('confirmDeleteHabit') ?? '确定将'}'
            '「${habit.name}」'
            '${loc.translate('permanentlyRemove') ?? '彻底移除吗？'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(loc.translate('cancel') ?? '取消'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteWithUndo(habit);
              },
              child: Text(loc.translate('delete') ?? '删除'),
            ),
          ],
        );
      },
    );
  }

  void _deleteWithUndo(Habit habit) {
    final index = _controller.habits.indexWhere(
      (candidate) => candidate.id == habit.id,
    );
    if (index < 0) return;

    _pendingDeletes.insert(0, _PendingDelete(habit: habit, index: index));

    _controller.deleteById(habit.id);
    _showUndoSnackBar(habit.name);
    _startClearTimer();
  }

  void _showUndoSnackBar(String name) {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          backgroundColor: const Color(0xFF2E2E3E),
          content: Text(
            '${loc.translate('deleted') ?? '已删除'}「$name」',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: loc.translate('undo') ?? '撤销',
            textColor: const Color(0xFF8E97FD),
            onPressed: _undoLastDelete,
          ),
        ),
      );
  }

  void _undoLastDelete() {
    if (_pendingDeletes.isEmpty) return;

    final pending = _pendingDeletes.removeAt(0);
    final habits = _controller.habits.toList();
    final index = pending.index.clamp(0, habits.length);

    habits.insert(index, pending.habit);
    _controller.replaceAll(habits);
  }

  void _startClearTimer() {
    _clearTimer?.cancel();
    _clearTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pendingDeletes.isEmpty) {
        timer.cancel();
        return;
      }
      _pendingDeletes.removeLast();
    });
  }

  void _reorderGroup(List<Habit> group, int oldIndex, int newIndex) {
    final reordered = List<Habit>.from(group);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    final full = _controller.habits.toList();
    final groupIds = group.map((habit) => habit.id).toSet();
    final positions = <int>[
      for (var i = 0; i < full.length; i++)
        if (groupIds.contains(full[i].id)) i,
    ];

    for (var i = 0; i < positions.length; i++) {
      full[positions[i]] = reordered[i];
    }

    _controller.replaceAll(full);
  }

  Widget _buildHabitGroup({
    required List<Habit> habits,
    required String title,
    required IconData icon,
    required Color badgeColor,
  }) {
    if (habits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: badgeColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${habits.length}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: habits.length,
          onReorderItem: (oldIndex, newIndex) {
            _reorderGroup(habits, oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final habit = habits[index];
            return Padding(
              key: ValueKey(habit.id),
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _HabitCard(
                      habit: habit,
                      done: _controller.isCompletedToday(habit),
                      scheduled: _controller.isScheduledToday(habit),
                      progress: _controller.progressToday(habit),
                      streakStats: _controller.streakStats(habit),
                      onToggle: () => _toggleHabit(habit),
                      onIncrement: () => _controller.incrementToday(habit),
                      onDecrement: () => _controller.decrementToday(habit),
                      onLongPress: () => _showHabitOptions(habit),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ReorderableDragStartListener(
                    index: index,
                    child: const SizedBox(
                      width: 40,
                      height: 48,
                      child: Center(
                        child: Icon(Icons.drag_indicator_rounded, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final habits = _controller.habits;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          if (habits.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.spa_outlined,
                        size: 64,
                        color: colorScheme.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      loc.translate('startMinimalLife') ?? '开启极简生活',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.translate('addFirstHabitHint') ??
                          '点击下方轻点创建\n让好习惯融入生活的呼吸',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHabitGroup(
                    habits: _controller.goodHabits,
                    title: loc.translate('goodProgress') ?? '好习惯进展',
                    icon: Icons.trending_up_rounded,
                    badgeColor: const Color(0xFF34C759),
                  ),
                  _buildHabitGroup(
                    habits: _controller.badHabits,
                    title: loc.translate('badRestraint') ?? '坏习惯克制',
                    icon: Icons.warning_amber_rounded,
                    badgeColor: const Color(0xFFFF3B30),
                  ),
                ]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHabitEditor(),
        icon: const Icon(Icons.add_rounded),
        label: Text(loc.translate('addHabit') ?? '新习惯'),
      ),
    );
  }

  Widget _buildAppBar() {
    final loc = AppLocalizations.of(context);

    return SliverAppBar.large(
      expandedHeight: 120,
      collapsedHeight: 64,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            title: Text(
              loc.translate('myHabits') ?? '我的习惯',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
              ),
            ),
            background: Container(
              color: Theme.of(
                context,
              ).scaffoldBackgroundColor.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.done,
    required this.scheduled,
    required this.progress,
    required this.streakStats,
    required this.onToggle,
    required this.onIncrement,
    required this.onDecrement,
    required this.onLongPress,
  });

  final Habit habit;
  final bool done;
  final bool scheduled;
  final double progress;
  final HabitStreakStats streakStats;
  final VoidCallback onToggle;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onLongPress;

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final isBad = habit.isBad;
    final activeColor = isBad ? const Color(0xFFFF453A) : colorScheme.primary;

    return Material(
      color: done ? activeColor.withValues(alpha: 0.06) : colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: done
                      ? activeColor
                      : scheduled
                      ? Colors.grey.shade300
                      : colorScheme.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done
                            ? colorScheme.onSurface.withValues(alpha: 0.35)
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (streakStats.currentStreak > 0) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 14,
                            color: activeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${loc.translate('streakDays') ?? 'Streak'} '
                            '${streakStats.currentStreak} '
                            '${loc.translate('daysUnit') ?? 'days'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: activeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (!scheduled)
                      Text(
                        loc.translate('notScheduledToday') ?? '今天不安排',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    else if (habit.isQuantity)
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: habit.progressRatioOn(
                                DateTime.now().toIso8601String().substring(
                                  0,
                                  10,
                                ),
                              ),
                              minHeight: 5,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatNumber(progress)} / '
                            '${_formatNumber(habit.effectiveTargetValue)}'
                            '${habit.unit.isEmpty ? '' : ' ${habit.unit}'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => HabitCalendarPage(habit: habit),
                    ),
                  );
                },
              ),
              if (habit.isQuantity)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: loc.translate('decreaseProgress') ?? '减少',
                      onPressed: scheduled && progress > 0 ? onDecrement : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: loc.translate('increaseProgress') ?? '增加',
                      onPressed: scheduled ? onIncrement : null,
                      icon: Icon(
                        done
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: done ? activeColor : null,
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: scheduled ? onToggle : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? activeColor : Colors.transparent,
                      border: Border.all(
                        color: done
                            ? activeColor
                            : colorScheme.onSurface.withValues(alpha: 0.15),
                        width: 2,
                      ),
                    ),
                    child: done
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingDelete {
  const _PendingDelete({required this.habit, required this.index});

  final Habit habit;
  final int index;
}
