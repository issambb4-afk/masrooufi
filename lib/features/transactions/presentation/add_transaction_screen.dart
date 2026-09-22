import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/transaction_form_controller.dart';

class AddTransactionScreen extends ConsumerWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionFormControllerProvider);
    final notifier = ref.read(transactionFormControllerProvider.notifier);

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

            // Date Input (Simulated UI)
            ListTile(
              title: const Text('Date'),
              subtitle: Text('${state.date.year}-${state.date.month}-${state.date.day}'),
              trailing: const Icon(Icons.calendar_today),
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

            // Mock Account / Category Selectors (Will be connected to actual DB data later)
            // Just raw string inputs for UI mapping right now
            TextField(
              decoration: const InputDecoration(labelText: 'Account ID'),
              onChanged: notifier.setAccount,
            ),
            const SizedBox(height: 16),

            if (state.type == 'transfer') ...[
              TextField(
                decoration: const InputDecoration(labelText: 'Destination Account ID'),
                onChanged: notifier.setDestinationAccount,
              ),
              const SizedBox(height: 16),
            ] else ...[
              TextField(
                decoration: const InputDecoration(labelText: 'Category ID'),
                onChanged: notifier.setCategory,
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
