import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/injection.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/money.dart';
import '../../../domain/repositories/transaction_repository.dart';

class TransactionFormState {
  final String type; // 'expense', 'income', 'transfer'
  final double amount;
  final String? accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final DateTime date;
  final String? note;
  final bool isSubmitting;
  final String? error;

  TransactionFormState({
    this.type = 'expense',
    this.amount = 0.0,
    this.accountId,
    this.destinationAccountId,
    this.categoryId,
    DateTime? date,
    this.note,
    this.isSubmitting = false,
    this.error,
  }) : date = date ?? DateTime.now();

  TransactionFormState copyWith({
    String? type,
    double? amount,
    String? accountId,
    String? destinationAccountId,
    String? categoryId,
    DateTime? date,
    String? note,
    bool? isSubmitting,
    String? error,
  }) {
    return TransactionFormState(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class TransactionFormController extends Notifier<TransactionFormState> {
  TransactionRepository? _repo;

  @override
  TransactionFormState build() {
    _repo = sl<TransactionRepository>();
    return TransactionFormState();
  }

  TransactionRepository get repo => _repo ?? sl<TransactionRepository>();

  // For testing
  void injectDependencies(TransactionRepository repo) {
    _repo = repo;
  }

  void setType(String type) => state = state.copyWith(type: type);
  void setAmount(double amount) => state = state.copyWith(amount: amount);
  void setAccount(String accountId) => state = state.copyWith(accountId: accountId);
  void setDestinationAccount(String destId) => state = state.copyWith(destinationAccountId: destId);
  void setCategory(String categoryId) => state = state.copyWith(categoryId: categoryId);
  void setDate(DateTime date) => state = state.copyWith(date: date);
  void setNote(String note) => state = state.copyWith(note: note);

  Future<bool> saveTransaction() async {
    // Validation
    if (state.amount <= 0) {
      state = state.copyWith(error: 'Amount must be greater than 0');
      return false;
    }
    if (state.accountId == null) {
      state = state.copyWith(error: 'Account must be selected');
      return false;
    }
    if (state.type == 'transfer' && state.destinationAccountId == null) {
      state = state.copyWith(error: 'Destination account required for transfers');
      return false;
    }
    if ((state.type == 'expense' || state.type == 'income') && state.categoryId == null) {
      state = state.copyWith(error: 'Category is required');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final transaction = TransactionEntity(
        id: const Uuid().v4(),
        type: state.type,
        amount: Money.parseToMinorUnits(state.amount), // defaults to TND logic
        accountId: state.accountId!,
        categoryId: state.type == 'transfer' ? null : state.categoryId,
        destinationAccountId: state.type == 'transfer' ? state.destinationAccountId : null,
        transactionDate: state.date,
        note: state.note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createTransaction(transaction);

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final transactionFormControllerProvider = NotifierProvider.autoDispose<TransactionFormController, TransactionFormState>(() {
  return TransactionFormController();
});
