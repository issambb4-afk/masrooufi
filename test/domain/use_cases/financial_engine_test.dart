import 'package:flutter_test/flutter_test.dart';
import 'package:masrooufi/domain/entities/account.dart';
import 'package:masrooufi/domain/entities/budget.dart';
import 'package:masrooufi/domain/entities/money.dart';
import 'package:masrooufi/domain/entities/transaction.dart' as entity_txn;
import 'package:masrooufi/domain/use_cases/get_account_balance.dart';
import 'package:masrooufi/domain/use_cases/get_budget_status.dart';
import 'package:masrooufi/domain/use_cases/get_daily_summary.dart';
import 'package:masrooufi/domain/use_cases/get_monthly_summary.dart';
import 'package:masrooufi/domain/use_cases/get_savings_rate.dart';

import 'package:masrooufi/domain/repositories/account_repository.dart';
import 'package:masrooufi/domain/repositories/transaction_repository.dart';
import 'package:masrooufi/domain/repositories/budget_repository.dart';

// Mock Repositories
class MockAccountRepository implements AccountRepository {
  final List<AccountEntity> accounts;
  MockAccountRepository(this.accounts);

  @override
  Future<void> createAccount(AccountEntity account) async {}
  @override
  Future<void> deactivateAccount(String id) async {}
  @override
  Future<AccountEntity?> getAccountById(String id) async => accounts.firstWhere((a) => a.id == id);
  @override
  Future<List<AccountEntity>> getAllAccounts() async => accounts;
  @override
  Future<void> updateAccount(AccountEntity account) async {}
}

class MockTransactionRepository implements TransactionRepository {
  final List<entity_txn.TransactionEntity> transactions;
  MockTransactionRepository(this.transactions);

  @override
  Future<void> createTransaction(entity_txn.TransactionEntity transaction) async {}
  @override
  Future<void> deleteTransaction(String id) async {}
  @override
  Future<List<entity_txn.TransactionEntity>> getAllTransactions() async => transactions;
  @override
  Future<int> getSumOfTransactionsByType(String type) async => 0; // Mock not full logic
  @override
  Future<int> getSumOfTransactionsByTypeAndDate(String type, DateTime start, DateTime end) async {
    return transactions
        .where((t) => t.type == type && t.transactionDate.compareTo(start) >= 0 && t.transactionDate.compareTo(end) <= 0)
        .fold<int>(0, (int sum, t) => sum + t.amount);
  }
  @override
  Future<int> getSumOfTransactionsByCategoryAndDate(String categoryId, DateTime start, DateTime end) async {
    return transactions
        .where((t) => t.categoryId == categoryId && t.transactionDate.compareTo(start) >= 0 && t.transactionDate.compareTo(end) <= 0)
        .fold<int>(0, (int sum, t) => sum + t.amount);
  }
  @override
  Future<entity_txn.TransactionEntity?> getTransactionById(String id) async => transactions.firstWhere((t) => t.id == id);
  @override
  Future<List<entity_txn.TransactionEntity>> getTransactionsBetweenDates(DateTime start, DateTime end) async => [];
  @override
  Future<List<entity_txn.TransactionEntity>> getTransactionsByAccount(String accountId) async {
    return transactions.where((t) => t.accountId == accountId || t.destinationAccountId == accountId).toList();
  }
  @override
  Future<List<entity_txn.TransactionEntity>> getTransactionsByCategory(String categoryId) async => [];
  @override
  Future<void> updateTransaction(entity_txn.TransactionEntity transaction) async {}
}

class MockBudgetRepository implements BudgetRepository {
  final List<BudgetEntity> budgets;
  MockBudgetRepository(this.budgets);

  @override
  Future<void> createBudget(BudgetEntity budget) async {}
  @override
  Future<void> deleteBudget(String id) async {}
  @override
  Future<List<BudgetEntity>> getAllBudgets() async => budgets;
  @override
  Future<BudgetEntity?> getBudgetById(String id) async => budgets.firstWhere((b) => b.id == id);
  @override
  Future<void> updateBudget(BudgetEntity budget) async {}
}

