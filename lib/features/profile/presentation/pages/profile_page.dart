import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/widgets/life_ui.dart';
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
    _controller = ProfileController(
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
    final controller = TextEditingController(
      text: _controller.settings.username,
    );
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.translate('editUsername') ?? '修改用户名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: loc.translate('editUsernameHint') ?? '请输入用户名',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.translate('cancel') ?? '取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: Text(loc.translate('save') ?? '保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || value == null || value.isEmpty) return;
    await _controller.setUsername(value);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        await _controller.setAvatarLocalPath(image.path);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $error')),
      );
    }
  }

  Future<void> _promptNetworkAvatar() async {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.translate('imageUrlDialogTitle') ?? '图片 URL 链接'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'https://...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.translate('cancel') ?? '取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: Text(loc.translate('confirm') ?? '确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || value == null || value.isEmpty) return;
    await _controller.setAvatarAssetOrUrl(value);
  }

  void _changeAvatar() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                loc.translate('changeAvatar') ?? '更换头像',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
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
              ],
              const SizedBox(height: 10),
              Text(
                loc.translate('presetAvatars') ?? '预设艺术头像',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final assetPath in _presetAvatars)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
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
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }

  Future<void> _pickReminderTime() async {
    final current = TimeOfDay(
      hour: _controller.settings.reminderHour,
      minute: _controller.settings.reminderMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (!mounted || picked == null || picked == current) return;
    await _controller.setReminderTime(
      hour: picked.hour,
      minute: picked.minute,
    );
  }

  Future<void> _exportData() async {
    final loc = AppLocalizations.of(context);
    await Clipboard.setData(
      ClipboardData(text: _controller.exportHabitsJson()),
    );
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loc.translate('dataCopied') ?? '数据已复制到剪贴板',
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

  Widget _avatar() {
    final provider = _avatarProvider();
    final username = _controller.settings.username;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 92,
          height: 92,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF3E4BF),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF315D43),
            backgroundImage: provider,
            child: provider == null
                ? Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 34,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          right: -2,
          bottom: 2,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF6),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF315D43).withValues(alpha: .15),
              ),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 15,
              color: Color(0xFF173F30),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final settings = _controller.settings;
    final displayName =
        settings.username == '用户' || settings.username.isEmpty
            ? (loc.translate('defaultUser') ?? '用户')
            : settings.username;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              sliver: SliverToBoxAdapter(
                child: LifePageHeader(
                  eyebrow: 'YOU',
                  title: 'Your life,\nmade intentional.',
                  subtitle:
                      'Shape the space around your habits and keep what matters close.',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF173F2D), Color(0xFF315D43)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _changeAvatar,
                        child: _avatar(),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: GestureDetector(
                          onTap: _editUsername,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                loc.translate('tapToChangeAvatar') ??
                                    '点击头像更换 · 点击名字编辑',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.white.withValues(alpha: .62),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _editUsername,
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFFE2C58A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 130),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  LifeSectionTitle(
                    title:
                        loc.translate('personalization') ?? 'Personalization',
                    caption: 'Choose how this space feels day to day',
                  ),
                  const SizedBox(height: 12),
                  _group([
                    _rowAction(
                      icon: Icons.light_mode_outlined,
                      title: loc.translate('lightMode') ?? '浅色模式',
                      trailing: widget.themeMode == ThemeMode.light
                          ? _checkedIcon()
                          : null,
                      onTap: () =>
                          widget.onThemeModeChanged(ThemeMode.light),
                    ),
                    _rowAction(
                      icon: Icons.dark_mode_outlined,
                      title: loc.translate('darkMode') ?? '深色模式',
                      trailing: widget.themeMode == ThemeMode.dark
                          ? _checkedIcon()
                          : null,
                      onTap: () =>
                          widget.onThemeModeChanged(ThemeMode.dark),
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
                  const SizedBox(height: 26),
                  LifeSectionTitle(
                    title: loc.translate('language') ?? 'Language',
                    caption: 'Choose how Habit speaks to you',
                  ),
                  const SizedBox(height: 12),
                  _group([
                    _languageOption(
                      '中文',
                      widget.locale.languageCode == 'zh',
                      () => widget.onLocaleChanged(const Locale('zh')),
                    ),
                    _languageOption(
                      'English',
                      widget.locale.languageCode == 'en',
                      () => widget.onLocaleChanged(const Locale('en')),
                    ),
                  ]),
                  const SizedBox(height: 26),
                  LifeSectionTitle(
                    title:
                        loc.translate('coreEfficiency') ?? 'Daily rhythm',
                    caption: 'Gentle structure for the life you want',
                  ),
                  const SizedBox(height: 12),
                  _group([
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFF315D43),
                      ),
                      title: Text(
                        loc.translate('dailyReminder') ?? '每日打卡提醒',
                      ),
                      value: settings.reminderEnabled,
                      onChanged: _controller.setReminderEnabled,
                    ),
                    if (settings.reminderEnabled)
                      _rowAction(
                        icon: Icons.access_time_rounded,
                        title:
                            loc.translate('reminderTime') ?? '提醒时间',
                        trailing: Text(
                          TimeOfDay(
                            hour: settings.reminderHour,
                            minute: settings.reminderMinute,
                          ).format(context),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF315D43),
                          ),
                        ),
                        onTap: _pickReminderTime,
                      ),
                  ]),
                  const SizedBox(height: 26),
                  LifeSectionTitle(
                    title: loc.translate('dataCenter') ?? 'Your space',
                    caption: 'Plans, reflections and your own data',
                  ),
                  const SizedBox(height: 12),
                  _group([
                    _rowAction(
                      icon: Icons.event_note_rounded,
                      title: loc.translate('plan') ?? '我的计划',
                      subtitle: loc.translate('planSubtitle') ??
                          '管理日常待办和习惯阶段目标',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const PlanPage(),
                        ),
                      ),
                    ),
                    _rowAction(
                      icon: Icons.auto_stories_outlined,
                      title: loc.translate('diary') ?? '我的日记',
                      subtitle: loc.translate('diarySubtitle') ??
                          '记录生活碎念与复盘随笔',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const DiaryPage(),
                        ),
                      ),
                    ),
                    _rowAction(
                      icon: Icons.ios_share_rounded,
                      title: loc.translate('exportData') ?? '导出所有习惯数据',
                      subtitle: loc.translate('exportDataSubtitle') ??
                          '以 JSON 格式备份你的数据',
                      onTap: _exportData,
                    ),
                  ]),
                  const SizedBox(height: 26),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      foregroundColor: const Color(0xFF9E4D45),
                      backgroundColor:
                          const Color(0xFF9E4D45).withValues(alpha: .07),
                    ),
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(
                      loc.translate('logout') ?? '退出登录账户',
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return LifeSurface(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _rowAction({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF315D43).withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF315D43),
          size: 19,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing:
          trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  Widget _checkedIcon() => const Icon(
        Icons.check_circle_rounded,
        color: Color(0xFF315D43),
        size: 20,
      );

  Widget _languageOption(
    String title,
    bool selected,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: selected ? _checkedIcon() : null,
      onTap: onTap,
    );
  }
}
