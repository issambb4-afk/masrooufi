import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/money.dart';
import '../application/transactions_list_controller.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: transactionsState.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text('No transactions yet.'),
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              return Dismissible(
                key: Key(t.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref.read(transactionsListControllerProvider.notifier).deleteTransaction(t.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted')),
                  );
                },
                child: ListTile(
                  title: Text(t.note?.isNotEmpty == true ? t.note! : t.type.toUpperCase()),
                  subtitle: Text('${t.transactionDate.year}-${t.transactionDate.month}-${t.transactionDate.day}'),
                  trailing: Text(
                    '${t.type == 'expense' ? '-' : ''}${Money(t.amount, currencyCode: 'TND').format('en_US')}',
                    style: TextStyle(
                      color: t.type == 'expense' ? Colors.red : (t.type == 'income' ? Colors.green : Colors.grey),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading transactions: $err')),
      ),
    );
  }
}
