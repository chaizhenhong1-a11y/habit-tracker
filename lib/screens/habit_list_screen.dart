import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import 'habit_calendar_screen.dart';

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  final HabitService _habitService = HabitService();
  List<Habit> _habits = [];

  final List<Map<String, dynamic>> _pendingDeletes = [];
  Timer? _clearTimer;

  final List<String> _emojiList = ['✅', '📚', '🏃', '💧', '🧘', '🎸', '💤', '🍎', '✍️', '🧹'];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  void _loadHabits() {
    setState(() {
      _habits = _habitService.getAllHabits();
    });
  }

  List<Habit> get _goodHabits => _habits.where((h) => h.type == 'good').toList();
  List<Habit> get _badHabits => _habits.where((h) => h.type == 'bad').toList();

  bool _isCompletedToday(Habit habit) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return habit.completedDates.contains(today);
  }

  void _toggleHabit(Habit habit) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      if (_isCompletedToday(habit)) {
        habit.completedDates.remove(today);
      } else {
        habit.completedDates.add(today);
      }
    });
    _habitService.updateHabit(habit);
    _loadHabits();
  }

  void _onReorder(int oldIndex, int newIndex, List<Habit> group) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = group.removeAt(oldIndex);
      group.insert(newIndex, item);
      _habits = [..._goodHabits, ..._badHabits];
      _habitService.updateOrder(_habits);
    });
  }

  void _showHabitOptions(Habit habit) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(habit.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(loc.translate('editHabit') ?? '编辑习惯', style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _showEditHabitDialog(habit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(loc.translate('deleteHabit') ?? '删除习惯', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(habit);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHabitDialog(Habit habit) {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController();
    String selectedEmoji = '✅';
    String nameWithoutEmoji = habit.name;

    for (final emoji in _emojiList) {
      if (habit.name.startsWith(emoji)) {
        selectedEmoji = emoji;
        nameWithoutEmoji = habit.name.substring(emoji.length).trim();
        break;
      }
    }
    nameController.text = nameWithoutEmoji;
    String selectedType = habit.type;

    _showCustomDialog(
      title: loc.translate('editHabit') ?? '编辑习惯',
      nameController: nameController,
      selectedEmoji: selectedEmoji,
      selectedType: selectedType,
      actionLabel: loc.translate('save') ?? '保存',
      onConfirm: (finalEmoji, finalType, finalName) {
        habit.name = '$finalEmoji $finalName';
        habit.type = finalType;
        _habitService.updateHabit(habit);
        _loadHabits();
      },
    );
  }

  void _showAddHabitDialog() {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController();
    _showCustomDialog(
      title: loc.translate('addHabit') ?? '新建习惯',
      nameController: nameController,
      selectedEmoji: '✅',
      selectedType: 'good',
      actionLabel: loc.translate('add') ?? '添加',
      onConfirm: (finalEmoji, finalType, finalName) {
        final habit = Habit(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '$finalEmoji $finalName',
          completedDates: [],
          type: finalType,
        );
        _habitService.addHabit(habit);
        _loadHabits();
      },
    );
  }

  void _showCustomDialog({
    required String title,
    required TextEditingController nameController,
    required String selectedEmoji,
    required String selectedType,
    required String actionLabel,
    required Function(String, String, String) onConfirm,
  }) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => selectedType = 'good'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedType == 'good' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: selectedType == 'good'
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Text(
                                '😇 ${loc.translate('goodHabit') ?? '好习惯'}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => selectedType = 'bad'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedType == 'bad' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: selectedType == 'bad'
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Text(
                                '😈 ${loc.translate('badHabit') ?? '坏习惯'}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _emojiList.map((emoji) {
                      final isSelected = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedEmoji = emoji),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? colorScheme.primary.withOpacity(0.12) : colorScheme.onSurface.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? colorScheme.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: loc.translate('habitNameHint') ?? '习惯名称',
                      filled: true,
                      fillColor: colorScheme.onSurface.withOpacity(0.04),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                      ),
                    ),
                    autofocus: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.translate('cancel') ?? '取消', style: const TextStyle(color: Colors.grey)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () {
                  final text = nameController.text.trim();
                  if (text.isNotEmpty) {
                    onConfirm(selectedEmoji, selectedType, text);
                    Navigator.pop(context);
                  }
                },
                child: Text(actionLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(Habit habit) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('deleteConfirm') ?? '删除确认'),
        content: Text('${loc.translate('confirmDeleteHabit') ?? '确定将'}「${habit.name}」${loc.translate('permanentlyRemove') ?? '彻底移除吗？'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.translate('cancel') ?? '取消', style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteWithUndo(habit);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(loc.translate('delete') ?? '删除', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteWithUndo(Habit habit) {
    final index = _habits.indexOf(habit);
    if (index == -1) return;

    _pendingDeletes.insert(0, {'habit': habit, 'index': index});
    setState(() {
      _habits.removeAt(index);
    });

    _showUndoSnackBar(habit.name);
    _startClearTimer();
  }

  void _showUndoSnackBar(String name) {
    final loc = AppLocalizations.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        backgroundColor: const Color(0xFF2E2E3E),
        content: Text('${loc.translate('deleted') ?? '已删除'}「$name」', style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: loc.translate('undo') ?? '撤销',
          textColor: const Color(0xFF8E97FD),
          onPressed: () => _undoLastDelete(scaffoldMessenger),
        ),
      ),
    );
  }

  void _undoLastDelete(ScaffoldMessengerState scaffoldMessenger) {
    if (_pendingDeletes.isEmpty) return;

    final last = _pendingDeletes.removeAt(0);
    final habit = last['habit'] as Habit;
    final originalIndex = last['index'] as int;

    setState(() {
      if (originalIndex <= _habits.length) {
        _habits.insert(originalIndex, habit);
      } else {
        _habits.add(habit);
      }
    });

    _habitService.addHabit(habit);
    scaffoldMessenger.hideCurrentSnackBar();
  }

  void _startClearTimer() {
    _clearTimer?.cancel();
    _clearTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pendingDeletes.isEmpty) {
        timer.cancel();
        return;
      }
      final oldest = _pendingDeletes.removeLast();
      _habitService.deleteHabit((oldest['habit'] as Habit).id);
    });
  }

  Widget _buildHabitGroup(List<Habit> habits, String title, IconData icon, Color badgeColor) {
    if (habits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: badgeColor),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              const SizedBox(width: 8),
              Text('${habits.length}', style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        ReorderableListView.builder(
          buildDefaultDragHandles: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: habits.length,
          onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, habits),
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) => Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(20),
                child: child,
              ),
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final habit = habits[index];
            return Padding(
              key: ValueKey(habit.id),
              padding: const EdgeInsets.only(bottom: 12),
              child: _HabitCard(
                habit: habit,
                done: _isCompletedToday(habit),
                onToggle: () => _toggleHabit(habit),
                onLongPress: () => _showHabitOptions(habit),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    if (_habits.isEmpty) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            _buildModernAppBar(context),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.06), shape: BoxShape.circle),
                      child: Icon(Icons.spa_outlined, size: 64, color: colorScheme.primary.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      loc.translate('startMinimalLife') ?? '开启极简生活',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.translate('addFirstHabitHint') ?? '点击下方轻点创建\n让好习惯融入生活的呼吸',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.4), height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFab(),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildModernAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHabitGroup(
                  _goodHabits,
                  loc.translate('goodProgress') ?? '好习惯进展',
                  Icons.trending_up_rounded,
                  const Color(0xFF34C759),
                ),
                _buildHabitGroup(
                  _badHabits,
                  loc.translate('badRestraint') ?? '坏习惯克制',
                  Icons.warning_amber_rounded,
                  const Color(0xFFFF3B30),
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SliverAppBar.large(
      expandedHeight: 120,
      collapsedHeight: 64,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            title: Text(
              loc.translate('myHabits') ?? '我的习惯',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
              ),
            ),
            background: Container(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.65)),
          ),
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildFab() {
    final loc = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FloatingActionButton.extended(
        onPressed: _showAddHabitDialog,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          loc.translate('addHabit') ?? '新习惯',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

// 卡片组件保持不变，无需本地化（名称由数据动态显示）
class _HabitCard extends StatefulWidget {
  final Habit habit;
  final bool done;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  const _HabitCard({
    super.key,
    required this.habit,
    required this.done,
    required this.onToggle,
    required this.onLongPress,
  });

  @override
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 120), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapCheck() {
    _controller.forward().then((_) {
      widget.onToggle();
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isBad = widget.habit.type == 'bad';

    final Color activeColor = isBad ? const Color(0xFFFF453A) : colorScheme.primary;
    final Color cardBg = widget.done
        ? (isBad ? const Color(0xFFFF453A).withOpacity(0.06) : colorScheme.primary.withOpacity(0.06))
        : Colors.white;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: widget.done
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onLongPress: widget.onLongPress,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: widget.done ? activeColor : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.habit.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: widget.done ? TextDecoration.lineThrough : null,
                        color: widget.done ? colorScheme.onSurface.withOpacity(0.35) : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today_rounded, size: 18, color: colorScheme.onSurface.withOpacity(0.35)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HabitCalendarScreen(habit: widget.habit)),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _onTapCheck,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.done ? activeColor : Colors.transparent,
                        border: Border.all(
                          color: widget.done ? activeColor : colorScheme.onSurface.withOpacity(0.15),
                          width: 2,
                        ),
                      ),
                      child: widget.done
                          ? const Icon(
                            Icons.check_circle_rounded,
                            color:Colors.white,
                            size:16,
                          )
                             
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}