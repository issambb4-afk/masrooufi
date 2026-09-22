import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/injection.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/money.dart';
import '../../../domain/repositories/budget_repository.dart';

class BudgetFormState {
  final String period; // e.g. 2026-09
  final String type; // global, category
  final String? categoryId;
  final double amount;
  final String currency;
  final bool isSubmitting;
  final String? error;

  BudgetFormState({
    String? period,
    this.type = 'global',
    this.categoryId,
    this.amount = 0.0,
    this.currency = 'TND',
    this.isSubmitting = false,
    this.error,
  }) : period = period ?? '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

  BudgetFormState copyWith({
    String? period,
    String? type,
    String? categoryId,
    double? amount,
    String? currency,
    bool? isSubmitting,
    String? error,
  }) {
    return BudgetFormState(
      period: period ?? this.period,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class BudgetFormController extends Notifier<BudgetFormState> {
  BudgetRepository? _repo;

  @override
  BudgetFormState build() {
    _repo = sl<BudgetRepository>();
    return BudgetFormState();
  }

  BudgetRepository get repo => _repo ?? sl<BudgetRepository>();

  void injectDependencies(BudgetRepository repo) {
    _repo = repo;
  }

  void setType(String type) => state = state.copyWith(type: type, categoryId: null);
  void setCategory(String categoryId) => state = state.copyWith(categoryId: categoryId);
  void setAmount(double amount) => state = state.copyWith(amount: amount);

  Future<bool> saveBudget() async {
    if (state.amount <= 0) {
      state = state.copyWith(error: 'Amount must be greater than 0');
      return false;
    }
    if (state.type == 'category' && state.categoryId == null) {
      state = state.copyWith(error: 'Category must be selected');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final budget = BudgetEntity(
        id: const Uuid().v4(),
        period: state.period,
        type: state.type,
        categoryId: state.type == 'category' ? state.categoryId : null,
        amount: Money.parseToMinorUnits(state.amount, currencyCode: state.currency),
        currency: state.currency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createBudget(budget);

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final budgetFormControllerProvider = NotifierProvider.autoDispose<BudgetFormController, BudgetFormState>(() {
  return BudgetFormController();
});
