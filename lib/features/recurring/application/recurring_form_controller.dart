import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/injection.dart';
import '../../../domain/entities/recurring_rule.dart';
import '../../../domain/entities/money.dart';
import '../../../domain/repositories/recurring_repository.dart';
import '../../../domain/repositories/account_repository.dart';

class RecurringFormState {
  final String name;
  final double amount;
  final String type; // expense, income, transfer
  final String? accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final String frequency; // daily, weekly, monthly, yearly
  final DateTime startDate;
  final bool isSubmitting;
  final String? error;

  RecurringFormState({
    this.name = '',
    this.amount = 0.0,
    this.type = 'expense',
    this.accountId,
    this.destinationAccountId,
    this.categoryId,
    this.frequency = 'monthly',
    DateTime? startDate,
    this.isSubmitting = false,
    this.error,
  }) : startDate = startDate ?? DateTime.now();

  RecurringFormState copyWith({
    String? name,
    double? amount,
    String? type,
    String? accountId,
    String? destinationAccountId,
    String? categoryId,
    String? frequency,
    DateTime? startDate,
    bool? isSubmitting,
    String? error,
  }) {
    return RecurringFormState(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class RecurringFormController extends Notifier<RecurringFormState> {
  RecurringRepository? _repo;

  @override
  RecurringFormState build() {
    _repo = sl<RecurringRepository>();
    _initDefaultAccount();
    return RecurringFormState();
  }

  RecurringRepository get repo => _repo ?? sl<RecurringRepository>();

  void injectDependencies(RecurringRepository repo) {
    _repo = repo;
  }

  Future<void> _initDefaultAccount() async {
    try {
      final accountRepo = sl<AccountRepository>();
      final accounts = await accountRepo.getAllAccounts();
      final active = accounts.where((a) => a.isActive).toList();
      if (active.isNotEmpty && state.accountId == null) {
        state = state.copyWith(accountId: active.first.id);
      }
    } catch (_) { }
  }

  void setName(String name) => state = state.copyWith(name: name);
  void setAmount(double amount) => state = state.copyWith(amount: amount);
  void setType(String type) => state = state.copyWith(type: type, categoryId: null, destinationAccountId: null);
  void setAccount(String accountId) => state = state.copyWith(accountId: accountId);
  void setDestinationAccount(String id) => state = state.copyWith(destinationAccountId: id);
  void setCategory(String id) => state = state.copyWith(categoryId: id);
  void setFrequency(String freq) => state = state.copyWith(frequency: freq);

  Future<bool> saveRule() async {
    if (state.name.trim().isEmpty) {
      state = state.copyWith(error: 'Name cannot be empty');
      return false;
    }
    if (state.amount <= 0) {
      state = state.copyWith(error: 'Amount must be greater than 0');
      return false;
    }
    if (state.accountId == null) {
      state = state.copyWith(error: 'Account must be selected');
      return false;
    }
    if (state.type == 'transfer' && state.destinationAccountId == null) {
      state = state.copyWith(error: 'Destination account required for transfers');
      return false;
    }
    if ((state.type == 'expense' || state.type == 'income') && state.categoryId == null) {
      state = state.copyWith(error: 'Category is required');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final accountRepo = sl<AccountRepository>();
      final account = await accountRepo.getAccountById(state.accountId!);
      final currency = account?.currency ?? 'TND';

      DateTime nextOccur = state.startDate;
      // In a real app we would compute the exact next occurrence based on frequency.
      // For now we just seed it to start date.

      final rule = RecurringRuleEntity(
        id: const Uuid().v4(),
        name: state.name,
        amount: Money.parseToMinorUnits(state.amount, currencyCode: currency),
        type: state.type,
        accountId: state.accountId!,
        destinationAccountId: state.type == 'transfer' ? state.destinationAccountId : null,
        categoryId: state.type == 'transfer' ? null : state.categoryId,
        frequency: state.frequency,
        interval: 1,
        startDate: state.startDate,
        nextOccurrence: nextOccur,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createRule(rule);

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final recurringFormControllerProvider = NotifierProvider.autoDispose<RecurringFormController, RecurringFormState>(() {
  return RecurringFormController();
});
