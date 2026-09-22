import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../domain/repositories/budget_repository.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/use_cases/get_budget_status.dart';

class BudgetsListController extends AsyncNotifier<List<BudgetStatus>> {
  BudgetRepository? _budgetRepo;
  TransactionRepository? _transactionRepo;

  @override
  Future<List<BudgetStatus>> build() async {
    _budgetRepo = sl<BudgetRepository>();
    _transactionRepo = sl<TransactionRepository>();
    return _fetchData();
  }

  BudgetRepository get budgetRepo => _budgetRepo ?? sl<BudgetRepository>();
  TransactionRepository get transactionRepo => _transactionRepo ?? sl<TransactionRepository>();

  void injectDependencies(BudgetRepository bRepo, TransactionRepository tRepo) {
    _budgetRepo = bRepo;
    _transactionRepo = tRepo;
  }

  Future<List<BudgetStatus>> _fetchData() async {
    final budgets = await budgetRepo.getAllBudgets();
    final statusUc = GetBudgetStatusUseCase(budgetRepo, transactionRepo);

    final list = <BudgetStatus>[];
    for (var b in budgets) {
      final status = await statusUc.execute(b.id);
      if (status != null) list.add(status);
    }

    return list;
  }

  Future<void> deleteBudget(String id) async {
    await budgetRepo.deleteBudget(id);
    ref.invalidateSelf();
  }
}

final budgetsListControllerProvider = AsyncNotifierProvider.autoDispose<BudgetsListController, List<BudgetStatus>>(() {
  return BudgetsListController();
});
