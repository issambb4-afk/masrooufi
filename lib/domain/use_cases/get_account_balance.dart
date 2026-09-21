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
    final transactions = await _transactionRepo.getTransactionsByAccount(accountId);

    for (final txn in transactions) {
      if (txn.type == 'income') {
        balance += txn.amount;
      } else if (txn.type == 'expense') {
        balance -= txn.amount;
      } else if (txn.type == 'transfer') {
        if (txn.accountId == accountId) {
          balance -= txn.amount; // Withdrawn from here
        } else if (txn.destinationAccountId == accountId) {
          balance += txn.amount; // Deposited here
        }
      }
    }
    return balance;
  }
}
