import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/diary_controller.dart';
import '../../data/repositories/shared_preferences_diary_repository.dart';
import '../../domain/entities/diary_entry.dart';

const Map<String, String> diaryMoodMap = {
  'happy': '😊',
  'calm': '😌',
  'sad': '😢',
  'angry': '😡',
  'excited': '🤩',
  'tired': '😴',
};

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late final DiaryController _controller;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = DiaryController(SharedPreferencesDiaryRepository())
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

  Future<void> _showDiaryDialog({DiaryEntry? existing}) async {
    final loc = AppLocalizations.of(context);
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(
      text: existing?.content ?? '',
    );
    var selectedMood = existing?.mood ?? 'happy';
    String? imagePath = existing?.imagePath;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing != null
                    ? (loc.translate('editDiary') ?? '编辑日记')
                    : (loc.translate('writeDiary') ?? '写日记'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.translate('todayMood') ?? '今天的心情：',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: diaryMoodMap.entries.map((entry) {
                        final selected = selectedMood == entry.key;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedMood = entry.key);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: loc.translate('title') ?? '标题',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: loc.translate('content') ?? '内容',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await _picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );
                            if (picked != null && context.mounted) {
                              setDialogState(() => imagePath = picked.path);
                            }
                          },
                          icon: const Icon(Icons.photo_library),
                          label: Text(loc.translate('gallery') ?? '相册'),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await _picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 80,
                            );
                            if (picked != null && context.mounted) {
                              setDialogState(() => imagePath = picked.path);
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: Text(loc.translate('camera') ?? '拍照'),
                        ),
                      ],
                    ),
                    if (imagePath != null) ...[
                      const SizedBox(height: 8),
                      Image.file(
                        File(imagePath!),
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                      TextButton(
                        onPressed: () {
                          setDialogState(() => imagePath = null);
                        },
                        child: Text(loc.translate('removePhoto') ?? '移除照片'),
                      ),
                    ],
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
                    final content = contentController.text.trim();
                    if (title.isEmpty && content.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            loc.translate('diaryEmpty') ?? '标题和内容不能都为空',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, {
                      'title': title,
                      'content': content,
                      'mood': selectedMood,
                      'imagePath': imagePath,
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
    contentController.dispose();

    if (!mounted || result == null) return;

    if (existing != null) {
      existing
        ..title = result['title'] as String
        ..content = result['content'] as String
        ..mood = result['mood'] as String
        ..imagePath = result['imagePath'] as String?;
      await _controller.update(existing);
    } else {
      await _controller.add(
        DiaryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: result['title'] as String,
          content: result['content'] as String,
          mood: result['mood'] as String,
          imagePath: result['imagePath'] as String?,
          date: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.translate('deleteDiary') ?? '删除日记'),
        content: Text(
          '${loc.translate('confirmDeleteDiary') ?? '确定删除'}'
          '「${entry.title.isNotEmpty ? entry.title : (loc.translate('untitled') ?? '无标题')}」?',
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
      await _controller.delete(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final entries = _controller.entries;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('myDiary') ?? '我的日记'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showDiaryDialog,
        child: const Icon(Icons.add),
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 80,
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.translate('noDiary') ?? '还没有日记',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.translate('addDiaryHint') ?? '点击右下角 + 开始记录',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => DiaryDetailPage(entry: entry),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text(
                            diaryMoodMap[entry.mood] ?? '😊',
                            style: const TextStyle(fontSize: 36),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.title.isNotEmpty
                                      ? entry.title
                                      : (loc.translate('untitled') ?? '无标题'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (entry.content.isNotEmpty)
                                  Text(
                                    entry.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                Text(
                                  _formatDate(entry.date),
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (entry.imagePath case final path?
                              when path.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(path),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _deleteEntry(entry),
                          ),
                        ],
                      ),
                    ),
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

class DiaryDetailPage extends StatelessWidget {
  const DiaryDetailPage({super.key, required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          entry.title.isNotEmpty
              ? entry.title
              : (loc.translate('untitled') ?? '无标题'),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  diaryMoodMap[entry.mood] ?? '😊',
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _DiaryPageState._formatDate(entry.date),
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      '${loc.translate('mood') ?? '心情'}：'
                      '${diaryMoodMap[entry.mood] ?? ''}',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (entry.imagePath case final path? when path.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(path),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              entry.content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
