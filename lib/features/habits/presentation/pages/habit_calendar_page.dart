import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/hive_habit_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/habit.dart';
import '../../domain/services/habit_progress_summarizer.dart';
import '../../domain/services/habit_streak_calculator.dart';

class HabitCalendarPage extends StatefulWidget {
  const HabitCalendarPage({super.key, required this.habit});

  final Habit habit;

  @override
  State<HabitCalendarPage> createState() => _HabitCalendarPageState();
}

class _HabitCalendarPageState extends State<HabitCalendarPage> {
  final _repository = HiveHabitRepository.fromHabitsBox();
  static const _streakCalculator = HabitStreakCalculator();
  static const _progressSummarizer = HabitProgressSummarizer();

  late DateTime _currentMonth;
  late List<String> _completedDates;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _completedDates = List<String>.from(widget.habit.completedDates);
  }

  Set<String> _completedDatesInMonth() {
    final prefix = DateFormat('yyyy-MM').format(_currentMonth);
    return _completedDates.where((date) => date.startsWith(prefix)).toSet();
  }

  List<DateTime?> _monthCells() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final leading = firstDay.weekday % 7;

    final cells = <DateTime?>[
      for (var i = 0; i < leading; i++) null,
      for (var day = 1; day <= lastDay.day; day++)
        DateTime(_currentMonth.year, _currentMonth.month, day),
    ];

    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
  }

  void _toggleDate(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);

    setState(() {
      if (_completedDates.contains(key)) {
        _completedDates.remove(key);
        widget.habit.setCompletedOn(key, completed: false);
      } else {
        _completedDates.add(key);
        widget.habit.setCompletedOn(key, completed: true);
      }
      _completedDates = List<String>.from(widget.habit.completedDates);
    });

    _repository.save(widget.habit);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);
    final completed = _completedDatesInMonth();
    final cells = _monthCells();
    final stats = _streakCalculator.calculate(widget.habit);
    final progressSummary = _progressSummarizer.summarize(widget.habit);
    final loc = AppLocalizations.of(context);
    final isZh = locale.languageCode == 'zh';

    final firstSunday = DateTime(2026, 6, 14);
    final weekDays = List.generate(
      7,
      (index) => DateFormat(
        'E',
        locale.toString(),
      ).format(firstSunday.add(Duration(days: index))),
    );

    final monthTitle = locale.languageCode == 'zh'
        ? DateFormat('yyyy年 M月').format(_currentMonth)
        : DateFormat('MMMM yyyy', locale.toString()).format(_currentMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit.name),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _TodayGoalCard(
              habit: widget.habit,
              summary: progressSummary,
              todayLabel:
                  loc.translate('todayProgress') ?? (isZh ? '今日进度' : 'Today'),
              completedLabel:
                  loc.translate('completed') ?? (isZh ? '已完成' : 'Completed'),
              notScheduledLabel:
                  loc.translate('notScheduledToday') ??
                  (isZh ? '今天无需执行' : 'Not scheduled today'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: _HabitStatsCard(
              currentStreak: stats.currentStreak,
              longestStreak: stats.longestStreak,
              completionRate: stats.completionRate,
              completedScheduledDays: stats.completedScheduledDays,
              completedThisWeek: stats.completedThisWeek,
              scheduledThisWeek: stats.scheduledThisWeek,
              currentStreakLabel:
                  loc.translate('streakDays') ?? (isZh ? '当前连续' : 'Streak'),
              longestStreakLabel: isZh ? '最长连续' : 'Longest Streak',
              completionRateLabel:
                  loc.translate('totalCompletionRate') ??
                  (isZh ? '总完成率' : 'Completion Rate'),
              totalPersistLabel:
                  loc.translate('totalPersist') ??
                  (isZh ? '累计坚持' : 'Total Completed'),
              weekCompletionLabel:
                  loc.translate('weekCompletion') ??
                  (isZh ? '本周完成' : 'This Week'),
              daysLabel: loc.translate('daysUnit') ?? (isZh ? '天' : 'days'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(monthTitle, style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final day in weekDays)
                  Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 7,
                children: [
                  for (final day in cells)
                    if (day == null)
                      const SizedBox.shrink()
                    else
                      _DayCell(
                        day: day,
                        completed: completed.contains(
                          DateFormat('yyyy-MM-dd').format(day),
                        ),
                        scheduled: widget.habit.isScheduledOn(day),
                        onTap: () => _toggleDate(day),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.completed,
    required this.scheduled,
    required this.onTap,
  });

  final DateTime day;
  final bool completed;
  final bool scheduled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final key = DateFormat('yyyy-MM-dd').format(day);
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = key == todayKey;

    return GestureDetector(
      onTap: scheduled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: completed
              ? colorScheme.primary.withValues(alpha: 0.3)
              : isToday
              ? colorScheme.secondaryContainer.withValues(alpha: 0.5)
              : scheduled
              ? null
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: !scheduled
                ? colorScheme.onSurface.withValues(alpha: 0.25)
                : completed
                ? colorScheme.primary
                : colorScheme.onSurface,
            fontWeight: completed || isToday ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}

class _HabitStatsCard extends StatelessWidget {
  const _HabitStatsCard({
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.completedScheduledDays,
    required this.completedThisWeek,
    required this.scheduledThisWeek,
    required this.currentStreakLabel,
    required this.longestStreakLabel,
    required this.completionRateLabel,
    required this.totalPersistLabel,
    required this.weekCompletionLabel,
    required this.daysLabel,
  });

  final int currentStreak;
  final int longestStreak;
  final double completionRate;
  final int completedScheduledDays;
  final int completedThisWeek;
  final int scheduledThisWeek;
  final String currentStreakLabel;
  final String longestStreakLabel;
  final String completionRateLabel;
  final String totalPersistLabel;
  final String weekCompletionLabel;
  final String daysLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = (completionRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_rounded,
                  label: currentStreakLabel,
                  value: '$currentStreak $daysLabel',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.emoji_events_rounded,
                  label: longestStreakLabel,
                  value: '$longestStreak $daysLabel',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: totalPersistLabel,
                  value: '$completedScheduledDays',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.date_range_rounded,
                  label: weekCompletionLabel,
                  value: '$completedThisWeek / $scheduledThisWeek',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  completionRateLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                '$percentage%',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completionRate.clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayGoalCard extends StatelessWidget {
  const _TodayGoalCard({
    required this.habit,
    required this.summary,
    required this.todayLabel,
    required this.completedLabel,
    required this.notScheduledLabel,
  });

  final Habit habit;
  final HabitProgressSummary summary;
  final String todayLabel;
  final String completedLabel;
  final String notScheduledLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final quantity = habit.trackingMode == HabitTrackingMode.quantity;
    final progressText = quantity
        ? '${_format(summary.todayProgress)} / '
                  '${_format(summary.todayTarget)} ${habit.unit}'
              .trim()
        : (summary.isCompletedToday ? completedLabel : '0 / 1');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                summary.isCompletedToday
                    ? Icons.check_circle_rounded
                    : Icons.track_changes_rounded,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  todayLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (summary.isCompletedToday)
                Text(
                  completedLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!summary.isScheduledToday)
            Text(
              notScheduledLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: summary.todayProgressRatio,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  progressText,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _format(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
