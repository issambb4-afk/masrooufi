import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:masrooufi/core/di/injection.dart';
import 'package:masrooufi/data/services/preferences_service.dart';
import 'package:masrooufi/domain/entities/account.dart';
import 'package:masrooufi/domain/entities/budget.dart';
import 'package:masrooufi/domain/repositories/account_repository.dart';
import 'package:masrooufi/domain/repositories/budget_repository.dart';
import 'package:masrooufi/features/onboarding/application/onboarding_controller.dart';

class MockAccountRepository implements AccountRepository {
  final List<AccountEntity> accounts = [];

  @override
  Future<void> createAccount(AccountEntity account) async {
    accounts.add(account);
  }
  @override
  Future<void> deactivateAccount(String id) async {}
  @override
  Future<AccountEntity?> getAccountById(String id) async => null;
  @override
  Future<List<AccountEntity>> getAllAccounts() async => accounts;
  @override
  Future<void> updateAccount(AccountEntity account) async {}
}

class MockBudgetRepository implements BudgetRepository {
  final List<BudgetEntity> budgets = [];

  @override
  Future<void> createBudget(BudgetEntity budget) async {
    budgets.add(budget);
  }
  @override
  Future<void> deleteBudget(String id) async {}
  @override
  Future<List<BudgetEntity>> getAllBudgets() async => budgets;
  @override
  Future<BudgetEntity?> getBudgetById(String id) async => null;
  @override
  Future<void> updateBudget(BudgetEntity budget) async {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
  });

  test('Onboarding flow creates an account, optional budget, and saves preferences', () async {
    final prefs = await SharedPreferences.getInstance();
    final prefService = PreferencesService(prefs);
    final accountRepo = MockAccountRepository();
    final budgetRepo = MockBudgetRepository();

    final container = ProviderContainer(
      overrides: [
        onboardingControllerProvider.overrideWith(() => OnboardingController()..injectDependencies(prefService, accountRepo, budgetRepo)),
      ],
    );

    final controller = container.read(onboardingControllerProvider.notifier);

    // Initial state
    expect(container.read(onboardingControllerProvider).currentStep, 0);

    // Step 1: Currency selection
    controller.setCurrency('USD');
    expect(container.read(onboardingControllerProvider).selectedCurrency, 'USD');

    // Step 2: Account details
    // 50.00 USD should be 5000 minor units
    controller.setAccountDetails('Test Savings', 50.00);

    // Step 3: Budget details
    // 200.00 USD should be 20000 minor units
    controller.setBudget(200.00);

    // Complete Onboarding
    await controller.completeOnboarding();

    // Verify preferences were saved
    expect(prefService.getHasCompletedOnboarding(), true);
    expect(prefService.getDefaultCurrency(), 'USD');

    // Verify account was created properly
    expect(accountRepo.accounts.length, 1);
    final createdAccount = accountRepo.accounts.first;

    expect(createdAccount.name, 'Test Savings');
    expect(createdAccount.currency, 'USD');
    expect(createdAccount.openingBalance, 5000); // 50 USD * 100 minor units

    // Verify budget was created properly
    expect(budgetRepo.budgets.length, 1);
    final createdBudget = budgetRepo.budgets.first;

    expect(createdBudget.amount, 20000); // 200 USD * 100 minor units
    expect(createdBudget.currency, 'USD');
    expect(createdBudget.type, 'global');

    container.dispose();
  });
}
