import '../entities/plan_item.dart';

abstract interface class PlanRepository {
  Future<List<PlanItem>> getAll();
  Future<void> replaceAll(List<PlanItem> plans);
}
