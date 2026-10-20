import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../app/widgets/life_ui.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../habits/data/repositories/hive_habit_repository.dart';
import '../../application/wish_controller.dart';
import '../../data/repositories/shared_preferences_wish_repository.dart';
import '../../domain/entities/redeem_record.dart';
import '../../domain/entities/reward.dart';

class WishPage extends StatefulWidget {
  const WishPage({super.key});

  @override
  State<WishPage> createState() => WishPageState();
}

class WishPageState extends State<WishPage> {
  static const _presets = <Map<String, dynamic>>[
    {'emoji': '🍰', 'cost': 10, 'key': 'reward_dessert'},
    {'emoji': '🎬', 'cost': 20, 'key': 'reward_movie'},
    {'emoji': '🛍️', 'cost': 50, 'key': 'reward_gift'},
    {'emoji': '🍲', 'cost': 100, 'key': 'reward_feast'},
    {'emoji': '✈️', 'cost': 300, 'key': 'reward_trip'},
  ];

  static const _emojis = <String>[
    '🎁',
    '🎮',
    '🎧',
    '📱',
    '🎬',
    '☕',
    '🍰',
    '🍕',
    '🍲',
    '✈️',
    '📚',
    '🏃',
    '🎸',
    '🎨',
    '🛍️',
    '🍩',
    '🍿',
    '🎡',
    '💆',
    '👑',
  ];

  late final WishController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        WishController(
            repository: SharedPreferencesWishRepository(),
            habitRepository: HiveHabitRepository.fromHabitsBox(),
          )
          ..addListener(_changed)
          ..load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> refreshPoints() => _controller.load();

