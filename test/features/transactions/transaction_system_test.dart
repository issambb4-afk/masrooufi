import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masrooufi/core/di/injection.dart';
import 'package:masrooufi/domain/entities/transaction.dart';
import 'package:masrooufi/domain/repositories/transaction_repository.dart';
import 'package:masrooufi/features/transactions/application/transaction_form_controller.dart';
import 'package:masrooufi/features/transactions/application/transactions_list_controller.dart';

class MockTransactionRepository implements TransactionRepository {
  final List<TransactionEntity> transactions = [];

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {
    transactions.add(transaction);
  }
  @override
  Future<void> deleteTransaction(String id) async {
    transactions.removeWhere((t) => t.id == id);
  }
  @override
  Future<List<TransactionEntity>> getAllTransactions() async => transactions;

  @override
  Future<int> getSumOfTransactionsByType(String type) async => 0;
  @override
  Future<int> getSumOfTransactionsByTypeAndDate(String type, DateTime start, DateTime end) async => 0;
  @override
  Future<int> getSumOfTransactionsByCategoryAndDate(String categoryId, DateTime start, DateTime end) async => 0;
  @override
  Future<TransactionEntity?> getTransactionById(String id) async => null;
  @override
  Future<List<TransactionEntity>> getTransactionsBetweenDates(DateTime start, DateTime end) async => [];
  @override
  Future<List<TransactionEntity>> getTransactionsByAccount(String accountId) async => [];
  @override
  Future<List<TransactionEntity>> getTransactionsByCategory(String categoryId) async => [];
  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {}
}

void main() {
  late MockTransactionRepository repo;
  late ProviderContainer container;

  setUp(() async {
    repo = MockTransactionRepository();
    await sl.reset();
    sl.registerLazySingleton<TransactionRepository>(() => repo);

    container = ProviderContainer(
      overrides: [
        transactionFormControllerProvider.overrideWith(() => TransactionFormController()..injectDependencies(repo)),
        // Remove override for list so it uses standard build
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Transaction Form Controller', () {
    test('Validates empty account / category correctly', () async {
      final controller = container.read(transactionFormControllerProvider.notifier);

      controller.setAmount(100.0);
      final result = await controller.saveTransaction();

      expect(result, isFalse);
      expect(container.read(transactionFormControllerProvider).error, 'Account must be selected');
    });

    test('Creates an expense transaction correctly mapped to minor units', () async {
      final controller = container.read(transactionFormControllerProvider.notifier);

      controller.setAmount(25.5);
      controller.setType('expense');
      controller.setAccount('acc_1');
      controller.setCategory('cat_1');

      final result = await controller.saveTransaction();

      expect(result, isTrue);
      expect(repo.transactions.length, 1);

      final txn = repo.transactions.first;
      expect(txn.type, 'expense');
      expect(txn.amount, 25500); // 25.500 TND mapped implicitly
      expect(txn.accountId, 'acc_1');
      expect(txn.categoryId, 'cat_1');
      expect(txn.destinationAccountId, isNull);
    });

    test('Creates a transfer transaction correctly', () async {
      final controller = container.read(transactionFormControllerProvider.notifier);

      controller.setAmount(50.0);
      controller.setType('transfer');
      controller.setAccount('acc_1');
      controller.setDestinationAccount('acc_2');

      final result = await controller.saveTransaction();

      expect(result, isTrue);
      expect(repo.transactions.length, 1);

      final txn = repo.transactions.first;
      expect(txn.type, 'transfer');
      expect(txn.amount, 50000);
      expect(txn.accountId, 'acc_1');
      expect(txn.destinationAccountId, 'acc_2');
      expect(txn.categoryId, isNull); // Transfers don't need categories
    });
  });

  group('Transactions List Controller', () {
    test('Loads transactions and handles delete', () async {
      final now = DateTime.now();
      repo.transactions.add(TransactionEntity(
        id: 't1', type: 'income', amount: 1000, accountId: 'a1', transactionDate: now, createdAt: now, updatedAt: now
      ));

      final subscription = container.listen(transactionsListControllerProvider, (_, __) {});

      // Wait for fetch
      await Future.microtask(() {});

      var state = container.read(transactionsListControllerProvider);

      expect(state.hasValue, isTrue);
      expect(state.value!.length, 1);

      // Delete
      await container.read(transactionsListControllerProvider.notifier).deleteTransaction('t1');

      state = container.read(transactionsListControllerProvider);
      expect(state.value!.length, 0);

      subscription.close();
    });
  });
}
