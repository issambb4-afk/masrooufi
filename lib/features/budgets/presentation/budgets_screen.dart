import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/money.dart';
import '../../categories/application/categories_provider.dart';
import '../application/budgets_list_controller.dart';
import '../application/budget_form_controller.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  void _showAddBudgetDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: const _AddBudgetForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetsListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: state.when(
        data: (budgets) {
          if (budgets.isEmpty) {
            return const Center(child: Text('No active budgets found.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(budgetsListControllerProvider.future),
            child: ListView.builder(
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final status = budgets[index];
                return Dismissible(
                  key: Key(status.budget.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(budgetsListControllerProvider.notifier).deleteBudget(status.budget.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.budget.type == 'global' ? 'Global Budget' : 'Category Budget',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(Money(status.usedAmount, currencyCode: status.budget.currency).format('en_US')),
                              Text('of ${Money(status.budget.amount, currencyCode: status.budget.currency).format('en_US')}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (status.percentageUsed / 100).clamp(0.0, 1.0),
                            color: status.isExceeded ? Colors.red : Theme.of(context).primaryColor,
                            backgroundColor: Colors.grey.shade300,
                          ),
                        ],
                      ),
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
        onPressed: () => _showAddBudgetDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddBudgetForm extends ConsumerWidget {
  const _AddBudgetForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetFormControllerProvider);
    final notifier = ref.read(budgetFormControllerProvider.notifier);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('New Budget', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Type'),
            value: state.type,
            items: const [
              DropdownMenuItem(value: 'global', child: Text('Global')),
              DropdownMenuItem(value: 'category', child: Text('Category')),
            ],
            onChanged: (val) {
              if (val != null) notifier.setType(val);
            },
          ),
          const SizedBox(height: 16),
          if (state.type == 'category') ...[
            categoriesAsync.when(
              data: (categories) {
                final expenseCats = categories.where((c) => c.type == 'expense').toList();
                if (expenseCats.isEmpty) return const Text('No expense categories available.');

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: state.categoryId,
                  items: expenseCats.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) notifier.setCategory(val);
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => notifier.setAmount(double.tryParse(val) ?? 0),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: state.isSubmitting ? null : () async {
              final success = await notifier.saveBudget();
              if (success && context.mounted) {
                ref.invalidate(budgetsListControllerProvider); // Refresh list
                Navigator.pop(context);
              } else if (!success && context.mounted && state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
              }
            },
            child: state.isSubmitting ? const CircularProgressIndicator() : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
