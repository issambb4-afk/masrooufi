import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/use_cases/get_account_balance.dart';

class AccountWithBalance {
  final AccountEntity account;
  final int balance;

  const AccountWithBalance(this.account, this.balance);
}

class AccountsListController extends AsyncNotifier<List<AccountWithBalance>> {
  AccountRepository? _accountRepo;
  TransactionRepository? _transactionRepo;

  @override
  Future<List<AccountWithBalance>> build() async {
    _accountRepo = sl<AccountRepository>();
    _transactionRepo = sl<TransactionRepository>();
    return _fetchData();
  }

  AccountRepository get accountRepo => _accountRepo ?? sl<AccountRepository>();
  TransactionRepository get transactionRepo => _transactionRepo ?? sl<TransactionRepository>();

  void injectDependencies(AccountRepository aRepo, TransactionRepository tRepo) {
    _accountRepo = aRepo;
    _transactionRepo = tRepo;
  }

  Future<List<AccountWithBalance>> _fetchData() async {
    final accounts = await accountRepo.getAllAccounts();
    final active = accounts.where((a) => a.isActive).toList();

    final balanceUc = GetAccountBalanceUseCase(accountRepo, transactionRepo);
    final list = <AccountWithBalance>[];

    for (var a in active) {
      final bal = await balanceUc.execute(a.id);
      list.add(AccountWithBalance(a, bal));
    }

    return list;
  }

  Future<void> deactivateAccount(String id) async {
    await accountRepo.deactivateAccount(id);
    ref.invalidateSelf();
  }
}

final accountsListControllerProvider = AsyncNotifierProvider.autoDispose<AccountsListController, List<AccountWithBalance>>(() {
  return AccountsListController();
});
