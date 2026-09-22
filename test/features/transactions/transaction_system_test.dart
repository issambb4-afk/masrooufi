import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masrooufi/core/di/injection.dart';
import 'package:masrooufi/domain/entities/account.dart';
import 'package:masrooufi/domain/entities/transaction.dart';
import 'package:masrooufi/domain/repositories/account_repository.dart';
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

class MockAccountRepository implements AccountRepository {
  final List<AccountEntity> accounts;
  MockAccountRepository(this.accounts);

  @override Future<void> createAccount(AccountEntity account) async {}
  @override Future<void> deactivateAccount(String id) async {}
  @override Future<AccountEntity?> getAccountById(String id) async {
    try {
      return accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
  @override Future<List<AccountEntity>> getAllAccounts() async => accounts;
  @override Future<void> updateAccount(AccountEntity account) async {}
}

void main() {
  late MockTransactionRepository repo;
  late MockAccountRepository accountRepo;
  late ProviderContainer container;

  setUp(() async {
    repo = MockTransactionRepository();

    accountRepo = MockAccountRepository([
      // Do not include active accounts to trigger the "Account must be selected" error properly during initial load test
    ]);

    await sl.reset();
    sl.registerLazySingleton<TransactionRepository>(() => repo);
    sl.registerLazySingleton<AccountRepository>(() => accountRepo);

    container = ProviderContainer(
      overrides: [
        transactionFormControllerProvider.overrideWith(() => TransactionFormController()..injectDependencies(repo)),
        transactionsListControllerProvider.overrideWith(() => TransactionsListController()..injectDependencies(repo)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Transaction Form Controller', () {
    test('Validates empty account / category correctly', () async {
      final controller = container.read(transactionFormControllerProvider.notifier);

      // Wait for _initDefaultAccount to complete and NOT set an account because list is empty
      await Future.microtask((){});

      controller.setAmount(100.0);
      final result = await controller.saveTransaction();

      expect(result, isFalse);
      expect(container.read(transactionFormControllerProvider).error, 'Account must be selected');
    });

    test('Creates an expense transaction correctly mapped to minor units (TND)', () async {
      accountRepo.accounts.add(AccountEntity(
        id: 'acc_1',
        name: 'TND Account',
        type: 'bank',
        currency: 'TND',
        openingBalance: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

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
      expect(txn.amount, 25500); // 25.500 TND -> 1000 multiplier
      expect(txn.accountId, 'acc_1');
      expect(txn.categoryId, 'cat_1');
      expect(txn.destinationAccountId, isNull);
    });

    test('Creates an expense transaction correctly mapped to minor units (USD)', () async {
      accountRepo.accounts.add(AccountEntity(
        id: 'acc_usd',
        name: 'USD Account',
        type: 'wallet',
        currency: 'USD',
        openingBalance: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final controller = container.read(transactionFormControllerProvider.notifier);

      controller.setAmount(25.5);
      controller.setType('expense');
      controller.setAccount('acc_usd');
      controller.setCategory('cat_1');

      final result = await controller.saveTransaction();

      expect(result, isTrue);
      expect(repo.transactions.length, 1);

      final txn = repo.transactions.first;
      expect(txn.type, 'expense');
      expect(txn.amount, 2550); // 25.50 USD -> 100 multiplier
      expect(txn.accountId, 'acc_usd');
    });

    test('Creates a transfer transaction correctly', () async {
      accountRepo.accounts.add(AccountEntity(
        id: 'acc_1',
        name: 'TND Account',
        type: 'bank',
        currency: 'TND',
        openingBalance: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      accountRepo.accounts.add(AccountEntity(
        id: 'acc_2',
        name: 'Bank',
        type: 'bank',
        currency: 'TND',
        openingBalance: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

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

      final sub = container.listen(transactionsListControllerProvider, (_, __) {});

      var state = container.read(transactionsListControllerProvider);
      while(state.isLoading) {
          await Future.microtask((){});
          state = container.read(transactionsListControllerProvider);
      }

      expect(state.hasValue, isTrue);
      expect(state.value!.length, 1);

      // Delete
      await container.read(transactionsListControllerProvider.notifier).deleteTransaction('t1');

      state = container.read(transactionsListControllerProvider);
      expect(state.value!.length, 0);

      sub.close();
    });
  });
}
