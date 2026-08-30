import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../achievements/domain/entities/achievement.dart';
import '../../../habits/data/repositories/hive_habit_repository.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../application/analytics_controller.dart';
import '../../data/analytics_repository.dart';
import '../../domain/analytics_snapshot.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => DataPageState();
}

class DataPageState extends State<DataPage> {
  late final AnalyticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnalyticsController(
      AnalyticsRepository(habitRepository: HiveHabitRepository.fromHabitsBox()),
    )..addListener(_onChanged);
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> refreshData() => _controller.load();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final snapshot = _controller.snapshot;

    return Scaffold(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.96),
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
      body: snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                children: [
                  _Overview(snapshot: snapshot),
                  const SizedBox(height: 20),
                  _Achievements(
                    achievements: _controller.achievements(snapshot.habits),
                  ),
                  const SizedBox(height: 20),
                  _WeeklyTrend(values: snapshot.weekValues),
                  const SizedBox(height: 20),
                  _MonthHeatmap(days: snapshot.monthDays),
                  const SizedBox(height: 20),
                  _MoodStats(moodCount: snapshot.moodCount),
                  const SizedBox(height: 20),
                  _RecentDiary(items: snapshot.recentDiary),
                  const SizedBox(height: 24),
                  Text(
                    loc.translate('habitDetailMonitor') ?? '习惯明细监控',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (snapshot.habits.isEmpty)
                    _EmptyState(colorScheme: colorScheme)
                  else
                    for (final habit in snapshot.habits)
                      _HabitAnalyticsCard(
                        habit: habit,
                        streak: _controller.streak(habit),
                        weeklyRate: _controller.weeklyCompletionRate(habit),
                        totalRate: _controller.totalCompletionRate(habit),
                      ),
                ],
              ),
            ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: loc.translate('totalEssays') ?? '累计随笔',
            value: '${snapshot.diaryTotalCount}',
            unit: loc.translate('essaysUnit') ?? '篇',
            icon: Icons.book_rounded,
            accent: colors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            label: loc.translate('persisting') ?? '正在坚持',
            value: '${snapshot.habitCount}',
            unit: loc.translate('habitsUnit') ?? '个',
            icon: Icons.widgets_rounded,
            accent: colors.tertiary,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
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
            child: Icon(icon, size: 40, color: accent.withValues(alpha: 0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(unit),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyTrend extends StatelessWidget {
  const _WeeklyTrend({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);
    final loc = AppLocalizations.of(context);
    final now = DateTime.now();
    final labels = [
      for (var i = 6; i >= 0; i--)
        DateFormat(
          'E',
          locale.toString(),
        ).format(now.subtract(Duration(days: i))),
    ];
    final maxValue = values.fold<double>(0, (max, v) => v > max ? v : max);

    return _SectionCard(
      title: loc.translate('weekCheckTrend') ?? '本周打卡趋势',
      icon: Icons.analytics_rounded,
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxValue == 0 ? 5 : maxValue + 1,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: colors.onSurface.withValues(alpha: 0.05)),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: colors.primary,
                barWidth: 3.5,
                spots: [
                  for (var i = 0; i < values.length; i++)
                    FlSpot(i.toDouble(), values[i]),
                ],
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.primary.withValues(alpha: 0.2),
                      colors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthHeatmap extends StatelessWidget {
  const _MonthHeatmap({required this.days});

  final List<AnalyticsMonthDay> days;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final maxCount = days.fold<int>(
      0,
      (max, d) => d.count > max ? d.count : max,
    );

    return _SectionCard(
      title: loc.translate('monthHeatmap') ?? '本月打卡热力图',
      icon: Icons.grid_on_rounded,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final day in days)
            Builder(
              builder: (context) {
                final intensity = maxCount == 0 ? 0.0 : day.count / maxCount;
                final color = day.count == 0
                    ? colors.onSurface.withValues(alpha: 0.04)
                    : Color.lerp(
                        colors.primary.withValues(alpha: 0.2),
                        colors.primary,
                        intensity,
                      );
                return Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: day.count > 0 ? FontWeight.bold : null,
                      color: day.count > 0 && intensity > 0.5
                          ? colors.onPrimary
                          : colors.onSurface,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MoodStats extends StatelessWidget {
  const _MoodStats({required this.moodCount});

  final Map<String, int> moodCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final total = moodCount.values.fold<int>(0, (sum, value) => sum + value);

    return _SectionCard(
      title: loc.translate('annualMoodBarometer') ?? '年度心情晴雨表',
      icon: Icons.face_retouching_natural_rounded,
      child: total == 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  loc.translate('noMoodRecordThisYear') ?? '今年还没有记录心情',
                ),
              ),
            )
          : Column(
              children: [
                for (final entry in AnalyticsRepository.moodMap.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Text(entry.value, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (moodCount[entry.key] ?? 0) / total,
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(10),
                            backgroundColor: colors.onSurface.withValues(
                              alpha: 0.05,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${moodCount[entry.key] ?? 0}'),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RecentDiary extends StatelessWidget {
  const _RecentDiary({required this.items});

  final List<AnalyticsDiaryItem> items;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    return _SectionCard(
      title: loc.translate('recentEssays') ?? '近几日随笔',
      icon: Icons.auto_stories_rounded,
      child: items.isEmpty
          ? Center(child: Text(loc.translate('essayBlank') ?? '随笔留白中...'))
          : Column(
              children: [
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      AnalyticsRepository.moodMap[item.mood] ?? '😊',
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      item.title.isEmpty
                          ? (loc.translate('unnamedThoughts') ?? '未命名心事')
                          : item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      DateFormat(
                        locale.languageCode == 'zh' ? 'MM月dd日' : 'MMM dd',
                        locale.toString(),
                      ).format(item.date),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Achievements extends StatelessWidget {
  const _Achievements({required this.achievements});

  final List<AchievementProgress> achievements;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return _SectionCard(
      title: loc.translate('achievementWall') ?? '成就荣誉墙',
      icon: Icons.military_tech_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final width = compact
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final achievement in achievements)
                SizedBox(
                  width: width,
                  child: _Badge(achievement: achievement),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.achievement});

  final AchievementProgress achievement;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final unlocked = achievement.isUnlocked;
    final definition = achievement.definition;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: unlocked
            ? colors.primary.withValues(alpha: 0.10)
            : colors.onSurface.withValues(alpha: 0.035),
        border: Border.all(
          color: unlocked
              ? colors.primary.withValues(alpha: 0.26)
              : colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                unlocked
                    ? Icons.workspace_premium_rounded
                    : Icons.lock_outline_rounded,
                color: unlocked
                    ? colors.primary
                    : colors.onSurface.withValues(alpha: 0.35),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: unlocked
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  unlocked
                      ? (loc.translate('unlocked') ?? '已解锁')
                      : (loc.translate('locked') ?? '未解锁'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: unlocked ? colors.primary : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            loc.translate(definition.titleKey) ?? definition.id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: achievement.progressRatio,
            minHeight: 7,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 7),
          Text(
            '${achievement.currentValue}/${definition.target} '
            '${loc.translate('daysUnit') ?? '天'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _HabitAnalyticsCard extends StatelessWidget {
  const _HabitAnalyticsCard({
    required this.habit,
    required this.streak,
    required this.weeklyRate,
    required this.totalRate,
  });

  final Habit habit;
  final int streak;
  final double weeklyRate;
  final double totalRate;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  habit.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text('🔥 $streak ${loc.translate('daysUnit') ?? '天'}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Rate(
                  label: loc.translate('weekCompletion') ?? '本周完成',
                  value: weeklyRate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Rate(
                  label: loc.translate('totalCompletionRate') ?? '总完成率',
                  value: totalRate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Rate extends StatelessWidget {
  const _Rate({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: value.clamp(0, 1)),
        const SizedBox(height: 4),
        Text('${(value * 100).toStringAsFixed(0)}%'),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 18),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 56,
            color: colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(loc.translate('noHabitData') ?? '暂无追踪中的习惯数据'),
        ],
      ),
    );
  }
}
