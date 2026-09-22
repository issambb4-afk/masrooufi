import '../entities/budget.dart';
import '../repositories/budget_repository.dart';
import '../repositories/transaction_repository.dart';

class BudgetStatus {
  final BudgetEntity budget;
  final int usedAmount;

  int get remainingAmount => budget.amount - usedAmount;
  double get percentageUsed => budget.amount > 0 ? (usedAmount / budget.amount) * 100 : 0;
  bool get isExceeded => usedAmount > budget.amount;

  const BudgetStatus({required this.budget, required this.usedAmount});
}

class GetBudgetStatusUseCase {
  final BudgetRepository _budgetRepo;
  final TransactionRepository _transactionRepo;

  GetBudgetStatusUseCase(this._budgetRepo, this._transactionRepo);

  Future<BudgetStatus?> execute(String budgetId) async {
    final budget = await _budgetRepo.getBudgetById(budgetId);
    if (budget == null) return null;

    final periodParts = budget.period.split('-'); // e.g. "2026-09"
    final year = int.parse(periodParts[0]);
    final month = int.parse(periodParts[1]);

    final startOfMonth = DateTime(year, month, 1);
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final endOfMonth = DateTime(nextYear, nextMonth, 1).subtract(const Duration(milliseconds: 1));

    int used = 0;
    if (budget.type == 'global') {
      used = await _transactionRepo.getSumOfTransactionsByTypeAndDate('expense', startOfMonth, endOfMonth);
    } else if (budget.type == 'category' && budget.categoryId != null) {
      used = await _transactionRepo.getSumOfTransactionsByCategoryAndDate(budget.categoryId!, startOfMonth, endOfMonth);
    }

    return BudgetStatus(budget: budget, usedAmount: used);
  }
}
