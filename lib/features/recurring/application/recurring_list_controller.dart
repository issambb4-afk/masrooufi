import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../domain/entities/recurring_rule.dart';
import '../../../domain/repositories/recurring_repository.dart';

class RecurringListController extends AsyncNotifier<List<RecurringRuleEntity>> {
  RecurringRepository? _repo;

  @override
  Future<List<RecurringRuleEntity>> build() async {
    _repo = sl<RecurringRepository>();
    return _fetchData();
  }

  RecurringRepository get repo => _repo ?? sl<RecurringRepository>();

  void injectDependencies(RecurringRepository repo) {
    _repo = repo;
  }

  Future<List<RecurringRuleEntity>> _fetchData() async {
    final rules = await repo.getAllRules();
    return rules.where((r) => r.isActive).toList();
  }

  Future<void> deactivateRule(String id) async {
    await repo.deactivateRule(id);
    ref.invalidateSelf();
  }
}

final recurringListControllerProvider = AsyncNotifierProvider.autoDispose<RecurringListController, List<RecurringRuleEntity>>(() {
  return RecurringListController();
});
