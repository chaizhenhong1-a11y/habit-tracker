import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../diary/presentation/pages/diary_page.dart';
import '../../../habits/data/repositories/hive_habit_repository.dart';
import '../../../plans/presentation/pages/plan_page.dart';
import '../../application/profile_controller.dart';
import '../../data/repositories/shared_preferences_profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.themeMode,
    required this.seedColor,
    required this.onThemeModeChanged,
    required this.onSeedColorChanged,
    required this.onLogout,
    required this.locale,
    required this.onLocaleChanged,
  });

  final ThemeMode themeMode;
  final Color seedColor;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Color> onSeedColorChanged;
  final VoidCallback onLogout;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _themeColors = <Color>[
    Color(0xFF6C63FF),
    Color(0xFF4CAF50),
    Color(0xFFFF7043),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFF9C27B0),
    Color(0xFFFFC107),
    Color(0xFF795548),
  ];

  static const _presetAvatars = <String>[
    'assets/images/如花.png',
    'assets/images/坤哥.png',
    'assets/images/小女孩.png',
    'assets/images/油腻大叔.png',
    'assets/images/秃头.png',
  ];

  late final ProfileController _controller;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller =
        ProfileController(
            repository: SharedPreferencesProfileRepository(),
            habitRepository: HiveHabitRepository.fromHabitsBox(),
          )
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

  Future<void> _editUsername() async {
    final loc = AppLocalizations.of(context);
    final textController = TextEditingController(
      text: _controller.settings.username,
    );
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.translate('editUsername') ?? '修改用户名',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: loc.translate('editUsernameHint') ?? '请输入用户名',
            filled: true,
            fillColor: Theme.of(
              dialogContext,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.translate('cancel') ?? '取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, textController.text.trim());
            },
            child: Text(loc.translate('save') ?? '保存'),
          ),
        ],
      ),
    );
    textController.dispose();

    if (!mounted || value == null || value.isEmpty) return;
    await _controller.setUsername(value);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        await _controller.setAvatarLocalPath(image.path);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择图片失败: $error')));
    }
  }

  Future<void> _promptNetworkAvatar() async {
    final loc = AppLocalizations.of(context);
    final textController = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.translate('imageUrlDialogTitle') ?? '图片 URL 链接'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'https://...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.translate('cancel') ?? '取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, textController.text.trim()),
            child: Text(loc.translate('confirm') ?? '确定'),
          ),
        ],
      ),
    );
    textController.dispose();

    if (!mounted || value == null || value.isEmpty) return;
    await _controller.setAvatarAssetOrUrl(value);
  }

  void _changeAvatar() {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
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
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
                _sheetAction(
                  icon: Icons.photo_library_outlined,
                  title: loc.translate('fromGallery') ?? '从相册选择',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _sheetAction(
                  icon: Icons.camera_alt_outlined,
                  title: loc.translate('takePhoto') ?? '拍照',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Divider(),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Text(
                    loc.translate('presetAvatars') ?? '预设艺术头像',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _presetAvatars.map((assetPath) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _controller.setAvatarAssetOrUrl(assetPath);
                        },
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: AssetImage(assetPath),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 24),
              _sheetAction(
                icon: Icons.link_rounded,
                title: loc.translate('useNetworkImage') ?? '使用网络图片链接',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _promptNetworkAvatar();
                },
              ),
              _sheetAction(
                icon: Icons.refresh_rounded,
                title: loc.translate('resetAvatar') ?? '恢复默认头像',
                destructive: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _controller.resetAvatar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive
        ? Colors.redAccent
        : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  Future<void> _pickReminderTime() async {
    final current = TimeOfDay(
      hour: _controller.settings.reminderHour,
      minute: _controller.settings.reminderMinute,
    );
    final picked = await showTimePicker(context: context, initialTime: current);
    if (!mounted || picked == null || picked == current) return;
    await _controller.setReminderTime(hour: picked.hour, minute: picked.minute);
  }

  Future<void> _exportData() async {
    final loc = AppLocalizations.of(context);
    final payload = _controller.exportHabitsJson();
    await Clipboard.setData(ClipboardData(text: payload));
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
            Expanded(
              child: Text(loc.translate('dataCopied') ?? '数据已完美复制到剪贴板！'),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object>? _avatarProvider() {
    final settings = _controller.settings;

    if (!kIsWeb && settings.avatarLocalPath.isNotEmpty) {
      final file = File(settings.avatarLocalPath);
      if (file.existsSync()) return FileImage(file);
    }

    if (settings.avatarUrl.isEmpty) return null;
    if (settings.avatarUrl.startsWith('http')) {
      return NetworkImage(settings.avatarUrl);
    }
    return AssetImage(settings.avatarUrl);
  }

  Widget _buildAvatar() {
    final imageProvider = _avatarProvider();
    final username = _controller.settings.username;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.seedColor.withValues(alpha: 0.3),
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
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
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
    final settings = _controller.settings;
    final displayName = settings.username == '用户' || settings.username.isEmpty
        ? (loc.translate('defaultUser') ?? '用户')
        : settings.username;

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
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.seedColor.withValues(alpha: 0.25),
                      widget.seedColor.withValues(alpha: 0.02),
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
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
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
                    _sectionTitle(loc.translate('personalization') ?? '个性视觉'),
                    _group([
                      Padding(
                        padding: const EdgeInsets.all(16),
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
                                  style: const TextStyle(
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
                                final selected =
                                    widget.seedColor.toARGB32() ==
                                    color.toARGB32();
                                return GestureDetector(
                                  onTap: () => widget.onSeedColorChanged(color),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selected
                                            ? colorScheme.surface
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: color.withValues(
                                                  alpha: 0.4,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: selected
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
                      _rowAction(
                        icon: Icons.light_mode_outlined,
                        title: loc.translate('lightMode') ?? '浅色模式',
                        trailing: widget.themeMode == ThemeMode.light
                            ? _checkedIcon()
                            : null,
                        onTap: () => widget.onThemeModeChanged(ThemeMode.light),
                      ),
                      _rowAction(
                        icon: Icons.dark_mode_outlined,
                        title: loc.translate('darkMode') ?? '深色模式',
                        trailing: widget.themeMode == ThemeMode.dark
                            ? _checkedIcon()
                            : null,
                        onTap: () => widget.onThemeModeChanged(ThemeMode.dark),
                      ),
                      _rowAction(
                        icon: Icons.settings_suggest_outlined,
                        title: loc.translate('systemMode') ?? '跟随系统',
                        trailing: widget.themeMode == ThemeMode.system
                            ? _checkedIcon()
                            : null,
                        onTap: () =>
                            widget.onThemeModeChanged(ThemeMode.system),
                      ),
                    ]),
                    _sectionTitle(loc.translate('language') ?? '语言 / Language'),
                    _group([
                      _languageOption(
                        loc.translate('chinese') ?? '中文',
                        widget.locale.languageCode == 'zh',
                        () => widget.onLocaleChanged(const Locale('zh')),
                      ),
                      _languageOption(
                        loc.translate('english') ?? 'English',
                        widget.locale.languageCode == 'en',
                        () => widget.onLocaleChanged(const Locale('en')),
                      ),
                    ]),
                    _sectionTitle(loc.translate('coreEfficiency') ?? '核心效率'),
                    _group([
                      SwitchListTile(
                        secondary: Icon(
                          Icons.notifications_active_outlined,
                          color: colorScheme.primary,
                        ),
                        title: Text(loc.translate('dailyReminder') ?? '每日打卡提醒'),
                        value: settings.reminderEnabled,
                        activeThumbColor: widget.seedColor,
                        onChanged: _controller.setReminderEnabled,
                      ),
                      if (settings.reminderEnabled) ...[
                        const Divider(height: 1, indent: 56),
                        _rowAction(
                          icon: Icons.access_time_rounded,
                          title: loc.translate('reminderTime') ?? '提醒时间',
                          trailing: Text(
                            TimeOfDay(
                              hour: settings.reminderHour,
                              minute: settings.reminderMinute,
                            ).format(context),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: _pickReminderTime,
                        ),
                      ],
                    ]),
                    _sectionTitle(loc.translate('dataCenter') ?? '数据中心'),
                    _group([
                      _rowAction(
                        icon: Icons.event_note_rounded,
                        title: loc.translate('plan') ?? '我的计划',
                        subtitle:
                            loc.translate('planSubtitle') ?? '管理日常待办和习惯阶段目标',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const PlanPage(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _rowAction(
                        icon: Icons.book_outlined,
                        title: loc.translate('diary') ?? '我的日记',
                        subtitle:
                            loc.translate('diarySubtitle') ?? '记录生活碎念与复盘随笔',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const DiaryPage(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _rowAction(
                        icon: Icons.cloud_upload_outlined,
                        title: loc.translate('exportData') ?? '导出所有习惯数据',
                        subtitle:
                            loc.translate('exportDataSubtitle') ??
                            '单击以标准 JSON 格式进行数据备份',
                        onTap: _exportData,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: Colors.red.withValues(alpha: 0.08),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: widget.onLogout,
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 24, 0, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _group(List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _rowAction({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  Widget _checkedIcon() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: widget.seedColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle_rounded,
        color: widget.seedColor,
        size: 20,
      ),
    );
  }

  Widget _languageOption(String title, bool selected, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: selected
          ? Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}
