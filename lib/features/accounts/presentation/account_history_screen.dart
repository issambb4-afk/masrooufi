import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/money.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../core/di/injection.dart';

final accountHistoryProvider = FutureProvider.autoDispose.family<List<TransactionEntity>, String>((ref, accountId) async {
  final repo = sl<TransactionRepository>();
  return await repo.getTransactionsByAccount(accountId);
});

class AccountHistoryScreen extends ConsumerWidget {
  final String accountId;
  final String accountName;

  const AccountHistoryScreen({super.key, required this.accountId, required this.accountName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountHistoryProvider(accountId));

    return Scaffold(
      appBar: AppBar(
        title: Text('$accountName History'),
      ),
      body: state.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions yet.'));
          }
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              final isExpense = t.type == 'expense' || (t.type == 'transfer' && t.accountId == accountId);
              final isIncome = t.type == 'income' || (t.type == 'transfer' && t.destinationAccountId == accountId);

              return ListTile(
                title: Text(t.note?.isNotEmpty == true ? t.note! : t.type.toUpperCase()),
                subtitle: Text('${t.transactionDate.year}-${t.transactionDate.month}-${t.transactionDate.day}'),
                trailing: Text(
                  '${isExpense ? '-' : '+'}${Money(t.amount, currencyCode: 'TND').format('en_US')}', // Ideally currency passed properly
                  style: TextStyle(
                    color: isExpense ? Colors.red : (isIncome ? Colors.green : Colors.grey),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
