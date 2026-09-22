import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/repositories/transaction_repository.dart';

class TransactionsListController extends Notifier<AsyncValue<List<TransactionEntity>>> {
  TransactionRepository? _repo;

  @override
  AsyncValue<List<TransactionEntity>> build() {
    _repo = sl<TransactionRepository>();
    _fetchTransactions();
    return const AsyncValue.loading();
  }

  TransactionRepository get repo => _repo ?? sl<TransactionRepository>();

  // For testing
  void injectDependencies(TransactionRepository repo) {
    _repo = repo;
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final transactions = await repo.getAllTransactions();
      // Optionally sort by date descending here if the repo doesn't enforce it
      transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await repo.deleteTransaction(id);
      await _fetchTransactions(); // Refresh
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transactionsListControllerProvider = NotifierProvider.autoDispose<TransactionsListController, AsyncValue<List<TransactionEntity>>>(() {
  return TransactionsListController();
});
