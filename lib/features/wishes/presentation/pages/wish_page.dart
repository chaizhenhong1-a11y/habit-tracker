import 'package:flutter/material.dart';

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
  static const _presetData = <Map<String, dynamic>>[
    {'emoji': '🍰', 'cost': 10, 'key': 'reward_dessert'},
    {'emoji': '🎬', 'cost': 20, 'key': 'reward_movie'},
    {'emoji': '🛍️', 'cost': 50, 'key': 'reward_gift'},
    {'emoji': '🍲', 'cost': 100, 'key': 'reward_feast'},
    {'emoji': '✈️', 'cost': 300, 'key': 'reward_trip'},
  ];

  static const _emojiList = <String>[
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

  Future<void> refreshPoints() => _controller.load();

  List<Reward> _presetRewards() {
    final loc = AppLocalizations.of(context);
    return _presetData.map((data) {
      return Reward(
        name: loc.translate(data['key'] as String) ?? data['key'] as String,
        emoji: data['emoji'] as String,
        cost: data['cost'] as int,
      );
    }).toList();
  }

  Future<void> _redeemReward(Reward reward) async {
    final loc = AppLocalizations.of(context);
    if (_controller.availablePoints < reward.cost) {
      _snack(loc.translate('notEnoughPoints') ?? '当前积分不足，再去打个卡吧！', error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          loc.translate('confirmRedeem') ?? '确认兑换',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reward.emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              '${loc.translate('spendPoints') ?? '确定花费'} ${reward.cost} ${loc.translate('pointsUnit') ?? '积分'}',
            ),
            Text(
              '「${reward.name}」${loc.translate('redeemQuestionSuffix') ?? '吗？'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.translate('cancel') ?? '取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.translate('confirm') ?? '确定'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    final redeemed = await _controller.redeem(reward);
    if (!mounted) return;
    if (redeemed) {
      _snack('${loc.translate('redeemedSuccess') ?? '成功兑换'}「${reward.name}」🎉');
    }
  }

  Future<void> _addWish() async {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final costController = TextEditingController();
    var selectedEmoji = '🎁';

    final reward = await showModalBottomSheet<Reward>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.translate('addWish') ?? '添加新愿望',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emojiList.length,
                    itemBuilder: (context, index) {
                      final emoji = _emojiList[index];
                      final selected = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedEmoji = emoji),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.grey.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: loc.translate('wishNameLabel') ?? '想实现什么愿望呢？',
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: loc.translate('targetPointsLabel') ?? '定个目标积分',
                    prefixIcon: const Icon(Icons.stars, color: Colors.amber),
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final cost = int.tryParse(costController.text.trim());
                      if (name.isEmpty || cost == null || cost <= 0) return;
                      Navigator.pop(
                        sheetContext,
                        Reward(name: name, emoji: selectedEmoji, cost: cost),
                      );
                    },
                    child: Text(loc.translate('publishWish') ?? '上架愿望单'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    nameController.dispose();
    costController.dispose();
    if (!mounted || reward == null) return;
    await _controller.addReward(reward);
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error
            ? Colors.redAccent.shade400
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _deleteReward(Reward reward) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.translate('deleteWish') ?? '删除愿望'),
        content: Text(
          '${loc.translate('confirmDeleteWish') ?? '确定从你的清单中移除'}「${reward.name}」?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.translate('cancel') ?? '取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.translate('delete') ?? '删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.deleteReward(reward);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final presetRewards = _presetRewards();

    return Scaffold(
      backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.2),
      appBar: AppBar(
        title: Text(
          loc.translate('wishShop') ?? '愿望商店',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    RedeemHistoryPage(history: _controller.redeemHistory),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshPoints,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary,
                    colors.primary.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    loc.translate('availablePoints') ?? '当前可用积分',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${_controller.availablePoints}',
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${loc.translate('totalEarned') ?? '累计赚取'} ${_controller.totalPoints} · '
                    '${loc.translate('spent') ?? '已用'} ${_controller.spentPoints}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _sectionHeader(loc.translate('presetRewards') ?? '官方精选'),
            const SizedBox(height: 12),
            _rewardGrid(presetRewards),
            const SizedBox(height: 32),
            _sectionHeader(
              loc.translate('myWishlist') ?? '我的愿望清单',
              onAdd: _addWish,
            ),
            const SizedBox(height: 12),
            if (_controller.customRewards.isEmpty)
              _empty()
            else
              _rewardGrid(_controller.customRewards, custom: true),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (onAdd != null)
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
      ],
    );
  }

  Widget _rewardGrid(List<Reward> rewards, {bool custom = false}) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.82,
      children: rewards
          .map((reward) => _rewardCard(reward, custom: custom))
          .toList(),
    );
  }

  Widget _rewardCard(Reward reward, {required bool custom}) {
    final colors = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final canAfford = _controller.availablePoints >= reward.cost;
    return GestureDetector(
      onLongPress: custom ? () => _deleteReward(reward) : null,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  '⭐ ${reward.cost}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(reward.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              Text(
                reward.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canAfford ? () => _redeemReward(reward) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: canAfford
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                  ),
                  child: Text(
                    canAfford
                        ? (loc.translate('redeem') ?? '兑换')
                        : (loc.translate('notEnoughPointsShort') ?? '积分不足'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(loc.translate('noWishesYet') ?? '还没有立下小Flag，快去添加吧'),
      ),
    );
  }
}

class RedeemHistoryPage extends StatelessWidget {
  const RedeemHistoryPage({super.key, required this.history});

  final List<RedeemRecord> history;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.2),
      appBar: AppBar(title: Text(loc.translate('redeemHistory') ?? '兑换足迹')),
      body: history.isEmpty
          ? Center(
              child: Text(loc.translate('noRedeemHistory') ?? '还没有兑换过任何奖励哦'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[index];
                return Card(
                  child: ListTile(
                    leading: Text(
                      record.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(record.rewardName),
                    subtitle: Text(
                      '${record.time.year}-${record.time.month.toString().padLeft(2, '0')}-'
                      '${record.time.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: Text(
                      '-${record.cost} ${loc.translate('pointsUnit') ?? '积分'}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