void main() {
  group('Money Entity', () {
    test('Calculates and formats TND correctly', () {
      final money = Money(25500, currencyCode: 'TND');
      expect(money.asDouble, 25.5);
      // TND has 3 decimal places
      expect(money.format('en_US').contains('25.500'), true);
    });

    test('Operators work mathematically correctly without floating point loss', () {
      final m1 = Money(10100);
      final m2 = Money(200);
      final res = m1 + m2;
      expect(res.minorUnits, 10300);
    });
  });

  group('Financial Calculations', () {
    final now = DateTime.now();
    final testTxns = [
      entity_txn.TransactionEntity(id: 't1', type: 'income', amount: 500000, accountId: 'a1', transactionDate: now, createdAt: now, updatedAt: now), // 500 TND
      entity_txn.TransactionEntity(id: 't2', type: 'expense', amount: 100000, accountId: 'a1', categoryId: 'c1', transactionDate: now, createdAt: now, updatedAt: now), // 100 TND
      entity_txn.TransactionEntity(id: 't3', type: 'expense', amount: 50000, accountId: 'a1', categoryId: 'c2', transactionDate: now, createdAt: now, updatedAt: now), // 50 TND
      entity_txn.TransactionEntity(id: 't4', type: 'transfer', amount: 200000, accountId: 'a1', destinationAccountId: 'a2', transactionDate: now, createdAt: now, updatedAt: now), // Transfer 200 TND from a1 to a2
    ];

    final mockAccounts = [
      AccountEntity(id: 'a1', name: 'Cash', type: 'cash', currency: 'TND', openingBalance: 100000, isActive: true, createdAt: now, updatedAt: now), // 100 TND
      AccountEntity(id: 'a2', name: 'Bank', type: 'bank', currency: 'TND', openingBalance: 0, isActive: true, createdAt: now, updatedAt: now), // 0 TND
    ];

    final accountRepo = MockAccountRepository(mockAccounts);
    final transactionRepo = MockTransactionRepository(testTxns);

    test('Account Balance computes correctly including transfers', () async {
      final usecase = GetAccountBalanceUseCase(accountRepo, transactionRepo);
      final balanceA1 = await usecase.execute('a1');
      // A1: 100(opening) + 500(income) - 100(expense) - 50(expense) - 200(transfer out) = 250 TND (250000 minor units)
      expect(balanceA1, 250000);

      final balanceA2 = await usecase.execute('a2');
      // A2: 0(opening) + 200(transfer in) = 200 TND (200000 minor units)
      expect(balanceA2, 200000);
    });

    test('Daily and Monthly Summary ignores transfers and sums income/expense', () async {
      final dailyUc = GetDailySummaryUseCase(transactionRepo);
      final summary = await dailyUc.execute(now);

      expect(summary.income, 500000);
      expect(summary.expense, 150000);
      expect(summary.net, 350000);
    });

    test('Savings Rate computes correctly', () async {
      final monthlyUc = GetMonthlySummaryUseCase(transactionRepo);
      final savingsUc = GetSavingsRateUseCase(monthlyUc);

      final rate = await savingsUc.execute(now.year, now.month);
      // Net = 350, Income = 500 -> 350/500 * 100 = 70.0%
      expect(rate, 70.0);
    });

    test('Budget Status computes remaining and percentage', () async {
      final mockBudgets = [
        BudgetEntity(id: 'b1', period: '${now.year}-${now.month.toString().padLeft(2, '0')}', type: 'global', amount: 300000, currency: 'TND', createdAt: now, updatedAt: now) // 300 TND limit
      ];
      final budgetRepo = MockBudgetRepository(mockBudgets);

      final budgetUc = GetBudgetStatusUseCase(budgetRepo, transactionRepo);
      final status = await budgetUc.execute('b1');

      expect(status!.usedAmount, 150000); // 150 TND total expenses
      expect(status.remainingAmount, 150000); // 300 - 150
      expect(status.percentageUsed, 50.0);
      expect(status.isExceeded, false);
    });
  });
}
