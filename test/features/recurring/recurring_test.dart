import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masrooufi/core/di/injection.dart';
import 'package:masrooufi/domain/entities/account.dart';
import 'package:masrooufi/domain/entities/recurring_rule.dart';
import 'package:masrooufi/domain/repositories/account_repository.dart';
import 'package:masrooufi/domain/repositories/recurring_repository.dart';
import 'package:masrooufi/features/recurring/application/recurring_form_controller.dart';

class MockRecurringRepository implements RecurringRepository {
  final List<RecurringRuleEntity> rules = [];
  @override Future<void> createRule(RecurringRuleEntity rule) async { rules.add(rule); }
  @override Future<void> deactivateRule(String id) async {}
  @override Future<List<RecurringRuleEntity>> getAllRules() async => rules;
  @override Future<RecurringRuleEntity?> getRuleById(String id) async => null;
  @override Future<void> updateRule(RecurringRuleEntity rule) async {}
}

class MockAccountRepository implements AccountRepository {
  final List<AccountEntity> accounts;
  MockAccountRepository(this.accounts);
  @override Future<void> createAccount(AccountEntity account) async {}
  @override Future<void> deactivateAccount(String id) async {}
  @override Future<AccountEntity?> getAccountById(String id) async {
    try {
      return accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
  @override Future<List<AccountEntity>> getAllAccounts() async => accounts;
  @override Future<void> updateAccount(AccountEntity account) async {}
}

void main() {
  late ProviderContainer container;
  late MockRecurringRepository repo;
  late MockAccountRepository accountRepo;

  setUp(() async {
    repo = MockRecurringRepository();
    accountRepo = MockAccountRepository([
      AccountEntity(id: 'acc1', name: 'Bank', type: 'bank', currency: 'EUR', openingBalance: 0, isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now())
    ]);

    await sl.reset();
    sl.registerLazySingleton<RecurringRepository>(() => repo);
    sl.registerLazySingleton<AccountRepository>(() => accountRepo);

    container = ProviderContainer(
      overrides: [
        recurringFormControllerProvider.overrideWith(() => RecurringFormController()..injectDependencies(repo)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('RecurringFormController handles EUR minor units based on account correctly', () async {
    final controller = container.read(recurringFormControllerProvider.notifier);

    // Wait for the async account default init
    await Future.microtask((){});

    controller.setName('Netflix');
    controller.setAmount(15.99);
    controller.setType('expense');
    controller.setAccount('acc1');
    controller.setCategory('cat1');

    final res = await controller.saveRule();
    expect(res, isTrue);
    expect(repo.rules.length, 1);
    expect(repo.rules.first.amount, 1599); // 15.99 EUR -> 1599 minor units
  });
}
