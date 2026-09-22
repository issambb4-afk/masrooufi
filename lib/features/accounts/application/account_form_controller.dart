import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/injection.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/money.dart';
import '../../../domain/repositories/account_repository.dart';

class AccountFormState {
  final String name;
  final String type; // cash, bank, creditCard, wallet, other
  final String currency;
  final double openingBalance;
  final bool isSubmitting;
  final String? error;

  AccountFormState({
    this.name = '',
    this.type = 'cash',
    this.currency = 'TND',
    this.openingBalance = 0.0,
    this.isSubmitting = false,
    this.error,
  });

  AccountFormState copyWith({
    String? name,
    String? type,
    String? currency,
    double? openingBalance,
    bool? isSubmitting,
    String? error,
  }) {
    return AccountFormState(
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      openingBalance: openingBalance ?? this.openingBalance,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class AccountFormController extends Notifier<AccountFormState> {
  AccountRepository? _repo;

  @override
  AccountFormState build() {
    _repo = sl<AccountRepository>();
    return AccountFormState();
  }

  AccountRepository get repo => _repo ?? sl<AccountRepository>();

  void injectDependencies(AccountRepository repo) {
    _repo = repo;
  }

  void setName(String name) => state = state.copyWith(name: name);
  void setType(String type) => state = state.copyWith(type: type);
  void setCurrency(String currency) => state = state.copyWith(currency: currency);
  void setOpeningBalance(double bal) => state = state.copyWith(openingBalance: bal);

  Future<bool> saveAccount() async {
    if (state.name.trim().isEmpty) {
      state = state.copyWith(error: 'Name cannot be empty');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final account = AccountEntity(
        id: const Uuid().v4(),
        name: state.name,
        type: state.type,
        currency: state.currency,
        openingBalance: Money.parseToMinorUnits(state.openingBalance, currencyCode: state.currency),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createAccount(account);

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final accountFormControllerProvider = NotifierProvider.autoDispose<AccountFormController, AccountFormState>(() {
  return AccountFormController();
});
