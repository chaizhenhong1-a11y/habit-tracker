import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

const Map<String, String> moodMap = {
  'happy': '😊',
  'calm': '😌',
  'sad': '😢',
  'angry': '😡',
  'excited': '🤩',
  'tired': '😴',
};

class _DiaryItem {
  final DateTime date;
  final String mood;
  final String title;
  _DiaryItem({required this.date, required this.mood, required this.title});
}

class _MonthDay {
  final int day;
  final int count;
  _MonthDay({required this.day, required this.count});
}

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});
  @override
  State<DataScreen> createState() => DataScreenState();
}

class DataScreenState extends State<DataScreen> {
  Map<String, int> _moodCount = {};
  List<_DiaryItem> _recentDiary = [];
  List<double> _weekValues = [0, 0, 0, 0, 0, 0, 0];
  List<_MonthDay> _monthDays = [];
  int _diaryTotalCount = 0;
  int _habitCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void refreshData() => _loadData();

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('diary_entries') ?? [];

    final now = DateTime.now();
    final thisYear = now.year;
    final thisMonth = now.month;

    final Map<String, int> count = {for (var key in moodMap.keys) key: 0};
    final List<_DiaryItem> items = [];
    for (var jsonStr in jsonList) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final date = DateTime.parse(map['date'] as String);
        final mood = map['mood'] as String? ?? 'happy';
        final title = map['title'] as String? ?? '';
        items.add(_DiaryItem(date: date, mood: mood, title: title));
        if (date.year == thisYear) {
          count[mood] = (count[mood] ?? 0) + 1;
        }
      } catch (e) {
        debugPrint('⚠️ 解析日记失败: $e');
      }
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    final recent = items.take(5).toList();

    final habits = HabitService().getAllHabits();
    final Map<String, int> dailyCount = {};
    for (var h in habits) {
      for (var dateStr in h.completedDates) {
        dailyCount[dateStr] = (dailyCount[dateStr] ?? 0) + 1;
      }
    }

    // 计算本周每天的数据（只存数值，标签在build中动态生成）
    final List<double> weekVals = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      weekVals.add((dailyCount[key] ?? 0).toDouble());
    }

    final daysInMonth = DateTime(thisYear, thisMonth + 1, 0).day;
    final List<_MonthDay> monthDays = [];
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(thisYear, thisMonth, d);
      final key = DateFormat('yyyy-MM-dd').format(date);
      monthDays.add(_MonthDay(day: d, count: dailyCount[key] ?? 0));
    }

    setState(() {
      _moodCount = count;
      _recentDiary = recent;
      _weekValues = weekVals;
      _monthDays = monthDays;
      _diaryTotalCount = jsonList.length;
      _habitCount = habits.length;
    });
  }

  int _maxStreak(List<Habit> habits) {
    int maxStreak = 0;
    for (final habit in habits) {
      final streak = _calculateStreak(habit.completedDates);
      if (streak > maxStreak) maxStreak = streak;
    }
    return maxStreak;
  }

  int _totalCompletedDays(List<Habit> habits) {
    return habits.fold(0, (sum, habit) => sum + habit.completedDates.length);
  }

  int _calculateStreak(List<String> completedDates) {
    if (completedDates.isEmpty) return 0;
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
    DateTime checkDate;
    if (completedDates.contains(todayStr)) {
      checkDate = today;
    } else if (completedDates.contains(yesterdayStr)) {
      checkDate = yesterday;
    } else {
      return 0;
    }
    int streak = 0;
    while (completedDates.contains(
      DateFormat('yyyy-MM-dd').format(checkDate),
    )) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double _weeklyCompletionRate(List<String> completedDates) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    int daysInWeek = 0;
    int completedDays = 0;
    for (var d = monday; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
      daysInWeek++;
      if (completedDates.contains(DateFormat('yyyy-MM-dd').format(d))) {
        completedDays++;
      }
    }
    return daysInWeek == 0 ? 0 : completedDays / daysInWeek;
  }

  double _totalCompletionRate(Habit habit) {
    final createdDate = DateTime.fromMillisecondsSinceEpoch(
      int.parse(habit.id),
    );
    final today = DateTime.now();
    final totalDays = today.difference(createdDate).inDays + 1;
    if (totalDays <= 0) return 0;
    return habit.completedDates.length / totalDays;
  }

  @override
  Widget build(BuildContext context) {
    final habits = HabitService().getAllHabits();
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final maxStreak = _maxStreak(habits);
    final totalDays = _totalCompletedDays(habits);

    return Scaffold(
      backgroundColor: colorScheme.surface.withOpacity(0.96),
      appBar: AppBar(
        title: Text(
          loc.translate('dataDashboard') ?? '数据看板',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildTopOverview(context),
          const SizedBox(height: 20),
          _buildAchievements(context, maxStreak, totalDays),
          const SizedBox(height: 20),
          _buildWeeklyTrendSafe(context),
          const SizedBox(height: 20),
          _buildMonthHeatmapSafe(context),
          const SizedBox(height: 20),
          _buildMoodStats(context),
          const SizedBox(height: 20),
          _buildRecentDiary(context),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              loc.translate('habitDetailMonitor') ?? '习惯明细监控',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          if (habits.isEmpty)
            _buildEmptyState(context, colorScheme)
          else
            ...habits.map((habit) {
              final streak = _calculateStreak(habit.completedDates);
              final weeklyRate = _weeklyCompletionRate(habit.completedDates);
              final totalRate = _totalCompletionRate(habit);
              final habitTotalDays = habit.completedDates.length;
              return _buildHabitCard(
                context,
                habit,
                streak,
                weeklyRate,
                totalRate,
                habitTotalDays,
              );
            }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTopOverview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildGridItem(
            context,
            loc.translate('totalEssays') ?? '累计随笔',
            _diaryTotalCount.toString(),
            loc.translate('essaysUnit') ?? '篇',
            Icons.book_rounded,
            colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGridItem(
            context,
            loc.translate('persisting') ?? '正在坚持',
            _habitCount.toString(),
            loc.translate('habitsUnit') ?? '个',
            Icons.widgets_rounded,
            colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(icon, size: 40, color: color.withOpacity(0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendSafe(BuildContext context) {
    try {
      return _buildWeeklyTrend(context);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMonthHeatmapSafe(BuildContext context) {
    try {
      return _buildMonthHeatmap(context);
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildWeeklyTrend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    // 动态生成星期标签（使用当前语言）
    final now = DateTime.now();
    final List<String> weekLabels = [];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      // 使用短格式星期，例如 "Mon" 或 "周一"
      weekLabels.add(DateFormat('E', locale.toString()).format(day));
    }

    final double maxVal = _weekValues.isEmpty
        ? 0
        : _weekValues.reduce((a, b) => a > b ? a : b);
    final double maxY = maxVal == 0 ? 5.0 : maxVal + 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            Icons.analytics_rounded,
            loc.translate('weekCheckTrend') ?? '本周打卡趋势',
            colorScheme.primary,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.onSurface.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < weekLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              weekLabels[idx],
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withOpacity(0.4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _weekValues.length,
                      (i) => FlSpot(i.toDouble(), _weekValues[i]),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: colorScheme.primary,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: colorScheme.surface,
                            strokeWidth: 2.5,
                            strokeColor: colorScheme.primary,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.2),
                          colorScheme.primary.withOpacity(0.00),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxY,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeatmap(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final maxCount = _monthDays.isEmpty
        ? 1
        : _monthDays.fold<int>(0, (max, d) => d.count > max ? d.count : max);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            Icons.grid_on_rounded,
            loc.translate('monthHeatmap') ?? '本月打卡热力图',
            colorScheme.secondary,
          ),
          const SizedBox(height: 18),
          Center(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _monthDays.map((d) {
                final intensity = maxCount > 0 ? d.count / maxCount : 0.0;
                final cellColor = d.count == 0
                    ? colorScheme.onSurface.withOpacity(0.04)
                    : Color.lerp(
                        colorScheme.primary.withOpacity(0.2),
                        colorScheme.primary,
                        intensity,
                      )!;
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: d.count > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: d.count == 0
                            ? colorScheme.onSurface.withOpacity(0.4)
                            : (intensity > 0.5
                                  ? Colors.white
                                  : colorScheme.primaryContainer),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(
    BuildContext context,
    int maxStreak,
    int totalDays,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            Icons.military_tech_rounded,
            loc.translate('achievementWall') ?? '成就荣誉墙',
            Colors.amber.shade700,
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _BadgeItem(
                icon: Icons.local_fire_department_rounded,
                label: loc.translate('beginner') ?? '初学乍练',
                unlocked: maxStreak >= 7,
                progress: maxStreak,
                target: 7,
                color: const Color(0xFFFF6B6B),
              ),
              _BadgeItem(
                icon: Icons.thunderstorm_rounded,
                label: loc.translate('perseverance') ?? '持之以恒',
                unlocked: maxStreak >= 30,
                progress: maxStreak,
                target: 30,
                color: const Color(0xFFFF9F43),
              ),
              _BadgeItem(
                icon: Icons.workspace_premium_rounded,
                label: loc.translate('habitNature') ?? '习惯成自然',
                unlocked: maxStreak >= 60,
                progress: maxStreak,
                target: 60,
                color: const Color(0xFF10AC84),
              ),
              _BadgeItem(
                icon: Icons.diamond_rounded,
                label: loc.translate('thousandTempering') ?? '千锤百炼',
                unlocked: totalDays >= 100,
                progress: totalDays,
                target: 100,
                color: const Color(0xFF2E86DE),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodStats(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final totalMoods = _moodCount.values.fold(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            Icons.face_retouching_natural_rounded,
            loc.translate('annualMoodBarometer') ?? '年度心情晴雨表',
            Colors.indigo,
          ),
          const SizedBox(height: 16),
          if (totalMoods == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  loc.translate('noMoodRecordThisYear') ?? '今年还没有记录心情',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
            )
          else
            ...moodMap.entries.map((mood) {
              final count = _moodCount[mood.key] ?? 0;
              final pct = totalMoods > 0 ? count / totalMoods : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Text(mood.value, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                mood.key.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withOpacity(0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$count ${loc.translate('essaysUnit') ?? '篇'}  ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                              Text(
                                '${(pct * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: colorScheme.onSurface
                                  .withOpacity(0.04),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentDiary(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            Icons.auto_stories_rounded,
            loc.translate('recentEssays') ?? '近几日随笔',
            colorScheme.primary,
          ),
          const SizedBox(height: 16),
          if (_recentDiary.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  loc.translate('essayBlank') ?? '随笔留白中...',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentDiary.length,
              itemBuilder: (context, index) {
                final item = _recentDiary[index];
                final showBorder = index != _recentDiary.length - 1;
                // 根据当前语言格式化日期
                String dateStr;
                if (locale.languageCode == 'zh') {
                  dateStr = DateFormat('MM月dd日').format(item.date);
                } else {
                  dateStr = DateFormat(
                    'MMM dd',
                  ).format(item.date); // 例如 "Jun 16"
                }
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: showBorder
                      ? BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.onSurface.withOpacity(0.04),
                              width: 1,
                            ),
                          ),
                        )
                      : null,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withOpacity(0.03),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          moodMap[item.mood] ?? '😊',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.title.isNotEmpty
                              ? item.title
                              : (loc.translate('unnamedThoughts') ?? '未命名心事'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(
    BuildContext context,
    Habit habit,
    int streak,
    double weeklyRate,
    double totalRate,
    int habitTotalDays,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  habit.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: streak > 0
                      ? Colors.orange.shade50
                      : colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: streak > 0
                          ? Colors.orange
                          : colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${loc.translate('streakDays') ?? '连击'} $streak ${loc.translate('daysUnit') ?? '天'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: streak > 0
                            ? Colors.orange.shade900
                            : colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniIndicator(
                loc.translate('weekCompletion') ?? '本周完成',
                weeklyRate,
              ),
              _buildMiniIndicator(
                loc.translate('totalCompletionRate') ?? '总完成率',
                totalRate,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('totalPersist') ?? '累计坚持',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$habitTotalDays',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2, left: 2),
                        child: Text(
                          loc.translate('daysUnit') ?? '天',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIndicator(String title, double rate) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            value: rate,
            strokeWidth: 3.5,
            backgroundColor: Colors.black.withOpacity(0.04),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade400),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.black.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${(rate * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
    Color accentColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 60,
            color: colorScheme.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 12),
          Text(
            loc.translate('noHabitData') ?? '暂无追踪中的习惯数据',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool unlocked;
  final int progress;
  final int target;
  final Color color;
  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.unlocked,
    required this.progress,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: unlocked
            ? LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.03)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  colorScheme.onSurface.withOpacity(0.02),
                  colorScheme.onSurface.withOpacity(0.01),
                ],
              ),
        border: Border.all(
          color: unlocked
              ? color.withOpacity(0.25)
              : colorScheme.onSurface.withOpacity(0.06),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: unlocked
                    ? color
                    : colorScheme.onSurface.withOpacity(0.2),
              ),
              const Spacer(),
              Text(
                unlocked
                    ? (loc.translate('unlocked') ?? '已解锁')
                    : (loc.translate('locked') ?? '未解锁'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: unlocked
                      ? color
                      : colorScheme.onSurface.withOpacity(0.25),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$progress/$target',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: colorScheme.onSurface.withOpacity(0.04),
              valueColor: AlwaysStoppedAnimation<Color>(
                unlocked ? color : colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
