import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/habit_service.dart';

class Reward {
  final String name;
  final String emoji;
  final int cost;

  Reward({required this.name, required this.emoji, required this.cost});

  Map<String, dynamic> toJson() => {'name': name, 'emoji': emoji, 'cost': cost};
  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        cost: json['cost'] as int,
      );
}

class RedeemRecord {
  final String rewardName;
  final String emoji;
  final int cost;
  final DateTime time;

  RedeemRecord({required this.rewardName, required this.emoji, required this.cost, required this.time});

  Map<String, dynamic> toJson() => {
        'rewardName': rewardName,
        'emoji': emoji,
        'cost': cost,
        'time': time.toIso8601String(),
      };

  factory RedeemRecord.fromJson(Map<String, dynamic> json) => RedeemRecord(
        rewardName: json['rewardName'] as String,
        emoji: json['emoji'] as String,
        cost: json['cost'] as int,
        time: DateTime.parse(json['time'] as String),
      );
}

class WishScreen extends StatefulWidget {
  const WishScreen({super.key});

  @override
  State<WishScreen> createState() => WishScreenState();
}

class WishScreenState extends State<WishScreen> {
  int _spentPoints = 0;
  List<Reward> _customRewards = [];
  List<RedeemRecord> _redeemHistory = [];

  // 预设奖励的原始数据（名称将使用翻译键动态替换）
  static const List<Map<String, dynamic>> _presetData = [
    {'emoji': '🍰', 'cost': 10, 'key': 'reward_dessert'},
    {'emoji': '🎬', 'cost': 20, 'key': 'reward_movie'},
    {'emoji': '🛍️', 'cost': 50, 'key': 'reward_gift'},
    {'emoji': '🍲', 'cost': 100, 'key': 'reward_feast'},
    {'emoji': '✈️', 'cost': 300, 'key': 'reward_trip'},
  ];

  final List<String> _emojiList = [
    '🎁', '🎮', '🎧', '📱', '🎬', '☕', '🍰', '🍕', '🍲', '✈️',
    '📚', '🏃', '🎸', '🎨', '🛍️', '🍩', '🍿', '🎡', '💆', '👑'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void refreshPoints() => _loadData();

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _spentPoints = prefs.getInt('spent_points') ?? 0;
      _customRewards = (prefs.getStringList('custom_rewards') ?? []).map((jsonStr) {
        return Reward.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      }).toList();
      _redeemHistory = (prefs.getStringList('redeem_history') ?? []).map((jsonStr) {
        return RedeemRecord.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      }).toList();
      _redeemHistory.sort((a, b) => b.time.compareTo(a.time));
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('spent_points', _spentPoints);
    await prefs.setStringList('custom_rewards', _customRewards.map((r) => jsonEncode(r.toJson())).toList());
    await prefs.setStringList('redeem_history', _redeemHistory.map((r) => jsonEncode(r.toJson())).toList());
  }

  int _getTotalPoints() {
    final habits = HabitService().getAllHabits();
    int total = 0;
    for (var habit in habits) {
      total += habit.completedDates.length;
    }
    return total;
  }

  int get _availablePoints => _getTotalPoints() - _spentPoints;

  Future<void> _redeemReward(Reward reward) async {
    final loc = AppLocalizations.of(context);
    if (_availablePoints < reward.cost) {
      _showCustomSnackBar(loc.translate('notEnoughPoints') ?? '当前积分不足，再去打个卡吧！', isError: true);
      return;
    }

    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondAnim, child) {
        return Transform.scale(
          scale: Curves.easeInOutBack.transform(anim.value),
          child: AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(
              loc.translate('confirmRedeem') ?? '确认兑换',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reward.emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(
                  '${loc.translate('spendPoints') ?? '确定花费'} ${reward.cost} ${loc.translate('pointsUnit') ?? '积分'}${loc.translate('redeemQuestion') ?? ''}',
                  style: const TextStyle(fontSize: 15),
                ),
                Text('「${reward.name}」${loc.translate('redeemQuestionSuffix') ?? '吗？'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  loc.translate('cancel') ?? '取消',
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  loc.translate('confirm') ?? '确定',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _spentPoints += reward.cost;
        _redeemHistory.insert(0, RedeemRecord(
          rewardName: reward.name,
          emoji: reward.emoji,
          cost: reward.cost,
          time: DateTime.now(),
        ));
      });
      await _saveData();
      _showCustomSnackBar('${loc.translate('redeemedSuccess') ?? '成功兑换'}「${reward.name}」🎉');
    }
  }