  List<Reward> _presetRewards() {
    final l = AppLocalizations.of(context);
    return _presets.map((preset) {
      final key = preset['key'] as String;
      return Reward(
        name: l.translate(key) ?? key,
        emoji: preset['emoji'] as String,
        cost: preset['cost'] as int,
      );
    }).toList();
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFF9E4D45) : null,
      ),
    );
  }

  Future<void> _redeem(Reward reward) async {
    final l = AppLocalizations.of(context);
    if (_controller.availablePoints < reward.cost) {
      _snack(
        l.translate('notEnoughPoints') ?? '当前积分不足，再去完成几个习惯吧。',
        error: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.translate('confirmRedeem') ?? '确认兑换'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reward.emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 14),
            Text(reward.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('${reward.cost} ${l.translate('pointsUnit') ?? '积分'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.translate('cancel') ?? '取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.translate('confirm') ?? '确定'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    if (await _controller.redeem(reward) && mounted) {
      _snack('${l.translate('redeemedSuccess') ?? '成功兑换'}「${reward.name}」');
    }
  }

  Future<void> _addWish() async {
    final l = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final costController = TextEditingController();
    var selectedEmoji = '🎁';

    final reward = await showModalBottomSheet<Reward>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final keyboard = MediaQuery.viewInsetsOf(context).bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: .72,
              minChildSize: .45,
              maxChildSize: .94,
              builder: (context, scrollController) => Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Text(
                      l.translate('addWish') ?? 'Create a reward',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).text('wishIntro'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            ...ScrollConfiguration.of(context).dragDevices,
                            PointerDeviceKind.mouse,
                          },
                        ),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _emojis.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final emoji = _emojis[index];
                            return ChoiceChip(
                              label: Text(
                                emoji,
                                style: const TextStyle(fontSize: 19),
                              ),
                              selected: selectedEmoji == emoji,
                              onSelected: (_) =>
                                  setSheetState(() => selectedEmoji = emoji),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText:
                            l.translate('wishNameLabel') ?? 'Reward name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: costController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText:
                            l.translate('targetPointsLabel') ?? 'Points needed',
                        prefixIcon: const Icon(Icons.auto_awesome_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final cost = int.tryParse(costController.text.trim());
                        if (name.isEmpty || cost == null || cost <= 0) return;
                        Navigator.pop(
                          sheetContext,
                          Reward(name: name, emoji: selectedEmoji, cost: cost),
                        );
                      },
                      child: Text(
                        l.translate('publishWish') ?? 'Add to journey',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    nameController.dispose();
    costController.dispose();
    if (!mounted || reward == null) return;
    await _controller.addReward(reward);
  }

  Future<void> _delete(Reward reward) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.translate('deleteWish') ?? 'Remove reward?'),
        content: Text(reward.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.translate('delete') ?? 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.deleteReward(reward);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final presets = _presetRewards();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: refreshPoints,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: LifePageHeader(
                    eyebrow: AppLocalizations.of(context).text('journeyLabel'),
                    title: AppLocalizations.of(context).text('journeyTitle'),
                    subtitle: AppLocalizations.of(context).text('journeyIntro'),
                    trailing: IconButton.filledTonal(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => RedeemHistoryPage(
                            history: _controller.redeemHistory,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.history_rounded),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _BalanceCard(
                    available: _controller.availablePoints,
                    total: _controller.totalPoints,
                    spent: _controller.spentPoints,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: LifeSectionTitle(
                    title: l.translate('presetRewards') ?? 'Curated rewards',
                    caption: AppLocalizations.of(context).text('rewardCaption'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: .9,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final reward = presets[index];
                    return _RewardCard(
                      reward: reward,
                      canAfford: _controller.availablePoints >= reward.cost,
                      onTap: () => _redeem(reward),
                    );
                  }, childCount: presets.length),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: LifeSectionTitle(
                    title: l.translate('myWishlist') ?? 'My milestones',
                    caption: AppLocalizations.of(
                      context,
                    ).text('wishlistCaption'),
                    action: TextButton.icon(
                      onPressed: _addWish,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(AppLocalizations.of(context).text('add')),
                    ),
                  ),
                ),
              ),
              if (_controller.customRewards.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
                  sliver: SliverToBoxAdapter(
                    child: LifeSurface(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                              size: 32,
                              color: Color(0xFF315D43),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l.translate('noWishesYet') ??
                                  'Create a reward for your next milestone.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: .9,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final reward = _controller.customRewards[index];
                      return _RewardCard(
                        reward: reward,
                        canAfford: _controller.availablePoints >= reward.cost,
                        onTap: () => _redeem(reward),
                        onLongPress: () => _delete(reward),
                      );
                    }, childCount: _controller.customRewards.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.available,
    required this.total,
    required this.spent,
  });

  final int available;
  final int total;
  final int spent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173F2D), Color(0xFF315D43)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173E2D).withValues(alpha: .18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).text('growthPoints'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$available',
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 48,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 5),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFE2C58A),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: AppLocalizations.of(context).text('earnedLabel'),
                  value: '$total',
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _Stat(
                  label: AppLocalizations.of(context).text('spentLabel'),
                  value: '$spent',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .58),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.canAfford,
    required this.onTap,
    this.onLongPress,
  });

  final Reward reward;
  final bool canAfford;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canAfford ? onTap : null,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF171F19) : const Color(0xFFFFFCF6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF315D43).withValues(alpha: .1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2C58A).withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${reward.cost} ✦',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8C682C),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(reward.emoji, style: const TextStyle(fontSize: 38)),
              const SizedBox(height: 9),
              Text(
                reward.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                canAfford
                    ? AppLocalizations.of(context).text('rewardReady')
                    : AppLocalizations.of(context).text('keepBuilding'),
                style: TextStyle(
                  fontSize: 11,
                  color: canAfford
                      ? const Color(0xFF315D43)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RedeemHistoryPage extends StatelessWidget {
  const RedeemHistoryPage({super.key, required this.history});

  final List<RedeemRecord> history;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('redeemHistory') ?? 'Reward history'),
      ),
      body: history.isEmpty
          ? Center(
              child: Text(
                l.translate('noRedeemHistory') ?? 'No rewards redeemed yet.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final record = history[index];
                final date =
                    '${record.time.year}-'
                    '${record.time.month.toString().padLeft(2, '0')}-'
                    '${record.time.day.toString().padLeft(2, '0')}';
                return LifeSurface(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      record.emoji,
                      style: const TextStyle(fontSize: 27),
                    ),
                    title: Text(
                      record.rewardName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(date),
                    trailing: Text(
                      '-${record.cost} ✦',
                      style: const TextStyle(
                        color: Color(0xFFB07858),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
