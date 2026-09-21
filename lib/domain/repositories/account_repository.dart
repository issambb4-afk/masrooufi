import '../entities/account.dart';

abstract class AccountRepository {
  Future<List<AccountEntity>> getAllAccounts();
  Future<AccountEntity?> getAccountById(String id);
  Future<void> createAccount(AccountEntity account);
  Future<void> updateAccount(AccountEntity account);
  Future<void> deactivateAccount(String id);
}
