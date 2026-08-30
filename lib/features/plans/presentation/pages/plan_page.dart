import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/plan_controller.dart';
import '../../data/repositories/shared_preferences_plan_repository.dart';
import '../../domain/entities/plan_item.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  late final PlanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlanController(SharedPreferencesPlanRepository())
      ..addListener(_onChanged)
      ..load();
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

  Future<void> _showPlanDialog({PlanItem? existing}) async {
    final loc = AppLocalizations.of(context);
    final titleController = TextEditingController(text: existing?.title ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    var selectedDate = existing?.dueDate;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing != null
                    ? (loc.translate('editPlan') ?? '编辑计划')
                    : (loc.translate('addPlan') ?? '添加计划'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: loc.translate('planTitle') ?? '计划标题',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: loc.translate('notesOptional') ?? '备注（可选）',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('${loc.translate('dueDate') ?? '截止日期'}：'),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 5),
                              ),
                            );
                            if (picked != null && context.mounted) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          child: Text(
                            selectedDate == null
                                ? (loc.translate('notSet') ?? '未设置')
                                : _formatDate(selectedDate!),
                          ),
                        ),
                        if (selectedDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setDialogState(() => selectedDate = null);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(loc.translate('cancel') ?? '取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            loc.translate('titleRequired') ?? '标题不能为空',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, {
                      'title': title,
                      'notes': notesController.text.trim(),
                      'dueDate': selectedDate,
                    });
                  },
                  child: Text(loc.translate('save') ?? '保存'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    notesController.dispose();

    if (!mounted || result == null) return;

    if (existing != null) {
      existing
        ..title = result['title'] as String
        ..notes = result['notes'] as String
        ..dueDate = result['dueDate'] as DateTime?;
      await _controller.update(existing);
    } else {
      await _controller.add(
        PlanItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: result['title'] as String,
          notes: result['notes'] as String,
          dueDate: result['dueDate'] as DateTime?,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _deletePlan(PlanItem plan) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.translate('deletePlan') ?? '删除计划'),
        content: Text(
          '${loc.translate('confirmDeletePlan') ?? '确定删除'}'
          '「${plan.title}」?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.translate('cancel') ?? '取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.translate('delete') ?? '删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.delete(plan.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final plans = _controller.plans;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('myPlan') ?? '我的计划'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPlanDialog,
        child: const Icon(Icons.add),
      ),
      body: plans.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 80,
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.translate('noPlans') ?? '还没有计划',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.translate('addPlanHint') ?? '点击右下角 + 添加计划',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Checkbox(
                      value: plan.isCompleted,
                      onChanged: (_) => _controller.toggleComplete(plan),
                    ),
                    title: Text(
                      plan.title,
                      style: TextStyle(
                        decoration: plan.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: plan.isCompleted
                            ? colorScheme.onSurface.withValues(alpha: 0.5)
                            : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (plan.notes.isNotEmpty)
                          Text(
                            plan.notes,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (plan.dueDate != null)
                          Text(
                            '${loc.translate('dueDateShort') ?? '截止'}：'
                            '${_formatDate(plan.dueDate!)}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showPlanDialog(existing: plan),
                    ),
                    onLongPress: () => _deletePlan(plan),
                  ),
                );
              },
            ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