  void _showAddWishBottomSheet() {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final costController = TextEditingController();
    String selectedEmoji = '🎁';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            top: 24, left: 24, right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.translate('addWish') ?? '添加新愿望',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.translate('chooseIcon') ?? '选择一个好看的图标',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _emojiList.length,
                    itemBuilder: (context, idx) {
                      final emoji = _emojiList[idx];
                      final isSelected = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedEmoji = emoji),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.withOpacity(0.06),
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5) : null,
                          ),
                          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
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
                    hintText: loc.translate('wishHint') ?? '如：喝一杯奶茶',
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: loc.translate('targetPointsLabel') ?? '定个目标积分',
                    hintText: loc.translate('positiveInteger') ?? '输入正整数',
                    prefixIcon: const Icon(Icons.stars, color: Colors.amber, size: 20),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final costText = costController.text.trim();
                      final cost = int.tryParse(costText);
                      if (name.isEmpty || cost == null || cost <= 0) {
                        _showCustomSnackBar(
                          loc.translate('invalidWishInput') ?? '请填写正确的名称与积分目标',
                          isError: true,
                        );
                        return;
                      }
                      Navigator.pop(context, Reward(name: name, emoji: selectedEmoji, cost: cost));
                    },
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text(
                      loc.translate('publishWish') ?? '上架愿望单',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((value) async {
      if (value != null && value is Reward) {
        setState(() => _customRewards.add(value));
        await _saveData();
      }
    });
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent.shade400 : Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // 动态生成本地化后的预设奖励列表
  List<Reward> _getPresetRewards() {
    final loc = AppLocalizations.of(context);
    return _presetData.map((data) => Reward(
      name: loc.translate(data['key'] as String) ?? data['key'] as String,
      emoji: data['emoji'] as String,
      cost: data['cost'] as int,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    final presetRewards = _getPresetRewards();  // 获取翻译后的预设奖励

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.2),
      appBar: AppBar(
        title: Text(
          loc.translate('wishShop') ?? '愿望商店',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: colorScheme.surface, shape: BoxShape.circle),
              child: Icon(Icons.history_rounded, color: colorScheme.primary, size: 20),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RedeemHistoryPage(history: _redeemHistory)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => refreshPoints(),
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 积分卡片
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.85)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: const Icon(Icons.stars, color: Colors.amber, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loc.translate('availablePoints') ?? '当前可用积分',
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_availablePoints',
                    style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${loc.translate('totalEarned') ?? '累计赚取'} ${_getTotalPoints()}  ·  ${loc.translate('spent') ?? '已用'} $_spentPoints',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 预设奖励
            _buildSectionHeader(loc.translate('presetRewards') ?? '官方精选', null),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
              children: presetRewards.map((reward) => _buildGridRewardCard(reward)).toList(),
            ),
            const SizedBox(height: 32),

            // 自定义愿望
            _buildSectionHeader(loc.translate('myWishlist') ?? '我的愿望清单', _showAddWishBottomSheet),
            const SizedBox(height: 12),
            if (_customRewards.isEmpty)
              _buildEmptyWidget()
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
                children: _customRewards.map((reward) => _buildGridRewardCard(reward, isCustom: true)).toList(),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        if (onAction != null)
          IconButton(
            onPressed: onAction,
            icon: Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
          )
      ],
    );
  }

  Widget _buildEmptyWidget() {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            loc.translate('noWishesYet') ?? '还没有立下小Flag，快去添加吧',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGridRewardCard(Reward reward, {bool isCustom = false}) {
    final canAfford = _availablePoints >= reward.cost;
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    return GestureDetector(
      onLongPress: isCustom ? () => _handleDeleteCustom(reward) : null,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: canAfford ? Colors.amber.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars, size: 12, color: canAfford ? Colors.amber.shade700 : Colors.grey),
                    const SizedBox(width: 2),
                    Text(
                      '${reward.cost} ${loc.translate('pointsUnit') ?? '分'}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: canAfford ? Colors.amber.shade900 : Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(reward.emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text(reward.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: FilledButton(
                onPressed: canAfford ? () => _redeemReward(reward) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: canAfford ? colorScheme.primaryContainer : Colors.grey.shade100,
                  foregroundColor: canAfford ? colorScheme.onPrimaryContainer : Colors.grey.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  canAfford ? (loc.translate('redeem') ?? '兑换') : (loc.translate('notEnoughPointsShort') ?? '积分不足'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _handleDeleteCustom(Reward reward) async {
    final loc = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('deleteWish') ?? '删除愿望'),
        content: Text('${loc.translate('confirmDeleteWish') ?? '确定从你的清单中移除'}「${reward.name}」${loc.translate('questionMark') ?? '吗？'}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel') ?? '取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(loc.translate('delete') ?? '删除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _customRewards.remove(reward));
      await _saveData();
    }
  }
}

class RedeemHistoryPage extends StatelessWidget {
  final List<RedeemRecord> history;
  const RedeemHistoryPage({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.2),
      appBar: AppBar(
        title: Text(
          loc.translate('redeemHistory') ?? '兑换足迹',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wallet_giftcard_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    loc.translate('noRedeemHistory') ?? '还没有兑换过任何奖励哦',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[index];
                final timeStr = '${record.time.month.toString().padLeft(2, '0')}-${record.time.day.toString().padLeft(2, '0')} ${record.time.hour.toString().padLeft(2, '0')}:${record.time.minute.toString().padLeft(2, '0')}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: colorScheme.surfaceVariant.withOpacity(0.3), shape: BoxShape.circle),
                      child: Text(record.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                    title: Text(record.rewardName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(timeStr, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    trailing: Text(
                      '-${record.cost} ${loc.translate('pointsUnit') ?? '积分'}',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
    );
  }
}