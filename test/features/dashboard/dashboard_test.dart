import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masrooufi/core/di/injection.dart';
import 'package:masrooufi/data/services/preferences_service.dart';
import 'package:masrooufi/domain/entities/account.dart';
import 'package:masrooufi/domain/entities/budget.dart';
import 'package:masrooufi/domain/entities/transaction.dart';
import 'package:masrooufi/domain/repositories/account_repository.dart';
import 'package:masrooufi/domain/repositories/budget_repository.dart';
import 'package:masrooufi/domain/repositories/transaction_repository.dart';
import 'package:masrooufi/features/dashboard/application/dashboard_controller.dart';
import 'package:masrooufi/features/dashboard/presentation/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAccountRepository implements AccountRepository {
  final List<AccountEntity> accounts;
  MockAccountRepository(this.accounts);
  @override Future<void> createAccount(AccountEntity account) async {}
  @override Future<void> deactivateAccount(String id) async {}
  @override Future<AccountEntity?> getAccountById(String id) async => accounts.firstWhere((a) => a.id == id);
  @override Future<List<AccountEntity>> getAllAccounts() async => accounts;
  @override Future<void> updateAccount(AccountEntity account) async {}
}

class MockTransactionRepository implements TransactionRepository {
  final List<TransactionEntity> transactions;
  MockTransactionRepository(this.transactions);

  @override Future<void> createTransaction(TransactionEntity transaction) async {}
  @override Future<void> deleteTransaction(String id) async {}
  @override Future<List<TransactionEntity>> getAllTransactions() async => transactions;
  @override Future<int> getSumOfTransactionsByType(String type) async {
    return transactions.where((t) => t.type == type).fold<int>(0, (sum, t) => sum + t.amount);
  }
  @override Future<int> getSumOfTransactionsByTypeAndDate(String type, DateTime start, DateTime end) async {
    return transactions
        .where((t) => t.type == type && t.transactionDate.compareTo(start) >= 0 && t.transactionDate.compareTo(end) <= 0)
        .fold<int>(0, (sum, t) => sum + t.amount);
  }
  @override Future<int> getSumOfTransactionsByCategoryAndDate(String categoryId, DateTime start, DateTime end) async {
    return transactions
        .where((t) => t.categoryId == categoryId && t.transactionDate.compareTo(start) >= 0 && t.transactionDate.compareTo(end) <= 0)
        .fold<int>(0, (sum, t) => sum + t.amount);
  }
  @override Future<TransactionEntity?> getTransactionById(String id) async => null;
  @override Future<List<TransactionEntity>> getTransactionsBetweenDates(DateTime start, DateTime end) async => [];
  @override Future<List<TransactionEntity>> getTransactionsByAccount(String accountId) async {
    return transactions.where((t) => t.accountId == accountId || t.destinationAccountId == accountId).toList();
  }
  @override Future<List<TransactionEntity>> getTransactionsByCategory(String categoryId) async => [];
  @override Future<void> updateTransaction(TransactionEntity transaction) async {}
}

class MockBudgetRepository implements BudgetRepository {
  final List<BudgetEntity> budgets;
  MockBudgetRepository(this.budgets);

  @override Future<void> createBudget(BudgetEntity budget) async {}
  @override Future<void> deleteBudget(String id) async {}
  @override Future<List<BudgetEntity>> getAllBudgets() async => budgets;
  @override Future<BudgetEntity?> getBudgetById(String id) async => budgets.firstWhere((b) => b.id == id);
  @override Future<void> updateBudget(BudgetEntity budget) async {}
}

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'defaultCurrency': 'TND'});
    final prefs = await SharedPreferences.getInstance();
    final prefService = PreferencesService(prefs);

    final now = DateTime.now();

    final mockAccounts = [
      AccountEntity(id: 'a1', name: 'Cash', type: 'cash', currency: 'TND', openingBalance: 100000, isActive: true, createdAt: now, updatedAt: now),
    ];
    final mockTxns = [
      TransactionEntity(id: 't1', type: 'income', amount: 500000, accountId: 'a1', transactionDate: now, createdAt: now, updatedAt: now),
      TransactionEntity(id: 't2', type: 'expense', amount: 25000, accountId: 'a1', categoryId: 'c1', note: 'Coffee', transactionDate: now, createdAt: now, updatedAt: now),
    ];
    final currentPeriod = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final mockBudgets = [
      BudgetEntity(id: 'b1', period: currentPeriod, type: 'global', amount: 300000, currency: 'TND', createdAt: now, updatedAt: now)
    ];

    await sl.reset();

    // Register mock repositories for the use cases invoked inside the controller
    sl.registerLazySingleton<PreferencesService>(() => prefService);
    sl.registerLazySingleton<AccountRepository>(() => MockAccountRepository(mockAccounts));
    sl.registerLazySingleton<TransactionRepository>(() => MockTransactionRepository(mockTxns));
    sl.registerLazySingleton<BudgetRepository>(() => MockBudgetRepository(mockBudgets));

    container = ProviderContainer(
      overrides: [
        dashboardControllerProvider.overrideWith(() => DashboardController()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('Dashboard controller correctly aggregates UI state', () async {
    final subscription = container.listen(dashboardControllerProvider, (_, __) {});

    // Wait for async load
    var state = container.read(dashboardControllerProvider);
    while (state.isLoading) {
      await Future.microtask(() {});
      state = container.read(dashboardControllerProvider);
    }

    final data = state.value;
    expect(data, isNotNull);

    // 100 TND (opening) + 500 TND (income) - 25 TND (expense) = 575 TND -> 575000 minor units
    expect(data!.totalBalance, 575000);
    expect(data.monthlySummary?.income, 500000);
    expect(data.monthlySummary?.expense, 25000);
    expect(data.globalBudgetStatus?.percentageUsed, (25000 / 300000) * 100);
    expect(data.recentTransactions.length, 2);

    subscription.close();
  });

  testWidgets('HomeScreen renders aggregated data correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Wait for future provider to yield data
    await tester.pumpAndSettle();

    // Verify Balance UI rendering '575.000 TND'
    expect(find.textContaining('575.000'), findsOneWidget);

    // Verify Monthly income
    expect(find.textContaining('500.000'), findsWidgets);

    // Verify Monthly expense
    expect(find.textContaining('25.000'), findsWidgets); // Expected in summary and recent transactions list

    // Verify recent transactions note rendering
    expect(find.text('Coffee'), findsOneWidget);
  });
}
