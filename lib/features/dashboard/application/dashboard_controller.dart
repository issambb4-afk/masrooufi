import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../data/services/preferences_service.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../domain/repositories/budget_repository.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/use_cases/get_account_balance.dart';
import '../../../domain/use_cases/get_budget_status.dart';
import '../../../domain/use_cases/get_daily_summary.dart';
import '../../../domain/use_cases/get_monthly_summary.dart';

class DashboardState {
  final int totalBalance;
  final MonthlySummary? monthlySummary;
  final DailySummary? todaySummary;
  final BudgetStatus? globalBudgetStatus;
  final List<TransactionEntity> recentTransactions;
  final String currency;

  DashboardState({
    this.totalBalance = 0,
    this.monthlySummary,
    this.todaySummary,
    this.globalBudgetStatus,
    this.recentTransactions = const [],
    this.currency = 'TND',
  });

  DashboardState copyWith({
    int? totalBalance,
    MonthlySummary? monthlySummary,
    DailySummary? todaySummary,
    BudgetStatus? globalBudgetStatus,
    List<TransactionEntity>? recentTransactions,
    String? currency,
  }) {
    return DashboardState(
      totalBalance: totalBalance ?? this.totalBalance,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      todaySummary: todaySummary ?? this.todaySummary,
      globalBudgetStatus: globalBudgetStatus ?? this.globalBudgetStatus,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      currency: currency ?? this.currency,
    );
  }
}

class DashboardController extends AsyncNotifier<DashboardState> {
  late final PreferencesService _prefs;
  late final AccountRepository _accountRepo;
  late final TransactionRepository _transactionRepo;
  late final BudgetRepository _budgetRepo;

  @override
  Future<DashboardState> build() async {
    _prefs = sl<PreferencesService>();
    _accountRepo = sl<AccountRepository>();
    _transactionRepo = sl<TransactionRepository>();
    _budgetRepo = sl<BudgetRepository>();
    return _fetchData();
  }

  // Exposed for tests
  void injectDependencies(PreferencesService prefs, AccountRepository accountRepo, TransactionRepository transactionRepo, BudgetRepository budgetRepo) {
    _prefs = prefs;
    _accountRepo = accountRepo;
    _transactionRepo = transactionRepo;
    _budgetRepo = budgetRepo;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await _fetchData();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<DashboardState> _fetchData() async {
    final currency = _prefs.getDefaultCurrency();
    final now = DateTime.now();

    // 1. Total Balance
    final accounts = await _accountRepo.getAllAccounts();
    int totalBalance = 0;
    final balanceUseCase = GetAccountBalanceUseCase(_accountRepo, _transactionRepo);
    for (var acc in accounts) {
      if (acc.isActive) {
        totalBalance += await balanceUseCase.execute(acc.id);
      }
    }

    // 2. Summaries
    final monthlyUseCase = GetMonthlySummaryUseCase(_transactionRepo);
    final monthlySummary = await monthlyUseCase.execute(now.year, now.month);

    final dailyUseCase = GetDailySummaryUseCase(_transactionRepo);
    final dailySummary = await dailyUseCase.execute(now);

    // 3. Budgets (Find the first global budget for current month)
    BudgetStatus? globalBudgetStatus;
    final budgets = await _budgetRepo.getAllBudgets();
    final currentPeriod = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    try {
      final globalBudget = budgets.firstWhere((b) => b.type == 'global' && b.period == currentPeriod);
      final budgetStatusUseCase = GetBudgetStatusUseCase(_budgetRepo, _transactionRepo);
      globalBudgetStatus = await budgetStatusUseCase.execute(globalBudget.id);
    } catch (_) {
      // No global budget found
    }

    // 4. Recent Transactions (last 5)
    final recentTxns = await _transactionRepo.getAllTransactions();
    recentTxns.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final topRecent = recentTxns.take(5).toList();

    return DashboardState(
      totalBalance: totalBalance,
      monthlySummary: monthlySummary,
      todaySummary: dailySummary,
      globalBudgetStatus: globalBudgetStatus,
      recentTransactions: topRecent,
      currency: currency,
    );
  }
}

final dashboardControllerProvider = AsyncNotifierProvider<DashboardController, DashboardState>(() {
  return DashboardController();
});
