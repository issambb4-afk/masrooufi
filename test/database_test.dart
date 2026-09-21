import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masrooufi/data/database/app_database.dart';
import 'package:masrooufi/data/repositories/account_repository_impl.dart';
import 'package:masrooufi/data/repositories/category_repository_impl.dart';
import 'package:masrooufi/data/repositories/budget_repository_impl.dart';
import 'package:masrooufi/data/repositories/recurring_repository_impl.dart';
import 'package:masrooufi/data/repositories/transaction_repository_impl.dart';

import 'package:masrooufi/domain/entities/account.dart';
import 'package:masrooufi/domain/entities/category.dart';
import 'package:masrooufi/domain/entities/budget.dart';
import 'package:masrooufi/domain/entities/transaction.dart' as entity_txn;

void main() {
  late AppDatabase db;
  late AccountRepositoryImpl accountRepo;
  late CategoryRepositoryImpl categoryRepo;
  late BudgetRepositoryImpl budgetRepo;
  late RecurringRepositoryImpl recurringRepo;
  late TransactionRepositoryImpl transactionRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    accountRepo = AccountRepositoryImpl(db);
    categoryRepo = CategoryRepositoryImpl(db);
    budgetRepo = BudgetRepositoryImpl(db);
    recurringRepo = RecurringRepositoryImpl(db);
    transactionRepo = TransactionRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Database can insert and retrieve an account correctly using domain entities', () async {
    final account = AccountEntity(
      id: 'acc_123',
      name: 'Test Bank',
      type: 'bank',
      currency: 'TND',
      openingBalance: 1500000,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await accountRepo.createAccount(account);

    final retrieved = await accountRepo.getAccountById('acc_123');
    expect(retrieved != null, isTrue);
    expect(retrieved!.name, 'Test Bank');
    expect(retrieved.openingBalance, 1500000);
  });

  test('Database enforces relationships and stores transfers correctly', () async {
    final accountSrc = AccountEntity(
      id: 'acc_456',
      name: 'Cash',
      type: 'cash',
      currency: 'TND',
      openingBalance: 0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final accountDest = AccountEntity(
      id: 'acc_789',
      name: 'Bank',
      type: 'bank',
      currency: 'TND',
      openingBalance: 0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final category = CategoryEntity(
      id: 'cat_123',
      name: 'Food',
      type: 'expense',
      isDefault: false,
      isActive: true,
      sortOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await accountRepo.createAccount(accountSrc);
    await accountRepo.createAccount(accountDest);
    await categoryRepo.createCategory(category);

    final transaction = entity_txn.TransactionEntity(
      id: 'txn_1',
      type: 'transfer',
      amount: 25500,
      accountId: 'acc_456',
      destinationAccountId: 'acc_789',
      categoryId: 'cat_123',
      transactionDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await transactionRepo.createTransaction(transaction);

    final txns = await transactionRepo.getAllTransactions();
    expect(txns.length, 1);
    expect(txns.first.amount, 25500);
    expect(txns.first.destinationAccountId, 'acc_789');
  });

  test('Database allows deactivating categories safely', () async {
    final category = CategoryEntity(
      id: 'cat_999',
      name: 'Temporary Category',
      type: 'expense',
      isDefault: false,
      isActive: true,
      sortOrder: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await categoryRepo.createCategory(category);
    await categoryRepo.deactivateCategory('cat_999');

    final cat = await categoryRepo.getCategoryById('cat_999');
    expect(cat!.isActive, isFalse);
  });

  test('Budget CRUD operations', () async {
    final budget = BudgetEntity(
      id: 'bg_1',
      period: '2026-09',
      type: 'global',
      amount: 2500000,
      currency: 'TND',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await budgetRepo.createBudget(budget);
    final fetched = await budgetRepo.getBudgetById('bg_1');
    expect(fetched!.amount, 2500000);

    await budgetRepo.deleteBudget('bg_1');
    final afterDelete = await budgetRepo.getAllBudgets();
    expect(afterDelete.isEmpty, isTrue);
  });

  test('Performance: Insert 50,000 records and measure aggregation time', () async {
    final account = AccountEntity(
      id: 'acc_perf',
      name: 'Perf Bank',
      type: 'bank',
      currency: 'TND',
      openingBalance: 0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await accountRepo.createAccount(account);

    final stopwatch = Stopwatch()..start();

    // Batch insert using Drift primitives to bypass entity mapping overhead in test setup
    await db.batch((batch) {
      for (var i = 0; i < 50000; i++) {
        batch.insert(
          db.transactions,
          TransactionsCompanion.insert(
            id: 'txn_$i',
            type: i % 2 == 0 ? 'income' : 'expense',
            amount: 1000,
            accountId: 'acc_perf',
            transactionDate: DateTime.now(),
          )
        );
      }
    });

    final insertTime = stopwatch.elapsedMilliseconds;

    stopwatch.reset();

    final totalIncome = await transactionRepo.getSumOfTransactionsByType('income');
    final totalExpense = await transactionRepo.getSumOfTransactionsByType('expense');

    final aggregateTime = stopwatch.elapsedMilliseconds;

    expect(totalIncome, 25000 * 1000);
    expect(totalExpense, 25000 * 1000);

    print('50k transactions insert time: $insertTime ms');
    print('50k transactions aggregate sum time: $aggregateTime ms');
  });

  test('Money Precision boundary checks map correctly', () async {
    final account = AccountEntity(
      id: 'acc_prec',
      name: 'Precision',
      type: 'bank',
      currency: 'TND',
      openingBalance: 1000500, // 1000.500 TND
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await accountRepo.createAccount(account);

    final txn1 = entity_txn.TransactionEntity(
      id: 'txn_prec_1',
      type: 'expense',
      amount: 25125, // 25.125 TND
      accountId: 'acc_prec',
      transactionDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await transactionRepo.createTransaction(txn1);

    final retrieved = await accountRepo.getAccountById('acc_prec');
    final txns = await transactionRepo.getAllTransactions();

    final balance = retrieved!.openingBalance - txns.first.amount;

    expect(balance, 1000500 - 25125);
    expect(balance, 975375); // 975.375 TND EXACTLY
  });
}
