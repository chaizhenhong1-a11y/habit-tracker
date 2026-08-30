import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/plan_item.dart';
import '../../domain/repositories/plan_repository.dart';

class SharedPreferencesPlanRepository implements PlanRepository {
  static const _storageKey = 'plans';

  @override
  Future<List<PlanItem>> getAll() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedPlans = preferences.getStringList(_storageKey) ?? const [];

    final plans = encodedPlans.map((encoded) {
      final map = jsonDecode(encoded) as Map<String, dynamic>;
      return PlanItem.fromJson(map);
    }).toList();

    plans.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return plans;
  }

  @override
  Future<void> replaceAll(List<PlanItem> plans) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedPlans = plans
        .map((plan) => jsonEncode(plan.toJson()))
        .toList(growable: false);
    await preferences.setStringList(_storageKey, encodedPlans);
  }
}
