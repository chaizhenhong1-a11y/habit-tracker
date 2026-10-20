import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/widgets/life_ui.dart';
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
      ..addListener(_changed)
      ..load();
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    _controller
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  void _showHabitOptions(Habit h) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (s) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              title: Text(
                h.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l.translate('editHabit') ?? '编辑习惯'),
              onTap: () {
                Navigator.pop(s);
                _showHabitEditor(habit: h);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l.translate('deleteHabit') ?? '删除习惯'),
              onTap: () {
                Navigator.pop(s);
                _confirmDelete(h);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHabitEditor({Habit? habit}) async {
    final l = AppLocalizations.of(context);
    final name = TextEditingController();
    final target = TextEditingController(
      text: habit?.isQuantity == true ? _num(habit!.effectiveTargetValue) : '1',
    );
    final unit = TextEditingController(text: habit?.unit ?? '');
    var emoji = '✅';
    var type = habit?.type ?? 'good';
    var mode = habit?.trackingMode ?? HabitTrackingMode.binary;
    var days = Set<int>.from(
      habit?.scheduledWeekdays ?? const [1, 2, 3, 4, 5, 6, 7],
    );
    if (habit != null) {
      var raw = habit.name;
      for (final e in _emojiList) {
        if (raw.startsWith(e)) {
          emoji = e;
          raw = raw.substring(e.length).trim();
          break;
        }
      }
      name.text = raw;
    }
    await showDialog<void>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (context, setD) {
          final labels = _weekdayLabels(context);
          return AlertDialog(
            title: Text(
              habit == null
                  ? (l.translate('addHabit') ?? '新建习惯')
                  : (l.translate('editHabit') ?? '编辑习惯'),
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'good',
                          label: Text(l.translate('goodHabit') ?? '好习惯'),
                        ),
                        ButtonSegment(
                          value: 'bad',
                          label: Text(l.translate('badHabit') ?? '坏习惯'),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: (v) => setD(() => type = v.first),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final e in _emojiList)
                          ChoiceChip(
                            label: Text(e),
                            selected: emoji == e,
                            onSelected: (_) => setD(() => emoji = e),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: name,
                      decoration: InputDecoration(
                        labelText: l.translate('habitNameHint') ?? '习惯名称',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<HabitTrackingMode>(
                      segments: [
                        ButtonSegment(
                          value: HabitTrackingMode.binary,
                          label: Text(
                            l.translate('binaryTracking') ?? '完成 / 未完成',
                          ),
                        ),
                        ButtonSegment(
                          value: HabitTrackingMode.quantity,
                          label: Text(
                            l.translate('quantityTracking') ?? '数值目标',
                          ),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (v) => setD(() => mode = v.first),
                    ),
                    if (mode == HabitTrackingMode.quantity) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: target,
                              decoration: InputDecoration(
                                labelText: l.translate('dailyTarget') ?? '每日目标',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: unit,
                              decoration: InputDecoration(
                                labelText: l.translate('unit') ?? '单位',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (var day = 1; day <= 7; day++)
                          FilterChip(
                            label: Text(labels[day - 1]),
                            selected: days.contains(day),
                            onSelected: (v) => setD(() {
                              if (v) {
                                days.add(day);
                              } else if (days.length > 1) {
                                days.remove(day);
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d),
                child: Text(l.translate('cancel') ?? '取消'),
              ),
              FilledButton(
                onPressed: () {
                  final text = name.text.trim();
                  final value = mode == HabitTrackingMode.quantity
                      ? double.tryParse(target.text.trim())
                      : 1.0;
                  if (text.isEmpty || value == null || value <= 0) return;
                  if (habit == null) {
                    _controller.add(
                      Habit(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: '$emoji $text',
                        completedDates: const [],
                        type: type,
                        trackingMode: mode,
                        targetValue: value,
                        unit: unit.text.trim(),
                        scheduledWeekdays: days.toList(),
                      ),
                    );
                  } else {
                    habit
                      ..name = '$emoji $text'
                      ..type = type
                      ..trackingMode = mode
                      ..targetValue = value
                      ..unit = unit.text.trim()
                      ..scheduledWeekdays = (days.toList()..sort());
                    _controller.update(habit);
                  }
                  Navigator.pop(d);
                },
                child: Text(l.translate('save') ?? '保存'),
              ),
            ],
          );
        },
      ),
    );
    name.dispose();
    target.dispose();
    unit.dispose();
  }

  List<String> _weekdayLabels(BuildContext c) {
    final l = AppLocalizations.of(c);
    return [
      l.translate('mondayShort') ?? 'Mon',
      l.translate('tuesdayShort') ?? 'Tue',
      l.translate('wednesdayShort') ?? 'Wed',
      l.translate('thursdayShort') ?? 'Thu',
      l.translate('fridayShort') ?? 'Fri',
      l.translate('saturdayShort') ?? 'Sat',
      l.translate('sundayShort') ?? 'Sun',
    ];
  }

  void _confirmDelete(Habit h) {
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.translate('deleteConfirm') ?? '删除确认'),
        content: Text(h.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: Text(l.translate('cancel') ?? '取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(d);
              _delete(h);
            },
            child: Text(l.translate('delete') ?? '删除'),
          ),
        ],
      ),
    );
  }

  void _delete(Habit h) {
    final i = _controller.habits.indexWhere((x) => x.id == h.id);
    if (i < 0) return;
    _pendingDeletes.insert(0, _PendingDelete(habit: h, index: i));
    _controller.deleteById(h.id);
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l.translate('deleted') ?? '已删除'}「${h.name}」'),
        action: SnackBarAction(
          label: l.translate('undo') ?? '撤销',
          onPressed: _undo,
        ),
      ),
    );
    _clearTimer?.cancel();
    _clearTimer = Timer(
      const Duration(seconds: 5),
      () => _pendingDeletes.clear(),
    );
  }

  void _undo() {
    if (_pendingDeletes.isEmpty) return;
    final p = _pendingDeletes.removeAt(0);
    final all = _controller.habits.toList();
    all.insert(p.index.clamp(0, all.length), p.habit);
    _controller.replaceAll(all);
  }

  void _reorder(List<Habit> group, int oldIndex, int newIndex) {
    final r = List<Habit>.from(group);
    final item = r.removeAt(oldIndex);
    r.insert(newIndex, item);
    final full = _controller.habits.toList();
    final ids = group.map((e) => e.id).toSet();
    final pos = <int>[
      for (var i = 0; i < full.length; i++)
        if (ids.contains(full[i].id)) i,
    ];
    for (var i = 0; i < pos.length; i++) {
      full[pos[i]] = r[i];
    }
    _controller.replaceAll(full);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final all = _controller.habits;
    final today = all.where(_controller.isScheduledToday).toList();
    final done = today.where(_controller.isCompletedToday).length;
    final ratio = today.isEmpty ? 0.0 : done / today.length;
    var streak = 0;
    for (final h in today) {
      final s = _controller.streakStats(h).currentStreak;
      if (s > streak) streak = s;
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              sliver: SliverToBoxAdapter(
                child: LifePageHeader(
                  eyebrow: DateFormat(
                    Localizations.localeOf(context).languageCode == 'zh'
                        ? 'M月d日 EEEE'
                        : 'EEEE · MMMM d',
                    Localizations.localeOf(context).toString(),
                  ).format(DateTime.now()),
                  title: _greeting(),
                  subtitle: AppLocalizations.of(context).text('todayIntro'),
                  trailing: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF194B36),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFFF4E8C9),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _TodayHero(
                  done: done,
                  total: today.length,
                  ratio: ratio,
                  streak: streak,
                ),
              ),
            ),
            if (all.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Empty(onAdd: () => _showHabitEditor()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 130),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    LifeSectionTitle(
                      title: AppLocalizations.of(context).text('todayFocus'),
                      caption: AppLocalizations.of(
                        context,
                      ).text('smallActions'),
                      action: TextButton.icon(
                        onPressed: () => _showHabitEditor(),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l.translate('addHabit') ?? 'Add'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _group(
                      _controller.goodHabits,
                      AppLocalizations.of(context).text('buildHabits'),
                      Icons.spa_rounded,
                      const Color(0xFF315C43),
                    ),
                    _group(
                      _controller.badHabits,
                      AppLocalizations.of(context).text('protectHabits'),
                      Icons.shield_outlined,
                      const Color(0xFFB07858),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return AppLocalizations.of(context).text('morningGreeting');
    if (h < 18) return AppLocalizations.of(context).text('afternoonGreeting');
    return AppLocalizations.of(context).text('eveningGreeting');
  }

  Widget _group(List<Habit> habits, String title, IconData icon, Color color) {
    if (habits.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text('${habits.length}'),
            ],
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: habits.length,
          onReorderItem: (a, b) => _reorder(habits, a, b),
          itemBuilder: (context, index) {
            final h = habits[index];
            return Padding(
              key: ValueKey(h.id),
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  Expanded(
                    child: _HabitCard(
                      habit: h,
                      done: _controller.isCompletedToday(h),
                      scheduled: _controller.isScheduledToday(h),
                      progress: _controller.progressToday(h),
                      streakStats: _controller.streakStats(h),
                      onToggle: () => _controller.toggleToday(h),
                      onIncrement: () => _controller.incrementToday(h),
                      onDecrement: () => _controller.decrementToday(h),
                      onLongPress: () => _showHabitOptions(h),
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.drag_indicator_rounded, size: 20),
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
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.done,
    required this.total,
    required this.ratio,
    required this.streak,
  });
  final int done, total, streak;
  final double ratio;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF173F2D), Color(0xFF315D43)],
      ),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).text('todayLabel'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                      color: Colors.white.withValues(alpha: .65),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).text('todayCompleted', {'done': done, 'total': total}),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 27,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            _Ring(value: ratio),
          ],
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: ratio,
          minHeight: 7,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation(Color(0xFFE2C58A)),
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).text('todayStreak', {
            'days': streak,
            'percent': (ratio * 100).round(),
          }),
          style: const TextStyle(
            color: Color(0xFFF4E8C9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 58,
    height: 58,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 5,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFE2C58A)),
          ),
        ),
        Text(
          '${(value * 100).round()}%',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.add_rounded),
      label: Text(AppLocalizations.of(context).text('firstHabit')),
    ),
  );
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
  final bool done, scheduled;
  final double progress;
  final HabitStreakStats streakStats;
  final VoidCallback onToggle, onIncrement, onDecrement, onLongPress;
  String _n(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  @override
  Widget build(BuildContext context) {
    final active = habit.isBad
        ? const Color(0xFFB07858)
        : const Color(0xFF315D43);
    return Card(
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!scheduled)
                      Text(
                        AppLocalizations.of(context).text('restDay'),
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else if (habit.isQuantity)
                      Text(
                        '${_n(progress)} / ${_n(habit.effectiveTargetValue)}${habit.unit.isEmpty ? '' : ' ${habit.unit}'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else if (streakStats.currentStreak > 0)
                      Text(
                        AppLocalizations.of(context).text('habitStreak', {
                          'days': streakStats.currentStreak,
                        }),
                        style: TextStyle(color: active, fontSize: 12),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined, size: 17),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => HabitCalendarPage(habit: habit),
                  ),
                ),
              ),
              if (habit.isQuantity) ...[
                IconButton(
                  onPressed: scheduled && progress > 0 ? onDecrement : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                IconButton(
                  onPressed: scheduled ? onIncrement : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ] else
                IconButton(
                  onPressed: scheduled ? onToggle : null,
                  icon: Icon(
                    done ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: done ? active : null,
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
