import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

const Map<String, String> moodMap = {
  'happy': '😊',
  'calm': '😌',
  'sad': '😢',
  'angry': '😡',
  'excited': '🤩',
  'tired': '😴',
};

class DiaryEntry {
  final String id;
  String title;
  String content;
  DateTime date;
  String mood;
  String? imagePath;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.mood = 'happy',
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'date': date.toIso8601String(),
        'mood': mood,
        'imagePath': imagePath,
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        date: DateTime.parse(json['date'] as String),
        mood: json['mood'] as String? ?? 'happy',
        imagePath: json['imagePath'] as String?,
      );
}

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<DiaryEntry> _entries = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('diary_entries') ?? [];
    setState(() {
      _entries = jsonList.map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return DiaryEntry.fromJson(map);
      }).toList();
      _entries.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('diary_entries', jsonList);
  }

  Future<void> _showDiaryDialog({DiaryEntry? existing}) async {
    final loc = AppLocalizations.of(context);
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(text: existing?.content ?? '');
    String selectedMood = existing?.mood ?? 'happy';
    String? imagePath = existing?.imagePath;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null
              ? (loc.translate('editDiary') ?? '编辑日记')
              : (loc.translate('writeDiary') ?? '写日记')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.translate('todayMood') ?? '今天的心情：',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: moodMap.entries.map((entry) {
                    final isSelected = selectedMood == entry.key;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedMood = entry.key;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(ctx).colorScheme.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(entry.value, style: const TextStyle(fontSize: 30)),
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
                Row(
                  children: [
                    Text('${loc.translate('photo') ?? '照片'}：'),
                    TextButton.icon(
                      onPressed: () async {
                        final XFile? picked = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            imagePath = picked.path;
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: Text(loc.translate('gallery') ?? '相册'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final XFile? picked = await _picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            imagePath = picked.path;
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: Text(loc.translate('camera') ?? '拍照'),
                    ),
                  ],
                ),
                if (imagePath != null) ...[
                  const SizedBox(height: 8),
                  Image.file(File(imagePath!), height: 120, fit: BoxFit.cover),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        imagePath = null;
                      });
                    },
                    child: Text(loc.translate('removePhoto') ?? '移除照片'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.translate('cancel') ?? '取消')),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final content = contentController.text.trim();
                if (title.isEmpty && content.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(loc.translate('diaryEmpty') ?? '标题和内容不能都为空')),
                  );
                  return;
                }
                Navigator.pop(ctx, {
                  'title': title,
                  'content': content,
                  'mood': selectedMood,
                  'imagePath': imagePath,
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
          existing.content = result['content'] as String;
          existing.mood = result['mood'] as String;
          existing.imagePath = result['imagePath'] as String?;
        });
      } else {
        final entry = DiaryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: result['title'] as String,
          content: result['content'] as String,
          mood: result['mood'] as String,
          imagePath: result['imagePath'] as String?,
          date: DateTime.now(),
        );
        setState(() {
          _entries.insert(0, entry);
        });
      }
      await _saveEntries();
      _loadEntries();
    }
  }

  void _viewEntry(DiaryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryDetailPage(entry: entry),
      ),
    );
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
    final loc = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('deleteDiary') ?? '删除日记'),
        content: Text(
          '${loc.translate('confirmDeleteDiary') ?? '确定删除'}「${entry.title.isNotEmpty ? entry.title : (loc.translate('untitled') ?? '无标题')}」?',
        ),
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
        _entries.remove(entry);
      });
      await _saveEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('myDiary') ?? '我的日记'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDiaryDialog(),
        child: const Icon(Icons.add),
      ),
      body: _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book, size: 80, color: colorScheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(loc.translate('noDiary') ?? '还没有日记',
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 8),
                  Text(loc.translate('addDiaryHint') ?? '点击右下角 + 开始记录',
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final dateStr =
                    '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _viewEntry(entry),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text(
                            moodMap[entry.mood] ?? '😊',
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
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (entry.content.isNotEmpty)
                                  Text(
                                    entry.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                                  ),
                                Text(
                                  dateStr,
                                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (entry.imagePath != null && entry.imagePath!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(entry.imagePath!),
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
}

class DiaryDetailPage extends StatelessWidget {
  final DiaryEntry entry;
  const DiaryDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr =
        '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.title.isNotEmpty ? entry.title : (loc.translate('untitled') ?? '无标题')),
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
                  moodMap[entry.mood] ?? '😊',
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
                    Text('${loc.translate('mood') ?? '心情'}：${moodMap[entry.mood] ?? ""}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (entry.imagePath != null && entry.imagePath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(entry.imagePath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(entry.content, style: const TextStyle(fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }
}