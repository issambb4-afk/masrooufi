import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/money.dart';
import '../../accounts/application/accounts_provider.dart';
import '../../categories/application/categories_provider.dart';
import '../application/recurring_list_controller.dart';
import '../application/recurring_form_controller.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  void _showAddRuleDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: const _AddRecurringForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recurringListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
      ),
      body: state.when(
        data: (rules) {
          if (rules.isEmpty) {
            return const Center(child: Text('No active recurring transactions.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(recurringListControllerProvider.future),
            child: ListView.builder(
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return Dismissible(
                  key: Key(rule.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(recurringListControllerProvider.notifier).deactivateRule(rule.id);
                  },
                  child: ListTile(
                    title: Text(rule.name),
                    subtitle: Text('${rule.type.toUpperCase()} • ${rule.frequency}'),
                    trailing: Text(
                      Money(rule.amount, currencyCode: 'TND').format('en_US'), // We would ideally grab the account's currency here
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRuleDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddRecurringForm extends ConsumerWidget {
  const _AddRecurringForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recurringFormControllerProvider);
    final notifier = ref.read(recurringFormControllerProvider.notifier);

    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('New Recurring Rule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Name/Note'),
              onChanged: notifier.setName,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
                ButtonSegment(value: 'transfer', label: Text('Transfer')),
              ],
              selected: {state.type},
              onSelectionChanged: (set) => notifier.setType(set.first),
            ),
            const SizedBox(height: 16),
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) return const Text('No accounts.');
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Account'),
                  value: state.accountId,
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.currency})'))).toList(),
                  onChanged: (val) {
                    if (val != null) notifier.setAccount(val);
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            if (state.type == 'transfer') ...[
              accountsAsync.when(
                data: (accounts) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Destination Account'),
                    value: state.destinationAccountId,
                    items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.currency})'))).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setDestinationAccount(val);
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
            ] else ...[
              categoriesAsync.when(
                data: (categories) {
                  final filtered = categories.where((c) => c.type == state.type).toList();
                  if (filtered.isEmpty) return Text('No ${state.type} categories.');
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Category'),
                    value: state.categoryId,
                    items: filtered.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setCategory(val);
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
            ],

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Frequency'),
              value: state.frequency,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (val) {
                if (val != null) notifier.setFrequency(val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => notifier.setAmount(double.tryParse(val) ?? 0),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: state.isSubmitting ? null : () async {
                final success = await notifier.saveRule();
                if (success && context.mounted) {
                  ref.invalidate(recurringListControllerProvider); // Refresh list
                  Navigator.pop(context);
                } else if (!success && context.mounted && state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
                }
              },
              child: state.isSubmitting ? const CircularProgressIndicator() : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
