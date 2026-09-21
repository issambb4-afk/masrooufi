import 'package:drift/drift.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../database/app_database.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final AppDatabase _db;

  BudgetRepositoryImpl(this._db);

  BudgetEntity _mapToEntity(Budget budget) {
    return BudgetEntity(
      id: budget.id,
      period: budget.period,
      type: budget.type,
      categoryId: budget.categoryId,
      amount: budget.amount,
      currency: budget.currency,
      createdAt: budget.createdAt,
      updatedAt: budget.updatedAt,
    );
  }

  BudgetsCompanion _mapToCompanion(BudgetEntity entity) {
    return BudgetsCompanion(
      id: Value(entity.id),
      period: Value(entity.period),
      type: Value(entity.type),
      categoryId: Value(entity.categoryId),
      amount: Value(entity.amount),
      currency: Value(entity.currency),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  Future<List<BudgetEntity>> getAllBudgets() async {
    final budgets = await _db.select(_db.budgets).get();
    return budgets.map(_mapToEntity).toList();
  }

  @override
  Future<BudgetEntity?> getBudgetById(String id) async {
    final budget = await (_db.select(_db.budgets)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return budget != null ? _mapToEntity(budget) : null;
  }

  @override
  Future<void> createBudget(BudgetEntity budget) =>
      _db.into(_db.budgets).insert(_mapToCompanion(budget));

  @override
  Future<void> updateBudget(BudgetEntity budget) =>
      _db.update(_db.budgets).replace(_mapToCompanion(budget));

  @override
  Future<void> deleteBudget(String id) async {
    await (_db.delete(_db.budgets)..where((tbl) => tbl.id.equals(id))).go();
  }
}
