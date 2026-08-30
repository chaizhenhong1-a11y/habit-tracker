import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/redeem_record.dart';
import '../../domain/entities/reward.dart';
import '../../domain/repositories/wish_repository.dart';

class SharedPreferencesWishRepository implements WishRepository {
  static const _spentPointsKey = 'spent_points';
  static const _customRewardsKey = 'custom_rewards';
  static const _redeemHistoryKey = 'redeem_history';

  @override
  Future<WishData> load() async {
    final preferences = await SharedPreferences.getInstance();

    final rewards = (preferences.getStringList(_customRewardsKey) ?? const [])
        .map(
          (value) => Reward.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();

    final history =
        (preferences.getStringList(_redeemHistoryKey) ?? const [])
            .map(
              (value) => RedeemRecord.fromJson(
                jsonDecode(value) as Map<String, dynamic>,
              ),
            )
            .toList()
          ..sort((a, b) => b.time.compareTo(a.time));

    return WishData(
      spentPoints: preferences.getInt(_spentPointsKey) ?? 0,
      customRewards: rewards,
      redeemHistory: history,
    );
  }

  @override
  Future<void> save(WishData data) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setInt(_spentPointsKey, data.spentPoints),
      preferences.setStringList(
        _customRewardsKey,
        data.customRewards
            .map((reward) => jsonEncode(reward.toJson()))
            .toList(),
      ),
      preferences.setStringList(
        _redeemHistoryKey,
        data.redeemHistory
            .map((record) => jsonEncode(record.toJson()))
            .toList(),
      ),
    ]);
  }
}
