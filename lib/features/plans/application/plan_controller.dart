import 'package:flutter/foundation.dart';

import '../domain/entities/plan_item.dart';
import '../domain/repositories/plan_repository.dart';

class PlanController extends ChangeNotifier {
  PlanController(this._repository);

  final PlanRepository _repository;
  List<PlanItem> _plans = const [];

  List<PlanItem> get plans => List.unmodifiable(_plans);

  Future<void> load() async {
    _plans = await _repository.getAll();
    notifyListeners();
  }

  Future<void> add(PlanItem plan) async {
    _plans = [..._plans, plan];
    await _persist();
  }

  Future<void> update(PlanItem plan) async {
    _plans = [
      for (final current in _plans)
        if (current.id == plan.id) plan else current,
    ];
    await _persist();
  }

  Future<void> toggleComplete(PlanItem plan) async {
    plan.isCompleted = !plan.isCompleted;
    await update(plan);
  }

  Future<void> delete(String id) async {
    _plans = _plans.where((plan) => plan.id != id).toList();
    await _persist();
  }

  Future<void> _persist() async {
    await _repository.replaceAll(_plans);
    _plans = await _repository.getAll();
    notifyListeners();
  }
}
