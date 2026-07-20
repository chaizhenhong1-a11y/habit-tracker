import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class PlanItem {
  final String id;
  String title;
  String notes;
  DateTime? dueDate;
  bool isCompleted;
  final DateTime createdAt;

  PlanItem({
    required this.id,
    required this.title,
    this.notes = '',
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
        id: json['id'] as String,
        title: json['title'] as String,
        notes: json['notes'] as String? ?? '',
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  List<PlanItem> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('plans') ?? [];
    setState(() {
      _plans = jsonList.map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return PlanItem.fromJson(map);
      }).toList();
      _plans.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    });
  }

  Future<void> _savePlans() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _plans.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('plans', jsonList);
  }

  Future<void> _showPlanDialog({PlanItem? existing}) async {
    final loc = AppLocalizations.of(context);
    final titleController = TextEditingController(text: existing?.title ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    DateTime? selectedDate = existing?.dueDate;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null 
              ? (loc.translate('editPlan') ?? '编辑计划') 
              : (loc.translate('addPlan') ?? '添加计划')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: loc.translate('planTitle') ?? '计划标题',
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
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
                          context: ctx,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Text(
                        selectedDate != null
                            ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                            : (loc.translate('notSet') ?? '未设置'),
                      ),
                    ),
                    if (selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setDialogState(() {
                            selectedDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.translate('cancel') ?? '取消')),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(loc.translate('titleRequired') ?? '标题不能为空')),
                  );
                  return;
                }
                Navigator.pop(ctx, {
                  'title': title,
                  'notes': notesController.text.trim(),
                  'dueDate': selectedDate,
                });
              },
              child: Text(loc.translate('save') ?? '保存'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      if (existing != null) {
        setState(() {
          existing.title = result['title'] as String;
          existing.notes = result['notes'] as String;
          existing.dueDate = result['dueDate'] as DateTime?;
        });
      } else {
        final plan = PlanItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: result['title'] as String,
          notes: result['notes'] as String,
          dueDate: result['dueDate'] as DateTime?,
          createdAt: DateTime.now(),
        );
        setState(() {
          _plans.add(plan);
        });
      }
      await _savePlans();
      _loadPlans();
    }
  }

  Future<void> _toggleComplete(PlanItem plan) async {
    setState(() {
      plan.isCompleted = !plan.isCompleted;
    });
    await _savePlans();
    _loadPlans();
  }

  Future<void> _deletePlan(PlanItem plan) async {
    final loc = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('deletePlan') ?? '删除计划'),
        content: Text('${loc.translate('confirmDeletePlan') ?? '确定删除'}「${plan.title}」?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel') ?? '取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.translate('delete') ?? '删除'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _plans.remove(plan);
      });
      await _savePlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('myPlan') ?? '我的计划'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlanDialog(),
        child: const Icon(Icons.add),
      ),
      body: _plans.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt, size: 80, color: colorScheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(loc.translate('noPlans') ?? '还没有计划',
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 8),
                  Text(loc.translate('addPlanHint') ?? '点击右下角 + 添加计划',
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                final dueDateStr = plan.dueDate != null
                    ? '${plan.dueDate!.year}-${plan.dueDate!.month.toString().padLeft(2, '0')}-${plan.dueDate!.day.toString().padLeft(2, '0')}'
                    : null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Checkbox(
                      value: plan.isCompleted,
                      onChanged: (_) => _toggleComplete(plan),
                    ),
                    title: Text(
                      plan.title,
                      style: TextStyle(
                        decoration: plan.isCompleted ? TextDecoration.lineThrough : null,
                        color: plan.isCompleted
                            ? colorScheme.onSurface.withOpacity(0.5)
                            : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (plan.notes.isNotEmpty)
                          Text(plan.notes, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (dueDateStr != null)
                          Text('${loc.translate('dueDateShort') ?? '截止'}：$dueDateStr',
                              style: TextStyle(color: colorScheme.primary, fontSize: 12)),
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
}