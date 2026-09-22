import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../accounts/application/accounts_provider.dart';
import '../../categories/application/categories_provider.dart';
import '../application/transaction_form_controller.dart';

class AddTransactionScreen extends ConsumerWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionFormControllerProvider);
    final notifier = ref.read(transactionFormControllerProvider.notifier);

    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type Selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
                ButtonSegment(value: 'transfer', label: Text('Transfer')),
              ],
              selected: {state.type},
              onSelectionChanged: (set) => notifier.setType(set.first),
            ),
            const SizedBox(height: 24),

            // Amount Input
            TextField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => notifier.setAmount(double.tryParse(val) ?? 0.0),
            ),
            const SizedBox(height: 16),

            // Date Input
            ListTile(
              title: const Text('Date'),
              subtitle: Text('${state.date.year}-${state.date.month}-${state.date.day}'),
              trailing: const Icon(Icons.calendar_today),
              contentPadding: EdgeInsets.zero,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: state.date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) notifier.setDate(date);
              },
            ),
            const SizedBox(height: 16),

            // Account Selector
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) return const Text('No accounts available.');

                // Auto-select first account if none selected
                if (state.accountId == null && accounts.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    notifier.setAccount(accounts.first.id);
                  });
                }

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Account'),
                  value: state.accountId,
                  items: accounts.map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.name} (${a.currency})'),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) notifier.setAccount(val);
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Error loading accounts: $err'),
            ),
            const SizedBox(height: 16),

            if (state.type == 'transfer') ...[
              accountsAsync.when(
                data: (accounts) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Destination Account'),
                    value: state.destinationAccountId,
                    items: accounts.map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.name} (${a.currency})'),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setDestinationAccount(val);
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
            ] else ...[
              categoriesAsync.when(
                data: (categories) {
                  // Filter categories based on transaction type
                  final filteredCats = categories.where((c) => c.type == state.type).toList();

                  if (filteredCats.isEmpty) return Text('No ${state.type} categories available.');

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Category'),
                    value: state.categoryId,
                    items: filteredCats.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setCategory(val);
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, _) => Text('Error loading categories: $err'),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              decoration: const InputDecoration(labelText: 'Note (Optional)'),
              onChanged: notifier.setNote,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: state.isSubmitting ? null : () async {
                final success = await notifier.saveTransaction();
                if (success && context.mounted) {
                  context.pop(); // return to dashboard
                } else if (!success && context.mounted && state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.error!)),
                  );
                }
              },
              child: state.isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
