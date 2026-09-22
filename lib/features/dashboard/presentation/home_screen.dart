import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/money.dart';
import '../application/dashboard_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardControllerProvider.notifier).refresh(),
          )
        ],
      ),
      body: dashboardState.when(
        data: (state) => RefreshIndicator(
          onRefresh: ref.read(dashboardControllerProvider.notifier).refresh,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _BalanceCard(
                balance: state.totalBalance,
                currency: state.currency,
              ),
              const SizedBox(height: 16),
              _MonthlySummaryCard(
                income: state.monthlySummary?.income ?? 0,
                expense: state.monthlySummary?.expense ?? 0,
                currency: state.currency,
              ),
              if (state.globalBudgetStatus != null) ...[
                const SizedBox(height: 16),
                _BudgetCard(
                  used: state.globalBudgetStatus!.usedAmount,
                  total: state.globalBudgetStatus!.budget.amount,
                  currency: state.currency,
                  percentage: state.globalBudgetStatus!.percentageUsed,
                ),
              ],
              const SizedBox(height: 24),
              const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (state.recentTransactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No transactions yet.'),
                )
              else
                ...state.recentTransactions.map((t) => ListTile(
                      title: Text(t.note?.isNotEmpty == true ? t.note! : t.type.toUpperCase()),
                      subtitle: Text('${t.transactionDate.year}-${t.transactionDate.month}-${t.transactionDate.day}'),
                      trailing: Text(
                        '${t.type == 'expense' ? '-' : ''}${Money(t.amount, currencyCode: state.currency).format('en_US')}',
                        style: TextStyle(
                          color: t.type == 'expense' ? Colors.red : (t.type == 'income' ? Colors.green : Colors.grey),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading dashboard: $err')),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int balance;
  final String currency;

  const _BalanceCard({required this.balance, required this.currency});

  @override
  Widget build(BuildContext context) {
    final money = Money(balance, currencyCode: currency);
    return Card(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Total Balance',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              money.format('en_US'),
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  final int income;
  final int expense;
  final String currency;

  const _MonthlySummaryCard({required this.income, required this.expense, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Income', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    Money(income, currencyCode: currency).format('en_US'),
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Expenses', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    Money(expense, currencyCode: currency).format('en_US'),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final int used;
  final int total;
  final String currency;
  final double percentage;

  const _BudgetCard({required this.used, required this.total, required this.currency, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Money(used, currencyCode: currency).format('en_US')),
                Text('of ${Money(total, currencyCode: currency).format('en_US')}'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              color: percentage >= 100 ? Colors.red : Theme.of(context).primaryColor,
              backgroundColor: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}
