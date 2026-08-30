import '../entities/redeem_record.dart';
import '../entities/reward.dart';

class WishData {
  const WishData({
    required this.spentPoints,
    required this.customRewards,
    required this.redeemHistory,
  });

  final int spentPoints;
  final List<Reward> customRewards;
  final List<RedeemRecord> redeemHistory;
}

abstract interface class WishRepository {
  Future<WishData> load();
  Future<void> save(WishData data);
}
