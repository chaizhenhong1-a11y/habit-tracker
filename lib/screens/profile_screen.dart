import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/habit_service.dart';
import '../services/notification_service.dart';
import 'diary_screen.dart';
import 'plan_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final Color seedColor;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Color> onSeedColorChanged;
  final VoidCallback onLogout;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  const ProfileScreen({
    super.key,
    required this.themeMode,
    required this.seedColor,
    required this.onThemeModeChanged,
    required this.onSeedColorChanged,
    required this.onLogout,
    required this.locale,
    required this.onLocaleChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  String _username = '用户';
  String _avatarUrl = '';
  File? _avatarFile;
  final ImagePicker _picker = ImagePicker();

  static const List<Color> _themeColors = [
    Color(0xFF6C63FF),
    Color(0xFF4CAF50),
    Color(0xFFFF7043),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFF9C27B0),
    Color(0xFFFFC107),
    Color(0xFF795548),
  ];

  static const List<String> _presetAvatars = [
    'assets/images/如花.png',
    'assets/images/坤哥.png',
    'assets/images/小女孩.png',
    'assets/images/油腻大叔.png',
    'assets/images/秃头.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminderEnabled = prefs.getBool('reminder_enabled') ?? false;
      final hour = prefs.getInt('reminder_hour') ?? 20;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
      _username = prefs.getString('username') ?? '用户';
      _avatarUrl = prefs.getString('avatar_url') ?? '';
      final localPath = prefs.getString('avatar_local_path');
      if (localPath != null && !kIsWeb) {
        final file = File(localPath);
        if (file.existsSync()) {
          _avatarFile = file;
          _avatarUrl = '';
        }
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', _reminderEnabled);
    await prefs.setInt('reminder_hour', _reminderTime.hour);
    await prefs.setInt('reminder_minute', _reminderTime.minute);
    await prefs.setString('username', _username);
    await prefs.setString('avatar_url', _avatarUrl);
    await prefs.setString('avatar_local_path', _avatarFile?.path ?? '');
  }

  Future<void> _toggleReminder(bool value) async {
    setState(() {
      _reminderEnabled = value;
    });
    await _saveSettings();
    final notificationService = NotificationService();
    if (_reminderEnabled) {
      await notificationService.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
        enabled: true,
      );
    } else {
      await notificationService.cancelAll();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _reminderTime) {
      setState(() => _reminderTime = picked);
      await _saveSettings();
      if (_reminderEnabled) {
        await NotificationService().scheduleDailyReminder(
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
          enabled: true,
        );
      }
    }
  }

  Future<void> _exportData() async {
    final loc = AppLocalizations.of(context);
    final habits = HabitService().getAllHabits();
    final jsonList = habits.map((h) => h.toMap()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
    await Clipboard.setData(ClipboardData(text: jsonString));
    if (!mounted) return;

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(loc.translate('dataCopied') ?? '数据已完美复制到剪贴板！'),
          ],
        ),
      ),
    );
  }

  Future<void> _editUsername() async {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController(text: _username);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.translate('editUsername') ?? '修改用户名',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: loc.translate('editUsernameHint') ?? '请输入用户名',
            filled: true,
            fillColor: Theme.of(
              ctx,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.translate('cancel') ?? '取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(loc.translate('save') ?? '保存'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _username = result);
      await _saveSettings();
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _avatarFile = File(image.path);
          _avatarUrl = '';
        });
        await _saveSettings();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _avatarFile = File(image.path);
          _avatarUrl = '';
        });
        await _saveSettings();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('拍照失败: $e')));
    }
  }

  void _changeAvatar() {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  loc.translate('changeAvatar') ?? '更换头像',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (!kIsWeb) ...[
                  _buildBottomSheetAction(
                    Icons.photo_library_outlined,
                    loc.translate('fromGallery') ?? '从相册选择',
                    () {
                      Navigator.pop(ctx);
                      _pickFromGallery();
                    },
                  ),
                  _buildBottomSheetAction(
                    Icons.camera_alt_outlined,
                    loc.translate('takePhoto') ?? '拍照',
                    () {
                      Navigator.pop(ctx);
                      _takePhoto();
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Text(
                      loc.translate('presetAvatars') ?? '预设艺术头像',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _presetAvatars.map((path) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: 14,
                          top: 4,
                          bottom: 4,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _avatarUrl = path;
                              _avatarFile = null;
                            });
                            _saveSettings();
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: AssetImage(path),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildBottomSheetAction(
                  Icons.link_rounded,
                  loc.translate('useNetworkImage') ?? '使用网络图片链接',
                  () async {
                    Navigator.pop(ctx);
                    final controller = TextEditingController();
                    final url = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          loc.translate('imageUrlDialogTitle') ?? '图片 URL 链接',
                        ),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'https://...',
                          ),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(loc.translate('cancel') ?? '取消'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(ctx, controller.text.trim()),
                            child: Text(loc.translate('confirm') ?? '确定'),
                          ),
                        ],
                      ),
                    );
                    if (url != null && url.isNotEmpty) {
                      setState(() {
                        _avatarUrl = url;
                        _avatarFile = null;
                      });
                      await _saveSettings();
                    }
                  },
                ),
                _buildBottomSheetAction(
                  Icons.refresh_rounded,
                  loc.translate('resetAvatar') ?? '恢复默认头像',
                  () {
                    setState(() {
                      _avatarUrl = '';
                      _avatarFile = null;
                    });
                    _saveSettings();
                    Navigator.pop(ctx);
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetAction(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.redAccent
        : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      horizontalTitleGap: 12,
      onTap: onTap,
    );
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider;
    if (_avatarFile != null && !kIsWeb) {
      imageProvider = FileImage(_avatarFile!);
    } else if (_avatarUrl.isNotEmpty) {
      imageProvider = _avatarUrl.startsWith('http')
          ? NetworkImage(_avatarUrl)
          : AssetImage(_avatarUrl) as ImageProvider;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.seedColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    _username.isNotEmpty ? _username[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    final displayName = (_username == '用户' || _username.isEmpty)
        ? (loc.translate('defaultUser') ?? '用户')
        : _username;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            centerTitle: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 2,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.seedColor.withOpacity(0.25),
                      widget.seedColor.withOpacity(0.02),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    GestureDetector(
                      onTap: _changeAvatar,
                      child: _buildAvatar(),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _editUsername,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit_note_rounded,
                            size: 20,
                            color: widget.seedColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.translate('tapToChangeAvatar') ?? '点击更换头像',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      loc.translate('personalization') ?? '个性视觉',
                    ),
                    _buildGroupContainer([
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.palette_outlined,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  loc.translate('applyThemeColor') ?? '应用色彩主题',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: _themeColors.map((color) {
                                final isSelected =
                                    widget.seedColor.value == color.value;
                                return GestureDetector(
                                  onTap: () => widget.onSeedColorChanged(color),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: color.withOpacity(0.4),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : [],
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.surface
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 18,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 16),
                      _buildRowAction(
                        icon: Icons.light_mode_outlined,
                        title: loc.translate('lightMode') ?? '浅色模式',
                        trailing: widget.themeMode == ThemeMode.light
                            ? _buildCheckedIcon()
                            : null,
                        onTap: () => widget.onThemeModeChanged(ThemeMode.light),
                      ),
                      _buildRowAction(
                        icon: Icons.dark_mode_outlined,
                        title: loc.translate('darkMode') ?? '深色模式',
                        trailing: widget.themeMode == ThemeMode.dark
                            ? _buildCheckedIcon()
                            : null,
                        onTap: () => widget.onThemeModeChanged(ThemeMode.dark),
                      ),
                      _buildRowAction(
                        icon: Icons.settings_suggest_outlined,
                        title: loc.translate('systemMode') ?? '跟随系统',
                        trailing: widget.themeMode == ThemeMode.system
                            ? _buildCheckedIcon()
                            : null,
                        onTap: () =>
                            widget.onThemeModeChanged(ThemeMode.system),
                      ),
                    ]),

                    _buildSectionTitle(
                      loc.translate('language') ?? '语言 / Language',
                    ),
                    _buildGroupContainer([
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.language,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  loc.translate('language') ?? 'Language',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _LanguageOption(
                              title: loc.translate('chinese') ?? '中文',
                              selected: widget.locale.languageCode == 'zh',
                              onTap: () =>
                                  widget.onLocaleChanged(const Locale('zh')),
                            ),
                            _LanguageOption(
                              title: loc.translate('english') ?? 'English',
                              selected: widget.locale.languageCode == 'en',
                              onTap: () =>
                                  widget.onLocaleChanged(const Locale('en')),
                            ),
                          ],
                        ),
                      ),
                    ]),

                    _buildSectionTitle(
                      loc.translate('coreEfficiency') ?? '核心效率',
                    ),
                    _buildGroupContainer([
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: Icon(
                            Icons.notifications_active_outlined,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            loc.translate('dailyReminder') ?? '每日打卡提醒',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          value: _reminderEnabled,
                          activeColor: widget.seedColor,
                          onChanged: _toggleReminder,
                        ),
                      ),
                      if (_reminderEnabled) ...[
                        const Divider(height: 1, indent: 56),
                        _buildRowAction(
                          icon: Icons.access_time_rounded,
                          title: loc.translate('reminderTime') ?? '提醒时间',
                          trailing: Text(
                            _reminderTime.format(context),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          onTap: _pickTime,
                        ),
                      ],
                    ]),

                    _buildSectionTitle(loc.translate('dataCenter') ?? '数据中心'),
                    _buildGroupContainer([
                      _buildRowAction(
                        icon: Icons.event_note_rounded,
                        title: loc.translate('plan') ?? '我的计划',
                        subtitle:
                            loc.translate('planSubtitle') ?? '管理日常待办和习惯阶段目标',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlanScreen()),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildRowAction(
                        icon: Icons.book_outlined,
                        title: loc.translate('diary') ?? '我的日记',
                        subtitle:
                            loc.translate('diarySubtitle') ?? '记录生活碎念与复盘随笔',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DiaryScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildRowAction(
                        icon: Icons.cloud_upload_outlined,
                        title: loc.translate('exportData') ?? '导出所有习惯数据',
                        subtitle:
                            loc.translate('exportDataSubtitle') ??
                            '单击以标准 JSON 格式进行数据备份',
                        onTap: _exportData,
                      ),
                    ]),

                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh.withOpacity(
                          0.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              loc.translate('infoReminder') ??
                                  '提醒功能需在手机端保持后台以便弹出通知。Web 端由于浏览器限制，暂无法支持桌面弹窗。',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant.withOpacity(
                                  0.7,
                                ),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: Colors.red.withOpacity(0.08),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('is_logged_in', false);
                        widget.onLogout();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            loc.translate('logout') ?? '退出登录账户',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 24, 0, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRowAction({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            )
          : null,
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
      horizontalTitleGap: 14,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  Widget _buildCheckedIcon() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: widget.seedColor.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle_rounded,
        color: widget.seedColor,
        size: 20,
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
