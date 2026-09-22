import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masrooufi/core/di/injection.dart';
import 'package:masrooufi/domain/entities/account.dart';
import 'package:masrooufi/domain/entities/transaction.dart';
import 'package:masrooufi/domain/repositories/account_repository.dart';
import 'package:masrooufi/domain/repositories/transaction_repository.dart';
import 'package:masrooufi/features/accounts/application/account_form_controller.dart';
import 'package:masrooufi/features/accounts/application/accounts_list_controller.dart';

class MockAccountRepository implements AccountRepository {
  final List<AccountEntity> accounts;
  MockAccountRepository(this.accounts);
  @override Future<void> createAccount(AccountEntity account) async { accounts.add(account); }
  @override Future<void> deactivateAccount(String id) async { accounts.removeWhere((a) => a.id == id); }
  @override Future<AccountEntity?> getAccountById(String id) async => accounts.firstWhere((a) => a.id == id);
  @override Future<List<AccountEntity>> getAllAccounts() async => accounts;
  @override Future<void> updateAccount(AccountEntity account) async {}
}

class MockTransactionRepository implements TransactionRepository {
  @override Future<void> createTransaction(TransactionEntity transaction) async {}
  @override Future<void> deleteTransaction(String id) async {}
  @override Future<List<TransactionEntity>> getAllTransactions() async => [];
  @override Future<int> getSumOfTransactionsByType(String type) async => 0;
  @override Future<int> getSumOfTransactionsByTypeAndDate(String type, DateTime start, DateTime end) async => 0;
  @override Future<int> getSumOfTransactionsByCategoryAndDate(String categoryId, DateTime start, DateTime end) async => 0;
  @override Future<TransactionEntity?> getTransactionById(String id) async => null;
  @override Future<List<TransactionEntity>> getTransactionsBetweenDates(DateTime start, DateTime end) async => [];
  @override Future<List<TransactionEntity>> getTransactionsByAccount(String accountId) async => [];
  @override Future<List<TransactionEntity>> getTransactionsByCategory(String categoryId) async => [];
  @override Future<void> updateTransaction(TransactionEntity transaction) async {}
  @override Future<int> getAccountBalanceOffset(String accountId) async => 0;
}

void main() {
  late ProviderContainer container;
  late MockAccountRepository repo;

  setUp(() async {
    repo = MockAccountRepository([]);
    await sl.reset();
    sl.registerLazySingleton<AccountRepository>(() => repo);

    container = ProviderContainer(
      overrides: [
        accountFormControllerProvider.overrideWith(() => AccountFormController()..injectDependencies(repo)),
        accountsListControllerProvider.overrideWith(() => AccountsListController()..injectDependencies(repo, MockTransactionRepository())),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('AccountFormController prevents empty names', () async {
    final controller = container.read(accountFormControllerProvider.notifier);
    final res = await controller.saveAccount();
    expect(res, isFalse);
    expect(container.read(accountFormControllerProvider).error, 'Name cannot be empty');
  });

  test('AccountFormController successfully parses initial balance to minor units', () async {
    final controller = container.read(accountFormControllerProvider.notifier);
    controller.setName('Test Account');
    controller.setCurrency('USD');
    controller.setOpeningBalance(50.25);
    final res = await controller.saveAccount();

    expect(res, isTrue);
    expect(repo.accounts.length, 1);
    expect(repo.accounts.first.openingBalance, 5025); // 50.25 USD * 100
  });
}
