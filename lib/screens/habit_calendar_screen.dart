import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

class HabitCalendarScreen extends StatefulWidget {
  final Habit habit;
  const HabitCalendarScreen({super.key, required this.habit});

  @override
  State<HabitCalendarScreen> createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  final HabitService _habitService = HabitService();
  late DateTime _currentMonth;
  late List<String> _completedDates;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _completedDates = List<String>.from(widget.habit.completedDates);
  }

  Set<String> _completedDatesInMonth() {
    final yearMonth = DateFormat('yyyy-MM').format(_currentMonth);
    return _completedDates.where((dateStr) => dateStr.startsWith(yearMonth)).toSet();
  }

  List<DateTime?> _generateMonthDays() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7;
    final List<DateTime?> days = [];
    for (int i = 0; i < firstWeekday; i++) {
      days.add(null);
    }
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }
    while (days.length % 7 != 0) {
      days.add(null);
    }
    return days;
  }

  void _previousMonth() => setState(() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
  });
  void _nextMonth() => setState(() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
  });

  void _toggleDate(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    setState(() {
      if (_completedDates.contains(dateStr)) {
        _completedDates.remove(dateStr);
      } else {
        _completedDates.add(dateStr);
      }
    });
    widget.habit.completedDates = List<String>.from(_completedDates);
    _habitService.updateHabit(widget.habit);
  }

  @override
  Widget build(BuildContext context) {
    final completedSet = _completedDatesInMonth();
    final days = _generateMonthDays();
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    // 动态生成星期标题（短格式，例如 "一" 或 "Mon"）
    // 使用一个参考日期（比如某个星期天）来获取所有星期几的名称
    final firstDayOfWeek = DateTime(2026, 6, 14); // 2026-06-14 是星期日
    final weekDays = List.generate(7, (index) {
      final date = firstDayOfWeek.add(Duration(days: index));
      return DateFormat('E', locale.toString()).format(date);
    });

    // 月份标题，使用当前 locale 格式化
    String monthTitle;
    if (locale.languageCode == 'zh') {
      monthTitle = DateFormat('yyyy年 M月').format(_currentMonth);
    } else {
      monthTitle = DateFormat('MMMM yyyy', locale.toString()).format(_currentMonth);
    }

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
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: _previousMonth),
                Text(
                  monthTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: weekDays.map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 7,
                children: days.map((day) {
                  if (day == null) return const SizedBox.shrink();
                  final dateStr = DateFormat('yyyy-MM-dd').format(day);
                  final isCompleted = completedSet.contains(dateStr);
                  final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;
                  return GestureDetector(
                    onTap: () => _toggleDate(day),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? colorScheme.primary.withOpacity(0.3)
                            : isToday
                                ? colorScheme.secondaryContainer.withOpacity(0.5)
                                : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday ? Border.all(color: colorScheme.primary, width: 2) : null,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isCompleted ? colorScheme.primary : colorScheme.onSurface,
                            fontWeight: isCompleted || isToday ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}