import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<List<BudgetEntity>> getAllBudgets();
  Future<BudgetEntity?> getBudgetById(String id);
  Future<void> createBudget(BudgetEntity budget);
  Future<void> updateBudget(BudgetEntity budget);
  Future<void> deleteBudget(String id);
}
