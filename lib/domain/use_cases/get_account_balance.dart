import '../repositories/account_repository.dart';
import '../repositories/transaction_repository.dart';

class GetAccountBalanceUseCase {
  final AccountRepository _accountRepo;
  final TransactionRepository _transactionRepo;

  GetAccountBalanceUseCase(this._accountRepo, this._transactionRepo);

  Future<int> execute(String accountId) async {
    final account = await _accountRepo.getAccountById(accountId);
    if (account == null) throw Exception('Account not found');

    int balance = account.openingBalance;

    // Use SQL aggregation methods via optimized repository function instead of pulling all transactions into memory
    final offset = await _transactionRepo.getAccountBalanceOffset(accountId);

    return balance + offset;
  }
}
