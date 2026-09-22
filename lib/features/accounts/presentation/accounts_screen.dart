import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/money.dart';
import '../application/accounts_list_controller.dart';
import '../application/account_form_controller.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: const _AddAccountForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountsListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: state.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts found.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(accountsListControllerProvider.future),
            child: ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final item = accounts[index];
                return Dismissible(
                  key: Key(item.account.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(accountsListControllerProvider.notifier).deactivateAccount(item.account.id);
                  },
                  child: ListTile(
                    title: Text(item.account.name),
                    subtitle: Text(item.account.type.toUpperCase()),
                    trailing: Text(
                      Money(item.balance, currencyCode: item.account.currency).format('en_US'),
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
        onPressed: () => _showAddAccountDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddAccountForm extends ConsumerWidget {
  const _AddAccountForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountFormControllerProvider);
    final notifier = ref.read(accountFormControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('New Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(labelText: 'Account Name'),
            onChanged: notifier.setName,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Type'),
            value: state.type,
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Cash')),
              DropdownMenuItem(value: 'bank', child: Text('Bank')),
              DropdownMenuItem(value: 'creditCard', child: Text('Credit Card')),
              DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (val) {
              if (val != null) notifier.setType(val);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Currency'),
            value: state.currency,
            items: const [
              DropdownMenuItem(value: 'TND', child: Text('TND')),
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
            ],
            onChanged: (val) {
              if (val != null) notifier.setCurrency(val);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(labelText: 'Opening Balance'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => notifier.setOpeningBalance(double.tryParse(val) ?? 0),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: state.isSubmitting ? null : () async {
              final success = await notifier.saveAccount();
              if (success && context.mounted) {
                ref.invalidate(accountsListControllerProvider); // Refresh list
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
