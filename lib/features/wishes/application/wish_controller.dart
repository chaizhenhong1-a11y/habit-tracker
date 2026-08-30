import 'package:flutter/foundation.dart';

import '../../habits/domain/repositories/habit_repository.dart';
import '../domain/entities/redeem_record.dart';
import '../domain/entities/reward.dart';
import '../domain/repositories/wish_repository.dart';

class WishController extends ChangeNotifier {
  WishController({required this.repository, required this.habitRepository});

  final WishRepository repository;
  final HabitRepository habitRepository;

  int _spentPoints = 0;
  List<Reward> _customRewards = const [];
  List<RedeemRecord> _redeemHistory = const [];

  int get spentPoints => _spentPoints;
  List<Reward> get customRewards => List.unmodifiable(_customRewards);
  List<RedeemRecord> get redeemHistory => List.unmodifiable(_redeemHistory);

  int get totalPoints => habitRepository.getAll().fold(
    0,
    (total, habit) => total + habit.completedDates.length,
  );

  int get availablePoints => totalPoints - _spentPoints;

  Future<void> load() async {
    final data = await repository.load();
    _spentPoints = data.spentPoints;
    _customRewards = List.of(data.customRewards);
    _redeemHistory = List.of(data.redeemHistory);
    notifyListeners();
  }

  Future<bool> redeem(Reward reward) async {
    if (availablePoints < reward.cost) return false;
    _spentPoints += reward.cost;
    _redeemHistory = [
      RedeemRecord(
        rewardName: reward.name,
        emoji: reward.emoji,
        cost: reward.cost,
        time: DateTime.now(),
      ),
      ..._redeemHistory,
    ];
    await _persist();
    return true;
  }

  Future<void> addReward(Reward reward) async {
    _customRewards = [..._customRewards, reward];
    await _persist();
  }

  Future<void> deleteReward(Reward reward) async {
    _customRewards = _customRewards
        .where(
          (item) =>
              !identical(item, reward) &&
              !(item.name == reward.name &&
                  item.emoji == reward.emoji &&
                  item.cost == reward.cost),
        )
        .toList();
    await _persist();
  }

  Future<void> _persist() async {
    await repository.save(
      WishData(
        spentPoints: _spentPoints,
        customRewards: _customRewards,
        redeemHistory: _redeemHistory,
      ),
    );
    notifyListeners();
  }
}
